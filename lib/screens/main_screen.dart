import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Request all permissions on app start
    await _permissionService.requestAllPermissions(context);
    
    // Initialize WebView
    _webViewService.initializeWebView(context, _handleWebViewMessage);
    
    setState(() {
      _isLoading = false;
    });
  }

  void _handleWebViewMessage(String message) {
    // Handle messages from WebView
    // You can add specific handling here if needed
    print('WebView message: $message');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.primary,
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.surface),
          ),
        ),
      );
    }

    return Scaffold(
      body: WebViewWidget(
        controller: _webViewService.webViewController,
      ),
    );
  }
}
