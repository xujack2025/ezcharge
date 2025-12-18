# EzCharge

[![Flutter](https://img.shields.io/badge/Flutter-3.9+-blue.svg)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Compatible-orange.svg)](https://firebase.google.com)

A comprehensive Flutter mobile application for electric vehicle (EV) charging management with multi-user roles, real-time location tracking, and AI-powered assistance.

## 📋 Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Project Structure](#project-structure)
- [Configuration](#configuration)
- [Running the App](#running-the-app)
- [Architecture](#architecture)
- [Technologies Used](#technologies-used)
- [Contributing](#contributing)

## ✨ Features

### User Management
- **Multi-role support:** Customer, Driver, and Admin dashboards
- **Firebase Authentication** with OTP verification
- **Google Sign-In** integration
- **Role-based access control** (RBAC)

### Emergency Charging Requests
- Real-time request creation and status tracking
- Location-based requests with GeoPoint mapping
- Image upload with Firebase Storage
- ETA calculation and energy consumption tracking
- Multi-stage status pipeline (Pending → Upcoming → Charging → Payment → Processing → Completed)

### Charging Infrastructure
- Charging station directory with capacity management
- Charging bay tracking and availability
- Station details with images and descriptions
- Real-time station information

### Location & Mapping
- **Google Maps integration** with polyline routing
- Real-time geolocation tracking
- Route optimization and distance calculation
- Driver location updates

### Communication
- **Real-time chat system** (Dash Chat 2)
- **AI-powered assistance** (ChatGPT SDK)
- Push notifications
- Notification management

### Analytics & Administration
- Admin dashboard with analytics
- Complaint management system
- Chart visualizations (FL Chart)
- PDF report generation
- Driver performance analytics

### Additional Features
- QR code generation and scanning
- Face detection with ML Kit
- Rating and review system
- Reward management
- Camera and media picker support

## 📋 Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter 3.9+** ([Install Flutter](https://flutter.dev/docs/get-started/install))
- **Dart 3.9+** (included with Flutter)
- **Xcode 14+** (for iOS development on macOS)
- **Android Studio** (for Android development)
- **Git**
- **Firebase Project** (for backend services)

Verify installation:
```bash
flutter --version
dart --version
```

## 🚀 Installation

### 1. Clone the Repository
```bash
git clone https://github.com/yourusername/ezcharge.git
cd ezcharge
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Configure Firebase

#### iOS
```bash
cd ios
pod install
cd ..
```

#### Android
Place your `google-services.json` file in `android/app/`

#### iOS
Place your `GoogleService-Info.plist` file in `ios/Runner/`

### 4. Setup Environment Variables
Create a `.env` file in the project root:
```env
FIREBASE_API_KEY=your_firebase_api_key
CHAT_GPT_API_KEY=your_chatgpt_api_key
```

### 5. Generate App Icons (Optional)
```bash
flutter pub run flutter_launcher_icons
flutter pub run flutter_native_splash:create
```

## 📁 Project Structure

```
lib/
├── main.dart                 # App entry point
├── constants/                # App constants
│   ├── colors.dart
│   └── text_styles.dart
├── models/                   # Data models
│   ├── charging_station_model.dart
│   ├── charging_bay_model.dart
│   ├── emergency_request_model.dart
│   ├── customer_model.dart
│   ├── driver_model.dart
│   ├── admin_model.dart
│   └── notification_model.dart
├── services/                 # Business logic & API calls
│   └── auth_service.dart
├── viewmodels/              # State management (Provider)
│   ├── emergency_request_viewmodel.dart
│   ├── charging_station_viewmodel.dart
│   ├── tracking_viewmodel.dart
│   └── notification_viewmodel.dart
├── views/                   # UI Screens
│   ├── auth/                # Authentication screens
│   ├── admin/               # Admin dashboard screens
│   ├── customer/            # Customer screens
│   ├── reports/             # Reporting screens
│   └── EZCHARGE/            # Main app screens
└── widgets/                 # Reusable UI components
    ├── bottom_app_bar.dart
    ├── navbar.dart
    ├── button.dart
    ├── textfield.dart
    ├── top_app_bar.dart
    └── notification_card.dart
```

## ⚙️ Configuration

### Firebase Setup
1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com)
2. Enable Authentication (Email/Password, Google Sign-In, Phone)
3. Enable Cloud Firestore
4. Enable Firebase Storage
5. Download service account credentials

### API Keys
Add the following to your `.env` file:
```env
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_API_KEY=your_api_key
FIREBASE_APP_ID=your_app_id
CHAT_GPT_API_KEY=your_chatgpt_key
GOOGLE_MAPS_API_KEY=your_maps_key
```

## 🏃 Running the App

### Run on iOS
```bash
flutter run -t lib/main.dart --release
```

### Run on Android
```bash
flutter run -t lib/main.dart --release
```

### Run in Debug Mode
```bash
flutter run
```

### Run on Specific Device
```bash
flutter devices                    # List available devices
flutter run -d <device_id>
```

## 🏗️ Architecture

### MVVM Pattern
The app follows the **Model-View-ViewModel** architecture:

- **Models:** Data classes representing app entities
- **ViewModels:** Business logic and state management using Provider
- **Views:** UI screens that consume ViewModels
- **Services:** Firebase and external API integrations

### State Management
- **Provider** for reactive state management
- **ChangeNotifier** for model updates
- **MultiProvider** for multiple providers at app root

### Data Flow
```
Views (UI) ← ViewModel (State) ← Services (Firebase)
    ↓
  Model (Data)
```

## 🛠️ Technologies Used

### Frontend
- **Flutter** - Cross-platform mobile framework
- **Dart** - Programming language
- **Provider** - State management
- **Google Fonts** - Typography

### Backend & Services
- **Firebase Authentication** - User authentication
- **Cloud Firestore** - Real-time database
- **Firebase Storage** - File storage
- **Firebase Core** - Firebase initialization

### Maps & Location
- **Google Maps Flutter** - Interactive maps
- **Geolocator** - Device location
- **Google Polyline Points** - Route optimization

### Communication
- **Dash Chat 2** - Real-time chat UI
- **Chat GPT SDK** - AI assistance

### Machine Learning
- **Google ML Kit Face Detection** - Face recognition

### Media & Scanning
- **Mobile Scanner** - QR/Barcode scanning
- **Image Picker** - Photo selection
- **File Picker** - File selection
- **Camera** - Native camera access
- **QR Flutter** - QR code generation

### Analytics & Reporting
- **FL Chart** - Data visualization
- **PDF** - PDF generation
- **Printing** - Print functionality

### Utilities
- **Intl** - Internationalization
- **Shared Preferences** - Local storage
- **Flutter DotEnv** - Environment variables
- **URL Launcher** - Deep linking

## 📝 Building for Release

### Android
```bash
flutter build apk --release
# or for App Bundle
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
# Archive for App Store
open ios/Runner.xcworkspace
```

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📧 Contact

For questions or support, please reach out to the development team or open an issue on GitHub.
