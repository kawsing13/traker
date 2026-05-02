import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/employee_controller.dart'; // Add this import
import '../services/database_service.dart';

class AuthService {
  static final AuthService instance = AuthService._init();
  final DatabaseService _dbService = DatabaseService.instance;

  AuthService._init();

  Future<bool> validateLogin(String empId, String password) async {
    final conn = await _dbService.getConnection();
    try {
      var results = await conn
          .query('SELECT birth_date FROM info WHERE emp_id = ?', [empId]);

      if (results.isNotEmpty) {
        final birthDate = results.first['birth_date'];
        if (birthDate != null) {
          // Convert birth_date to password format (MMDDYYYY)
          final DateTime date = DateTime.parse(birthDate.toString());
          final String formattedDate = DateFormat('MMddyyyy').format(date);
          return password == formattedDate;
        }
      }
      return false;
    } catch (e) {
      print('Login Validation Error: $e');
      return false;
    } finally {
      await conn.close();
    }
  }

  Future<Map<String, dynamic>?> getEmployeeDetails(String empId) async {
    final conn = await _dbService.getConnection();
    try {
      var results = await conn.query(
        '''
        SELECT 
          i.emp_id,
          i.alias,
          i.first_name,
          i.middle_name,
          i.surname,
          i.birth_date,
          i.marital_status,
          i.sex,
          i.birth_place,
          i.email,
          n.date_hired,
          n.tin,
          n.sss,
          n.philhealth,
          n.pagibig
        FROM info i
        LEFT JOIN numbers n ON i.emp_id = n.emp_id
        WHERE i.emp_id = ?
        ''',
        [empId],
      );

      if (results.isNotEmpty) {
        var row = results.first;
        return {
          'emp_id': row['emp_id']?.toString() ?? '',
          'alias': row['alias']?.toString() ?? '',
          'first_name': row['first_name']?.toString() ?? '',
          'middle_name': row['middle_name']?.toString() ?? '',
          'surname': row['surname']?.toString() ?? '',
          'birth_date': row['birth_date']?.toString() ?? '',
          'civil_status': row['marital_status']?.toString() ?? '',
          'sex': row['sex']?.toString() ?? '',
          'birth_place': row['birth_place']?.toString() ?? '',
          'email': row['email']?.toString() ?? '',
          'date_hired': row['date_hired']?.toString() ?? '',
          'tin': row['tin']?.toString() ?? '',
          'sss': row['sss']?.toString() ?? '',
          'phic': row['philhealth']?.toString() ?? '',
          'hdmf': row['pagibig']?.toString() ?? '',
        };
      }
      return null;
    } catch (e) {
      print('Get Employee Error: $e');
      return null;
    } finally {
      await conn.close();
    }
  }

  Future<Map<String, dynamic>?> getEmployeePositionDetails(String empId) async {
    final conn = await _dbService.getConnection();
    try {
      // Query to get the position with the highest position_no for the employee
      final results = await conn.query('''
        SELECT position, branch, department, office, unit, company, position_no
        FROM employee.positions 
        WHERE emp_id = ? 
        ORDER BY position_no DESC 
        LIMIT 1
      ''', [empId]);

      if (results.isNotEmpty) {
        return {
          'position': results.first['position'],
          'branch': results.first['branch'],
          'department': results.first['department'],
          'office': results.first['office'],
          'unit': results.first['unit'],
          'company': results.first['company'],
          'position_no': results.first['position_no'],
        };
      }
      return null;
    } catch (e) {
      print('Error getting position details: $e');
      return null;
    } finally {
      await conn.close();
    }
  }

  /// Get entity name from HR tables
  Future<Map<String, dynamic>?> getEntityName(
      String entityType, int entityId) async {
    final conn = await _dbService.getConnection();
    try {
      // Build the query based on entity type
      String query = 'SELECT id, name FROM hr.$entityType WHERE id = ?';

      final results = await conn.query(query, [entityId]);

      if (results.isNotEmpty) {
        return {
          'id': results.first['id'],
          'name': results.first['name'],
        };
      }
      return null;
    } catch (e) {
      print('Error getting $entityType name: $e');
      return null;
    } finally {
      await conn.close();
    }
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final conn = await _dbService.getConnection();
    try {
      // Your existing login logic
      final results = await conn.query(
        'SELECT * FROM employee.employee WHERE emp_id = ? AND password = ?',
        [username, password],
      );

      if (results.isEmpty) {
        return {'success': false, 'message': 'Invalid credentials'};
      }

      // Create a map of employee data
      final employeeData = {
        'emp_id': results.first['emp_id'],
        'first_name': results.first['first_name'],
        'middle_name': results.first['middle_name'],
        'surname': results.first['surname'],
        // Add other needed fields
      };

      // Update the employee controller
      try {
        final employeeController = Get.find<EmployeeController>();
        employeeController.setEmployeeData(employeeData);
      } catch (e) {
        print('Error finding EmployeeController: $e');
        // If controller is not registered yet, register it
        final controller = EmployeeController();
        Get.put(controller);
        controller.setEmployeeData(employeeData);
      }

      return {
        'success': true,
        'message': 'Login successful',
        'employee': employeeData,
      };
    } catch (e) {
      print('Login error: $e');
      return {'success': false, 'message': 'An error occurred during login'};
    } finally {
      await conn.close();
    }
  }
}
