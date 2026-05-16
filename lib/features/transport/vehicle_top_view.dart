import 'package:flutter/material.dart';
import '../../core/models/seat_booking_model.dart';
import 'seat_booking_controller.dart';
// Avoid circular import — inline Get access
import 'package:get/get.dart';

// ─────────────────────────────────────────────────────────
//  VehicleTopView
//  Renders the accurate top-view layout of the vehicle.
//  Scales to available width using LayoutBuilder.
// ─────────────────────────────────────────────────────────
class VehicleTopView extends StatelessWidget {
  final SeatBookingController ctrl;

  const VehicleTopView({super.key, required this.ctrl});

  static const _canvasW = 240.0;
  static const _canvasH = 420.0;
  static const _eecoCanvasW = 160.0;
  static const _eecoCanvasH = 280.0;

  @override
  Widget build(BuildContext context) {
    final isCruiser = ctrl.vehicleType == VehicleType.cruiser;
    final logicalW = isCruiser ? _canvasW : _eecoCanvasW;
    final logicalH = isCruiser ? _canvasH : _eecoCanvasH;

    return LayoutBuilder(
      builder: (_, constraints) {
        final maxW = constraints.maxWidth.clamp(200.0, 320.0);
        final scale = maxW / logicalW;
        final renderH = logicalH * scale;

        return Center(
          child: SizedBox(
            width: maxW,
            height: renderH,
            child: Obx(() => GestureDetector(
                  onTapUp: (details) =>
                      _handleTap(details.localPosition, scale),
                  child: CustomPaint(
                    size: Size(maxW, renderH),
                    painter: _VehiclePainter(
                      layout: ctrl.vehicleType.layout,
                      bookings: ctrl.bookings,
                      selectedSeatId: ctrl.selectedSeatId.value,
                      currentUid: ctrl.myBookedSeatId != null
                          ? ctrl.bookings.entries
                              .firstWhere(
                                  (e) => e.value.userId == ctrl.myBookedSeatId)
                              .value
                              .userId
                          : '',
                      myUid: Get.find<dynamic>().uid as String? ?? '',
                      scale: scale,
                      isCruiser: isCruiser,
                    ),
                  ),
                )),
          ),
        );
      },
    );
  }

  void _handleTap(Offset pos, double scale) {
    for (final seat in ctrl.vehicleType.layout) {
      if (seat.isDriver) continue;
      final rect = Rect.fromLTWH(
        seat.x * scale,
        seat.y * scale,
        seat.w * scale,
        seat.h * scale,
      );
      if (rect.contains(pos)) {
        ctrl.selectSeat(seat.id);
        return;
      }
    }
  }
}

// ─────────────────────────────────────────────────────────
//  Painter
// ─────────────────────────────────────────────────────────
class _VehiclePainter extends CustomPainter {
  final List<SeatDefinition> layout;
  final Map<String, SeatBookingModel> bookings;
  final String selectedSeatId;
  final String currentUid;
  final String myUid;
  final double scale;
  final bool isCruiser;

  _VehiclePainter({
    required this.layout,
    required this.bookings,
    required this.selectedSeatId,
    required this.currentUid,
    required this.myUid,
    required this.scale,
    required this.isCruiser,
  });

  // Theme colors matching the dark glassmorphism app
  static const _bodyFill = Color(0xFF0C0A09);
  static const _bodyBorder = Color(0xFF047857);
  static const _windshield = Color(0xFF1E3A5F);
  static const _windshieldLine = Color(0xFF059669);
  static const _doorFill = Color(0xFF047857);
  static const _doorBorder = Color(0xFF059669);
  static const _aisleFill = Color(0xFF0A1F3D);
  static const _bootFill = Color(0xFF102040);

  // Seat states
  static const _seatAvail = Color(0xFF047857); // blue
  static const _seatAvailBdr = Color(0xFF059669);
  static const _seatMine = Color(0xFF00897B); // teal
  static const _seatMineBdr = Color(0xFF26C6DA);
  static const _seatBooked = Color(0xFF7B1FA2); // purple
  static const _seatBookedBdr = Color(0xFFCE93D8);
  static const _seatSelected = Color(0xFF1976D2);
  static const _seatSelectedBdr = Color(0xFF40C4FF);
  static const _seatDriver = Color(0xFF1A1A2E);
  static const _seatDriverBdr = Color(0xFF9C3030);

