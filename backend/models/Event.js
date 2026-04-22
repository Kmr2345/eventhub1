const mongoose = require("mongoose");

const eventSchema = new mongoose.Schema({
  title: {
    type: String,
    required: true
  },
  description: String,
  eventDate: Date,
  location: String,
  category: String,
  capacity: Number,
  registeredCount: {
    type: Number,
    default: 0
  },
  organizerId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User"
  },
  isCompleted: {
    type: Boolean,
    default: false
  },
  photos: [String]
}, { timestamps: true });

module.exports = mongoose.model("Event", eventSchema);