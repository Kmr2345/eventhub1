const express = require("express");
const router = express.Router();
const Favorite = require("../models/Favorite");
const auth = require("../middleware/auth");

// ADD to favorites
router.post("/", auth, async (req, res) => {
  try {
    const { eventId } = req.body;

    const exists = await Favorite.findOne({
      userId: req.user.id,
      eventId,
    });

    if (exists) return res.json(exists);

    const fav = new Favorite({
      userId: req.user.id,
      eventId,
    });

    await fav.save();
    return res.json(fav);
  } catch (err) {
    return res.status(500).json(err);
  }
});

// REMOVE from favorites
router.delete("/:eventId", auth, async (req, res) => {
  try {
    await Favorite.findOneAndDelete({
      userId: req.user.id,
      eventId: req.params.eventId,
    });

    return res.json({ message: "Removed" });
  } catch (err) {
    return res.status(500).json(err);
  }
});

// GET favorites
router.get("/", auth, async (req, res) => {
  try {
    const favs = await Favorite.find({ userId: req.user.id }).populate("eventId");
    return res.json(favs);
  } catch (err) {
    return res.status(500).json(err);
  }
});

module.exports = router;

