import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

// ─── BASE SHIMMER BOX ────────────────────────────────────────────────────────
class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF292524),
      highlightColor: const Color(0xFF2A3D8A),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF292524),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

// ─── SHIMMER CIRCLE (avatar) ─────────────────────────────────────────────────
class ShimmerCircle extends StatelessWidget {
  final double size;
  const ShimmerCircle({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF292524),
      highlightColor: const Color(0xFF2A3D8A),
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Color(0xFF292524),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ─── DASHBOARD SHIMMER ───────────────────────────────────────────────────────
class DashboardShimmer extends StatelessWidget {
  const DashboardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerBox(
              width: double.infinity, height: 100, borderRadius: 16),
          const SizedBox(height: 24),
          const ShimmerBox(width: 120, height: 16),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: List.generate(
              4,
              (_) => const ShimmerBox(
                  width: double.infinity,
                  height: double.infinity,
                  borderRadius: 16),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: List.generate(
              3,
              (i) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 2 ? 8 : 0),
                  child: const ShimmerBox(
                      width: double.infinity, height: 72, borderRadius: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── LIST TILE SHIMMER ───────────────────────────────────────────────────────
class ListTileShimmer extends StatelessWidget {
  const ListTileShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          ShimmerCircle(size: 44),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: double.infinity, height: 14),
                SizedBox(height: 8),
                ShimmerBox(width: 160, height: 12),
              ],
            ),
          ),
          SizedBox(width: 12),
          ShimmerBox(width: 60, height: 24, borderRadius: 12),
        ],
      ),
    );
  }
}

// ─── LIST SHIMMER (multiple tiles) ───────────────────────────────────────────
class ListShimmer extends StatelessWidget {
  final int itemCount;
  const ListShimmer({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(itemCount, (_) => const ListTileShimmer()),
    );
  }
}

// ─── CARD SHIMMER ────────────────────────────────────────────────────────────
class CardShimmer extends StatelessWidget {
  final double height;
  const CardShimmer({super.key, this.height = 120});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ShimmerBox(
        width: double.infinity,
        height: height,
        borderRadius: 12,
      ),
    );
  }
}

// ─── CARD LIST SHIMMER ───────────────────────────────────────────────────────
class CardListShimmer extends StatelessWidget {
  final int itemCount;
  final double cardHeight;
  const CardListShimmer({
    super.key,
    this.itemCount = 4,
    this.cardHeight = 120,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        itemCount,
        (_) => CardShimmer(height: cardHeight),
      ),
    );
  }
}

