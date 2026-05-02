//import 'package:mysql1/mysql1.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'database_service.dart';

class FormsService {
  static final FormsService instance = FormsService._init();
  FormsService._init();

  final DatabaseService _dbService = DatabaseService.instance;

  // OBLU Forms Functions
  Future<int?> saveObluForm({
    int? formId,
    required String empId,
    required String subType,
    required DateTime selectedDate,
    TimeOfDay? timeIn,
    TimeOfDay? timeOut,
    required String reason,
    String? lateReason,
  }) async {
    final conn = await _dbService.getConnection();
    try {
      String? startTime;
      String? endTime;
      bool isLateFiling = selectedDate.isBefore(DateTime.now());

      // Handle time based on sub_type
      if (subType == 'late') {
        if (timeIn != null) {
          startTime =
              '${timeIn.hour.toString().padLeft(2, '0')}:${timeIn.minute.toString().padLeft(2, '0')}:00';
        }
        endTime = '00:00:00';
      } else if (subType == 'undertime') {
        if (timeOut != null) {
          startTime =
              '${timeOut.hour.toString().padLeft(2, '0')}:${timeOut.minute.toString().padLeft(2, '0')}:00';
        }
        endTime = '00:00:00';
      } else if (subType == 'ot') {
        if (timeIn != null) {
          startTime =
              '${timeIn.hour.toString().padLeft(2, '0')}:${timeIn.minute.toString().padLeft(2, '0')}:00';
        }
        if (timeOut != null) {
          endTime =
              '${timeOut.hour.toString().padLeft(2, '0')}:${timeOut.minute.toString().padLeft(2, '0')}:00';
        }
      } else if (subType == 'ob') {
        if (timeIn != null) {
          startTime =
              '${timeIn.hour.toString().padLeft(2, '0')}:${timeIn.minute.toString().padLeft(2, '0')}:00';
        }
        if (timeOut != null) {
          endTime =
              '${timeOut.hour.toString().padLeft(2, '0')}:${timeOut.minute.toString().padLeft(2, '0')}:00';
        }
      }

      if (formId != null) {
        // Update existing form
        await conn.query(
          '''
          UPDATE forms 
          SET sub_type = ?,
              start_time = ?,
              end_time = ?,
              start_date = ?,
              end_date = NULL,
              reason = ?,
              late_filing = ?,
              late_reason = ?,
              approver_level = 0
          WHERE form_id = ?
          ''',
          [
            subType,
            startTime,
            endTime,
            DateFormat('yyyy-MM-dd').format(selectedDate),
            reason,
            isLateFiling ? 'Y' : 'N',
            lateReason,
            formId,
          ],
        );
        return formId;
      } else {
        // Insert new form
        var result = await conn.query(
          '''
          INSERT INTO forms (
            emp_id, form_type, sub_type, start_time, end_time, 
            start_date, end_date, reason, created_on, f_status, status,
            late_filing, late_reason, approver_level
          ) VALUES (?, 'OBLU', ?, ?, ?, ?, NULL, ?, NOW(), 'Active', 'New', ?, ?, 0)
          ''',
          [
            empId,
            subType,
            startTime,
            endTime,
            DateFormat('yyyy-MM-dd').format(selectedDate),
            reason,
            isLateFiling ? 'Y' : 'N',
            lateReason,
          ],
        );
        return result.insertId;
      }
    } catch (e) {
      print('Save OBLU Form Error: $e');
      return null;
    } finally {
      await conn.close();
    }
  }

  Future<bool> finalizeObluForm(int formId) async {
    return await _finalizeFormHelper(formId);
  }

  Future<bool> voidObluForm(int formId) async {
    final conn = await _dbService.getConnection();
    try {
      var result = await conn.query(
        '''
        UPDATE forms 
        SET status = 'Void'
        WHERE form_id = ? AND form_type = 'OBLU'
        ''',
        [formId],
      );

      return result.affectedRows! > 0;
    } catch (e) {
      print('Void OBLU Form Error: $e');
      return false;
    } finally {
      await conn.close();
    }
  }

