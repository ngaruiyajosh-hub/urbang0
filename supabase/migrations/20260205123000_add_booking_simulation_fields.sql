-- Migration: Store simulated distance, duration, and final fare on bookings

ALTER TABLE public."Bookings"
  ADD COLUMN IF NOT EXISTS simulated_distance_km NUMERIC,
  ADD COLUMN IF NOT EXISTS simulated_duration_min INTEGER,
  ADD COLUMN IF NOT EXISTS final_fare NUMERIC;

CREATE INDEX IF NOT EXISTS idx_bookings_simulated_distance
  ON public."Bookings"(simulated_distance_km);
