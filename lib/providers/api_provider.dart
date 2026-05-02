import 'dart:io';
import "dart:convert";
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:requests/requests.dart';
import 'package:hr_demo/vars.dart';
import 'package:path/path.dart' as p;

class hrApiProvider {
  static final hrApiProvider api = hrApiProvider._();

  hrApiProvider._();

  String? _event = "";

  Future<bool> login(String? userName, String? password) async {
    /* try local login */

    var url = "https://core10.myapps.ph/app/api.cf";

    var params = {
      "tpl": "login",
      "username": userName,
      "password": password,
    };

    Response response = await Dio().post(url,
        data: params,
        options: Options(contentType: Headers.formUrlEncodedContentType));

    print(response.statusCode);

    if (response.statusCode == 200) {
      String rawData = response.data.trim();

      final jsonMatch =
          RegExp(r'(\{.*\}|\[.*\])', dotAll: true).firstMatch(rawData);
      if (jsonMatch == null) return false;

      dynamic res = json.decode(jsonMatch.group(0)!);
      if (res is List && res.isNotEmpty) res = res[0];

      final SharedPreferences prefs = await SharedPreferences.getInstance();

      prefs.setInt('user_id', int.parse(res['user_id'] ?? "0"));
      userId = int.parse(res['user_id'] ?? "0");
      empId = int.parse(res['emp_id'] ?? "0");
      fullName = res['name'] ?? '';
      userName = userName ?? "";

      print('Login successful: $fullName');
      return true;
    }

    return false;
  }

  /// Upload employee face image file to server.
  /// Returns true on success.
  Future<bool> uploadEmployeeFace(int empId, String filePath) async {
    try {
      // Change this endpoint to your actual upload URL if different
      final url = "https://core10.myapps.ph/app/api.cf";

      final fileName = p.basename(filePath);

      final formData = FormData.fromMap({
        'emp_id': empId.toString(),
        'tpl': 'facial',
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });

      final response = await Dio().post(url,
          data: formData, options: Options(contentType: 'multipart/form-data'));

      if (response.statusCode == 200) {
        print('Upload response: ${response.data}');
        // You can add more robust success checking based on your API response
        return true;
      }
      return false;
    } catch (e) {
      print('Error uploading face: $e');
      return false;
    }
  }

  /// Log attendance via remote API. Sends emp_id, date (yyyy-MM-dd), time (HH:mm:ss), and state (1=IN,0=OUT).
  Future<bool> logAttendance(
      int empId, String date, String time, int state) async {
    try {
      final url = "https://core10.myapps.ph/app/api.cf";

      final params = {
        'tpl': 'logAttendance',
        'emp_id': empId.toString(),
        'date': date,
        'time': time,
        'state': state.toString(),
      };

      final response = await Dio().post(url,
          data: params,
          options: Options(contentType: Headers.formUrlEncodedContentType));

      if (response.statusCode == 200) {
        print('Attendance logged remotely: ${response.data}');
        return true;
      }
      print(
          'Attendance remote logging failed with status: ${response.statusCode}');
      return false;
    } catch (e) {
      print('Error logging attendance remotely: $e');
      return false;
    }
  }

  /// Log attendance with photo (multipart form). Uses field name `imagePath` for the file.
  Future<bool> logAttendanceWithImage(
      int empId, String date, String time, int state, String filePath) async {
    try {
      final url = "https://core10.myapps.ph/app/api.cf";

      final fileName = p.basename(filePath);

      final formData = FormData.fromMap({
        'tpl': 'logAttendance',
        'emp_id': empId.toString(),
        'date': date,
        'time': time,
        'state': state.toString(),
        // server expects the uploaded image under the 'imagePath' field
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });

      final response = await Dio().post(url,
          data: formData, options: Options(contentType: 'multipart/form-data'));

      if (response.statusCode == 200) {
        print('Attendance with image uploaded: ${response.data}');
        return true;
      }
      print('Attendance with image failed: ${response.statusCode}');
      return false;
    } catch (e) {
      print('Error logging attendance with image: $e');
      return false;
    }
  }

