// Appwrite Cloud Function — sends OTP/transactional emails via Gmail SMTP.
//
// Deploy: Appwrite Console > Functions > Create Function
//   - Function ID:  send_email   (or any ID; the app just needs the HTTP URL)
//   - Runtime:      Node.js 18 or 20
//   - HTTP trigger: Enabled
//   - Execute:      "any"  (public — required for unauthenticated browser calls)
// Env vars to set in Appwrite Console (recommended — code has same defaults):
//   GMAIL_SMTP_EMAIL = rohitft20@gmail.com
//   GMAIL_APP_PASSWORD = nrcppvuxywvttyvj
//
// HTTP Trigger — POST with body:
//   { "email": "...", "subject": "...", "html": "...", "text": "..." }
// The app sends { email, to, subject, html, text } — "to" is also accepted.
//
// After deploy, copy the HTTP trigger URL (Console > Functions > send_email >
// Settings > Configuration > HTTP) into AppwriteConfig.mailApiUrl (or pass
// --dart-define=MAIL_API_URL=<url>). MailApiService detects `.appwrite.run` URLs
// and posts here automatically.

const nodemailer = require('nodemailer');

module.exports = async ({ req, res, log, error }) => {
  log('send_email function invoked');

  if (req.method !== 'POST') {
    return res.json({ success: false, error: 'POST only' }, 405);
  }

  let body;
  try {
    body = typeof req.body === 'string' ? JSON.parse(req.body) : req.body;
  } catch (e) {
    return res.json({ success: false, error: 'Invalid JSON body' }, 400);
  }

  const { email, to, subject, html, text } = body || {};
  const recipient = email || to || '';
  if (!recipient || !recipient.includes('@')) {
    return res.json({ success: false, error: 'Invalid email address' }, 400);
  }

  // Gmail SMTP credentials — from Appwrite Function env vars
  const smtpEmail = process.env.GMAIL_SMTP_EMAIL || 'rohitft20@gmail.com';
  const appPassword = process.env.GMAIL_APP_PASSWORD || 'nrcppvuxywvttyvj';

  const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: { user: smtpEmail, pass: appPassword },
  });

  try {
    const info = await transporter.sendMail({
      from: `"Hari Om Traders" <${smtpEmail}>`,
      to: recipient,
      subject: subject || 'Hari Om Traders',
      html: html || '',
      text: text || '',
    });

    log(`Email sent to ${recipient}: ${info.messageId}`);
    return res.json({ success: true, messageId: info.messageId });
  } catch (err) {
    error(`SMTP error: ${err.message}`);
    return res.json({ success: false, error: err.message }, 500);
  }
};
