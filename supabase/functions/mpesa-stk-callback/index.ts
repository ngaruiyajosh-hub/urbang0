import { corsHeaders } from "../_shared/cors.ts";
import { supabaseAdmin } from "../_shared/supabase.ts";

const simulateTripUrl = Deno.env.get("SIMULATE_TRIP_URL") ?? "";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const payload = await req.json();
    const parsed = parseCallback(payload);

    if (!parsed.bookingId || !parsed.transactionId) {
      return new Response(
        JSON.stringify({ error: "Missing bookingId or transactionId" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const now = new Date().toISOString();

    const { data: payment, error: paymentError } = await supabaseAdmin
      .from("Payments")
      .select("id, booking_id, payment_status")
      .eq("mpesa_transaction_id", parsed.transactionId)
      .maybeSingle();

    if (paymentError) throw paymentError;

    if (payment && payment.payment_status === "Completed") {
      return new Response(
        JSON.stringify({ success: true, message: "Already completed" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    if (payment) {
      const { error: updatePaymentError } = await supabaseAdmin
        .from("Payments")
        .update({
          payment_status: "Completed",
          transaction_date: now,
        })
        .eq("id", payment.id);
      if (updatePaymentError) throw updatePaymentError;
    } else {
      const { error: insertPaymentError } = await supabaseAdmin
        .from("Payments")
        .insert({
          booking_id: parsed.bookingId,
          amount: parsed.amount ?? 0,
          payment_method: "M-Pesa",
          payment_status: "Completed",
          mpesa_transaction_id: parsed.transactionId,
          mpesa_phone_number: parsed.phoneNumber,
          transaction_date: now,
        });
      if (insertPaymentError) throw insertPaymentError;
    }

    const { error: bookingError } = await supabaseAdmin
      .from("Bookings")
      .update({
        status: "Confirmed",
        payment_completed_at: now,
        trip_status: "driver_assigned",
      })
      .eq("id", parsed.bookingId);

    if (bookingError) throw bookingError;

    if (simulateTripUrl) {
      void fetch(simulateTripUrl, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ bookingId: parsed.bookingId }),
      });
    }

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

type CallbackData = {
  bookingId?: string;
  transactionId?: string;
  amount?: number;
  phoneNumber?: string;
};

function parseCallback(payload: any): CallbackData {
  if (payload?.bookingId && payload?.transactionId) {
    return {
      bookingId: String(payload.bookingId),
      transactionId: String(payload.transactionId),
      amount: Number(payload.amount ?? 0),
      phoneNumber: payload.phoneNumber ? String(payload.phoneNumber) : undefined,
    };
  }

  const stk = payload?.Body?.stkCallback;
  if (!stk) return {};

  const metadata = stk?.CallbackMetadata?.Item ?? [];
  const metaMap: Record<string, any> = {};
  for (const item of metadata) {
    if (item?.Name) metaMap[item.Name] = item.Value;
  }

  return {
    bookingId: String(stk?.AccountReference ?? ""),
    transactionId: String(metaMap?.MpesaReceiptNumber ?? stk?.CheckoutRequestID ?? ""),
    amount: Number(metaMap?.Amount ?? 0),
    phoneNumber: metaMap?.PhoneNumber ? String(metaMap.PhoneNumber) : undefined,
  };
}
