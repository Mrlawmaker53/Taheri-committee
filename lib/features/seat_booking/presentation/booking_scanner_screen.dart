import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/new_seat_booking_model.dart';
import '../../../core/theme/app_tokens.dart';

/// Admin screen to verify bookings on event day.
/// Supports both manual code entry and (future) QR camera scan.
class BookingScannerScreen extends StatefulWidget {
  final String eventId;
  final String eventTitle;

  const BookingScannerScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  State<BookingScannerScreen> createState() => _BookingScannerScreenState();
}

class _BookingScannerScreenState extends State<BookingScannerScreen> {
  final _codeCtrl = TextEditingController();
  final _db = FirebaseFirestore.instance;

  NewSeatBookingModel? _result;
  bool _isSearching = false;
  String? _errorMsg;
  bool _verified = false;

  Future<void> _lookupBooking(String code) async {
    if (code.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _result = null;
      _errorMsg = null;
      _verified = false;
    });

    try {
      final snap = await _db
          .collection('seatBookings')
          .where('eventId', isEqualTo: widget.eventId)
          .where('bookingCode', isEqualTo: code.trim().toUpperCase())
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        setState(() {
          _errorMsg = 'No booking found with code "${code.trim()}"';
          _isSearching = false;
        });
        return;
      }

      final booking = NewSeatBookingModel.fromFirestore(snap.docs.first);

      if (booking.status == 'cancelled') {
        setState(() {
          _errorMsg = 'This booking was cancelled';
          _result = booking;
          _isSearching = false;
        });
        return;
      }

      setState(() {
        _result = booking;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _errorMsg = 'Error looking up booking: $e';
        _isSearching = false;
      });
    }
  }

  Future<void> _markVerified() async {
    if (_result == null) return;
    try {
      await _db.collection('seatBookings').doc(_result!.id).update({
        'verifiedAt': Timestamp.now(),
      });
      setState(() => _verified = true);
      Get.snackbar(
        'Verified!',
        '${_result!.userName} checked in successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade900,
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to mark verified: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade900);
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.chevronLeft, size: 16),
          onPressed: () => Get.back(),
        ),
        title: const Text('Verify Bookings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Event header ─────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppTokens.heroGradient,
                borderRadius: BorderRadius.circular(AppTokens.radiusCard),
              ),
              child: Row(
                children: [
                  const FaIcon(FontAwesomeIcons.calendarCheck,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.eventTitle,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                        const SizedBox(height: 2),
                        Text('Scan or enter booking code to verify',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Manual entry ─────────────────────────────────────────
            Text('Enter Booking Code',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppTokens.darkTextPrimary
                        : AppTokens.textPrimary)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codeCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'e.g., TC2605150001',
                      prefixIcon: const Icon(Icons.confirmation_number_outlined),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppTokens.radiusInput),
                      ),
                    ),
                    onSubmitted: _lookupBooking,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed:
                        _isSearching ? null : () => _lookupBooking(_codeCtrl.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTokens.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTokens.radiusButton),
                      ),
                    ),
                    child: _isSearching
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const FaIcon(FontAwesomeIcons.magnifyingGlass,
                            size: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Result area ──────────────────────────────────────────
            if (_errorMsg != null) _errorCard(isDark),
            if (_result != null && _errorMsg == null) _resultCard(isDark),
          ],
        ),
      ),
    );
  }

  Widget _errorCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTokens.danger.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        border: Border.all(color: AppTokens.danger.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTokens.danger, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(_errorMsg!,
                style: const TextStyle(
                    color: AppTokens.danger, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _resultCard(bool isDark) {
    final b = _result!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTokens.darkCard : AppTokens.surfaceCard,
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        border: Border.all(
          color: _verified
              ? AppTokens.success
              : AppTokens.primary.withOpacity(0.4),
          width: 2,
        ),
        boxShadow: isDark ? null : AppTokens.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Status indicator ──────────────────────────────────
          if (_verified)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTokens.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTokens.radiusSm),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: AppTokens.success, size: 20),
                  SizedBox(width: 8),
                  Text('VERIFIED',
                      style: TextStyle(
                          color: AppTokens.success,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          letterSpacing: 1)),
                ],
              ),
            ),

          // ── User info ────────────────────────────────────────
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppTokens.primary,
                backgroundImage:
                    b.userAvatar != null && b.userAvatar!.isNotEmpty
                        ? NetworkImage(b.userAvatar!)
                        : null,
                child: b.userAvatar == null || b.userAvatar!.isEmpty
                    ? Text(
                        b.userName.isNotEmpty
                            ? b.userName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20))
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.userName,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppTokens.darkTextPrimary
                                : AppTokens.textPrimary)),
                    if (b.teamName.isNotEmpty)
                      Text(b.teamName,
                          style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppTokens.darkTextSecondary
                                  : AppTokens.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),

          // ── Booking details ──────────────────────────────────
          _infoRow('Booking Code', b.bookingCode, isDark),
          _infoRow('Status', b.status.toUpperCase(), isDark),
          _infoRow('Booked At',
              DateFormat('dd MMM yyyy, hh:mm a').format(b.bookedAt), isDark),
          if (b.userMobile != null && b.userMobile!.isNotEmpty)
            _infoRow('Mobile', b.userMobile!, isDark),

          // ── Verify button ────────────────────────────────────
          if (!_verified) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _markVerified,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Mark as Verified',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTokens.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppTokens.radiusButton),
                  ),
                ),
              ),
            ),
          ],

          // ── Scan next button ─────────────────────────────────
          if (_verified) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  _codeCtrl.clear();
                  setState(() {
                    _result = null;
                    _errorMsg = null;
                    _verified = false;
                  });
                },
                icon: const FaIcon(FontAwesomeIcons.arrowRotateRight, size: 14),
                label: const Text('Scan Next'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTokens.primary,
                  side: const BorderSide(color: AppTokens.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppTokens.radiusButton),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppTokens.darkTextSecondary
                      : AppTokens.textSecondary)),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppTokens.darkTextPrimary
                      : AppTokens.textPrimary)),
        ],
      ),
    );
  }
}