  @override
  void paint(Canvas canvas, Size size) {
    _drawBody(canvas, size);
    if (isCruiser) {
      _drawCruiserDetails(canvas, size);
    } else {
      _drawEecoDetails(canvas, size);
    }
    _drawSeats(canvas);
  }

  // ── Vehicle shell ───────────────────────────────────────
  void _drawBody(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _bodyFill.withOpacity(0.85)
      ..style = PaintingStyle.fill;
    final border = Paint()
      ..color = _bodyBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(s(20), s(10), size.width - s(40), size.height - s(20)),
      Radius.circular(s(18)),
    );
    canvas.drawRRect(bodyRect, paint);
    canvas.drawRRect(bodyRect, border);
  }

  // ── Land Cruiser extras ─────────────────────────────────
  void _drawCruiserDetails(Canvas canvas, Size size) {
    // Windshield
    _drawWindshield(canvas, size);
    // Left doors
    _drawDoor(canvas, s(10), s(65), s(12), s(44)); // front left
    _drawDoor(canvas, s(10), s(150), s(12), s(50)); // mid left
    // Right doors
    _drawDoor(canvas, size.width - s(22), s(65), s(12), s(44));
    _drawDoor(canvas, size.width - s(22), s(150), s(12), s(50));
    // Aisle (rear section)
    _drawAisle(canvas, size);
    // Boot
    _drawBoot(canvas, size);
    // Row 2 dashed outline
    final dashPaint = Paint()
      ..color = _doorBorder.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    _drawDashedRect(
        canvas,
        Rect.fromLTWH(s(28), s(148), size.width - s(56), s(56)),
        dashPaint,
        s(4),
        s(3));
  }

  void _drawEecoDetails(Canvas canvas, Size size) {
    _drawWindshield(canvas, size);
    _drawDoor(canvas, s(10), s(36), s(10), s(36));
    _drawDoor(canvas, size.width - s(20), s(36), s(10), s(36));
    _drawBoot(canvas, size);
  }

  void _drawWindshield(Canvas canvas, Size size) {
    final fill = Paint()
      ..color = _windshield
      ..style = PaintingStyle.fill;
    final glow = Paint()
      ..color = _windshieldLine
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(s(30), s(10), size.width - s(60), s(26)),
      Radius.circular(s(8)),
    );
    canvas.drawRRect(rect, fill);
    canvas.drawRRect(rect, glow);
    _drawText(canvas, 'FRONT', Offset(size.width / 2, s(24)), 8.5,
        _windshieldLine.withOpacity(0.8));
  }

  void _drawDoor(Canvas canvas, double x, double y, double w, double h) {
    final fill = Paint()
      ..color = _doorFill
      ..style = PaintingStyle.fill;
    final border = Paint()
      ..color = _doorBorder.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final rr = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, w, h), Radius.circular(s(4)));
    canvas.drawRRect(rr, fill);
    canvas.drawRRect(rr, border);
  }

  void _drawAisle(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _aisleFill
      ..style = PaintingStyle.fill;
    final border = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    final rr = RRect.fromRectAndRadius(
      Rect.fromLTWH(s(104), s(232), s(32), s(150)),
      Radius.circular(s(4)),
    );
    canvas.drawRRect(rr, paint);
    canvas.drawRRect(rr, border);
    _drawText(canvas, 'AISLE', Offset(s(120), s(308)), 7.5,
        Colors.white.withOpacity(0.15),
        vertical: true);
  }

  void _drawBoot(Canvas canvas, Size size) {
    final isCruiserLayout = isCruiser;
    final bootY = isCruiserLayout ? s(382) : s(200);
    final paint = Paint()
      ..color = _bootFill
      ..style = PaintingStyle.fill;
    final border = Paint()
      ..color = _bodyBorder.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final rr = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width / 2 - s(50), bootY, s(100), s(24)),
      Radius.circular(s(6)),
    );
    canvas.drawRRect(rr, paint);
    canvas.drawRRect(rr, border);
    _drawText(canvas, 'BOOT', Offset(size.width / 2, bootY + s(12)), 7.5,
        Colors.white.withOpacity(0.3));
    _drawText(canvas, 'REAR', Offset(size.width / 2, bootY + s(36)), 8.5,
        Colors.white.withOpacity(0.2));
  }

  // ── Seats ───────────────────────────────────────────────
  void _drawSeats(Canvas canvas) {
    for (final seat in layout) {
      final booking = bookings[seat.id];
      final isSelected = selectedSeatId == seat.id;
      final isMyBooking = booking?.userId == _authUid;

      Color fill, border;
      String label;

      if (seat.isDriver) {
        fill = _seatDriver;
        border = _seatDriverBdr;
        label = 'DRV';
        _drawSeatRect(canvas, seat, fill, border, label);
        _drawSteeringWheel(canvas, seat);
        continue;
      }

      if (isMyBooking) {
        fill = _seatMine;
        border = _seatMineBdr;
        label = 'Me';
      } else if (booking != null) {
        fill = _seatBooked;
        border = _seatBookedBdr;
        // First name only, max 5 chars
        label = booking.displayName.split(' ').first;
        if (label.length > 5) label = label.substring(0, 5);
      } else if (isSelected) {
        fill = _seatSelected;
        border = _seatSelectedBdr;
        label = '✓';
      } else {
        fill = _seatAvail;
        border = _seatAvailBdr;
        label = seat.label;
      }

      _drawSeatRect(canvas, seat, fill, border, label);
    }
  }

  String get _authUid {
    try {
      // Access via Get — same pattern used across the app
      final auth = Get.find<dynamic>();
      return (auth.uid as String?) ?? '';
    } catch (_) {
      return '';
    }
  }

  void _drawSeatRect(Canvas canvas, SeatDefinition seat, Color fill,
      Color border, String label) {
    final fillPaint = Paint()
      ..color = fill.withOpacity(0.85)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final rr = RRect.fromRectAndRadius(
      Rect.fromLTWH(s(seat.x), s(seat.y), s(seat.w), s(seat.h)),
      Radius.circular(s(6)),
    );
    canvas.drawRRect(rr, fillPaint);
    canvas.drawRRect(rr, borderPaint);

    _drawText(
      canvas,
      label,
      Offset(s(seat.x + seat.w / 2), s(seat.y + seat.h / 2)),
      7.5,
      Colors.white,
      bold: true,
    );
  }

  void _drawSteeringWheel(Canvas canvas, SeatDefinition seat) {
    final cx = s(seat.x + seat.w / 2);
    final cy = s(seat.y + seat.h / 2 - 3);
    final r = s(9.0);
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawCircle(Offset(cx, cy), r, paint);
    canvas.drawLine(Offset(cx, cy - r), Offset(cx, cy + r), paint);
    canvas.drawLine(Offset(cx - r, cy), Offset(cx + r, cy), paint);
  }

  // ── Helpers ─────────────────────────────────────────────
  double s(double v) => v * scale; // scale logical → pixels

  void _drawText(
      Canvas canvas, String text, Offset center, double size, Color color,
      {bool bold = false, bool vertical = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size * scale,
          fontWeight: bold ? FontWeight.bold : FontWeight.w500,
          letterSpacing: 0.3,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    if (vertical) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(1.5708); // 90°
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    } else {
      tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
    }
  }

  void _drawDashedRect(
      Canvas canvas, Rect rect, Paint paint, double dashLen, double gapLen) {
    final path = Path()..addRect(rect);
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double dist = 0;
      while (dist < metric.length) {
        final end = (dist + dashLen).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(dist, end), paint);
        dist += dashLen + gapLen;
      }
    }
  }

  @override
  bool shouldRepaint(_VehiclePainter old) =>
      old.bookings != bookings || old.selectedSeatId != selectedSeatId;
}
