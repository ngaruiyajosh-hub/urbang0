-- Migration: Complete schema setup with authentication integration
-- Creates all necessary tables and sets up authentication properly

-- 1. Create User table if it doesn't exist
CREATE TABLE IF NOT EXISTS public."User" (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    auth_id UUID UNIQUE,
    email TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'Passenger',
    "phone number" TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Create Vehicle table if it doesn't exist
CREATE TABLE IF NOT EXISTS public."Vehicle" (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    driver_id UUID REFERENCES public."User"(id) ON DELETE CASCADE,
    vehicle_type TEXT NOT NULL,
    license_plate TEXT UNIQUE NOT NULL,
    capacity INTEGER NOT NULL,
    status TEXT DEFAULT 'Available',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 3. Create Routes table if it doesn't exist
CREATE TABLE IF NOT EXISTS public."Routes" (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    route_name TEXT NOT NULL,
    start_location TEXT NOT NULL,
    end_location TEXT NOT NULL,
    distance NUMERIC,
    estimated_duration INTEGER,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 4. Create Bookings table if it doesn't exist
CREATE TABLE IF NOT EXISTS public."Bookings" (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    passenger_id UUID REFERENCES public."User"(id) ON DELETE CASCADE,
    route_id UUID REFERENCES public."Routes"(id) ON DELETE SET NULL,
    vehicle_id UUID REFERENCES public."Vehicle"(id) ON DELETE SET NULL,
    booking_date TIMESTAMPTZ DEFAULT now(),
    status TEXT DEFAULT 'Pending',
    pickup_location TEXT,
    dropoff_location TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 5. Create Payments table if it doesn't exist
CREATE TABLE IF NOT EXISTS public."Payments" (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID REFERENCES public."Bookings"(id) ON DELETE CASCADE,
    amount NUMERIC NOT NULL,
    payment_method TEXT NOT NULL,
    payment_status TEXT DEFAULT 'Pending',
    transaction_date TIMESTAMPTZ DEFAULT now(),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 6. Create Reviews table if it doesn't exist
CREATE TABLE IF NOT EXISTS public."Reviews" (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID REFERENCES public."Bookings"(id) ON DELETE CASCADE,
    reviewer_id UUID REFERENCES public."User"(id) ON DELETE CASCADE,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 7. Add foreign key constraint for auth_id if not exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'User_auth_id_fkey'
    ) THEN
        ALTER TABLE public."User"
          ADD CONSTRAINT "User_auth_id_fkey"
          FOREIGN KEY (auth_id)
          REFERENCES auth.users(id)
          ON DELETE CASCADE;
    END IF;
END $$;

-- 8. Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_user_auth_id ON public."User"(auth_id);
CREATE INDEX IF NOT EXISTS idx_bookings_passenger ON public."Bookings"(passenger_id);
CREATE INDEX IF NOT EXISTS idx_vehicle_driver ON public."Vehicle"(driver_id);

-- 9. Enable Row Level Security on all tables
ALTER TABLE public."User" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."Vehicle" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."Routes" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."Bookings" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."Payments" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."Reviews" ENABLE ROW LEVEL SECURITY;

-- 10. Create trigger function to auto-create User profile
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO public."User" (auth_id, email, name, role, "phone number")
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
        COALESCE(NEW.raw_user_meta_data->>'role', 'Passenger'),
        COALESCE(NEW.raw_user_meta_data->>'phone_number', NULL)
    )
    ON CONFLICT (auth_id) DO UPDATE SET
        email = EXCLUDED.email,
        name = COALESCE(EXCLUDED.name, public."User".name),
        role = COALESCE(EXCLUDED.role, public."User".role),
        "phone number" = COALESCE(EXCLUDED."phone number", public."User"."phone number"),
        updated_at = now();
    
    RETURN NEW;
EXCEPTION
    WHEN unique_violation THEN
        RAISE LOG 'Unique violation for user %: %', NEW.email, SQLERRM;
        RETURN NEW;
    WHEN foreign_key_violation THEN
        RAISE LOG 'Foreign key violation for user %: %', NEW.email, SQLERRM;
        RETURN NEW;
    WHEN OTHERS THEN
        RAISE LOG 'Error creating user profile for %: %', NEW.email, SQLERRM;
        RETURN NEW;
END;
$$;

-- 11. Create trigger on auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- 12. RLS Policy: Users manage their own profile
DROP POLICY IF EXISTS "users_manage_own_profile" ON public."User";
CREATE POLICY "users_manage_own_profile"
ON public."User"
FOR ALL
TO authenticated
USING (auth_id = auth.uid())
WITH CHECK (auth_id = auth.uid());

-- 13. RLS Policy: Users read their own profile
DROP POLICY IF EXISTS "users_read_own_profile" ON public."User";
CREATE POLICY "users_read_own_profile"
ON public."User"
FOR SELECT
TO authenticated
USING (auth_id = auth.uid());

-- 14. RLS Policy: Drivers manage their own vehicles
DROP POLICY IF EXISTS "drivers_manage_own_vehicles" ON public."Vehicle";
CREATE POLICY "drivers_manage_own_vehicles"
ON public."Vehicle"
FOR ALL
TO authenticated
USING (
    driver_id IN (
        SELECT id FROM public."User" WHERE auth_id = auth.uid() AND role = 'Driver'
    )
)
WITH CHECK (
    driver_id IN (
        SELECT id FROM public."User" WHERE auth_id = auth.uid() AND role = 'Driver'
    )
);

-- 15. RLS Policy: Passengers view available vehicles
DROP POLICY IF EXISTS "passengers_view_vehicles" ON public."Vehicle";
CREATE POLICY "passengers_view_vehicles"
ON public."Vehicle"
FOR SELECT
TO authenticated
USING (true);

-- 16. RLS Policy: Authenticated users view routes
DROP POLICY IF EXISTS "authenticated_view_routes" ON public."Routes";
CREATE POLICY "authenticated_view_routes"
ON public."Routes"
FOR SELECT
TO authenticated
USING (true);

-- 17. RLS Policy: Passengers manage their own bookings
DROP POLICY IF EXISTS "passengers_manage_own_bookings" ON public."Bookings";
CREATE POLICY "passengers_manage_own_bookings"
ON public."Bookings"
FOR ALL
TO authenticated
USING (
    passenger_id IN (
        SELECT id FROM public."User" WHERE auth_id = auth.uid()
    )
)
WITH CHECK (
    passenger_id IN (
        SELECT id FROM public."User" WHERE auth_id = auth.uid()
    )
);

-- 18. RLS Policy: Users view their own payments
DROP POLICY IF EXISTS "users_view_own_payments" ON public."Payments";
CREATE POLICY "users_view_own_payments"
ON public."Payments"
FOR SELECT
TO authenticated
USING (true);

-- 19. RLS Policy: Authenticated users manage reviews
DROP POLICY IF EXISTS "authenticated_manage_reviews" ON public."Reviews";
CREATE POLICY "authenticated_manage_reviews"
ON public."Reviews"
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);