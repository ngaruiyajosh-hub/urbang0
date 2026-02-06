-- Migration: Fix User table email column default value
-- Removes incorrect default value that causes signup failures

-- Remove the incorrect default value from email column
ALTER TABLE public."User"
  ALTER COLUMN email DROP DEFAULT;

-- Ensure email column is NOT NULL (it should be required)
ALTER TABLE public."User"
  ALTER COLUMN email SET NOT NULL;

-- Verify the unique constraint exists on email
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'User_email_key' 
        AND conrelid = 'public."User"'::regclass
    ) THEN
        ALTER TABLE public."User" ADD CONSTRAINT "User_email_key" UNIQUE (email);
    END IF;
END $$;

-- Update the trigger function to handle potential conflicts more gracefully
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Insert new user profile
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
        "phone number" = COALESCE(EXCLUDED."phone number", public."User"."phone number");
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        RAISE LOG 'Error creating user profile for %: %', NEW.email, SQLERRM;
        RETURN NEW;
END;
$$;

-- Recreate the trigger to use updated function
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();