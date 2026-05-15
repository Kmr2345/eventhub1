const express = require("express");
const router = express.Router();
const mongoose = require("mongoose");
const Review = require("../models/Review");
const Registration = require("../models/Registration");
const Event = require("../models/Event");
const auth = require("../middleware/auth");
const createNotification = require("../utils/createNotification");
const User = require("../models/User");

// POST — создать отзыв (только attended студент)
router.post("/", auth, async (req, res) => {
  try {
    const { eventId, rating, comment } = req.body;

    if (req.user.role !== "student") {
      return res.status(403).json("Only students can leave reviews");
    }

    if (!eventId || !mongoose.Types.ObjectId.isValid(eventId)) {
      return res.status(400).json("Invalid eventId");
    }

    if (!rating || rating < 1 || rating > 5) {
      return res.status(400).json("Rating must be between 1 and 5");
    }

    // Проверяем что студент посетил мероприятие
    const registration = await Registration.findOne({
      userId: req.user.id,
      eventId,
      status: "attended"
    });

    if (!registration) {
      return res.status(403).json("You can only review events you attended");
    }

    // Проверяем что отзыв ещё не оставлен
    const existing = await Review.findOne({ eventId, userId: req.user.id });
    if (existing) {
      return res.status(400).json("You already reviewed this event");
    }

    const review = new Review({
      eventId,
      userId: req.user.id,
      rating,
      comment: comment || ""
    });

    await review.save();

    // ✅ Пересчитываем рейтинг в Event
    const allReviews = await Review.find({ eventId });
    const avg = allReviews.length
      ? allReviews.reduce((sum, r) => sum + r.rating, 0) / allReviews.length
      : 0;
    await Event.findByIdAndUpdate(eventId, {
      avgRating: Math.round(avg * 10) / 10,
      reviewCount: allReviews.length,
    });


    // Уведомляем организатора
    // Уведомляем организатора и всех админов
    try {
      const event = await Event.findById(eventId);
      if (event && event.organizerId) {
        // Организатору
        await createNotification(
          event.organizerId,
          "Новый отзыв",
          `Студент оставил отзыв на "${event.title}"`,
          { type: "newReview", eventId: event._id.toString(), reviewerId: req.user.id }
        );

        // Всем админам
        const admins = await User.find({ role: "admin" }).select("_id");
        for (const admin of admins) {
          // Не дублируем если организатор сам является админом
          if (admin._id.toString() === event.organizerId.toString()) continue;
          await createNotification(
            admin._id,
            "Новый отзыв",
            `Студент оставил отзыв на "${event.title}"`,
            { type: "newReview", eventId: event._id.toString(), reviewerId: req.user.id }
          );
        }
      }
    } catch (notifyErr) {
      console.log("NOTIFY ERROR:", notifyErr?.message ?? notifyErr);
    }

    const populated = await review.populate("userId", "name");
    res.json(populated);
  } catch (err) {
    if (err.code === 11000) {
      return res.status(400).json("You already reviewed this event");
    }
    res.status(500).json(err);
  }
});

// GET — получить отзывы по мероприятию
router.get("/event/:eventId", async (req, res) => {
  try {
    const reviews = await Review.find({ eventId: req.params.eventId })
      .populate("userId", "name")
      .sort({ createdAt: -1 });

    // Считаем среднюю оценку
    const avg = reviews.length
      ? reviews.reduce((sum, r) => sum + r.rating, 0) / reviews.length
      : 0;

    res.json({ reviews, avgRating: Math.round(avg * 10) / 10, total: reviews.length });
  } catch (err) {
    res.status(500).json(err);
  }
});

// GET — проверить может ли пользователь оставить отзыв
router.get("/can-review/:eventId", auth, async (req, res) => {
  try {
    const attended = await Registration.findOne({
      userId: req.user.id,
      eventId: req.params.eventId,
      status: "attended"
    });

    const alreadyReviewed = await Review.findOne({
      userId: req.user.id,
      eventId: req.params.eventId
    });

    res.json({
      canReview: !!attended && !alreadyReviewed,
      attended: !!attended,
      alreadyReviewed: !!alreadyReviewed
    });
  } catch (err) {
    res.status(500).json(err);
  }
});

module.exports = router;