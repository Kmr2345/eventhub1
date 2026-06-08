const express = require("express");
const router = express.Router();
const mongoose = require("mongoose");
const Registration = require("../models/Registration");
const Event = require("../models/Event");
const User = require("../models/User");
const auth = require("../middleware/auth");
const createNotification = require("../utils/createNotification");

// REGISTER TO EVENT
router.post("/", auth, async (req, res) => {
  try {
    const { eventId } = req.body;

    console.log("REGISTER:", req.user.id, eventId);
    if (req.user.role === "organizer") {
      return res.status(403).json("Organizers cannot register for events");
    }

    if (!eventId || !mongoose.Types.ObjectId.isValid(eventId)) {
      return res.status(400).json("Invalid eventId");
    }

    const eventObjectId = new mongoose.Types.ObjectId(eventId);

    const event = await Event.findById(eventObjectId);
    if (!event) return res.status(404).json("Event not found");

    if (event.eventDate && new Date(event.eventDate) < new Date()) {
      return res.status(400).json("Registration is closed — event has already passed");
    }
    if (event.capacity && event.registeredCount >= event.capacity) {
      return res.status(400).json("No spots left — event is full");
    }

    let registration = await Registration.findOne({
      userId: req.user.id,
      eventId: eventObjectId
    });

    console.log("FOUND:", registration);

    if (registration && registration.status === "cancelled") {
      registration.status = "registered";
      await registration.save();
      await Event.findByIdAndUpdate(eventObjectId, { $inc: { registeredCount: 1 } });
      return res.json(registration);
    }

    if (registration && ["registered", "confirmed"].includes(registration.status)) {
      return res.status(400).json("Already registered");
    }

    registration = new Registration({
      userId: req.user.id,
      eventId: eventObjectId,
      status: "registered"
    });

    await registration.save();
    await Event.findByIdAndUpdate(eventObjectId, { $inc: { registeredCount: 1 } });

    // Уведомляем организатора о новой регистрации
    try {
      const student = await User.findById(req.user.id).select("name");
      const studentName = student?.name ?? "Студент";
      if (event && event.organizerId) {
        await createNotification(
          event.organizerId,
          { ru: "Новая регистрация", kz: "Жаңа тіркелу", en: "New Registration" },
          {
            ru: `${studentName} зарегистрировался на «${event.titleRu || event.title}»`,
            kz: `${studentName} «${event.titleKz || event.title}» іс-шарасына тіркелді`,
            en: `${studentName} registered for «${event.title}»`,
          },
          { type: "newRegistration", eventId: eventObjectId.toString() }
        );
      }
    } catch (notifyErr) {
      console.log("NOTIFY ERROR:", notifyErr?.message ?? notifyErr);
    }

    return res.json(registration);
  } catch (err) {
    console.log("ERROR:", err);
    return res.status(500).json(err);
  }
});

// CONFIRM ATTENDANCE
router.put("/:id/confirm", auth, async (req, res) => {
  try {
    const registration = await Registration.findById(req.params.id);
    if (!registration) return res.status(404).json("Registration not found");
    if (registration.userId.toString() !== req.user.id) return res.status(403).json("Not allowed");
    registration.status = "confirmed";
    await registration.save();
    res.json(registration);
  } catch (err) {
    res.status(500).json(err);
  }
});

// CANCEL
router.put("/:id/cancel", auth, async (req, res) => {
  try {
    const id = req.params.id;
    console.log("CANCEL REQUEST ID:", id);

    const registration = await Registration.findById(id);
    if (!registration) {
      console.log("NOT FOUND");
      return res.status(404).json("Registration not found");
    }

    registration.status = "cancelled";
    await registration.save();
    await Event.findByIdAndUpdate(registration.eventId, { $inc: { registeredCount: -1 } });

    console.log("AFTER UPDATE:", registration.status);

    // Уведомляем организатора об отмене
    try {
      const student = await User.findById(registration.userId).select("name");
      const studentName = student?.name ?? "Студент";
      const event = await Event.findById(registration.eventId);
      if (event && event.organizerId) {
        await createNotification(
          event.organizerId,
          { ru: "Отмена регистрации", kz: "Тіркелуді болдырмау", en: "Registration Cancelled" },
          {
            ru: `${studentName} отменил регистрацию на «${event.titleRu || event.title}»`,
            kz: `${studentName} «${event.titleKz || event.title}» іс-шарасынан тіркелуін болдырмады`,
            en: `${studentName} cancelled registration for «${event.title}»`,
          },
          { type: "cancelRegistration", eventId: registration.eventId.toString() }
        );
      }
    } catch (notifyErr) {
      console.log("NOTIFY ERROR:", notifyErr?.message ?? notifyErr);
    }

    return res.json(registration);
  } catch (err) {
    console.log("CANCEL ERROR:", err);
    return res.status(500).json(err);
  }
});

// MARK AS ATTENDED (organizer/admin)
router.put("/:id/attended", auth, async (req, res) => {
  try {
    const registration = await Registration.findById(req.params.id).populate("eventId");
    if (!registration) return res.status(404).json("Registration not found");
    if (!["organizer", "admin"].includes(req.user.role)) {
      return res.status(403).json("Only organizer or admin can mark attendance");
    }

    const event = registration.eventId;
    if (event && event.eventDate) {
      const eventDay = new Date(event.eventDate);
      eventDay.setHours(0, 0, 0, 0);
      if (new Date() < eventDay) {
        return res.status(400).json("Cannot mark attendance before event day");
      }
    }

    if (registration.status === "attended") {
      return res.status(409).json("Already attended");
    }

    if (!["registered", "confirmed"].includes(registration.status)) {
      return res.status(400).json("Registration is not active");
    }

    registration.status = "attended";
    await registration.save();

    // Уведомление студенту — оцените мероприятие
    try {
      const eventTitle = event?.title ?? "мероприятие";
      const eventTitleRu = event?.titleRu || eventTitle;
      const eventTitleKz = event?.titleKz || eventTitle;
      const eventId = event?._id ?? registration.eventId;
      await createNotification(
        registration.userId,
        { ru: "Оцените мероприятие", kz: "Іс-шараны бағалаңыз", en: "Rate the Event" },
        {
          ru: `Вы посетили «${eventTitleRu}». Оставьте оценку и отзыв!`,
          kz: `Сіз «${eventTitleKz}» іс-шарасына қатыстыңыз. Баға қалдырыңыз!`,
          en: `You attended «${eventTitle}». Leave a rating and review!`,
        },
        { type: "reviewRequest", eventId: eventId.toString() }
      );
    } catch (notifyErr) {
      console.log("NOTIFY ERROR:", notifyErr?.message ?? notifyErr);
    }

    res.json(registration);
  } catch (err) {
    res.status(500).json(err);
  }
});

// GET MY REGISTRATIONS
router.get("/my", auth, async (req, res) => {
  const regs = await Registration.find({ userId: req.user.id }).populate("eventId");
  res.json(regs);
});

// GET REGISTRATIONS BY EVENT (organizer/admin only)
router.get("/event/:eventId", auth, async (req, res) => {
  try {
    if (!["organizer", "admin"].includes(req.user.role)) {
      return res.status(403).json("Not allowed");
    }
    const regs = await Registration.find({ eventId: req.params.eventId })
      .populate("userId", "name email");
    res.json(regs);
  } catch (err) {
    res.status(500).json(err);
  }
});

module.exports = router;