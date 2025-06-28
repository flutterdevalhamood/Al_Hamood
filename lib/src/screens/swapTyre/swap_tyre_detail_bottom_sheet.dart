import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/swap_tyre_controller.dart';
import 'package:sample/src/widgets/image_viewer_dialog.dart';

class SwapTyreDetailBottomSheet extends StatefulWidget {
  final int swapTyreId;

  const SwapTyreDetailBottomSheet({super.key, required this.swapTyreId});

  @override
  State<SwapTyreDetailBottomSheet> createState() =>
      _SwapTyreDetailBottomSheetState();
}

class _SwapTyreDetailBottomSheetState extends State<SwapTyreDetailBottomSheet> {
  static const Color darkBlue = Color(0xFF1A1A2E);
  late SwapTyreController _controller;

  @override
  void initState() {
    super.initState();
    _controller = context.read<SwapTyreController>();
    _controller.setSwapTyreId(widget.swapTyreId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.getSwapTyreDetail();
    });
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
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
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: darkBlue,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Swap Tyre Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Content
          Flexible(
            child: Consumer<SwapTyreController>(
              builder: (context, controller, child) {
                return _buildContent(controller);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(SwapTyreController controller) {
    if (controller.isLoading) {
      return Container(
        height: 300,
        child: const Center(
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
        ),
      );
    }

    if (controller.errorMessage != null) {
      return Container(
        height: 300,
        child: Center(
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
                onPressed: () => controller.getSwapTyreDetail(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (controller.swapTyreData == null || controller.swapTyreData!.isEmpty) {
      return SizedBox(
        height: 300,
        child: Center(
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
        ),
      );
    }

    final data = controller.swapTyreData!.first;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Basic Info Card
          _buildInfoCard(
            title: 'Swap Information',
            icon: Icons.swap_horiz,
            children: [
              _buildDetailRow(
                'Change Date',
                _formatDate(data['tyre_change_date']?.toString()),
              ),
              _buildDetailRow(
                'Changed By',
                data['changed_by']?.toString() ?? 'N/A',
              ),
              _buildDetailRow(
                'Reason for Change',
                data['reason_for_change']?.toString() ?? 'N/A',
              ),
            ],
          ),

          const SizedBox(height: 16),

          // FROM Vehicle Information
          _buildInfoCard(
            title: 'FROM Vehicle',
            icon: Icons.logout,
            color: Colors.orange,
            children: [
              _buildDetailRow(
                'Vehicle Plate',
                data['from_company_vehicle']?['PlateNo1']?.toString() ?? 'N/A',
              ),
              _buildDetailRow(
                'Tyre Code',
                data['from_code']?['Code']?.toString() ?? 'N/A',
              ),
              _buildDetailRow(
                'Tyre Depth (mm)',
                data['from_tyre_depth_mm']?.toString() ?? 'N/A',
              ),
              _buildDetailRow(
                'Tyre Condition (%)',
                data['from_tyre_condition']?.toString() ?? 'N/A',
              ),
              _buildDetailRow(
                'Odometer Reading',
                data['from_vehicle_odometer']?.toString() ?? 'N/A',
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Swap Direction Indicator
          const Center(
            child: Icon(
              Icons.keyboard_arrow_down,
              color: Color(0xFF1976D2),
              size: 32,
            ),
          ),

          const SizedBox(height: 8),

          // TO Vehicle Information
          _buildInfoCard(
            title: 'TO Vehicle',
            icon: Icons.login,
            color: Colors.green,
            children: [
              _buildDetailRow(
                'Vehicle Plate',
                data['to_company_vehicle']?['PlateNo1']?.toString() ?? 'N/A',
              ),
              _buildDetailRow(
                'Tyre Code',
                data['to_code']?['Code']?.toString() ?? 'N/A',
              ),
              _buildDetailRow(
                'Tyre Depth (mm)',
                data['to_tyre_depth_mm']?.toString() ?? 'N/A',
              ),
              _buildDetailRow(
                'Tyre Condition (%)',
                data['to_tyre_condition']?.toString() ?? 'N/A',
              ),
              _buildDetailRow(
                'Odometer Reading',
                data['to_vehicle_odometer']?.toString() ?? 'N/A',
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Documents Section
          _buildDocumentsSection(data),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    Color? color,
  }) {
    final cardColor = color ?? const Color(0xFF1976D2);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: cardColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: cardColor,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
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

  Widget _buildDocumentsSection(Map<String, dynamic> data) {
    final documents = data['swap_tyre_documents'] as List<dynamic>? ?? [];

    return _buildInfoCard(
      title: 'Documents',
      icon: Icons.description,
      color: Colors.purple,
      children: [
        if (documents.isEmpty)
          const Text(
            'No documents attached',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          )
        else
          ...documents.map((doc) => _buildDocumentItem(doc)).toList(),
        const SizedBox(height: 8),

        // Odometer Images Section
        if (data['from_vehicle_odometer_image'] != null ||
            data['to_vehicle_odometer_image'] != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(),
              const Text(
                'Odometer Images:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              if (data['from_vehicle_odometer_image'] != null)
                _buildImageItem(
                  'FROM Vehicle Odometer',
                  data['from_vehicle_odometer_image'],
                ),
              if (data['to_vehicle_odometer_image'] != null)
                _buildImageItem(
                  'TO Vehicle Odometer',
                  data['to_vehicle_odometer_image'],
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildDocumentItem(dynamic document) {
    final imageUrl = document['Title'] as String? ?? '';
    final documentId = document['id']?.toString() ?? '';
    final description = document['Description'] as String? ?? 'Document Image';
    final label =
        description.isNotEmpty ? description : 'Document #$documentId';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.image, size: 16, color: Colors.purple[600]),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          if (imageUrl.isNotEmpty)
            IconButton(
              onPressed: () {
                _showImageViewer(context, imageUrl, label);
              },
              icon: const Icon(Icons.visibility, size: 16),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildImageItem(String label, String? imagePath) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.image, size: 16, color: Colors.blue[600]),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          if (imagePath != null)
            IconButton(
              onPressed: () {
                _showImageViewer(context, imagePath, label);
              },
              icon: const Icon(Icons.visibility, size: 16),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  void _showImageViewer(BuildContext context, String imagePath, String title) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(10),
          child: ImageViewerDialog(imagePath: imagePath, title: title),
        );
      },
    );
  }
}

// Extension to show the bottom sheet
extension SwapTyreDetailExtension on BuildContext {
  void showSwapTyreDetail(int swapTyreId) {
    showModalBottomSheet(
      context: this,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder:
                (context, scrollController) =>
                    SwapTyreDetailBottomSheet(swapTyreId: swapTyreId),
          ),
    );
  }
}
