const Notification = require("../models/Notification");

function dayKey(d) {
  const yyyy = d.getFullYear();
  const mm = String(d.getMonth() + 1).padStart(2, "0");
  const dd = String(d.getDate()).padStart(2, "0");
  return `${yyyy}-${mm}-${dd}`;
}

/**
 * Create notification with simple de-dupe.
 * meta.type + meta.eventId (+ meta.day when provided) are used for uniqueness.
 */
async function createNotification(userId, title, body, meta = {}) {
  const type = meta.type;
  const eventId = meta.eventId?.toString();
  const day = meta.day;

  if (type && eventId) {
    const query = {
      userId,
      "meta.type": type,
      "meta.eventId": eventId,
    };
    if (day) query["meta.day"] = day;

    const exists = await Notification.findOne(query);
    if (exists) return exists;
  }

  const n = new Notification({
    userId,
    eventId: eventId ?? null,
    title,
    body,
    meta: {
      ...meta,
      eventId: eventId ?? meta.eventId,
    },
  });
  await n.save();
  return n;
}

createNotification.dayKey = dayKey;

module.exports = createNotification;

