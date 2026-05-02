import 'package:get/get.dart';
import '../config/constants.dart';

class TimeTrackerController extends GetxController {
  var clockInTime = AppConstants.defaultTimeFormat.obs;
  var clockOutTime = AppConstants.defaultTimeFormat.obs;

  var clockInTime2 = AppConstants.defaultTimeFormat.obs;
  var clockOutTime2 = AppConstants.defaultTimeFormat.obs;

  void updateClockInTime(String time) {
    clockInTime.value = time;
  }

  void updateClockOutTime(String time) {
    clockOutTime.value = time;
  }

  // Add these methods
  void updateClockInTime2(String time) {
    clockInTime2.value = time;
  }

  void updateClockOutTime2(String time) {
    clockOutTime2.value = time;
  }
}
