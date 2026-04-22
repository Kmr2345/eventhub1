const express = require("express");
const router = express.Router();
const Registration = require("../models/Registration");
const auth = require("../middleware/auth");

// REGISTER TO EVENT
router.post("/", auth, async (req, res) => {
  try {
    const { eventId } = req.body;

    const existing = await Registration.findOne({
      userId: req.user.id,
      eventId
    });

    if (existing) {
      return res.status(400).json("Already registered");
    }

    const registration = new Registration({
      userId: req.user.id,
      eventId
    });

    await registration.save();

    res.json(registration);
  } catch (err) {
    res.status(500).json(err);
  }
});

// CONFIRM ATTENDANCE
router.put("/:id/confirm", auth, async (req, res) => {
  try {
    const registration = await Registration.findById(req.params.id);

    if (!registration) {
      return res.status(404).json("Registration not found");
    }

    // защита только владелец
    if (registration.userId.toString() !== req.user.id) {
      return res.status(403).json("Not allowed");
    }

    registration.status = "confirmed";
    await registration.save();

    res.json(registration);

  } catch (err) {
    res.status(500).json(err);
  }
});

// CANCEL
router.put("/:id/cancel", auth, async (req, res) => {
  try {
    const registration = await Registration.findById(req.params.id);

    if (!registration) {
      return res.status(404).json("Not found");
    }

    if (registration.userId.toString() !== req.user.id) {
      return res.status(403).json("Not allowed");
    }

    registration.status = "cancelled";
    await registration.save();

    res.json(registration);

  } catch (err) {
    res.status(500).json(err);
  }
});

// MARK AS ATTENDED (только organizer)
router.put("/:id/attended", auth, async (req, res) => {
  try {
    const registration = await Registration.findById(req.params.id);

    if (!registration) {
      return res.status(404).json("Registration not found");
    }

    // только организатор
    if (req.user.role !== "organizer") {
      return res.status(403).json("Only organizer can mark attendance");
    }

    // можно добавить проверку статуса
    if (registration.status !== "confirmed") {
      return res.status(400).json("User must confirm first");
    }

    registration.status = "attended";
    await registration.save();

    res.json(registration);

  } catch (err) {
    res.status(500).json(err);
  }
});

// GET MY REGISTRATIONS
router.get("/my", auth, async (req, res) => {
  const regs = await Registration.find({ userId: req.user.id })
      .populate("eventId");

  res.json(regs);
});

module.exports = router;