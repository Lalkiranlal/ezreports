import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'permission_service.dart';

class WebViewService {
  static final WebViewService _instance = WebViewService._internal();
  factory WebViewService() => _instance;
  WebViewService._internal();

  late WebViewController _webViewController;
  final PermissionService _permissionService = PermissionService();

  WebViewController get webViewController => _webViewController;

  void initializeWebView(
    BuildContext context,
    Function(String) onMessageReceived,
  ) {
    developer.log('🌐 Initializing WebView...', name: 'WebViewService');
    
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            developer.log(
              '📊 WebView loading progress: $progress%',
              name: 'WebViewService',
            );
          },
          onPageStarted: (String url) {
            developer.log(
              '📄 WebView page started loading: $url',
              name: 'WebViewService',
            );
          },
          onPageFinished: (String url) async {
            developer.log(
              '✅ WebView page finished loading: $url',
              name: 'WebViewService',
            );
            // Set up response handler in web page
            _setupWebResponseHandler();
            // Wait longer for JavaScript libraries and variables to initialize
            await Future.delayed(const Duration(milliseconds: 3000));
            // Restore saved form data after page loads (URL-specific)
            await _restoreFormData(url);
            // Test connection by sending a ping to web
            _testConnection();
          },
          onWebResourceError: (WebResourceError error) {
            developer.log(
              '❌ WebView resource error: ${error.description} (${error.errorCode})',
              name: 'WebViewService',
            );
          },
          onNavigationRequest: (NavigationRequest request) {
            developer.log(
              '🧭 WebView navigation request: ${request.url}',
              name: 'WebViewService',
            );
            if (request.url.startsWith('https://')) {
              return NavigationDecision.navigate;
            }
            developer.log(
              '🚫 Navigation blocked: ${request.url}',
              name: 'WebViewService',
            );
            return NavigationDecision.prevent;
          },
        ),
      )
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: (JavaScriptMessage message) {
          developer.log(
            '📨 Received message from web: ${message.message}',
            name: 'WebViewService',
          );
          _handleJavaScriptMessage(message.message, context);
        },
      )
      ..loadRequest(Uri.parse('https://ezyreport.com'));

    developer.log(
      '🌐 WebView loading URL: https://ezyreport.com',
      name: 'WebViewService',
    );
  }

  Future<void> _handleJavaScriptMessage(
    String message,
    BuildContext context,
  ) async {
    developer.log(
      '🔄 Processing JavaScript message: $message',
      name: 'WebViewService',
    );
    
    try {
      final data = json.decode(message);
      final action = data['action'] as String?;
      
      developer.log('🎯 Action detected: $action', name: 'WebViewService');

      switch (action) {
        case 'testConnection':
          developer.log(
            '🔗 Handling testConnection request',
            name: 'WebViewService',
          );
          // Only respond to testConnection if it's from web (not from our own test)
          // Check if this is the initial test from web (has message but no status)
          if (data['message'] != null && data['status'] == null) {
            _sendToWeb(
              json.encode({
                'action': 'testConnectionResponse',
                'message': 'Connection test successful!',
                'timestamp': DateTime.now().toIso8601String(),
                'status': 'success',
              }),
            );
          }
          break;
        case 'getLocation':
          developer.log(
            '📍 Handling getLocation request',
            name: 'WebViewService',
          );
          await _getLocation(context);
          break;
        case 'captureImage':
          developer.log(
            '📷 Handling captureImage request',
            name: 'WebViewService',
          );
          await _captureImage(context);
          break;
        case 'pickFile':
          developer.log('📁 Handling pickFile request', name: 'WebViewService');
          await _pickImage(context);
          break;
        case 'saveFormData':
          developer.log('💾 Saving form data from web', name: 'WebViewService');
          await _saveFormData(data['data'] as Map<String, dynamic>);
          break;
        default:
          developer.log('❓ Unknown action: $action', name: 'WebViewService');
          _sendToWeb(
            json.encode({
            'error': 'Unknown action: $action',
            'status': 'error'
          }));
      }
    } catch (e) {
      developer.log('💥 Error processing message: $e', name: 'WebViewService');
      _sendToWeb(
        json.encode({
        'error': 'Failed to process message: $e',
        'status': 'error'
      }));
    }
  }

  Future<void> _getLocation(BuildContext context) async {
    developer.log('🗺️ Getting location...', name: 'WebViewService');
    
    try {
      bool hasPermission = await _permissionService.requestLocationPermission(context);
      developer.log(
        '🔐 Location permission granted: $hasPermission',
        name: 'WebViewService',
      );
      
      if (!hasPermission) {
        const errorMsg = 'Location permission denied';
        developer.log('🚫 $errorMsg', name: 'WebViewService');
        _sendToWeb(json.encode({'error': errorMsg,
          'status': 'error'
        }));
        return;
      }

      developer.log('⏳ Fetching current position...', name: 'WebViewService');
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      developer.log(
        '📍 Location obtained: Lat=${position.latitude}, Lon=${position.longitude}',
        name: 'WebViewService',
      );

      final response = {
        'action': 'locationResponse',
        'data': {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
          'timestamp': position.timestamp.toIso8601String(),
        },
        'status': 'success'
      };

      developer.log(
        '📤 Sending location response to web: ${json.encode(response)}',
        name: 'WebViewService',
      );
      _sendToWeb(json.encode(response));
    } catch (e) {
      developer.log('💥 Location error: $e', name: 'WebViewService');
      _sendToWeb(
        json.encode({
        'error': 'Failed to get location: $e',
        'status': 'error'
      }));
    }
  }

  Future<void> _captureImage(BuildContext context) async {
    developer.log('📸 Starting camera capture...', name: 'WebViewService');
    
    try {
      bool hasPermission = await _permissionService.requestCameraPermission(context);
      developer.log(
        '🔐 Camera permission granted: $hasPermission',
        name: 'WebViewService',
      );
      
      if (!hasPermission) {
        const errorMsg = 'Camera permission denied';
        developer.log('🚫 $errorMsg', name: 'WebViewService');
        _sendToWeb(json.encode({'error': errorMsg,
          'status': 'error'
        }));
        return;
      }

      developer.log('📷 Opening camera...', name: 'WebViewService');
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 40,
        maxWidth: 600,
        maxHeight: 600,
      );

      if (image != null) {
        developer.log(
          '📷 Image captured: ${image.name}',
          name: 'WebViewService',
        );
        
        // Convert image to base64 for web transmission
        final bytes = await image.readAsBytes();
        final base64Image = base64Encode(bytes);
        developer.log(
          '🔄 Image converted to base64 (${bytes.length} bytes)',
          name: 'WebViewService',
        );
        
        final response = {
          'action': 'fileResponse',
          'data': {
            'base64': base64Image,
            'name': image.name,
            'path': image.path,
            'size': bytes.length,
          },
          'status': 'success'
        };

        developer.log(
          '📤 Sending image response to web (base64 length: ${base64Image.length})',
          name: 'WebViewService',
        );
        _sendToWeb(json.encode(response));
      } else {
        const errorMsg = 'No image captured';
        developer.log('⚠️ $errorMsg', name: 'WebViewService');
        _sendToWeb(json.encode({'error': errorMsg,
          'status': 'error'
        }));
      }
    } catch (e) {
      developer.log('💥 Camera capture error: $e', name: 'WebViewService');
      _sendToWeb(
        json.encode({
        'error': 'Failed to capture image: $e',
        'status': 'error'
      }));
    }
  }

  Future<void> _pickImage(BuildContext context) async {
    developer.log('🖼️ Starting gallery pick...', name: 'WebViewService');
    
    try {
      bool hasPermission = await _permissionService.requestStoragePermission(context);
      developer.log(
        '🔐 Storage permission granted: $hasPermission',
        name: 'WebViewService',
      );
      
      if (!hasPermission) {
        const errorMsg = 'Storage permission denied';
        developer.log('🚫 $errorMsg', name: 'WebViewService');
        _sendToWeb(json.encode({'error': errorMsg,
          'status': 'error'
        }));
        return;
      }

      developer.log('📁 Opening gallery...', name: 'WebViewService');
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 40,
        maxWidth: 600,
        maxHeight: 600,
      );

      if (image != null) {
        developer.log(
          '🖼️ Image selected: ${image.name}',
          name: 'WebViewService',
        );
        
        final bytes = await image.readAsBytes();
        final base64Image = base64Encode(bytes);
        developer.log(
          '🔄 Image converted to base64 (${bytes.length} bytes)',
          name: 'WebViewService',
        );
        
        final response = {
          'action': 'fileResponse',
          'data': {
            'base64': base64Image,
            'name': image.name,
            'path': image.path,
            'size': bytes.length,
          },
          'status': 'success'
        };

        developer.log(
          '📤 Sending image response to web (base64 length: ${base64Image.length})',
          name: 'WebViewService',
        );
        _sendToWeb(json.encode(response));
      } else {
        const errorMsg = 'No image selected';
        developer.log('⚠️ $errorMsg', name: 'WebViewService');
        _sendToWeb(json.encode({'error': errorMsg,
          'status': 'error'
        }));
      }
    } catch (e) {
      developer.log('💥 Gallery pick error: $e', name: 'WebViewService');
      _sendToWeb(
        json.encode({
        'error': 'Failed to pick image: $e',
        'status': 'error'
      }));
    }
  }

  void sendMessageToWebView(String message) {
    developer.log(
      '📤 Sending message to WebView: $message',
      name: 'WebViewService',
    );
    _webViewController.runJavaScript("""
      if (window.ezReportCallback) {
        window.ezReportCallback($message);
      } else {
        console.log('ezReportCallback not found in window');
      }
    """);
  }

  void _testConnection() {
    developer.log('🔍 Testing WebView connection...', name: 'WebViewService');

    // Check if FlutterChannel is available in web
    _webViewController.runJavaScript("""
      if (typeof FlutterChannel !== 'undefined') {
        console.log('✅ FlutterChannel is available in web');
        FlutterChannel.postMessage(JSON.stringify({
          action: 'testConnection',
          message: 'Connection test from web',
          timestamp: new Date().toISOString()
        }));
      } else {
        console.log('❌ FlutterChannel is NOT available in web');
      }
    """);
  }

  void _setupWebResponseHandler() {
    developer.log(
      '🔧 Setting up web response handler...',
      name: 'WebViewService',
    );

    _webViewController.runJavaScript("""
      // Add global error handler to catch JavaScript errors
      window.addEventListener('error', function(e) {
        console.error('JavaScript error caught:', e.error);
        return false;
      });
      
      // Create a global function to handle Flutter responses
      window.handleFlutterResponse = function(response) {
        try {
          const data = typeof response === 'string' ? JSON.parse(response) : response;
          console.log('📨 Received Flutter response:', data);
          
          if (data.action === 'locationResponse' && data.status === 'success') {
            setLocation(data.data.latitude, data.data.longitude);
          } else if (data.action === 'locationResponse' && data.status === 'error') {
            document.getElementById("gps_status").innerHTML = '<span class="text-danger">❌ ' + data.error + '</span>';
          } else if (data.action === 'imageResponse' && data.status === 'success') {
            console.log('📷 Image received:', data.data.name);
            // Handle image response here
          } else if (data.action === 'injectFormData') {
            console.log('💾 Injecting form data:', data.data);
            // Inject form data into fields
            Object.keys(data.data).forEach(function(fieldId) {
              var element = document.getElementById(fieldId);
              if (element && data.data[fieldId]) {
                element.value = data.data[fieldId];
                element.dispatchEvent(new Event('input', { bubbles: true }));
                element.dispatchEvent(new Event('change', { bubbles: true }));
                console.log('✅ Restored field:', fieldId, 'with value:', data.data[fieldId]);
              }
            });
          } else if (data.action === 'testConnectionResponse' && data.status === 'success') {
            console.log('🔗 Connection test successful:', data.message);
          }
        } catch (error) {
          console.error('Error parsing Flutter message:', error);
        }
      };
      
      // Monitor form changes and save to Flutter
      document.addEventListener('input', function(e) {
        if (e.target && e.target.id && (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA' || e.target.tagName === 'SELECT')) {
          // Skip auto-saving passwords for security
          if (e.target.type === 'password') {
            return;
          }
          
          const formData = {};
          const inputs = document.querySelectorAll('input, textarea, select');
          inputs.forEach(function(input) {
            if (input.id && input.type !== 'file') {
              formData[input.id] = input.value;
            }
          });
          
          // Send form data to Flutter for persistence
          if (window.FlutterChannel && Object.keys(formData).length > 0) {
            window.FlutterChannel.postMessage(JSON.stringify({
              action: 'saveFormData',
              data: formData
            }));
          }
        }
      });
    """);
  }

  void _sendToWeb(String message) {
    developer.log(
      '📤 Sending message to web (length: ${message.length})',
      name: 'WebViewService',
    );

    // For large messages (like base64 images), use a more reliable method
    if (message.length > 50000) {
      _webViewController.runJavaScript("""
        if (window.handleFlutterResponse) {
          window.handleFlutterResponse('$message');
        } else {
          console.log('handleFlutterResponse not found, falling back to console');
          console.log('Flutter message (large data)');
        }
      """);
    } else {
      _webViewController.runJavaScript("""
        if (window.handleFlutterResponse) {
          window.handleFlutterResponse($message);
        } else {
          console.log('handleFlutterResponse not found, falling back to console');
          console.log('Flutter message:', $message);
        }
      """);
    }
  }

  // Save form data to SharedPreferences (URL-specific)
  Future<void> _saveFormData(Map<String, dynamic> formData) async {
    try {
      // Get current URL to create URL-specific storage key
      final currentUrl = await _webViewController.currentUrl() ?? 'unknown';
      final urlKey = 'webview_form_data_${currentUrl.hashCode}';

      final prefs = await SharedPreferences.getInstance();
      final formDataJson = json.encode(formData);
      await prefs.setString(urlKey, formDataJson);
      developer.log(
        '💾 Saved form data for $currentUrl: $formDataJson',
        name: 'WebViewService',
      );
    } catch (e) {
      developer.log('❌ Error saving form data: $e', name: 'WebViewService');
    }
  }

  // Restore form data from SharedPreferences (URL-specific)
  Future<void> _restoreFormData(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final urlKey = 'webview_form_data_${url.hashCode}';
      final savedData = prefs.getString(urlKey);

      if (savedData != null && savedData.isNotEmpty) {
        final formData = json.decode(savedData) as Map<String, dynamic>;
        developer.log(
          '🔄 Restoring form data for $url: $formData',
          name: 'WebViewService',
        );

        // Send form data to web page for injection
        await _sendFormDataToWeb(formData);

        // Restore individual form fields
        formData.forEach((key, value) async {
          if (value != null) {
            await _webViewController.runJavaScript("""
              var element = document.getElementById('$key');
              if (element) {
                element.value = '$value';
                element.dispatchEvent(new Event('input', { bubbles: true }));
                element.dispatchEvent(new Event('change', { bubbles: true }));
              }
            """);
          }
        });

        // Small delay to ensure DOM is ready
        await Future.delayed(const Duration(milliseconds: 500));
      } else {
        developer.log(
          '📝 No saved form data found for $url',
          name: 'WebViewService',
        );
      }
    } catch (e) {
      developer.log('❌ Error restoring form data: $e', name: 'WebViewService');
    }
  }

  // Send form data to web page for injection
  Future<void> _sendFormDataToWeb(Map<String, dynamic> formData) async {
    try {
      final formDataJson = json.encode({
        'action': 'injectFormData',
        'data': formData,
      });

      developer.log(
        '📤 Sending form data to web: $formDataJson',
        name: 'WebViewService',
      );
      _sendToWeb(formDataJson);
    } catch (e) {
      developer.log(
        '❌ Error sending form data to web: $e',
        name: 'WebViewService',
      );
    }
  }

  // Clear saved form data
  Future<void> _clearFormData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('webview_form_data');
      developer.log('🗑️ Cleared saved form data', name: 'WebViewService');
    } catch (e) {
      developer.log('❌ Error clearing form data: $e', name: 'WebViewService');
    }
  }
}
