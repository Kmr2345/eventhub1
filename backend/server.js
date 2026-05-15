const express = require("express");
const mongoose = require("mongoose");
const cron = require("node-cron");
const cors = require("cors");
const Event = require("./models/Event");
const Registration = require("./models/Registration");
const createNotification = require("./utils/createNotification");

const app = express();
app.use(cors());
app.use(express.json());

// MongoDB
mongoose.connect("mongodb://kunshuak06_db_user:57In2m69XsT4NExt@ac-8pbn1os-shard-00-00.x2otkv6.mongodb.net:27017,ac-8pbn1os-shard-00-01.x2otkv6.mongodb.net:27017,ac-8pbn1os-shard-00-02.x2otkv6.mongodb.net:27017/eventhub?ssl=true&replicaSet=atlas-115kpv-shard-0&authSource=admin&appName=Eventhub")
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

// Reminder cron (1 day before)
cron.schedule("0 * * * *", async () => {
  try {
    const now = new Date();
    const tomorrow = new Date(now);
    tomorrow.setDate(tomorrow.getDate() + 1);
    const day = createNotification.dayKey(tomorrow);

    const events = await Event.find({ eventDate: { $ne: null } }).select("_id title eventDate");

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
            "Напоминание",
            `Завтра: ${event.title}`,
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

app.listen(5000, () => {
  console.log("Server started on port 5000");
});