import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/features/reserve-order/domain/entities/customer_options_entity.dart';
import 'package:progress_group/features/reserve-order/domain/entities/reserve_order_questionnaire_entity.dart';
import 'package:progress_group/features/reserve-order/presentation/widgets/option_picker_sheet.dart';

/// Isian kuesioner yang sedang diedit — dipegang halaman pemilik (bukan [ReserveQuestionnaireForm]),
/// supaya isiannya tidak hilang saat grup "Kuesioner" dilipat (`CustomDropdownGroupContact` membuang
/// child-nya saat tertutup). Halaman wajib memanggil [dispose].
class ReserveQuestionnaireController {
  final ReserveQuestionnaireEntity questionnaire;

  /// Nilai pilihan per `name` — check ('1' / ''), radio & pick (value option / 'more' / '').
  final Map<String, String> _values = {};

  /// Isian teks/angka per `name`, + `<name>more` utk angka pilihan "Lebih dari 3".
  final Map<String, TextEditingController> _tc = {};

  /// Centang di depan isian ber-`toggle` — isian aktif selama dicentang.
  final Map<String, bool> _toggles = {};

  ReserveQuestionnaireController(this.questionnaire) {
    for (final q in questionnaire.questions) {
      for (final input in q.inputs) {
        if (input.isText) {
          _tc[input.name] = TextEditingController(text: input.value);
          if (input.toggle != null) _toggles[input.name] = input.value != '';
        } else {
          _values[input.name] = input.value;
          if (input.moreLabel != null) {
            _tc['${input.name}more'] = TextEditingController(
              text: input.moreValue,
            );
          }
        }
      }
    }
  }

  void dispose() {
    for (final c in _tc.values) {
      c.dispose();
    }
  }

  String _valueOf(String name) => _values[name] ?? _tc[name]?.text ?? '';

  /// Body `questioner[<name>]` — aturan sama dgn form web: isian kosong / centang mati / pertanyaan
  /// tersembunyi = null; radio "Lebih dari 3" = 'more' + angka di `<name>more`.
  Map<String, String?> answers() {
    String? orNull(String value) => value.trim().isEmpty ? null : value.trim();
    final answers = <String, String?>{};
    for (final q in questionnaire.questions) {
      final visible = q.isVisible(_valueOf);
      for (final input in q.inputs) {
        if (input.isText) {
          final off = input.toggle != null && !(_toggles[input.name] ?? false);
          answers[input.name] = !visible || off
              ? null
              : orNull(_tc[input.name]!.text);
          continue;
        }
        final value = visible ? orNull(_values[input.name] ?? '') : null;
        answers[input.name] = input.type == 'check' && value != '1'
            ? null
            : value;
        if (input.moreLabel != null) {
          answers['${input.name}more'] = value == 'more'
              ? orNull(_tc['${input.name}more']!.text)
              : null;
        }
      }
    }
    return answers;
  }
}

/// Form "Kuesioner" customer reserve order — pertanyaan, pilihan & aturannya dari server
/// (`questionnaire` di detail = form Edit Customer Reserve web), jadi app tidak menyimpan daftar
/// pertanyaan sendiri. Dipasang di halaman "Edit Data Customer" ([EditCustomerReserveOrderPage])
/// supaya data customer & kuesioner tersimpan dgn 1x Save; isiannya di [controller].
class ReserveQuestionnaireForm extends StatefulWidget {
  final ReserveQuestionnaireController controller;

  const ReserveQuestionnaireForm({super.key, required this.controller});

  @override
  State<ReserveQuestionnaireForm> createState() =>
      _ReserveQuestionnaireFormState();
}

class _ReserveQuestionnaireFormState extends State<ReserveQuestionnaireForm> {
  ReserveQuestionnaireController get _c => widget.controller;
  Map<String, String> get _values => _c._values;
  Map<String, TextEditingController> get _tc => _c._tc;
  Map<String, bool> get _toggles => _c._toggles;
  List<ReserveQuestionEntity> get _questions => _c.questionnaire.questions;

