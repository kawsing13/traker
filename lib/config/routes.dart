import 'package:get/get.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home/time_tracker_screen.dart';
import '../screens/home/menu_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/utilities/memo_screen.dart';
import '../screens/utilities/dtr_screen.dart';
import '../screens/forms/oblu/oblu_list_screen.dart';
import '../screens/forms/oblu/oblu_form_screen.dart';
import '../screens/forms/dtr/dtr_form_list_screen.dart';
import '../screens/forms/dtr/dtr_form_screen.dart';
import '../screens/forms/leave/leave_form_list_screen.dart';
import '../screens/forms/leave/leave_form_screen.dart';
import '../screens/payslip/payslip_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String timeTracker = '/time_tracker';
  static const String menu = '/menu';
  static const String profile = '/profile';
  static const String memo = '/memo';
  static const String dtr = '/dtr';
  static const String oblu = '/oblu';
  static const String obluNew = '/oblu/new';
  static const String obluEdit = '/oblu/edit';
  static const String dtrForm = '/dtr-form';
  static const String dtrFormNew = '/dtr-form/new';
  static const String leaveForm = '/leave-form';
  static const String leaveFormNew = '/leave-form/new';
  static const String payslip = '/payslip';

  static final List<GetPage> pages = [
    GetPage(
      name: login,
      page: () => const LoginScreen(),
    ),
    GetPage(
      name: timeTracker,
      page: () => const TimeTrackerScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: menu,
      page: () => const MenuScreen(),
      transition: Transition.leftToRight,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: profile,
      page: () => ProfileScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: memo,
      page: () => const MemoScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: dtr,
      page: () => const DTRScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: oblu,
      page: () => const ObluListScreen(),
    ),
    GetPage(
      name: obluNew,
      page: () => const ObluFormScreen(),
    ),
    GetPage(
      name: obluEdit,
      page: () => const ObluFormScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: dtrForm,
      page: () => const DtrFormListScreen(),
    ),
    GetPage(
      name: dtrFormNew,
      page: () => const DtrFormScreen(),
    ),
    GetPage(name: leaveForm, page: () => const LeaveFormListScreen()),
    GetPage(name: leaveFormNew, page: () => const LeaveFormScreen()),
    GetPage(
      name: payslip,
      page: () => const PayslipScreen(),
      transition: Transition.rightToLeft,
    ),
  ];
}
