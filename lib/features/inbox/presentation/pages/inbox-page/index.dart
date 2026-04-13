import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/utils/widget/custom_header.dart';
import 'package:progress_group/core/utils/widget/custom_search_field.dart';
import 'package:progress_group/core/utils/widget/custom_selectbox.dart';
import 'package:progress_group/features/contact/data/models/selectbox_model.dart';
import 'package:progress_group/features/inbox/data/arguments/inbox_detail_args.dart';
import 'package:progress_group/features/inbox/data/models/dropdown_model.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  final List<SelectBoxModel> selectBoxes = [
    SelectBoxModel(items: ['Owner', 'B', 'C'], hint: "Owner"),
    SelectBoxModel(items: ['1', '2', '3'], hint: "Create Date"),
    SelectBoxModel(items: ['X', 'Y', 'Z'], hint: "Status"),
    SelectBoxModel(items: ['A', 'B', 'C'], hint: "Priority"),
    SelectBoxModel(items: ['Open', 'Close'], hint: "State")];

  final List<DropdownItemModel> itemsGroup = [
    DropdownItemModel(
      id: 1,
      title: "John Doe",
      subtitle: "Hallo",
      image: "https://i.pravatar.cc/150?img=1",
      count: "12",
      time: "12:00",
    ),
    DropdownItemModel(
      id: 2,
      title: "Jane Smith",
      subtitle: "Hai",
      image: "https://i.pravatar.cc/150?img=1",
      count: "1",
      time: "12:00",
    ),
  ];

  final List<DropdownItemModel> itemsPersonal = [
    DropdownItemModel(
      id: 1,
      title: "John Doe",
      subtitle: "Hallo",
      image: "https://i.pravatar.cc/150?img=1",
      count: "12",
      time: "12:00",
    ),
    DropdownItemModel(
      id: 2,
      title: "Jane Smith",
      subtitle: "Hai",
      image: "https://i.pravatar.cc/150?img=1",
      count: "1",
      time: "12:00",
    ),
    DropdownItemModel(
      id: 3,
      title: "John Doe",
      subtitle: "Hallo",
      image: "https://i.pravatar.cc/150?img=1",
      count: "12",
      time: "12:00",
    ),
    DropdownItemModel(
      id: 4,
      title: "Jane Smith",
      subtitle: "Hai",
      image: "https://i.pravatar.cc/150?img=1",
      count: "1",
      time: "12:00",
    ),
    DropdownItemModel(
      id: 5,
      title: "John Doe",
      subtitle: "Hallo",
      image: "https://i.pravatar.cc/150?img=1",
      count: "12",
      time: "12:00",
    ),
    DropdownItemModel(
      id: 6,
      title: "Jane Smith",
      subtitle: "Hai",
      image: "https://i.pravatar.cc/150?img=1",
      count: "1",
      time: "12:00",
    ),
    DropdownItemModel(
      id: 7,
      title: "John Doe",
      subtitle: "Hallo",
      image: "https://i.pravatar.cc/150?img=1",
      count: "12",
      time: "12:00",
    ),
    DropdownItemModel(
      id: 8,
      title: "Jane Smith",
      subtitle: "Hai",
      image: "https://i.pravatar.cc/150?img=1",
      count: "1",
      time: "12:00",
    ),
    DropdownItemModel(
      id: 1,
      title: "John Doe",
      subtitle: "Hallo",
      image: "https://i.pravatar.cc/150?img=1",
      count: "12",
      time: "12:00",
    ),
    DropdownItemModel(
      id: 2,
      title: "Jane Smith",
      subtitle: "Hai",
      image: "https://i.pravatar.cc/150?img=1",
      count: "1",
      time: "12:00",
    ),
    DropdownItemModel(
      id: 3,
      title: "John Doe",
      subtitle: "Hallo",
      image: "https://i.pravatar.cc/150?img=1",
      count: "12",
      time: "12:00",
    ),
    DropdownItemModel(
      id: 4,
      title: "Jane Smith",
      subtitle: "Hai",
      image: "https://i.pravatar.cc/150?img=1",
      count: "1",
      time: "12:00",
    ),
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
                  customSearchField(controller: _searchController,focusNode: _searchFocus),
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
                  SizedBox(height: 20),
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
          Tab(text: "Groups"),
          Tab(text: "Personal"),
        ],
      ),
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      children: [
        _buildList(itemsGroup, Icons.group),
        _buildList(itemsPersonal, Icons.person),
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
}
