import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:progress_group/core/constants/colors.dart';

/// Field "Tanggal Bukti Transfer" (`reference_date`) untuk pembayaran Non Tunai — dipakai di
/// Create Reserve Order & Top Up Pembayaran. Mengikuti `referenceDateError()` di
/// `Api\ReserveOrderController`: Transfer/Kartu Kredit tidak boleh melebihi hari ini, hanya Giro
/// (tanggal jatuh tempo) yang boleh ke depan ([allowFuture]).
class ReferenceDateField extends StatelessWidget {
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final bool isError;
  final bool allowFuture;

  const ReferenceDateField({
    super.key,
    required this.value,
    required this.onChanged,
    this.isError = false,
    this.allowFuture = false,
  });

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDate = allowFuture ? DateTime(now.year + 1, 12, 31) : today;
    final initial = value ?? today;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(lastDate) ? lastDate : initial,
      firstDate: DateTime(now.year - 1),
      lastDate: lastDate,
      helpText: 'Tanggal Bukti Transfer',
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            children: [
              TextSpan(
                text: 'Tanggal Bukti Transfer',
                style: TextStyle(color: Color(grey1Color)),
              ),
              TextSpan(
                text: ' *',
                style: TextStyle(color: Color(redColor)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () => _pick(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: const Color(grey11Color),
              border: Border(
                bottom: BorderSide(
                  color: isError
                      ? const Color(redColor)
                      : const Color(grey7Color),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    hasValue
                        ? DateFormat('dd/MM/yyyy').format(value!)
                        : 'Pilih tanggal',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: hasValue ? FontWeight.w700 : FontWeight.w400,
                      color: hasValue ? Colors.black : const Color(grey5Color),
                    ),
                  ),
                ),
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: Color(grey4Color),
                ),
              ],
            ),
          ),
        ),
        if (isError)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'Pilih tanggal bukti transfer',
              style: TextStyle(fontSize: 11, color: Color(redColor)),
            ),
          ),
        const SizedBox(height: 10),
      ],
    );
  }
}
