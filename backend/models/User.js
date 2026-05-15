const mongoose = require("mongoose");

const userSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true
  },
  email: {
    type: String,
    required: true,
    unique: true
  },
  password: {
    type: String,
    required: true
  },
  role: {
    type: String,
    enum: ["student", "organizer", "admin"],
    default: "student"
  },
  isVerified: {
    type: Boolean,
    default: false
  },
  verifyCode: {
    type: String,
    default: null
  },
  verifyCodeExpires: {
      type: Date,
      default: null,
      expires: 600
    }
}, { timestamps: true });

module.exports = mongoose.model("User", userSchema);