import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/utils/widget/custom_buttomsheet.dart';
import 'package:progress_group/core/utils/widget/custom_dropdown_group.dart';
import 'package:progress_group/features/reserve-order/data/models/reserve_order_customer_data.dart';

/// Halaman "Edit Data Pembeli" — field & tampilannya diambil dari
/// `lib/features/reserve-order/presentation/pages/edit/index.dart` di branch `reserve-order`
/// (field underline gaya `ContactFormPage`, section pakai `CustomDropdownGroupContact` yang sudah
/// ada). Daftar field-nya ([reserveCustomerFieldSections]) dipakai bareng oleh tab Customer
/// (read-only) di `ReserveOrderDetailPage`, jadi kalau nambah/ubah field cukup di satu tempat.
///
/// [highlightKey], kalau diisi (dari tap salah satu baris di tab Customer), scroll ke field itu &
/// beri highlight sementara (~3 detik) — gaya sama seperti `ContactFormPage`.
class EditCustomerReserveOrderPage extends StatefulWidget {
  final ReserveOrderCustomerData customer;
  final String? highlightKey;

  const EditCustomerReserveOrderPage({
    super.key,
    required this.customer,
    this.highlightKey,
  });

  @override
  State<EditCustomerReserveOrderPage> createState() =>
      _EditCustomerReserveOrderPageState();
}

