const express = require("express");
const router = express.Router();
const Event = require("../models/Event");

router.get("/events/:id", async (req, res) => {
  try {
    const ev = await Event.findById(req.params.id);
    if (!ev) return res.status(404).send("Event not found");

    const title = ev.titleRu || ev.title || "Мероприятие";
    const description = ev.descriptionRu || ev.description || "";
    const image = ev.image || "";
    const date = ev.eventDate
      ? new Date(ev.eventDate).toLocaleDateString("ru-RU", {
          day: "numeric", month: "long", year: "numeric",
        })
      : "";
    const location = ev.locationRu || ev.location || "";

    // deep link в приложение (если настроен)
    const appLink = `eventhub://events/${ev._id}`;
    const webLink = `https://eventhubdeploy-production.up.railway.app/events/${ev._id}`;

    res.setHeader("Content-Type", "text/html; charset=utf-8");
    res.send(`<!DOCTYPE html>
<html lang="ru">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>${title}</title>

  <!-- Open Graph (Telegram, WhatsApp, VK) -->
  <meta property="og:title" content="${title}" />
  <meta property="og:description" content="${date ? date + ' · ' : ''}${location}${description ? '\n' + description : ''}" />
  <meta property="og:image" content="${image}" />
  <meta property="og:url" content="${webLink}" />
  <meta property="og:type" content="website" />

  <!-- Twitter Card -->
  <meta name="twitter:card" content="summary_large_image" />
  <meta name="twitter:title" content="${title}" />
  <meta name="twitter:image" content="${image}" />

  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: -apple-system, sans-serif; background: #f5f5f5; display: flex; justify-content: center; align-items: center; min-height: 100vh; padding: 16px; }
    .card { background: white; border-radius: 16px; overflow: hidden; max-width: 480px; width: 100%; box-shadow: 0 4px 20px rgba(0,0,0,0.1); }
    .card img { width: 100%; height: 220px; object-fit: cover; display: ${image ? "block" : "none"}; }
    .card-body { padding: 20px; }
    h1 { font-size: 20px; font-weight: 700; color: #1a1a1a; margin-bottom: 8px; }
    .meta { font-size: 14px; color: #666; margin-bottom: 6px; }
    .desc { font-size: 14px; color: #444; margin-top: 12px; line-height: 1.5; }
    .btn { display: block; margin-top: 20px; background: #6C63FF; color: white; text-align: center; padding: 14px; border-radius: 10px; text-decoration: none; font-size: 15px; font-weight: 600; }
  </style>
</head>
<body>
  <div class="card">
    ${image ? `<img src="${image}" alt="${title}" />` : ""}
    <div class="card-body">
      <h1>${title}</h1>
      ${date ? `<div class="meta">📅 ${date}</div>` : ""}
      ${location ? `<div class="meta">📍 ${location}</div>` : ""}
      ${description ? `<div class="desc">${description}</div>` : ""}
      <a class="btn" href="${appLink}" id="appBtn">Открыть в приложении</a>
    </div>
  </div>
  <script>
    // Пробуем открыть deep link, если не получилось — ничего
    document.getElementById('appBtn').addEventListener('click', function(e) {
      e.preventDefault();
      window.location.href = '${appLink}';
    });
  </script>
</body>
</html>`);
  } catch (err) {
    res.status(500).send("Server error");
  }
});

module.exports = router;