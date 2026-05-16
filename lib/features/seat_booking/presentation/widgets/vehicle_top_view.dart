import 'package:flutter/material.dart';
import '../../../../core/constants/vehicle_layouts.dart';
import '../../domain/booking_model.dart';
import 'seat_painter.dart';

class VehicleTopView extends StatelessWidget {
  final String vehicleType;           // "cruiser" | "eeco"
  final Map<String, BookingModel> bookings;
  final String currentUserId;
  final String? selectedSeatId;
  final void Function(String seatId) onSeatTap;

  const VehicleTopView({
    super.key,
    required this.vehicleType,
    required this.bookings,
    required this.currentUserId,
    required this.selectedSeatId,
    required this.onSeatTap,
  });

  @override
  Widget build(BuildContext context) {
    final canvasW = vehicleCanvasWidth[vehicleType]!.toDouble();
    final canvasH = vehicleCanvasHeight[vehicleType]!.toDouble();
    final layout = vehicleLayouts[vehicleType]!;

    return LayoutBuilder(builder: (context, constraints) {
      // Scale canvas to available width, maintain aspect ratio
      final scale = constraints.maxWidth / canvasW;
      final displayH = canvasH * scale;

      return SizedBox(
        width: constraints.maxWidth,
        height: displayH,
        child: GestureDetector(
          onTapUp: (details) {
            // Convert tap position back to canvas space
            final canvasX = details.localPosition.dx / scale;
            final canvasY = details.localPosition.dy / scale;
            for (final seat in layout) {
              final x = seat['x'] as double;
              final y = seat['y'] as double;
              final w = seat['w'] as double;
              final h = seat['h'] as double;
              if (canvasX >= x && canvasX <= x + w &&
                  canvasY >= y && canvasY <= y + h) {
                onSeatTap(seat['id'] as String);
                return;
              }
            }
          },
          child: CustomPaint(
            painter: VehiclePainter(
              vehicleType: vehicleType,
              layout: layout,
              bookings: bookings,
              currentUserId: currentUserId,
              selectedSeatId: selectedSeatId,
              scale: scale,
            ),
          ),
        ),
      );
    });
  }
}
