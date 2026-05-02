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
//import '../../../config/constants.dart';
import 'dtr_form_screen.dart';

class DtrFormListScreen extends StatefulWidget {
  const DtrFormListScreen({super.key});

  @override
  State<DtrFormListScreen> createState() => _DtrFormListScreenState();
}

class _DtrFormListScreenState extends State<DtrFormListScreen> {
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
            await _formsService.getDtrForms(employeeData['emp_id']);
        setState(() {
          forms = loadedForms;
        });
      }
    } catch (e) {
      print('Error loading forms: $e');
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
      return DateFormat('MM/dd/yyyy').format(date);
    } catch (e) {
      return 'Invalid Date';
    }
  }

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
          'DTR Form',
          style: AppTheme.titleStyle,
        ),
      ),
      body: SmartRefresher(
        controller: _refreshController,
        onRefresh: _loadForms,
        header: const WaterDropHeader(),
        child: forms.isEmpty && !isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('No forms found', style: AppTheme.subtitleStyle),
                    const SizedBox(height: 16),
                    CustomButton(
                      text: "Create New Form",
                      onPressed: () => Get.toNamed(AppRoutes.dtrFormNew),
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
                      ? 'VOIDED'
                      : form['status'] != 'Finalized'
                          ? 'NOT SUBMITTED'
                          : form['f_status']?.toString().toUpperCase() ?? '';

                  // Get form type text
                  String formType = form['sub_type'] == 'log'
                      ? 'FAILED TO LOG'
                      : 'CHANGED SHIFT';

                  return FormItemCard(
                    formNumber: form['form_id'].toString(),
                    dateFiled: _formatDate(form['date_filed']),
                    dateApplied: _formatDate(form['start_date']),
                    formType: formType,
                    status: statusText,
                    onTap: () {
                      Get.to(
                        () => const DtrFormScreen(),
                        arguments: form,
                        transition: Transition.rightToLeft,
                      );
                    },
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed(AppRoutes.dtrFormNew),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }
}
