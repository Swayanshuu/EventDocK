export default async function handler(req, res) {
  // Set CORS headers so local or cross-origin calls work
  res.setHeader('Access-Control-Allow-Credentials', 'true');
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS,PATCH,DELETE,POST,PUT');
  res.setHeader(
    'Access-Control-Allow-Headers',
    'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version, Authorization'
  );

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { email, name } = req.body || {};
    if (!email || !email.includes('@')) {
      return res.status(400).json({ error: 'Valid email is required' });
    }

    const cleanEmail = email.trim().toLowerCase();
    const displayName = (name && name.trim().length > 0) ? name.trim() : 'Developer';
    const resendApiKey = process.env.RESEND_API_KEY || 're_DvwFRoG2_qQ3cEszVg8ieBSqs9L3mNeTv';
    const fromEmail = process.env.RESEND_FROM_EMAIL || 'EventDock <noreply@swynx.dev>';

    const htmlContent = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Welcome to EventDock Early Access</title>
</head>
<body style="margin: 0; padding: 0; background-color: #000000; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; color: #F5F5F5;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #000000; padding: 40px 20px;">
    <tr>
      <td align="center">
        <table width="100%" max-width="560px" cellpadding="0" cellspacing="0" style="max-width: 560px; background-color: #171717; border: 1px solid #383838; border-radius: 12px; padding: 36px 32px; text-align: left;">
          <tr>
            <td>
              <div style="margin-bottom: 24px;">
                <img src="https://eventdock.swynx.dev/assets/assets/EventDocK-removebg-preview.png" alt="EventDock" height="34" style="display: block; height: 34px; border: 0;" />
              </div>
              <h1 style="color: #F5F5F5; font-size: 20px; font-weight: 700; margin: 0 0 14px 0;">
                You're on the early access list, ${displayName}!
              </h1>
              <p style="color: #A3A3A3; font-size: 14px; line-height: 1.6; margin: 0 0 20px 0;">
                Thank you for signing up. EventDock is a dedicated developer platform designed to detect, inspect, and reproduce API failures in Spring Boot applications.
              </p>
              
              <div style="background-color: #262626; border-left: 3px solid #FF7043; border-radius: 6px; padding: 14px 16px; margin: 20px 0;">
                <div style="color: #F5F5F5; font-size: 13px; font-weight: 600; margin-bottom: 4px;">⚡ What's coming in Early Access:</div>
                <div style="color: #A3A3A3; font-size: 12px; line-height: 1.5;">
                  • <strong>Zero-Latency Error Capture:</strong> Non-blocking 5xx ingestion via eventdock-starter.<br>
                  • <strong>Sanitized Java Traces:</strong> Automatic redaction of sensitive tokens and cookies.<br>
                  • <strong>One-Click Request Replay:</strong> Safe local reproduction with SSRF guardrails.
                </div>
              </div>

              <p style="color: #A3A3A3; font-size: 14px; line-height: 1.6; margin: 0 0 28px 0;">
                We are onboarding teams in batches. We'll send your access credentials directly to this email address.
              </p>

              <table width="100%" cellpadding="0" cellspacing="0">
                <tr>
                  <td>
                    <a href="https://eventdock.swynx.dev" style="display: inline-block; background-color: #FF7043; color: #000000; font-size: 13px; font-weight: 700; text-decoration: none; padding: 12px 24px; border-radius: 6px;">
                      Visit EventDock →
                    </a>
                  </td>
                </tr>
              </table>

              <hr style="border: none; border-top: 1px solid #383838; margin: 32px 0 20px 0;">
              <p style="color: #666666; font-size: 11px; margin: 0; line-height: 1.4;">
                © 2026 EventDock. Built for Spring Boot microservices. If you didn't request this, you can safely ignore this email.
              </p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
    `;

    const resendResponse = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${resendApiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from: fromEmail,
        to: [cleanEmail],
        subject: "You're on the EventDock Waitlist! ⚡",
        html: htmlContent,
      }),
    });

    const data = await resendResponse.json();
    return res.status(resendResponse.status).json(data);
  } catch (err) {
    return res.status(500).json({ error: err.message || 'Internal error' });
  }
}
