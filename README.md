# EventHub — Student Events App

Мобильное приложение для управления студенческими мероприятиями.  
Дипломный проект, Astana IT University.

## Стек технологий

- **Frontend:** Flutter (Dart)
- **Backend:** Node.js + Express
- **База данных:** MongoDB Atlas
- **Авторизация:** JWT

## Функциональность

- Регистрация и авторизация (student / organizer / admin)
- Просмотр и поиск мероприятий
- Запись на мероприятия с QR-кодом
- Сканер QR для отметки посещаемости
- Избранное, уведомления, отзывы и рейтинг
- Мультиязычность: RU / KZ / EN

## Запуск backend

1. Перейди в корень проекта
2. Создай файл `backend/.env` по образцу `backend/.env.example`
3. Установи зависимости и запусти сервер:

```bash
npm install
node backend/server.js
```

## Запуск Flutter

```bash
flutter pub get
flutter run
```