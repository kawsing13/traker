import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/employee_controller.dart';
import '../../../services/forms_service.dart';
import '../../../widgets/common/custom_card.dart';
import '../../../widgets/common/custom_button.dart';
import '../../../widgets/form_widgets/date_time_pickers.dart';
import '../../../config/theme.dart';
import '../../../config/constants.dart';

class ObluFormScreen extends StatefulWidget {
  const ObluFormScreen({super.key});

  @override
  State<ObluFormScreen> createState() => _ObluFormScreenState();
}

class _ObluFormScreenState extends State<ObluFormScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime? selectedDate;
  TimeOfDay? timeIn;
  TimeOfDay? timeOut;
  String? reason;
  bool willBeInOffice = false;
  String? selectedOption;

  bool _isSaved = false;
  bool _isFinalized = false;
  bool _isVoided = false;
  int? formId;

  final employeeController = Get.find<EmployeeController>();
  final FormsService _formsService = FormsService.instance;

  Map<String, dynamic>? formData;
  bool isEditing = false;

  String? lateReason;
  bool isLateFiling = false;

  @override
  void initState() {
    super.initState();
    formData = Get.arguments as Map<String, dynamic>?;
    print('Received arguments: $formData');
    if (formData != null) {
      isEditing = true;
      _loadFormData();
    }
  }

  void _loadFormData() {
    if (formData == null) return;

    setState(() {
      formId = formData!['form_id'];
      selectedOption = formData!['sub_type']?.toString().toLowerCase();
      reason = formData!['reason']?.toString();

      // Parse start date
      if (formData!['start_date'] != null) {
        selectedDate = DateTime.parse(formData!['start_date'].toString());
      }

      // Parse time values
      if (formData!['start_time'] != null &&
          formData!['start_time'].toString().isNotEmpty) {
        try {
          final timeParts = formData!['start_time'].toString().split(':');
          timeIn = TimeOfDay(
            hour: int.parse(timeParts[0]),
            minute: int.parse(timeParts[1]),
          );
        } catch (e) {
          print('Error parsing start time: $e');
        }
      }

      if (formData!['end_time'] != null &&
          formData!['end_time'].toString().isNotEmpty) {
        try {
          final timeParts = formData!['end_time'].toString().split(':');
          timeOut = TimeOfDay(
            hour: int.parse(timeParts[0]),
            minute: int.parse(timeParts[1]),
          );
        } catch (e) {
          print('Error parsing end time: $e');
        }
      }

      // Check late filing
      if (formData!['created_on'] != null && selectedDate != null) {
        DateTime createdOn = DateTime.parse(formData!['created_on'].toString());
        isLateFiling = selectedDate!.isBefore(createdOn);
      }

      // Load late filing data
      if (formData!['late_filing'] == 'Y') {
        isLateFiling = true;
        lateReason = formData!['late_reason']?.toString();
      }

      _isSaved = true;
      _isFinalized = formData!['status'] == 'Finalized';
      _isVoided = formData!['status'] == 'Void';
    });

    // Show late filing notification after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isLateFiling) {
        Get.snackbar(
          'Late Filing',
          'This form was filed after the applied date',
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppTheme.warningColor,
          colorText: Colors.white,
          duration: AppConstants.snackBarDuration,
        );
      }
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
        title: const Text(
          'Official Business Form',
          style: AppTheme.titleStyle,
        ),
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
                  // Date picker - always show regardless of read-only status
                  DatePickerField(
                    label: 'Date',
                    selectedDate: selectedDate,
                    onDateSelected: (date) {
                      if (isReadOnly) return;
                      setState(() {
                        selectedDate = date;
                        // Check if selected date is before today
                        isLateFiling = date.isBefore(DateTime.now());
                        if (isLateFiling) {
                          // Show snackbar to inform user about late filing
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
                  const SizedBox(height: 24),

                  // Type selection
                  const Text(
                    'Please be informed that I:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  RadioListTile<String>(
                    title: const Text('Was or will be late'),
                    value: 'late',
                    groupValue: selectedOption,
                    onChanged: isReadOnly
                        ? null
                        : (value) {
                            setState(() {
                              selectedOption = value;
                              timeOut =
                                  null; // Clear timeOut when switching options
                            });
                          },
                  ),
                  RadioListTile<String>(
                    title: const Text('Will leave early (Undertime)'),
                    value: 'undertime',
                    groupValue: selectedOption,
                    onChanged: isReadOnly
                        ? null
                        : (value) {
                            setState(() {
                              selectedOption = value;
                              timeIn =
                                  null; // Clear timeIn when switching options
                            });
                          },
                  ),
                  RadioListTile<String>(
                    title: const Text('Will leave for Official Business'),
                    value: 'ob',
                    groupValue: selectedOption,
                    onChanged: isReadOnly
                        ? null
                        : (value) {
                            setState(() {
                              selectedOption = value;
                            });
                          },
                  ),

                  RadioListTile<String>(
                    title: const Text('Will have overtime'),
                    value: 'ot',
                    groupValue: selectedOption,
                    onChanged: isReadOnly
                        ? null
                        : (value) {
                            setState(() {
                              selectedOption = value;
                              timeIn = null;
                            });
                          },
                  ),

                  // Time fields based on selected option
                  if (selectedOption != null) ...[
                    if (selectedOption == 'late')
                      TimePickerField(
                        label: 'Time In',
                        selectedTime: timeIn,
                        onTimeSelected: (time) {
                          if (isReadOnly) return;
                          setState(() {
                            timeIn = time;
                          });
                        },
                        enabled: !isReadOnly,
                      ),
                    if (selectedOption == 'undertime')
                      TimePickerField(
                        label: 'Time Out',
                        selectedTime: timeOut,
                        onTimeSelected: (time) {
                          if (isReadOnly) return;
                          setState(() {
                            timeOut = time;
                          });
                        },
                        enabled: !isReadOnly,
                      ),
                    if (selectedOption == 'ob' || selectedOption == 'ot')
                      Row(
                        children: [
                          Expanded(
                            child: TimePickerField(
                              label: 'Time In',
                              selectedTime: timeIn,
                              onTimeSelected: (time) {
                                if (isReadOnly) return;
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
                                if (isReadOnly) return;
                                setState(() {
                                  timeOut = time;
                                });
                              },
                              enabled: !isReadOnly,
                            ),
                          ),
                        ],
                      ),
                  ],
                  const SizedBox(height: 16),

                  // Reason field
                  _buildReasonField(),

                  // Late filing reason field
                  if (isLateFiling) ...[
                    const SizedBox(height: 16),
                    _buildLateReasonField(),
                  ],

                  // File upload section
                  const SizedBox(height: 16),
                  _buildFileUpload(),

                  // Action buttons
                  const SizedBox(height: 24),
                  if (!isReadOnly) _buildActionButtons(),

                  // Void button for read-only but not voided forms
                  if (isReadOnly &&
                      !_isVoided &&
                      formData?['status'] != 'Void') ...[
                    Center(
                      child: CustomButton(
                        text: 'Void',
                        onPressed: _voidForm,
                        isOutlined: true,
                        color: AppTheme.dangerColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
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
          onChanged: (val) => setState(() => reason = val),
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
          onChanged: (val) => setState(() => lateReason = val),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Show Save button if not finalized and not voided
        if (!_isFinalized && !_isVoided) ...[
          CustomButton(
            text: 'Save',
            onPressed: _saveForm,
            isOutlined: true,
            color: AppTheme.infoColor,
          ),
          const SizedBox(width: 16),
        ],
        // Show Finalize button if saved and not finalized/voided
        if (_isSaved && !_isFinalized && !_isVoided) ...[
          CustomButton(
            text: 'Finalize',
            onPressed: _finalizeForm,
            isOutlined: true,
            color: AppTheme.successColor,
          ),
          const SizedBox(width: 16),
        ],
        // Show Void button if form is saved (regardless of status)
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
        AppConstants.formFieldsRequiredMessage,
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppTheme.dangerColor,
        colorText: Colors.white,
        duration: AppConstants.snackBarDuration,
      );
      return;
    }

    // Validate required fields
    if (selectedDate == null ||
        selectedOption == null ||
        reason == null ||
        reason!.isEmpty) {
      Get.snackbar(
        'Error',
        AppConstants.formFieldsRequiredMessage,
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppTheme.dangerColor,
        colorText: Colors.white,
        duration: AppConstants.snackBarDuration,
      );
      return;
    }

    if ((selectedOption == 'late' && timeIn == null) ||
        (selectedOption == 'undertime' && timeOut == null) ||
        (selectedOption == 'ot' && timeOut == null && timeIn == null) ||
        (selectedOption == 'ob' && (timeIn == null || timeOut == null))) {
      Get.snackbar(
        'Error',
        'Please select required time(s)',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppTheme.dangerColor,
        colorText: Colors.white,
        duration: AppConstants.snackBarDuration,
      );
      return;
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

    final newFormId = await _formsService.saveObluForm(
      formId: formId,
      empId: employeeData['emp_id'],
      subType: selectedOption!.toLowerCase(),
      selectedDate: selectedDate!,
      timeIn: (selectedOption == 'late' ||
              selectedOption == 'ob' ||
              selectedOption == 'ot')
          ? timeIn
          : null,
      timeOut: (selectedOption == 'undertime' ||
              selectedOption == 'ob' ||
              selectedOption == 'ot')
          ? timeOut
          : null,
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
        isEditing
            ? AppConstants.formUpdatedMessage
            : AppConstants.formSavedMessage,
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
        AppConstants.formSaveFirstMessage,
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppTheme.dangerColor,
        colorText: Colors.white,
        duration: AppConstants.snackBarDuration,
      );
      return;
    }

    final result = await Get.dialog<bool>(
      AlertDialog(
        title: const Text(AppConstants.finalizeFormTitle),
        content: const Text(AppConstants.finalizeFormMessage),
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
      final success = await _formsService.finalizeObluForm(formId!);
      if (success) {
        setState(() {
          _isFinalized = true;
        });
        Get.back();
        Get.snackbar(
          'Success',
          AppConstants.formFinalizedMessage,
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppTheme.successColor,
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
        AppConstants.formCannotVoidMessage,
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppTheme.dangerColor,
        colorText: Colors.white,
        duration: AppConstants.snackBarDuration,
      );
      return;
    }

    final result = await Get.dialog<bool>(
      AlertDialog(
        title: const Text(AppConstants.voidFormTitle),
        content: const Text(AppConstants.voidFormMessage),
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
        final success = await _formsService.voidObluForm(formId!);
        if (success) {
          setState(() {
            _isVoided = true;
          });
          Get.back();
          Get.snackbar(
            'Success',
            AppConstants.formVoidedMessage,
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

class FormField extends StatelessWidget {
  final String label;
  final String value;
  final bool isMultiline;

  const FormField({
    super.key,
    required this.label,
    required this.value,
    this.isMultiline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
              color: Colors.grey.shade50,
            ),
            child: isMultiline
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var line in value.split('\n'))
                        Text(
                          line,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                    ],
                  )
                : Text(value),
          ),
        ],
      ),
    );
  }
}
