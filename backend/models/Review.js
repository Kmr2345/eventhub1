const mongoose = require("mongoose");

const reviewSchema = new mongoose.Schema({
  eventId: { type: mongoose.Schema.Types.ObjectId, ref: "Event", required: true },
  userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
  rating: { type: Number, required: true, min: 1, max: 5 },
  comment: { type: String, default: "" },
}, { timestamps: true });

// Один отзыв на одно мероприятие от одного пользователя
reviewSchema.index({ eventId: 1, userId: 1 }, { unique: true });

module.exports = mongoose.model("Review", reviewSchema);