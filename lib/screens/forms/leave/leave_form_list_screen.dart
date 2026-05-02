import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../../../controllers/employee_controller.dart';
import '../../../services/forms_service.dart';
import '../../../widgets/common/custom_card.dart';
import '../../../widgets/common/custom_button.dart';
import '../../../config/theme.dart';
import '../../../config/routes.dart';
import '../../../config/constants.dart';
import 'leave_form_screen.dart';

class LeaveFormListScreen extends StatefulWidget {
  const LeaveFormListScreen({super.key});

  @override
  State<LeaveFormListScreen> createState() => _LeaveFormListScreenState();
}

class _LeaveFormListScreenState extends State<LeaveFormListScreen> {
  final FormsService _formsService = FormsService.instance;
  final employeeController = Get.find<EmployeeController>();
  final RefreshController _refreshController = RefreshController();
  List<Map<String, dynamic>> forms = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadForms();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _loadForms() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      final employeeData = employeeController.getEmployeeData();
      if (employeeData != null) {
        final loadedForms =
            await _formsService.getLeaveForms(employeeData['emp_id']);
        setState(() {
          forms = loadedForms;
        });
      }
    } catch (e) {
      print('Error loading forms: $e');
      Get.snackbar(
        'Error',
        'Failed to load forms: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppTheme.dangerColor,
        colorText: Colors.white,
        duration: AppConstants.snackBarDuration,
      );
    } finally {
      setState(() {
        isLoading = false;
      });
      _refreshController.refreshCompleted();
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Pending';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat(AppConstants.dateFormatDisplay).format(date);
    } catch (e) {
      return 'Invalid Date';
    }
  }

  // Get status color based on form status

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
          'Leave Forms',
          style: AppTheme.titleStyle,
        ),
      ),
      body: Container(
        color: Colors.grey.shade50,
        child: SmartRefresher(
          controller: _refreshController,
          onRefresh: _loadForms,
          header: const WaterDropHeader(),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : forms.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('No leave forms found',
                              style: AppTheme.subtitleStyle),
                          const SizedBox(height: 16),
                          CustomButton(
                            text: "Create New Leave Form",
                            onPressed: () =>
                                Get.toNamed(AppRoutes.leaveFormNew),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: forms.length,
                      itemBuilder: (context, index) {
                        final form = forms[index];

                        // Get form status text
                        String statusText = form['status'] == 'Void'
                            ? AppConstants.statusVoided
                            : form['status'] != 'Finalized'
                                ? AppConstants.statusNotSubmitted
                                : form['f_status']?.toString().toUpperCase() ??
                                    '';

                        // Calculate duration
                        String duration = 'Unknown';
                        if (form['start_date'] != null &&
                            form['end_date'] != null) {
                          try {
                            final startDate =
                                DateTime.parse(form['start_date']);
                            final endDate = DateTime.parse(form['end_date']);
                            final days = _calculateDuration(startDate, endDate);
                            duration = '$days day(s)';
                          } catch (e) {
                            print('Error calculating duration: $e');
                          }
                        }

                        return FormItemCard(
                          formNumber: form['form_id'].toString(),
                          dateFiled: _formatDate(form['date_filed']),
                          dateApplied:
                              '${_formatDate(form['start_date'])} - ${_formatDate(form['end_date'])}',
                          formType: form['leave_type_label'] ?? 'LEAVE',
                          status: statusText,
                          onTap: () {
                            Get.to(
                              () => const LeaveFormScreen(),
                              arguments: form,
                              transition: Transition.rightToLeft,
                            );
                          },
                          extraContent: [
                            _buildInfoRow('Duration:', duration),
                          ],
                        );
                      },
                    ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed(AppRoutes.leaveFormNew),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _calculateDuration(DateTime start, DateTime end) {
    // Calculate business days excluding weekends
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
}
