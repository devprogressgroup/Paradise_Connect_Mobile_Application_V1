import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/constants/assets.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/utils/widget/custom_search_field.dart';
import 'package:progress_group/features/contact/data/arguments/contact_detail_args.dart';
import 'package:progress_group/features/contact/data/models/activity_model.dart';
import 'package:progress_group/features/contact/presentation/pages/contact-form/index.dart';

import '../../../../../core/utils/widget/custom_bg_icon.dart';
import '../../../../../core/utils/widget/custom_buttomsheet.dart';


class ContactDetailPage extends StatefulWidget {
  final ContactDetailArgs args;

  const ContactDetailPage({super.key, required this.args});

  @override
  State<ContactDetailPage> createState() => _ContactDetailPageState();
}

class _ContactDetailPageState extends State<ContactDetailPage> {

  TextEditingController searchTC = TextEditingController();
  
  FocusNode searchFN = FocusNode();
  
  int selectedIndex = 0;

  final tabs = ["Activity", "About", "Attachment"];

  final Map<String, List<ActivityModel>> activityByMonth = {
      "JAN 2024": [
        ActivityModel(
          title: "Meeting",
          subtitle: "Client A",
          message: "Discuss project",
          color: Colors.purple,
        ),
      ],
      "FEB 2024": [
        ActivityModel(
          title: "Call",
          subtitle: "Team",
          message: "Daily sync",
          color: Colors.green,
        ),
        ActivityModel(
          title: "Review",
          subtitle: "Design",
          message: "Check UI",
          color: Colors.orange,
        ),
      ],
      "DES 2024": [
        ActivityModel(
          title: "Launch",
          subtitle: "Product",
          message: "Go live 🚀",
          color: Colors.blue,
        ),
      ],
    };


  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child:  _selectContact()
      ),
    );
  }

  Widget _selectContact() {
    return Scaffold(
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 10), 
        child: FloatingActionButton(
          onPressed: () {
            showCustomBottomSheet(
              context: context,
              child: _buildContentBSAdd(),
            );
          },
          backgroundColor: Color(primaryColor),
          shape: const CircleBorder(),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: DefaultTabController(
          length: tabs.length,
          child: Column(
            children: [
              SizedBox(
                height: 210,
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      bottom: 50,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        color: Color(whiteColor),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => context.pop(),
                                  child: Icon(Icons.arrow_back, color: Color(primaryColor), size: 27),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Contacts",style: TextStyle(fontSize: 11,color: Color(blue2Color))),
                                    Text(widget.args.data?.name ?? '-',style: const TextStyle(fontSize: 20,fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                BgIcon(asset: icContactDetailPhone),
                                BgIcon(asset: icContactDetailWA),
                                BgIcon(asset: null, onTap: (){showCustomBottomSheet(context: context,child: buildContenBSdit(context));}),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
          
                    Positioned(
                      bottom: 50,
                      left: 16,
                      right: 16,
                      child: Transform.translate(
                        offset: const Offset(0, 25),
                        child: _buildTabBar(),
                      ),
                    ),
                  ],
                ),
              ),
          
             Expanded(
                child: TabBarView(
                  children: [
                    _buildActivityContent(),
                    ContactFormPage(args: ContactDetailArgs(page: 2)),
                    _buildAttachmentContent(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildContentBSAdd(){
    return Container(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Add...",style: TextStyle(fontSize: 18,fontWeight: FontWeight.w700)),
            ],
          ),
          SizedBox(height: 5),
          buildIconLink(icContactDetailPhone, "Phone", (){context.pushNamed('addContact', extra: ContactDetailArgs(page: 0));}),
          buildIconLink(icContactDetailWA, "WhatsApp", (){context.pushNamed('addContact', extra: ContactDetailArgs(page: 1));}),
          buildIconLink(icContactDetailMeeting, "Meeting", (){context.pushNamed('addContact', extra: ContactDetailArgs(page: 2));}),
          buildIconLink(icContactDetailReminder, "Task", (){context.pushNamed('addContact', extra: ContactDetailArgs(page: 3));}),
          buildIconLink(icContactDetailVisit, "Visit", (){context.pushNamed('addContact', extra: ContactDetailArgs(page: 4));}),
          buildIconLink(icSidebarSalesKit,color: Color(primaryColor), "Attachment",(){context.pushNamed('addContact', extra: ContactDetailArgs(page: 5));})
        ],
      ),
    );
  }
  
  Widget _buildTabBar() {
    return Container(
      height: 40,
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Color(grey1Color),
        borderRadius: BorderRadius.circular(24),
      ),
      child: TabBar(
        dividerColor: Colors.transparent,
        labelColor: Color(whiteColor),
        unselectedLabelColor: Color(blue2Color),
        indicator: BoxDecoration(color: Color(primaryColor),borderRadius: BorderRadius.circular(24)),
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: TextStyle(fontWeight: FontWeight.w700,fontSize: 14,),
        tabs: tabs.map((e) => Tab(text: e)).toList(),
      ),
    );
  }

  Widget _buildActivityContent() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: activityByMonth.entries.map((entry) {
        final month = entry.key;
        final activities = entry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              month,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(blackColor),
              ),
            ),
            const SizedBox(height: 10),
            Column(
              children: activities.map((item) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(whiteColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 50,
                        width: 5,
                        decoration: BoxDecoration(
                          color: Color(purpleColor),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),

                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(blackColor),
                              ),
                            ),
                            Text(
                              item.subtitle,
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(grey7Color),
                              ),
                            ),
                            Text(
                              item.message,
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(blackColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildAttachmentContent(){
    return Column(
      children: [
        customSearchField(controller: searchTC, focusNode: searchFN),
        SizedBox(height: 9),
        Container(
          width: double.infinity,
            margin: const EdgeInsets.only(bottom: 9),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(whiteColor),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                ),
              ],
            ),
          child: Row(
            children: [
              BgIcon(asset: icUpload, onTap: (){context.pushNamed('addContact', extra: ContactDetailArgs(page: 5));}, color: Color(primaryColor)),
              SizedBox(width: 10),
              Column(
                children: [
                  Text("Add New File",style: TextStyle(fontSize: 14,fontWeight: FontWeight.w700, color: Color(primaryColor))),
                  Text("upload new file",style: TextStyle(fontSize: 12,fontWeight: FontWeight.w400, color: Color(grey7Color))),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: 10,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(whiteColor),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [ 
                    BgIcon(asset: icAttacment, onTap: (){}),
                    SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Attachment",style: TextStyle(fontSize: 14,fontWeight: FontWeight.w700)),
                        Text("Attachment",style: TextStyle(fontSize: 12,fontWeight: FontWeight.w400)),
                      ],
                    ),
                    Spacer(),
                    BgIcon(asset: null, onTap: (){}),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}


  Widget buildContenBSdit(BuildContext context){
    return Container(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildIconLink(icEdit, "Edit Contact", (){context.pushNamed('formContact', extra: ContactDetailArgs(page: 1));}),
          buildIconLink(icDelete, "Delete Contact", (){}),
          buildIconLink(icShare, "Share Contact", (){}),

        ],
      ),
    );
  }

  

  Widget buildIconLink(String asset, String label, VoidCallback onTap, {Color? color}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            BgIcon(asset: asset, onTap: null, color: color),
            SizedBox(width: 10),
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

