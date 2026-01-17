
// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
// Import Firebase Admin SDK from a CDN or use a Deno-compatible version
// Note: Direct Firebase Admin SDK support in Deno is limited. 
// Standard approach is to use valid access tokens or JWT with the FCM HTTP v1 API directly.
// For simplicity in this example, we will use the FCM HTTP v1 API directly with a service account.

// !!! IMPORTANT: You need to set 'FIREBASE_SERVICE_ACCOUNT' secret in Supabase Dashboard !!!
// The secret should be the JSON content of your service account.

console.log("Hello from Functions!")

interface NotificationPayload {
  type: 'INSERT'
  table: string
  record: {
    id: string
    user_id: string
    title: string
    body: string
    data?: any
    created_at: string
  }
  schema: string
}

serve(async (req) => {
  const { name } = await req.json()
  const payload: NotificationPayload = await req.json()

  console.log('Webhook received:', payload)

  if (payload.type !== 'INSERT') {
      return new Response('Not an INSERT event', { status: 200 })
  }

  const { user_id, title, body } = payload.record

  // 1. Get User's FCM Token from Supabase Database
  // Apps connect directly to Supabase, but Edge Functions can also query it.
  // We use the Service Key client typically available in the environment or create one.
  
  const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
  const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''

  if (!supabaseUrl || !supabaseServiceKey) {
     return new Response('Missing Supabase Config', { status: 500 })
  }

  // Simple fetch to get profile
  const profileRes = await fetch(`${supabaseUrl}/rest/v1/profiles?id=eq.${user_id}&select=fcm_token`, {
     headers: {
        'apikey': supabaseServiceKey,
        'Authorization': `Bearer ${supabaseServiceKey}`
     }
  })
  
  if (!profileRes.ok) {
     console.error("Failed to fetch profile", await profileRes.text())
     return new Response('Failed to fetch profile', { status: 500 })
  }

  const profiles = await profileRes.json()
  if (profiles.length === 0 || !profiles[0].fcm_token) {
     console.log(`No FCM token found for user ${user_id}`)
     return new Response('No FCM token found', { status: 200 })
  }

  const fcmToken = profiles[0].fcm_token

  // 2. Get Access Token for Firebase (using Service Account)
  // This requires generating a JWT signed with the service account private key.
  // For brevity, we'll assume the user sets up the JWT generation or uses a simplified approach.
  // A robust way in Deno is using 'jose' library or similar.
  // FOR THE USER: The easiest way to get this working quickly without complex Deno crypto setup 
  // is to use the Legacy FCM API (Server Key) if enabled, OR use a library like 'djwt'.
  // We'll use the Cloud Messaging V1 API which is required now.
  
  // To keep this file simple and runnable, we will output instructions if credentials are missing.
  
  const serviceAccountStr = Deno.env.get('FIREBASE_SERVICE_ACCOUNT')
  if (!serviceAccountStr) {
      console.error("FIREBASE_SERVICE_ACCOUNT secret is missing")
      return new Response('Server Config Error: Missing Firebase Secret', { status: 500 })
  }

  try {
      const accessToken = await getAccessToken(JSON.parse(serviceAccountStr));
      
      // 3. Send Notification via FCM HTTP v1 API
      const projectId = JSON.parse(serviceAccountStr).project_id;
      const fcmUrl = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;
      
      const message = {
          message: {
              token: fcmToken,
              notification: {
                  title: title,
                  body: body,
              },
              data: {
                  click_action: "FLUTTER_NOTIFICATION_CLICK"
              }
          }
      };

      const fcmRes = await fetch(fcmUrl, {
          method: 'POST',
          headers: {
              'Authorization': `Bearer ${accessToken}`,
              'Content-Type': 'application/json'
          },
          body: JSON.stringify(message)
      });

      const fcmData = await fcmRes.json();
      console.log('FCM Response:', fcmData);

      return new Response(JSON.stringify(fcmData), { headers: { "Content-Type": "application/json" } });

  } catch (err) {
      console.error("Error sending notification:", err);
      return new Response(String(err), { status: 500 });
  }
})

// --- Helper to generate OAuth2 Access Token for FCM v1 ---
// Minimal implementation using 'djwt' or 'jose' would be needed here.
// Since we can't easily import external deps without a deno.json map sometimes,
// we will rely on a common Deno pattern. 
// For this artifact, I will use a simplified mock or suggest `import { create } from "https://deno.land/x/djwt@v2.8/mod.ts";`

import { create, getNumericDate } from "https://deno.land/x/djwt@v2.8/mod.ts";

async function getAccessToken(serviceAccount: any) {
    const algorithm = "RS256";
    const pkey = serviceAccount.private_key;
    const email = serviceAccount.client_email;

    const jwt = await create(
        { alg: algorithm, typ: "JWT" },
        { 
            iss: email, 
            scope: "https://www.googleapis.com/auth/firebase.messaging", 
            aud: "https://oauth2.googleapis.com/token",
            exp: getNumericDate(60 * 60), // 1 hour
            iat: getNumericDate(0)
        },
        pkey
    );

    // Exchange JWT for Access Token
    const params = new URLSearchParams();
    params.append('grant_type', 'urn:ietf:params:oauth:grant-type:jwt-bearer');
    params.append('assertion', jwt);

    const res = await fetch('https://oauth2.googleapis.com/token', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: params
    });

    const data = await res.json();
    return data.access_token;
}
