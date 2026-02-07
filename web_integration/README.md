# EzReport Web Integration Guide

## Overview
This guide shows how to integrate your PHP web interface with the EzReport Flutter mobile app.

## Files Structure
```
web_integration/
├── api.php          # Backend API for handling Flutter requests
├── index.html        # Frontend web interface
└── uploads/          # Directory for uploaded images
```

## Setup Instructions

### 1. Server Setup
1. Upload files to your web server (e.g., `https://ezyreport.com`)
2. Create `uploads/` directory with write permissions
3. Configure database connection in `api.php`

### 2. Database Setup
Create these tables in your MySQL database:

```sql
CREATE TABLE reports (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    category VARCHAR(100),
    priority VARCHAR(20),
    location JSON,
    images JSON,
    user_id VARCHAR(100),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE images (
    id INT AUTO_INCREMENT PRIMARY KEY,
    filename VARCHAR(255) NOT NULL,
    filepath VARCHAR(500) NOT NULL,
    location JSON,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE locations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    accuracy DECIMAL(8, 2),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 3. Flutter App Configuration
Update your Flutter app to load your web interface:

```dart
// In lib/services/webview_service.dart
WebView(
  initialUrl: 'https://your-domain.com/web_integration/', // Your URL
  // ... rest of WebView configuration
)
```

## Features Available

### 📍 Location Services
- **Get Current Location**: Captures GPS coordinates
- **Accuracy Display**: Shows location precision
- **Error Handling**: Handles permission denials

### 📷 Camera Integration
- **Capture Photo**: Opens device camera
- **Gallery Access**: Select from photo library
- **Image Preview**: Shows captured images
- **Base64 Transfer**: Secure image data transmission

### 📤 Report Submission
- **Form Validation**: Ensures required fields
- **Multiple Images**: Support for multiple photos
- **Priority Levels**: Low, Medium, High, Urgent
- **Categories**: Infrastructure, Safety, Environment, Other

## API Endpoints

### POST /api.php
| Action | Parameters | Response |
|---------|------------|----------|
| `getLocation` | latitude, longitude, accuracy | Location data |
| `captureImage` | imageData, location | Image save result |
| `pickImage` | imageData, location | Gallery image result |
| `submitReport` | title, description, location, images, category, priority | Report submission result |

## JavaScript Channel Communication

### From Web to Flutter
```javascript
// Request location
FlutterChannel.postMessage(JSON.stringify({
    action: 'getLocation'
}));

// Capture photo
FlutterChannel.postMessage(JSON.stringify({
    action: 'captureImage'
}));

// Pick from gallery
FlutterChannel.postMessage(JSON.stringify({
    action: 'pickImage'
}));
```

### From Flutter to Web
```javascript
// Listen for responses
window.addEventListener('message', function(event) {
    const data = JSON.parse(event.data);
    
    switch (data.action) {
        case 'locationResult':
            // Handle location response
            break;
        case 'imageResult':
            // Handle image response
            break;
    }
});
```

## Security Considerations

### 1. Input Validation
- Sanitize all user inputs
- Validate file types and sizes
- Implement rate limiting

### 2. Authentication
```php
// Add to api.php
session_start();
if (!isset($_SESSION['user_id'])) {
    echo json_encode(['error' => 'Authentication required']);
    exit;
}
```

### 3. File Upload Security
```php
// Validate image uploads
$allowedTypes = ['image/jpeg', 'image/png', 'image/jpg'];
$maxSize = 5 * 1024 * 1024; // 5MB

if (!in_array($fileType, $allowedTypes) || $fileSize > $maxSize) {
    echo json_encode(['error' => 'Invalid file']);
    exit;
}
```

## Testing

### 1. Local Testing
- Use XAMPP/WAMP for local PHP server
- Test with Flutter emulator
- Check browser console for errors

### 2. Mobile Testing
- Install Flutter app on device
- Test all features (location, camera, gallery)
- Verify image uploads and report submission

### 3. Integration Testing
- Test Flutter ↔ Web communication
- Verify data persistence
- Check error handling

## Troubleshooting

### Common Issues

#### Flutter Channel Not Working
```javascript
// Check if Flutter channel exists
if (window.flutter_inappwebview) {
    // Use inappwebview channel
} else if (window.FlutterChannel) {
    // Use custom channel
}
```

#### Image Upload Fails
- Check uploads directory permissions
- Verify PHP file upload limits
- Ensure base64 decoding works

#### Location Not Working
- Check Android location permissions
- Verify GPS is enabled
- Test in different locations

## Production Deployment

### 1. HTTPS Required
- Use SSL certificate
- Update all URLs to HTTPS
- Configure secure headers

### 2. Performance Optimization
- Implement image compression
- Use CDN for static assets
- Enable database caching

### 3. Monitoring
- Add error logging
- Monitor API response times
- Track user analytics

## Support

For technical support:
1. Check browser console for JavaScript errors
2. Review Flutter debug logs
3. Verify PHP error logs
4. Test with different devices/browsers

This integration provides a complete bridge between your EzReport Flutter app and PHP web backend, enabling full mobile reporting functionality.
