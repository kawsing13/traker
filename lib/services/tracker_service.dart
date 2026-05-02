import 'package:intl/intl.dart';
import 'database_service.dart';
import 'package:hr_demo/providers/api_provider.dart';
import 'face_recognition_service.dart';
import 'dart:io';

class TrackerService {
  static final TrackerService instance = TrackerService._init();
  final DatabaseService _databaseService = DatabaseService.instance;

  TrackerService._init();

  /// Log attendance. The method now auto-toggles state based on the latest
  /// record for the employee for the given date. If no previous record exists
  /// for today, the new state defaults to IN (1). Otherwise the state toggles
  /// (1 -> 0, 0 -> 1).
  Future<bool> logAttendance(String empId, DateTime timestamp, bool isClockIn,
      {int logNumber = 1, String? attendanceImagePath}) async {
    if (empId.isEmpty) {
      print('Error: Empty employee ID provided');
      return false;
    }
    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(timestamp);
      final formattedTime = DateFormat('HH:mm:ss').format(timestamp);

      // Determine new state by checking the most recent record for today via API
      int newState = 1; // default to IN
      try {
        final fetchRes = await hrApiProvider.api.fetchDTR(
            int.tryParse(empId) ?? 0, formattedDate);
        if (fetchRes['success'] == true &&
            fetchRes['data'] is List &&
            (fetchRes['data'] as List).isNotEmpty) {
          final data = fetchRes['data'] as List;
          data.sort((a, b) => a['time'].toString().compareTo(b['time'].toString()));
          final last = data.last;
          final lastState = int.tryParse(last['state'].toString()) ?? 0;
          newState = (lastState == 1) ? 0 : 1;
        }
      } catch (e) {
        print('Error determining last state from API, defaulting to IN: $e');
        newState = 1;
      }

      // Attempt to log attendance to remote API
      try {
        // Use provided attendanceImagePath if available; otherwise capture a new one
        bool remoteResult = false;
        if (attendanceImagePath != null) {
          try {
            remoteResult = await hrApiProvider.api.logAttendanceWithImage(
              int.tryParse(empId) ?? 0,
              formattedDate,
              formattedTime,
              newState,
              attendanceImagePath,
            );
            // delete temp image if present
            try {
              final f = File(attendanceImagePath);
              if (await f.exists()) await f.delete();
            } catch (_) {}
          } catch (e) {
            print('Error uploading provided attendance image: $e');
            remoteResult = false;
          }
        } else {
          // Capture attendance image and send with API if possible
          final faceService = FaceRecognitionService();
          String? imagePath;
          try {
            imagePath = await faceService.captureAttendanceImage();
          } catch (e) {
            print('Attendance capture error: $e');
            imagePath = null;
          }

          if (imagePath != null) {
            remoteResult = await hrApiProvider.api.logAttendanceWithImage(
              int.tryParse(empId) ?? 0,
              formattedDate,
              formattedTime,
              newState,
              imagePath,
            );
            // delete temp image if present
            try {
              final f = File(imagePath);
              if (await f.exists()) await f.delete();
            } catch (_) {}
          } else {
            remoteResult = await hrApiProvider.api.logAttendance(
              int.tryParse(empId) ?? 0,
              formattedDate,
              formattedTime,
              newState,
            );
          }
        }

        if (!remoteResult) {
          print('Warning: remote attendance logging failed for emp $empId');
        }
      } catch (e) {
        print('Remote logging error: $e');
      }

      return true;
    } catch (e) {
      print('Error logging attendance: $e');
      return false;
    }
  }

  Future<Map<String, String>?> getLatestAttendance(String empId) async {
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final res = await hrApiProvider.api.fetchDTR(
          int.tryParse(empId) ?? 0, today);
      if (res['success'] == true && res['data'] is List &&
          (res['data'] as List).isNotEmpty) {
        final data = res['data'] as List;
        data.sort((a, b) => a['time'].toString().compareTo(b['time'].toString()));
        final last = data.last;
        return {
          'time': last['time'].toString(),
          'date': last['date'].toString(),
          'state': last['state'].toString(),
        };
      }
      return null;
    } catch (e) {
      print('Get Latest Attendance Error (API): $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getTodayAttendance(String empId) async {
    if (empId.isEmpty) {
      print('Error: Empty employee ID provided');
      return null;
    }

    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final res = await hrApiProvider.api.fetchDTR(
          int.tryParse(empId) ?? 0, today);

      List<Map<String, dynamic>> results = [];
      if (res['success'] == true && res['data'] is List) {
        for (var r in res['data'] as List) {
          results.add({'time': r['time'].toString(), 'state': r['state'].toString()});
        }
        results.sort((a, b) => a['time'].toString().compareTo(b['time'].toString()));
      }

      // Initialize variables
      String? clockInTime1;
      String? clockOutTime1;
      String? clockInTime2;
      String? clockOutTime2;

      // Track which record we're processing
      int currentPair = 1;
      bool waitingForClockOut = false;


      if (results.isNotEmpty) {
        for (var row in results) {
          final state = row['state'].toString();
          final time = row['time'].toString();

          if (currentPair == 1) {
            if (state == '1' && clockInTime1 == null) {
              clockInTime1 = time;
              waitingForClockOut = true;
            } else if (state == '0' && waitingForClockOut) {
              clockOutTime1 = time;
              waitingForClockOut = false;
              currentPair = 2;
            }
          } else if (currentPair == 2) {
            if (state == '1' && clockInTime2 == null) {
              clockInTime2 = time;
              waitingForClockOut = true;
            } else if (state == '0' && waitingForClockOut) {
              clockOutTime2 = time;
              waitingForClockOut = false;
            }
          }
        }

        bool canClockInOut = true;
        if (clockOutTime2 != null) canClockInOut = false;

        return {
          'clockInTime1': clockInTime1,
          'clockOutTime1': clockOutTime1,
          'clockInTime2': clockInTime2,
          'clockOutTime2': clockOutTime2,
          'canClockInOut': canClockInOut,
        };
      }

      // No records found - user can clock in
      return {
        'canClockInOut': true,
        'clockInTime1': null,
        'clockOutTime1': null,
        'clockInTime2': null,
        'clockOutTime2': null,
      };
    } catch (e) {
      print('Get Today Attendance Error (API): $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getDTRRecords(
      String empId, DateTime month) async {
    try {
      final startDate = DateTime(month.year, month.month, 1);
      final endDate = DateTime(month.year, month.month + 1, 0);

      List<Map<String, dynamic>> dtrRecords = [];

      for (var day = startDate;
          !day.isAfter(endDate);
          day = day.add(Duration(days: 1))) {
        final dateStr = DateFormat('yyyy-MM-dd').format(day);
        try {
          final res = await hrApiProvider.api.fetchDTR(
              int.tryParse(empId) ?? 0, dateStr);
          List<Map<String, dynamic>> logs = [];
          if (res['success'] == true && res['data'] is List) {
            for (var r in res['data'] as List) {
              logs.add({'time': r['time'].toString(), 'state': r['state']});
            }
            logs.sort((a, b) => a['time'].toString().compareTo(b['time'].toString()));
          }

          List<String?> inOutPairs = [];
          String? lastIn;
          for (var log in logs) {
            final state = log['state'].toString();
            final time = log['time'].toString();
            if (state == '1') {
              lastIn = time;
            } else if (state == '0' && lastIn != null) {
              inOutPairs.add(lastIn);
              inOutPairs.add(time);
              lastIn = null;
            }
          }
          if (lastIn != null) {
            inOutPairs.add(lastIn);
            inOutPairs.add(null);
          }

          dtrRecords.add({'date': dateStr, 'pairs': inOutPairs});
        } catch (e) {
          dtrRecords.add({'date': dateStr, 'pairs': []});
        }
      }

      return dtrRecords;
    } catch (e) {
      print('Get DTR Records Error (API): $e');
      return [];
    }
  }
}