  /// Fetch DTR entries for a specific employee and date from remote API.
  /// Returns a Map with:
  /// - 'success': bool (true if request succeeded, false on network/server error)
  /// - 'data': List<Map> (DTR records if success, empty list otherwise)
  /// - 'isEmpty': bool (true if success but no records, false otherwise)
  Future<Map<String, dynamic>> fetchDTR(int empId, String date) async {
    try {
      final url = "https://core10.myapps.ph/app/api.cf";

      final response = await Dio().get(url, queryParameters: {
        'tpl': 'dtr',
        'emp_id': empId.toString(),
        'date': date,
      });

      if (response.statusCode == 200) {
        // Response may contain HTML/text wrapper - extract JSON-like substring
        final raw = response.data.toString();
        final jsonMatch =
            RegExp(r'(\{.*\}|\[.*\])', dotAll: true).firstMatch(raw);
        if (jsonMatch == null) {
          return {
            'success': true,
            'data': [],
            'isEmpty': true,
          };
        }
        final decoded = json.decode(jsonMatch.group(0)!);
        if (decoded is List) {
          final records = decoded.map<Map<String, dynamic>>((e) {
            return {
              'date': e['date']?.toString() ?? date,
              'time': e['time']?.toString() ?? '',
              'state': e['state']?.toString() ?? '',
            };
          }).toList();
          return {
            'success': true,
            'data': records,
            'isEmpty': records.isEmpty,
          };
        }
        return {
          'success': true,
          'data': [],
          'isEmpty': true,
        };
      }
      return {
        'success': false,
        'data': [],
        'isEmpty': false,
      };
    } catch (e) {
      print('Error fetching DTR: $e');
      return {
        'success': false,
        'data': [],
        'isEmpty': false,
      };
    }
  }

  /// Fetch employee profile from remote API.
  /// Returns a Map with profile data on success.
  Future<Map<String, dynamic>?> fetchProfile(int empId) async {
    try {
      final url = "https://core10.myapps.ph/app/api.cf";

      final response = await Dio().get(url, queryParameters: {
        'tpl': 'profile',
        'emp_id': empId.toString(),
      });

      if (response.statusCode == 200) {
        // Response may contain HTML/text wrapper - extract JSON-like substring
        final raw = response.data.toString();
        final jsonMatch =
            RegExp(r'(\{.*\}|\[.*\])', dotAll: true).firstMatch(raw);
        if (jsonMatch == null) return null;

        final decoded = json.decode(jsonMatch.group(0)!);

        // If it's a list, take the first element
        if (decoded is List && decoded.isNotEmpty) {
          return {
            'alias': decoded[0]['alias']?.toString() ?? '',
            'first_name': decoded[0]['first_name']?.toString() ?? '',
            'middle_name': decoded[0]['middle_name']?.toString() ?? '',
            'surname': decoded[0]['surname']?.toString() ?? '',
            'birth_date': decoded[0]['birth_date']?.toString() ?? '',
            'marital_status': decoded[0]['marital_status']?.toString() ?? '',
            'sex': decoded[0]['sex']?.toString() ?? '',
            'birth_place': decoded[0]['birth_place']?.toString() ?? '',
            'email': decoded[0]['email']?.toString() ?? '',
            'date_hired': decoded[0]['date_hired']?.toString() ?? '',
            'tin': decoded[0]['tin']?.toString() ?? '',
            'sss': decoded[0]['sss']?.toString() ?? '',
            'philhealth': decoded[0]['philhealth']?.toString() ?? '',
            'pagibig': decoded[0]['pagibig']?.toString() ?? '',
          };
        }

        // If it's a single object
        if (decoded is Map) {
          return {
            'alias': decoded['alias']?.toString() ?? '',
            'first_name': decoded['first_name']?.toString() ?? '',
            'middle_name': decoded['middle_name']?.toString() ?? '',
            'surname': decoded['surname']?.toString() ?? '',
            'birth_date': decoded['birth_date']?.toString() ?? '',
            'marital_status': decoded['marital_status']?.toString() ?? '',
            'sex': decoded['sex']?.toString() ?? '',
            'birth_place': decoded['birth_place']?.toString() ?? '',
            'email': decoded['email']?.toString() ?? '',
            'date_hired': decoded['date_hired']?.toString() ?? '',
            'tin': decoded['tin']?.toString() ?? '',
            'sss': decoded['sss']?.toString() ?? '',
            'philhealth': decoded['philhealth']?.toString() ?? '',
            'pagibig': decoded['pagibig']?.toString() ?? '',
          };
        }
      }
      return null;
    } catch (e) {
      print('Error fetching profile: $e');
      return null;
    }
  }
}
