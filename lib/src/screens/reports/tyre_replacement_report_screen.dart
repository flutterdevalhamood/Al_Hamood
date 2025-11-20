import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/company_vehicle_controller.dart';
import 'package:sample/src/util/app_colors.dart';
import 'package:sample/src/util/pdf_share_helper.dart';
import 'package:sample/src/widgets/pdf_download_widget.dart';

class TyreReplacementReportScreen extends StatefulWidget {
  const TyreReplacementReportScreen({super.key});

  @override
  State<TyreReplacementReportScreen> createState() =>
      _TyreReplacementReportScreenState();
}

class _TyreReplacementReportScreenState
    extends State<TyreReplacementReportScreen> {
  DateTime? _fromDate;
  DateTime? _toDate;
  dynamic? _selectedVehicleId;
  bool _isLoading = false;
  String? _pdfPath;
  bool _isGeneratingReport = false;

  late CompanyVehicleController _companyVehicleController;

  @override
  void initState() {
    super.initState();
    _companyVehicleController = Provider.of<CompanyVehicleController>(
      context,
      listen: false,
    );

    // Set default date range to last 30 days
    _toDate = DateTime.now();
    _fromDate = DateTime.now().subtract(const Duration(days: 30));

    // Load vehicle data
    _loadFormData();
  }

  Future<void> _loadFormData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get company vehicles data
      await _companyVehicleController.getCompanyVehicleData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Always set isLoading to false when done, even if there's an error
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime initialDate =
        isFromDate
            ? (_fromDate ?? DateTime.now())
            : (_toDate ?? DateTime.now());
    final DateTime firstDate = DateTime(2000);
    final DateTime lastDate = DateTime.now().add(const Duration(days: 365));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
    }
  }

  Future<void> _generateReport() async {
    if (_fromDate == null || _toDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select date range'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isGeneratingReport = true;
    });

    try {
      final String fromDateFormatted = DateFormat(
        'yyyy-MM-dd',
      ).format(_fromDate!);
      final String toDateFormatted = DateFormat('yyyy-MM-dd').format(_toDate!);

      final isSuccess = await _companyVehicleController
          .postCompanyVehicleReports(
            fromDateFormatted,
            toDateFormatted,
            _selectedVehicleId.toString(),
          );

      if (isSuccess &&
          _companyVehicleController.tyreReplacementReportUrl != null) {
        final pdfPath = await PdfDownloadHelper.downloadAndOpenPdf(
          url: _companyVehicleController.tyreReplacementReportUrl!,
          reportType: 'tyre_replacement',
          context: context,
        );

        if (pdfPath != null && mounted) {
          setState(() {
            _pdfPath = pdfPath;
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _companyVehicleController.errorMessage ??
                    'Failed to generate report',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingReport = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Tyre Replacement Reports',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        elevation: 0,
        backgroundColor: Appcolors.darkBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_pdfPath != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed:
                  () => PdfShareHelper.sharePdf(
                    context: context,
                    pdfPath: _pdfPath!,
                    subject: 'Tyre Replacement Report',
                    text:
                        'Tyre Replacement Report from ${DateFormat('MMM dd, yyyy').format(_fromDate!)} to ${DateFormat('MMM dd, yyyy').format(_toDate!)}',
                  ),
              tooltip: 'Share Report',
            ),
        ],
      ),
      body: _pdfPath != null ? _buildPdfViewer() : _buildReportForm(),
    );
  }

  Widget _buildReportForm() {
    return Consumer<CompanyVehicleController>(
      builder: (context, controller, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Report Parameters',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Date Range Section
                      const Text(
                        'Date Range',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectDate(context, true),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'From Date',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  suffixIcon: const Icon(Icons.calendar_today),
                                ),
                                child: Text(
                                  _fromDate != null
                                      ? DateFormat(
                                        'MMM dd, yyyy',
                                      ).format(_fromDate!)
                                      : 'Select Date',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectDate(context, false),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'To Date',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  suffixIcon: const Icon(Icons.calendar_today),
                                ),
                                child: Text(
                                  _toDate != null
                                      ? DateFormat(
                                        'MMM dd, yyyy',
                                      ).format(_toDate!)
                                      : 'Select Date',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Filters Section
                      const Text(
                        'Filters',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Vehicle Dropdown
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : DropdownButtonFormField<dynamic>(
                            decoration: InputDecoration(
                              labelText: 'Vehicle (Optional)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            value: _selectedVehicleId,
                            hint: const Text('Select the vehicle'),
                            isExpanded: true,
                            items: [
                              const DropdownMenuItem<dynamic>(
                                value: 'all',
                                child: Text('All Vehicles'),
                              ),
                              ...?controller.companyVehicleOriginalData?.map((
                                vehicle,
                              ) {
                                final plateNo1 =
                                    vehicle['PlateNo1']?.toString() ?? '';
                                final plateNo2 =
                                    vehicle['PlateNo2']?.toString() ?? '';
                                final vehicleDisplay =
                                    plateNo2.isNotEmpty
                                        ? '$plateNo1 - $plateNo2'
                                        : plateNo1;

                                return DropdownMenuItem<int>(
                                  value: vehicle['id'],
                                  child: Text(
                                    vehicleDisplay.isNotEmpty
                                        ? vehicleDisplay
                                        : 'Vehicle #${vehicle['id']}',
                                  ),
                                );
                              }),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedVehicleId = value;
                              });
                            },
                          ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Column(
                children: [
                  // Generate Report Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isGeneratingReport ? null : _generateReport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isGeneratingReport
                                ? Colors.grey
                                : Appcolors.darkBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child:
                          _isGeneratingReport
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text(
                                'Generate Report',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPdfViewer() {
    return Stack(
      children: [
        PDFView(
          filePath: _pdfPath!,
          enableSwipe: true,
          swipeHorizontal: false,
          autoSpacing: true,
          pageFling: true,
          pageSnap: true,
          defaultPage: 0,
          fitPolicy: FitPolicy.BOTH,
          preventLinkNavigation: false,
          onError: (error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error loading PDF: $error'),
                backgroundColor: Colors.red,
              ),
            );
          },
        ),
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            backgroundColor: Appcolors.darkBlue,
            onPressed: () {
              setState(() {
                _pdfPath = null;
              });
            },
            child: const Icon(Icons.close, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
