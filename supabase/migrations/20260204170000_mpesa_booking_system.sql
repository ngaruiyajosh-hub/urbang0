-- Migration: M-Pesa Payment System with Booking and Wallet Management
-- Adds wallet functionality, payment timeout tracking, and seat management

-- 1. Add wallet balance to User table
ALTER TABLE public."User"
  ADD COLUMN IF NOT EXISTS wallet_balance NUMERIC DEFAULT 0.00;

-- 2. Add payment-related fields to Bookings table
ALTER TABLE public."Bookings"
  ADD COLUMN IF NOT EXISTS fare_amount NUMERIC DEFAULT 0.00,
  ADD COLUMN IF NOT EXISTS payment_initiated_at TIMESTAMP WITH TIME ZONE,
  ADD COLUMN IF NOT EXISTS payment_completed_at TIMESTAMP WITH TIME ZONE,
  ADD COLUMN IF NOT EXISTS payment_timeout_at TIMESTAMP WITH TIME ZONE,
  ADD COLUMN IF NOT EXISTS seats_booked INTEGER DEFAULT 1;

-- 3. Add available_seats to Vehicle table
ALTER TABLE public."Vehicle"
  ADD COLUMN IF NOT EXISTS available_seats INTEGER DEFAULT 0;

-- Update existing vehicles to have available_seats equal to capacity
UPDATE public."Vehicle"
SET available_seats = capacity
WHERE available_seats = 0 OR available_seats IS NULL;

-- 4. Add mpesa_transaction_id to Payments table
ALTER TABLE public."Payments"
  ADD COLUMN IF NOT EXISTS mpesa_transaction_id TEXT,
  ADD COLUMN IF NOT EXISTS mpesa_phone_number TEXT,
  ADD COLUMN IF NOT EXISTS payment_timeout_at TIMESTAMP WITH TIME ZONE;

