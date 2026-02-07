<?php
// EzReport Web Interface - PHP Integration with Flutter App
// This file demonstrates how to communicate with the EzReport Flutter mobile app

session_start();
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Handle different actions from Flutter app
$action = $_POST['action'] ?? $_GET['action'] ?? '';

switch ($action) {
    case 'getLocation':
        handleGetLocation();
        break;
        
    case 'captureImage':
        handleCaptureImage();
        break;
        
    case 'pickImage':
        handlePickImage();
        break;
        
    case 'submitReport':
        handleSubmitReport();
        break;
        
    default:
        echo json_encode(['error' => 'Unknown action: ' . $action]);
        break;
}

/**
 * Handle location requests from Flutter app
 */
function handleGetLocation() {
    // Get location data from Flutter app
    $latitude = $_POST['latitude'] ?? '';
    $longitude = $_POST['longitude'] ?? '';
    $accuracy = $_POST['accuracy'] ?? '';
    
    if (empty($latitude) || empty($longitude)) {
        echo json_encode([
            'error' => 'Location data required',
            'status' => 'error'
        ]);
        return;
    }
    
    // Process location (save to database, use for reporting, etc.)
    $locationData = [
        'latitude' => $latitude,
        'longitude' => $longitude,
        'accuracy' => $accuracy,
        'timestamp' => date('Y-m-d H:i:s'),
        'status' => 'success'
    ];
    
    // Example: Save to database
    // saveLocationToDatabase($locationData);
    
    echo json_encode($locationData);
}

/**
 * Handle image capture from Flutter app
 */
function handleCaptureImage() {
    $imageData = $_POST['imageData'] ?? '';
    $location = $_POST['location'] ?? '';
    
    if (empty($imageData)) {
        echo json_encode([
            'error' => 'Image data required',
            'status' => 'error'
        ]);
        return;
    }
    
    // Process base64 image data
    $imageData = str_replace('data:image/png;base64,', '', $imageData);
    $imageData = base64_decode($imageData);
    
    if ($imageData === false) {
        echo json_encode([
            'error' => 'Invalid image data',
            'status' => 'error'
        ]);
        return;
    }
    
    // Generate unique filename
    $filename = 'report_' . time() . '_' . uniqid() . '.png';
    $filepath = 'uploads/' . $filename;
    
    // Save image
    if (file_put_contents($filepath, $imageData)) {
        $response = [
            'filename' => $filename,
            'filepath' => $filepath,
            'location' => $location,
            'timestamp' => date('Y-m-d H:i:s'),
            'status' => 'success'
        ];
        
        // Example: Save to database
        // saveImageToDatabase($filename, $filepath, $location);
        
        echo json_encode($response);
    } else {
        echo json_encode([
            'error' => 'Failed to save image',
            'status' => 'error'
        ]);
    }
}

/**
 * Handle image pick from gallery
 */
function handlePickImage() {
    $imageData = $_POST['imageData'] ?? '';
    $location = $_POST['location'] ?? '';
    
    if (empty($imageData)) {
        echo json_encode([
            'error' => 'Image data required',
            'status' => 'error'
        ]);
        return;
    }
    
    // Process base64 image data (same as capture)
    $imageData = str_replace('data:image/png;base64,', '', $imageData);
    $imageData = base64_decode($imageData);
    
    if ($imageData === false) {
        echo json_encode([
            'error' => 'Invalid image data',
            'status' => 'error'
        ]);
        return;
    }
    
    // Generate unique filename
    $filename = 'gallery_' . time() . '_' . uniqid() . '.png';
    $filepath = 'uploads/' . $filename;
    
    // Save image
    if (file_put_contents($filepath, $imageData)) {
        $response = [
            'filename' => $filename,
            'filepath' => $filepath,
            'location' => $location,
            'timestamp' => date('Y-m-d H:i:s'),
            'status' => 'success'
        ];
        
        echo json_encode($response);
    } else {
        echo json_encode([
            'error' => 'Failed to save image',
            'status' => 'error'
        ]);
    }
}

/**
 * Handle complete report submission
 */
function handleSubmitReport() {
    $reportData = [
        'title' => $_POST['title'] ?? '',
        'description' => $_POST['description'] ?? '',
        'location' => $_POST['location'] ?? '',
        'images' => $_POST['images'] ?? [],
        'category' => $_POST['category'] ?? '',
        'priority' => $_POST['priority'] ?? '',
        'timestamp' => date('Y-m-d H:i:s'),
        'user_id' => $_SESSION['user_id'] ?? 'anonymous'
    ];
    
    // Validate required fields
    if (empty($reportData['title']) || empty($reportData['description'])) {
        echo json_encode([
            'error' => 'Title and description required',
            'status' => 'error'
        ]);
        return;
    }
    
    // Save complete report to database
    $reportId = saveReportToDatabase($reportData);
    
    if ($reportId) {
        echo json_encode([
            'reportId' => $reportId,
            'status' => 'success',
            'message' => 'Report submitted successfully'
        ]);
    } else {
        echo json_encode([
            'error' => 'Failed to save report',
            'status' => 'error'
        ]);
    }
}

/**
 * Example database functions (implement based on your database)
 */
function saveLocationToDatabase($data) {
    // Implement your database logic here
    // Example: INSERT INTO locations (latitude, longitude, accuracy, timestamp) VALUES (...)
    return true;
}

function saveImageToDatabase($filename, $filepath, $location) {
    // Implement your database logic here
    // Example: INSERT INTO images (filename, filepath, location, timestamp) VALUES (...)
    return true;
}

function saveReportToDatabase($reportData) {
    // Implement your database logic here
    // Example: INSERT INTO reports (title, description, location, images, category, priority, user_id, timestamp) VALUES (...)
    // Return report ID
    return 123; // Example report ID
}
?>
