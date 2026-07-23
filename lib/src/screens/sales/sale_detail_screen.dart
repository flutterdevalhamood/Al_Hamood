import 'package:flutter/material.dart';
import 'package:sample/src/models/sale_model.dart';

class SaleDetailScreen extends StatelessWidget {
  final Sale sale;

  const SaleDetailScreen({super.key, required this.sale});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Sale ${sale.saleNumber.isNotEmpty ? sale.saleNumber : '#${sale.id}'}',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Print',
            onPressed: () {
              // Hook up to existing print/report action
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSummaryCard(context),
          const SizedBox(height: 16),
          _SectionHeader('Customer'),
          _buildCustomerCard(context),
          const SizedBox(height: 16),
          _SectionHeader('Sale items (${sale.saleDetails.length})'),
          ...sale.saleDetails.map((d) => _buildSaleDetailCard(context, d)),
          const SizedBox(height: 16),
          _SectionHeader('Recorded by'),
          _buildRecordedByCard(context),
          if (sale.description != null &&
              sale.description!.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionHeader('Notes'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(sale.description!),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primaryContainer.withOpacity(0.35),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Sale Date', style: theme.textTheme.labelMedium),
                Text(
                  sale.saleDate,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Divider(),
            _kv(context, 'Sub total', _money(sale.subTotal)),
            _kv(context, 'Total', _money(sale.total)),
            _kv(context, 'Total VAT', _money(sale.totalVat)),
            _kv(context, 'Grand total', _money(sale.grandTotal), bold: true),
            _kv(context, 'Paid balance', _money(sale.paidBalance)),
            _kv(context, 'Remaining balance', _money(sale.remainingBalance)),
            const SizedBox(height: 6),
            _kv(
              context,
              'Payment status',
              sale.isPaid
                  ? 'Fully paid'
                  : sale.isPartialPaid
                  ? 'Partially paid'
                  : 'Unpaid',
            ),
            _kv(context, 'Last updated', sale.updatedAt),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerCard(BuildContext context) {
    final c = sale.customer;
    if (c == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Text('No customer data'),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              c.name,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (c.representative.isNotEmpty)
              Text(
                'Rep: ${c.representative}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 8),
            _kv(context, 'TRN number', c.trnNumber),
            _kv(context, 'Address', c.address),
            if (c.mobile != null) _kv(context, 'Mobile', c.mobile!),
            if (c.phone != null) _kv(context, 'Phone', c.phone!),
            if (c.email != null) _kv(context, 'Email', c.email!),
            _kv(context, 'Login email', c.loginEmail),
            _kv(context, 'Opening balance', _money(c.openingBalance)),
            _kv(context, 'Registration date', c.registrationDate),
            if (c.trnCertificateExpiryDate != null)
              _kv(context, 'TRN cert. expiry', c.trnCertificateExpiryDate!),
            _kv(context, 'Active', c.isActive ? 'Yes' : 'No'),
          ],
        ),
      ),
    );
  }

  Widget _buildSaleDetailCard(BuildContext context, SaleDetail d) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_gas_station,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    d.product?.name ?? 'Product',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text('Pad # ${d.padNumber}', style: theme.textTheme.bodySmall),
              ],
            ),
            if (d.description != null && d.description!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(d.description!, style: theme.textTheme.bodySmall),
              ),
            const SizedBox(height: 8),
            _kv(context, 'Vehicle', d.vehicle?.registrationNumber ?? '-'),
            _kv(context, 'Quantity', d.quantity.toStringAsFixed(2)),
            _kv(context, 'Unit price', _money(d.price)),
            _kv(context, 'Row total', _money(d.rowTotal)),
            _kv(context, 'VAT', _money(d.vat)),
            _kv(context, 'Row VAT amount', _money(d.rowVatAmount)),
            _kv(context, 'Row sub total', _money(d.rowSubTotal)),
            if (d.product != null && d.product!.units.isNotEmpty)
              _kv(
                context,
                'Available units',
                d.product!.units.map((u) => u.name).join(', '),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordedByCard(BuildContext context) {
    final u = sale.apiUser;
    if (u == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Text('No user data'),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _kv(context, 'Name', u.name),
            _kv(context, 'Email', u.email),
            if (u.contactNumber != null)
              _kv(context, 'Contact', u.contactNumber!),
            _kv(context, 'Address', u.address),
          ],
        ),
      ),
    );
  }

  Widget _kv(
    BuildContext context,
    String label,
    String value, {
    bool bold = false,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _money(num v) => v.toStringAsFixed(2);
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}
