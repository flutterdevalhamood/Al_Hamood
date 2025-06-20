import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/tyre_replacement_controller.dart';
import 'package:sample/src/util/app_colors.dart';
import 'package:sample/src/util/snack.dart';

class TyreReplacementScreen extends StatefulWidget {
  const TyreReplacementScreen({super.key});

  @override
  State<TyreReplacementScreen> createState() => _TyreReplacementScreenState();
}

class _TyreReplacementScreenState extends State<TyreReplacementScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _tyreBrandController = TextEditingController();
  final TextEditingController _currentOdometerController =
      TextEditingController();
  final TextEditingController _reasonForChangeController =
      TextEditingController();
  final TextEditingController _changedByController = TextEditingController();
  final TextEditingController _tyreChangeDateController =
      TextEditingController();

  String? selectedVehicle;
  String? selectedVersion;
  String? selectedTyreCode;
  String? selectedSupplier;

  DateTime? _selectedDate;
  final List<XFile> _odometerImages = [];

  bool _isSubmitting = false;

  late TyreReplacementController _tyreReplacementController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchBaseData();
    });
  }

  Future<void> _fetchBaseData() async {
    _tyreReplacementController = context.read<TyreReplacementController>();
    _tyreReplacementController.getTyreReplacementBaseData();
  }

  @override
  void dispose() {
    _tyreBrandController.dispose();
    _currentOdometerController.dispose();
    _reasonForChangeController.dispose();
    _changedByController.dispose();
    _tyreChangeDateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _tyreChangeDateController.text =
            "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  Future<void> _pickOdometerImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        setState(() {
          _odometerImages.addAll(images);
        });
      }
    } catch (e) {
      showErrorSnack('Error picking images: $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _odometerImages.removeAt(index);
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedVehicle == null ||
        selectedVersion == null ||
        selectedTyreCode == null ||
        selectedSupplier == null) {
      showErrorSnack('Please fill all required dropdown fields');
      return;
    }

    if (_selectedDate == null) {
      showErrorSnack('Please select tyre change date');
      return;
    }

    if (_odometerImages.isEmpty) {
      showErrorSnack('Please add at least one odometer image');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      List<MultipartFile> multipartFiles = [];
      for (XFile image in _odometerImages) {
        String fileName = image.path.split('/').last;
        multipartFiles.add(
          await MultipartFile.fromFile(image.path, filename: fileName),
        );
      }

      bool success = await _tyreReplacementController.postTyreReplacement(
        companyVehicleId: _tyreReplacementController.selectedVehicleId,
        vehicleTyreCodeId: _tyreReplacementController.selectedTyreCodeId,
        supplierID: _tyreReplacementController.selectedSupplierId,
        brand: _tyreBrandController.text.trim(),
        tyreChangeDate:
            "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}",
        currentOdometer: _currentOdometerController.text.trim(),
        reasonForChange: _reasonForChangeController.text.trim(),
        changedBy: _changedByController.text.trim(),
        odoMeterImages: multipartFiles,
      );

      if (success) {
        showSuccessSnack('Tyre replacement data saved successfully!');
        _resetForm();
      } else {
        showErrorSnack(
          _tyreReplacementController.errorMessage ??
              'Failed to save tyre replacement data',
        );
      }
    } catch (e) {
      showErrorSnack('Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _resetForm() {
    _formKey.currentState!.reset();
    setState(() {
      selectedVehicle = null;
      selectedVersion = null;
      selectedTyreCode = null;
      selectedSupplier = null;
      _selectedDate = null;
      _odometerImages.clear();
    });

    _tyreBrandController.clear();
    _currentOdometerController.clear();
    _reasonForChangeController.clear();
    _changedByController.clear();
    _tyreChangeDateController.clear();
  }

  Widget _buildLabeledField(
    String label, {
    required Widget child,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (required)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Theme.of(context).primaryColor),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            suffixIcon: suffixIcon,
          ),
          validator: validator,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
        ),
      ],
    );
  }

  // Searchable Dropdown Widget
  Widget _buildSearchableDropdown({
    required String label,
    required String hint,
    String? value,
    required List<Map<String, dynamic>> items,
    required Function(String?) onChanged,
    required String? Function(String?) validator,
    required String displayKey,
    bool required = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (required)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap:
              () => _showSearchableDialog(
                context: context,
                title: 'Select $label',
                items: items,
                displayKey: displayKey,
                onSelected: onChanged,
                currentValue: value,
              ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value != null
                        ? items.firstWhere(
                              (item) => item['id'].toString() == value,
                              orElse: () => {displayKey: hint},
                            )[displayKey] ??
                            hint
                        : hint,
                    style: TextStyle(
                      color: value != null ? Colors.black87 : Colors.grey,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
              ],
            ),
          ),
        ),
        // Hidden FormField for validation
        FormField<String>(
          initialValue: value,
          validator: validator,
          builder: (field) {
            return field.hasError
                ? Padding(
                  padding: const EdgeInsets.only(top: 8, left: 12),
                  child: Text(
                    field.errorText!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                )
                : const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  void _showSearchableDialog({
    required BuildContext context,
    required String title,
    required List<Map<String, dynamic>> items,
    required String displayKey,
    required Function(String?) onSelected,
    String? currentValue,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SearchableDropdownDialog(
          title: title,
          items: items,
          displayKey: displayKey,
          onSelected: onSelected,
          currentValue: currentValue,
        );
      },
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Current Odometer Images *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickOdometerImages,
          child: Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey.shade300,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey),
                SizedBox(height: 8),
                Text(
                  'Tap to add odometer images',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
        if (_odometerImages.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _odometerImages.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(_odometerImages[index].path),
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TyreReplacementController>(
      builder: (context, controller, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Tyre Replacement'),
            backgroundColor: Appcolors.darkBlue,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vehicle Dropdown
                  _buildSearchableDropdown(
                    label: 'Vehicle',
                    hint: 'Select Vehicle',
                    value: selectedVehicle,
                    items: controller.companyVehicleData ?? [],
                    displayKey: 'PlateNo1',
                    onChanged: (value) {
                      if (value != null) {
                        controller.setVehicleType(int.parse(value));
                        setState(() {
                          selectedVehicle = value;
                        });
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a vehicle';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Version Dropdown
                  _buildSearchableDropdown(
                    label: 'Version',
                    hint: 'Select Version',
                    value: selectedVersion,
                    items: controller.tyreVersion ?? [],
                    displayKey: 'Name',
                    onChanged: (value) {
                      if (value != null) {
                        controller.setVersionType(int.parse(value));
                        setState(() {
                          selectedVersion = value;
                          // Reset tyre code selection when version changes
                          selectedTyreCode = null;
                        });
                        // Call API to get tyre codes for selected version
                        controller.getTyreCodesOfVersion(int.parse(value));
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a version';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Tyre Code Dropdown
                  _buildSearchableDropdown(
                    label: 'Tyre Code',
                    hint: 'Select Tyre Code',
                    value: selectedTyreCode,
                    items: controller.tyreCodesOfVersionData ?? [],
                    displayKey:
                        'display_name', // Changed from 'Name' to 'display_name'
                    onChanged: (value) {
                      if (value != null) {
                        controller.setVTyreCode(int.parse(value));
                        setState(() {
                          selectedTyreCode = value;
                        });
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a tyre code';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Supplier Dropdown
                  _buildSearchableDropdown(
                    label: 'Supplier',
                    hint: 'Select Supplier',
                    value: selectedSupplier,
                    items: controller.supplierData ?? [],
                    displayKey: 'Name',
                    onChanged: (value) {
                      if (value != null) {
                        controller.setSupplier(int.parse(value));
                        setState(() {
                          selectedSupplier = value;
                        });
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a supplier';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Tyre Change Date
                  _buildTextField(
                    label: 'Tyre Change Date *',
                    controller: _tyreChangeDateController,
                    hint: 'Select Date',
                    readOnly: true,
                    onTap: _selectDate,
                    suffixIcon: const Icon(Icons.calendar_today),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select tyre change date';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Tyre Brand
                  _buildTextField(
                    label: 'Tyre Brand *',
                    controller: _tyreBrandController,
                    hint: 'Enter tyre brand',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter tyre brand';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Current Odometer
                  _buildTextField(
                    label: 'Current Odometer *',
                    controller: _currentOdometerController,
                    hint: 'Enter current odometer reading',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter current odometer reading';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Reason for Change
                  _buildTextField(
                    label: 'Reason for Change *',
                    controller: _reasonForChangeController,
                    hint: 'Enter reason for tyre change',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter reason for change';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Changed By
                  _buildTextField(
                    label: 'Changed By *',
                    controller: _changedByController,
                    hint: 'Enter name of person who changed',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter who changed the tyre';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Image Section
                  _buildImageSection(),
                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Appcolors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child:
                          _isSubmitting
                              ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Submitting...',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              )
                              : const Text(
                                'Submit',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Searchable Dropdown Dialog Widget
class SearchableDropdownDialog extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> items;
  final String displayKey;
  final Function(String?) onSelected;
  final String? currentValue;

  const SearchableDropdownDialog({
    super.key,
    required this.title,
    required this.items,
    required this.displayKey,
    required this.onSelected,
    this.currentValue,
  });

  @override
  State<SearchableDropdownDialog> createState() =>
      _SearchableDropdownDialogState();
}

class _SearchableDropdownDialogState extends State<SearchableDropdownDialog> {
  late List<Map<String, dynamic>> filteredItems;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredItems = widget.items;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterItems(String searchTerm) {
    setState(() {
      if (searchTerm.isEmpty) {
        filteredItems = widget.items;
      } else {
        filteredItems =
            widget.items
                .where(
                  (item) => (item[widget.displayKey] ?? '')
                      .toString()
                      .toLowerCase()
                      .contains(searchTerm.toLowerCase()),
                )
                .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            // Search Field
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                onChanged: _filterItems,
              ),
            ),
            // Items List
            Flexible(
              child:
                  filteredItems.isEmpty
                      ? const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'No items found',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      )
                      : ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          final isSelected =
                              widget.currentValue == item['id'].toString();

                          return ListTile(
                            title: Text(
                              item[widget.displayKey]?.toString() ?? 'Unknown',
                              style: TextStyle(
                                fontWeight:
                                    isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                color:
                                    isSelected
                                        ? Theme.of(context).primaryColor
                                        : null,
                              ),
                            ),
                            trailing:
                                isSelected
                                    ? Icon(
                                      Icons.check,
                                      color: Theme.of(context).primaryColor,
                                    )
                                    : null,
                            onTap: () {
                              widget.onSelected(item['id'].toString());
                              Navigator.of(context).pop();
                            },
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
