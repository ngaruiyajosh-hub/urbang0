import { corsHeaders } from "../_shared/cors.ts";
import { supabaseAdmin } from "../_shared/supabase.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const body = await req.json();
    const bookingId = String(body.bookingId ?? "");
    if (!bookingId) {
      return new Response(
        JSON.stringify({ error: "Missing bookingId" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    await updateTripStatus(bookingId, "driver_assigned");
    await delaySeconds(30);
    await updateTripStatus(bookingId, "driver_arriving");
    await delaySeconds(60);
    await updateTripStatus(bookingId, "trip_started");
    await delaySeconds(90);
    await updateTripStatus(bookingId, "in_progress");
    await delaySeconds(180);
    await updateTripStatus(bookingId, "completed");

    return new Response(
      JSON.stringify({ success: true }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (e) {
    return new Response(
      JSON.stringify({ error: String(e) }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});

async function updateTripStatus(bookingId: string, tripStatus: string) {
  const { error } = await supabaseAdmin
    .from("Bookings")
    .update({ trip_status: tripStatus })
    .eq("id", bookingId);
  if (error) throw error;
}

function delaySeconds(seconds: number) {
  return new Promise((resolve) => setTimeout(resolve, seconds * 1000));
}
