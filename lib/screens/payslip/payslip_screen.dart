import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/employee_controller.dart';
import '../../services/payroll_service.dart';
import '../../widgets/common/custom_card.dart';
import '../../widgets/common/custom_button.dart';
import '../../config/theme.dart';

class PayslipScreen extends StatefulWidget {
  const PayslipScreen({super.key});

  @override
  State<PayslipScreen> createState() => _PayslipScreenState();
}

class _PayslipScreenState extends State<PayslipScreen> {
  final employeeController = Get.find<EmployeeController>();
  final PayrollService _payrollService = PayrollService.instance;

  bool isLoading = false;
  String selectedPayPeriod = '';

  int selectedMonth = DateTime.now().month;
  int selectedDay = 1; // Only allows 1 or 16
  int selectedYear = DateTime.now().year;
  DateTime? startDate;
  DateTime? endDate;

  final GlobalKey<FormState> _dateFormKey = GlobalKey<FormState>();

  // All data will be populated from database
  final Map<String, dynamic> payslipData = {
    'income': {
      'basic_pay': 0.0, // Will be populated from database
      'benefits': 0.0, // Will be populated from database
      'leave_pay': 0.0, // Will be populated from database
    },
    'net_pay': 0.0, // Will be populated from payroll.atm
    'attendance': <Map<String, dynamic>>[], // Will be populated from database
    'dtr_data': <String, dynamic>{}, // Will be populated from database
    'contributions':
        <Map<String, dynamic>>[], // Will be populated from database
    'loans': <Map<String, dynamic>>[], // Will be populated from database
  };

  int noOfDays = 0;

  @override
  void initState() {
    super.initState();
    setState(() {
      isLoading = false;
    });
  }

