const nodemailer = require("nodemailer");

const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: process.env.GMAIL_USER,
    pass: process.env.GMAIL_PASS,
  },
});

async function sendVerificationEmail(toEmail, code) {
  await transporter.sendMail({
    from: `"EventHub" <${process.env.GMAIL_USER}>`,
    to: toEmail,
    subject: "EventHub — Код подтверждения",
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 480px; margin: 0 auto; padding: 32px; background: #f9f9f9; border-radius: 12px;">
        <h2 style="color: #6C63FF; margin-bottom: 8px;">EventHub</h2>
        <p style="color: #333; font-size: 16px;">Ваш код подтверждения:</p>
        <div style="font-size: 40px; font-weight: bold; letter-spacing: 10px; color: #6C63FF; margin: 24px 0; text-align: center;">
          ${code}
        </div>
        <p style="color: #888; font-size: 13px;">Код действителен 10 минут. Не передавайте его никому.</p>
      </div>
    `,
  });
}

module.exports = sendVerificationEmail;