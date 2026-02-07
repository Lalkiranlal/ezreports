import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/constants/app_strings.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  Future<bool> requestLocationPermission(BuildContext context) async {
    try {
      print('REQUESTING LOCATION PERMISSION');
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showDialog(context, AppStrings.locationServiceDisabled, 'Please enable location services in your device settings.');
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showDialog(context, AppStrings.permissionDenied, AppStrings.locationPermissionMessage);
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showDialog(context, AppStrings.permissionPermanentlyDenied, AppStrings.locationPermissionMessage);
        return false;
      }

      return true;
    } catch (e) {
      _showDialog(context, AppStrings.somethingWentWrong, 'Failed to get location permission: $e');
      return false;
    }
  }

  Future<bool> requestCameraPermission(BuildContext context) async {
    try {
      print('REQUESTING CAMERA PERMISSION');
      PermissionStatus status = await Permission.camera.status;
      
      if (status.isDenied) {
        status = await Permission.camera.request();
        if (status.isDenied) {
          _showDialog(context, AppStrings.permissionDenied, AppStrings.cameraPermissionMessage);
          return false;
        }
      }

      if (status.isPermanentlyDenied) {
        _showDialog(context, AppStrings.permissionPermanentlyDenied, AppStrings.cameraPermissionMessage);
        return false;
      }

      return status.isGranted;
    } catch (e) {
      _showDialog(context, AppStrings.somethingWentWrong, 'Failed to get camera permission: $e');
      return false;
    }
  }

  Future<bool> requestStoragePermission(BuildContext context) async {
    try {
      print('STORAGE PERMISSION: METHOD CALLED');
      print('STORAGE PERMISSION: CHECKING CURRENT STATUS');
      
      // Try newer media permissions first (Android 13+)
      PermissionStatus mediaStatus = await Permission.photos.status;
      print('STORAGE PERMISSION: MEDIA PHOTOS STATUS = $mediaStatus');
      
      // If media permission is already granted, no need to request again
      if (mediaStatus.isGranted) {
        print('STORAGE PERMISSION: MEDIA PHOTOS ALREADY GRANTED');
        return true;
      }
      
      if (mediaStatus.isDenied) {
        print('STORAGE PERMISSION: MEDIA PHOTOS DENIED - REQUESTING MEDIA PERMISSION');
        mediaStatus = await Permission.photos.request();
        print('STORAGE PERMISSION: MEDIA REQUEST RESULT = $mediaStatus');
        
        if (mediaStatus.isGranted) {
          print('STORAGE PERMISSION: MEDIA PHOTOS GRANTED AFTER REQUEST');
          return true;
        }
      }
      
      // Fall back to legacy storage permission
      PermissionStatus status = await Permission.storage.status;
      print('STORAGE PERMISSION: LEGACY STORAGE STATUS = $status');
      
      // If storage permission is already granted, no need to request again
      if (status.isGranted) {
        print('STORAGE PERMISSION: LEGACY STORAGE ALREADY GRANTED');
        return true;
      }
      
      if (status.isDenied) {
        print('STORAGE PERMISSION: LEGACY DENIED - REQUESTING LEGACY PERMISSION');
        status = await Permission.storage.request();
        print('STORAGE PERMISSION: LEGACY REQUEST RESULT = $status');
        if (status.isGranted) {
          print('STORAGE PERMISSION: LEGACY STORAGE GRANTED AFTER REQUEST');
          return true;
        }
        
        if (status.isDenied) {
          print('STORAGE PERMISSION: STILL DENIED - SHOWING DIALOG');
          _showDialog(context, AppStrings.permissionDenied, AppStrings.storagePermissionMessage);
          return false;
        }
      }

      if (status.isPermanentlyDenied || mediaStatus.isPermanentlyDenied) {
        print('STORAGE PERMISSION: PERMANENTLY DENIED - SHOWING SETTINGS DIALOG');
        _showSettingsDialog(context, 'Storage Permission Required', 
          'Storage permission is permanently denied. Please enable it in app settings to access gallery and files.');
        return false;
      }

      print('STORAGE PERMISSION: GRANTED = ${status.isGranted || mediaStatus.isGranted}');
      return status.isGranted || mediaStatus.isGranted;
    } catch (e) {
      print('STORAGE PERMISSION: EXCEPTION OCCURRED = $e');
      _showDialog(context, AppStrings.somethingWentWrong, 'Failed to get storage permission: $e');
      return false;
    }
  }

  Future<bool> requestAllPermissions(BuildContext context) async {
    print('REQUESTING ALL STARTUP PERMISSIONS');
    
    // Request all permissions on startup
    bool locationGranted = false;
    bool cameraGranted = false;
    bool storageGranted = false;
    
    try {
      locationGranted = await requestLocationPermission(context);
    } catch (e) {
      print('Location permission failed: $e');
    }
    
    try {
      cameraGranted = await requestCameraPermission(context);
    } catch (e) {
      print('Camera permission failed: $e');
    }
    
    try {
      print('ABOUT TO CALL STORAGE PERMISSION');
      storageGranted = await requestStoragePermission(context);
      print('STORAGE PERMISSION CALL COMPLETED');
    } catch (e) {
      print('Storage permission failed: $e');
    }
    
    print('PERMISSION RESULTS - Location: $locationGranted, Camera: $cameraGranted, Storage: $storageGranted');
    
    return locationGranted && cameraGranted && storageGranted;
  }

  void _showDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showSettingsDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('Settings'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}
