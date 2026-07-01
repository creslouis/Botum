# Botum

Botum is a Flutter souvenir store application built with Dart and fully integrated with Firebase. The app is designed to provide a smooth shopping experience for browsing souvenir products, authenticating users, managing cloud-backed data, and deploying to the web through Firebase Hosting.

## Overview

This project combines Flutter's cross-platform UI toolkit with Firebase services to build a modern mobile and web-ready e-commerce application. Botum supports multiple authentication methods and uses Firestore as its cloud database to store and manage application data such as users, products, and other store-related records.

## Features

- Cross-platform Flutter application written in Dart
- Souvenir store shopping experience
- Firebase Authentication integration
- Sign in with Google
- Sign in with Facebook
- Sign in with email and password
- Cloud Firestore for database storage
- Firebase Hosting for web deployment
- Scalable backend powered by Firebase services

## Tech Stack

- Flutter
- Dart
- Firebase Authentication
- Cloud Firestore
- Firebase Hosting
- Android and Web platform support

## Authentication

Botum supports multiple login methods through Firebase Authentication:

- Google Sign-In
- Facebook Login
- Email and Password Authentication

These options make the app more accessible to users while keeping account management centralized through Firebase.

## Firebase Services Used

### Firebase Authentication

Used to register users, sign users in, and manage account sessions securely.

### Cloud Firestore

Used as the main cloud database for storing and syncing application data in real time. This can include:

- User profiles
- Product listings
- Store inventory
- Orders
- Favorites or cart data

### Firebase Hosting

Used to deploy the Flutter web build so the souvenir store can be accessed online.

## Project Goals

The main goal of Botum is to deliver a souvenir store application that demonstrates:

- Flutter app development using Dart
- Real-world Firebase integration
- Multi-provider authentication
- Cloud-based data storage with Firestore
- Web deployment using Firebase Hosting

## Getting Started

### Prerequisites

Before running this project, make sure you have the following installed:

- Flutter SDK
- Dart SDK
- Android Studio or VS Code
- Firebase CLI
- A Firebase project configured in the Firebase Console

You can verify your Flutter installation with:

```bash
flutter doctor
```

## Installation

1. Clone the repository:

```bash
git clone <your-repository-url>
```

2. Open the project folder:

```bash
cd Botum
```

3. Install dependencies:

```bash
flutter pub get
```

4. Configure Firebase for the platforms you want to support.

## Firebase Setup

To fully run this project with Firebase, configure the following in your Firebase project:

1. Create a new Firebase project in the Firebase Console.
2. Register your Android app and Flutter web app.
3. Enable Authentication providers:
- Google
- Facebook
- Email/Password
4. Create a Cloud Firestore database.
5. Enable Firebase Hosting if deploying the web app.
6. Add the Firebase configuration files required by Flutter.

Typical files include:

- `google-services.json` for Android
- Firebase web configuration for web builds
- `firebase_options.dart` if using FlutterFire configuration

If you are using FlutterFire CLI, you can configure Firebase with:

```bash
flutterfire configure
```

## Running the App

Run the app on a connected device or emulator:

```bash
flutter run
```

Run the app in Chrome:

```bash
flutter run -d chrome
```

## Building the App

Build an Android APK:

```bash
flutter build apk
```

Build the Flutter web app:

```bash
flutter build web
```

## Deploying to Firebase Hosting

After building the web app, deploy it with Firebase Hosting:

```bash
firebase deploy
```

Make sure your Firebase Hosting configuration points to Flutter's web build output directory.

## Suggested App Modules

Depending on the current implementation, the souvenir store can include modules such as:

- User authentication
- Home page
- Product catalog
- Product details
- Shopping cart
- Favorites or wishlist
- Checkout flow
- User profile
- Admin or inventory management

## Project Structure

Current project structure:

```text
Botum/
|- android/
|- lib/
|  |- main.dart
|- test/
|- web/
|- pubspec.yaml
|- README.md
```

As the project grows, additional folders such as `screens`, `widgets`, `services`, `models`, and `firebase` configuration files may be added under `lib/`.

## Future Improvements

- Product search and filtering
- Shopping cart persistence
- Order history
- Payment gateway integration
- Admin dashboard for product management
- Push notifications
- Better responsive support for web

## Academic / Portfolio Value

This project is suitable as:

- A mobile application development assignment
- A Flutter and Firebase portfolio project
- A sample e-commerce app using cloud backend services

## Author

Developed as a Flutter souvenir store project using Dart and Firebase.

## License

This project is for educational and development purposes unless otherwise specified.
