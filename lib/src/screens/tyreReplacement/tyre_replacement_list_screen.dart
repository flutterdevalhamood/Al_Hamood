import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/models/vehicle_tyre_response_model.dart';
import 'package:sample/src/providers/tyre_replacement_controller.dart';
import 'package:sample/src/screens/tyreReplacement/tyre_replacement_bottom_sheet.dart';
import 'package:sample/src/util/app_navigation.dart';
import 'package:sample/src/util/app_routes.dart';

class TyreReplacementListScreen extends StatefulWidget {
  const TyreReplacementListScreen({super.key});

  @override
  State<TyreReplacementListScreen> createState() =>
      _TyreReplacementListScreenState();
}

class _TyreReplacementListScreenState extends State<TyreReplacementListScreen> {
  static const Color darkBlue = Color(0xFF1A1A2E);
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _deleteReasonController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _filteredData = [];
  String _searchQuery = '';
  late TyreReplacementController _tyreReplacementController;

  @override
  void initState() {
    super.initState();
    _tyreReplacementController = context.read<TyreReplacementController>();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tyreReplacementController.getTyreReplacementData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<TyreReplacementController>().loadMore();
    }
  }

  void _filterData(List<Map<String, dynamic>>? data) {
    if (data == null) {
      _filteredData = [];
      return;
    }

    if (_searchQuery.isEmpty) {
      _filteredData = data;
    } else {
      _filteredData =
          data.where((item) {
            final brand = item['brand']?.toString().toLowerCase() ?? '';
            final plateNo =
                item['company_vehicle']?['PlateNo1']
                    ?.toString()
                    .toLowerCase() ??
                '';
            final code = item['code']?['Code']?.toString().toLowerCase() ?? '';
            final query = _searchQuery.toLowerCase();

            return brand.contains(query) ||
                plateNo.contains(query) ||
                code.contains(query);
          }).toList();
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
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

  void _showDeleteConfirmation(VehicleTyreData tyre) async {
    _deleteReasonController.clear();
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Tyre Data'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Are you sure you want to delete this tyre data?'),
              const SizedBox(height: 16),
              TextField(
                controller: _deleteReasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason for deletion',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed:
                  () => NavigationService().popNavigation(arguments: false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed:
                  () => NavigationService().popNavigation(arguments: true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (result == true) {
      _tyreReplacementController.deleteTyreReplacement(
        tyre.id,
        _deleteReasonController.text,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tyre Data deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _navigateToReportsScreen() {
    NavigationService().pushNavigation(
      Screenroutes.tyreReplacementReportScreen,
    );
  }

  Future<void> _onRefresh() async {
    await _tyreReplacementController.refreshData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Tyre Replacement List',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: darkBlue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.summarize),
            tooltip: 'Reports',
            onPressed: _navigateToReportsScreen,
          ),
        ],
      ),

      body: Consumer<TyreReplacementController>(
        builder: (context, controller, child) {
          // Filter data based on search query
          _filterData(controller.tyreReplacementData);

          return Column(
            children: [
              // Search Bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: darkBlue,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search by plate number...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    suffixIcon:
                        _searchQuery.isNotEmpty
                            ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            )
                            : null,
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ),

              // Results Count
              if (_filteredData.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    '${_filteredData.length} result${_filteredData.length != 1 ? 's' : ''} found',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

              // Content
              Expanded(child: _buildContent(controller)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          NavigationService().pushNavigation(
            Screenroutes.tyreReplacementDataScreen,
          );
        },
        backgroundColor: darkBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildContent(TyreReplacementController controller) {
    if (controller.isLoading &&
        (controller.tyreReplacementData?.isEmpty ?? true)) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF1976D2)),
            SizedBox(height: 16),
            Text(
              'Loading tyre replacements...',
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
              'Error loading data',
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
              onPressed: () => controller.getTyreReplacementData(),
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

    if (_filteredData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty ? Icons.search_off : Icons.tire_repair,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No results found'
                  : 'No tyre replacements yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try adjusting your search terms'
                  : 'Tyre replacement records will appear here',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        controller.currentPage = 1;
        await controller.getTyreReplacementData();
      },
      color: const Color(0xFF1976D2),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _filteredData.length + (controller.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _filteredData.length) {
            return _buildLoadMoreIndicator(controller);
          }
          return _buildTyreReplacementCard(_filteredData[index]);
        },
      ),
    );
  }

  Widget _buildLoadMoreIndicator(TyreReplacementController controller) {
    if (!controller.hasMore) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child:
            controller.isLoading
                ? const CircularProgressIndicator(color: Color(0xFF1976D2))
                : const Text(
                  'Pull down to load more',
                  style: TextStyle(color: Colors.grey),
                ),
      ),
    );
  }

  Widget _buildTyreReplacementCard(Map<String, dynamic> item) {
    final tyreData = VehicleTyreData(
      id: item['id'] as int? ?? 0,
      companyVehicleId: item['company_vehicle_id']?.toString() ?? '',
      vehicleTyreCodeId: item['vehicle_tyre_code_id']?.toString() ?? '',
      brand: item['brand']?.toString() ?? '',
      tyreChangeDate: item['tyre_change_date']?.toString() ?? '',
      companyVehicle: CompanyVehicle(
        id: item['company_vehicle']?['id'] as int? ?? 0,
        plateNo1: item['company_vehicle']?['PlateNo1']?.toString() ?? '',
      ),
      code: TyreCode(
        id: item['code']?['id'] as int? ?? 0,
        code: item['code']?['Code']?.toString() ?? '',
      ),
    );
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          context.showTyreReplacementDetail(tyreData.id);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1976D2).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.tire_repair,
                            color: Color(0xFF1976D2),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['brand']?.toString().toUpperCase() ??
                                    'N/A',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1976D2),
                                ),
                              ),
                              Text(
                                'ID: ${item['id']?.toString() ?? 'N/A'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      _showDeleteConfirmation(tyreData);
                    },
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red[400],
                    tooltip: 'Delete Sale data',
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item['code']?['Code']?.toString() ?? 'N/A',
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Details Section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _buildDetailRow(
                      Icons.directions_car,
                      'Vehicle Plate',
                      item['company_vehicle']?['PlateNo1']?.toString() ?? 'N/A',
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      Icons.calendar_today,
                      'Change Date',
                      _formatDate(item['tyre_change_date']?.toString()),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
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
    );
  }
}
