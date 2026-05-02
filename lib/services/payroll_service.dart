import 'package:intl/intl.dart';
import 'database_service.dart';

class PayrollService {
  static final PayrollService instance = PayrollService._init();
  PayrollService._init();

  final DatabaseService _dbService = DatabaseService.instance;

  Future<Map<String, Map<String, dynamic>>> getEmployeePayrollDays(
      String empId, DateTime payStart, DateTime payEnd) async {
    final conn = await _dbService.getConnection();

    try {
      final String formattedStartDate =
          DateFormat('yyyy-MM-dd').format(payStart);
      final String formattedEndDate = DateFormat('yyyy-MM-dd').format(payEnd);

      // Execute the query to get payroll days data
      final payrollDaysResults = await conn.query('''
        SELECT pay_date, ab, hours_worked 
        FROM payroll.days 
        WHERE emp_id=? 
        AND pay_date BETWEEN ? AND ?
        ORDER BY pay_date
      ''', [
        empId, // For emp_id=?
        formattedStartDate, // For pay_date BETWEEN ?
        formattedEndDate, // For AND ?
      ]);

      // Process results into a map with date as key
      Map<String, Map<String, dynamic>> payrollDays = {};

      for (var row in payrollDaysResults) {
        if (row['pay_date'] != null) {
          final date = row['pay_date'] is DateTime
              ? row['pay_date'] as DateTime
              : DateTime.parse(row['pay_date'].toString());

          final dateKey = DateFormat('yyyy-MM-dd').format(date);

          payrollDays[dateKey] = {
            'ab': (row['ab'] as num?)?.toDouble() ?? 0.0,
            'hours_worked': (row['hours_worked'] as num?)?.toDouble() ?? 0.0,
          };
        }
      }

      return payrollDays;
    } catch (e) {
      print('Error getting payroll days: $e');
      return {};
    } finally {
      await conn.close();
    }
  }

  /// Get basic pay from employee.positions table based on highest position_no
  Future<double> getEmployeeBasicPay(String empId) async {
    final conn = await _dbService.getConnection();

    try {
      // Execute the query to get the position with highest position_no
      final positionResults = await conn.query('''
        SELECT rate, rate_factor
        FROM employee.positions 
        WHERE emp_id=? 
        ORDER BY position_no DESC
        LIMIT 1
      ''', [
        empId, // For emp_id=?
      ]);

      // Calculate basic pay based on rate and rate_factor
      if (positionResults.isNotEmpty) {
        final row = positionResults.first;
        final rate = (row['rate'] as num?)?.toDouble() ?? 0.0;
        final rateFactor = row['rate_factor']?.toString() ?? '';

        double basicPay = 0.0;

        switch (rateFactor.toLowerCase()) {
          case 'month':
            basicPay = rate / 2; // Divide by 2 for semi-monthly
            break;
          case 'day':
            basicPay =
                rate * 11; // Multiply by 11 for semi-monthly (working days)
            break;
          case 'week':
            basicPay = rate * 2; // Multiply by 2 for semi-monthly
            break;
          default:
            basicPay = rate; // Use rate as-is if factor is unknown
            break;
        }

        return basicPay;
      }

      return 0.0;
    } catch (e) {
      print('Error getting employee basic pay from positions: $e');
      return 0.0;
    } finally {
      await conn.close();
    }
  }

  /// Get total benefits for the period from payroll.benefits table
  Future<double> getEmployeeBenefits(
      String empId, DateTime payStart, DateTime payEnd) async {
    final conn = await _dbService.getConnection();

    try {
      final String formattedStartDate =
          DateFormat('yyyy-MM-dd').format(payStart);
      final String formattedEndDate = DateFormat('yyyy-MM-dd').format(payEnd);

      // Execute the query to get sum of benefits
      final benefitsResults = await conn.query('''
        SELECT COALESCE(SUM(amount), 0) as total_benefits
        FROM payroll.benefits 
        WHERE emp_id=? 
        AND date BETWEEN ? AND ?
      ''', [
        empId, // For emp_id=?
        formattedStartDate, // For date BETWEEN ?
        formattedEndDate, // For AND ?
      ]);

      // Extract the total from the result
      if (benefitsResults.isNotEmpty &&
          benefitsResults.first['total_benefits'] != null) {
        return (benefitsResults.first['total_benefits'] as num).toDouble();
      }

      return 0.0;
    } catch (e) {
      print('Error getting employee benefits: $e');
      return 0.0;
    } finally {
      await conn.close();
    }
  }

  /// Get total leave pay for the period from payroll.days table
  Future<double> getEmployeeLeavePay(
      String empId, DateTime payStart, DateTime payEnd) async {
    final conn = await _dbService.getConnection();

    try {
      final String formattedStartDate =
          DateFormat('yyyy-MM-dd').format(payStart);
      final String formattedEndDate = DateFormat('yyyy-MM-dd').format(payEnd);

      // Execute the query to get sum of leave pay
      final leavePayResults = await conn.query('''
        SELECT COALESCE(SUM(lv_pay), 0) as total_leave_pay
        FROM payroll.days 
        WHERE emp_id=? 
        AND pay_date BETWEEN ? AND ?
      ''', [
        empId, // For emp_id=?
        formattedStartDate, // For pay_date BETWEEN ?
        formattedEndDate, // For AND ?
      ]);

      // Extract the total from the result
      if (leavePayResults.isNotEmpty &&
          leavePayResults.first['total_leave_pay'] != null) {
        return (leavePayResults.first['total_leave_pay'] as num).toDouble();
      }

      return 0.0;
    } catch (e) {
      print('Error getting employee leave pay: $e');
      return 0.0;
    } finally {
      await conn.close();
    }
  }

