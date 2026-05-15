const express = require("express");
const router = express.Router();
const User = require("../models/User");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const sendVerificationEmail = require("../utils/sendEmail");

function generateCode() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

function isValidEmail(email) {
  const regex = /^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$/;
  if (!regex.test(email)) return false;
  const parts = email.split('@');
  const local = parts[0];
  const domain = parts[1];
  if (local.startsWith('.') || local.endsWith('.')) return false;
  if (local.includes('..') || domain.includes('..')) return false;
  return true;
}

// REGISTER — создаёт аккаунт и отправляет код
router.post("/register", async (req, res) => {
  try {
    const { name, email, password, role } = req.body;

    if (!name || !email || !password) {
      return res.status(400).json({ message: "All fields required" });
    }

    if (!isValidEmail(email)) {
      return res.status(400).json({ message: "Invalid email format" });
    }

    const existingUser = await User.findOne({ email });
    if (existingUser && existingUser.isVerified) {
      return res.status(400).json({ message: "User already exists" });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const code = generateCode();
    const expires = new Date(Date.now() + 10 * 60 * 1000); // 10 минут

    if (existingUser && !existingUser.isVerified) {
      // Обновляем код если уже регистрировался но не подтвердил
      existingUser.name = name;
      existingUser.password = hashedPassword;
      existingUser.verifyCode = code;
      existingUser.verifyCodeExpires = expires;
      await existingUser.save();
    } else {
      await User.create({
        name,
        email,
        password: hashedPassword,
        role: role || "student",
        isVerified: false,
        verifyCode: code,
        verifyCodeExpires: expires,
      });
    }

    await sendVerificationEmail(email, code);

    res.json({ message: "Code sent", email });
  } catch (err) {
    console.error("REGISTER ERROR:", err);
    res.status(500).json({ error: err.message });
  }
});

// VERIFY — проверяет код и активирует аккаунт
router.post("/verify", async (req, res) => {
  try {
    const { email, code } = req.body;

    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ message: "User not found" });

    if (user.isVerified) {
      return res.status(400).json({ message: "Already verified" });
    }

    if (!user.verifyCode || user.verifyCode !== code) {
      return res.status(400).json({ message: "Invalid code" });
    }

    if (new Date() > new Date(user.verifyCodeExpires)) {
      return res.status(400).json({ message: "Code expired" });
    }

    user.isVerified = true;
    user.verifyCode = null;
    user.verifyCodeExpires = null;
    await user.save();

    const token = jwt.sign(
      { id: user._id, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: "7d" }
    );

    const userObj = user.toObject();
    delete userObj.password;
    delete userObj.verifyCode;
    delete userObj.verifyCodeExpires;

    res.json({ token, user: userObj });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// RESEND — повторная отправка кода
router.post("/resend-code", async (req, res) => {
  try {
    const { email } = req.body;

    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ message: "User not found" });
    if (user.isVerified) return res.status(400).json({ message: "Already verified" });

    const code = generateCode();
    user.verifyCode = code;
    user.verifyCodeExpires = new Date(Date.now() + 10 * 60 * 1000);
    await user.save();

    await sendVerificationEmail(email, code);
    res.json({ message: "Code resent" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// LOGIN
router.post("/login", async (req, res) => {
  try {
    const { email, password } = req.body;

    const user = await User.findOne({ email });
    if (!user) {
      return res.status(400).json({ message: "User not found" });
    }

    if (!user.isVerified) {
      return res.status(403).json({ message: "Email not verified", needVerify: true, email });
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(400).json({ message: "Invalid credentials" });
    }

    const token = jwt.sign(
      { id: user._id, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: "7d" }
    );

    const userObj = user.toObject();
    delete userObj.password;
    delete userObj.verifyCode;
    delete userObj.verifyCodeExpires;

    res.json({ token, user: userObj });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;