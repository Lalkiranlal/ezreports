# EzReport

A web-based Flutter application for easy reporting solutions with location and image sharing capabilities.

## Features

- **WebView Integration**: Seamlessly integrates with https://ezyreport.com
- **Script Channel Communication**: Bidirectional communication between web and native app
- **Location Services**: Share accurate location data with web requests
- **Image Handling**: Capture and share images via camera or gallery
- **Permission Management**: Comprehensive permission handling for location, camera, and storage
- **Splash Screen**: Beautiful splash screen with EzReport branding
- **Cross-Platform**: Works on both Android and iOS

## Architecture

The app follows a clean architecture with:

- **Core Layer**: Constants, colors, strings, and utilities
- **Services Layer**: Permission handling and WebView management
- **Screens Layer**: Splash screen and main WebView screen
- **Web Integration**: JavaScript channel for web-app communication

## Setup Instructions

### Prerequisites

- Flutter SDK (>= 3.10.8)
- Dart SDK
- Android Studio / Xcode for mobile development

### Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd ez_reports
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

### Permissions

The app requires the following permissions:

- **Location**: Fine and coarse location access
- **Camera**: Capture images for reports
- **Storage**: Read and write external storage
- **Internet**: WebView functionality

## Web Integration

The app communicates with https://ezyreport.com through a JavaScript channel. The web interface can request:

- **Location Data**: 
  ```javascript
  FlutterChannel.postMessage(JSON.stringify({
    action: 'getLocation'
  }));
  ```

- **Capture Image**:
  ```javascript
  FlutterChannel.postMessage(JSON.stringify({
    action: 'captureImage'
  }));
  ```

- **Pick Image from Gallery**:
  ```javascript
  FlutterChannel.postMessage(JSON.stringify({
    action: 'pickImage'
  }));
  ```

### Response Format

All responses follow this format:
```json
{
  "action": "responseType",
  "data": { /* response data */ },
  "status": "success|error",
  "error": "error message (if status is error)"
}
```

## Project Structure

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_colors.dart
│   │   └── app_strings.dart
├── screens/
│   ├── splash_screen.dart
│   └── main_screen.dart
├── services/
│   ├── permission_service.dart
│   └── webview_service.dart
└── main.dart
```

## Adding Your Logo

1. Replace the placeholder logo at `assets/logo/ez_report_logo.png` with your actual EzReport logo
2. Ensure the logo is high quality and properly sized for mobile displays
3. Update the splash screen to use your logo if needed

## Development

### Running Tests

```bash
flutter test
```

### Building for Production

**Android:**
```bash
flutter build apk --release
```

**iOS:**
```bash
flutter build ios --release
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is proprietary software for EzReport. All rights reserved.
# ezreports
# ezreports