class _EditCustomerReserveOrderPageState
    extends State<EditCustomerReserveOrderPage> {
  late Map<String, dynamic> _values;
  final Map<String, TextEditingController> _tc = {};
  final Map<String, GlobalKey> _fieldKeys = {};

  String? _highlightedKey;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _values = Map<String, dynamic>.of(widget.customer.raw);
    _highlightedKey = widget.highlightKey;

    if (_highlightedKey != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToHighlight();
        // Highlight-nya sementara, hilang sendiri — bukan ditunggu sampai user menyentuh layar.
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _highlightedKey = null);
        });
      });
    }
  }

  @override
  void dispose() {
    for (final c in _tc.values) {
      c.dispose();
    }
    super.dispose();
  }

  GlobalKey _keyFor(String key) =>
      _fieldKeys.putIfAbsent(key, () => GlobalKey());

  void _scrollToHighlight() {
    final targetContext = _highlightedKey == null
        ? null
        : _fieldKeys[_highlightedKey]?.currentContext;
    if (targetContext == null) return;
    Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      alignment: 0.2,
    );
  }

  TextEditingController _c(String key) => _tc.putIfAbsent(
    key,
    () => TextEditingController(text: _values[key]?.toString() ?? ''),
  );

  DateTime? _dateValue(String key) {
    final value = _values[key];
    return value == null ? null : DateTime.tryParse('$value');
  }

  /// Bingkai field underline bersama, dipakai semua builder field — highlight-nya (dari
  /// [_highlightedKey]) menyatu ke border-bawah + tint field itu sendiri, gaya sama seperti
  /// `ContactFormPage._buildField`, bukan kotak terpisah yang membungkus field.
  Widget _fieldFrame(
    String key,
    Widget child, {
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
      vertical: 5,
      horizontal: 16,
    ),
  }) {
    final highlighted = key == _highlightedKey;
    return Container(
      key: key == widget.highlightKey ? _keyFor(key) : null,
      padding: padding,
      constraints: const BoxConstraints(minHeight: 50),
      decoration: BoxDecoration(
        color: highlighted
            ? const Color(primaryColor).withValues(alpha: 0.06)
            : const Color(whiteColor),
        border: Border(
          bottom: BorderSide(
            width: highlighted ? 2 : 1,
            color: highlighted
                ? const Color(primaryColor)
                : const Color(grey9Color),
          ),
        ),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_submitting,
      child: Scaffold(
        backgroundColor: const Color(whiteColor),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final section in reserveCustomerFieldSections)
                        CustomDropdownGroupContact(
                          hint: section.title,
                          child: Column(
                            children: [
                              for (final field in section.fields)
                                _buildField(field),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Header ala "Edit Contact" — bar putih polos, tombol kembali kiri, tombol "Save" inline
  /// kanan (bukan bar aksi terpisah di bawah).
  Widget _buildHeader() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(whiteColor),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: const Icon(
              Icons.arrow_back,
              color: Color(primaryColor),
              size: 27,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Edit Data Pembeli',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _submitting ? null : _onSubmit,
            child: Container(
              height: 36,
              width: 100,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: const Color(blue3Color),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(whiteColor),
                      ),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(
                        color: Color(whiteColor),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(ReserveCustomerFieldSpec f) {
    return switch (f.kind) {
      ReserveCustomerFieldKind.text => _textField(f),
      ReserveCustomerFieldKind.date => _dateField(f),
      ReserveCustomerFieldKind.boolChoice => _boolField(f),
      ReserveCustomerFieldKind.option => _optionField(f),
    };
  }

  /// Field teks underline + label mengambang, gaya `ContactFormPage._buildField` — border cuma di
  /// bawah, label jadi hint saat kosong lalu mengambang ke atas begitu diisi/difokus.
  Widget _textField(ReserveCustomerFieldSpec f) {
    final highlighted = f.key == _highlightedKey;
    final labelColor = highlighted
        ? const Color(primaryColor)
        : const Color(grey2Color);
    return _fieldFrame(
      f.key,
      TextField(
        controller: _c(f.key),
        keyboardType: f.keyboardType,
        inputFormatters: f.key == 'cust_ktp'
            ? [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(16),
              ]
            : null,
        minLines: f.maxLines > 1 ? f.maxLines : null,
        maxLines: null,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: highlighted
              ? const Color(primaryColor)
              : const Color(blackColor),
        ),
        decoration: InputDecoration(
          isDense: true,
          label: Text(
            f.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: labelColor,
            ),
          ),
          floatingLabelStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: labelColor,
          ),
          hintText: f.hint,
          hintStyle: const TextStyle(fontSize: 12, color: Color(grey5Color)),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _boolField(ReserveCustomerFieldSpec f) {
    final current = switch (_values[f.key]) {
      true => f.trueLabel,
      false => f.falseLabel,
      _ => null,
    };
    return _buildPickerField(
      fieldKey: f.key,
      label: f.label,
      value: current,
      onTap: () => _showOptionSheet(
        title: f.label,
        items: [f.trueLabel!, f.falseLabel!],
        selected: current,
        onPicked: (v) => setState(() => _values[f.key] = v == f.trueLabel),
      ),
    );
  }

  Widget _dateField(ReserveCustomerFieldSpec f) {
    final value = _dateValue(f.key);
    return _buildPickerField(
      fieldKey: f.key,
      label: f.label,
      value: value == null
          ? null
          : DateFormat('dd MMMM yyyy', 'id_ID').format(value),
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime(now.year - 30, now.month, now.day),
          firstDate: DateTime(1900),
          lastDate: now,
        );
        if (picked != null)
          setState(
            () => _values[f.key] = picked.toIso8601String().split('T').first,
          );
      },
    );
  }

  Widget _optionField(ReserveCustomerFieldSpec f) {
    final value = _values[f.key]?.toString();
    return _buildPickerField(
      fieldKey: f.key,
      label: f.label,
      value: (value == null || value.isEmpty) ? null : value,
      onTap: () => _showOptionSheet(
        title: f.label,
        items: f.options ?? const [],
        selected: value,
        onPicked: (v) => setState(() => _values[f.key] = v),
      ),
    );
  }

  /// Field "pilihan" underline (tanggal/opsi/ya-tidak) — gaya `ContactFormPage._buildFieldDown`:
  /// label kecil di atas nilai kalau sudah terisi, atau label besar sebagai placeholder kalau
  /// masih kosong, + panah dropdown di kanan.
  Widget _buildPickerField({
    required String fieldKey,
    required String label,
    required String? value,
    required VoidCallback onTap,
  }) {
    final highlighted = fieldKey == _highlightedKey;
    final labelColor = highlighted
        ? const Color(primaryColor)
        : const Color(grey2Color);
    final isEmpty = value == null || value.isEmpty;
    return _fieldFrame(
      fieldKey,
      InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isEmpty)
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: labelColor,
                      ),
                    ),
                  isEmpty
                      ? Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: labelColor,
                          ),
                        )
                      : Text(
                          value,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: highlighted
                                ? const Color(primaryColor)
                                : const Color(blackColor),
                          ),
                        ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_drop_down,
              size: 28,
              color: Color(grey4Color),
            ),
          ],
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    );
  }

  /// Sheet pilihan teks polos buat field picker — daftar [items], centang di [selected].
  void _showOptionSheet({
    required String title,
    required List<String> items,
    required String? selected,
    required ValueChanged<String> onPicked,
  }) {
    showCustomBottomSheet(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(blackColor),
              ),
            ),
          ),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Text(
                'Tidak ada pilihan tersedia',
                style: TextStyle(fontSize: 13, color: Color(grey5Color)),
              ),
            )
          else
            for (final item in items)
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  onPicked(item);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 4,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(blackColor),
                          ),
                        ),
                      ),
                      if (item == selected)
                        const Icon(
                          Icons.check,
                          size: 18,
                          color: Color(primaryColor),
                        ),
                    ],
                  ),
                ),
              ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _onSubmit() async {
    if (_c('cust_name').text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nama lengkap wajib diisi')));
      return;
    }

    setState(() => _submitting = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    final updated = ReserveOrderCustomerData(raw: _buildRaw());
    setState(() => _submitting = false);
    Navigator.of(context).pop(updated);
  }

  Map<String, dynamic> _buildRaw() {
    final raw = Map<String, dynamic>.of(_values);
    for (final section in reserveCustomerFieldSections) {
      for (final f in section.fields) {
        if (f.kind != ReserveCustomerFieldKind.text) continue;
        final text = _c(f.key).text.trim();
        raw[f.key] = text.isEmpty
            ? null
            : (f.numeric ? num.tryParse(text) : text);
      }
    }
    return raw;
  }
}
