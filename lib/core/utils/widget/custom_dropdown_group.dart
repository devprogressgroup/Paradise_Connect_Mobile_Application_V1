import 'package:flutter/material.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/features/inbox/data/models/dropdown_model.dart';

class CustomDropdownGroupInbox extends StatefulWidget {
  final List<DropdownItemModel> items;
  final String hint;
  final Function(DropdownItemModel)? onChanged;
  final Icon icon;

  const CustomDropdownGroupInbox({
    super.key,
    required this.items,
    required this.hint,
    this.onChanged,
    required this.icon
  });

  @override
  State<CustomDropdownGroupInbox> createState() => _CustomDropdownGroupInboxState();
}

class _CustomDropdownGroupInboxState extends State<CustomDropdownGroupInbox> {
  DropdownItemModel? selectedItem;
  bool isOpen = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        /// 🔹 FIELD
        GestureDetector(
          onTap: () {
            setState(() {
              isOpen = !isOpen;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(
                  isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, 
                  color: Color(blue3Color),
                  size: 24,
                ),
                Text(
                  selectedItem?.title ?? widget.hint,
                  style: TextStyle(
                    color: Color(blue3Color),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                
              ],
            ),
          ),
        ),

        /// 🔥 DROPDOWN (tidak ngambang)
        if (isOpen)
          Container(
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.items.length,
              separatorBuilder: (_, __) =>  Container(height: 1),
              itemBuilder: (context, index) {
                final item = widget.items[index];

                return InkWell(
                  onTap: () {
                    setState(() {
                      // selectedItem = item;
                      // isOpen = false;
                    });
                    widget.onChanged?.call(item);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        /// Image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            item.image,
                            width: 46,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Container(
                                  width: 46,
                                  height: 40,
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Color(grey1Color),
                                    shape: BoxShape.circle,

                                  ),
                                  child: Icon(widget.icon.icon, 
                                  
                                  size: 24,color: Color(blue3Color),),
                                ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    item.subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Column(
                                    children: [
                                      Text(
                                        item.time,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Color(redColor),
                                          borderRadius: BorderRadius.circular(24),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Color(shadowColor).withOpacity(0.08),
                                              blurRadius: 10,
                                              offset: const Offset(0, -2),
                                            ),
                                          ],
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
                                  ),
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






class CustomDropdownGroupContact extends StatefulWidget {
  final String hint;
  final bool? bg;
  final Function()? onTap;
  final Widget child; // 🔥 FIX

  const CustomDropdownGroupContact({
    super.key,
    required this.hint,
    this.onTap,
    required this.child,
    this.bg,
  });

  @override
  State<CustomDropdownGroupContact> createState() =>
      _CustomDropdownGroupContactState();
}

class _CustomDropdownGroupContactState extends State<CustomDropdownGroupContact> {
  bool isOpen = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      
      margin: EdgeInsets.only(bottom: !isOpen ? 10 : 0),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                isOpen = !isOpen;
              });
              widget.onTap?.call();
            },
            child: Container(
              color: widget.bg != null ? Colors.transparent : Color(grey10Color) ,
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.hint,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(
                    isOpen
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down, size: 35,
                  ),
                ],
              ),
            ),
          ),
      
      
          /// 🔥 CONTENT DINAMIS
          if (isOpen)
            Container(
              width: double.infinity,
              child: widget.child,
            ),
        ],
      ),
    );
  }
}