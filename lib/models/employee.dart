import 'package:intl/intl.dart';

class Employee {
  final String empId;
  final String alias;
  final String firstName;
  final String middleName;
  final String surname;
  final String birthDate;
  final String maritalStatus;
  final String sex;
  final String birthPlace;
  final String email;
  final String tin;
  final String sss;
  final String phic;
  final String hdmf;
  final String dateHired;

  Employee({
    required this.empId,
    required this.alias,
    required this.firstName,
    required this.middleName,
    required this.surname,
    this.birthDate = '',
    this.maritalStatus = '',
    this.sex = '',
    this.birthPlace = '',
    this.email = '',
    this.tin = '',
    this.sss = '',
    this.phic = '',
    this.hdmf = '',
    this.dateHired = '',
  });

  factory Employee.fromMap(Map<String, dynamic> map) {
    String formatDate(dynamic date) {
      if (date == null) return '';
      try {
        final DateTime dateTime =
            date is DateTime ? date : DateTime.parse(date.toString());
        return DateFormat('yyyy-MM-dd').format(dateTime);
      } catch (e) {
        return '';
      }
    }

    return Employee(
      empId: map['emp_id']?.toString() ?? '',
      alias: map['alias']?.toString() ?? '',
      firstName: map['first_name']?.toString() ?? '',
      middleName: map['middle_name']?.toString() ?? '',
      surname: map['surname']?.toString() ?? '',
      birthDate: formatDate(map['birth_date']),
      maritalStatus: map['civil_status']?.toString() ?? '', // <-- FIXED
      sex: map['sex']?.toString() ?? '',
      birthPlace: map['birth_place']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      tin: map['tin']?.toString() ?? '',
      sss: map['sss']?.toString() ?? '',
      phic: map['phic']?.toString() ?? '',
      hdmf: map['hdmf']?.toString() ?? '',
      dateHired: formatDate(map['date_hired']),
    );
  }
}
