import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'dart:io';

Future<void> createSimpleIcon() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  
  // Background
  final paint = Paint()..color = const Color(0xFFF5EDE4);
  canvas.drawRRect(
    RRect.fromRectAndRadius(const Rect.fromLTWH(0, 0, 1024, 1024), const Radius.circular(256)),
    paint,
  );
  
  // Icon
  final iconPaint = Paint()..color = const Color(0xFF5D4037);
  final iconPath = Path();
  
  // Draw a simple document/report icon
  canvas.drawRRect(
    RRect.fromRectAndRadius(const Rect.fromLTWH(256, 256, 512, 640), const Radius.circular(32)),
    iconPaint,
  );
  
  // Draw lines on the document
  for (int i = 0; i < 5; i++) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(320, 320 + (i * 80), 384, 16),
        const Radius.circular(8),
      ),
      iconPaint,
    );
  }
  
  final picture = recorder.endRecording();
  final image = await picture.toImage(1024, 1024);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  
  final file = File('assets/logo/ez_report_logo.png');
  await file.writeAsBytes(byteData!.buffer.asUint8List());
  
  picture.dispose();
  image.dispose();
}
