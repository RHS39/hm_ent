// Appwrite Cloud Function — sends OTP/transactional emails via Gmail SMTP.
//
// Deploy: Appwrite Console > Functions > Create Function > Node.js 18
// Env vars to set in Appwrite Console:
//   GMAIL_SMTP_EMAIL = rohitft20@gmail.com
//   GMAIL_APP_PASSWORD = nrcppvuxywvttyvj
//
// HTTP Trigger — POST with body:
//   { "email": "...", "subject": "...", "html": "...", "text": "..." }

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

  const { email, subject, html, text } = body || {};
  if (!email || !email.includes('@')) {
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
      to: email,
      subject: subject || 'Hari Om Traders',
      html: html || '',
      text: text || '',
    });

    log(`Email sent to ${email}: ${info.messageId}`);
    return res.json({ success: true, messageId: info.messageId });
  } catch (err) {
    error(`SMTP error: ${err.message}`);
    return res.json({ success: false, error: err.message }, 500);
  }
};