  /// Get DTR data (absences, late, undertime) for the period from payroll.days table
  Future<Map<String, dynamic>> getEmployeeDTRData(
      String empId, DateTime payStart, DateTime payEnd) async {
    final conn = await _dbService.getConnection();

    try {
      final String formattedStartDate =
          DateFormat('yyyy-MM-dd').format(payStart);
      final String formattedEndDate = DateFormat('yyyy-MM-dd').format(payEnd);

      // Execute the query to get DTR data
      final dtrResults = await conn.query('''
        SELECT 
          COALESCE(SUM(ab), 0) as total_absences,
          COALESCE(SUM(ab_pay), 0) as total_absences_pay,
          COALESCE(SUM(la), 0) as total_late,
          COALESCE(SUM(la_pay), 0) as total_late_pay,
          COALESCE(SUM(ut), 0) as total_undertime,
          COALESCE(SUM(ut_pay), 0) as total_undertime_pay
        FROM payroll.days 
        WHERE emp_id=? 
        AND pay_date BETWEEN ? AND ?
      ''', [
        empId, // For emp_id=?
        formattedStartDate, // For pay_date BETWEEN ?
        formattedEndDate, // For AND ?
      ]);

      // Extract the totals from the result
      if (dtrResults.isNotEmpty) {
        final row = dtrResults.first;
        return {
          'absences': {
            'total': (row['total_absences'] as num?)?.toDouble() ?? 0.0,
            'pay': (row['total_absences_pay'] as num?)?.toDouble() ?? 0.0,
          },
          'late': {
            'total': (row['total_late'] as num?)?.toDouble() ?? 0.0,
            'pay': (row['total_late_pay'] as num?)?.toDouble() ?? 0.0,
          },
          'undertime': {
            'total': (row['total_undertime'] as num?)?.toDouble() ?? 0.0,
            'pay': (row['total_undertime_pay'] as num?)?.toDouble() ?? 0.0,
          },
        };
      }

      return {
        'absences': {'total': 0.0, 'pay': 0.0},
        'late': {'total': 0.0, 'pay': 0.0},
        'undertime': {'total': 0.0, 'pay': 0.0},
      };
    } catch (e) {
      print('Error getting employee DTR data: $e');
      return {
        'absences': {'total': 0.0, 'pay': 0.0},
        'late': {'total': 0.0, 'pay': 0.0},
        'undertime': {'total': 0.0, 'pay': 0.0},
      };
    } finally {
      await conn.close();
    }
  }

  /// Get contributions data for the period from payroll.contributions table
  Future<List<Map<String, dynamic>>> getEmployeeContributions(
      String empId, DateTime payStart, DateTime payEnd) async {
    final conn = await _dbService.getConnection();

    try {
      final String formattedStartDate =
          DateFormat('yyyy-MM-dd').format(payStart);
      final String formattedEndDate = DateFormat('yyyy-MM-dd').format(payEnd);

      // Execute the query to get contributions data
      final contributionsResults = await conn.query('''
        SELECT contribution_id, employee, date
        FROM payroll.contributions 
        WHERE emp_id=? 
        AND date BETWEEN ? AND ?
        ORDER BY date, contribution_id
      ''', [
        empId, // For emp_id=?
        formattedStartDate, // For date BETWEEN ?
        formattedEndDate, // For AND ?
      ]);

      // Process results into a list
      List<Map<String, dynamic>> contributions = [];

      for (var row in contributionsResults) {
        contributions.add({
          'contribution_id': row['contribution_id']?.toString() ?? '',
          'employee': (row['employee'] as num?)?.toDouble() ?? 0.0,
          'date': row['date'],
        });
      }

      return contributions;
    } catch (e) {
      print('Error getting employee contributions: $e');
      return [];
    } finally {
      await conn.close();
    }
  }

  /// Get loans data for the period from payroll.loans with loan type descriptions
  Future<List<Map<String, dynamic>>> getEmployeeLoans(
      String empId, DateTime payStart, DateTime payEnd) async {
    final conn = await _dbService.getConnection();

    try {
      final String formattedStartDate =
          DateFormat('yyyy-MM-dd').format(payStart);
      final String formattedEndDate = DateFormat('yyyy-MM-dd').format(payEnd);

      // Execute the query to get loans data with loan type descriptions
      final loansResults = await conn.query('''
        SELECT pl.amount, pl.date, lt.description
        FROM payroll.loans pl
        LEFT JOIN hr.loan_types lt ON pl.loan_type = lt.id
        WHERE pl.emp_id=? 
        AND pl.date BETWEEN ? AND ?
        ORDER BY pl.date, lt.description
      ''', [
        empId, // For emp_id=?
        formattedStartDate, // For date BETWEEN ?
        formattedEndDate, // For AND ?
      ]);

      // Process results into a list
      List<Map<String, dynamic>> loans = [];

      for (var row in loansResults) {
        loans.add({
          'description': row['description']?.toString() ?? 'Unknown Loan Type',
          'amount': (row['amount'] as num?)?.toDouble() ?? 0.0,
          'date': row['date'],
        });
      }

      return loans;
    } catch (e) {
      print('Error getting employee loans: $e');
      return [];
    } finally {
      await conn.close();
    }
  }

