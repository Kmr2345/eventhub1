const Map<String, Map<String, String>> messages = {
  "registerSuccess": {
    "ru": "Регистрация успешна",
    "kz": "Тіркелу сәтті өтті",
    "en": "Registration successful",
  },
  "eventRegistered": {
    "ru": "Вы записались на мероприятие",
    "kz": "Сіз іс-шараға тіркелдіңіз",
    "en": "You registered for the event",
  },
  "eventCancelled": {
    "ru": "Регистрация отменена",
    "kz": "Тіркелу тоқтатылды",
    "en": "Registration cancelled",
  },
  "favoriteAdded": {
    "ru": "Добавлено в избранное",
    "kz": "Таңдаулыларға қосылды",
    "en": "Added to favorites",
  },
  "favoriteRemoved": {
    "ru": "Удалено из избранного",
    "kz": "Таңдаулылардан өшірілді",
    "en": "Removed from favorites",
  },

  // Common app messages
  "loginFirst": {
    "ru": "Сначала войдите в аккаунт",
    "kz": "Алдымен аккаунтқа кіріңіз",
    "en": "Please login first",
  },
  "registrationNotFound": {
    "ru": "Регистрация на это мероприятие не найдена",
    "kz": "Бұл іс-шараға тіркелу табылмады",
    "en": "Registration not found for this event",
  },
  "eventCreated": {
    "ru": "Событие создано",
    "kz": "Іс-шара жасалды",
    "en": "Event created",
  },
  "enterTitle": {
    "ru": "Введите название",
    "kz": "Атауын енгізіңіз",
    "en": "Enter title",
  },
  "attendanceMarked": {
    "ru": "Пользователь отмечен как пришедший",
    "kz": "Қатысушы келді деп белгіленді",
    "en": "User marked as attended",
  },
  "attendanceError": {
    "ru": "Ошибка при отметке посещения",
    "kz": "Қатысуды белгілеу қатесі",
    "en": "Error marking attendance",
  },
};

String getMessage(String key, String lang) {
  return messages[key]?[lang] ?? messages[key]?['en'] ?? key;
}