  String _valueOf(String name) => _c._valueOf(name);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final q in _questions)
          if (q.isVisible(_valueOf)) _buildQuestion(q),
      ],
    );
  }

  Widget _buildQuestion(ReserveQuestionEntity q) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(grey10Color))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (q.text != null) ...[
            Text(
              q.text!,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(primaryColor),
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (q.isTable) _buildTable(q) else ..._buildFields(q),
        ],
      ),
    );
  }

  /// Tabel (Rincian penghuni / Properti pilihan lain) — 1 isian per baris jadi "label  [isian]",
  /// >1 isian jadi label di atas + isian berjajar (hint = judul kolom [ReserveQuestionEntity.head]);
  /// >3 isian (Cluster, Product, Wilayah, Kota) ditata 2 kolom supaya tidak terlalu sempit.
  Widget _buildTable(ReserveQuestionEntity q) {
    final rows = <String, List<ReserveQuestionInputEntity>>{};
    for (final input in q.inputs) {
      rows.putIfAbsent(input.row ?? '', () => []).add(input);
    }
    String hintAt(int i) =>
        i + 1 < q.head.length ? q.head[i + 1] : (q.inputs[i].label ?? '');

    return Column(
      children: [
        for (final entry in rows.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: entry.value.length == 1
                ? Row(
                    children: [
                      Expanded(flex: 3, child: _rowLabel(entry.key)),
                      Expanded(
                        flex: 2,
                        child: _cell(entry.value.first, hint: hintAt(0)),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _rowLabel(entry.key),
                      const SizedBox(height: 4),
                      if (entry.value.length > 3)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final width = (constraints.maxWidth - 6) / 2;
                            return Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (var i = 0; i < entry.value.length; i++)
                                  SizedBox(
                                    width: width,
                                    child: _cell(
                                      entry.value[i],
                                      hint: hintAt(i),
                                    ),
                                  ),
                              ],
                            );
                          },
                        )
                      else
                        Row(
                          children: [
                            for (var i = 0; i < entry.value.length; i++) ...[
                              if (i > 0) const SizedBox(width: 6),
                              Expanded(
                                child: _cell(entry.value[i], hint: hintAt(i)),
                              ),
                            ],
                          ],
                        ),
                    ],
                  ),
          ),
      ],
    );
  }

  /// Isian 1 sel tabel — dropdown (`select`, mis. Wilayah) atau teks/angka.
  Widget _cell(ReserveQuestionInputEntity input, {String? hint}) =>
      input.type == 'select'
      ? _selectField(input, hint: hint)
      : _input(input, hint: hint);

  /// Dropdown dari [ReserveQuestionInputEntity.options] (daftar master dari API, mis. 317 Wilayah
  /// Area) — sheet pilihan yang bisa dicari, sama dgn dropdown Wilayah Area di data customer.
  Widget _selectField(ReserveQuestionInputEntity input, {String? hint}) {
    final value = _values[input.name] ?? '';
    final selected = input.options.where((o) => o.value == value).firstOrNull;
    final text = selected?.label ?? (value.isEmpty ? null : value);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => showOptionPickerSheet(
        context: context,
        title: hint ?? input.label ?? '',
        items: [
          if (value.isNotEmpty)
            const CustomerOptionEntity(value: '', label: '— Kosongkan —'),
          for (final o in input.options)
            CustomerOptionEntity(value: o.value, label: o.label),
        ],
        selected: value,
        onPicked: (o) => setState(() => _values[input.name] = o.value),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(grey9Color)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text ?? hint ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text == null
                    ? const TextStyle(fontSize: 12, color: Color(grey5Color))
                    : const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(
              Icons.arrow_drop_down,
              size: 20,
              color: Color(grey4Color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rowLabel(String text) => Text(
    text,
    style: const TextStyle(fontSize: 12, color: Color(grey2Color)),
  );

  /// Isian biasa. Centang berurutan dikumpulkan jadi 1 [Wrap] (sama dgn grid centang di web).
  List<Widget> _buildFields(ReserveQuestionEntity q) {
    final widgets = <Widget>[];
    final checks = <Widget>[];
    void flushChecks() {
      if (checks.isEmpty) return;
      widgets.add(Wrap(spacing: 4, runSpacing: 0, children: [...checks]));
      checks.clear();
    }

    for (final input in q.inputs) {
      if (input.type == 'check') {
        checks.add(_checkItem(input));
        continue;
      }
      flushChecks();
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: switch (input.type) {
            'radio' || 'pick' => _choice(input),
            'select' => _selectField(input, hint: input.label),
            _ when input.toggle != null => _toggleInput(input),
            _ => _input(input, hint: input.placeholder, label: input.label),
          },
        ),
      );
    }
    flushChecks();
    return widgets;
  }

  Widget _checkItem(ReserveQuestionInputEntity input) {
    final checked = _values[input.name] == '1';
    return _tapRow(
      onTap: () => setState(() => _values[input.name] = checked ? '' : '1'),
      control: Checkbox(
        value: checked,
        onChanged: (v) =>
            setState(() => _values[input.name] = v == true ? '1' : ''),
      ),
      label: input.label ?? '',
    );
  }

  /// Pilih satu — radio / pick; radio ber-`more` punya pilihan "Lebih dari 3 (sebutkan)" + angka.
  Widget _choice(ReserveQuestionInputEntity input) {
    final selected = _values[input.name] ?? '';
    void pick(String value) => setState(() => _values[input.name] = value);
    return RadioGroup<String>(
      groupValue: selected,
      onChanged: (v) => pick(v ?? ''),
      child: Wrap(
        spacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final option in input.options)
            _tapRow(
              onTap: () => pick(option.value),
              control: Radio<String>(value: option.value),
              label: option.label,
            ),
          if (input.moreLabel != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: _tapRow(
                    onTap: () => pick('more'),
                    control: const Radio<String>(value: 'more'),
                    label: input.moreLabel!,
                  ),
                ),
                SizedBox(
                  width: 90,
                  child: _textField(
                    _tc['${input.name}more']!,
                    numeric: true,
                    enabled: selected == 'more',
                    hint: 'Jumlah',
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  /// Isian ber-centang (mis. "Lain-lain", "Mobil Pribadi") — isian aktif selama dicentang,
  /// lepas centang = isiannya dikosongkan (sama dgn web).
  Widget _toggleInput(ReserveQuestionInputEntity input) {
    final on = _toggles[input.name] ?? false;
    void toggle(bool value) => setState(() {
      _toggles[input.name] = value;
      if (!value) _tc[input.name]!.clear();
    });
    return Row(
      children: [
        Flexible(
          child: _tapRow(
            onTap: () => toggle(!on),
            control: Checkbox(value: on, onChanged: (v) => toggle(v == true)),
            label: input.toggle!,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _input(input, hint: input.placeholder, enabled: on),
        ),
      ],
    );
  }

  Widget _input(
    ReserveQuestionInputEntity input, {
    String? hint,
    String? label,
    bool enabled = true,
  }) {
    return _textField(
      _tc[input.name]!,
      numeric: input.type == 'int',
      maxLength: input.max,
      enabled: enabled,
      hint: hint,
      label: label,
    );
  }

  Widget _textField(
    TextEditingController controller, {
    bool numeric = false,
    int? maxLength,
    bool enabled = true,
    String? hint,
    String? label,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      inputFormatters: [
        if (numeric) FilteringTextInputFormatter.digitsOnly,
        if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
      ],
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12, color: Color(grey5Color)),
        prefixIcon: label == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(left: 10, right: 6),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(grey2Color),
                  ),
                ),
              ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0),
        filled: !enabled,
        fillColor: const Color(grey11Color),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
        border: _border(),
        enabledBorder: _border(),
        disabledBorder: _border(),
        focusedBorder: _border(const Color(primaryColor)),
      ),
    );
  }

  OutlineInputBorder _border([Color color = const Color(grey9Color)]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: color),
      );

  /// Kontrol (centang/radio) + label yg bisa di-tap bersama. Labelnya [Flexible] — pemanggil
  /// wajib memberi lebar terbatas (di dalam [Wrap] / dibungkus [Flexible] kalau di [Row]).
  Widget _tapRow({
    required VoidCallback onTap,
    required Widget control,
    required String label,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 32, height: 32, child: control),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(label, style: const TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

}
