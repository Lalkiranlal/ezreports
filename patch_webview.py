import os

path = '/Users/kiranlalk/Desktop/ez_reports/lib/services/webview_service.dart'
with open(path, 'r') as f:
    content = f.read()

imports = """import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart' as fileOpen;
"""
content = content.replace("import 'package:webview_flutter/webview_flutter.dart';", "import 'package:webview_flutter/webview_flutter.dart';\n" + imports)

nav_req_old = """          onNavigationRequest: (NavigationRequest request) {
            developer.log(
              '🧭 WebView navigation request: ${request.url}',
              name: 'WebViewService',
            );
            
            // Handle blob URLs more carefully - only allow actual downloads
            if (request.url.startsWith('blob:')) {
              // Extract blob info from URL
              final uri = Uri.parse(request.url);
              final pathSegments = uri.pathSegments;

              // Check if this looks like a file download (has file extension)
              if (pathSegments.isNotEmpty) {
                final lastSegment = pathSegments.last.toLowerCase();
                final isFileDownload =
                    lastSegment.contains('.') ||
                    lastSegment.length > 3; // Likely has file extension
                
                if (isFileDownload) {
                  developer.log(
                    '🔓 Allowing blob file download: ${request.url}',
                    name: 'WebViewService',
                  );
                  _lastBlobUrl = request.url;
                  return NavigationDecision.navigate;
                } else {
                  developer.log(
                    '🚫 Blocking non-file blob URL: ${request.url}',
                    name: 'WebViewService',
                  );
                  return NavigationDecision.prevent;
                }
              } else {
                developer.log(
                  ' Blocking invalid blob URL: ${request.url}',
                  name: 'WebViewService',
                );
                return NavigationDecision.prevent;
              }
            }
            
            // Allow https URLs
            if (request.url.startsWith('https://')) {
              return NavigationDecision.navigate;
            }
            
            // Block other navigation attempts
            developer.log(
              '🚫 Navigation blocked: ${request.url}',
              name: 'WebViewService',
            );
            return NavigationDecision.prevent;
          },"""

nav_req_new = """          onNavigationRequest: (NavigationRequest request) {
            developer.log(
              '🧭 WebView navigation request: ${request.url}',
              name: 'WebViewService',
            );
            
            if (_isDownloadableUrl(request.url)) {
              developer.log('Download detected: ${request.url}');
              _downloadUrlFile(request.url);
              return NavigationDecision.prevent;
            } else if (request.url.startsWith('blob:')) {
              _downloadBlob(request.url);
              return NavigationDecision.prevent;
            }
            
            // Allow https URLs
            if (request.url.startsWith('https://') || request.url.startsWith('http://')) {
              return NavigationDecision.navigate;
            }
            
            // Block other navigation attempts
            developer.log(
              '🚫 Navigation blocked: ${request.url}',
              name: 'WebViewService',
            );
            return NavigationDecision.prevent;
          },"""

content = content.replace(nav_req_old, nav_req_new)

channel_old = """      ..addJavaScriptChannel(
        'FlutterChannel',"""

channel_new = """      ..addJavaScriptChannel(
        'BlobDownloader',
        onMessageReceived: (JavaScriptMessage message) async {
          developer.log('Blob data received', name: 'WebViewService');
          try {
            final Map<String, dynamic> data = jsonDecode(message.message);
            final base64Data = data['base64'];
            final mimeType = data['mimeType'];
            await _saveBlobAsFile(base64Data, mimeType: mimeType);
          } catch (e) {
            developer.log('Error processing blob message: $e', name: 'WebViewService');
          }
        },
      )
      ..addJavaScriptChannel(
        'FlutterChannel',"""

content = content.replace(channel_old, channel_new)

methods = """

  bool _isDownloadableUrl(String url) {
    return url.contains(RegExp(
        r"\\.(pdf|doc|docx|xls|xlsx|zip|rar|jpg|jpeg|png|gif|mp4|mp3)($|\\?)"));
  }

  String _extractBasename(String url) {
    String fileName = Uri.parse(url).pathSegments.last;
    fileName = fileName.split('?').first;
    return fileName;
  }

  Future<void> _downloadUrlFile(String url) async {
    try {
      final deviceDir = await getTemporaryDirectory();
      String fileName = _extractBasename(url);

      if (fileName.isEmpty || !fileName.contains('.')) {
        fileName = 'download_${DateTime.now().millisecondsSinceEpoch}.bin';
      }

      String localPath = '${deviceDir.path}/$fileName';
      developer.log("Downloading to $localPath", name: 'WebViewService');

      Dio dio = Dio();
      await dio.download(
        url,
        localPath,
        onReceiveProgress: (received, total) {
          developer.log('Download progress: ${(received / total * 100).toStringAsFixed(2)}%', name: 'WebViewService');
        },
      );

      final result = await fileOpen.OpenFilex.open(localPath);
      if (result.type != fileOpen.ResultType.done) {
        developer.log('Could not open file: ${result.message}', name: 'WebViewService');
      }
    } catch (e) {
      developer.log('Error downloading file: $e', name: 'WebViewService');
    }
  }

  Future<void> _saveBlobAsFile(String base64Data, {String? mimeType}) async {
    try {
      final bytes = base64Decode(base64Data);
      String extension = 'bin';
      if (mimeType != null) {
        if (mimeType == 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet') extension = 'xlsx';
        else if (mimeType == 'application/pdf') extension = 'pdf';
        else if (mimeType == 'image/jpeg') extension = 'jpg';
        else if (mimeType == 'image/png') extension = 'png';
        else if (mimeType == 'application/msword') extension = 'doc';
        else if (mimeType == 'application/vnd.openxmlformats-officedocument.wordprocessingml.document') extension = 'docx';
      }

      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/blob_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final file = File(filePath);

      await file.writeAsBytes(bytes);
      developer.log('Blob saved to: $filePath', name: 'WebViewService');

      final openResult = await fileOpen.OpenFilex.open(filePath);
      developer.log('OpenFile result: ${openResult.type}', name: 'WebViewService');
    } catch (e) {
      developer.log('Error saving blob file: $e', name: 'WebViewService');
    }
  }

  void _downloadBlob(String blobUrl) {
    developer.log('Attempting to download blob: $blobUrl', name: 'WebViewService');
    final javascriptCode = \"\"\"
    (async function() {
      try {
        const response = await fetch('$blobUrl');
        const blob = await response.blob();
        const mimeType = blob.type;
        const reader = new FileReader();
        reader.onloadend = function() {
          BlobDownloader.postMessage(JSON.stringify({
            base64: reader.result.split(',')[1],
            mimeType: mimeType
          }));
        };
        reader.readAsDataURL(blob);
      } catch (e) {
        console.error('Error fetching blob:', e);
      }
    })();
    \"\"\";
    _webViewController.runJavaScript(javascriptCode);
  }
}
"""

content = content.rsplit('}', 1)[0] + methods

with open(path, 'w') as f:
    f.write(content)

