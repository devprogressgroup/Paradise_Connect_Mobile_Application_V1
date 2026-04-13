import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/features/contact/data/arguments/contact_dropdown_args.dart';

class DropdownListContact extends StatefulWidget {
  final ContactDropdownArgs args;
  const DropdownListContact({super.key, required this.args});

  @override
  State<DropdownListContact> createState() => _DropdownListContactState();
}

class _DropdownListContactState extends State<DropdownListContact> {
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: SafeArea(
      child: Column( // ✅ langsung Column
        children: [
          /// 🔹 HEADER
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Color(whiteColor),
              border: Border(
                bottom: BorderSide(
                  width: 1,
                  color: Color(grey10Color),
                ),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Icon(
                    Icons.arrow_back,
                    color: Color(primaryColor),
                    size: 27,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded( // ✅ ini baru boleh
                  child: Text(
                    widget.args.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          /// 🔥 CONTENT (BIAR AMAN)
          Expanded(
            child: ListView(
              children: [
                Container(
                  height: 45,
                  width: double.infinity,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Color(whiteColor),
                    border: Border(
                      bottom: BorderSide(
                        width: 1,
                        color: Color(grey10Color),
                      ),
                    ),
                  ),
                  child: Text(
                    "01-PSC",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(grey2Color),
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
}}