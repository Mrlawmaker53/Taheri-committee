import 'package:flutter/material.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/constants/vehicle_layouts.dart';
import '../../domain/booking_model.dart';

class VehiclePainter extends CustomPainter {
  final String vehicleType;
  final List<Map<String, dynamic>> layout;
  final Map<String, BookingModel> bookings;
  final String currentUserId;
  final String? selectedSeatId;
  final double scale;

  VehiclePainter({
    required this.vehicleType,
    required this.layout,
    required this.bookings,
    required this.currentUserId,
    required this.selectedSeatId,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(scale, scale);
    final cw = vehicleCanvasWidth[vehicleType]!.toDouble();
    final ch = vehicleCanvasHeight[vehicleType]!.toDouble();

    _drawVehicleShell(canvas, cw, ch);
    _drawDoorMarkers(canvas, cw, ch);
    if (vehicleType == 'cruiser') _drawAisle(canvas, cw);
    _drawBoot(canvas, cw, ch);

    for (final seat in layout) {
      _drawSeat(canvas, seat);
    }
  }

  void _drawVehicleShell(Canvas canvas, double cw, double ch) {
    final paint = Paint()
      ..color = const Color(0xFFEFF4F8)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = const Color(0xFFAEC6D8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(10, 10, cw - 20, ch - 56), const Radius.circular(18));
    canvas.drawRRect(rect, paint);
    canvas.drawRRect(rect, borderPaint);

    // Windshield
    final wsPaint = Paint()..color = const Color(0xFFD3EAF9);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(26, 10, cw - 52, 28), const Radius.circular(8)),
        wsPaint);
    _drawText(canvas, 'FRONT', cw / 2, 24, 9, AppTokens.primary);
  }

  void _drawDoorMarkers(Canvas canvas, double cw, double ch) {
    final doorPaint = Paint()
      ..color = const Color(0xFFB5D4F4)
      ..style = PaintingStyle.fill;
    final doorBorder = Paint()
      ..color = const Color(0xFF378ADD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Front doors
    _drawRoundRect(canvas, 14, 60, 14, 44, 4, doorPaint, doorBorder);
    _drawRoundRect(canvas, cw - 28, 60, 14, 44, 4, doorPaint, doorBorder);
    _drawText(canvas, '←', 21, 82, 8, const Color(0xFF0C447C));
    _drawText(canvas, '→', cw - 21, 82, 8, const Color(0xFF0C447C));

    if (vehicleType == 'cruiser') {
      // Sliding doors
      final slidePaint = Paint()..color = const Color(0xFF9FE1CB);
      final slideBorder = Paint()
        ..color = const Color(0xFF1D9E75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      _drawRoundRect(canvas, 14, 150, 14, 52, 4, slidePaint, slideBorder);
      _drawRoundRect(canvas, cw - 28, 150, 14, 52, 4, slidePaint, slideBorder);
      _drawText(canvas, '⇐', 21, 176, 8, const Color(0xFF085041));
      _drawText(canvas, '⇒', cw - 21, 176, 8, const Color(0xFF085041));
    }
  }

  void _drawAisle(Canvas canvas, double cw) {
    final paint = Paint()
      ..color = const Color(0xFFCCE0F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    // Dashed center line in rear section
    double y = 234.0;
    while (y < 378) {
      canvas.drawLine(Offset(cw / 2, y), Offset(cw / 2, y + 6), paint);
      y += 10;
    }
    _drawText(canvas, 'AISLE', cw / 2, 310, 7, const Color(0xFFB0C8D8));
  }

  void _drawBoot(Canvas canvas, double cw, double ch) {
    final bootPaint = Paint()..color = const Color(0xFFC0DD97);
    final bootBorder = Paint()
      ..color = const Color(0xFF639922)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final bootRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(cw / 2 - 52, ch - 56, 104, 28), const Radius.circular(8));
    canvas.drawRRect(bootRect, bootPaint);
    canvas.drawRRect(bootRect, bootBorder);
    _drawText(canvas, 'BOOT', cw / 2, ch - 42, 8, const Color(0xFF27500A));
    _drawText(canvas, 'REAR', cw / 2, ch - 6, 8, const Color(0xFFAABBCC));
  }

  void _drawSeat(Canvas canvas, Map<String, dynamic> seat) {
    final id = seat['id'] as String;
    final type = seat['type'] as String;
    final x = seat['x'] as double;
    final y = seat['y'] as double;
    final w = seat['w'] as double;
    final h = seat['h'] as double;

    // Determine seat state
    Color fill, stroke, textColor;
    String label;
    bool isDriver = type == 'driver';

    if (isDriver) {
      fill = const Color(0xFFF7C1C1);
      stroke = const Color(0xFFE24B4A);
      textColor = const Color(0xFFA32D2D);
      label = 'DRV';
    } else if (bookings[id]?.userId == currentUserId) {
      fill = const Color(0xFF1D9E75);
      stroke = const Color(0xFF0F6E56);
      textColor = Colors.white;
      label = 'YOU';
    } else if (bookings[id] != null) {
      fill = const Color(0xFFF5C4B3);
      stroke = const Color(0xFFD85A30);
      textColor = const Color(0xFF712B13);
      // Show first name, truncated to fit
      final name = bookings[id]!.displayName.split(' ').first;
      label = name.length > 5 ? '${name.substring(0, 5)}.' : name;
    } else if (selectedSeatId == id) {
      fill = const Color(0xFFB5D4F4);
      stroke = const Color(0xFF185FA5);
      textColor = const Color(0xFF042C53);
      label = '✓';
    } else {
      fill = const Color(0xFFE6F1FB);
      stroke = const Color(0xFF378ADD);
      textColor = const Color(0xFF0C447C);
      label = id;
    }

    final fillPaint = Paint()..color = fill;
    final strokePaint = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final rr = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, w, h), const Radius.circular(7));
    canvas.drawRRect(rr, fillPaint);
    canvas.drawRRect(rr, strokePaint);

    // Draw steering wheel on driver seat
    if (isDriver) {
      _drawSteeringWheel(canvas, x + w / 2, y + h / 2 - 3);
    } else {
      _drawText(canvas, label, x + w / 2, y + h / 2, 7.5, textColor,
          bold: true);
    }
  }

  void _drawSteeringWheel(Canvas canvas, double cx, double cy) {
    final paint = Paint()
      ..color = const Color(0xFF666660)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(cx, cy), 9, paint);
    final linePaint = Paint()
      ..color = const Color(0xFF666660)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(cx, cy - 9), Offset(cx, cy + 9), linePaint);
    canvas.drawLine(Offset(cx - 9, cy), Offset(cx + 9, cy), linePaint);
    canvas.drawCircle(
        Offset(cx, cy), 3, Paint()..color = const Color(0xFF888880));
  }

  void _drawRoundRect(Canvas canvas, double x, double y, double w, double h,
      double r, Paint fill, Paint border) {
    final rr =
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r));
    canvas.drawRRect(rr, fill);
    canvas.drawRRect(rr, border);
  }

  void _drawText(
      Canvas canvas, String text, double x, double y, double size, Color color,
      {bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: size,
          color: color,
          fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
          fontFamily: 'sans-serif',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
  }

  @override
  bool shouldRepaint(VehiclePainter old) =>
      old.bookings != bookings ||
      old.selectedSeatId != selectedSeatId ||
      old.scale != scale;
}
