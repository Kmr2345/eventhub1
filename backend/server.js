require("dotenv").config();
const express = require("express");
const mongoose = require("mongoose");
const cron = require("node-cron");
const cors = require("cors");
const path = require("path");
const multer = require("multer");
const auth = require("./middleware/auth");
const Event = require("./models/Event");
const Registration = require("./models/Registration");
const createNotification = require("./utils/createNotification");

const app = express();
app.use(cors({
  origin: "*",
  methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
  allowedHeaders: ["Content-Type", "Authorization"],
}));
app.use(express.json());


// Multer setup
// Cloudinary setup
const cloudinary = require('cloudinary').v2;
const { CloudinaryStorage } = require('multer-storage-cloudinary');

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key:    process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

const storage = new CloudinaryStorage({
  cloudinary,
  params: {
    folder: 'eventhub',
    allowed_formats: ['jpg', 'jpeg', 'png', 'webp'],
    transformation: [{ width: 1200, quality: 85, crop: 'limit' }],
  },
});

const upload = multer({
  storage,
  limits: { fileSize: 10 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    if (
      file.mimetype.startsWith('image/') ||
      file.mimetype === 'application/octet-stream' ||
      /\.(jpg|jpeg|png|gif|webp)$/i.test(file.originalname)
    ) cb(null, true);
    else cb(new Error('Only image files allowed'));
  },
});

// UPLOAD IMAGE
app.post('/upload', auth, upload.single('image'), (req, res) => {
  if (!req.file) return res.status(400).json({ message: 'No file uploaded' });
  // Cloudinary возвращает готовый URL в req.file.path
  res.json({ url: req.file.path });
});

// MongoDB
mongoose.connect(process.env.MONGO_URI)
  .then(() => console.log("MongoDB connected"))
  .catch(err => console.log(err));

// Routes
const authRoutes = require("./routes/auth");
app.use("/auth", authRoutes);

const eventRoutes = require("./routes/events");
app.use("/events", eventRoutes);

const registrationRoutes = require("./routes/registrations");
app.use("/registrations", registrationRoutes);

const favoriteRoutes = require("./routes/favorites");
app.use("/favorites", favoriteRoutes);

const notificationRoutes = require("./routes/notifications");
app.use("/notifications", notificationRoutes);

const adminRoutes = require("./routes/admin");
app.use("/admin", adminRoutes);

const reviewRoutes = require("./routes/reviews");
app.use("/reviews", reviewRoutes);

const profileRoutes = require("./routes/profile");
app.use("/profile", profileRoutes);

// Reminder cron (1 day before)
cron.schedule("0 * * * *", async () => {
  try {
    const now = new Date();
    const tomorrow = new Date(now);
    tomorrow.setDate(tomorrow.getDate() + 1);
    const day = createNotification.dayKey(tomorrow);

    const events = await Event.find({ eventDate: { $ne: null } }).select("_id title eventDate titleRu titleKz");

    for (const event of events) {
      const eventDate = new Date(event.eventDate);
      const diff = Math.abs(eventDate - tomorrow);

      if (diff < 1000 * 60 * 60 * 24) {
        const regs = await Registration.find({
          eventId: event._id,
          status: { $in: ["registered", "confirmed"] },
        }).select("userId");

        for (const r of regs) {
          await createNotification(
            r.userId,
            { ru: "Напоминание", kz: "Еске салу", en: "Reminder" },
            {
              ru: `Завтра: ${event.titleRu || event.title}`,
              kz: `Ертең: ${event.titleKz || event.title}`,
              en: `Tomorrow: ${event.title}`,
            },
            { type: "reminder1d", eventId: event._id, day }
          );
        }
      }
    }
  } catch (err) {
    console.log("CRON ERROR:", err?.message ?? err);
  }
});

app.get("/", (req, res) => {
  res.send("API running");
});

app.listen(process.env.PORT || 5000, () => {
  console.log(`Server started on port ${process.env.PORT || 5000}`);
});