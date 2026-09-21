import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/utils/widget/custom_button.dart';
import 'package:progress_group/core/utils/widget/custom_buttomsheet.dart';
import 'package:progress_group/core/utils/widget/custom_snackbar.dart';
import 'package:progress_group/features/reserve-order/domain/entities/cara_bayar_entity.dart';
import 'package:progress_group/features/reserve-order/domain/entities/edit_reserve_order_params.dart';
import 'package:progress_group/features/reserve-order/presentation/state/cara_bayar/cara_bayar_bloc.dart';
import 'package:progress_group/features/reserve-order/presentation/state/cara_bayar/cara_bayar_event.dart';
import 'package:progress_group/features/reserve-order/presentation/state/cara_bayar/cara_bayar_state.dart';
import 'package:progress_group/features/reserve-order/presentation/state/reserve_order_detail/reserve_order_detail_cubit.dart';

/// Halaman "Edit Reserve Order" (menu ⋮ di Detail) — `POST /reserve-order/edit/{id}`.
///
/// Catatan: field yang bisa diedit lewat endpoint-nya sebenarnya juga mencakup unit/property
/// (property_id/product_id/company_id), tapi memilih ulang unit butuh alur "Pilih Unit" penuh
/// (township_id + GetSelectUnitUseCase) seperti di wizard Create yang belum tersedia dari
/// konteks Detail — jadi form ini baru mengekspos Cara Bayar & Catatan.
class EditReserveOrderPage extends StatefulWidget {
  final int reserveOrderId;
  final String? initialNote;
  final int? initialCaraBayarId;
  final String? initialCaraBayarName;

  const EditReserveOrderPage({
    super.key,
    required this.reserveOrderId,
    this.initialNote,
    this.initialCaraBayarId,
    this.initialCaraBayarName,
  });

  @override
  State<EditReserveOrderPage> createState() => _EditReserveOrderPageState();
}

class _EditReserveOrderPageState extends State<EditReserveOrderPage> {
  late final TextEditingController _noteController;
  int? _caraBayarId;
  String? _caraBayarName;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.initialNote ?? '');
    _caraBayarId = widget.initialCaraBayarId;
    _caraBayarName = widget.initialCaraBayarName;
    context.read<CaraBayarBloc>().add(const FetchCaraBayarEvent());
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_submitting,
      child: Scaffold(
        backgroundColor: const Color(whiteColor),
        appBar: AppBar(
          backgroundColor: const Color(whiteColor),
          elevation: 0.6,
          title: const Text(
            'Edit Reserve Order',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fieldLabel('Cara Bayar'),
                      const SizedBox(height: 8),
                      BlocBuilder<CaraBayarBloc, CaraBayarState>(
                        builder: (context, state) => _picker(
                          value: _caraBayarName,
                          onTap: () => _pickCaraBayar(state.items),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _fieldLabel('Catatan'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _noteController,
                        maxLines: 4,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(blue2Color),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Catatan reserve order…',
                          hintStyle: const TextStyle(
                            fontSize: 12,
                            color: Color(grey4Color),
                          ),
                          filled: true,
                          fillColor: const Color(grey11Color),
                          contentPadding: const EdgeInsets.all(12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: const BoxDecoration(
                  color: Color(whiteColor),
                  border: Border(top: BorderSide(color: Color(grey10Color))),
                ),
                child: customButton(
                  _submitting ? null : _submit,
                  _submitting ? 'Menyimpan…' : 'Simpan Perubahan',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        color: Color(grey1Color),
      ),
    );
  }

  Widget _picker({required String? value, required VoidCallback onTap}) {
    final isEmpty = value == null || value.isEmpty;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(grey11Color),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                isEmpty ? 'Pilih cara bayar' : value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isEmpty
                      ? const Color(grey4Color)
                      : const Color(blue2Color),
                ),
              ),
            ),
            const Icon(
              Icons.arrow_drop_down,
              size: 22,
              color: Color(grey4Color),
            ),
          ],
        ),
      ),
    );
  }

  void _pickCaraBayar(List<CaraBayarEntity> items) {
    showCustomBottomSheet(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Cara Bayar',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
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
                  setState(() {
                    _caraBayarId = item.caraBayarId;
                    _caraBayarName = item.name;
                  });
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
                          item.name,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      if (item.caraBayarId == _caraBayarId)
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

  Future<void> _submit() async {
    setState(() => _submitting = true);

    final error = await context.read<ReserveOrderDetailCubit>().editOrder(
      widget.reserveOrderId,
      EditReserveOrderParams(
        reserveNote: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        caraBayarId: _caraBayarId,
      ),
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (error != null) {
      showSnackbar(context, error, isError: true);
      return;
    }

    Navigator.of(context).pop(true);
  }
}
