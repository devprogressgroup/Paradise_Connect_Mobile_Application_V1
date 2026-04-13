import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/colors.dart';
import '../../../../../core/utils/widget/custom_dropdown_group.dart';
import '../../../data/arguments/contact_detail_args.dart';
import '../../../data/arguments/contact_dropdown_args.dart';

class ContactFormPage extends StatefulWidget {
  final ContactDetailArgs args;
  const ContactFormPage({super.key, required this.args});

  @override
  State<ContactFormPage> createState() => _ContactFormPageState();
}

class _ContactFormPageState extends State<ContactFormPage> {
  TextEditingController emailTC = TextEditingController();
  TextEditingController phoneTC = TextEditingController();
  TextEditingController waTC = TextEditingController();
  TextEditingController FPProductTC = TextEditingController();
  TextEditingController FPCategoryTC = TextEditingController();
  TextEditingController salesExecutiveTC = TextEditingController();
  TextEditingController salesManagerTC = TextEditingController();

  FocusNode emailFN = FocusNode();
  FocusNode phoneFN = FocusNode();
  FocusNode waFN = FocusNode();
  FocusNode FPProducttFN = FocusNode();
  FocusNode FPCategorytFN = FocusNode();  
  FocusNode salesExecutiveFN = FocusNode();
  FocusNode salesManagerFN = FocusNode();
  
  @override
  void dispose() {
    emailTC.dispose();
    phoneTC.dispose();
    waTC.dispose();
    FPProductTC.dispose();
    FPCategoryTC.dispose();
    salesExecutiveTC.dispose();
    salesManagerTC.dispose();
    emailFN.dispose();
    phoneFN.dispose();
    waFN.dispose();
    FPProducttFN.dispose();
    FPCategorytFN.dispose();  
    salesExecutiveFN.dispose();
    salesManagerFN.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child:   _createContact())
    );
  }

  
  Widget _createContact() {
    return Column(
      children: [
        /// 🔹 HEADER
        if (widget.args.page != 2)
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Color(whiteColor),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Icon(Icons.arrow_back,
                          color: Color(primaryColor), size: 27),
                    ),
                    const SizedBox(width: 10),
                    Text(
                     widget.args.page == 1 ? "Edit Contact" : "Create Contact",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    height: 36,
                    width: 100,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: Color(blue3Color),
                    ),
                    child: Text(
                      "Save",
                      style: TextStyle(
                        color: Color(whiteColor),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

        /// 🔥 CONTENT (SCROLLABLE)
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              children: [
                CustomDropdownGroupContact(
                  hint: "Contact Info",
                  child: Column(
                    children: [
                      _buildFieldDown(label: "Owner", value:null, onTap: () {context.pushNamed('detailContactDropdown', extra: ContactDropdownArgs(title: 'Owner'));}),
                      _buildFieldDown(label: "Salutation", value: "Bapak", onTap: () {context.pushNamed('detailContactDropdown', extra: ContactDropdownArgs(title: 'Salutation'));}),
                      _buildField(label: "Email", controller: emailTC, focusNode: emailFN),
                      _buildField(label: "Phone", controller: phoneTC, focusNode: phoneFN),
                      _buildField(label: "Whatsapp", controller: waTC, focusNode: waFN),
                      _buildFieldDown(label: "Status Prospect", value: "50 - SP", onTap: () {context.pushNamed('detailContactDropdown', extra: ContactDropdownArgs(title: 'Status Prospect'));}),
                      _buildFieldDown(label: "First Project Website", value: "PSC", onTap: () {context.pushNamed('detailContactDropdown', extra: ContactDropdownArgs(title: 'First Project Website'));}),
                      _buildField(label: "First Project Product", controller: FPProductTC, focusNode: FPProducttFN),
                      _buildField(label: "First Project Category", controller: FPCategoryTC, focusNode: FPCategorytFN)
                    ],
                  ),
                ),
                CustomDropdownGroupContact(
                  hint: "Sales Information",
                  child: Column(
                    children: [
                      _buildField(label: "Sales Executive", controller: salesExecutiveTC, focusNode: salesExecutiveFN),
                      _buildField(label: "Sales Manager", controller: salesManagerTC, focusNode: salesManagerFN),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFieldDown({  required String label,  String? value,  VoidCallback? onTap,}) {
  final isEmpty = value == null || value.isEmpty;

  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isEmpty)
                  Text(
                    label,
                    style: TextStyle(
                      color: Color(grey2Color),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                Text(
                  isEmpty ? label : value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isEmpty? Color(grey2Color) : Color(blackColor),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_drop_down, size: 28),
        ],
      ),
    ),
  );
}

  Widget _buildField({  required String label,  required TextEditingController controller,  required FocusNode focusNode,}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical:  5, horizontal: 10),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  onTapOutside: (_) => focusNode.unfocus(),
                  style:  TextStyle(fontSize: 12, color: Color(blackColor),fontWeight: FontWeight.w700),
                  decoration:  InputDecoration(
                    isDense: true,
                    label: Text(label, style: TextStyle(fontSize: 12),),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  



}