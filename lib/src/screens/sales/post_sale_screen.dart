import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/post_sale_controller.dart';

import 'line_item_editor_sheet.dart';

const _accentColor = Color(0xFF52B79A);

class PostSaleScreen extends StatelessWidget {
  const PostSaleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // employeeId is optional — pass it in here if you want it recorded
      // on the sale (e.g. employeeId: AuthRepo.employeeId), otherwise
      // it's fine to leave it out.
      create: (_) => PostSaleController()..loadBaseData(),
      child: const _PostSaleView(),
    );
  }
}

class _PostSaleView extends StatelessWidget {
  const _PostSaleView();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PostSaleController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('New Sale'),
        actions: [
          if (controller.savedBatches.isNotEmpty)
            IconButton(
              icon: Badge(
                label: Text('${controller.savedBatches.length}'),
                child: const Icon(Icons.history),
              ),
              tooltip: 'Posted this session',
              onPressed: () => _showHistorySheet(context),
            ),
        ],
      ),
      body:
          controller.isLoading
              ? const Center(child: CircularProgressIndicator())
              : controller.baseData == null
              ? _ErrorRetry(
                message: controller.errorMessage ?? 'Failed to load data',
                onRetry:
                    () => context.read<PostSaleController>().loadBaseData(),
              )
              : Column(
                children: [
                  if (controller.errorMessage != null)
                    _ErrorBanner(message: controller.errorMessage!),
                  Expanded(
                    child:
                        controller.rows.isEmpty
                            ? const _EmptyState()
                            : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                12,
                                16,
                                100,
                              ),
                              itemCount: controller.rows.length,
                              separatorBuilder:
                                  (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, i) {
                                final row = controller.rows[i];
                                return _LineItemCard(rowId: row.id);
                              },
                            ),
                  ),
                ],
              ),
      floatingActionButton:
          controller.baseData == null
              ? null
              : FloatingActionButton.extended(
                backgroundColor: _accentColor,
                icon: const Icon(Icons.add),
                label: const Text('Add item'),
                onPressed: () {
                  final id = context.read<PostSaleController>().addRow();
                  showLineItemEditor(context, rowId: id);
                },
              ),
      bottomNavigationBar:
          controller.baseData == null ? null : const _BottomSummaryBar(),
    );
  }

  void _showHistorySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (_) => ChangeNotifierProvider.value(
            value: context.read<PostSaleController>(),
            child: const _HistorySheet(),
          ),
    );
  }
}

// ---------------------------------------------------------------------
// Line item card (replaces the desktop table row)
// ---------------------------------------------------------------------

class _LineItemCard extends StatelessWidget {
  const _LineItemCard({required this.rowId});

  final String rowId;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PostSaleController>();
    final row = controller.rowById(rowId);
    if (row == null) return const SizedBox.shrink();

    return Dismissible(
      key: ValueKey(rowId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => context.read<PostSaleController>().removeRow(rowId),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => showLineItemEditor(context, rowId: rowId),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color:
                    row.isValid
                        ? const Color(0xFFE7E9EC)
                        : Colors.orange.shade200,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _accentColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    row.quantity == 0 ? '–' : row.quantity.toStringAsFixed(0),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _accentColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.product?.name ?? 'Select a product',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color:
                              row.product == null
                                  ? Colors.black38
                                  : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        [
                          if (row.padNumber.isNotEmpty) 'Pad ${row.padNumber}',
                          if (row.customer != null) row.customer!.name,
                          if (row.vehicle != null)
                            row.vehicle!.registrationNumber,
                        ].join(' • '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      row.rowSubTotal.toStringAsFixed(2),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    if (!row.isValid)
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: Colors.orange.shade600,
                      )
                    else
                      const Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: Colors.black38,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'No items yet',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap "Add item" to start this sale.',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Sticky bottom totals / payment / save bar
// ---------------------------------------------------------------------

class _BottomSummaryBar extends StatefulWidget {
  const _BottomSummaryBar();

  @override
  State<_BottomSummaryBar> createState() => _BottomSummaryBarState();
}

class _BottomSummaryBarState extends State<_BottomSummaryBar> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PostSaleController>();

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${controller.rows.length} item(s) • VAT ${controller.totalVat.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                          Text(
                            controller.grandTotal.toStringAsFixed(2),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _expanded ? Icons.expand_more : Icons.expand_less,
                      color: Colors.black45,
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState:
                  _expanded
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
              firstChild: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _MiniAmountField(
                            label: 'Account Closing',
                            value: controller.accountClosing,
                            onChanged:
                                (v) => context
                                    .read<PostSaleController>()
                                    .setAccountClosing(v),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MiniAmountField(
                            label: 'Cash Paid',
                            value: controller.cashPaid,
                            onChanged:
                                (v) => context
                                    .read<PostSaleController>()
                                    .setCashPaid(v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Remaining Balance',
                          style: TextStyle(color: Colors.black54),
                        ),
                        Text(
                          controller.remainingBalance.toStringAsFixed(2),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
              secondChild: const SizedBox.shrink(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          () => context.read<PostSaleController>().resetForm(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed:
                          controller.isSaving
                              ? null
                              : () async {
                                final ok =
                                    await context
                                        .read<PostSaleController>()
                                        .submit();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        ok
                                            ? 'Sale saved successfully'
                                            : controller.errorMessage ??
                                                'Failed to save',
                                      ),
                                    ),
                                  );
                                }
                              },
                      child:
                          controller.isSaving
                              ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : const Text(
                                'Save Sale',
                                style: TextStyle(color: Colors.white),
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniAmountField extends StatelessWidget {
  const _MiniAmountField({
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
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: value == 0 ? '' : value.toString(),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: const Color(0xFFF5F6F8),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (v) => onChanged(double.tryParse(v) ?? 0),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------
// Session history sheet (replaces the desktop "saved batches" table)
// ---------------------------------------------------------------------

class _HistorySheet extends StatelessWidget {
  const _HistorySheet();

  @override
  Widget build(BuildContext context) {
    final batches = context.watch<PostSaleController>().savedBatches;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      builder: (context, scrollController) {
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
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Text(
                    'Posted this session',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: batches.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final b = batches[batches.length - 1 - i];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F6F8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                b.customerName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Pad ${b.padNumber} • ${b.vehicleReg}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          b.amount.toStringAsFixed(2),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------
// Error handling helpers
// ---------------------------------------------------------------------

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade200),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(message, style: TextStyle(color: Colors.red.shade700)),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
