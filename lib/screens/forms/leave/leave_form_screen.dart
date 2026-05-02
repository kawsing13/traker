import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../services/forms_service.dart';
import '../../../controllers/employee_controller.dart';
import '../../../widgets/form_widgets/date_time_pickers.dart';
import '../../../widgets/common/custom_button.dart';
import '../../../widgets/common/custom_card.dart';
import '../../../config/theme.dart';
import '../../../config/constants.dart';

class LeaveFormScreen extends StatefulWidget {
  const LeaveFormScreen({super.key});

  @override
  State<LeaveFormScreen> createState() => _LeaveFormScreenState();
}

class _LeaveFormScreenState extends State<LeaveFormScreen> {
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic>? selectedLeaveType;
  DateTime? startDate;
  DateTime? endDate;
  String? reason;
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _fileController = TextEditingController();
  bool _isSubmitting = false;
  bool _isLoading = true;
  List<Map<String, dynamic>> leaveTypes = [];
  Map<String, dynamic>? employeeData;

  final employeeController = Get.find<EmployeeController>();
  final FormsService _formsService = FormsService.instance;

  bool _isSaved = false;
  bool _isFinalized = false;
  bool _isVoided = false;
  int? formId;
  Map<String, dynamic>? formData;
  bool isEditing = false;
  int requestedDays = 0;

  @override
  void initState() {
    super.initState();
    employeeData = employeeController.getEmployeeData();
    formData = Get.arguments as Map<String, dynamic>?;
    if (formData != null) {
      isEditing = true;
    }
    _loadLeaveTypes();
  }

