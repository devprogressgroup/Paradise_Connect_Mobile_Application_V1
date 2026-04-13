import 'package:flutter/material.dart';
import 'package:progress_group/core/constants/colors.dart';






class CustomSelectBox extends StatefulWidget {
  final List<String> items;
  final String hints;
  final double? width;

  const CustomSelectBox({super.key,required this.items,required this.hints,this.width});

  @override
  State<CustomSelectBox> createState() => _CustomSelectBoxState();
}

class _CustomSelectBoxState extends State<CustomSelectBox> {
  String? selectedValue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        width: widget.width,
        height: 30, 
        child: DropdownButtonFormField<String>(
          icon: Icon(Icons.keyboard_arrow_down_rounded),
          value: selectedValue,
          isDense: true, 
          hint:  Text(widget.hints,style: TextStyle(fontSize: 12)),
          decoration: InputDecoration(
            filled: true,
            fillColor: Color(whiteColor),
            contentPadding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),borderSide: BorderSide.none)
          ),
          items: widget.items.map((item) {
            return DropdownMenuItem(value: item,child: Text(item,style: const TextStyle(fontSize: 16)));
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedValue = value;
            });
          },
        ),
      ),
    );
  }
}