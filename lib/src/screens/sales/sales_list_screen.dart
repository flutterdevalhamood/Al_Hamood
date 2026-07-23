import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/models/sale_model.dart';
import 'package:sample/src/providers/sales_controller.dart';
import 'package:sample/src/screens/sales/sale_detail_screen.dart';
import 'package:sample/src/util/app_navigation.dart';
import 'package:sample/src/util/app_routes.dart';

class SalesListScreen extends StatefulWidget {
  const SalesListScreen({super.key});

  @override
  State<SalesListScreen> createState() => _SalesListScreenState();
}

class _SalesListScreenState extends State<SalesListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SalesController>().getSalesData();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<SalesController>().loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sale'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New sale',
            onPressed: () {
              NavigationService().pushNavigation(Screenroutes.salesDataScreen);
            },
          ),
        ],
      ),
      body: Consumer<SalesController>(
        builder: (context, controller, _) {
          return Column(
            children: [
              _buildSearchBar(controller),
              if (controller.errorMessage != null)
                _buildErrorBanner(controller),
              Expanded(child: _buildList(controller)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(SalesController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by Pad No',
          prefixIcon: const Icon(Icons.search),
          suffixIcon:
              controller.isFiltered
                  ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      controller.clearSearch();
                    },
                  )
                  : null,
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 0,
            horizontal: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: controller.searchSales,
      ),
    );
  }

  Widget _buildErrorBanner(SalesController controller) {
    return Container(
      width: double.infinity,
      color: Colors.red.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        controller.errorMessage!,
        style: TextStyle(color: Colors.red.shade700),
      ),
    );
  }

  Widget _buildList(SalesController controller) {
    if (controller.isLoading && (controller.salesData?.isEmpty ?? true)) {
      return const Center(child: CircularProgressIndicator());
    }

    final sales = controller.salesData ?? [];

    if (sales.isEmpty) {
      return const Center(child: Text('No sales found'));
    }

    return RefreshIndicator(
      onRefresh: controller.refreshData,
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
        itemCount: sales.length + (controller.hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index >= sales.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _SaleCard(sale: sales[index]);
        },
      ),
    );
  }
}

/// A single row card. Shows the same columns as the web grid:
/// Date, Pad #, Customer, Vehicle, Quantity, Unit Price, VAT, Amount, Paid.
/// Everything else from the API response lives behind "View details".
class _SaleCard extends StatelessWidget {
  final Sale sale;

  const _SaleCard({required this.sale});

  @override
  Widget build(BuildContext context) {
    final detail = sale.primaryDetail;
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.4)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => SaleDetailScreen(sale: sale)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: Pad # + status chip
              Row(
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Pad # ${detail?.padNumber ?? '-'}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  _StatusChip(sale: sale),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                sale.customer?.name ?? 'Unknown customer',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 13, color: theme.hintColor),
                  const SizedBox(width: 4),
                  Text(sale.saleDate, style: theme.textTheme.bodySmall),
                  const SizedBox(width: 14),
                  Icon(Icons.directions_car, size: 13, color: theme.hintColor),
                  const SizedBox(width: 4),
                  Text(
                    detail?.vehicle?.registrationNumber ?? '-',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              const Divider(height: 18),
              Row(
                children: [
                  _MiniStat(label: 'Qty', value: _fmt(detail?.quantity ?? 0)),
                  _MiniStat(
                    label: 'Unit price',
                    value: _fmt(detail?.price ?? 0),
                  ),
                  _MiniStat(label: 'VAT', value: _fmt(sale.totalVat)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Amount',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                      Text(
                        _fmt(sale.grandTotal),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Paid',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                      Text(
                        _fmt(sale.paidBalance),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(num v) => v.toStringAsFixed(2);
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final Sale sale;

  const _StatusChip({required this.sale});

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final Color color;

    if (sale.isPaid) {
      label = 'Paid';
      color = Colors.green;
    } else if (sale.isPartialPaid) {
      label = 'Partial';
      color = Colors.orange;
    } else {
      label = 'Unpaid';
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
