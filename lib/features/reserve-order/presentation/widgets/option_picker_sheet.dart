import 'package:flutter/material.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/utils/widget/custom_buttomsheet.dart';
import 'package:progress_group/features/reserve-order/domain/entities/customer_options_entity.dart';

/// Sheet pilihan buat field picker — daftar [items] (label tampil, value disimpan), centang di
/// [selected] (value). Daftar panjang (mis. 317 Wilayah Area) bisa di-scroll & dicari. Dipakai halaman
/// Edit Data Customer (dropdown data customer) & form kuesioner (Wilayah).
void showOptionPickerSheet({
  required BuildContext context,
  required String title,
  required List<CustomerOptionEntity> items,
  required String? selected,
  required ValueChanged<CustomerOptionEntity> onPicked,
}) {
  var query = '';
  showCustomBottomSheet(
    context: context,
    child: StatefulBuilder(
      builder: (sheetContext, setSheetState) {
        final q = query.trim().toLowerCase();
        final shown = q.isEmpty
            ? items
            : items.where((o) => o.label.toLowerCase().contains(q)).toList();
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
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
              if (items.length > 10)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextField(
                    onChanged: (v) => setSheetState(() => query = v),
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Cari…',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: Color(grey5Color),
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        size: 18,
                        color: Color(grey4Color),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(grey8Color)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(grey8Color)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(primaryColor),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              if (shown.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  child: Text(
                    'Tidak ada pilihan tersedia',
                    style: TextStyle(fontSize: 13, color: Color(grey5Color)),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(sheetContext).size.height * 0.5,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: shown.length,
                    itemBuilder: (_, i) {
                      final item = shown[i];
                      return InkWell(
                        onTap: () {
                          Navigator.pop(sheetContext);
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
                                  item.label,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(blackColor),
                                  ),
                                ),
                              ),
                              if (item.value == selected)
                                const Icon(
                                  Icons.check,
                                  size: 18,
                                  color: Color(primaryColor),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    ),
  );
}
