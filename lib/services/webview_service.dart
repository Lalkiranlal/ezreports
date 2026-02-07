import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'permission_service.dart';

class WebViewService {
  static final WebViewService _instance = WebViewService._internal();
  factory WebViewService() => _instance;
  WebViewService._internal();

  late WebViewController _webViewController;
  final PermissionService _permissionService = PermissionService();

  WebViewController get webViewController => _webViewController;

  void initializeWebView(BuildContext context, Function(String) onWebViewMessage) {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('https://ezyreport.com')) {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
        ),
      )
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: (JavaScriptMessage message) {
          _handleJavaScriptMessage(message.message, context, onWebViewMessage);
        },
      )
      ..loadRequest(Uri.parse('https://ezyreport.com'));
  }

  Future<void> _handleJavaScriptMessage(String message, BuildContext context, Function(String) onWebViewMessage) async {
    try {
      final data = json.decode(message);
      final action = data['action'] as String?;

      switch (action) {
        case 'getLocation':
          await _getLocation(context, onWebViewMessage);
          break;
        case 'captureImage':
          await _captureImage(context, onWebViewMessage);
          break;
        case 'pickImage':
          await _pickImage(context, onWebViewMessage);
          break;
        default:
          onWebViewMessage(json.encode({
            'error': 'Unknown action: $action',
            'status': 'error'
          }));
      }
    } catch (e) {
      onWebViewMessage(json.encode({
        'error': 'Failed to process message: $e',
        'status': 'error'
      }));
    }
  }

  Future<void> _getLocation(BuildContext context, Function(String) onWebViewMessage) async {
    try {
      bool hasPermission = await _permissionService.requestLocationPermission(context);
      
      if (!hasPermission) {
        onWebViewMessage(json.encode({
          'error': 'Location permission denied',
          'status': 'error'
        }));
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      onWebViewMessage(json.encode({
        'action': 'locationResponse',
        'data': {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
          'timestamp': position.timestamp.toIso8601String(),
        },
        'status': 'success'
      }));
    } catch (e) {
      onWebViewMessage(json.encode({
        'error': 'Failed to get location: $e',
        'status': 'error'
      }));
    }
  }

  Future<void> _captureImage(BuildContext context, Function(String) onWebViewMessage) async {
    try {
      bool hasPermission = await _permissionService.requestCameraPermission(context);
      
      if (!hasPermission) {
        onWebViewMessage(json.encode({
          'error': 'Camera permission denied',
          'status': 'error'
        }));
        return;
      }

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        // Convert image to base64 for web transmission
        final bytes = await image.readAsBytes();
        final base64Image = base64Encode(bytes);
        
        onWebViewMessage(json.encode({
          'action': 'imageResponse',
          'data': {
            'image': base64Image,
            'name': image.name,
            'path': image.path,
            'size': bytes.length,
          },
          'status': 'success'
        }));
      } else {
        onWebViewMessage(json.encode({
          'error': 'No image captured',
          'status': 'error'
        }));
      }
    } catch (e) {
      print('Camera capture error: $e');
      onWebViewMessage(json.encode({
        'error': 'Failed to capture image: $e',
        'status': 'error'
      }));
    }
  }

  Future<void> _pickImage(BuildContext context, Function(String) onWebViewMessage) async {
    try {
      bool hasPermission = await _permissionService.requestStoragePermission(context);
      
      if (!hasPermission) {
        onWebViewMessage(json.encode({
          'error': 'Storage permission denied',
          'status': 'error'
        }));
        return;
      }

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64Image = base64Encode(bytes);
        
        onWebViewMessage(json.encode({
          'action': 'imageResponse',
          'data': {
            'image': base64Image,
            'name': image.name,
            'path': image.path,
            'size': bytes.length,
          },
          'status': 'success'
        }));
      } else {
        onWebViewMessage(json.encode({
          'error': 'No image selected',
          'status': 'error'
        }));
      }
    } catch (e) {
      print('Gallery pick error: $e');
      onWebViewMessage(json.encode({
        'error': 'Failed to pick image: $e',
        'status': 'error'
      }));
    }
  }

  void sendMessageToWebView(String message) {
    _webViewController.runJavaScript("""
      if (window.ezReportCallback) {
        window.ezReportCallback($message);
      }
    """);
  }
}
