import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/tyre_replacement_controller.dart';

class TyreReplacementDetailBottomSheet extends StatefulWidget {
  final int tyreId;

  const TyreReplacementDetailBottomSheet({super.key, required this.tyreId});

  @override
  State<TyreReplacementDetailBottomSheet> createState() =>
      _TyreReplacementDetailBottomSheetState();
}

class _TyreReplacementDetailBottomSheetState
    extends State<TyreReplacementDetailBottomSheet> {
  static const Color darkBlue = Color(0xFF1A1A2E);
  late TyreReplacementController _controller;

  @override
  void initState() {
    super.initState();
    _controller = context.read<TyreReplacementController>();
    _controller.id = widget.tyreId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.getTyreReplacementDetail();
    });
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: darkBlue,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.tire_repair,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Tyre Replacement Details',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                  padding: const EdgeInsets.all(8),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Consumer<TyreReplacementController>(
              builder: (context, controller, child) {
                return _buildContent(controller);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(TyreReplacementController controller) {
    if (controller.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF1976D2)),
            SizedBox(height: 16),
            Text(
              'Loading details...',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (controller.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error loading details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              controller.errorMessage!,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => controller.getTyreReplacementDetail(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (controller.tyreData == null || controller.tyreData!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No details available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    final data = controller.tyreData!.first;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Basic Information Card
          _buildInfoCard(
            title: 'Basic Information',
            icon: Icons.info_outline,
            children: [
              _buildDetailRow('ID', data['id']?.toString() ?? 'N/A'),
              _buildDetailRow('Brand', data['brand']?.toString() ?? 'N/A'),
              _buildDetailRow(
                'Tyre Code',
                data['code']?['Code']?.toString() ?? 'N/A',
              ),
              _buildDetailRow(
                'Change Date',
                _formatDate(data['tyre_change_date']?.toString()),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Vehicle Information Card
          _buildInfoCard(
            title: 'Vehicle Information',
            icon: Icons.directions_car,
            children: [
              _buildDetailRow(
                'Plate Number',
                data['company_vehicle']?['PlateNo1']?.toString() ?? 'N/A',
              ),
              _buildDetailRow(
                'Vehicle ID',
                data['company_vehicle_id']?.toString() ?? 'N/A',
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Replacement Details Card
          _buildInfoCard(
            title: 'Replacement Details',
            icon: Icons.build,
            children: [
              _buildDetailRow(
                'Current Odometer',
                data['current_odometer']?.toString() ?? 'N/A',
              ),
              _buildDetailRow(
                'Reason for Change',
                data['reason_for_change']?.toString() ?? 'N/A',
              ),
              _buildDetailRow(
                'Changed By',
                data['changed_by']?.toString() ?? 'N/A',
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Supplier Information Card
          if (data['supplier'] != null)
            _buildInfoCard(
              title: 'Supplier Information',
              icon: Icons.business,
              children: [
                _buildDetailRow(
                  'Supplier Name',
                  data['supplier']?['Name']?.toString() ?? 'N/A',
                ),
                _buildDetailRow(
                  'Supplier ID',
                  data['supplier_id']?.toString() ?? 'N/A',
                ),
              ],
            ),

          const SizedBox(height: 16),

          // Odometer Image Card
          if (data['odometer_image'] != null &&
              data['odometer_image'].toString().isNotEmpty)
            _buildInfoCard(
              title: 'Odometer Image',
              icon: Icons.image,
              children: [
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      data['odometer_image'].toString(),
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value:
                                loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Image not available',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),

          const SizedBox(height: 16),

          // Documents Section
          if (data['tyre_replacement_documents'] != null)
            _buildInfoCard(
              title: 'Documents',
              icon: Icons.folder,
              children: [
                if ((data['tyre_replacement_documents'] as List).isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.grey[400]),
                        const SizedBox(width: 8),
                        Text(
                          'No documents available',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                else
                  ...((data['tyre_replacement_documents'] as List)
                      .map(
                        (doc) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.description, color: Colors.blue[600]),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  doc.toString(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.blue[800],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList()),
              ],
            ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: darkBlue, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: darkBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(':', style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Extension to show the bottom sheet
extension TyreReplacementDetailExtension on BuildContext {
  void showTyreReplacementDetail(int tyreId) {
    showModalBottomSheet(
      context: this,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TyreReplacementDetailBottomSheet(tyreId: tyreId),
    );
  }
}
