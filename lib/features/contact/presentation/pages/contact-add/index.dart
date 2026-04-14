import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:progress_group/core/constants/assets.dart';
import 'package:progress_group/core/utils/widget/custom_button.dart';

import '../../../../../core/constants/colors.dart';
import '../../../../../core/utils/helpers/date_helper.dart';
import '../../../../../core/utils/widget/custom_header.dart';
import '../../../data/arguments/contact_detail_args.dart';
import '../../../data/arguments/contact_dropdown_args.dart';

class ContactAddPage extends StatefulWidget {
  final ContactDetailArgs args;
  const ContactAddPage({super.key, required this.args});

  @override
  State<ContactAddPage> createState() => _ContactAddPageState();
}

class _ContactAddPageState extends State<ContactAddPage> {
  TextEditingController descTC = TextEditingController();
  FocusNode descFN = FocusNode();

  bool isFollowUp = false;
  DateTime? selectedDate;

  File? selectedImage;
  final ImagePicker picker = ImagePicker();


  Future<void> pickImage() async {
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        selectedImage = File(image.path);
      });
    }
  }
  
  Future<void> pickDateTime(BuildContext context) async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(selectedDate ?? now),
    );

    if (time == null) return;

    setState(() {
      selectedDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
           customHeader(context, widget.args.page == 0 ? "Call" : widget.args.page == 1 ? "WhatsApp" : widget.args.page == 2 ? "Meeting" : widget.args.page == 3 ? "Task" : widget.args.page == 4 ? "Visit" : "Attachment", isBack: true, colorBack: Color(primaryColor)),
           SizedBox(height: 16),
           Expanded(child: Padding(
             padding: EdgeInsets.all(16.0),
             child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 widget.args.page == 5 ? _buildAttachment() : _buildForm(),
               ],
             ),
           )),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachment(){
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Color(whiteColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: pickImage,
            child: Container(
              width: double.infinity,
              height: 180,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Color(grey10Color),
                border: Border.all(color: Color(grey11Color)),
              ),
              child: selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        selectedImage!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 58,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Color(whiteColor),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Color(primaryColor)),
                          ),
                          child: Image.asset(icUpload, height: 24, width: 24),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Upload Files",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(blue2Color),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          SizedBox(height: 12),
          Text("Attachment Type",style: TextStyle(fontSize: 12,fontWeight: FontWeight.bold, color: Color(grey2Color))),
          SizedBox(height: 6),
          GestureDetector(
            onTap: () => context.pushNamed('detailContactDropdown', extra: ContactDropdownArgs(title: 'Owner')),
            child: Container(
               width: double.infinity,
               height: 40,
               decoration: BoxDecoration(
                 border: Border.all(color: Color(grey4Color)),
                 borderRadius: BorderRadius.circular(8),
               ),
               padding: EdgeInsets.symmetric(horizontal: 16),
               alignment: Alignment.centerLeft,
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   Text("Select type",style: TextStyle(fontSize: 14, color: Color(grey2Color))),
                   Icon(Icons.keyboard_arrow_down_rounded, color: Color(grey2Color), size: 30),
                 ],
               ), 
             ),
          ),
           SizedBox(height: 12,),
           Text("Description",style: TextStyle(fontSize: 12,fontWeight: FontWeight.bold, color: Color(grey2Color))),
           SizedBox(height: 6),
           TextField(
              maxLines: 4,
              minLines: 3,
              controller: descTC,
              focusNode: descFN,
              onTapOutside: (event) => descFN.unfocus(),
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: "Describe the attachment...",
                hintStyle: TextStyle(color: Color(grey2Color),fontSize: 14),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),borderSide: BorderSide(color: Color(grey11Color))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),borderSide: BorderSide(color: Color(grey11Color))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),borderSide: BorderSide(color: Color(primaryColor))),
              ),
            ),
            SizedBox(height: 20),
           customButton( (){context.pop();}, "Save")

        ],
      ),
    );
  }

  Widget _buildForm(){
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Color(whiteColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Call",style: TextStyle(fontSize: 12,fontWeight: FontWeight.bold, color: Color(grey2Color))),
          SizedBox(height: 6),
          TextField(
              maxLines: 4,
              minLines: 3,
              controller: descTC,
              focusNode: descFN,
              onTapOutside: (event) => descFN.unfocus(),
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: "Describe the call...",
                hintStyle: TextStyle(color: Color(grey2Color),fontSize: 14),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),borderSide: BorderSide(color: Color(grey11Color))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),borderSide: BorderSide(color: Color(grey11Color))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),borderSide: BorderSide(color: Color(primaryColor))),
              ),
            ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Color(grey11Color)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(DateHelper.nowFull(),style: TextStyle(fontSize: 12,fontWeight: FontWeight.bold, color: Color(grey2Color))),
                Icon(Icons.calendar_today, color: Color(grey2Color), size: 16),
              ],
            )),
          SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    "Follow Up Task",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(grey2Color),
                    ),
                  ),
                  SizedBox(width: 12),
                  Transform.scale(
                    scale: 0.8,
                    child: CupertinoSwitch(
                      value: isFollowUp,
                      activeColor: Color(primaryColor),
                      onChanged: (value) {
                        setState(() {
                          isFollowUp = value;
                        });
                      },
                    ),
                  )
                ],
              ),
              if (isFollowUp) ...[
                SizedBox(height: 5),
                Text(
                  "Follow Up In",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(grey2Color),
                  ),
                ),
                SizedBox(height: 6),
                GestureDetector(
                  onTap: () => pickDateTime(context),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Color(grey11Color)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(selectedDate != null? DateHelper.formatFull(selectedDate!): DateHelper.nowFull(), style: TextStyle(fontSize: 12,fontWeight: FontWeight.bold,color: Color(blackColor),),),
                        Icon(Icons.calendar_today,color: Color(primaryColor), size: 16),
                      ],
                    ),
                  ),
                ),
              ],
               SizedBox(height: 32,),
              customButton( (){context.pop();}, "Save")
              
            ],
          )
        ],
      ),
    );
  }
}