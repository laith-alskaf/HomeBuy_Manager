<div align="center">

<img src="assets/icon/icon-splash.png" alt="Radar Al-Masrouf Logo" width="120" />

# 🏠 Radar Al-Masrouf

### The All-in-One Personal Finance Manager for Arabic-Speaking Families

[![Flutter](https://img.shields.io/badge/Flutter-v3.10%2B-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0%2B-00B4AB?logo=dart&logoColor=white)](https://dart.dev)
[![Version](https://img.shields.io/badge/Version-5.1.0-brightgreen)](pubspec.yaml)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-black?logo=android&logoColor=white)](https://flutter.dev)
[![Offline](https://img.shields.io/badge/Offline--First-100%25-success)](https://flutter.dev)

[Features](#-features) • [Tech Stack](#-tech-stack) • [Architecture](#-architecture) • [Getting Started](#-getting-started) • [Download](#-download) • [Contributing](#-contributing)

</div>

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [Tech Stack](#-tech-stack)
- [Architecture](#-architecture)
- [Getting Started](#-getting-started)
- [Backup System](#-backup-system)
- [Security & Privacy](#-security--privacy)
- [Download](#-download)
- [Contributing](#-contributing)
- [License](#-license)

---

## 📖 Overview

**Radar Al-Masrouf** (رادار المصروف) is a comprehensive, offline-first personal finance application built with Flutter. Designed specifically for Arabic-speaking households, it brings together all critical aspects of personal finance into a single, intuitive interface — from daily shopping tracking to long-term savings goals.

> **100% Offline-First** — All your data stays on your device. No servers, no cloud sync, no data collection.

The app covers the full spectrum of personal financial management:
- 🛍️ Smart shopping list tracking with price history
- 💰 Multi-currency wallet management (SYP, USD, EUR, SAR, AED)
- 📊 Monthly budgets with real-time overspending alerts
- 📄 Recurring bills and subscription tracking
- 🏦 Debt management with wallet integration
- 🎯 Savings goals with visual progress tracking
- 🔐 Smart Vault with automated saving rules
- 📂 Professional backup and data restore system

---

## ✨ Features

### 🏦 1. Central Wallet & Multi-Currency Support
- Manage multiple currency balances (SYP, USD, EUR, SAR, AED) from a single dashboard.
- Full transaction history with per-entry categorization.
- Instant in-app currency exchange with automatic balance updates.

### 🛍️ 2. Smart Shopping Radar
- 12 built-in categories plus fully customizable categories with unique icons and colors.
- **Price Memory**: The app remembers the last recorded price for every item to help you make smarter purchase decisions.
- Budget-aware alerts that trigger instantly when an item would exceed your category budget.

### 📄 3. Bills & Recurring Commitments Manager
- Track subscriptions, rent, utilities, and any recurring payment (daily, weekly, or monthly).
- **Pay Now / Skip** flow with a full undo mechanism that reverses the charge back to your wallet.
- Automatic deduction from the correct wallet currency on payment.

### 💸 4. Side Balance
- A separate financial pocket for money you don't want mixed with your daily spending.
- Full multi-currency support.
- One-tap transfer to your main wallet when needed.

### 🎯 5. Savings Goals
- Create named savings goals (e.g., "New Phone," "Family Trip," "Home Renovation").
- Visual progress bar showing percentage completed.
- Detailed deposit history per goal.

### 📊 6. Financial Analytics
- Month-over-month spending comparison reports.
- Interactive pie and bar charts for expense distribution by category.
- Automatic carry-over calculation for unspent monthly budgets.

### 🔐 7. Smart Vault
- Rule-based automated saving (e.g., save a fixed amount on a schedule).
- Manual top-up support.
- Multi-currency vault balance tracking.

### 💳 8. Debt Manager
- Track money you owe and money owed to you.
- Direct integration with wallet: settling a debt automatically updates the correct currency balance.
- Full debt history per contact.

### 💾 9. Professional Backup System
- **Manual Export**: Export all your data as a portable `.json` file to share or store anywhere.
- **Auto Backup**: Periodic automatic backups to prevent any data loss.
- **One-Tap Restore**: Restore your full financial history from any backup file instantly.

---

## 🛠️ Tech Stack

| Category | Technology | Version |
|---|---|---|
| **Framework** | Flutter | 3.10.4+ |
| **Language** | Dart | 3.0+ |
| **Local Storage** | SharedPreferences (JSON) | 2.4.0 |
| **Database (Ready)** | Hive | 2.2.3 |
| **Charts** | fl_chart | 1.1.1 |
| **Typography** | Google Fonts (Outfit, Tajawal) | 8.0.2 |
| **Notifications** | flutter_local_notifications | 21.0.0 |
| **Remote Config** | Firebase Remote Config | 5.2.0 |
| **File Handling** | file_picker, share_plus | 10.x / 12.x |
| **Splash Screen** | flutter_native_splash | 2.4.7 |
| **Internationalization** | flutter_localizations, intl | SDK / 0.20.2 |

---

## 🏗️ Architecture

The project follows a **Clean Architecture** pattern adapted for Flutter, ensuring clear separation of concerns, testability, and maintainability.

```
lib/
├── config/                     # App-wide theme and configuration
│   └── app_theme.dart
│
├── core/                       # Shared utilities, constants, and helpers
│
├── data/                       # Data Layer
│   ├── models/                 # Data models (Shopping, Wallet, Debt, Goals, etc.)
│   ├── repositories/           # Repository implementations
│   └── services/               # Raw data access (LocalStorageService)
│
├── domain/                     # Domain Layer
│   └── repositories/           # Abstract repository interfaces (contracts)
│
├── services/                   # Business Logic Services
│   ├── backup_service.dart     # Import / Export / Auto-backup logic
│   ├── budget_service.dart     # Budget calculation and alert logic
│   ├── categories_service.dart # Category management
│   ├── currency_service.dart   # Currency exchange logic
│   ├── notification_service.dart
│   ├── firebase_notification_service.dart
│   └── remote_config_service.dart
│
├── presentation/               # Presentation Layer (UI)
│   ├── pages/                  # Full screens
│   │   ├── home_page.dart
│   │   ├── analytics_screen.dart
│   │   ├── bills_manager_screen.dart
│   │   ├── debt_manager_screen.dart
│   │   ├── goals_screen.dart
│   │   ├── side_balance_screen.dart
│   │   ├── smart_vault_screen.dart
│   │   ├── backup_screen.dart
│   │   ├── settings_page.dart
│   │   └── ...
│   ├── widgets/                # Reusable UI components
│   ├── dialogs/                # Modal dialogs and confirmation sheets
│   └── sheets/                 # Bottom sheets
│
├── utils/                      # Utility functions and extensions
│
└── main.dart                   # App entry point & initialization
```

### Initialization Strategy

The app uses a **non-blocking startup** pattern. Firebase services and auto-backup run as background microtasks, ensuring the UI is always responsive from the first frame.

```
App Launch
    │
    ├─► Firebase.initializeApp()
    │
    ├─► Background (non-blocking):
    │       ├─ FirebaseNotificationService.initialize()
    │       └─ RemoteConfigService.initialize()
    │
    └─► UI: LandingScreen (first launch) → HomePage
```

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) **v3.10.0 or later**
- An Android emulator or physical Android / iOS device
- [Git](https://git-scm.com/)

### Installation

**1. Clone the repository**
```bash
git clone https://github.com/laith-alskaf/HomeBuy_Manager.git
cd HomeBuy_Manager
```

**2. Install dependencies**
```bash
flutter pub get
```

**3. Run the application**
```bash
flutter run
```

### Build for Production

```bash
# Android APK
flutter build apk --release

# Android App Bundle (recommended for Play Store)
flutter build appbundle --release

# iOS (requires macOS with Xcode)
flutter build ios --release
```

---

## 💾 Backup System

Radar Al-Masrouf provides a robust, three-mode backup system to ensure your financial data is always safe:

| Mode | Description |
|---|---|
| **Manual Export** | Export all data as a `.json` file to any storage location or share via any app. |
| **Auto Backup** | App automatically creates periodic backups in the background without interrupting the user. |
| **One-Tap Restore** | Import any previously exported `.json` backup file to fully restore your financial history. |

> **Note:** Backups are stored locally. No data is ever sent to any external server.

---

## 🔒 Security & Privacy

| Guarantee | Details |
|---|---|
| **100% Offline** | No internet connection is required for any core feature. Your data never leaves your device. |
| **No Tracking** | Zero analytics, zero telemetry, zero personal data collection. |
| **Local Storage Only** | All financial data is stored locally on the device using SharedPreferences and Hive. |
| **No Account Required** | The app works fully without any sign-up or login. |

> Firebase is used **only** for Remote Config (app-level configuration) and optional push notifications. No user financial data is ever sent to Firebase.

---

## 🗺️ Roadmap

- [ ] Hive migration for improved performance and query capabilities
- [ ] Dark Mode support
- [ ] Widget support for home screen balance overview
- [ ] CSV export for spreadsheet compatibility
- [ ] iOS TestFlight release
- [ ] Recurring bill smart reminders

---

## 🤝 Contributing

Contributions are welcome and appreciated! Here's how to get started:

1. **Fork** the repository.
2. **Create** a new branch: `git checkout -b feature/your-feature-name`
3. **Commit** your changes: `git commit -m 'feat: add your feature description'`
4. **Push** to the branch: `git push origin feature/your-feature-name`
5. **Open** a Pull Request.

Please follow the existing code style and include relevant tests or screenshots where applicable.

---

## 📥 Download

The latest release of **Radar Al-Masrouf** is available for direct download from Google Drive:

<div align="center">

[![Download APK](https://img.shields.io/badge/Download%20APK-Google%20Drive-4285F4?style=for-the-badge&logo=googledrive&logoColor=white)](https://drive.google.com/drive/folders/1PTTms0S6cwumAz42Ib0R8BlxhqOSv6e1)

</div>

> **Note:** The APK is for Android devices. iOS builds require Xcode and a valid Apple Developer certificate — see the [Getting Started](#-getting-started) section for build instructions.

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

---

<div align="center">

**Crafted with ❤️ to empower Arabic-speaking families to manage their finances smarter.**

[⬆️ Back to Top](#-radar-al-masrouf) • [🐙 GitHub](https://github.com/laith-alskaf/HomeBuy_Manager) • [📥 Download APK](https://drive.google.com/drive/folders/1PTTms0S6cwumAz42Ib0R8BlxhqOSv6e1) • [📧 Report an Issue](https://github.com/laith-alskaf/HomeBuy_Manager/issues)

</div>
