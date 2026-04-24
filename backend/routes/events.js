const express = require("express");
const router = express.Router();
const Event = require("../models/Event");
const User = require("../models/User");
const auth = require("../middleware/auth");
const createNotification = require("../utils/createNotification");

// CREATE EVENT
router.post("/", auth, async (req, res) => {
  try {
    if (req.user.role !== "organizer") {
      return res.status(403).json("Only organizers can create events");
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
    const events = await Event.find().populate("organizerId", "name email");
    res.json(events);
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

module.exports = router;