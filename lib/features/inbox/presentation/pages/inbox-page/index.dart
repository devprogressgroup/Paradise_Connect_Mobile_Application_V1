import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/utils/widget/custom_header.dart';
import 'package:progress_group/core/utils/widget/custom_search_field.dart';
import 'package:progress_group/core/utils/widget/custom_selectbox.dart';
import 'package:progress_group/features/contact/data/models/selectbox_model.dart';
import 'package:progress_group/features/inbox/data/arguments/inbox_detail_args.dart';
import 'package:progress_group/features/inbox/data/models/dropdown_model.dart';

import '../../../../../core/constants/assets.dart';
import '../../../../../core/utils/widget/custom_button.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  bool isFilterPhone = false;

  final TextEditingController searchTC = TextEditingController();
  final FocusNode searchFN = FocusNode();

  final List<SelectBoxModel> selectBoxes = [
    SelectBoxModel(items: ['Owner', 'B', 'C'], hint: "Owner"),
    SelectBoxModel(items: ['1', '2', '3'], hint: "Create Date"),
    SelectBoxModel(items: ['X', 'Y', 'Z'], hint: "Status"),
    SelectBoxModel(items: ['A', 'B', 'C'], hint: "Priority"),
    SelectBoxModel(items: ['Open', 'Close'], hint: "State")];

  final List<DropdownItemModel> itemsGroup = [
    DropdownItemModel(id: 1,title: "John Doe",subtitle: "Hallo",image: "https://i.pravatar.cc/150?img=1",count: "12",time: "12:00",),
    DropdownItemModel(id: 2,title: "Jane Smith",subtitle: "Hai",image: "https://i.pravatar.cc/150?img=1",count: "1",time: "12:00",),
  ];

  final List<DropdownItemModel> itemsPersonal = [
    DropdownItemModel(id: 1,title: "John Doe",subtitle: "Hallo",image: "https://i.pravatar.cc/150?img=1",count: "12",time: "12:00",),
    DropdownItemModel(id: 2,title: "Jane Smith",subtitle: "Hai",image: "https://i.pravatar.cc/150?img=1",count: "1",time: "12:00",),
    DropdownItemModel(id: 3,title: "John Doe",subtitle: "Hallo",image: "https://i.pravatar.cc/150?img=1",count: "12",time: "12:00",),
    DropdownItemModel(id: 4,title: "Jane Smith",subtitle: "Hai",image: "https://i.pravatar.cc/150?img=1",count: "1",time: "12:00",),
    DropdownItemModel(id: 5,title: "John Doe",subtitle: "Hallo",image: "https://i.pravatar.cc/150?img=1",count: "12",time: "12:00",),
    DropdownItemModel(id: 6,title: "Jane Smith",subtitle: "Hai",image: "https://i.pravatar.cc/150?img=1",count: "1",time: "12:00",),
    DropdownItemModel(id: 7,title: "John Doe",subtitle: "Hallo",image: "https://i.pravatar.cc/150?img=1",count: "12",time: "12:00",),
    DropdownItemModel(id: 8,title: "Jane Smith",subtitle: "Hai",image: "https://i.pravatar.cc/150?img=1",count: "1",time: "12:00",),
    DropdownItemModel(id: 1,title: "John Doe",subtitle: "Hallo",image: "https://i.pravatar.cc/150?img=1",count: "12",time: "12:00",),
    DropdownItemModel(id: 2,title: "Jane Smith",subtitle: "Hai",image: "https://i.pravatar.cc/150?img=1",count: "1",time: "12:00",),
    DropdownItemModel(id: 3,title: "John Doe",subtitle: "Hallo",image: "https://i.pravatar.cc/150?img=1",count: "12",time: "12:00",),
    DropdownItemModel(id: 4,title: "Jane Smith",subtitle: "Hai",image: "https://i.pravatar.cc/150?img=1",count: "1",time: "12:00",),
  ];
    
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          customHeader(context, 'Whatsapp'),
          SizedBox(height: 16),
          Expanded(
            child: Padding(
              padding:  EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: customSearchField(controller: searchTC,focusNode: searchFN)),
                      SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                         setState(() {
                            isFilterPhone = !isFilterPhone;
                          });
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          padding: EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Color(whiteColor),
                            border: Border.all(color: Color(greenPercentColor), width: 1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Image.asset(icContactDetailWA,width: 5,height: 5, color: Color(greenPercentColor),)
                        ),
                      ),
                    ],
                  ),
                  if(isFilterPhone)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Color(whiteColor),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          
                          _buildListPhone(phone: "62856111777", name: "Aulia Mila", image: icContactDetailWA, colorImg: Color(greenPercentColor), onTap: () {_showInboxQRDialog();}),
                          SizedBox(height: 5,),
                          _buildListPhone(phone: "62856111777", name: "Aulia Mila", image: icQR, colorImg: Color(primaryColor), onTap: () {_showInboxQRDialog();}),
                        
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
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
                  SizedBox(height: 10),
                  Expanded(
                    child: DefaultTabController(
                      length: 2,
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: Color(whiteColor),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Color(shadowColor).withOpacity(0.08),
                              blurRadius: 10,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildTabBar(),
                            Expanded(child: _buildTabBarView()),
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
          
        ],
      ),
    );
  }

  Widget _buildListPhone({required String phone, required String name, required String image, required Color colorImg, required VoidCallback onTap}){
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 40,
              alignment: Alignment.center,
              child: Row(
                children: [
                  Image.asset(icContactDetailPhone,width: 15,height: 15,color: Color(primaryColor),),
                  SizedBox(width: 5),
                  Text(phone,style: TextStyle(color: Color(blackColor),fontSize: 16, fontWeight: FontWeight.bold),),
                ],
              ),
            ),
            Row(
              children: [
                Image.asset(icPerson,width: 15,height: 15,color: Color(primaryColor),),
                SizedBox(width: 5),
                Text(name,style: TextStyle(color: Color(grey7Color),fontSize: 14),),
              ],
            ),
          ],
        ),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 40,
            height: 40,
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(whiteColor),
              border: Border.all(color: colorImg, width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.asset(image,width: 15,height: 15,color: colorImg,),
          ),
        )
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 30,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100, 
        borderRadius: BorderRadius.circular(30),
      ),
      child: TabBar(
        dividerColor: Colors.transparent, 
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey,
        indicator: BoxDecoration(
          color: Color(primaryColor), 
          borderRadius: BorderRadius.circular(30),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        tabs: [
          Tab(text: "Personal"),
          Tab(text: "Groups"),
        ],
      ),
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      children: [
        _buildList(itemsPersonal, Icons.person),
        _buildList(itemsGroup, Icons.group),

      ],
    );
  }

  Widget _buildList(List<DropdownItemModel> items, IconData icon) {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        Container(
          margin: const EdgeInsets.only(top: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => Container(height: 1),
            itemBuilder: (context, index) {
              final item = items[index];

              return InkWell(
                onTap: () {
                  context.pushNamed(
                    'detailInbox',
                    extra: InboxDetailArgs(
                      data: item,
                      icon: icon,
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                     
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          item.image,
                          width: 46,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 46,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Color(grey1Color),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon,
                                size: 24, color: Color(blue3Color)),
                          ),
                        ),
                      ),

                      SizedBox(width: 10),

                     
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                           
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  item.subtitle,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),

                           
                            Column(
                              children: [
                                Text(
                                  item.time,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),

                                SizedBox(height: 4),

                               
                                if (item.count != "0")
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Color(redColor),
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: Text(
                                      item.count,
                                      style: TextStyle(
                                        color: Color(whiteColor),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  )
                              ],
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  void _showInboxQRDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black54, 
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), 
          ),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.6,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Scan QR Code for", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      border: Border.all(color: Color(grey1Color)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        "https://api.qrserver.com/v1/create-qr-code/?size=180x180&data=0000011",
                        width: 180,
                        height: 180,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text("Buka WhatsApp > Perangkat Tertaut > Tautkan Perangkat",textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey)),
                  SizedBox(height: 16),
                  customButton((){ Navigator.pop(context); }, "Tutup", colorBg: Color(primaryColor), colorText: Color(whiteColor)),
                  SizedBox(height: 10),
                  customButton((){ Navigator.pop(context); }, "Gunakan Pairing Code", colorBg: Color(primaryColor), colorText: Color(whiteColor)),
            
      
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