  Future<List<Map<String, dynamic>>> getObluForms(String empId) async {
    final conn = await _dbService.getConnection();
    try {
      var results = await conn.query(
        '''
        SELECT 
          form_id,
          emp_id,
          form_type,
          sub_type,
          start_time,
          end_time,
          start_date,
          end_date,
          reason,
          created_on,
          date_filed,
          f_status,
          status,
          late_filing,
          late_reason
        FROM forms 
        WHERE emp_id = ? 
          AND form_type = 'OBLU'
        ORDER BY created_on DESC
        ''',
        [empId],
      );

      return results.map((row) {
        return {
          'form_id': row['form_id'],
          'emp_id': row['emp_id'],
          'form_type': row['form_type'],
          'sub_type': row['sub_type'],
          'start_time': row['start_time']?.toString(),
          'end_time': row['end_time']?.toString(),
          'start_date': row['start_date']?.toString(),
          'end_date': row['end_date']?.toString(),
          'reason': row['reason'],
          'created_on': row['created_on']?.toString(),
          'date_filed': row['date_filed']?.toString(),
          'f_status': row['f_status'],
          'status': row['status'],
          'late_filing': row['late_filing'],
          'late_reason': row['late_reason'],
        };
      }).toList();
    } catch (e) {
      print('Get OBLU Forms Error: $e');
      return [];
    } finally {
      await conn.close();
    }
  }

  // DTR Forms Functions
  Future<List<Map<String, dynamic>>> getDtrForms(String empId) async {
    final conn = await _dbService.getConnection();
    try {
      var results = await conn.query(
        '''
        SELECT 
          form_id,
          emp_id,
          form_type,
          sub_type,
          start_time,
          end_time,
          start_date,
          end_date,
          reason,
          created_on,
          date_filed,
          f_status,
          status,
          late_filing,
          late_reason
        FROM forms 
        WHERE emp_id = ? 
          AND form_type = 'DTR'
        ORDER BY created_on DESC
        ''',
        [empId],
      );

      return results.map((row) {
        return {
          'form_id': row['form_id'],
          'emp_id': row['emp_id'],
          'form_type': row['form_type'],
          'sub_type': row['sub_type'],
          'start_time': row['start_time']?.toString(),
          'end_time': row['end_time']?.toString(),
          'start_date': row['start_date']?.toString(),
          'end_date': row['end_date']?.toString(),
          'reason': row['reason'],
          'created_on': row['created_on']?.toString(),
          'date_filed': row['date_filed']?.toString(),
          'f_status': row['f_status'],
          'status': row['status'],
          'late_filing': row['late_filing'],
          'late_reason': row['late_reason'],
        };
      }).toList();
    } catch (e) {
      print('Get DTR Forms Error: $e');
      return [];
    } finally {
      await conn.close();
    }
  }

  Future<int?> saveDtrForm({
    int? formId,
    required String empId,
    required String subType,
    required DateTime selectedDate,
    TimeOfDay? timeIn,
    TimeOfDay? timeOut,
    required String reason,
    String? lateReason,
  }) async {
    final conn = await _dbService.getConnection();
    try {
      String? startTime = timeIn != null
          ? '${timeIn.hour.toString().padLeft(2, '0')}:${timeIn.minute.toString().padLeft(2, '0')}:00'
          : null;
      String? endTime = timeOut != null
          ? '${timeOut.hour.toString().padLeft(2, '0')}:${timeOut.minute.toString().padLeft(2, '0')}:00'
          : null;
      bool isLateFiling = selectedDate.isBefore(DateTime.now());

      if (formId != null) {
        await conn.query(
          '''
          UPDATE forms 
          SET sub_type = ?,
              start_time = ?,
              end_time = ?,
              start_date = ?,
              end_date = NULL,
              reason = ?,
              late_filing = ?,
              late_reason = ?,
              approver_level = 0
          WHERE form_id = ? AND form_type = 'DTR'
          ''',
          [
            subType,
            startTime,
            endTime,
            DateFormat('yyyy-MM-dd').format(selectedDate),
            reason,
            isLateFiling ? 'Y' : 'N',
            lateReason,
            formId,
          ],
        );
        return formId;
      } else {
        var result = await conn.query(
          '''
          INSERT INTO forms (
            emp_id, form_type, sub_type, start_time, end_time, 
            start_date, end_date, reason, created_on, f_status, status,
            late_filing, late_reason, approver_level
          ) VALUES (?, 'DTR', ?, ?, ?, ?, NULL, ?, NOW(), 'Active', 'New', ?, ?, 0)
          ''',
          [
            empId,
            subType,
            startTime,
            endTime,
            DateFormat('yyyy-MM-dd').format(selectedDate),
            reason,
            isLateFiling ? 'Y' : 'N',
            lateReason,
          ],
        );
        return result.insertId;
      }
    } catch (e) {
      print('Save DTR Form Error: $e');
      return null;
    } finally {
      await conn.close();
    }
  }

