const express = require("express");
const router = express.Router();
const mongoose = require("mongoose");
const Registration = require("../models/Registration");
const Event = require("../models/Event");
const auth = require("../middleware/auth");

// REGISTER TO EVENT
router.post("/", auth, async (req, res) => {
  try {
    const { eventId } = req.body;

    console.log("REGISTER:", req.user.id, eventId);
    if (req.user.role === "organizer") {
      return res.status(403).json("Organizers cannot register for events");
    }

    if (!eventId || !mongoose.Types.ObjectId.isValid(eventId)) {
      return res.status(400).json("Invalid eventId");
    }

    const eventObjectId = new mongoose.Types.ObjectId(eventId);

    let registration = await Registration.findOne({
      userId: req.user.id,
      eventId: eventObjectId
    });

    console.log("FOUND:", registration);

    // CASE 1: if exists AND cancelled → reuse
    if (registration && registration.status === "cancelled") {
      registration.status = "registered";
      await registration.save();
      await Event.findByIdAndUpdate(eventObjectId, { $inc: { registeredCount: 1 } });
      return res.json(registration);
    }

    // CASE 2: if exists AND active → block
    if (registration && ["registered", "confirmed"].includes(registration.status)) {
      return res.status(400).json("Already registered");
    }

    // CASE 3: create new
    registration = new Registration({
      userId: req.user.id,
      eventId: eventObjectId,
      status: "registered"
    });

    await registration.save();
    await Event.findByIdAndUpdate(eventObjectId, { $inc: { registeredCount: 1 } });

    return res.json(registration);
  } catch (err) {
    console.log("ERROR:", err);
    return res.status(500).json(err);
  }
});

// CONFIRM ATTENDANCE
router.put("/:id/confirm", auth, async (req, res) => {
  try {
    const registration = await Registration.findById(req.params.id);
    if (!registration) return res.status(404).json("Registration not found");
    if (registration.userId.toString() !== req.user.id) return res.status(403).json("Not allowed");
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
    const id = req.params.id;
    console.log("CANCEL REQUEST ID:", id);

    const registration = await Registration.findById(id);
    if (!registration) {
      console.log("NOT FOUND");
      return res.status(404).json("Registration not found");
    }

    registration.status = "cancelled";
    await registration.save();
    await Event.findByIdAndUpdate(registration.eventId, { $inc: { registeredCount: -1 } });

    console.log("AFTER UPDATE:", registration.status);
    return res.json(registration);
  } catch (err) {
    console.log("CANCEL ERROR:", err);
    return res.status(500).json(err);
  }
});

// MARK AS ATTENDED (только organizer)
router.put("/:id/attended", auth, async (req, res) => {
  try {
    const registration = await Registration.findById(req.params.id);
    if (!registration) return res.status(404).json("Registration not found");
    if (req.user.role !== "organizer") return res.status(403).json("Only organizer can mark attendance");
    if (registration.status !== "confirmed") return res.status(400).json("User must confirm first");
    registration.status = "attended";
    await registration.save();
    res.json(registration);
  } catch (err) {
    res.status(500).json(err);
  }
});

// GET MY REGISTRATIONS
router.get("/my", auth, async (req, res) => {
  const regs = await Registration.find({ userId: req.user.id }).populate("eventId");
  res.json(regs);
});

// GET REGISTRATIONS BY EVENT (organizer/admin only)
router.get("/event/:eventId", auth, async (req, res) => {
  try {
    if (!["organizer", "admin"].includes(req.user.role)) {
      return res.status(403).json("Not allowed");
    }
    const regs = await Registration.find({ eventId: req.params.eventId })
      .populate("userId", "name email");
    res.json(regs);
  } catch (err) {
    res.status(500).json(err);
  }
});

module.exports = router;