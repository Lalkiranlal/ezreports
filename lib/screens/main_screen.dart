import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../core/constants/app_colors.dart';
import '../services/permission_service.dart';
import '../services/webview_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final WebViewService _webViewService = WebViewService();
  final PermissionService _permissionService = PermissionService();
  bool _isLoading = true;
  bool _showDownloadFab = false;
  String? _downloadUrl;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<bool> _onWillPop() async {
    // Prevent back navigation - user must use web page navigation
    developer.log(
      '🚫 Back navigation blocked - use web page navigation',
      name: 'MainScreen',
    );
    return false;
  }

  Future<void> _initializeApp() async {
    developer.log('🚀 Initializing MainScreen...', name: 'MainScreen');

    // Request all permissions on app start
    developer.log('🔐 Requesting all permissions...', name: 'MainScreen');
    await _permissionService.requestAllPermissions(context);

    // Initialize WebView
    developer.log('🌐 Initializing WebView...', name: 'MainScreen');
    _webViewService.initializeWebView(context, _handleWebViewMessage);

    developer.log('✅ MainScreen initialization complete', name: 'MainScreen');
    setState(() {
      _isLoading = false;
    });
  }

  void _handleWebViewMessage(String message) {
    developer.log(
      '📨 MainScreen received WebView message: $message',
      name: 'MainScreen',
    );

    try {
      final data = json.decode(message);
      final action = data['action'] as String?;

      // Handle download responses
      if (action == 'downloadFileResponse') {
        if (data['status'] == 'success') {
          setState(() {
            _showDownloadFab = true;
            _downloadUrl = data['filePath'] as String;
          });
        }
      }
    } catch (e) {
      developer.log('❌ Error parsing WebView message: $e', name: 'MainScreen');
    }

    // Handle messages from WebView
    print('WebView message: $message');
  }

  // Navigate to file app with downloaded file
  Future<void> _navigateToFileApp(String filePath) async {
    try {
      developer.log('📂 Opening file with app: $filePath', name: 'MainScreen');

      // Try to open with appropriate app based on file type
      final uri = Uri.file(filePath);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        developer.log(
          '✅ File opened successfully: $filePath',
          name: 'MainScreen',
        );
      } else {
        developer.log(
          '❌ No app available to open file: $filePath',
          name: 'MainScreen',
        );
        // Show snackbar or dialog to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No app available to open this file type'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      developer.log('❌ Error opening file: $e', name: 'MainScreen');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.surface),
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: () async {
              developer.log('🔄 Pull-to-refresh triggered', name: 'MainScreen');
              await _webViewService.reloadCurrentPage();
            },
            child: Stack(
              children: [
                WebViewWidget(controller: _webViewService.webViewController),
                // Download FAB
                if (_showDownloadFab && _downloadUrl != null)
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: FloatingActionButton.extended(
                      onPressed: () async {
                        developer.log(
                          '📱 Download FAB clicked: $_downloadUrl',
                          name: 'MainScreen',
                        );
                        await _navigateToFileApp(_downloadUrl!);
                      },
                      icon: const Icon(Icons.download),
                      label: const Text('Open Downloaded File'),
                      backgroundColor: AppColors.primary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
