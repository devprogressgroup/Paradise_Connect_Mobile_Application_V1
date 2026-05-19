import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../constants/colors.dart';

class _ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const _ShimmerBox({required this.width, required this.height, this.borderRadius = 8});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

Widget _shimmerWrap({required Widget child}) {
  return Shimmer.fromColors(
    baseColor: Color(grey8Color),
    highlightColor: Color(grey4Color),
    child: child,
  );
}

// ─── Contact List Item ────────────────────────────────────────────────────────
class ShimmerContactItem extends StatelessWidget {
  const ShimmerContactItem({super.key});

  @override
  Widget build(BuildContext context) {
    return _shimmerWrap(
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5),
        ),
        padding: const EdgeInsets.all(10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  const _ShimmerBox(width: 40, height: 40, borderRadius: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _ShimmerBox(width: double.infinity, height: 14),
                        const SizedBox(height: 6),
                        _ShimmerBox(width: 140, height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const _ShimmerBox(width: 27, height: 27, borderRadius: 4),
          ],
        ),
      ),
    );
  }
}

Widget buildContactListShimmer() {
  return ListView.separated(
    physics: const NeverScrollableScrollPhysics(),
    shrinkWrap: true,
    itemCount: 8,
    separatorBuilder: (_, __) => const SizedBox(height: 10),
    itemBuilder: (_, __) => const ShimmerContactItem(),
  );
}

// ─── Activity / Timeline Item ─────────────────────────────────────────────────
// Matches: Container(margin:bottom10, padding:12, radius:12) with left-border accent + 3 text lines
class ShimmerActivityItem extends StatelessWidget {
  const ShimmerActivityItem({super.key});

  @override
  Widget build(BuildContext context) {
    return _shimmerWrap(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ShimmerBox(width: 100, height: 10),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(color: Color(grey3Color), borderRadius: BorderRadius.circular(12)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Container(
                  //   width: 5,
                  //   height: 60,
                  //   decoration: BoxDecoration(
                  //     color: Colors.white,
                  //     borderRadius: BorderRadius.circular(4),
                  //   ),
                  // ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ShimmerBox(width: 160, height: 13),
                          const SizedBox(height: 6),
                          _ShimmerBox(width: 100, height: 11),
                          const SizedBox(height: 6),
                          _ShimmerBox(width: double.infinity, height: 11),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget buildActivityShimmer() {
  return ListView.builder(
    physics: const NeverScrollableScrollPhysics(),
    shrinkWrap: true,
    itemCount: 6,
    itemBuilder: (_, __) => const ShimmerActivityItem(),
  );
}

// ─── Attachment Item ──────────────────────────────────────────────────────────
// Matches: padding(15h,10v), radius 16, 44x44(r12) thumb, 3 text lines, 44x44 right button
class ShimmerAttachmentItem extends StatelessWidget {
  const ShimmerAttachmentItem({super.key});

  @override
  Widget build(BuildContext context) {
    return _shimmerWrap(
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const _ShimmerBox(width: 44, height: 44, borderRadius: 12),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ShimmerBox(width: double.infinity, height: 13),
                  const SizedBox(height: 5),
                  _ShimmerBox(width: 120, height: 11),
                  const SizedBox(height: 4),
                  _ShimmerBox(width: 160, height: 10),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const _ShimmerBox(width: 44, height: 44, borderRadius: 14),
          ],
        ),
      ),
    );
  }
}

Widget buildAttachmentShimmer() {
  return ListView.builder(
    physics: const NeverScrollableScrollPhysics(),
    shrinkWrap: true,
    itemCount: 6,
    itemBuilder: (_, __) => const ShimmerAttachmentItem(),
  );
}

// ─── Inbox Item ───────────────────────────────────────────────────────────────
// Matches: padding all(10), 46x40 rect avatar (r8), name+phone left, time+badge(18x18) right
class ShimmerInboxItem extends StatelessWidget {
  const ShimmerInboxItem({super.key});

  @override
  Widget build(BuildContext context) {
    return _shimmerWrap(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            const _ShimmerBox(width: 46, height: 40, borderRadius: 8),
            const SizedBox(width: 10),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ShimmerBox(width: 150, height: 13),
                      const SizedBox(height: 6),
                      _ShimmerBox(width: 100, height: 11),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ShimmerBox(width: 50, height: 10),
                      const SizedBox(height: 6),
                      const _ShimmerBox(width: 18, height: 18, borderRadius: 9),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget buildInboxShimmer() {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
    ),
    child: ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: 10,
      separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
      itemBuilder: (_, __) => const ShimmerInboxItem(),
    ),
  );
}

Widget buildHomeTaskShimmer() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _shimmerWrap(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _ShimmerBox(width: 130, height: 16),
            _ShimmerBox(width: 50, height: 12),
          ],
        ),
      ),
      const SizedBox(height: 8),
      Container(
        height: 240,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: _shimmerWrap(
          child: Column(
            children: List.generate(3, (_) => Container(
              height: 60,
              margin: const EdgeInsets.symmetric(horizontal: 6,vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
             
            )),
          ),
        ),
      ),
    ],
  );
}

