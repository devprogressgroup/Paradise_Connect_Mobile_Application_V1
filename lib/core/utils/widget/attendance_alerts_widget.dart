import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/constants/assets.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/features/attandance/presentation/state/attandance/attendance_bloc.dart';
import 'package:progress_group/features/attandance/presentation/state/attandance/attendance_state.dart';

class AttendanceAlertsWidget extends StatelessWidget {
  const AttendanceAlertsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AttendanceBloc, AttendanceState>(
      builder: (context, state) {
        if (state is! AttendanceLoaded) return const SizedBox.shrink();

        final today = state.todayData;
        final isClockedIn = today?.clockIn != null;

        bool showCheckIn = false;
        bool isCheckedIn = false;
        if (today != null && today.clockIn != null) {
          isCheckedIn = today.checkInActivity != null;
          if (!isCheckedIn) {
            final clockInTime = DateTime.tryParse(today.clockIn!);
            if (clockInTime != null) {
              showCheckIn = DateTime.now().difference(clockInTime).inMinutes >= 10;
            }
          } else {
            showCheckIn = true;
          }
        }

        final hasAlert = !isClockedIn || (showCheckIn && !isCheckedIn);
        if (!hasAlert) return const SizedBox.shrink();

        return Column(
          children: [
            if (!isClockedIn)
              _buildItem(context, 'Kamu belum Clock In hari ini', Icons.fingerprint),
            if (showCheckIn && !isCheckedIn)
              _buildItem(context, 'Kamu belum Check In hari ini', Icons.location_on_outlined),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildItem(BuildContext context, String message, IconData icon) {
    return GestureDetector(
      onTap: () => context.go('/attandance'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(grey10Color), width: 1)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  color: Color(primaryColor),
                  size: 40,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(blackColor),
                      ),
                    ),
                    Text(
                      'Tap untuk absensi',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(grey2Color)),
                    ),
                  ],
                ),
              ],
            ),
            Image.asset(icNavActivity, width: 30, color: Color(primaryColor)),
          ],
        ),
      ),
    );
  }
}
