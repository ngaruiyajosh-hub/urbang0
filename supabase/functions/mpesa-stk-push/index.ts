import { corsHeaders } from "../_shared/cors.ts";

const consumerKey = Deno.env.get("MPESA_CONSUMER_KEY") ?? "";
const consumerSecret = Deno.env.get("MPESA_CONSUMER_SECRET") ?? "";
const shortcode = Deno.env.get("MPESA_SHORTCODE") ?? "";
const passkey = Deno.env.get("MPESA_PASSKEY") ?? "";
const stkUrl = Deno.env.get("MPESA_STK_URL") ??
  "https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest";
const authUrl = Deno.env.get("MPESA_AUTH_URL") ??
  "https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials";
const callbackUrl = Deno.env.get("MPESA_CALLBACK_URL") ?? "";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    if (!consumerKey || !consumerSecret || !shortcode || !passkey) {
      return new Response(
        JSON.stringify({ error: "Missing M-Pesa env vars" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }
    if (!callbackUrl) {
      return new Response(
        JSON.stringify({ error: "Missing MPESA_CALLBACK_URL" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const body = await req.json();
    const amount = Number(body.amount ?? 0);
    const phoneNumber = String(body.phoneNumber ?? "");
    const accountReference = String(body.accountReference ?? "UrbanGo");
    const transactionDesc = String(
      body.transactionDesc ?? "Urban Go ride payment",
    );

    if (!amount || !phoneNumber) {
      return new Response(
        JSON.stringify({ error: "Missing amount or phoneNumber" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const timestamp = formatTimestampNairobi();
    const password = btoa(`${shortcode}${passkey}${timestamp}`);

    const accessToken = await getAccessToken();

    const stkPayload = {
      BusinessShortCode: shortcode,
      Password: password,
      Timestamp: timestamp,
      TransactionType: "CustomerPayBillOnline",
      Amount: Math.round(amount),
      PartyA: phoneNumber,
      PartyB: shortcode,
      PhoneNumber: phoneNumber,
      CallBackURL: callbackUrl,
      AccountReference: accountReference,
      TransactionDesc: transactionDesc,
    };

    const stkRes = await fetch(stkUrl, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(stkPayload),
    });

    const stkJson = await stkRes.json();

    if (!stkRes.ok) {
      return new Response(JSON.stringify(stkJson), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify(stkJson), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    return new Response(
      JSON.stringify({ error: String(e) }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});

async function getAccessToken(): Promise<string> {
  const auth = btoa(`${consumerKey}:${consumerSecret}`);
  const res = await fetch(authUrl, {
    headers: { Authorization: `Basic ${auth}` },
  });
  const json = await res.json();
  if (!res.ok) {
    throw new Error(json?.error_description ?? "Failed to get access token");
  }
  return json.access_token;
}

function formatTimestampNairobi(): string {
  const date = new Date();
  const parts = new Intl.DateTimeFormat("en-GB", {
    timeZone: "Africa/Nairobi",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
    hour12: false,
  }).formatToParts(date);

  const map: Record<string, string> = {};
  for (const p of parts) map[p.type] = p.value;
  return `${map.year}${map.month}${map.day}${map.hour}${map.minute}${map.second}`;
}
