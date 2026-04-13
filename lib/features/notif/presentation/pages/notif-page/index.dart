import 'package:flutter/material.dart';
import 'package:progress_group/core/constants/assets.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/utils/widget/custom_header.dart';

class NotifPage extends StatefulWidget {
  const NotifPage({super.key});

  @override
  State<NotifPage> createState() => _NotifPageState();
}

class _NotifPageState extends State<NotifPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
         customHeader(context, "Notifikasi", isBack: true, colorBack: Color(primaryColor)),
         SizedBox(height: 16),
         Expanded(child: Padding(
           padding: const EdgeInsets.symmetric(horizontal: 16),
           child: _buildListNotif(),
         )),
        ],
      ),
    );
  }

  Widget _buildListNotif() {
    List<bool> readStatus = List.generate(120, (index) => index % 3 == 0);

    return ListView.builder(
      itemCount: readStatus.length,
      itemBuilder: (context, index) {
        return _buildNotif(
          title: "Notifikasi $index",
          subtitle: "Ini isi notifikasi",
          icon: icContactDetailPhone,
          date: "2022-01-01",
          isRead: readStatus[index], 
        );
      },
    );
  }

  Widget _buildNotif({  required String title,  required String subtitle,  required String icon,  required String date,  required bool isRead,}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              SizedBox(
                width: 50,
                height: 50,
                child: Image.asset(icon, color: Color(greenPercentColor)),
              ),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  Text(subtitle,
                      style: TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
            ],
          ),

          if (!isRead)
            Container(
              height: 12,
              width: 12,
              decoration: BoxDecoration(
                color: Color(redColor),
                borderRadius: BorderRadius.circular(3),
              ),
            )
        ],
      ),
    );
  }
}