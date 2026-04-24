const express = require("express");
const mongoose = require("mongoose");
const cron = require("node-cron");
const Event = require("./models/Event");
const Registration = require("./models/Registration");
const createNotification = require("./utils/createNotification");

const app = express(); //

app.use(express.json());

// MongoDB
mongoose.connect("mongodb://127.0.0.1:27017/eventhub")
  .then(() => console.log("MongoDB connected"))
  .catch(err => console.log(err));

// Routes
const authRoutes = require("./routes/auth");
app.use("/auth", authRoutes);

//events
const eventRoutes = require("./routes/events");

app.use("/events", eventRoutes);

//event registration
const registrationRoutes = require("./routes/registrations");

app.use("/registrations", registrationRoutes);

//favorites
const favoriteRoutes = require("./routes/favorites");
app.use("/favorites", favoriteRoutes);

//notifications
const notificationRoutes = require("./routes/notifications");
app.use("/notifications", notificationRoutes);

// Reminder cron (1 day before)
cron.schedule("0 * * * *", async () => {
  try {
    const now = new Date();
    const tomorrow = new Date(now);
    tomorrow.setDate(tomorrow.getDate() + 1);
    const day = createNotification.dayKey(tomorrow);

    const events = await Event.find({ eventDate: { $ne: null } }).select(
      "_id title eventDate"
    );

    for (const event of events) {
      const eventDate = new Date(event.eventDate);
      const diff = Math.abs(eventDate - tomorrow);

      // within 24h window relative to "tomorrow"
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
            {
              type: "reminder1d",
              eventId: event._id,
              day,
            }
          );
        }
      }
    }
  } catch (err) {
    console.log("CRON ERROR:", err?.message ?? err);
  }
});

// Test route
app.get("/", (req, res) => {
  res.send("API running");
});

// Server
app.listen(5000, () => {
  console.log("Server started on port 5000");
});