  Future<bool> finalizeDtrForm(int formId) async {
    return await _finalizeFormHelper(formId);
  }

  Future<bool> voidDtrForm(int formId) async {
    final conn = await _dbService.getConnection();
    try {
      var result = await conn.query(
        '''
        UPDATE forms 
        SET status = 'Void'
        WHERE form_id = ? AND form_type = 'DTR'
        ''',
        [formId],
      );

      return result.affectedRows! > 0;
    } catch (e) {
      print('Void DTR Form Error: $e');
      return false;
    } finally {
      await conn.close();
    }
  }

  // General form methods that can be used across different form types
  Future<Map<String, dynamic>?> getFormById(int formId) async {
    final conn = await _dbService.getConnection();
    try {
      var results = await conn.query(
        '''
        SELECT 
          form_id,
          emp_id,
          form_type,
          sub_type,
          start_time,
          end_time,
          start_date,
          end_date,
          reason,
          created_on,
          date_filed,
          f_status,
          status,
          late_filing,
          late_reason
        FROM forms 
        WHERE form_id = ?
        ''',
        [formId],
      );

      if (results.isNotEmpty) {
        var row = results.first;
        return {
          'form_id': row['form_id'],
          'emp_id': row['emp_id'],
          'form_type': row['form_type'],
          'sub_type': row['sub_type'],
          'start_time': row['start_time']?.toString(),
          'end_time': row['end_time']?.toString(),
          'start_date': row['start_date']?.toString(),
          'end_date': row['end_date']?.toString(),
          'reason': row['reason'],
          'created_on': row['created_on']?.toString(),
          'date_filed': row['date_filed']?.toString(),
          'f_status': row['f_status'],
          'status': row['status'],
          'late_filing': row['late_filing'],
          'late_reason': row['late_reason'],
        };
      }
      return null;
    } catch (e) {
      print('Get Form By ID Error: $e');
      return null;
    } finally {
      await conn.close();
    }
  }

  Future<List<Map<String, dynamic>>> getLeaveTypes() async {
    final conn = await _dbService.getHrConnection();
    try {
      var results = await conn.query(
        '''
        SELECT 
          leave_id, 
          label, 
          label_short,
          x_perfect,
          withPay,
          sex,
          count,
          reset,
          civil_status,
          status
        FROM leave_types
        WHERE status = 'Active'
        ORDER BY label
        ''',
      );

      return results.map((row) {
        return {
          'leave_id': row['leave_id'],
          'label': row['label'],
          'label_short': row['label_short'],
          'x_perfect': row['x_perfect'],
          'withPay': row['withPay'],
          'sex': row['sex'],
          'count': row['count'],
          'reset': row['reset'],
          'civil_status': row['civil_status'],
          'status': row['status'],
        };
      }).toList();
    } catch (e) {
      print('Get Leave Types Error: $e');
      return [];
    } finally {
      await conn.close();
    }
  }