// ─── Home Chart ───────────────────────────────────────────────────────────────
Widget buildHomeChartShimmer() {
  return _shimmerWrap(
    child: SizedBox(
      height: 150,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            7,
            (i) => _ShimmerBox(
              width: 28,
              height: 40.0 + (i % 3) * 30,
              borderRadius: 4,
            ),
          ),
        ),
      ),
    ),
  );
}

// ─── Saleskit Card ────────────────────────────────────────────────────────────
// Matches: padding bottom 16, height 141, radius 16, centered Column: logo+title+subtitle
class ShimmerSaleskitCard extends StatelessWidget {
  const ShimmerSaleskitCard({super.key});

  @override
  Widget build(BuildContext context) {
    return _shimmerWrap(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 141,
            width: double.infinity,
            color: Colors.white,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const _ShimmerBox(width: 60, height: 40, borderRadius: 8),
                const SizedBox(height: 8),
                _ShimmerBox(width: 160, height: 14),
                const SizedBox(height: 6),
                _ShimmerBox(width: 220, height: 11),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget buildSaleskitShimmer() {
  return ListView.builder(
    physics: const NeverScrollableScrollPhysics(),
    shrinkWrap: true,
    itemCount: 5,
    itemBuilder: (_, __) => const ShimmerSaleskitCard(),
  );
}

// ─── Attendance Item ──────────────────────────────────────────────────────────
// Matches: padding(4v,8h), Row: 70x40(r6) date box + icon+text col + 2x40 divider + icon+text col
Widget buildAttendanceShimmer() {
  return ListView.builder(
    physics: const NeverScrollableScrollPhysics(),
    shrinkWrap: true,
    itemCount: 6,
    itemBuilder: (_, __) => _shimmerWrap(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _ShimmerBox(width: 70, height: 40, borderRadius: 6),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ShimmerBox(width: 20, height: 20, borderRadius: 4),
                  const SizedBox(height: 4),
                  _ShimmerBox(width: 60, height: 11),
                ],
              ),
            ),
            Container(width: 2, height: 40, color: Colors.white),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ShimmerBox(width: 20, height: 20, borderRadius: 4),
                  const SizedBox(height: 4),
                  _ShimmerBox(width: 60, height: 11),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ─── Profile ──────────────────────────────────────────────────────────────────
// Matches: SingleChildScrollView → Container(radius24, padding16): Row(60x60 circle + name col) + NIK + divider + 4 fields + buttons
Widget buildProfileShimmer() {
  return SingleChildScrollView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.all(16),
    child: _shimmerWrap(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _ShimmerBox(width: 60, height: 60, borderRadius: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ShimmerBox(width: double.infinity, height: 16),
                      const SizedBox(height: 6),
                      _ShimmerBox(width: 120, height: 12),
                      const SizedBox(height: 4),
                      _ShimmerBox(width: 90, height: 11),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _ShimmerBox(width: 180, height: 12),
            const SizedBox(height: 16),
            Container(height: 1, color: Colors.white),
            const SizedBox(height: 16),
            ...List.generate(4, (_) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ShimmerBox(width: 80, height: 12),
                  const SizedBox(height: 6),
                  _ShimmerBox(width: double.infinity, height: 48, borderRadius: 14),
                ],
              ),
            )),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _ShimmerBox(width: double.infinity, height: 48, borderRadius: 14)),
                const SizedBox(width: 20),
                Expanded(child: _ShimmerBox(width: double.infinity, height: 48, borderRadius: 14)),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

// ─── Notification Item ────────────────────────────────────────────────────────
// Matches: Container(margin:bottom10, padding:16h/12v, radius:10, white), Row spaceBetween: [circle+lines] + [icon]
Widget buildNotifShimmer() {
  return ListView.builder(
    physics: const NeverScrollableScrollPhysics(),
    shrinkWrap: true,
    itemCount: 8,
    itemBuilder: (_, __) => _shimmerWrap(
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const _ShimmerBox(width: 40, height: 40, borderRadius: 20),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ShimmerBox(width: 140, height: 13),
                    const SizedBox(height: 6),
                    _ShimmerBox(width: 160, height: 11),
                    const SizedBox(height: 4),
                    _ShimmerBox(width: 100, height: 10),
                  ],
                ),
              ],
            ),
            const _ShimmerBox(width: 30, height: 30, borderRadius: 4),
          ],
        ),
      ),
    ),
  );
}