// ─── STAT CARDS SHIMMER ──────────────────────────────────────────────────────
class StatCardsShimmer extends StatelessWidget {
  final int count;
  const StatCardsShimmer({super.key, this.count = 3});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(
          count,
          (i) => Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < count - 1 ? 8 : 0),
              child: const ShimmerBox(
                width: double.infinity,
                height: 80,
                borderRadius: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── EVENT CARD SHIMMER ──────────────────────────────────────────────────────
class EventCardShimmer extends StatelessWidget {
  const EventCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: Container(
          height: 90,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                const Color(0xFF292524).withOpacity(0.8),
                const Color(0xFF292524).withOpacity(0.4),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Shimmer.fromColors(
            baseColor: const Color(0xFF292524),
            highlightColor: const Color(0xFF2A3D8A),
            child: Row(
              children: [
                // Left accent bar with gradient
                Container(
                  width: 3,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF2A3D8A),
                        Color(0xFF292524),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                ),
                // Date section - more compact
                Container(
                  width: 70,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ShimmerBox(width: 25, height: 18, borderRadius: 6),
                      SizedBox(height: 2),
                      ShimmerBox(width: 20, height: 8, borderRadius: 2),
                    ],
                  ),
                ),
                // Subtle divider
                Container(
                  width: 1,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  color: Colors.white.withOpacity(0.06),
                ),
                // Content section - more compact
                const Expanded(
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ShimmerBox(width: 50, height: 8, borderRadius: 3),
                        SizedBox(height: 6),
                        ShimmerBox(
                            width: double.infinity,
                            height: 14,
                            borderRadius: 3),
                        SizedBox(height: 3),
                        Row(
                          children: [
                            ShimmerBox(width: 10, height: 10, borderRadius: 4),
                            SizedBox(width: 4),
                            Expanded(
                                child: ShimmerBox(
                                    width: double.infinity,
                                    height: 11,
                                    borderRadius: 3)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Right section - more compact
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ShimmerBox(width: 40, height: 16, borderRadius: 6),
                      SizedBox(height: 4),
                      ShimmerBox(width: 10, height: 10, borderRadius: 5),
                    ],
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

// ─── MEMBER CARD SHIMMER ─────────────────────────────────────────────────────
class MemberCardShimmer extends StatelessWidget {
  const MemberCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF292524).withOpacity(0.8),
            const Color(0xFF292524).withOpacity(0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Shimmer.fromColors(
        baseColor: const Color(0xFF292524),
        highlightColor: const Color(0xFF2A3D8A),
        child: Column(
          children: [
            // Top accent bar with gradient
            Container(
              height: 3,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF2A3D8A),
                    Color(0xFF292524),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(10, 12, 10, 8), // Reduced padding
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Avatar section - more compact
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: const Color(0xFF2A3D8A), width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2A3D8A).withOpacity(0.3),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const ShimmerCircle(
                              size: 52), // Reduced from 48 to 52 (radius 26)
                        ),
                        // Active status indicator
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50),
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.black, width: 1.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8), // Reduced from 12 to 8
                    // Name placeholder
                    const ShimmerBox(
                        width: double.infinity, height: 12, borderRadius: 4),
                    const SizedBox(height: 2), // Reduced from 6 to 2
                    // Email placeholder
                    const ShimmerBox(
                        width: double.infinity, height: 10, borderRadius: 3),
                    const SizedBox(height: 6), // Reduced from 10 to 6
                    // Role badge placeholder
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A3D8A).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: const Color(0xFF2A3D8A).withOpacity(0.5)),
                      ),
                      child: const ShimmerBox(
                          width: 40, height: 9, borderRadius: 3),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── CONTRIBUTION CARD SHIMMER ───────────────────────────────────────────────
class ContributionCardShimmer extends StatelessWidget {
  const ContributionCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerBox(width: 80, height: 22),
                ShimmerBox(width: 70, height: 24, borderRadius: 12),
              ],
            ),
            SizedBox(height: 10),
            ShimmerBox(width: 180, height: 12),
            SizedBox(height: 6),
            ShimmerBox(width: 120, height: 12),
          ],
        ),
      ),
    );
  }
}

// ─── NOTIFICATION SHIMMER ────────────────────────────────────────────────────
class NotificationShimmer extends StatelessWidget {
  const NotificationShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerCircle(size: 40),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: double.infinity, height: 14),
                SizedBox(height: 6),
                ShimmerBox(width: double.infinity, height: 12),
                SizedBox(height: 6),
                ShimmerBox(width: 80, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── CHART SHIMMER ───────────────────────────────────────────────────────────
class ChartShimmer extends StatelessWidget {
  const ChartShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerBox(width: 160, height: 16),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [20.0, 45.0, 30.0, 60.0, 40.0, 55.0]
                .map((h) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ShimmerBox(
                          width: double.infinity,
                          height: h,
                          borderRadius: 4,
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(
              6,
              (_) => const Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: ShimmerBox(width: double.infinity, height: 10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── PROFILE SHIMMER ─────────────────────────────────────────────────────────
class ProfileShimmer extends StatelessWidget {
  const ProfileShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const ShimmerCircle(size: 80),
          const SizedBox(height: 12),
          const ShimmerBox(width: 160, height: 18),
          const SizedBox(height: 8),
          const ShimmerBox(width: 120, height: 14),
          const SizedBox(height: 4),
          const ShimmerBox(width: 80, height: 24, borderRadius: 12),
          const SizedBox(height: 24),
          ...List.generate(
            4,
            (_) => const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: ShimmerBox(
                width: double.infinity,
                height: 52,
                borderRadius: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── FULL PAGE LOADER (auth/init) ────────────────────────────────────────────
class FullPageLoader extends StatelessWidget {
  final String message;
  const FullPageLoader({super.key, this.message = 'Loading...'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Color(0xFF047857),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── BUTTON LOADER ───────────────────────────────────────────────────────────
class ButtonLoader extends StatelessWidget {
  const ButtonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        color: Colors.white,
      ),
    );
  }
}
