# 💰 Expense Tracker (Full-Stack)

A complete, offline-first personal finance manager built for real-world use. It works fully offline on your Android device and syncs with a custom backend when connected.

## 🏗️ Project Structure

This repository contains both the client app and the backend server:

- **[`/client`](./client)**: The Flutter mobile application (Android/iOS).
- **[`/server`](./server)**: The PHP CodeIgniter 4 REST API backend.

---

## 📱 Mobile Client (Flutter)

The mobile app is designed to be completely usable offline. It stores all transactions, categories, and accounts in a local SQLite database and syncs them securely to the cloud on-demand.

### ✨ Features

- **Offline-First**: Add, edit, or delete transactions without an internet connection.
- **Bi-Directional Sync**: Tap "Sync" to push your local changes and pull any updates from the server.
- **Privacy & Control**: Manage your data locally. Use the "Clear Data" button to manually wipe your device data without affecting your cloud backup.
- **Dynamic Dashboard**: Real-time insights, Safe to Spend calculations, and actionable profile management directly from the home screen.
- **Production Ready**: Configured for Google Play Store publication with secure HTTP requirements and centralized configuration.

### 🚀 Getting Started (Client)

1. Navigate to the client directory: `cd client`
2. Install dependencies: `flutter pub get`
3. Configure the API URL (optional):
  - Default (Android Emulator): `http://10.0.2.2:8080/api/v1`
	 - Override at build/run time:
		 - `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api/v1`
		 - `flutter run --dart-define=API_BASE_URL=http://192.168.x.x:8080/api/v1` (physical device, same Wi-Fi)
4. Run the app: `flutter run`

---

## 🖥️ Backend Server (PHP CodeIgniter)

> **Stack**: PHP 8.1+ · CodeIgniter 4 · MySQL 8 · Custom HS256 JWT

The REST API backend handles user authentication, data persistence, and conflict resolution during syncing.

### ✨ Features

- **Atomic Sync Endpoint**: A single `/sync` endpoint handles pushing and pulling records to keep offline devices up to date.
- **UUID Keys**: Uses UUID v4 for primary keys to prevent collisions between offline devices.
- **Secure Auth**: Custom JWT-based authentication (HS256) with bcrypt password hashing.

### 🚀 Getting Started (Server)
1. Navigate to the server directory: `cd server`
2. Install dependencies: `composer install`
3. Configure environment: Copy `.env.example` to `.env` and fill in your database credentials and `JWT_SECRET`.
4. Run migrations: `php spark migrate`
5. Start development server: `php spark serve --host 0.0.0.0 --port 8080` (Use `0.0.0.0` so your mobile device can reach it).

---

## 🔐 Security Notes
- **API URLs**: Ensure the client uses HTTPS in production, as cleartext traffic has been explicitly disabled for Play Store compliance.
- **Data Deletion**: Logging out from the app does not automatically wipe local device data. Users are informed that data is retained and must be manually cleared via Settings.
- **App Signing**: To publish to the Play Store, you must generate a release Keystore and configure it in `client/android/app/build.gradle.kts`.

## 📜 Documentation
- Complete API Documentation: **[`api_docs.md`](./api_docs.md)**
- Contribution Guidelines: **[`CONTRIBUTING.md`](./CONTRIBUTING.md)**
