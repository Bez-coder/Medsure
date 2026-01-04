# Medsure 🏥

**Medsure** is a comprehensive health management and medicine authentication app designed to protect lives by ensuring the authenticity of medications. 

## 🚀 Features

- **Medicine Authentication**: Instantly verify the authenticity of medicines by scanning QR codes.
- **Medication Reminders**: Never miss a dose with high-reliability background notifications that work even when the app is closed.
- **Health Tracking**: Keep a secure digital log of your medication history and health metrics.
- **Smart Analytics**: View your adherence history and health progress at a glance.
- **Session Persistence**: Fast access with a 10-minute session bypass for guest users and permanent login for authenticated users.
- **Google Sign-In**: Secure and easy authentication using your Google account.
- **Featured Health Insights**: Stay informed with curated medical articles and quick health tips.

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev/) (Dart)
- **Backend**: [Firebase](https://firebase.google.com/) (Auth, Firestore)
- **State Management**: Provider
- **Icons**: Lucide Icons & Custom Branding
- **Notifications**: Flutter Local Notifications with Timezone support

## 📦 Getting Started

### Prerequisites

- Flutter SDK (^3.10.4)
- Android Studio / VS Code
- A Firebase Project

### Setup

1. **Clone the repository**:
   ```bash
   git clone https://github.com/yourusername/medsure.git
   cd medsure
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Firebase Configuration**:
   - Place your `google-services.json` in `android/app/`.
   - Place your `GoogleService-Info.plist` in `ios/Runner/`.

4. **Run the app**:
   ```bash
   flutter run
   ```

## 🔒 Session Management

Medsure implements a "Guest Grace Period." If you use the app without logging in, your session is remembered for **10 minutes**. Authenticated users stay logged in across app restarts.

## 🔔 Notifications

The app uses `flutter_local_notifications` with a dedicated High Importance channel on Android to ensure medication reminders are delivered exactly on time.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---
*Developed with ❤️ to protect lives.*
