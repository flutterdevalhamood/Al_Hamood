import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/models/sale_base_model.dart';
import 'package:sample/src/providers/post_sale_controller.dart';

const _accentColor = Color(0xFF52B79A);

/// Opens a scrollable, draggable bottom sheet for editing a single line
/// item. Designed for one-handed mobile use: full width fields stacked
/// vertically, large tap targets, sticky "Save line" button.
Future<void> showLineItemEditor(BuildContext context, {required String rowId}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder:
        (_) => ChangeNotifierProvider.value(
          value: context.read<PostSaleController>(),
          child: _LineItemEditorSheet(rowId: rowId),
        ),
  );
}

class _LineItemEditorSheet extends StatelessWidget {
  const _LineItemEditorSheet({required this.rowId});

  final String rowId;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Consumer<PostSaleController>(
          builder: (context, controller, _) {
            final row = controller.rowById(rowId);
            if (row == null) return const SizedBox.shrink();
            final baseData = controller.baseData!;
            final vehicles =
                row.customer?.vehicles ?? const <CustomerVehicleInfo>[];

            return Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Line item',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                        ),
                        onPressed: () {
                          controller.removeRow(rowId);
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    children: [
                      _SectionLabel('Product'),
                      DropdownButtonFormField<ProductItem>(
                        isExpanded: true,
                        value: row.product,
                        decoration: _fieldDecoration(hint: 'Select product'),
                        items:
                            baseData.products
                                .map(
                                  (p) => DropdownMenuItem(
                                    value: p,
                                    child: Text(p.name),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) => controller.setRowProduct(rowId, v),
                      ),
                      if (row.product != null &&
                          row.product!.units.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _SectionLabel('Unit'),
                        DropdownButtonFormField<ProductUnit>(
                          isExpanded: true,
                          value: row.unit,
                          decoration: _fieldDecoration(hint: 'Select unit'),
                          items:
                              row.product!.units
                                  .map(
                                    (u) => DropdownMenuItem(
                                      value: u,
                                      child: Text(u.name),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) => controller.setRowUnit(rowId, v),
                        ),
                      ],
                      const SizedBox(height: 16),
                      _SectionLabel('Date'),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: row.date,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null)
                            controller.setRowDate(rowId, picked);
                        },
                        child: InputDecorator(
                          decoration: _fieldDecoration(
                            suffixIcon: const Icon(
                              Icons.calendar_today,
                              size: 18,
                            ),
                          ),
                          child: Text(_formatDate(row.date)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SectionLabel('Pad #'),
                      TextFormField(
                        initialValue: row.padNumber,
                        decoration: _fieldDecoration(hint: 'Pad number'),
                        onChanged: (v) => controller.setRowPadNumber(rowId, v),
                      ),
                      const SizedBox(height: 16),
                      _SectionLabel('Customer'),
                      DropdownButtonFormField<CustomerItem>(
                        isExpanded: true,
                        value: row.customer,
                        decoration: _fieldDecoration(hint: '--Customer--'),
                        items:
                            baseData.customers
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c.name),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) => controller.setRowCustomer(rowId, v),
                      ),
                      const SizedBox(height: 16),
                      _SectionLabel('Vehicle'),
                      DropdownButtonFormField<CustomerVehicleInfo>(
                        isExpanded: true,
                        value: row.vehicle,
                        decoration: _fieldDecoration(
                          hint:
                              row.customer == null
                                  ? 'Select a customer first'
                                  : 'Select vehicle',
                        ),
                        items:
                            vehicles
                                .map(
                                  (v) => DropdownMenuItem(
                                    value: v,
                                    child: Text(v.registrationNumber),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            row.customer == null
                                ? null
                                : (v) => controller.setRowVehicle(rowId, v),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _NumberField(
                              label: 'Quantity',
                              value: row.quantity,
                              onChanged:
                                  (v) => controller.setRowQuantity(rowId, v),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _NumberField(
                              label: 'Unit Price',
                              value: row.unitPrice,
                              onChanged:
                                  (v) => controller.setRowUnitPrice(rowId, v),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _NumberField(
                              label: 'VAT %',
                              value: row.vat,
                              onChanged: (v) => controller.setRowVat(rowId, v),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _SectionLabel('Amount'),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _accentColor.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    row.rowSubTotal.toStringAsFixed(2),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _accentColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _SectionLabel('Description'),
                      TextFormField(
                        initialValue: row.description,
                        maxLines: 2,
                        decoration: _fieldDecoration(hint: 'Optional note'),
                        onChanged:
                            (v) => controller.setRowDescription(rowId, v),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accentColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed:
                            row.isValid
                                ? () => Navigator.of(context).pop()
                                : null,
                        child: const Text(
                          'Save line',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static InputDecoration _fieldDecoration({String? hint, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF5F6F8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.black54,
      ),
    ),
  );
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(label),
        TextFormField(
          initialValue: value == 0 ? '' : value.toString(),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: _LineItemEditorSheet._fieldDecoration(hint: '0'),
          onChanged: (v) => onChanged(double.tryParse(v) ?? 0),
        ),
      ],
    );
  }
}
