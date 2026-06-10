const https = require('https');

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

  const payload = JSON.stringify({
    sender: { name: 'EventHub', email: 'kunshuak.06@gmail.com' },
    to: [{ email: toEmail }],
    subject: subjects[l],
    htmlContent: `
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

  return new Promise((resolve, reject) => {
    const req = https.request({
      hostname: 'api.brevo.com',
      path: '/v3/smtp/email',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'api-key': process.env.BREVO_API_KEY,
        'Content-Length': Buffer.byteLength(payload),
      },
    }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve();
        } else {
          reject(new Error(`Brevo API error ${res.statusCode}: ${data}`));
        }
      });
    });
    req.on('error', reject);
    req.write(payload);
    req.end();
  });
}

module.exports = sendVerificationEmail;