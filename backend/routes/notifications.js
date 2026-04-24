const express = require("express");
const router = express.Router();
const auth = require("../middleware/auth");
const Notification = require("../models/Notification");

// GET current user's notifications
router.get("/", auth, async (req, res) => {
  try {
    const list = await Notification.find({ userId: req.user.id })
      .sort({ createdAt: -1 })
      .limit(200);
    return res.json(list);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// Mark all read (optional convenience)
router.post("/readAll", auth, async (req, res) => {
  try {
    await Notification.updateMany(
      { userId: req.user.id, read: false },
      { $set: { read: true } }
    );
    return res.json({ message: "OK" });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// Mark single notification as read
router.put("/read/:id", auth, async (req, res) => {
  try {
    const n = await Notification.findOneAndUpdate(
      { _id: req.params.id, userId: req.user.id },
      { $set: { read: true } },
      { new: true }
    );
    if (!n) return res.status(404).json({ message: "Not found" });
    return res.json(n);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

module.exports = router;

