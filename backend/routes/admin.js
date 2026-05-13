const express = require("express");
const router = express.Router();
const User = require("../models/User");
const Event = require("../models/Event");
const Registration = require("../models/Registration");
const authMiddleware = require("../middleware/auth");

// Middleware: only admin can access
const adminOnly = (req, res, next) => {
  if (req.user?.role !== "admin") {
    return res.status(403).json({ message: "Access denied" });
  }
  next();
};

// GET all users
router.get("/users", authMiddleware, adminOnly, async (req, res) => {
  try {
    const users = await User.find({}, "-password").sort({ createdAt: -1 });
    res.json(users);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PATCH change user role
router.patch("/users/:id/role", authMiddleware, adminOnly, async (req, res) => {
  try {
    const { role } = req.body;
    if (!["student", "organizer", "admin"].includes(role)) {
      return res.status(400).json({ message: "Invalid role" });
    }
    const user = await User.findByIdAndUpdate(
      req.params.id,
      { role },
      { new: true, select: "-password" }
    );
    if (!user) return res.status(404).json({ message: "User not found" });
    res.json(user);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE user
router.delete("/users/:id", authMiddleware, adminOnly, async (req, res) => {
  try {
    await User.findByIdAndDelete(req.params.id);
    res.json({ message: "User deleted" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE any event
router.delete("/events/:id", authMiddleware, adminOnly, async (req, res) => {
  try {
    await Event.findByIdAndDelete(req.params.id);
    await Registration.deleteMany({ eventId: req.params.id });
    res.json({ message: "Event deleted" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET stats
router.get("/stats", authMiddleware, adminOnly, async (req, res) => {
  try {
    const totalUsers = await User.countDocuments();
    const totalEvents = await Event.countDocuments();
    const totalRegistrations = await Registration.countDocuments();
    const organizers = await User.countDocuments({ role: "organizer" });
    const students = await User.countDocuments({ role: "student" });
    res.json({ totalUsers, totalEvents, totalRegistrations, organizers, students });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;