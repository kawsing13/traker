import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controllers/employee_controller.dart';
import 'controllers/time_tracker_controller.dart';
import 'config/routes.dart';
import 'services/payroll_service.dart';
import 'services/credentials_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize CredentialsService
  await CredentialsService.instance.init();

  Get.put(TimeTrackerController(), permanent: true);
  Get.put(EmployeeController(), permanent: true);

  Get.put(PayrollService.instance, permanent: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gecko HR',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      initialRoute: AppRoutes.login,
      getPages: AppRoutes.pages,
    );
  }
}
