import 'package:get/get.dart';
import '../services/auth_service.dart';

class EmployeeController extends GetxController {
  final Rx<Map<String, dynamic>> employeeData = Rx<Map<String, dynamic>>({});
  final currentEmployeeId = RxString('');

  // Additional details from employee.positions
  final RxMap<String, dynamic> positionDetails = RxMap<String, dynamic>({});

  // Names of related entities
  final RxString positionName = RxString('');
  final RxString branchName = RxString('');
  final RxString departmentName = RxString('');
  final RxString officeName = RxString('');
  final RxString unitName = RxString('');
  final RxString companyName = RxString('');

  final AuthService _authService = AuthService.instance;

  void setEmployeeData(Map<String, dynamic> data) {
    employeeData.value = data;
    currentEmployeeId.value = data['emp_id'] ?? '';

    // Load additional position details after setting employee data
    if (data['emp_id'] != null) {
      _loadPositionDetails(data['emp_id']);
    }
  }

  Map<String, dynamic>? getEmployeeData() {
    return employeeData.value;
  }

  /// Get position details including readable names
  Map<String, dynamic> getPositionDetails() {
    return {
      'position': positionName.value,
      'branch': branchName.value,
      'department': departmentName.value,
      'office': officeName.value,
      'unit': unitName.value,
      'company': companyName.value,
      // Don't include raw position details with IDs
    };
  }

  /// Load position details for the employee
  Future<void> _loadPositionDetails(String empId) async {
    try {
      // Fetch position details with the highest position_no
      final position = await _authService.getEmployeePositionDetails(empId);

      if (position != null) {
        // Store the raw position details
        positionDetails.assignAll(position);

        // Fetch and store the readable names for all related entities
        await _loadRelatedEntityNames(position);
      }
    } catch (e) {
      print('Error loading position details: $e');
    }
  }

  /// Load the names of related entities (position, branch, department, etc.)
  Future<void> _loadRelatedEntityNames(Map<String, dynamic> position) async {
    try {
      if (position['position'] != null) {
        final posData =
            await _authService.getEntityName('position', position['position']);
        positionName.value = posData?['name']?.toString() ?? 'Not assigned';
      }

      // Load branch name
      if (position['branch'] != null) {
        final branchData =
            await _authService.getEntityName('branch', position['branch']);
        branchName.value = branchData?['name']?.toString() ?? 'Not assigned';
      }

      // Load department name
      if (position['department'] != null) {
        final deptData = await _authService.getEntityName(
            'department', position['department']);
        departmentName.value = deptData?['name']?.toString() ?? 'Not assigned';
      }

      // Load office name
      if (position['office'] != null) {
        final officeData =
            await _authService.getEntityName('office', position['office']);
        officeName.value = officeData?['name']?.toString() ?? 'Not assigned';
      }

      // Load unit name
      if (position['unit'] != null) {
        final unitData =
            await _authService.getEntityName('unit', position['unit']);
        unitName.value = unitData?['name']?.toString() ?? 'Not assigned';
      }

      // Load company name
      if (position['company'] != null) {
        final companyData =
            await _authService.getEntityName('company', position['company']);
        companyName.value = companyData?['name']?.toString() ?? 'Not assigned';
      }
    } catch (e) {
      print('ERROR: Failed to load entity names: $e');
    }
  }
}
