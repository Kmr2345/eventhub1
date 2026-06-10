const Brevo = require('@getbrevo/brevo');

const client = Brevo.ApiClient.instance;
client.authentications['api-key'].apiKey = process.env.BREVO_API_KEY;

const api = new Brevo.TransactionalEmailsApi();

async function sendVerificationEmail(toEmail, code) {
  await api.sendTransacEmail({
    sender: { name: 'EventHub', email: 'noreply@eventhub.com' },
    to: [{ email: toEmail }],
    subject: 'EventHub — Код подтверждения',
    htmlContent: `
      <div style="font-family: Arial, sans-serif; max-width: 480px; margin: 0 auto; padding: 32px; background: #f9f9f9; border-radius: 12px;">
        <h2 style="color: #6C63FF;">EventHub</h2>
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