  Future<void> _loadLeaveTypes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final types = await _formsService.getLeaveTypes();
      setState(() {
        leaveTypes = types;
        _isLoading = false;

        // Load form data after leave types are loaded
        if (formData != null) {
          _loadFormData();
        }
      });
    } catch (e) {
      print('Error loading leave types: $e');
      Get.snackbar(
        'Error',
        'Failed to load leave types: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppTheme.dangerColor,
        colorText: Colors.white,
        duration: AppConstants.snackBarDuration,
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _loadFormData() {
    if (formData == null) return;

    setState(() {
      formId = formData!['form_id'];

      // Find the leave type from loaded leave types
      if (formData!['sub_type_int'] != null && leaveTypes.isNotEmpty) {
        try {
          selectedLeaveType = leaveTypes.firstWhere(
            (lt) => lt['leave_id'] == formData!['sub_type_int'],
            orElse: () => leaveTypes.isEmpty ? {} : leaveTypes.first,
          );
        } catch (e) {
          print('Error finding leave type: $e');
        }
      }

      reason = formData!['reason']?.toString();
      _reasonController.text = reason ?? '';

      // Parse dates
      if (formData!['start_date'] != null) {
        startDate = DateTime.parse(formData!['start_date'].toString());
      }
      if (formData!['end_date'] != null) {
        endDate = DateTime.parse(formData!['end_date'].toString());
      }

      // Calculate requested days if dates are available
      if (startDate != null && endDate != null) {
        requestedDays = _calculateDuration(startDate!, endDate!);
      }

      _isSaved = true;
      _isFinalized = formData!['status'] == 'Finalized';
      _isVoided = formData!['status'] == 'Void';

      // If the form is approved, adjust the leave count in the selected leave type
      if (formData!['f_status'] == 'Approved' && selectedLeaveType != null) {
        // We don't modify the original list, but we can adjust the display count
        // for this particular view
        if (selectedLeaveType!['count'] != null) {
          selectedLeaveType = Map<String, dynamic>.from(selectedLeaveType!);
          int updatedCount =
              (selectedLeaveType!['count'] as int) - requestedDays;
          if (updatedCount < 0) updatedCount = 0;
          selectedLeaveType!['count'] = updatedCount;
          selectedLeaveType!['original_count'] = leaveTypes.firstWhere(
            (lt) => lt['leave_id'] == selectedLeaveType!['leave_id'],
            orElse: () => {'count': 0},
          )['count'];
        }
      }
    });
  }

  // Check if leave type is eligible for the employee
  bool isLeaveTypeEligible(Map<String, dynamic> leaveType) {
    // For approved forms in edit mode, consider the original leave type always eligible
    if (isEditing &&
        formData?['f_status'] == 'Approved' &&
        leaveType['leave_id'] == selectedLeaveType?['leave_id']) {
      return true;
    }

    // Check count
    final count = leaveType['count'] ?? 0;
    if (count <= 0) {
      return false;
    }

    // Check sex requirement
    final requiredSex = leaveType['sex']?.toString().toLowerCase() ?? 'all';
    if (requiredSex != 'all') {
      final employeeSex = employeeData?['sex']?.toString().toLowerCase() ?? '';
      if (requiredSex != employeeSex && requiredSex != 'all') {
        return false;
      }
    }

    // Check civil status requirement
    final requiredCivilStatus =
        leaveType['civil_status']?.toString().toLowerCase() ?? 'all';
    if (requiredCivilStatus != 'all') {
      final employeeCivilStatus =
          employeeData?['civil_status']?.toString().toLowerCase() ?? '';
      if (requiredCivilStatus != employeeCivilStatus &&
          requiredCivilStatus != 'all') {
        return false;
      }
    }

    return true;
  }

  String getLeaveTypeTooltip(Map<String, dynamic> leaveType) {
    final List<String> reasons = [];

    // Check count
    final count = leaveType['count'] ?? 0;
    if (count <= 0) {
      reasons.add('No remaining leave credits');
    }

    // Check sex requirement
    final requiredSex = leaveType['sex']?.toString().toLowerCase() ?? 'all';
    if (requiredSex != 'all') {
      final employeeSex = employeeData?['sex']?.toString().toLowerCase() ?? '';
      if (requiredSex != employeeSex) {
        reasons.add(
            'For ${requiredSex == 'f' ? 'female' : 'male'} employees only');
      }
    }

    // Check civil status requirement
    final requiredCivilStatus =
        leaveType['civil_status']?.toString().toLowerCase() ?? 'all';
    if (requiredCivilStatus != 'all') {
      final employeeCivilStatus =
          employeeData?['civil_status']?.toString().toLowerCase() ?? '';
      if (requiredCivilStatus != employeeCivilStatus) {
        reasons.add('For ${requiredCivilStatus.toUpperCase()} employees only');
      }
    }

    return reasons.isNotEmpty ? reasons.join(', ') : '';
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _fileController.dispose();
    super.dispose();
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
        title: const Text('Leave Form', style: AppTheme.titleStyle),
      ),
      body: Container(
        color: Colors.grey.shade50,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: CustomCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Form creation date for existing forms
                        if (isEditing) ...[
                          const Text('Date Created',
                              style: AppTheme.formLabelStyle),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: AppTheme.formFieldContainerDecoration,
                            child:
                                Text(_formatDateTime(formData?['created_on'])),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Leave Type Dropdown
                        _buildLeaveTypeDropdown(),
                        const SizedBox(height: 24),

                        // Date pickers
                        _buildDateRangePicker(),
                        const SizedBox(height: 24),

                        // Reason field
                        _buildReasonField(),
                        const SizedBox(height: 24),

                        // File upload
                        _buildFileUpload(),
                        const SizedBox(height: 32),

                        // Form status for existing forms
                        if (isEditing) ...[
                          const Text('Form Status',
                              style: AppTheme.formLabelStyle),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: AppTheme.formFieldContainerDecoration,
                            child: Text(
                              formData?['status'] == 'Void'
                                  ? 'VOIDED'
                                  : formData?['status'] != 'Finalized'
                                      ? 'NOT SUBMITTED'
                                      : formData?['f_status']
                                              ?.toString()
                                              .toUpperCase() ??
                                          '',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(
                                    formData?['f_status'] ?? ''),
                              ),
                            ),
                          ),
                          if (formData?['date_filed'] != null) ...[
                            const SizedBox(height: 16),
                            const Text('Date Filed',
                                style: AppTheme.formLabelStyle),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: AppTheme.formFieldContainerDecoration,
                              child: Text(
                                  _formatDateTime(formData?['date_filed'])),
                            ),
                          ],
                          const SizedBox(height: 24),
                        ],

                        // Action buttons
                        _buildActionButtons(),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return AppTheme.successColor;
      case 'REJECTED':
        return AppTheme.dangerColor;
      case 'ACTIVE':
        return AppTheme.infoColor;
      case 'VOIDED':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  Widget _buildLeaveTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Leave Type', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<Map<String, dynamic>>(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            enabled: true,
          ),
          value: selectedLeaveType,
          hint: const Text('Select Leave Type'),
          items: leaveTypes.map((leaveType) {
            final bool isEligible = isLeaveTypeEligible(leaveType);

            // Show adjusted count for selected leave type if it's an approved form
            String countDisplay = '${leaveType['count']} days';
            if (isEditing &&
                formData?['f_status'] == 'Approved' &&
                leaveType['leave_id'] == selectedLeaveType?['leave_id'] &&
                selectedLeaveType?['original_count'] != null) {
              countDisplay =
                  '${selectedLeaveType!['count']} days (${selectedLeaveType!['original_count']} - $requestedDays)';
            }

            final String leaveLabel = '${leaveType['label']} ($countDisplay)';
            final String tooltip = getLeaveTypeTooltip(leaveType);

            return DropdownMenuItem<Map<String, dynamic>>(
              value: leaveType,
              enabled: isEligible && !isReadOnly,
              child: Tooltip(
                message: isEligible ? '' : tooltip,
                child: Text(
                  leaveLabel,
                  style: TextStyle(
                    color: (!isEligible || isReadOnly)
                        ? Colors.grey
                        : Colors.black,
                    fontStyle: (!isEligible || isReadOnly)
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                ),
              ),
            );
          }).toList(),
          onChanged: isReadOnly
              ? null
              : (value) {
                  setState(() {
                    selectedLeaveType = value;
                  });
                },
          validator: (value) {
            if (value == null) {
              return 'Please select a leave type';
            }
            return null;
          },
        ),
        if (selectedLeaveType != null) ...[
          const SizedBox(height: 8),
          Text(
            'Selected leave type: ${selectedLeaveType!['label']}',
            style: const TextStyle(
              color: AppTheme.infoColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            selectedLeaveType!['withPay'] == 'Y' ? 'With Pay' : 'Without Pay',
            style: TextStyle(
              color: selectedLeaveType!['withPay'] == 'Y'
                  ? AppTheme.successColor
                  : AppTheme.warningColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDateRangePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DatePickerField(
          label: 'Start Date',
          selectedDate: startDate,
          onDateSelected: (date) {
            setState(() {
              startDate = date;
              // Reset end date if it's before start date
              if (endDate != null && endDate!.isBefore(date)) {
                endDate = date;
              }

              // Update requested days
              if (endDate != null) {
                requestedDays = _calculateDuration(date, endDate!);
              }
            });
          },
          firstDate: DateTime.now(),
          enabled: !isReadOnly,
        ),
        const SizedBox(height: 16),
        DatePickerField(
          label: 'End Date',
          selectedDate: endDate,
          onDateSelected: (date) {
            setState(() {
              endDate = date;

              // Update requested days
              if (startDate != null) {
                requestedDays = _calculateDuration(startDate!, date);
              }
            });
          },
          firstDate: startDate ?? DateTime.now(),
          enabled: !isReadOnly,
        ),
        if (startDate != null && endDate != null) ...[
          const SizedBox(height: 8),
          Text(
            'Duration: ${_calculateDuration(startDate!, endDate!)} day(s)',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ],
    );
  }

  int _calculateDuration(DateTime start, DateTime end) {
    int days = 0;
    DateTime current = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);

    while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
      // Skip weekends (6 = Saturday, 7 = Sunday)
      if (current.weekday != DateTime.saturday &&
          current.weekday != DateTime.sunday) {
        days++;
      }
      current = current.add(const Duration(days: 1));
    }

    return days;
  }

  Widget _buildReasonField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Reason', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _reasonController,
          enabled: !isReadOnly,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Enter reason for leave',
          ),
          maxLines: 3,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a reason';
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
        const Text('Attachments (Optional)',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _fileController,
          enabled: !isReadOnly,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: 'No file selected',
            suffixIcon: IconButton(
              icon: const Icon(Icons.attach_file),
              onPressed: isReadOnly ? null : _pickFile,
            ),
          ),
          readOnly: true,
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    if (isReadOnly) {
      // Show only void button for forms that can be voided
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
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Show Save button if not finalized and not voided
        if (!_isFinalized && !_isVoided) ...[
          CustomButton(
            text: isEditing ? 'Update' : 'Save',
            onPressed: _isSubmitting ? null : _submitForm,
            isLoading: _isSubmitting,
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

        // Show Cancel button if editing a new form
        if (!_isSaved) ...[
          const SizedBox(width: 16),
          CustomButton(
            text: 'Cancel',
            onPressed: () => Get.back(),
            isOutlined: true,
            color: Colors.grey,
          ),
        ],
      ],
    );
  }

  Future<void> _pickFile() async {
    Get.snackbar(
      'Information',
      'File picking will be implemented',
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppTheme.infoColor,
      colorText: Colors.white,
      duration: AppConstants.snackBarDuration,
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedLeaveType == null) {
      Get.snackbar(
        'Error',
        'Please select a leave type',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppTheme.dangerColor,
        colorText: Colors.white,
        duration: AppConstants.snackBarDuration,
      );
      return;
    }

    if (startDate == null || endDate == null) {
      Get.snackbar(
        'Error',
        'Please select both start and end dates',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppTheme.dangerColor,
        colorText: Colors.white,
        duration: AppConstants.snackBarDuration,
      );
      return;
    }

    // Check if the selected leave duration is within available credits
    final int requestedDays = _calculateDuration(startDate!, endDate!);
    final int availableDays = selectedLeaveType!['count'] ?? 0;

    if (requestedDays > availableDays) {
      Get.snackbar(
        'Error',
        'You only have $availableDays days available for this leave type',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppTheme.warningColor,
        colorText: Colors.white,
        duration: AppConstants.snackBarDuration,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final employeeData = this.employeeData;
      if (employeeData == null) {
        throw Exception('Employee data not found');
      }

      final leaveId = selectedLeaveType!['leave_id'];

      final newFormId = await _formsService.saveLeaveForm(
        formId: formId, // Pass existing formId if editing
        empId: employeeData['emp_id'],
        leaveId: leaveId,
        startDate: startDate!,
        endDate: endDate!,
        reason: _reasonController.text,
        attachmentPath: null,
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
      }
    } catch (e) {
      print('Error saving leave form: $e');
      Get.snackbar(
        'Error',
        'Failed to save leave form: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppTheme.dangerColor,
        colorText: Colors.white,
        duration: AppConstants.snackBarDuration,
      );
    } finally {
      setState(() => _isSubmitting = false);
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
      setState(() => _isSubmitting = true);

      try {
        final success = await _formsService.finalizeLeaveForm(formId!);
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
      } catch (e) {
        print('Error finalizing leave form: $e');
        Get.snackbar(
          'Error',
          'Failed to finalize form',
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppTheme.dangerColor,
          colorText: Colors.white,
          duration: AppConstants.snackBarDuration,
        );
      } finally {
        setState(() => _isSubmitting = false);
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
      setState(() => _isSubmitting = true);

      try {
        final success = await _formsService.voidLeaveForm(formId!);
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
      } finally {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _formatDateTime(String? dateTime) {
    if (dateTime == null) return 'Not filed';
    try {
      final date = DateTime.parse(dateTime);
      return DateFormat('MM/dd/yyyy hh:mm a').format(date);
    } catch (e) {
      return 'Invalid Date';
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
          Text(label, style: AppTheme.formLabelStyle),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: AppTheme.formFieldContainerDecoration,
            child: isMultiline
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var line in value.split('\n'))
                        Text(line, style: AppTheme.formValueStyle),
                    ],
                  )
                : Text(value, style: AppTheme.formValueStyle),
          ),
        ],
      ),
    );
  }
}
