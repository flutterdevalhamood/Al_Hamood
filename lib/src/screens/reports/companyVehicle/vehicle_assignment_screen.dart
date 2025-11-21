import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/company_vehicle_controller.dart';
import 'package:sample/src/util/app_colors.dart';

class VehicleAssignmentScreen extends StatefulWidget {
  final int vehicleId;
  final String vehicleName;
  final String plateNumber;

  const VehicleAssignmentScreen({
    Key? key,
    required this.vehicleId,
    required this.vehicleName,
    required this.plateNumber,
  }) : super(key: key);

  @override
  State<VehicleAssignmentScreen> createState() =>
      _VehicleAssignmentScreenState();
}

class _VehicleAssignmentScreenState extends State<VehicleAssignmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _dateTimeController = TextEditingController();

  int? _selectedCompanyId;
  DateTime _selectedDateTime = DateTime.now();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _dateTimeController.text = DateFormat(
      'yyyy-MM-dd HH:mm',
    ).format(_selectedDateTime);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<CompanyVehicleController>(
        context,
        listen: false,
      );
      // Fetch both base data and vehicle details
      provider.getCompanyVehicleAssignmentBaseData();
      provider.getVehicleDetails(widget.vehicleId);
    });
  }

  @override
  void dispose() {
    _remarksController.dispose();
    _dateTimeController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );

      if (time != null && mounted) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
          _dateTimeController.text = DateFormat(
            'yyyy-MM-dd HH:mm',
          ).format(_selectedDateTime);
        });
      }
    }
  }

  Future<void> _submitAssignment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCompanyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a company'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final provider = Provider.of<CompanyVehicleController>(
      context,
      listen: false,
    );

    final success = await provider.postAssignCompanyVehicle(
      companyVehicleId: widget.vehicleId,
      assignedAt: DateFormat('yyyy-MM-dd HH:mm:ss').format(_selectedDateTime),
      remarks: _remarksController.text.trim(),
      companyId: _selectedCompanyId,
    );

    setState(() {
      _isSubmitting = false;
    });

    if (mounted) {
      if (success) {
        // Refresh the vehicle details so UI updates
        await provider.getVehicleDetails(widget.vehicleId);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vehicle assigned successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Stay on same page, just rebuild UI
        setState(() {});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Failed to assign vehicle'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildCurrentAssignmentCard(Map<String, dynamic>? activeAssignment) {
    if (activeAssignment == null) {
      return const SizedBox.shrink();
    }

    final company = activeAssignment['company'] as Map<String, dynamic>?;
    final companyName = company?['Name'] ?? 'Unknown Company';
    final assignedAt = activeAssignment['assigned_at']?.toString() ?? '';
    final remarks = activeAssignment['remarks']?.toString() ?? 'No remarks';
    final releasedAt = activeAssignment['released_at'];

    // Parse and format the assigned date
    String formattedDate = '';
    if (assignedAt.isNotEmpty) {
      try {
        final dateTime = DateTime.parse(assignedAt);
        formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
      } catch (e) {
        formattedDate = assignedAt;
      }
    }

    final status = releasedAt == null ? 'Active' : 'Released';
    final statusColor = releasedAt == null ? Colors.green : Colors.orange;

    return Column(
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: statusColor.withOpacity(0.3), width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Current Assignment',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor, width: 1),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildAssignmentRow(Icons.business, 'Company', companyName),
                const SizedBox(height: 12),
                _buildAssignmentRow(
                  Icons.calendar_today,
                  'Assigned At',
                  formattedDate,
                ),
                if (remarks.isNotEmpty && remarks != 'No remarks') ...[
                  const SizedBox(height: 12),
                  _buildAssignmentRow(Icons.notes, 'Remarks', remarks),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildAssignmentRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Appcolors.darkBlue, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Vehicle'),
        backgroundColor: Appcolors.darkBlue,
      ),
      body: Consumer<CompanyVehicleController>(
        builder: (context, provider, child) {
          // Show loading indicator while fetching initial data
          if (provider.isLoading &&
              (provider.companies == null ||
                  provider.currentVehicleDetails == null)) {
            return const Center(child: CircularProgressIndicator());
          }

          // Get the current vehicle details including active assignment
          final vehicleDetails = provider.currentVehicleDetails;
          final activeAssignment = vehicleDetails?['active_assignment_company'];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vehicle Info Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Vehicle Details',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(
                                Icons.directions_car,
                                color: Appcolors.darkBlue,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.vehicleName,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.confirmation_number,
                                color: Appcolors.darkBlue,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                widget.plateNumber,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Current Assignment Card (if exists)
                  _buildCurrentAssignmentCard(activeAssignment),

                  // Company Selection
                  const Text(
                    'Select Company *',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: _selectedCompanyId,
                    decoration: InputDecoration(
                      hintText: 'Choose a company',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    items:
                        provider.companies?.map((company) {
                          return DropdownMenuItem<int>(
                            value: company['id'],
                            child: Text(company['Name'] ?? 'Unknown'),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCompanyId = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a company';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Date and Time Selection
                  const Text(
                    'Assign Date & Time *',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _dateTimeController,
                    readOnly: true,
                    decoration: InputDecoration(
                      hintText: 'Select date and time',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: _selectDateTime,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    onTap: _selectDateTime,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select date and time';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Remarks Field
                  const Text(
                    'Remarks',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _remarksController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Enter any additional remarks (optional)',
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 60),
                        child: Icon(Icons.notes),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Assign Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitAssignment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Appcolors.darkBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                      child:
                          _isSubmitting
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : const Text(
                                'Assign Vehicle',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
