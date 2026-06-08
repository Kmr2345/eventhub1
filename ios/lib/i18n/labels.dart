const labels = {
  'registered': {
    'ru': 'Вы зарегистрированы',
    'kz': 'Сіз тіркелдіңіз',
    'en': 'Registered',
  },
};

String getLabel(String key, String lang) {
  final entry = labels[key];
  if (entry == null) return key;
  return entry[lang] ?? entry['en'] ?? key;
}