  void _generatePayslipPeriod() {
    if (!_dateFormKey.currentState!.validate()) {
      return;
    }

    startDate = DateTime(selectedYear, selectedMonth, selectedDay);

    if (selectedDay == 1) {
      endDate = DateTime(selectedYear, selectedMonth, 15);
    } else {
      endDate = DateTime(selectedYear, selectedMonth + 1, 0);
    }

    String periodString =
        '${DateFormat('MM/dd/yyyy').format(startDate!)}-${DateFormat('MM/dd/yyyy').format(endDate!)}';

    Get.dialog(
      AlertDialog(
        title: const Text('Load Payslip Period'),
        content: Text('Do you want to load payslip for period: $periodString?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          CustomButton(
            text: 'Load',
            onPressed: () {
              Get.back();
              _loadPayslipForPeriod(periodString);
            },
            color: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  void _loadPayslipForPeriod(String period) async {
    setState(() {
      isLoading = true;
    });

    try {
      final employeeData = employeeController.getEmployeeData();
      String empId = '';

      if (employeeData != null && employeeData['emp_id'] != null) {
        empId = employeeData['emp_id'];

        if (startDate != null && endDate != null) {
          noOfDays = endDate!.difference(startDate!).inDays + 1;

          // NEW: Check if period is Finalized before loading
          final isFinalized =
              await _payrollService.isPayslipPeriodFinalized(startDate!);
          if (!isFinalized) {
            setState(() {
              isLoading = false;
            });
            Get.snackbar(
              'No Finalized Payslip',
              'No Finalized payslip for period: $period',
              snackPosition: SnackPosition.TOP,
              backgroundColor: AppTheme.dangerColor,
              colorText: Colors.white,
              duration: const Duration(seconds: 5),
            );
            return;
          }

          await Future.wait([
            _loadAttendanceData(empId, startDate!, endDate!),
            _loadIncomeData(empId, startDate!, endDate!),
            _loadDTRData(empId, startDate!, endDate!),
            _loadContributionsData(empId, startDate!, endDate!),
            _loadLoansData(empId, startDate!, endDate!),
            _loadNetPayData(empId, startDate!),
          ]);

          setState(() {
            isLoading = false;
            selectedPayPeriod = period;
          });

          Get.snackbar(
            'Success',
            'Payslip loaded successfully for period: $period',
            snackPosition: SnackPosition.TOP,
            backgroundColor: AppTheme.successColor,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
        } else {
          throw Exception('Employee ID not available');
        }
      } else {
        throw Exception('Employee ID not available');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      Get.snackbar(
        'Error',
        'Failed to load payslip: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppTheme.dangerColor,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    }
  }

  /// Load net pay data from payroll.atm table
  Future<void> _loadNetPayData(String empId, DateTime payStart) async {
    try {
      final netPay = await _payrollService.getEmployeeNetPay(empId, payStart);

      setState(() {
        payslipData['net_pay'] = netPay;
      });
    } catch (e) {
      print('Error loading net pay data: $e');
      setState(() {
        payslipData['net_pay'] = 0.0;
      });
    }
  }

  /// Load loans data for the selected period
  Future<void> _loadLoansData(
      String empId, DateTime payStart, DateTime payEnd) async {
    try {
      final loans =
          await _payrollService.getEmployeeLoans(empId, payStart, payEnd);

      setState(() {
        payslipData['loans'] = loans;
      });
    } catch (e) {
      print('Error loading loans data: $e');
      setState(() {
        payslipData['loans'] = <Map<String, dynamic>>[];
      });
    }
  }

  /// Load contributions data for the selected period
  Future<void> _loadContributionsData(
      String empId, DateTime payStart, DateTime payEnd) async {
    try {
      final contributions = await _payrollService.getEmployeeContributions(
          empId, payStart, payEnd);

      setState(() {
        payslipData['contributions'] = contributions;
      });
    } catch (e) {
      print('Error loading contributions data: $e');
      setState(() {
        payslipData['contributions'] = <Map<String, dynamic>>[];
      });
    }
  }

  /// Load DTR data for the selected period
  Future<void> _loadDTRData(
      String empId, DateTime payStart, DateTime payEnd) async {
    try {
      final dtrData =
          await _payrollService.getEmployeeDTRData(empId, payStart, payEnd);

      setState(() {
        payslipData['dtr_data'] = dtrData;
      });
    } catch (e) {
      print('Error loading DTR data: $e');
      setState(() {
        payslipData['dtr_data'] = {
          'absences': {'total': 0.0, 'pay': 0.0},
          'late': {'total': 0.0, 'pay': 0.0},
          'undertime': {'total': 0.0, 'pay': 0.0},
        };
      });
    }
  }

  /// Load all income data (basic pay, benefits, leave pay)
  Future<void> _loadIncomeData(
      String empId, DateTime payStart, DateTime payEnd) async {
    try {
      // Load basic pay (not date dependent)
      final basicPay = await _payrollService.getEmployeeBasicPay(empId);

      // Load benefits for the period
      final benefits =
          await _payrollService.getEmployeeBenefits(empId, payStart, payEnd);

      // Load leave pay for the period
      final leavePay =
          await _payrollService.getEmployeeLeavePay(empId, payStart, payEnd);

      setState(() {
        payslipData['income']['basic_pay'] = basicPay;
        payslipData['income']['benefits'] = benefits;
        payslipData['income']['leave_pay'] = leavePay;
      });
    } catch (e) {
      print('Error loading income data: $e');
      setState(() {
        payslipData['income']['basic_pay'] = 0.0;
        payslipData['income']['benefits'] = 0.0;
        payslipData['income']['leave_pay'] = 0.0;
      });
    }
  }

  Future<void> _loadAttendanceData(
      String empId, DateTime payStart, DateTime payEnd) async {
    try {
      // Batch fetch attendance logs for all days in the period
      final attendanceRecords = await _payrollService
          .getEmployeeAttendanceLogsForPeriod(empId, payStart, payEnd);

      // Also fetch payroll days data as before
      final payrollDaysData =
          await _payrollService.getEmployeePayrollDays(empId, payStart, payEnd);

      List<Map<String, dynamic>> attendanceList = [];

      // Loop through each day and process logs
      DateTime currentDate = payStart;
      while (!currentDate.isAfter(payEnd)) {
        final dateKey = DateFormat('yyyy-MM-dd').format(currentDate);
        final dayAttendance = attendanceRecords[dateKey] ?? [];
        final payrollDayData = payrollDaysData[dateKey];

        String timeIn1 = '';
        String timeOut1 = '';
        String timeIn2 = '';
        String timeOut2 = '';
        String remarks = '';
        double hoursWorked = 0.0;

        // Get hours worked and remarks from payroll.days
        if (payrollDayData != null) {
          hoursWorked = payrollDayData['hours_worked'] ?? 0.0;
          final abValue = payrollDayData['ab'] ?? 0.0;

          if (abValue == 1.0) {
            remarks = 'AB';
          } else if (abValue == 0.5) {
            remarks = 'HD';
          }
        }

        if (dayAttendance.isNotEmpty) {
          dayAttendance.sort((a, b) {
            final timeA = _extractTimeString(a['log_time']);
            final timeB = _extractTimeString(b['log_time']);
            return timeA.compareTo(timeB);
          });

          List<String> inTimes = [];
          List<String> outTimes = [];

          for (var log in dayAttendance) {
            final timeStr = _extractTimeString(log['log_time']);
            if (log['state'] == 1) {
              inTimes.add(timeStr);
            } else if (log['state'] == 0) {
              outTimes.add(timeStr);
            }
          }

          if (inTimes.isNotEmpty) timeIn1 = inTimes[0];
          if (outTimes.isNotEmpty) timeOut1 = outTimes[0];
          if (inTimes.length > 1) timeIn2 = inTimes[1];
          if (outTimes.length > 1) timeOut2 = outTimes[1];
        }

        if (payrollDayData == null && dayAttendance.isEmpty) {
          remarks = 'No Record';
        }

        attendanceList.add({
          'date': DateFormat('MM/dd').format(currentDate),
          'in1': timeIn1,
          'out1': timeOut1,
          'in2': timeIn2,
          'out2': timeOut2,
          'remarks': remarks,
          'hours_worked': hoursWorked,
        });

        currentDate = currentDate.add(const Duration(days: 1));
      }

      setState(() {
        payslipData['attendance'] = attendanceList;
      });
    } catch (e) {
      print('Error loading attendance data: $e');
      setState(() {
        payslipData['attendance'] = <Map<String, dynamic>>[];
      });
    }
  }

  /// Extract time string from various possible formats
  String _extractTimeString(dynamic timeValue) {
    if (timeValue == null) return '';

    if (timeValue is String) {
      // If it's already a time string, format it to HH:mm
      try {
        if (timeValue.contains('T')) {
          // ISO format: 2024-06-11T08:30:00
          final dateTime = DateTime.parse(timeValue);
          return DateFormat('HH:mm').format(dateTime);
        } else if (timeValue.contains(':')) {
          // Time only format: 08:30:00 or 08:30
          final parts = timeValue.split(':');
          if (parts.length >= 2) {
            return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
          }
        }
      } catch (e) {
        print('Error parsing time string: $timeValue - $e');
      }
      return timeValue;
    } else if (timeValue is DateTime) {
      return DateFormat('HH:mm').format(timeValue);
    } else if (timeValue is Duration) {
      // Handle Duration objects (like from MySQL TIME fields)
      final totalSeconds = timeValue.inSeconds;
      final hours = totalSeconds ~/ 3600;
      final minutes = (totalSeconds % 3600) ~/ 60;
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
    } else {
      // Try to convert to string and parse
      return _extractTimeString(timeValue.toString());
    }
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return '0.00';

    final formatter = NumberFormat.currency(
      locale: 'en_PH',
      symbol: '',
      decimalDigits: 2,
    );

    return formatter.format(double.tryParse(amount.toString()) ?? 0);
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
        title: const Text('Payslip', style: AppTheme.titleStyle),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEmployeeInfo(),
                  const SizedBox(height: 16),
                  _buildDateSelectionCard(),
                  const SizedBox(height: 16),
                  if (selectedPayPeriod.isNotEmpty) ...[
                    _buildAttendanceSection(),
                    const SizedBox(height: 16),
                    _buildIncomeSection(),
                    const SizedBox(height: 16),
                    _buildDTRSection(),
                    const SizedBox(height: 16),
                    _buildContributionsSection(),
                    const SizedBox(height: 16),
                    _buildLoansSection(),
                    const SizedBox(height: 20),
                    _buildNetPay(),
                    const SizedBox(height: 24),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Get.snackbar(
                            'Information',
                            'Download feature coming soon',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: AppTheme.infoColor,
                            colorText: Colors.white,
                          );
                        },
                        icon: const Icon(Icons.download),
                        label: const Text('Download PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildEmployeeInfo() {
    final employeeData = employeeController.getEmployeeData();
    // Get position details from the controller instead of hardcoded values
    final positionDetails = employeeController.getPositionDetails();

    String displayName = '';

    if (employeeData != null) {
      final String firstName = employeeData['first_name'] ?? '';
      final String middleName = employeeData['middle_name'] ?? '';
      final String lastName = employeeData['surname'] ?? '';

      String middleInitial = '';
      if (middleName.isNotEmpty) {
        middleInitial = ' ${middleName.substring(0, 1)}.';
      }

      displayName = '$firstName$middleInitial $lastName';
    }

    final String empId =
        employeeData != null ? employeeData['emp_id'] ?? '' : '';

    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dynamic pay period header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Text(
              'Pay Period: '
              '${startDate != null && endDate != null ? "${DateFormat('MM/dd/yyyy').format(startDate!)} - ${DateFormat('MM/dd/yyyy').format(endDate!)}" : "Not Selected"}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Employee: $displayName',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          // Use position information from controller
          Text('Position: ${positionDetails['position'] ?? 'N/A'}'),
          const SizedBox(height: 4),
          Text('Department: ${positionDetails['department'] ?? 'N/A'}'),
          const SizedBox(height: 4),
          Text('Office: ${positionDetails['office'] ?? 'N/A'}'),
          if (positionDetails['branch'] != null &&
              positionDetails['branch'] != 'Not assigned') ...[
            const SizedBox(height: 4),
            Text('Branch: ${positionDetails['branch']}'),
          ],
          const SizedBox(height: 4),
          Text('Employee ID: $empId'),
          if (noOfDays > 0) ...[
            const SizedBox(height: 8),
            Text('Number of Days: $noOfDays',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ],
      ),
    );
  }

  Widget _buildDateSelectionCard() {
    final List<DropdownMenuItem<int>> monthItems = List.generate(
      12,
      (index) => DropdownMenuItem(
        value: index + 1,
        child: Text(DateFormat('MMM').format(DateTime(2023, index + 1))),
      ),
    );

    final List<DropdownMenuItem<int>> dayItems = [
      const DropdownMenuItem(value: 1, child: Text('1')),
      const DropdownMenuItem(value: 16, child: Text('16')),
    ];

    final int currentYear = DateTime.now().year;
    final List<DropdownMenuItem<int>> yearItems = List.generate(
      3,
      (index) => DropdownMenuItem(
        value: currentYear - index,
        child: Text('${currentYear - index}'),
      ),
    );

    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _dateFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Generate Payslip Period',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Select start date',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Month',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      isDense: true,
                    ),
                    value: selectedMonth,
                    items: monthItems,
                    onChanged: (value) {
                      setState(() {
                        if (value != null) selectedMonth = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) return 'Required';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Day',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      isDense: true,
                    ),
                    value: selectedDay,
                    items: dayItems,
                    onChanged: (value) {
                      setState(() {
                        if (value != null) selectedDay = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) return 'Required';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Year',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      isDense: true,
                    ),
                    value: selectedYear,
                    items: yearItems,
                    onChanged: (value) {
                      setState(() {
                        if (value != null) selectedYear = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) return 'Required';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'End date will be: ${_getCalculatedEndDate()}',
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: CustomButton(
                text: 'Generate Period',
                onPressed: _generatePayslipPeriod,
                icon: Icons.calendar_today,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCalculatedEndDate() {
    if (selectedDay == 1) {
      return DateFormat('MM/dd/yyyy')
          .format(DateTime(selectedYear, selectedMonth, 15));
    } else {
      return DateFormat('MM/dd/yyyy')
          .format(DateTime(selectedYear, selectedMonth + 1, 0));
    }
  }

  Widget _buildAttendanceSection() {
    final attendance = payslipData['attendance'] as List<dynamic>;

    if (attendance.isEmpty) {
      return const CustomCard(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Attendance', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('No attendance records found for this period.'),
          ],
        ),
      );
    }

    return CustomCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Attendance',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 12,
              columns: const [
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('In 1')),
                DataColumn(label: Text('Out 1')),
                DataColumn(label: Text('In 2')),
                DataColumn(label: Text('Out 2')),
                DataColumn(label: Text('Remarks')),
                DataColumn(label: Text('Hrs')),
              ],
              rows: attendance.map<DataRow>((record) {
                return DataRow(cells: [
                  DataCell(Text(record['date'] ?? '')),
                  DataCell(Text(record['in1'] ?? '')),
                  DataCell(Text(record['out1'] ?? '')),
                  DataCell(Text(record['in2'] ?? '')),
                  DataCell(Text(record['out2'] ?? '')),
                  DataCell(Text(record['remarks'] ?? '')),
                  DataCell(
                      Text((record['hours_worked'] ?? 0.0).toStringAsFixed(2))),
                ]);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeSection() {
    final income = payslipData['income'] as Map<String, dynamic>;

    return CustomCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Income', style: TextStyle(fontWeight: FontWeight.bold)),
          _buildIncomeRow('Basic Pay', income['basic_pay']),
          _buildIncomeRow('Benefits', income['benefits']),
          _buildIncomeRow('Leave Pay', income['leave_pay']),
        ],
      ),
    );
  }

  Widget _buildIncomeRow(String label, dynamic value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(_formatCurrency(value)),
      ],
    );
  }

  Widget _buildDTRSection() {
    final dtrData = payslipData['dtr_data'] as Map<String, dynamic>;

    if (dtrData.isEmpty) {
      return const CustomCard(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('DTR', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('No DTR data found for this period.'),
          ],
        ),
      );
    }

    final absences = dtrData['absences'] ?? {'total': 0.0, 'pay': 0.0};
    final late = dtrData['late'] ?? {'total': 0.0, 'pay': 0.0};
    final undertime = dtrData['undertime'] ?? {'total': 0.0, 'pay': 0.0};

    return CustomCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('DTR', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildDTRRow('Absences', absences['total'], absences['pay']),
          _buildDTRRow('Late', late['total'], late['pay']),
          _buildDTRRow('Undertime', undertime['total'], undertime['pay']),
        ],
      ),
    );
  }

  Widget _buildDTRRow(String label, dynamic total, dynamic pay) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$label (${(total ?? 0.0).toStringAsFixed(2)})'),
          Text(_formatCurrency(pay)),
        ],
      ),
    );
  }

  Widget _buildContributionsSection() {
    final contributions = payslipData['contributions'] as List<dynamic>;

    if (contributions.isEmpty) {
      return const CustomCard(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Contributions',
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('No contributions found for this period.'),
          ],
        ),
      );
    }

    return CustomCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Contributions',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...contributions.map<Widget>((contribution) {
            return _buildContributionRow(
              contribution['contribution_id'] ?? '',
              contribution['employee'] ?? 0.0,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildContributionRow(String contributionId, dynamic amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(contributionId),
          Text(_formatCurrency(amount)),
        ],
      ),
    );
  }

  Widget _buildLoansSection() {
    final loans = payslipData['loans'] as List<dynamic>;

    if (loans.isEmpty) {
      return const CustomCard(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Loans', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('No loans found for this period.'),
          ],
        ),
      );
    }

    return CustomCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Loans', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...loans.map<Widget>((loan) {
            return _buildLoanRow(
              loan['description'] ?? 'Unknown Loan Type',
              loan['amount'] ?? 0.0,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLoanRow(String description, dynamic amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(description),
          Text(_formatCurrency(amount)),
        ],
      ),
    );
  }

  Widget _buildNetPay() {
    final netPay = payslipData['net_pay'] ?? 0.0;
    return Center(
      child: Text(
        'Net Pay: ₱${_formatCurrency(netPay)}',
        style: const TextStyle(
            fontWeight: FontWeight.bold, fontSize: 20, color: Colors.green),
      ),
    );
  }
}
