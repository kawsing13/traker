import 'package:flutter/material.dart';
import 'package:get/get.dart';
//import 'package:intl/intl.dart';
import '../../../controllers/employee_controller.dart';
import '../../../services/forms_service.dart';
import '../../../widgets/common/custom_card.dart';
import '../../../widgets/common/custom_button.dart';
import '../../../widgets/form_widgets/date_time_pickers.dart';
import '../../../config/theme.dart';
//import '../../../config/routes.dart';
import '../../../config/constants.dart';

class DtrFormScreen extends StatefulWidget {
  const DtrFormScreen({super.key});

  @override
  State<DtrFormScreen> createState() => _DtrFormScreenState();
}

class _DtrFormScreenState extends State<DtrFormScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime? selectedDate;
  TimeOfDay? timeIn;
  TimeOfDay? timeOut;
  String? reason;
  String? lateReason;
  String? selectedOption; // 'failed' or 'changed'
  bool _isSaved = false;
  bool _isFinalized = false;
  bool _isVoided = false;
  int? formId;
  bool isLateFiling = false;
  Map<String, dynamic>? formData;
  bool isEditing = false;

  final employeeController = Get.find<EmployeeController>();
  final FormsService _formsService = FormsService.instance;

  @override
  void initState() {
    super.initState();
    formData = Get.arguments as Map<String, dynamic>?;
    if (formData != null) {
      isEditing = true;
      _loadFormData();
    }
  }

  void _loadFormData() {
    if (formData == null) return;
    setState(() {
      formId = formData!['form_id'];
      selectedOption = formData!['sub_type'] == 'log'
          ? 'failed'
          : formData!['sub_type'] == 'shift'
              ? 'changed'
              : null;
      reason = formData!['reason']?.toString();
      lateReason = formData!['late_reason']?.toString();
      if (formData!['start_date'] != null) {
        selectedDate = DateTime.parse(formData!['start_date'].toString());
      }
      if (formData!['start_time'] != null &&
          formData!['start_time'].toString().isNotEmpty) {
        final timeParts = formData!['start_time'].toString().split(':');
        timeIn = TimeOfDay(
          hour: int.parse(timeParts[0]),
          minute: int.parse(timeParts[1]),
        );
      }
      if (formData!['end_time'] != null &&
          formData!['end_time'].toString().isNotEmpty) {
        final timeParts = formData!['end_time'].toString().split(':');
        timeOut = TimeOfDay(
          hour: int.parse(timeParts[0]),
          minute: int.parse(timeParts[1]),
        );
      }
      isLateFiling = formData!['late_filing'] == 'Y';
      _isSaved = true;
      _isFinalized = formData!['status'] == 'Finalized';
      _isVoided = formData!['status'] == 'Void';
    });
  }

  bool get isReadOnly =>
      _isFinalized ||
      _isVoided ||
      formData?['f_status'] == 'Approved' ||
      formData?['f_status'] == 'Rejected';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: const Text('DTR Form', style: AppTheme.titleStyle),
      ),
      body: Container(
        color: Colors.grey.shade50,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: CustomCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date picker
                  DatePickerField(
                    label: 'Date',
                    selectedDate: selectedDate,
                    onDateSelected: (date) {
                      setState(() {
                        selectedDate = date;
                        isLateFiling = date.isBefore(DateTime.now());
                        if (isLateFiling) {
                          Get.snackbar(
                            'Late Filing',
                            'You are filing for a past date. Please provide a reason for late filing.',
                            snackPosition: SnackPosition.TOP,
                            backgroundColor: AppTheme.warningColor,
                            colorText: Colors.white,
                            duration: AppConstants.snackBarDuration,
                          );
                        }
                      });
                    },
                    firstDate:
                        DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                    enabled: !isReadOnly,
                  ),
                  const SizedBox(height: 16),
                  // Option selection
                  _buildTypeSelection(),
                  const SizedBox(height: 16),
                  // Time fields
                  _buildTimeFields(),
                  const SizedBox(height: 16),
                  // Reason
                  _buildReasonField(),
                  if (isLateFiling) ...[
                    const SizedBox(height: 16),
                    _buildLateReasonField(),
                  ],
                  const SizedBox(height: 16),
                  // File upload (optional)
                  _buildFileUpload(),
                  const SizedBox(height: 24),
                  // Always show action buttons but their content will vary based on state
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Type', style: TextStyle(fontWeight: FontWeight.bold)),
        RadioListTile<String>(
          title: const Text('I failed to'),
          value: 'failed',
          groupValue: selectedOption,
          onChanged: isReadOnly
              ? null
              : (value) => setState(() => selectedOption = value),
          activeColor: AppTheme.primaryColor,
        ),
        RadioListTile<String>(
          title: const Text('I changed'),
          value: 'changed',
          groupValue: selectedOption,
          onChanged: isReadOnly
              ? null
              : (value) => setState(() => selectedOption = value),
          activeColor: AppTheme.primaryColor,
        ),
      ],
    );
  }

  Widget _buildTimeFields() {
    return Row(
      children: [
        Expanded(
          child: TimePickerField(
            label: 'Time In',
            selectedTime: timeIn,
            onTimeSelected: (time) {
              setState(() {
                timeIn = time;
              });
            },
            enabled: !isReadOnly,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TimePickerField(
            label: 'Time Out',
            selectedTime: timeOut,
            onTimeSelected: (time) {
              setState(() {
                timeOut = time;
              });
            },
            enabled: !isReadOnly,
          ),
        ),
      ],
    );
  }

  Widget _buildReasonField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Reason', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: reason,
          enabled: !isReadOnly,
          maxLines: 3,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Enter reason',
          ),
          onChanged: (val) => reason = val,
          validator: (val) {
            if (val == null || val.isEmpty) {
              return 'Please enter a reason';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildLateReasonField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Reason for Late Filing',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: lateReason,
          enabled: !isReadOnly,
          maxLines: 2,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Enter reason for late filing',
          ),
          onChanged: (val) => lateReason = val,
          validator: (val) {
            if (isLateFiling && (val == null || val.isEmpty)) {
              return 'Please enter reason for late filing';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildFileUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Upload a file',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'No file chosen',
                ),
                readOnly: true,
              ),
            ),
            const SizedBox(width: 8),
            CustomButton(
              text: 'Browse',
              onPressed: isReadOnly
                  ? null
                  : () {
                      // Implement file upload
                    },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    // For read-only forms, show only void button if applicable
    if (isReadOnly) {
      // Only show void button for forms that aren't already voided
      if (!_isVoided && formData?['status'] != 'Void') {
        return Center(
          child: CustomButton(
            text: 'Void',
            onPressed: _voidForm,
            isOutlined: true,
            color: AppTheme.dangerColor,
          ),
        );
      }
      // Don't show any buttons for voided or already approved/rejected forms
      return const SizedBox.shrink();
    }

    // For editable forms, show appropriate action buttons
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!_isFinalized && !_isVoided) ...[
          CustomButton(
            text: 'Save',
            onPressed: _saveForm,
            isOutlined: true,
            color: AppTheme.infoColor,
          ),
          const SizedBox(width: 16),
        ],
        if (_isSaved && !_isFinalized && !_isVoided) ...[
          CustomButton(
            text: 'Finalize',
            onPressed: _finalizeForm,
            isOutlined: true,
            color: AppTheme.successColor,
          ),
          const SizedBox(width: 16),
        ],
        if (_isSaved && !_isVoided) ...[
          CustomButton(
            text: 'Void',
            onPressed: _voidForm,
            isOutlined: true,
            color: AppTheme.dangerColor,
          ),
        ],
      ],
    );
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) {
      Get.snackbar(
        'Error',
        'Please fill in all required fields',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppTheme.dangerColor,
        colorText: Colors.white,
        duration: AppConstants.snackBarDuration,
      );
      return;
    }

    if (selectedDate == null ||
        selectedOption == null ||
        reason == null ||
        reason!.isEmpty) {
      Get.snackbar(
        'Error',
        'Please fill in all required fields',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppTheme.dangerColor,
        colorText: Colors.white,
        duration: AppConstants.snackBarDuration,
      );
      return;
    }

    // Map option to sub_type
    String subType = selectedOption == 'failed' ? 'log' : 'shift';

    // Validation for "I failed to"
    if (subType == 'log') {
      if (timeIn == null && timeOut == null) {
        Get.snackbar(
          'Error',
          'Please provide at least Time In or Time Out',
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppTheme.dangerColor,
          colorText: Colors.white,
          duration: AppConstants.snackBarDuration,
        );
        return;
      }
    } else {
      // For "I changed", require both
      if (timeIn == null || timeOut == null) {
        Get.snackbar(
          'Error',
          'Please select both Time In and Time Out',
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppTheme.dangerColor,
          colorText: Colors.white,
          duration: AppConstants.snackBarDuration,
        );
        return;
      }
    }

    if (isLateFiling && (lateReason == null || lateReason!.isEmpty)) {
      Get.snackbar(
        'Error',
        'Please enter reason for late filing',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppTheme.dangerColor,
        colorText: Colors.white,
        duration: AppConstants.snackBarDuration,
      );
      return;
    }

    final employeeData = employeeController.getEmployeeData();
    if (employeeData == null) return;

    final newFormId = await _formsService.saveDtrForm(
      formId: formId,
      empId: employeeData['emp_id'],
      subType: subType,
      selectedDate: selectedDate!,
      timeIn: timeIn,
      timeOut: timeOut,
      reason: reason!,
      lateReason: lateReason,
    );

    if (newFormId != null) {
      setState(() {
        _isSaved = true;
        formId = newFormId;
      });

      Get.snackbar(
        'Success',
        'Form ${isEditing ? 'updated' : 'saved'} successfully',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppTheme.successColor,
        colorText: Colors.white,
        duration: AppConstants.snackBarDuration,
      );
    } else {
      Get.snackbar(
        'Error',
        'Failed to ${isEditing ? 'update' : 'save'} form',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppTheme.dangerColor,
        colorText: Colors.white,
        duration: AppConstants.snackBarDuration,
      );
    }
  }

  Future<void> _finalizeForm() async {
    if (!_isSaved) {
      Get.snackbar(
        'Error',
        'Please save the form first',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppTheme.dangerColor,
        colorText: Colors.white,
        duration: AppConstants.snackBarDuration,
      );
      return;
    }

    final result = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Finalize Form'),
        content: const Text(
            'Are you sure you want to finalize this form? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          CustomButton(
            text: 'Finalize',
            onPressed: () => Get.back(result: true),
            color: AppTheme.successColor,
          ),
        ],
      ),
    );

    if (result == true) {
      final success = await _formsService.finalizeDtrForm(formId!);
      if (success) {
        setState(() {
          _isFinalized = true;
        });
        Get.back();
        Get.snackbar(
          'Success',
          'Form finalized successfully',
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppTheme.successColor,
          colorText: Colors.white,
          duration: AppConstants.snackBarDuration,
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to finalize form',
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppTheme.dangerColor,
          colorText: Colors.white,
          duration: AppConstants.snackBarDuration,
        );
      }
    }
  }

  Future<void> _voidForm() async {
    if (formId == null) {
      Get.snackbar(
        'Error',
        'Cannot void unsaved form',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppTheme.dangerColor,
        colorText: Colors.white,
        duration: AppConstants.snackBarDuration,
      );
      return;
    }

    final result = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Void Form'),
        content: const Text(
            'Are you sure you want to void this form? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          CustomButton(
            text: 'Void',
            onPressed: () => Get.back(result: true),
            color: AppTheme.dangerColor,
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final success = await _formsService.voidDtrForm(formId!);
        if (success) {
          setState(() {
            _isVoided = true;
          });
          Get.back();
          Get.snackbar(
            'Success',
            'Form voided successfully',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.grey,
            colorText: Colors.white,
            duration: AppConstants.snackBarDuration,
          );
        } else {
          throw Exception('Failed to void form');
        }
      } catch (e) {
        print('Error voiding form: $e');
        Get.snackbar(
          'Error',
          'Failed to void form',
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppTheme.dangerColor,
          colorText: Colors.white,
          duration: AppConstants.snackBarDuration,
        );
      }
    }
  }
}
