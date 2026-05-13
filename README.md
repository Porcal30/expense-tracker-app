# 💰 Expense Tracker App

A secure and modern Flutter-based Expense Tracker application that helps users manage their daily expenses, monitor spending habits, and visualize financial data through charts and analytics.

---

# 📱 Project Description

Expense Tracker App is a mobile application developed using Flutter and Dart. The app allows users to record expenses, organize transactions into categories, set weekly and monthly budgets, manage recurring expenses, and analyze spending patterns through graphical reports.

The application also focuses on security by implementing secure authentication, encrypted local storage, PIN protection, and Firebase integration.

---

# ✨ Features

## Core Features

- Add new expenses
- Edit and delete transactions
- Expense categorization
- View transaction history
- Financial summary dashboard
- Charts and analytics
- Weekly budgeting system
- Monthly budgeting system
- Recurring expenses management
- Expense tracking and monitoring
- Budget progress tracking
- Secure login authentication
- PIN security protection
- Responsive and modern UI

## Security Features

- Firebase Authentication
- Encrypted local storage using FlutterSecureStorage
- PIN hashing using Crypto package
- Secure logout functionality
- Input validation
- HTTPS-secured Firebase communication
- Biometric/device authentication support

## Additional Features

- State management using Provider
- Animations for smoother user experience
- Local persistence using SharedPreferences
- Cross-platform Flutter support

---

# 🛠 Technologies Used

## Frontend

- Flutter
- Dart

## State Management

- Provider

## Backend & Database

- Firebase Authentication
- Cloud Firestore

## Security

- Flutter Secure Storage
- Crypto
- Local Authentication

## UI & Utilities

- fl_chart
- intl
- animations
- uuid

---

# 📂 Project Structure

```plaintext
lib/
├── core/
├── data/
├── providers/
├── screens/
├── widgets/
├── app.dart
├── firebase_options.dart
└── main.dart
```

---

## 🔒 Security Checklist

### DATA ENCRYPTION

| Security Item | Status | Week |
|---|---|---|
| HTTPS used for all API calls (not HTTP) | ✅ | Week 7 |
| Sensitive data encrypted at rest (FlutterSecureStorage) | ✅ | Week 8 |
| No sensitive data in SharedPreferences | ✅ | Week 8 |
| Passwords hashed, never stored plain text | ✅ | Week 8 |

---

### AUTHENTICATION

| Security Item | Status | Week |
|---|---|---|
| JWT tokens stored in secure storage | ✅ | Week 7 |
| Token refresh mechanism implemented | ✅ | Week 7 |
| Logout clears all sensitive data | ✅ | Week 9 |
| Session timeout implemented | ✅ | Week 9 |

---

### INPUT VALIDATION

| Security Item | Status | Week |
|---|---|---|
| All user inputs validated | ✅ | Week 6 |
| Email format validation | ✅ | Week 6 |
| Password strength requirements enforced | ✅ | Week 6 |
| Input sanitization (XSS prevention) | ✅ | Week 11 |

---

### FIREBASE SECURITY

| Security Item | Status | Week |
|---|---|---|
| Security rules NOT in test mode | ✅ | Week 10 |
| User can only access their own data | ✅ | Week 10 |
| Data validation rules in place | ✅ | Week 10 |

---

### CODE SECURITY

| Security Item | Status | Week |
|---|---|---|
| No API keys hardcoded in source | ✅ | Week 7 |
| No passwords/secrets in code | ✅ | Week 7 |
| Debug logs removed (print statements) | ✅ | Week 11 |
| Error messages don't expose internals | ✅ | Week 7 |

---

### TESTING

| Security Item | Status | Week |
|---|---|---|
| Security functions have unit tests | ✅ | Week 11 |
| Validation functions tested | ✅ | Week 11 |
| Edge cases and error conditions tested | ✅ | Week 11 |

## Security Implementation Summary

The application protects sensitive financial information using Firebase Authentication, encrypted local storage, session locking, biometric authentication, and PIN hashing. Sensitive user credentials are never stored in plain text, and secure logout clears session-related data from memory and device storage.

Security mechanisms include SHA-256 PIN hashing, FlutterSecureStorage encryption, Firebase secure authentication tokens, user-scoped secure storage keys, session timeout handling, and protected Firebase Firestore access rules.
---

# 🚀 Why Flutter? (Course Goal 2)

Flutter was chosen for this project because:

- Flutter allows cross-platform development using a single codebase.
- Hot reload speeds up testing and UI development.
- Flutter widgets make it easier to create responsive and modern interfaces.
- Provider simplifies state management.
- Flutter integrates smoothly with Firebase services.
- Dart provides strong typing and excellent asynchronous programming support.

Flutter helped accelerate development while maintaining performance and UI consistency.

---

# 📸 Screenshots

Include screenshots of the following screens:

1. Login Screen
2. Dashboard Screen
3. Add Expense Screen
4. Transaction History Screen
5. Analytics/Charts Screen
6. Security/PIN Screen

---

# ⚙️ Setup Instructions

## Clone Repository

```bash
git clone https://github.com/Porcal30/expense_tracker_app.git
```

## Navigate to Project Folder

```bash
cd expense_tracker_app
```

## Install Dependencies

```bash
flutter pub get
```

## Run the Application

```bash
flutter run
```

---

# 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter

  provider: ^6.1.2
  firebase_core: ^3.13.0
  firebase_auth: ^5.5.3
  cloud_firestore: ^5.6.7
  shared_preferences: ^2.5.3
  flutter_secure_storage: ^9.2.2
  crypto: ^3.0.3
  intl: ^0.20.2
  uuid: ^4.5.1
  fl_chart: ^0.68.0
  local_auth: ^2.3.0
  animations: ^2.0.11
```

---

# 📱 Release Build

## Build APK

```bash
flutter build apk --release
```

## Build App Bundle

```bash
flutter build appbundle --release
```

---

# 🧪 Testing

The application was tested for:

- Form validation
- Secure login/logout
- Expense CRUD operations
- Firebase connectivity
- Local storage functionality
- Responsive UI behavior
- Error handling

---

# 📋 Documentation Checklist

| Requirement | Status |
|-------------|--------|
| Multiple screens with navigation | ✅ |
| Form validation | ✅ |
| State management using Provider | ✅ |
| Data persistence | ✅ |
| Security implementation | ✅ |
| Organized project structure | ✅ |
| Release build support | ✅ |

---

# 🎥 Presentation Guide

## Introduction

- Introduce the Expense Tracker App
- Explain the target users and purpose

## Demonstration

- Show login/authentication
- Add and manage expenses
- Display analytics and charts
- Demonstrate security features

## Security Features

- Explain encrypted storage
- Explain PIN hashing and authentication
- Discuss secure Firebase integration

## Why Flutter?

- Cross-platform development
- Fast development using hot reload
- Beautiful and responsive UI system

---

# 👨‍💻 Author

**GROUP 2**  
BSIT - Integrative Programming 2

---

# 📌 Future Improvements

- Dark mode support
- Budget goals and notifications
- Export reports to PDF
- Offline synchronization
- Multi-device syncing
- AI-based spending analysis

---

# 📄 License

This project is for educational purposes only.
