-- Migration: Auth Integration for Transport App
-- Integrates Supabase Auth with existing User table
-- Creates trigger for automatic user profile creation

-- 1. Update User table to link with auth.users
-- Note: auth_id column already exists, just ensure it references auth.users
ALTER TABLE public."User"
  DROP CONSTRAINT IF EXISTS "User_auth_id_fkey";

ALTER TABLE public."User"
  ADD CONSTRAINT "User_auth_id_fkey"
  FOREIGN KEY (auth_id)
  REFERENCES auth.users(id)
  ON DELETE CASCADE;

-- 2. Create index for auth_id lookups
CREATE INDEX IF NOT EXISTS idx_user_auth_id ON public."User"(auth_id);

-- 3. Create trigger function to auto-create User profile when auth user is created
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
    ON CONFLICT (auth_id) DO NOTHING;
    RETURN NEW;
END;
$$;

-- 4. Create trigger on auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- 5. Update RLS policies for User table
DROP POLICY IF EXISTS "users_manage_own_profile" ON public."User";
CREATE POLICY "users_manage_own_profile"
ON public."User"
FOR ALL
TO authenticated
USING (auth_id = auth.uid())
WITH CHECK (auth_id = auth.uid());

-- 6. Update RLS policies for Vehicle table (drivers only)
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

-- Allow passengers to view available vehicles
DROP POLICY IF EXISTS "passengers_view_vehicles" ON public."Vehicle";
CREATE POLICY "passengers_view_vehicles"
ON public."Vehicle"
FOR SELECT
TO authenticated
USING (true);

-- 7. Update RLS policies for Routes table
DROP POLICY IF EXISTS "authenticated_view_routes" ON public."Routes";
CREATE POLICY "authenticated_view_routes"
ON public."Routes"
FOR SELECT
TO authenticated
USING (true);

-- 8. Update RLS policies for Bookings table
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

-- 9. Update RLS policies for Payments table
DROP POLICY IF EXISTS "users_view_own_payments" ON public."Payments";
CREATE POLICY "users_view_own_payments"
ON public."Payments"
FOR SELECT
TO authenticated
USING (true);

-- 10. Update RLS policies for Reviews table
DROP POLICY IF EXISTS "authenticated_manage_reviews" ON public."Reviews";
CREATE POLICY "authenticated_manage_reviews"
ON public."Reviews"
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- 11. Create mock users for testing
DO $$
DECLARE
    passenger_auth_id UUID := gen_random_uuid();
    driver_auth_id UUID := gen_random_uuid();
BEGIN
    -- Create auth users (trigger will create User profiles automatically)
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        created_at, updated_at, raw_user_meta_data, raw_app_meta_data,
        is_sso_user, is_anonymous, confirmation_token, confirmation_sent_at,
        recovery_token, recovery_sent_at, email_change_token_new, email_change,
        email_change_sent_at, email_change_token_current, email_change_confirm_status,
        reauthentication_token, reauthentication_sent_at, phone, phone_change,
        phone_change_token, phone_change_sent_at
    ) VALUES
        (
            passenger_auth_id,
            '00000000-0000-0000-0000-000000000000',
            'authenticated',
            'authenticated',
            'passenger@transportconnect.com',
            crypt('passenger123', gen_salt('bf', 10)),
            now(),
            now(),
            now(),
            jsonb_build_object('name', 'John Passenger', 'role', 'Passenger'),
            jsonb_build_object('provider', 'email', 'providers', ARRAY['email']::TEXT[]),
            false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null
        ),
        (
            driver_auth_id,
            '00000000-0000-0000-0000-000000000000',
            'authenticated',
            'authenticated',
            'driver@transportconnect.com',
            crypt('driver123', gen_salt('bf', 10)),
            now(),
            now(),
            now(),
            jsonb_build_object('name', 'Sarah Driver', 'role', 'Driver'),
            jsonb_build_object('provider', 'email', 'providers', ARRAY['email']::TEXT[]),
            false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null
        )
    ON CONFLICT (id) DO NOTHING;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Mock user creation failed: %', SQLERRM;
END $$;