  /// Get net pay from payroll.atm table
  Future<double> getEmployeeNetPay(String empId, DateTime payStart) async {
    final conn = await _dbService.getConnection();

    try {
      final String formattedStartDate =
          DateFormat('yyyy-MM-dd').format(payStart);

      // Execute the query to get net pay from atm table
      final atmResults = await conn.query('''
        SELECT amount
        FROM payroll.atm 
        WHERE emp_id=? 
        AND pay_start = ?
        LIMIT 1
      ''', [
        empId, // For emp_id=?
        formattedStartDate, // For pay_start = ?
      ]);

      // Extract the amount from the result
      if (atmResults.isNotEmpty && atmResults.first['amount'] != null) {
        return (atmResults.first['amount'] as num).toDouble();
      }

      return 0.0;
    } catch (e) {
      print('Error getting employee net pay from ATM: $e');
      return 0.0;
    } finally {
      await conn.close();
    }
  }

  /// Get detailed attendance logs for a specific date
  Future<List<Map<String, dynamic>>> getEmployeeAttendanceLogs(
      String empId, DateTime date) async {
    final attendantConn = await _dbService.getAttendantConnection();

    try {
      final String formattedDate = DateFormat('yyyy-MM-dd').format(date);

      // Execute the query to get attendance logs
      final attendanceLogsResults = await attendantConn.query('''
        SELECT `time` as log_time, `state` 
        FROM attendant.login 
        WHERE emp_id=? AND `date` = ? 
        ORDER BY `time`
      ''', [
        empId, // For emp_id=?
        formattedDate, // For `date` = ?
      ]);

      // Process results
      List<Map<String, dynamic>> attendanceLogs = [];

      for (var row in attendanceLogsResults) {
        attendanceLogs.add({
          'log_time': row['log_time'],
          'state': row['state'],
        });
      }

      return attendanceLogs;
    } catch (e) {
      print('Error getting employee attendance logs: $e');
      return [];
    } finally {
      await attendantConn.close();
    }
  }

  /// Get all attendance records for a pay period
  Future<Map<String, List<Map<String, dynamic>>>>
      getEmployeeAttendanceLogsForPeriod(
          String empId, DateTime payStart, DateTime payEnd) async {
    final attendantConn = await _dbService.getAttendantConnection();

    try {
      final String formattedStartDate =
          DateFormat('yyyy-MM-dd').format(payStart);
      final String formattedEndDate = DateFormat('yyyy-MM-dd').format(payEnd);

      // Query all logs for the period
      final results = await attendantConn.query('''
        SELECT `date`, `time` as log_time, `state`
        FROM attendant.login
        WHERE emp_id=? AND `date` BETWEEN ? AND ?
        ORDER BY `date`, `time`
      ''', [
        empId,
        formattedStartDate,
        formattedEndDate,
      ]);

      // Group logs by date
      Map<String, List<Map<String, dynamic>>> attendanceByDate = {};
      for (var row in results) {
        final dateObj = row['date'] is DateTime
            ? row['date'] as DateTime
            : DateTime.parse(row['date'].toString());
        final dateKey = DateFormat('yyyy-MM-dd').format(dateObj);
        attendanceByDate.putIfAbsent(dateKey, () => []);
        attendanceByDate[dateKey]!.add({
          'log_time': row['log_time'],
          'state': row['state'],
        });
      }
      return attendanceByDate;
    } catch (e) {
      print('Error getting period attendance logs: $e');
      return {};
    } finally {
      await attendantConn.close();
    }
  }

  /// Dummy method to simulate logging a payslip period (always returns success)
  Future<bool> logPayslipPeriod(
      String empId, DateTime payStart, DateTime payEnd) async {
    // Just return true without doing any database operations
    return true;
  }

  Future<bool> isPayslipPeriodFinalized(DateTime payStart) async {
    final conn = await _dbService.getConnection();
    try {
      final String formattedStartDate =
          DateFormat('yyyy-MM-dd').format(payStart);
      final results = await conn.query('''
        SELECT status
        FROM payroll.status
        WHERE pay_start = ?
        LIMIT 1
      ''', [formattedStartDate]);
      if (results.isNotEmpty && results.first['status'] != null) {
        print("Payslip period status: ${results.first['status']}");
        return results.first['status'].toString() == 'Finalized';
      }
      return false;
    } catch (e) {
      print('Error checking payslip period status: $e');
      return false;
    } finally {
      await conn.close();
    }
  }
}
