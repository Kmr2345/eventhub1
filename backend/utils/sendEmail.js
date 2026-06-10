const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  host: 'smtp-relay.brevo.com',
  port: 587,
  secure: false,
  auth: {
    user: 'ae41b3001@smtp-brevo.com',
    pass: process.env.BREVO_SMTP_KEY,
  },
});

async function sendVerificationEmail(toEmail, code, lang = 'ru') {
  const subjects = {
    ru: 'EventHub — Код подтверждения',
    kz: 'EventHub — Растау коды',
    en: 'EventHub — Verification Code',
  };
  const titles = {
    ru: 'Ваш код подтверждения:',
    kz: 'Сіздің растау кодыңыз:',
    en: 'Your verification code:',
  };
  const footers = {
    ru: 'Код действителен 10 минут. Не передавайте его никому.',
    kz: 'Код 10 минут бойы жарамды. Ешкімге бермеңіз.',
    en: 'The code is valid for 10 minutes. Do not share it with anyone.',
  };

  const l = ['ru', 'kz', 'en'].includes(lang) ? lang : 'ru';

  await transporter.sendMail({
    from: '"EventHub" <ae41b3001@smtp-brevo.com>',
    to: toEmail,
    subject: subjects[l],
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 480px; margin: 0 auto; padding: 32px; background: #f9f9f9; border-radius: 12px;">
        <h2 style="color: #6C63FF;">EventHub</h2>
        <p style="color: #333; font-size: 16px;">${titles[l]}</p>
        <div style="font-size: 40px; font-weight: bold; letter-spacing: 10px; color: #6C63FF; margin: 24px 0; text-align: center;">
          ${code}
        </div>
        <p style="color: #888; font-size: 13px;">${footers[l]}</p>
      </div>
    `,
  });
}

module.exports = sendVerificationEmail;