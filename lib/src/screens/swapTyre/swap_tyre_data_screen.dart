import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/swap_tyre_controller.dart';
import 'package:sample/src/util/app_colors.dart';
import 'package:sample/src/util/app_navigation.dart';
import 'package:sample/src/util/app_routes.dart';
import 'package:sample/src/util/snack.dart';

class SwapTyreDataScreen extends StatefulWidget {
  const SwapTyreDataScreen({super.key});

  @override
  State<SwapTyreDataScreen> createState() => _SwapTyreDataScreenState();
}

class _SwapTyreDataScreenState extends State<SwapTyreDataScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  // From Vehicle Controllers
  final TextEditingController _fromTyreDepthController =
      TextEditingController();
  final TextEditingController _fromTyreConditionController =
      TextEditingController();
  final TextEditingController _fromVehicleOdometerController =
      TextEditingController();

  // To Vehicle Controllers
  final TextEditingController _toVehicleOdometerController =
      TextEditingController();
  final TextEditingController _toTyreDepthController = TextEditingController();
  final TextEditingController _toTyreConditionController =
      TextEditingController();

  // General Controllers
  final TextEditingController _tyreChangeDateController =
      TextEditingController();
  final TextEditingController _reasonForChangeController =
      TextEditingController();
  final TextEditingController _changedByController = TextEditingController();

  // Dropdown selections
  String? selectedFromVehicle;
  String? selectedFromVersion;
  String? selectedFromTyreCode;
  String? selectedToVehicle;
  String? selectedToVersion;
  String? selectedToTyreCode;

  DateTime? _selectedDate;
  final List<XFile> _fromOdometerImages = [];
  final List<XFile> _toOdometerImages = [];

  bool _isSubmitting = false;

  late SwapTyreController _swapTyreController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchBaseData();
    });
  }

  Future<void> _fetchBaseData() async {
    _swapTyreController = context.read<SwapTyreController>();
    _swapTyreController.getSwapTyreBaseData();
  }

  @override
  void dispose() {
    _fromTyreDepthController.dispose();
    _fromTyreConditionController.dispose();
    _fromVehicleOdometerController.dispose();
    _toVehicleOdometerController.dispose();
    _toTyreDepthController.dispose();
    _toTyreConditionController.dispose();
    _tyreChangeDateController.dispose();
    _reasonForChangeController.dispose();
    _changedByController.dispose();
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

  Future<void> _pickFromOdometerImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        setState(() {
          _fromOdometerImages.addAll(images);
        });
      }
    } catch (e) {
      showErrorSnack('Error picking from odometer images: $e');
    }
  }

  Future<void> _pickToOdometerImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        setState(() {
          _toOdometerImages.addAll(images);
        });
      }
    } catch (e) {
      showErrorSnack('Error picking to odometer images: $e');
    }
  }

  void _removeFromImage(int index) {
    setState(() {
      _fromOdometerImages.removeAt(index);
    });
  }

  void _removeToImage(int index) {
    setState(() {
      _toOdometerImages.removeAt(index);
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedFromVehicle == null ||
        selectedFromVersion == null ||
        selectedFromTyreCode == null ||
        selectedToVehicle == null ||
        selectedToVersion == null ||
        selectedToTyreCode == null) {
      showErrorSnack('Please fill all required dropdown fields');
      return;
    }

    if (_selectedDate == null) {
      showErrorSnack('Please select tyre change date');
      return;
    }

    if (_fromOdometerImages.isEmpty) {
      showErrorSnack('Please add at least one from vehicle odometer image');
      return;
    }

    if (_toOdometerImages.isEmpty) {
      showErrorSnack('Please add at least one to vehicle odometer image');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final List<MultipartFile> fromOdometerImages = await Future.wait(
        _fromOdometerImages.map((image) async {
          return await MultipartFile.fromFile(
            image.path,
            filename: image.path.split('/').last,
          );
        }),
      );

      final List<MultipartFile> toOdometerImages = await Future.wait(
        _toOdometerImages.map((image) async {
          return await MultipartFile.fromFile(
            image.path,
            filename: image.path.split('/').last,
          );
        }),
      );

      bool success = await _swapTyreController.postSwapTyre(
        fromCompanyVehicleId: int.parse(selectedFromVehicle!),
        fromVehicleTyreCodeId: int.parse(selectedFromTyreCode!),
        fromTyreDepthMm: _fromTyreDepthController.text.trim(),
        fromTyreCondition: _fromTyreConditionController.text.trim(),
        fromVehicleOdometer: _fromVehicleOdometerController.text.trim(),
        fromVehicleOdometerImage: fromOdometerImages,

        toCompanyVehicleId: int.parse(selectedToVehicle!),
        toVehicleTyreCodeId: int.parse(selectedToTyreCode!),
        toTyreDepthMm: _toTyreDepthController.text.trim(),
        toTyreCondition: _toTyreConditionController.text.trim(),
        toVehicleOdometer: _toVehicleOdometerController.text.trim(),
        toVehicleOdometerImage: toOdometerImages,

        tyreChangeDate:
            "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}",
        reasonForChange: _reasonForChangeController.text.trim(),
        changedBy: _changedByController.text.trim(),
      );

      if (success) {
        showSuccessSnack('Swap tyre data saved successfully!');
        if (mounted) {
          // Navigate to picture upload screen - replace with your actual route
          NavigationService().pushNavigation(
            Screenroutes.swapTyrePictureUploadScreen,
          );
        }
        _resetForm();
      } else {
        showErrorSnack(
          _swapTyreController.errorMessage ?? 'Failed to save swap tyre data',
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
      selectedFromVehicle = null;
      selectedFromVersion = null;
      selectedFromTyreCode = null;
      selectedToVehicle = null;
      selectedToVersion = null;
      selectedToTyreCode = null;
      _selectedDate = null;
      _fromOdometerImages.clear();
      _toOdometerImages.clear();
    });

    _fromTyreDepthController.clear();
    _fromTyreConditionController.clear();
    _fromVehicleOdometerController.clear();
    _toVehicleOdometerController.clear();
    _toTyreDepthController.clear();
    _toTyreConditionController.clear();
    _tyreChangeDateController.clear();
    _reasonForChangeController.clear();
    _changedByController.clear();
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

  Widget _buildImageSection({
    required String title,
    required List<XFile> images,
    required VoidCallback onPickImages,
    required Function(int) onRemoveImage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onPickImages,
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
                Text('Tap to add images', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
        if (images.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(images[index].path),
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => onRemoveImage(index),
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

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Appcolors.darkBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Appcolors.darkBlue,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SwapTyreController>(
      builder: (context, controller, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Swap Tyre Registration'),
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
                  // FROM VEHICLE SECTION
                  _buildSectionHeader('FROM VEHICLE'),
                  const SizedBox(height: 16),

                  // From Vehicle Dropdown
                  _buildSearchableDropdown(
                    label: 'From Vehicle',
                    hint: 'Select Vehicle',
                    value: selectedFromVehicle,
                    items: controller.companyVehicleData ?? [],
                    displayKey: 'PlateNo1',
                    onChanged: (value) {
                      setState(() {
                        selectedFromVehicle = value;
                        selectedFromVersion = null;
                        selectedFromTyreCode = null;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select from vehicle';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // From Version Dropdown
                  _buildSearchableDropdown(
                    label: 'From Version',
                    hint: 'Select Version',
                    value: selectedFromVersion,
                    items: controller.swapTyreVersion ?? [],
                    displayKey: 'Name',
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedFromVersion = value;
                          selectedFromTyreCode = null;
                        });
                        controller.getSwapTyreCodesOfVersion(int.parse(value));
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select from version';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // From Tyre Code Dropdown
                  _buildSearchableDropdown(
                    label: 'From Tyre Code',
                    hint: 'Select Tyre Code',
                    value: selectedFromTyreCode,
                    items: controller.swapTyreCodesOfVersionData ?? [],
                    displayKey: 'display_name',
                    onChanged: (value) {
                      setState(() {
                        selectedFromTyreCode = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select from tyre code';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // From Tyre Depth
                  _buildTextField(
                    label: 'From Tyre Depth (mm) *',
                    controller: _fromTyreDepthController,
                    hint: 'Enter tyre depth in mm',
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter from tyre depth';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // From Tyre Condition
                  _buildTextField(
                    label: 'From Tyre Condition *',
                    controller: _fromTyreConditionController,
                    hint: 'Enter tyre condition',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter from tyre condition';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // From Vehicle Odometer
                  _buildTextField(
                    label: 'From Vehicle Odometer *',
                    controller: _fromVehicleOdometerController,
                    hint: 'Enter vehicle odometer reading',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter from vehicle odometer';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // From Vehicle Odometer Images
                  _buildImageSection(
                    title: 'From Vehicle Odometer Images *',
                    images: _fromOdometerImages,
                    onPickImages: _pickFromOdometerImages,
                    onRemoveImage: _removeFromImage,
                  ),
                  const SizedBox(height: 24),

                  // TO VEHICLE SECTION
                  _buildSectionHeader('TO VEHICLE'),
                  const SizedBox(height: 16),

                  // To Vehicle Dropdown
                  _buildSearchableDropdown(
                    label: 'To Vehicle',
                    hint: 'Select Vehicle',
                    value: selectedToVehicle,
                    items: controller.companyVehicleData ?? [],
                    displayKey: 'PlateNo1',
                    onChanged: (value) {
                      setState(() {
                        selectedToVehicle = value;
                        selectedToVersion = null;
                        selectedToTyreCode = null;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select to vehicle';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // To Version Dropdown
                  _buildSearchableDropdown(
                    label: 'To Version',
                    hint: 'Select Version',
                    value: selectedToVersion,
                    items: controller.swapTyreVersion ?? [],
                    displayKey: 'Name',
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedToVersion = value;
                          selectedToTyreCode = null;
                        });
                        controller.getSwapTyreCodesOfVersion(int.parse(value));
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select to version';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // To Tyre Code Dropdown
                  _buildSearchableDropdown(
                    label: 'To Tyre Code',
                    hint: 'Select Tyre Code',
                    value: selectedToTyreCode,
                    items: controller.swapTyreCodesOfVersionData ?? [],
                    displayKey: 'display_name',
                    onChanged: (value) {
                      setState(() {
                        selectedToTyreCode = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select to tyre code';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // To Tyre Depth
                  _buildTextField(
                    label: 'To Tyre Depth (mm) *',
                    controller: _toTyreDepthController,
                    hint: 'Enter tyre depth in mm',
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter to tyre depth';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // To Tyre Condition
                  _buildTextField(
                    label: 'To Tyre Condition *',
                    controller: _toTyreConditionController,
                    hint: 'Enter tyre condition',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter to tyre condition';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // To Vehicle Odometer
                  _buildTextField(
                    label: 'To Vehicle Odometer *',
                    controller: _toVehicleOdometerController,
                    hint: 'Enter vehicle odometer reading',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter to vehicle odometer';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // To Vehicle Odometer Images
                  _buildImageSection(
                    title: 'To Vehicle Odometer Images *',
                    images: _toOdometerImages,
                    onPickImages: _pickToOdometerImages,
                    onRemoveImage: _removeToImage,
                  ),
                  const SizedBox(height: 24),

                  // GENERAL INFORMATION SECTION
                  _buildSectionHeader('GENERAL INFORMATION'),
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

                  // Reason for Change
                  _buildTextField(
                    label: 'Reason for Change *',
                    controller: _reasonForChangeController,
                    hint: 'Enter reason for tyre swap',
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
                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed:
                          _isSubmitting || controller.isLoading
                              ? null
                              : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Appcolors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child:
                          _isSubmitting || controller.isLoading
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
                                'Submit Swap Tyre',
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
