import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from '@supabase/supabase-js'
import { corsHeaders } from '../_shared/cors.ts'
import { create, getNumericDate } from "djwt/mod.ts"

// Types for Google API response
interface GooglePurchaseResponse {
  kind?: string;
  startTimeMillis?: string;
  expiryTimeMillis?: string;
  autoRenewing?: boolean;
  priceCurrencyCode?: string;
  priceAmountMicros?: string;
  countryCode?: string;
  paymentState?: number;
  acknowledgementState?: number;
  orderId?: string;
}

/**
 * Gets an OAuth2 access token for the Google Play Developer API.
 */
async function getGoogleAccessToken(credsJson: string): Promise<string> {
  const creds = JSON.parse(credsJson);
  
  // Create JWT for Google Auth
  const header = { alg: 'RS256', typ: 'JWT' };
  const payload = {
    iss: creds.client_email,
    sub: creds.client_email,
    aud: 'https://oauth2.googleapis.com/token',
    iat: getNumericDate(0),
    exp: getNumericDate(3600),
    scope: 'https://www.googleapis.com/auth/androidpublisher',
  };

  // Convert private key to CryptoKey
  const pemHeader = "-----BEGIN PRIVATE KEY-----";
  const pemFooter = "-----END PRIVATE KEY-----";
  const pemContents = creds.private_key.substring(pemHeader.length, creds.private_key.length - pemFooter.length).replace(/\s/g, "");
  const binaryDerString = atob(pemContents);
  const binaryDer = new Uint8Array(binaryDerString.length);
  for (let i = 0; i < binaryDerString.length; i++) {
    binaryDer[i] = binaryDerString.charCodeAt(i);
  }

  const key = await crypto.subtle.importKey(
    "pkcs8",
    binaryDer,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );

  const jwt = await create(header, payload, key);

  // Exchange JWT for Access Token
  const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  });

  const data = await tokenResponse.json();
  if (data.error) throw new Error(`Google Auth Failed: ${data.error_description || data.error}`);
  return data.access_token;
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // 1. Authenticate User (Get ID from JWT)
    const authHeader = req.headers.get('Authorization')!
    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: authError } = await supabaseClient.auth.getUser(token)

    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // 2. Parse Request Body
    const { purchase_token, product_id, package_name } = await req.json()

    if (!purchase_token || !product_id || !package_name) {
      return new Response(JSON.stringify({ error: 'Missing parameters' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // 🛡️ DEMO MODE PROTECTION: Still allowed for local development
    if (purchase_token === "dummy_pro_token") {
      console.log('🧪 Demo mode detected: Upgrading user directly');
      const expiresAt = new Date()
      expiresAt.setDate(expiresAt.getDate() + 30)
      
      await upgradeUser(supabaseClient, user.id, purchase_token, expiresAt)
      return new Response(JSON.stringify({ success: true, message: 'Upgraded (Demo Mode)', expires_at: expiresAt.toISOString() }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // 3. 🚀 REAL PRODUCTION LOGIC
    const googleCreds = Deno.env.get('GOOGLE_SERVICE_ACCOUNT_JSON');
    if (!googleCreds) {
      throw new Error('Server configuration error: Google Service Account missing');
    }

    const accessToken = await getGoogleAccessToken(googleCreds);

    // Call Google Play API to verify subscription
    // https://developers.google.com/android-publisher/api-ref/rest/v3/purchases.subscriptions/get
    const verifyResp = await fetch(
      `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${package_name}/purchases/subscriptions/${product_id}/tokens/${purchase_token}`,
      {
        headers: { Authorization: `Bearer ${accessToken}` },
      }
    );

    if (!verifyResp.ok) {
      const errorData = await verifyResp.json();
      return new Response(JSON.stringify({ error: 'Google verification failed', details: errorData }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const purchaseData: GooglePurchaseResponse = await verifyResp.json();

    // 4. Update Database
    const expiryTime = purchaseData.expiryTimeMillis 
      ? new Date(parseInt(purchaseData.expiryTimeMillis))
      : new Date(Date.now() + 30 * 24 * 60 * 60 * 1000); // Fallback to 30 days

    await upgradeUser(supabaseClient, user.id, purchase_token, expiryTime)

    return new Response(JSON.stringify({ 
      success: true, 
      message: 'Verified and Upgraded',
      expires_at: expiryTime.toISOString(),
      order_id: purchaseData.orderId
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })

  } catch (error) {
    console.error('💥 Error:', error.message);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})

async function upgradeUser(supabase: any, userId: string, token: string, expiresAt: Date) {
  const { error } = await supabase
    .from('profiles')
    .update({ 
      role: 'pro', 
      purchase_token: token,
      pro_expires_at: expiresAt.toISOString(),
      updated_at: new Date().toISOString()
    })
    .eq('id', userId);
  
  if (error) {
    console.error('Database Error:', error)
    throw new Error('Failed to update user profile')
  }
}
