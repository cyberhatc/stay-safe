# Stay Safe - Women's Safety App

A Flutter-based women's safety application with emergency SOS, location sharing, fake calls, and more.

## Features

- **Emergency SOS**: Shake phone or tap button to send SMS + push notifications with GPS location
- **Scream Alarm**: Play loud alarm sounds (male scream or police siren)
- **Fake Call**: Schedule fake incoming calls to escape uncomfortable situations
- **Friends List**: Manage emergency contacts (add from phone or manually)
- **Where Are You**: Send location requests to friends via Firestore
- **Track Me**: Share real-time location with trusted contacts
- **Settings**: Toggle emergency services, low battery alerts, customize sounds

## Architecture

```
lib/
├── core/           # Shared services, theme, constants
│   ├── theme/      # AppColors, AppTheme (Material 3, purple/pink)
│   ├── services/   # Database, Location, SMS, Notifications, Firestore
│   └── constants/  # App-wide constants
├── features/       # Feature-based organization
│   ├── auth/       # Phone OTP auth with Firebase
│   ├── home/       # Home screen with feature grid
│   ├── sos/        # Emergency SOS with shake detection
│   ├── scream_alarm/ # Alarm sound player
│   ├── fake_call/  # Fake incoming call UI
│   ├── friends/    # Emergency contacts management
│   ├── where_are_you/ # Location request feature
│   ├── track_me/   # Real-time location sharing
│   └── settings/   # App settings
└── shared/         # Shared widgets (AppShell, SosFab, FeatureTile)
```

## Tech Stack

- Flutter 3.x with Dart null-safety
- Riverpod v3 for state management
- Firebase Auth (Phone OTP), Firestore, FCM
- sqflite for local storage
- Material 3 with custom purple/pink theme
- geolocator, sensors_plus, audioplayers, url_launcher

## Setup Instructions

### 1. Firebase Setup

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Add an Android app with package name `com.staysafe.stay_safe`
3. Download `google-services.json` and place it in `android/app/`
4. Enable these Firebase services:
   - **Authentication** > Phone sign-in method
   - **Cloud Firestore** > Create database
   - **Cloud Messaging** > FCM is enabled by default

### 2. Google Maps API Key

1. Get a Google Maps API key from Google Cloud Console
2. Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_API_KEY_HERE"/>
```

### 3. Firebase Firestore Rules

```rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /location_requests/{requestId} {
      allow read, write: if request.auth != null;
    }
    match /tracking_sessions/{sessionId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### 4. Run the App

```bash
cd stay_safe
flutter pub get
flutter run
```

## Manual Setup Required

1. **Sound Assets**: Drop your alarm sound files in `assets/sounds/`:
   - `scream_male.mp3` - Male voice scream sound
   - `police_siren.mp3` - Police siren sound
   - Find royalty-free sounds at:
     - [freesound.org](https://freesound.org)
     - [pixabay.com/sound-effects](https://pixabay.com/sound-effects/)
     - [mixkit.co/free-sound-effects](https://mixkit.co/free-sound-effects/)

2. **Google Maps**: Enable "Maps SDK for Android" in Google Cloud Console

3. **Firebase Phone Auth**: Add test phone numbers in Firebase Console > Authentication > Settings > Phone numbers (for testing)

4. **Android Signing**: Generate a keystore for release builds

## Permission Explanations (shown to users)

| Permission | Why Needed |
|---|---|
| Location | Share your position in emergencies |
| SMS | Send emergency SMS to contacts |
| Contacts | Pick emergency contacts from phone |
| Notifications | Receive alerts from friends |
| Background Location | SOS works when app is in background |

## Future Extension Points

- [ ] Home screen widget for quick SOS
- [ ] Location safety ratings from user feedback
- [ ] Nearest police station / hospital finder
- [ ] iOS support
- [ ] In-app calling instead of SMS fallback
