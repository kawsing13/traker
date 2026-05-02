import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../services/tracker_service.dart';
import '../../controllers/employee_controller.dart';
import '../../providers/api_provider.dart';
import '../../vars.dart';

class DTRScreen extends StatefulWidget {
  const DTRScreen({super.key});
  @override
  State<DTRScreen> createState() => _DTRScreenState();
}

class _DTRScreenState extends State<DTRScreen> {
  final TrackerService _trackerService = TrackerService.instance;
  final employeeController = Get.find<EmployeeController>();
  DateTime selectedMonth = DateTime.now();
  // Single-date filter for remote DTR API
  DateTime selectedDate = DateTime.now();
  bool isLoading = false;
  List<Map<String, dynamic>> dtrRecords = [];
  List<Map<String, dynamic>> remoteDtr = [];
  String? remoteError;

  @override
  void initState() {
    super.initState();
    // Only use remote DTR. Fetch for today by default.
    _fetchRemoteDTR();
  }

  Future<void> _loadDTRData() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    final employeeData = employeeController.getEmployeeData();

    // Fallback to global `empId` if controller doesn't have it yet
    int empIdValue = empId;
    if (employeeData != null &&
        employeeData['emp_id'] != null &&
        employeeData['emp_id'].toString().trim().isNotEmpty) {
      empIdValue = int.tryParse(employeeData['emp_id'].toString()) ?? empId;
    }

    final records = await _trackerService.getDTRRecords(
      empIdValue.toString(),
      selectedMonth,
    );

    // Check if widget is still mounted before updating state
    if (mounted) {
      setState(() {
        dtrRecords = records;
        isLoading = false;
      });
    }
  }

  Future<void> _fetchRemoteDTR() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      remoteDtr = [];
      remoteError = null;
    });

    final employeeData = employeeController.getEmployeeData();

    // Determine emp id: prefer controller data, otherwise fallback to global `empId`.
    int empIdValue = empId;
    if (employeeData != null &&
        employeeData['emp_id'] != null &&
        employeeData['emp_id'].toString().trim().isNotEmpty) {
      empIdValue = int.tryParse(employeeData['emp_id'].toString()) ?? empId;
    }

    if (empIdValue == 0) {
      if (mounted) {
        setState(() {
          isLoading = false;
          remoteError = 'Employee not set. Please login again.';
        });
      }
      return;
    }

    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);

    final result = await hrApiProvider.api.fetchDTR(empIdValue, dateStr);

    if (mounted) {
      setState(() {
        isLoading = false;

        if (result['success'] == true) {
          // Request succeeded
          remoteDtr = result['data'] ?? [];
          if (result['isEmpty'] == true) {
            remoteError = 'No data';
          } else {
            remoteError = null;
          }
        } else {
          // Request failed (no internet or server error)
          remoteDtr = [];
          remoteError =
              'No internet or cannot reach server. Please check your connection.';
        }
      });
    }
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '--:--';
    // Try parsing with seconds+milliseconds, then fallback to seconds only or minutes
    DateTime? time;
    time = DateFormat('HH:mm:ss.SSS').parse(timeStr);
    return DateFormat('HH:mm').format(time);
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
          'Daily Time Record',
          style: TextStyle(color: Colors.black),
        ),
        actions: [],
      ),
      body: Column(
        children: [
          // Header: Remote DTR date filter (defaults to today)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() {
                          selectedDate = picked;
                        });
                        // Auto-fetch DTR when date changes
                        _fetchRemoteDTR();
                      }
                    },
                    icon: const Icon(Icons.filter_alt_outlined),
                    label: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildRemoteDTRList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDTRTable() {
    // Determine max number of in/out pairs
    int maxPairs = 0;
    for (var record in dtrRecords) {
      final pairs = record['pairs'] as List?;
      if (pairs != null) {
        maxPairs =
            (pairs.length ~/ 2 > maxPairs) ? (pairs.length ~/ 2) : maxPairs;
      }
    }

    // Build columns
    List<DataColumn> columns = [
      const DataColumn(label: Text('Date')),
      const DataColumn(label: Text('Day')),
    ];
    for (int i = 0; i < maxPairs; i++) {
      columns.add(DataColumn(label: Text('In ${i + 1}')));
      columns.add(DataColumn(label: Text('Out ${i + 1}')));
    }

    // Build rows
    List<DataRow> rows = dtrRecords.map((record) {
      final date = DateTime.parse(record['date']);
      final pairs = record['pairs'] as List?;
      List<DataCell> cells = [
        DataCell(Text(DateFormat('MM/dd').format(date))),
        DataCell(Text(DateFormat('EEE').format(date))),
      ];
      for (int i = 0; i < maxPairs; i++) {
        final inTime = (pairs != null && pairs.length > i * 2)
            ? _formatTime(pairs[i * 2])
            : '--:--';
        final outTime = (pairs != null && pairs.length > i * 2 + 1)
            ? _formatTime(pairs[i * 2 + 1])
            : '--:--';
        cells.add(DataCell(Text(inTime)));
        cells.add(DataCell(Text(outTime)));
      }
      return DataRow(cells: cells);
    }).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.grey[200]),
          columnSpacing: 24,
          columns: columns,
          rows: rows,
        ),
      ),
    );
  }

  Widget _buildRemoteDTRList() {
    if (remoteError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(remoteError!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _fetchRemoteDTR,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (remoteDtr.isEmpty) {
      return const Center(child: Text('No DTR records for selected date'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: remoteDtr.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final row = remoteDtr[index];
        final time = row['time'] ?? '';
        final state = row['state'] ?? '';
        return ListTile(
          leading: Icon(
              state.toString().toLowerCase() == 'in' || state.toString() == '1'
                  ? Icons.login
                  : Icons.logout),
          title: Text(time.toString()),
          subtitle: Text(state.toString()),
        );
      },
    );
  }

  void _showMonthPicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked != null) {
      setState(() {
        selectedMonth = DateTime(picked.year, picked.month);
      });
      _loadDTRData();
    }
  }
}
