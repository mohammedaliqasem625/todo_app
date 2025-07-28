# 📝 To-Do App (Flutter)

A simple yet powerful to-do list app built with Flutter, supporting:

- ✅ Task creation & deletion
- 🎯 Category filtering & searching
- 🌗 Light & dark mode toggle
- ⏰ Local notifications for reminders
- 🌐 Multi-language support (English / Arabic)
- 💾 Persistent storage using Hive

---

## 📸 Screenshots

| Light Mode 🇬🇧 | Dark Mode 🇸🇦 |
|---------------|--------------|
| ![Light](assets/screenshots/light_en.png) | ![Dark](assets/screenshots/dark_ar.png) |

---

## 🌍 Language Support

- 🇬🇧 English  
- 🇸🇦 Arabic (العربية)

You can switch languages inside the app using the language selector in the top right corner.

---

## 🔧 Features

- Add, edit and delete tasks easily
- Filter by category: Work, Personal, Study, etc.
- Mark tasks as **done**
- Theme switching between light & dark
- Reminder notifications using `flutter_local_notifications`
- Localization with ARB & `flutter_gen`

---

## 🚀 Getting Started

To run this project:

```bash
git clone https://github.com/mohammedaliqasem625/todo_app.git
cd todo_app
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
