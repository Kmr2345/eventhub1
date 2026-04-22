const mongoose = require("mongoose");

const registrationSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User"
  },
  eventId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Event"
  },
  status: {
    type: String,
    enum: ["registered", "confirmed", "attended", "cancelled"],
    default: "registered"
  }
}, { timestamps: true });

module.exports = mongoose.model("Registration", registrationSchema);