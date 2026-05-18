import 'package:flutter/material.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/utils/widget/custom_bg_icon.dart';
import 'package:progress_group/features/contact/domain/entities/contact/contact_entity.dart';



class ContactOptionsSheet extends StatelessWidget {
  final ContactEntity contact;
  final int initialTab;

  const ContactOptionsSheet({
    super.key,
    required this.contact,
    this.initialTab = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          
        ],
      ),
    );
  }

  static Widget buildIconLink(
    BuildContext context,
    String asset,
    String label,
    VoidCallback onTap, {
    Color? color,
  }) {

    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: Row(
          children: [
            BgIcon(asset: asset, onTap: null, color: color),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: Color(blue2Color),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
