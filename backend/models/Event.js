const mongoose = require("mongoose");

const eventSchema = new mongoose.Schema({
  title: {
    type: String,
    required: true
  },
  titleRu: String,
  titleKz: String,
  description: String,
  descriptionRu: String,
  descriptionKz: String,
  eventDate: Date,
  location: String,
  locationRu: String,
  locationKz: String,
  category: String,
  image: String,
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
  photos: [String],

  avgRating: {
    type: Number,
    default: 0
  },
  reviewCount: {
    type: Number,
    default: 0
  }
}, { timestamps: true });

module.exports = mongoose.model("Event", eventSchema);