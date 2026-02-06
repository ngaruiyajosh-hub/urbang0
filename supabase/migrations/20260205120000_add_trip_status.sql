-- Migration: Add trip_status to Bookings for lifecycle simulation

ALTER TABLE public."Bookings"
  ADD COLUMN IF NOT EXISTS trip_status TEXT;

CREATE INDEX IF NOT EXISTS idx_bookings_trip_status
  ON public."Bookings"(trip_status);
