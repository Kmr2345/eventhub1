const express = require("express");
const mongoose = require("mongoose");

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

// Test route
app.get("/", (req, res) => {
  res.send("API running");
});

// Server
app.listen(5000, () => {
  console.log("Server started on port 5000");
});