// ─── Site Plan ────────────────────────────────────────────────────────────────
Widget buildSiteplanShimmer() {
  return _shimmerWrap(
    child: Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _ShimmerBox(width: double.infinity, height: 40, borderRadius: 8),
        ),
      ],
    ),
  );
}

// ─── Message / Chat Item ──────────────────────────────────────────────────────
// Matches: left has 40x40 circle + name+time row + bubble(topLeft:0); right has time+name row + bubble(topRight:0)
class ShimmerMessageItem extends StatelessWidget {
  final bool isMe;
  const ShimmerMessageItem({super.key, this.isMe = false});

  @override
  Widget build(BuildContext context) {
    return _shimmerWrap(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: isMe ? _buildRight() : _buildLeft(),
      ),
    );
  }

  Widget _buildLeft() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const _ShimmerBox(width: 40, height: 40, borderRadius: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ShimmerBox(width: 80, height: 11),
                const SizedBox(width: 6),
                _ShimmerBox(width: 40, height: 10),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              width: 180,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12).copyWith(topLeft: Radius.zero),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRight() {
    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ShimmerBox(width: 40, height: 10),
              const SizedBox(width: 6),
              _ShimmerBox(width: 80, height: 11),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            width: 180,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12).copyWith(topRight: Radius.zero),
            ),
          ),
        ],
      ),
    );
  }
}

Widget buildMessageShimmer() {
  return ListView.builder(
    physics: const NeverScrollableScrollPhysics(),
    shrinkWrap: true,
    reverse: true,
    itemCount: 10,
    itemBuilder: (_, i) => ShimmerMessageItem(isMe: i % 3 == 0),
  );
}

// ─── Task Item ────────────────────────────────────────────────────────────────
// Matches: padding(16h,5v), bottom border, Row: 40px circle + 3 text lines + 30px icon right
Widget buildTaskShimmer() {
  return _shimmerWrap(
    child: Column(
      children: List.generate(
        6,
        (_) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.white)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const _ShimmerBox(width: 40, height: 40, borderRadius: 20),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ShimmerBox(width: 120, height: 14),
                      const SizedBox(height: 5),
                      _ShimmerBox(width: 100, height: 12),
                      const SizedBox(height: 4),
                      _ShimmerBox(width: 140, height: 12),
                    ],
                  ),
                ],
              ),
              const _ShimmerBox(width: 30, height: 30, borderRadius: 4),
            ],
          ),
        ),
      ),
    ),
  );
}

// ─── Form / Detail Loading ────────────────────────────────────────────────────
Widget buildFormShimmer() {
  return _shimmerWrap(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(
          8,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShimmerBox(width: 100, height: 10),
                const SizedBox(height: 6),
                _ShimmerBox(width: double.infinity, height: 44, borderRadius: 8),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
