import 'package:mysql1/mysql1.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  DatabaseService._init();

  Future<MySqlConnection> getConnection() async {
    final settings = ConnectionSettings(
        host: '10.0.5.100',
        port: 3306,
        user: 'gecko',
        password: 'tuko9',
        db: 'employee');

    return await MySqlConnection.connect(settings);
  }

  Future<MySqlConnection> getAttendanceConnection() async {
    final settings = ConnectionSettings(
      host: '10.0.5.101',
      port: 3306,
      user: 'gecko',
      password: 'tuko9',
      db: 'attendant', // Different database for attendance
    );

    return await MySqlConnection.connect(settings);
  }

  Future<MySqlConnection> getHrConnection() async {
    final settings = ConnectionSettings(
      host: '10.0.5.100',
      port: 3306,
      user: 'gecko',
      password: 'tuko9',
      db: 'hr', // HR database for leave types
    );

    return await MySqlConnection.connect(settings);
  }

  Future<MySqlConnection> getCalendarConnection() async {
    final settings = ConnectionSettings(
      host: '10.0.5.100',
      port: 3306,
      user: 'gecko',
      password: 'tuko9',
      db: 'calendar', // Calendar database for events
    );

    return await MySqlConnection.connect(settings);
  }

  Future<MySqlConnection> getAttendantConnection() async {
    final settings = ConnectionSettings(
      host: '10.0.5.100',
      port: 3306,
      user: 'gecko',
      password: 'tuko9',
      db: 'attendant', // Attendant database for login records
    );

    return await MySqlConnection.connect(settings);
  }

  Future<bool> testConnection() async {
    try {
      final conn = await getConnection();
      await conn.close();
      return true;
    } catch (e) {
      print('Connection Error: $e');
      return false;
    }
  }

  // Keep only non-form related database functions here
}
