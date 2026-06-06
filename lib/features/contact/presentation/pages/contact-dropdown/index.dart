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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<int> _tempSelectedIds = [];

  @override
  void initState() {
    super.initState();
    if (widget.args.isMultiSelect) {
      _tempSelectedIds = List.from(widget.args.selectedIds ?? []);
    } else if (widget.args.selectedId != null) {
      _tempSelectedIds = [widget.args.selectedId!];
    }
  }

  List<OwnerDropdownItem> get _filteredItems {
    final items = _searchQuery.isEmpty
        ? widget.args.items
        : widget.args.items.where((item) {
            final q = _searchQuery.toLowerCase();
            return item.name.toLowerCase().contains(q) ||
                (item.subtitle?.toLowerCase().contains(q) ?? false);
          }).toList();
    return items..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(whiteColor),
      body: SafeArea(
        child: Column(
          children: [
            /// 🔹 HEADER
            Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Color(whiteColor),
                border: Border(
                  bottom: BorderSide(width: 1, color: Color(grey9Color)),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Icon(Icons.arrow_back, color: Color(primaryColor), size: 27),
                  ),
                  const SizedBox(width: 10),
                   Expanded(
                    child: Text(
                      widget.args.title,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.args.isMultiSelect)
                    TextButton(
                      onPressed: () {
                        final selectedItems = widget.args.items
                            .where((item) => _tempSelectedIds.contains(item.id))
                            .toList();
                        context.pop(selectedItems);
                      },
                      child: Text("Save",
                          style: TextStyle(
                              color: Color(primaryColor),
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                    )
                  else if (widget.args.allowClear && _tempSelectedIds.isNotEmpty)
                    TextButton(
                      onPressed: () => context.pop(<OwnerDropdownItem>[]),
                      child: Text("Clear",
                          style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                    ),
                ],
              ),
            ),

            /// 🔍 SEARCH
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Color(primaryColor)),
                  borderRadius: BorderRadius.circular(10)
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    hintStyle: TextStyle(color: Color(grey5Color), fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: Color(grey5Color)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            child: Icon(Icons.close, color: Color(grey5Color)),
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.transparent,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),

            /// SELECT ALL / CLEAR ALL
            if (widget.args.isMultiSelect)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${_tempSelectedIds.length} dipilih',
                        style: TextStyle(fontSize: 13, color: Color(grey5Color))),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _tempSelectedIds = widget.args.items
                                  .where((e) => e.id != null)
                                  .map((e) => e.id!)
                                  .toList();
                            });
                          },
                          style: TextButton.styleFrom(
                            minimumSize: Size.zero,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text('Select All',
                              style: TextStyle(fontSize: 13, color: Color(primaryColor), fontWeight: FontWeight.w600)),
                        ),
                        Text('|', style: TextStyle(color: Color(grey5Color))),
                        TextButton(
                          onPressed: () => setState(() => _tempSelectedIds = []),
                          style: TextButton.styleFrom(
                            minimumSize: Size.zero,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text('Clear All',
                              style: TextStyle(fontSize: 13, color: Color(grey5Color), fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            /// 🔥 LIST
            Expanded(
              child: _filteredItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 48, color: Color(grey5Color)),
                          const SizedBox(height: 8),
                          Text(
                            'Tidak ditemukan',
                            style: TextStyle(color: Color(grey5Color), fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _filteredItems.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: Color(grey9Color),
                        indent: 72,
                      ),
                      itemBuilder: (context, index) {
                        final item = _filteredItems[index];
                        final isSelected = _tempSelectedIds.contains(item.id) ||
                            (item.id == null &&
                                widget.args.selectedName != null &&
                                item.name == widget.args.selectedName);

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              if (widget.args.isMultiSelect) {
                                setState(() {
                                  if (isSelected) {
                                    _tempSelectedIds.remove(item.id);
                                  } else {
                                    if (item.id != null) _tempSelectedIds.add(item.id!);
                                  }
                                });
                              } else {
                                context.pop(item);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              color: isSelected ? Color(grey10Color) : Color(whiteColor),
                              child: Row(
                                children: [

                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: Color(isSelected ? primaryColor : blue2Color),
                                          ),
                                        ),
                                        if (item.subtitle != null && item.subtitle!.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            item.subtitle!,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Color(grey5Color),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (widget.args.isMultiSelect)
                                    Checkbox(
                                      value: isSelected,
                                      activeColor: Color(primaryColor),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                      onChanged: (val) {
                                        setState(() {
                                          if (val == true) {
                                            if (item.id != null) _tempSelectedIds.add(item.id!);
                                          } else {
                                            _tempSelectedIds.remove(item.id);
                                          }
                                        });
                                      },
                                    )
                                  else if (isSelected)
                                    Icon(Icons.check_circle, color: Color(primaryColor), size: 22),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}