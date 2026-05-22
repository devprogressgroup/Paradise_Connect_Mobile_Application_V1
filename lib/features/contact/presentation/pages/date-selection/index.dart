import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/features/contact/data/models/dropdown/date_filter.dart';

class DateFilterPage extends StatefulWidget {
  final String? selectedLabel;
  final String? startDate;
  final String? endDate;
  final bool isSingleSelect;
  const DateFilterPage({super.key, this.selectedLabel, this.startDate, this.endDate, this.isSingleSelect = false});

  @override
  State<DateFilterPage> createState() => _DateFilterPageState();
}

class _DateFilterPageState extends State<DateFilterPage> {
  String? _selectedLabel;
  DateFilterResult? _selectedResult;
  bool _isSelectAll = false;

  late final DateTime _today;
  late final List<_DateOption> _presets;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
    final yesterday = _today.subtract(const Duration(days: 1));
    final startOfWeek = _today.subtract(Duration(days: _today.weekday - 1));
    final startOfLastWeek = startOfWeek.subtract(const Duration(days: 7));
    final endOfLastWeek = startOfWeek.subtract(const Duration(days: 1));
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfLastMonth = DateTime(now.year, now.month - 1, 1);
    final endOfLastMonth = DateTime(now.year, now.month, 0);

    _presets = [
      _DateOption("Today", _today, _today),
      _DateOption("Yesterday", yesterday, yesterday),
      _DateOption("This Week", startOfWeek, _today),
      _DateOption("Last Week", startOfLastWeek, endOfLastWeek),
      _DateOption("This Month", startOfMonth, _today),
      _DateOption("Last Month", startOfLastMonth, endOfLastMonth),
    ];

    _selectedLabel = widget.selectedLabel;
    if (_selectedLabel == 'Select All') {
      _isSelectAll = true;
      _selectedResult = _buildResult('Select All', _presets.last.start, _today);
    } else if (_selectedLabel != null) {
      final match = _presets.where((e) => e.label == _selectedLabel).firstOrNull;
      if (match != null) _selectedResult = _buildResult(match.label, match.start, match.end);
    } else if (widget.startDate != null && widget.endDate != null) {
      // restore from ContactBloc dates when selectedLabel is null (e.g. after widget recreate)
      for (final preset in _presets) {
        if (DateFormat('yyyy-MM-dd').format(preset.start) == widget.startDate &&
            DateFormat('yyyy-MM-dd').format(preset.end) == widget.endDate) {
          _selectedLabel = preset.label;
          _selectedResult = _buildResult(preset.label, preset.start, preset.end);
          break;
        }
      }
    }
  }

  DateFilterResult _buildResult(String label, DateTime start, DateTime end) {
    return DateFilterResult(
      label: label,
      startDate: DateFormat('yyyy-MM-dd').format(start),
      endDate: DateFormat('yyyy-MM-dd').format(end),
    );
  }

  void _selectPreset(_DateOption opt) {
    setState(() {
      _isSelectAll = false;
      if (_selectedLabel == opt.label) {
        _selectedLabel = null;
        _selectedResult = null;
      } else {
        _selectedLabel = opt.label;
        _selectedResult = _buildResult(opt.label, opt.start, opt.end);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _isSelectAll = true;
      _selectedLabel = 'Select All';
      _selectedResult = _buildResult('Select All', _presets.last.start, _today);
    });
  }

  void _clearAll() {
    setState(() {
      _isSelectAll = false;
      _selectedLabel = null;
      _selectedResult = null;
    });
  }

  void _save() {
    if (_selectedResult != null) {
      context.pop(_selectedResult);
    } else {
      context.pop(DateFilterResult(isClear: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(whiteColor),
      body: SafeArea(
        child: Column(
          children: [
            /// HEADER
            Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Color(whiteColor),
                border: Border(bottom: BorderSide(width: 1, color: Color(grey9Color))),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Icon(Icons.arrow_back, color: Color(primaryColor), size: 27),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text("Filter Date",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis),
                  ),
                  TextButton(
                    onPressed: _save,
                    child: Text("Save",
                        style: TextStyle(
                            color: Color(primaryColor), fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
            ),

            /// SELECT ALL / CLEAR ALL
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${_isSelectAll ? _presets.length : (_selectedLabel != null ? 1 : 0)} dipilih',
                      style: TextStyle(fontSize: 13, color: Color(grey5Color))),
                  Row(
                    children: [
                      if (!widget.isSingleSelect) ...[
                        TextButton(
                          onPressed: _selectAll,
                          style: TextButton.styleFrom(
                            minimumSize: Size.zero,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text('Select All',
                              style: TextStyle(
                                  fontSize: 13, color: Color(primaryColor), fontWeight: FontWeight.w600)),
                        ),
                        Text('|', style: TextStyle(color: Color(grey5Color))),
                      ],
                      TextButton(
                        onPressed: _clearAll,
                        style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(widget.isSingleSelect ? 'Clear' : 'Clear All',
                            style: TextStyle(
                                fontSize: 13, color: Color(grey5Color), fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            /// LIST
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _presets.length + 1,
                separatorBuilder: (_, __) => Divider(height: 1, color: Color(grey9Color), indent: 16),
                itemBuilder: (context, index) {
                  if (index < _presets.length) {
                    final opt = _presets[index];
                    final isSelected = _isSelectAll || _selectedLabel == opt.label;
                    return _buildItem(
                      label: opt.label,
                      isSelected: isSelected,
                      onTap: () => _selectPreset(opt),
                    );
                  }
                  return _buildCustomItem();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem({required String label, required bool isSelected, required VoidCallback onTap}) {
    return Material(
      color: isSelected ? Color(grey10Color) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(isSelected ? primaryColor : blue2Color))),
              isSelected
                  ? Icon(Icons.check_circle, color: Color(primaryColor), size: 22)
                  : Icon(Icons.radio_button_unchecked, size: 22, color: Color(grey5Color)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomItem() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          final picked = await showDateRangePicker(
            context: context,
            firstDate: DateTime(2020),
            lastDate: DateTime.now().add(const Duration(days: 365)),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: ColorScheme.light(
                    primary: Color(primaryColor),
                    onPrimary: Colors.white,
                    onSurface: Color(blue2Color),
                  ),
                ),
                child: child!,
              );
            },
          );

          if (picked != null) {
            final label =
                "${DateFormat('dd MMM').format(picked.start)} - ${DateFormat('dd MMM yyyy').format(picked.end)}";
            setState(() {
              _selectedLabel = label;
              _selectedResult = _buildResult(label, picked.start, picked.end);
            });
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Custom Range",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(blue2Color))),
              Icon(Icons.arrow_forward_ios, size: 16, color: Color(grey5Color)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateOption {
  final String label;
  final DateTime start;
  final DateTime end;
  const _DateOption(this.label, this.start, this.end);
}