-- 5. Create Wallet Transactions table for tracking all wallet activities
CREATE TABLE IF NOT EXISTS public."WalletTransactions" (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public."User"(id) ON DELETE CASCADE,
  transaction_type TEXT NOT NULL CHECK (transaction_type IN ('credit', 'debit', 'refund')),
  amount NUMERIC NOT NULL,
  description TEXT,
  booking_id UUID REFERENCES public."Bookings"(id) ON DELETE SET NULL,
  payment_id UUID REFERENCES public."Payments"(id) ON DELETE SET NULL,
  balance_before NUMERIC NOT NULL,
  balance_after NUMERIC NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 6. Create index for wallet transactions
CREATE INDEX IF NOT EXISTS idx_wallet_transactions_user_id ON public."WalletTransactions"(user_id);
CREATE INDEX IF NOT EXISTS idx_wallet_transactions_created_at ON public."WalletTransactions"(created_at DESC);

-- 7. Function to decrease available seats when booking is confirmed
CREATE OR REPLACE FUNCTION public.decrease_vehicle_seats()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    IF NEW.status = 'Confirmed' AND (OLD.status IS NULL OR OLD.status != 'Confirmed') THEN
        UPDATE public."Vehicle"
        SET available_seats = available_seats - COALESCE(NEW.seats_booked, 1)
        WHERE id = NEW.vehicle_id AND available_seats >= COALESCE(NEW.seats_booked, 1);
        
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Not enough available seats';
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

-- 8. Function to increase available seats when booking is cancelled
CREATE OR REPLACE FUNCTION public.increase_vehicle_seats()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    refund_amount NUMERIC;
    user_id_val UUID;
    current_balance NUMERIC;
BEGIN
    IF NEW.status = 'Cancelled' AND OLD.status = 'Confirmed' THEN
        -- Increase available seats
        UPDATE public."Vehicle"
        SET available_seats = available_seats + COALESCE(OLD.seats_booked, 1)
        WHERE id = OLD.vehicle_id;
        
        -- Process refund to wallet
        refund_amount := OLD.fare_amount;
        user_id_val := OLD.passenger_id;
        
        -- Get current balance
        SELECT wallet_balance INTO current_balance
        FROM public."User"
        WHERE id = user_id_val;
        
        -- Update user wallet balance
        UPDATE public."User"
        SET wallet_balance = wallet_balance + refund_amount
        WHERE id = user_id_val;
        
        -- Record wallet transaction
        INSERT INTO public."WalletTransactions" (
            user_id, transaction_type, amount, description,
            booking_id, balance_before, balance_after
        ) VALUES (
            user_id_val, 'refund', refund_amount,
            'Refund for cancelled booking',
            OLD.id, current_balance, current_balance + refund_amount
        );
    END IF;
    RETURN NEW;
END;
$$;

-- 9. Create triggers for seat management
DROP TRIGGER IF EXISTS trigger_decrease_seats ON public."Bookings";
CREATE TRIGGER trigger_decrease_seats
    BEFORE UPDATE ON public."Bookings"
    FOR EACH ROW
    EXECUTE FUNCTION public.decrease_vehicle_seats();

DROP TRIGGER IF EXISTS trigger_increase_seats ON public."Bookings";
CREATE TRIGGER trigger_increase_seats
    AFTER UPDATE ON public."Bookings"
    FOR EACH ROW
    EXECUTE FUNCTION public.increase_vehicle_seats();

-- 10. Function to handle payment timeout (auto-cancel bookings after 5 minutes)
CREATE OR REPLACE FUNCTION public.cancel_expired_bookings()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    cancelled_count INTEGER := 0;
BEGIN
    UPDATE public."Bookings"
    SET status = 'Expired'
    WHERE status = 'Pending'
      AND payment_timeout_at IS NOT NULL
      AND payment_timeout_at < now()
      AND payment_completed_at IS NULL;
    
    GET DIAGNOSTICS cancelled_count = ROW_COUNT;
    RETURN cancelled_count;
END;
$$;

-- 11. RLS Policies for WalletTransactions
ALTER TABLE public."WalletTransactions" ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "users_view_own_wallet_transactions" ON public."WalletTransactions";
CREATE POLICY "users_view_own_wallet_transactions"
ON public."WalletTransactions"
FOR SELECT
TO authenticated
USING (
    user_id IN (
        SELECT id FROM public."User" WHERE auth_id = auth.uid()
    )
);

-- 12. Insert mock data for testing
DO $$
DECLARE
    test_passenger_id UUID;
    test_driver_id UUID;
    test_vehicle_id UUID;
    test_route_id UUID;
BEGIN
    -- Get test users
    SELECT id INTO test_passenger_id FROM public."User" WHERE email = 'passenger@transportconnect.com' LIMIT 1;
    SELECT id INTO test_driver_id FROM public."User" WHERE email = 'driver@transportconnect.com' LIMIT 1;
    
    IF test_passenger_id IS NOT NULL AND test_driver_id IS NOT NULL THEN
        -- Create test route
        INSERT INTO public."Routes" (route_name, start_location, end_location, distance, estimated_duration)
        VALUES ('Downtown to Airport', 'Downtown Plaza', 'International Airport', 25.5, 35)
        ON CONFLICT DO NOTHING
        RETURNING id INTO test_route_id;
        
        IF test_route_id IS NULL THEN
            SELECT id INTO test_route_id FROM public."Routes" WHERE route_name = 'Downtown to Airport' LIMIT 1;
        END IF;
        
        -- Create test vehicle
        INSERT INTO public."Vehicle" (driver_id, vehicle_type, license_plate, capacity, available_seats, status)
        VALUES (test_driver_id, 'Economy', 'KAA-123B', 4, 4, 'Available')
        ON CONFLICT (license_plate) DO UPDATE SET available_seats = 4
        RETURNING id INTO test_vehicle_id;
        
        IF test_vehicle_id IS NULL THEN
            SELECT id INTO test_vehicle_id FROM public."Vehicle" WHERE license_plate = 'KAA-123B' LIMIT 1;
        END IF;
        
        -- Add more test vehicles
        INSERT INTO public."Vehicle" (driver_id, vehicle_type, license_plate, capacity, available_seats, status)
        VALUES 
            (test_driver_id, 'Premium', 'KBB-456C', 3, 3, 'Available'),
            (test_driver_id, 'Shared', 'KCC-789D', 7, 7, 'Available')
        ON CONFLICT (license_plate) DO NOTHING;
        
        -- Initialize wallet balance for test passenger
        UPDATE public."User"
        SET wallet_balance = 50.00
        WHERE id = test_passenger_id;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Mock data creation failed: %', SQLERRM;
END $$;