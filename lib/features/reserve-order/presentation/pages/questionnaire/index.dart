import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/utils/widget/custom_snackbar.dart';
import 'package:progress_group/features/reserve-order/domain/entities/reserve_order_questionnaire_entity.dart';
import 'package:progress_group/features/reserve-order/presentation/state/reserve_order_detail/reserve_order_detail_cubit.dart';

/// Form "Kuesioner" customer reserve order — pertanyaan, pilihan & aturannya dari server
/// (`questionnaire` di detail = form Edit Customer Reserve web), jadi app tidak menyimpan daftar
/// pertanyaan sendiri. Dibuka dari section Kuesioner di tab Customer; header & tombol Save sama
/// dgn "Edit Data Customer" ([EditCustomerReserveOrderPage]).
class ReserveOrderQuestionnairePage extends StatefulWidget {
  final int reserveOrderId;
  final ReserveQuestionnaireEntity questionnaire;

  const ReserveOrderQuestionnairePage({
    super.key,
    required this.reserveOrderId,
    required this.questionnaire,
  });

  @override
  State<ReserveOrderQuestionnairePage> createState() =>
      _ReserveOrderQuestionnairePageState();
}

class _ReserveOrderQuestionnairePageState
    extends State<ReserveOrderQuestionnairePage> {
  /// Nilai pilihan per `name` — check ('1' / ''), radio & pick (value option / 'more' / '').
  final Map<String, String> _values = {};

  /// Isian teks/angka per `name`, + `<name>more` utk angka pilihan "Lebih dari 3".
  final Map<String, TextEditingController> _tc = {};

  /// Centang di depan isian ber-`toggle` — isian aktif selama dicentang.
  final Map<String, bool> _toggles = {};

  bool _submitting = false;

  List<ReserveQuestionEntity> get _questions => widget.questionnaire.questions;

  @override
  void initState() {
    super.initState();
    for (final q in _questions) {
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

  @override
  void dispose() {
    for (final c in _tc.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _valueOf(String name) => _values[name] ?? _tc[name]?.text ?? '';

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
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    for (final q in _questions)
                      if (q.isVisible(_valueOf)) _buildQuestion(q),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
              'Kuesioner',
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
  /// >1 isian jadi label di atas + isian berjajar (hint = judul kolom [ReserveQuestionEntity.head]).
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
                        child: _input(entry.value.first, hint: hintAt(0)),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _rowLabel(entry.key),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          for (var i = 0; i < entry.value.length; i++) ...[
                            if (i > 0) const SizedBox(width: 6),
                            Expanded(
                              child: _input(entry.value[i], hint: hintAt(i)),
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

  /// Body `questioner[<name>]` — aturan sama dgn form web: isian kosong / centang mati / pertanyaan
  /// tersembunyi = null; radio "Lebih dari 3" = 'more' + angka di `<name>more`.
  Map<String, String?> _buildAnswers() {
    String? orNull(String value) => value.trim().isEmpty ? null : value.trim();
    final answers = <String, String?>{};
    for (final q in _questions) {
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

  Future<void> _onSubmit() async {
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);

    final error = await context
        .read<ReserveOrderDetailCubit>()
        .updateQuestionnaire(widget.reserveOrderId, _buildAnswers());

    if (!mounted) return;
    setState(() => _submitting = false);

    if (error != null) {
      showSnackbar(context, error, isError: true);
      return;
    }

    Navigator.of(context).pop(true);
  }
}