  Future<int?> saveLeaveForm({
    int? formId,
    required String empId,
    required int leaveId,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
    String? attachmentPath,
  }) async {
    final conn = await _dbService.getConnection();
    try {
      // Always use these time values
      const String startTime = '00:00:01';
      const String endTime = '23:59:59';

      if (formId != null) {
        // Update existing form
        await conn.query(
          '''
          UPDATE forms 
          SET sub_type_int = ?,
              start_time = ?,
              end_time = ?,
              start_date = ?,
              end_date = ?,
              reason = ?,
              late_filing = 'N',
              approver_level = 0
          WHERE form_id = ?
          ''',
          [
            leaveId,
            startTime,
            endTime,
            DateFormat('yyyy-MM-dd').format(startDate),
            DateFormat('yyyy-MM-dd').format(endDate),
            reason,
            formId,
          ],
        );
        return formId;
      } else {
        // Insert new form
        var result = await conn.query(
          '''
          INSERT INTO forms (
            emp_id, form_type, sub_type_int, start_time, end_time, 
            start_date, end_date, reason, created_on, f_status, status,
            late_filing, approver_level
          ) VALUES (?, 'LEAVE', ?, ?, ?, ?, ?, ?, NOW(), 'Active', 'New', 'N', 0)
          ''',
          [
            empId,
            leaveId,
            startTime,
            endTime,
            DateFormat('yyyy-MM-dd').format(startDate),
            DateFormat('yyyy-MM-dd').format(endDate),
            reason,
          ],
        );

        // If there's an attachment, store it in a separate table
        if (attachmentPath != null && result.insertId != null) {
          await conn.query(
            '''
            INSERT INTO form_attachments (
              form_id, file_path, uploaded_on
            ) VALUES (?, ?, NOW())
            ''',
            [result.insertId, attachmentPath],
          );
        }

        return result.insertId;
      }
    } catch (e) {
      print('Save Leave Form Error: $e');
      return null;
    } finally {
      await conn.close();
    }
  }

  Future<bool> finalizeLeaveForm(int formId) async {
    return await _finalizeFormHelper(formId);
  }

  Future<bool> voidLeaveForm(int formId) async {
    final conn = await _dbService.getConnection();
    try {
      var result = await conn.query(
        '''
        UPDATE forms 
        SET status = 'Void'
        WHERE form_id = ? AND form_type = 'LEAVE'
        ''',
        [formId],
      );

      return result.affectedRows! > 0;
    } catch (e) {
      print('Void Leave Form Error: $e');
      return false;
    } finally {
      await conn.close();
    }
  }

  Future<List<Map<String, dynamic>>> getLeaveForms(String empId) async {
    final conn = await _dbService.getConnection();
    try {
      var results = await conn.query(
        '''
        SELECT 
          f.form_id,
          f.emp_id,
          f.form_type,
          f.sub_type_int,
          f.start_time,
          f.end_time,
          f.start_date,
          f.end_date,
          f.reason,
          f.created_on,
          f.date_filed,
          f.f_status,
          f.status,
          f.late_filing,
          lt.label as leave_type_label
        FROM forms f
        LEFT JOIN hr.leave_types lt ON f.sub_type_int = lt.leave_id
        WHERE f.emp_id = ? 
          AND f.form_type = 'LEAVE'
        ORDER BY f.created_on DESC
        ''',
        [empId],
      );

      return results.map((row) {
        return {
          'form_id': row['form_id'],
          'emp_id': row['emp_id'],
          'form_type': row['form_type'],
          'sub_type_int': row['sub_type_int'],
          'leave_type_label': row['leave_type_label'],
          'start_time': row['start_time']?.toString(),
          'end_time': row['end_time']?.toString(),
          'start_date': row['start_date']?.toString(),
          'end_date': row['end_date']?.toString(),
          'reason': row['reason'],
          'created_on': row['created_on']?.toString(),
          'date_filed': row['date_filed']?.toString(),
          'f_status': row['f_status'],
          'status': row['status'],
          'late_filing': row['late_filing'],
        };
      }).toList();
    } catch (e) {
      print('Get Leave Forms Error: $e');
      return [];
    } finally {
      await conn.close();
    }
  }

  // Add this helper method to your FormsService class
  Future<bool> _finalizeFormHelper(int formId) async {
    final conn = await _dbService.getConnection();
    try {
      // Start transaction
      await conn.query('START TRANSACTION');

      // Update the form status to 'Finalized'
      await conn.query('''
        UPDATE employee.forms
        SET status = 'Finalized'
        WHERE form_id = ?
      ''', [formId]);

      // Update a_status to 1
      await conn.query('''
        UPDATE employee.forms
        SET a_status = 1
        WHERE form_id = ?
      ''', [formId]);

      // Commit transaction
      await conn.query('COMMIT');
      return true;
    } catch (e) {
      // Rollback on error
      await conn.query('ROLLBACK');
      print('Error finalizing form: $e');
      return false;
    } finally {
      await conn.close();
    }
  }
}
