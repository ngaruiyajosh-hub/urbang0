-- Migration: Fix RLS policies to allow profile reads after authentication
-- Resolves issue where users cannot read their profile immediately after signup

-- 1. Drop conflicting policies
DROP POLICY IF EXISTS "users_manage_own_profile" ON public."User";
DROP POLICY IF EXISTS "users_read_own_profile" ON public."User";

-- 2. Create comprehensive policy for authenticated users to manage their own profile
CREATE POLICY "authenticated_users_full_access"
ON public."User"
FOR ALL
TO authenticated
USING (auth_id = auth.uid())
WITH CHECK (auth_id = auth.uid());

-- 3. Allow authenticated users to read all user profiles (needed for app functionality)
CREATE POLICY "authenticated_users_read_all"
ON public."User"
FOR SELECT
TO authenticated
USING (true);

-- 4. Update trigger function to ensure proper error handling
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Insert new user profile with explicit column names
    INSERT INTO public."User" (auth_id, email, name, role, "phone number", created_at, updated_at)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
        COALESCE(NEW.raw_user_meta_data->>'role', 'Passenger'),
        COALESCE(NEW.raw_user_meta_data->>'phone_number', NULL),
        now(),
        now()
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
        -- Log and continue if duplicate
        RAISE LOG 'User profile already exists for %', NEW.email;
        RETURN NEW;
    WHEN OTHERS THEN
        -- Log error but don't block auth user creation
        RAISE LOG 'Error in handle_new_user for %: %', NEW.email, SQLERRM;
        RETURN NEW;
END;
$$;

-- 5. Recreate trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();