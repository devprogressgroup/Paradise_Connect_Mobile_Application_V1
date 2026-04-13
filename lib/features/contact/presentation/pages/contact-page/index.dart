import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/utils/widget/custom_header.dart';
import 'package:progress_group/core/utils/widget/custom_search_field.dart';
import 'package:progress_group/core/utils/widget/custom_selectbox.dart';
import 'package:progress_group/features/contact/data/arguments/contact_detail_args.dart';
import 'package:progress_group/features/contact/data/models/person_model.dart';
import 'package:progress_group/features/contact/data/models/selectbox_model.dart';


class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  final List<PersonModel> peopleList = List.generate(20,(index) => PersonModel(name: "User $index",phone: "08123${index.toString().padLeft(6, '0')}",image: "https://i.pravatar.cc/150?img=${index + 1}"));
  final List<SelectBoxModel> selectBoxes = [
    SelectBoxModel(items: ['Owner', 'B', 'C'], hint: "Owner"),
    SelectBoxModel(items: ['1', '2', '3'], hint: "Create Date"),
    SelectBoxModel(items: ['X', 'Y', 'Z'], hint: "Status"),
    SelectBoxModel(items: ['A', 'B', 'C'], hint: "Priority"),
    SelectBoxModel(items: ['Open', 'Close'], hint: "State")];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            customHeader(context, 'Contacts'),
            SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  customSearchField(controller: _searchController,focusNode: _searchFocus,),
                  SizedBox(
                    height: 50,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: selectBoxes.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final item = selectBoxes[index];
                        return CustomSelectBox(
                          items: item.items,
                          hints: item.hint,
                          width: 150,
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: ListView.separated(
                      itemCount: peopleList.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final person = peopleList[index];
                        return _buildListContacts(context, person);
                      },
                    ),
                  )     
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 10), 
        child: FloatingActionButton(
          onPressed: () {
            context.pushNamed('formContact', extra: ContactDetailArgs(page: 0));
          },
          backgroundColor: Color(primaryColor),
          shape: const CircleBorder(),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}

Widget _buildListContacts(BuildContext context,PersonModel person){
  return GestureDetector(
    onTap: () {
      context.pushNamed('detailContact', extra: ContactDetailArgs(data: person, page: 2));
    },
    child: Container(
      height: 70,
      decoration: BoxDecoration(color: Color(whiteColor),borderRadius: const BorderRadius.all(Radius.circular(5)), boxShadow: [
        BoxShadow(
          color: Color(shadowColor).withOpacity(0.08),
          blurRadius: 10,
          offset: const Offset(0, -2)
        ),
      ],),
      padding: const EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(backgroundImage: NetworkImage(person.image)),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(person.name,style: TextStyle(fontSize: 16,color: Color(blue2Color))),
                  Text(person.phone,style: TextStyle(fontSize: 14,color: Color(grey7Color)))
                ],
              ),
            ],
          ),
          Icon(Icons.more_vert,size: 27,color: Color(blackColor))
        ],
      ),
    ),
  );
}
