const express = require("express");
const router = express.Router();
const Event = require("../models/Event");
const auth = require("../middleware/auth");

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

    res.json(event);
  } catch (err) {
    res.status(500).json(err);
  }
});

// GET ALL EVENTS
router.get("/", async (req, res) => {
  try {
    const events = await Event.find();
    res.json(events);
  } catch (err) {
    res.status(500).json(err);
  }
});

module.exports = router;