const express = require("express");
const router = express.Router();
const Event = require("../models/Event");
const User = require("../models/User");
const auth = require("../middleware/auth");
const createNotification = require("../utils/createNotification");

// CREATE EVENT
router.post("/", auth, async (req, res) => {
  try {
    if (req.user.role !== "organizer" && req.user.role !== "admin") {
      return res.status(403).json("Only organizers and admins can create events");
    }

    const event = new Event({
      ...req.body,
      organizerId: req.user.id
    });

    await event.save();

    // Notify all students about new event
    try {
      const users = await User.find({ role: "student" }).select("_id");
      for (const u of users) {
        await createNotification(
          u._id,
          "Новое мероприятие",
          event.title,
          { type: "newEvent", eventId: event._id }
        );
      }
    } catch (notifyErr) {
      console.log("NEW EVENT NOTIFY ERROR:", notifyErr?.message ?? notifyErr);
    }

    res.json(event);
  } catch (err) {
    res.status(500).json(err);
  }
});

// GET ALL EVENTS
router.get("/", async (req, res) => {
  try {
    const now = new Date();
    const upcoming = await Event.find({ eventDate: { $gte: now } }).populate("organizerId", "name email").sort({ eventDate: 1 });
    const past = await Event.find({ eventDate: { $lt: now } }).populate("organizerId", "name email").sort({ eventDate: -1 });
    res.json([...upcoming, ...past]);
  } catch (err) {
    res.status(500).json(err);
  }
});

// GET EVENT BY ID
router.get("/:id", async (req, res) => {
  try {
    const ev = await Event.findById(req.params.id).populate("organizerId", "name email");
    if (!ev) return res.status(404).json({ message: "Event not found" });
    return res.json(ev);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// UPDATE EVENT
router.put("/:id", auth, async (req, res) => {
  try {
    if (req.user.role !== "organizer" && req.user.role !== "admin") {
      return res.status(403).json({ message: "Only organizers and admins can edit events" });
    }

    const event = await Event.findById(req.params.id);
    if (!event) return res.status(404).json({ message: "Event not found" });

    // Только организатор-владелец или админ может редактировать
    if (req.user.role !== "admin" && event.organizerId.toString() !== req.user.id) {
      return res.status(403).json({ message: "You can only edit your own events" });
    }

    const allowed = [
      "title", "titleRu", "titleKz",
      "description", "descriptionRu", "descriptionKz",
      "eventDate", "location", "locationRu", "locationKz",
      "category", "image", "capacity"
    ];

    allowed.forEach(field => {
      if (req.body[field] !== undefined) event[field] = req.body[field];
    });

    await event.save();
    res.json(event);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;