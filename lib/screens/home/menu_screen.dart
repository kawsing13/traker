import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:get/get.dart';
import '../../controllers/time_tracker_controller.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../config/constants.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String currentTime = AppConstants.defaultTimeFormat;
  String currentDate = "";
  Timer? _timer;
  final timeController = Get.find<TimeTrackerController>();
  bool _isFormsExpanded = false;

  @override
  void initState() {
    super.initState();
    _updateDateTime();
    _timer = Timer.periodic(AppConstants.clockRefreshRate, (timer) {
      _updateDateTime();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateDateTime() {
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute;
    final second = now.second;
    final amPm = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    setState(() {
      currentTime =
          "${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:${second.toString().padLeft(2, '0')} $amPm";
      currentDate = DateFormat(AppConstants.dateFormatFull).format(now);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: Column(
          children: [
            Text(currentDate, style: AppTheme.clockDateStyle),
            Text(currentTime, style: AppTheme.clockTimeStyle),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),

          // Menu items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildMenuItem(
                  context,
                  Icons.person,
                  "Profile",
                  () => Get.toNamed(AppRoutes.profile),
                ),
                /*Column(
                  children: [
                    _buildMenuItem(
                      context,
                      Icons.description,
                      "Forms",
                      () {
                        setState(() {
                          _isFormsExpanded = !_isFormsExpanded;
                        });
                      },
                    ),
                    if (_isFormsExpanded)
                      Column(
                        children: [
                          _buildSubMenuItem(
                              context, "OBLU Form", AppRoutes.oblu),
                          _buildSubMenuItem(
                              context, "DTR Form", AppRoutes.dtrForm),
                          _buildSubMenuItem(
                              context, "Leave Form", AppRoutes.leaveForm),
                        ],
                      ),
                  ],
                ), */
                /*_buildMenuItem(
                  context,
                  Icons.payment,
                  "Payslip",
                  () => Get.toNamed(AppRoutes.payslip),
                ),*/

                _buildMenuItem(context, Icons.assessment, "DTR",
                    () => Get.toNamed(AppRoutes.dtr)),
                /*
                _buildMenuItem(context, Icons.note, "Memo",
                    () => Get.toNamed(AppRoutes.memo)),
                */
                _buildMenuItem(
                  context,
                  Icons.logout,
                  "Logout",
                  () => _showLogoutDialog(context),
                ),
              ],
            ),
          ),

          // Time indicators
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Obx(() => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTimeIndicator(
                        timeController.clockInTime.value, Icons.login),
                    _buildTimeIndicator(
                        timeController.clockOutTime.value, Icons.logout),
                  ],
                )),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String title, [
    VoidCallback? onTap,
    Widget? trailing,
  ]) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: Colors.grey[600]),
        title: Text(title, style: AppTheme.subtitleStyle),
        trailing:
            trailing ?? Icon(Icons.chevron_right, color: Colors.grey[400]),
        onTap: onTap ??
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$title feature coming soon!'),
                  duration: AppConstants.snackBarDuration,
                ),
              );
            },
      ),
    );
  }

  Widget _buildSubMenuItem(
      BuildContext context, String title, String? routeName) {
    return Card(
      margin: const EdgeInsets.only(left: 48, right: 4, top: 2, bottom: 2),
      child: ListTile(
        dense: true,
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[800],
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
        onTap: () {
          if (routeName != null) {
            Get.toNamed(routeName);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$title feature coming soon!'),
                duration: AppConstants.snackBarDuration,
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildTimeIndicator(String time, IconData icon) {
    return Column(
      children: [
        Container(
          padding:
              const EdgeInsets.all(AppConstants.timeIndicatorPadding / 1.5),
          decoration: AppTheme.timeIndicatorDecoration,
          child: Icon(icon,
              size: AppConstants.timeIndicatorIconSize * 0.8,
              color: Colors.grey[600]),
        ),
        const SizedBox(height: AppConstants.verticalSpacingSmall / 2),
        Text(
          time,
          style: TextStyle(
            fontSize: AppConstants.timeIndicatorFontSize - 1,
            color: Colors.grey[600],
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              style: AppTheme.outlinedButtonStyle(AppTheme.dangerColor),
              onPressed: () {
                Get.back(); // Close dialog
                Get.offAllNamed(AppRoutes.login); // Navigate to login
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}
