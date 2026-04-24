const Map<String, Map<String, String>> errorTexts = {
  "emptyEmail": {
    "ru": "Введите email",
    "kz": "Email енгізіңіз",
    "en": "Enter email",
  },
  "emptyPassword": {
    "ru": "Введите пароль",
    "kz": "Құпия сөзді енгізіңіз",
    "en": "Enter password",
  },
  "invalidEmail": {
    "ru": "Некорректный email",
    "kz": "Email қате",
    "en": "Invalid email",
  },
  "weakPassword": {
    "ru": "Пароль должен быть не менее 6 символов",
    "kz": "Құпия сөз кемінде 6 таңба болуы керек",
    "en": "Password must be at least 6 characters",
  },
  "userNotFound": {
    "ru": "Пользователь не найден",
    "kz": "Пайдаланушы табылмады",
    "en": "User not found",
  },
  "wrongPassword": {
    "ru": "Неверный пароль",
    "kz": "Құпия сөз қате",
    "en": "Wrong password",
  },
  "networkError": {
    "ru": "Нет подключения к интернету",
    "kz": "Интернет жоқ",
    "en": "No internet connection",
  },
  "serverError": {
    "ru": "Ошибка сервера",
    "kz": "Сервер қатесі",
    "en": "Server error",
  },
};

String getError(String key, String lang) {
  return errorTexts[key]?[lang] ?? errorTexts[key]?['en'] ?? key;
}

