import 'package:flutter/material.dart';
import '../../services/face_recognition_service.dart';
import 'package:camera/camera.dart';
import '../../vars.dart' as vars;
import '../../providers/api_provider.dart';
import 'package:intl/intl.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:get/get.dart';

import '../../controllers/time_tracker_controller.dart';
import '../../services/tracker_service.dart';
import '../../controllers/employee_controller.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../config/constants.dart';
// removed duplicate vars import (use local '../../vars.dart' as vars)

class TimeTrackerScreen extends StatefulWidget {
  const TimeTrackerScreen({super.key});

  @override
  State<TimeTrackerScreen> createState() => _TimeTrackerScreenState();
}

class _TimeTrackerScreenState extends State<TimeTrackerScreen> {
  // Ensure controllers exist; fall back to creating them if not registered yet.
  final timeController = Get.isRegistered<TimeTrackerController>()
      ? Get.find<TimeTrackerController>()
      : Get.put(TimeTrackerController());
  final FaceRecognitionService _faceService = FaceRecognitionService();
  bool _faceEnrolled = false;
  final TrackerService _trackerService = TrackerService.instance;
  final employeeController = Get.isRegistered<EmployeeController>()
      ? Get.find<EmployeeController>()
      : Get.put(EmployeeController());

  // camera-based, so no local_auth fields

  bool isClockIn = true;
  String currentTime = AppConstants.defaultTimeFormat;
  String currentDate = "";
  Timer? _timer;
  bool _canClockInOut = true;
  // allow either 1 or 2 log pairs
  int _maxLogs = 1; // 1 = single in/out, 2 = two in/out pairs

  // Variables for two-pair logic
  int _currentLogNumber = 1; // Track current log when using 2 pairs
  bool _firstPairComplete = false; // Track if first in/out pair is complete

  // 5. Add a Worker field to track the debounce subscription
  Worker? _worker;

  @override
  void initState() {
    super.initState();
    // Load any enrolled face for current employee
    _faceService.loadEnrolledFace(vars.empId).then((_) {
      if (mounted) {
        setState(() {
          _faceEnrolled = _faceService.isFaceEnrolled();
        });
      }
    });
    _updateTime();
    _updateDate();
    _timer = Timer.periodic(AppConstants.clockRefreshRate, (timer) {
      if (mounted) {
        _updateTime();
        _updateDate();
      }
    });

    // Check initial state
    _checkInitialClockState();

    // Store the worker reference so we can dispose it later
    _worker = debounce(
      employeeController.currentEmployeeId,
      (_) {
        if (mounted) {
          print(
              'Employee changed to: ${employeeController.currentEmployeeId.value}');
          _resetClockValues();
          _checkInitialClockState();
        }
      },
      time: const Duration(milliseconds: 300),
    );
  }

  // Helper to decode image bytes into ui.Image for accurate overlay scaling
  Future<ui.Image> _loadUiImage(Uint8List bytes) async {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, (ui.Image img) {
      completer.complete(img);
    });
    return completer.future;
  }

  // Validate prerequisites and start the camera authentication flow
  Future<void> _startAuthentication() async {
    if (!_canClockInOut) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppConstants.attendanceCompletedMessage),
          duration: AppConstants.snackBarDuration,
        ),
      );
      return;
    }

    if (!_faceEnrolled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Face not enrolled. Please enroll first.')),
      );
      return;
    }

    await _authenticateWithFace();
  }

  Future<void> _authenticateWithFace() async {
    try {
      final initialized = await _faceService.initializeCamera();
      if (!initialized) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to initialize camera.')),
        );
        return;
      }

      // Add a small delay to ensure camera is fully ready
      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;

      // Show dialog with live preview and wait for result
      final result = await showDialog<String?>(
        context: context,
        barrierDismissible: false,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Face Authentication'),
              content: SizedBox(
                width: 300,
                height: 400,
                child: Column(
                  children: [
                    Expanded(
                      child: _faceService.cameraController != null &&
                              _faceService.isCameraInitialized
                          ? CameraPreview(_faceService.cameraController!)
                          : const Center(child: CircularProgressIndicator()),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Position your face in the camera.\\nStay still for capture.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context, null);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final controller = _faceService.cameraController;
                      if (controller == null) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Camera not initialized')),
                          );
                        }
                        return;
                      }

                      final XFile file = await controller.takePicture();

                      // Run face detection on captured image
                      final faces =
                          await _faceService.detectFacesInImagePath(file.path);
                      if (faces.isEmpty) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'No face detected. Please position your face and try again.')),
                          );
                        }
                        return;
                      }

                      // Optional: show confirmation with bounding box before authenticating
                      final bytes = await File(file.path).readAsBytes();
                      final uiImg = await _loadUiImage(bytes);

                      final confirmed = await showDialog<bool?>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Confirm Capture'),
                          content: SizedBox(
                            width: 300,
                            height: 400,
                            child: Column(
                              children: [
                                Expanded(
                                  child: Stack(
                                    children: [
                                      Image.file(File(file.path),
                                          fit: BoxFit.contain,
                                          width: double.infinity),
                                      // overlay using detected face bounds
                                      if (faces.isNotEmpty)
                                        Positioned.fill(
                                          child: CustomPaint(
                                            painter:
                                                _FaceRectPainter(faces, uiImg),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text('Is this clear?'),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Retake')),
                            ElevatedButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Use')),
                          ],
                        ),
                      );

                      if (confirmed != true) return;

                      // Compare with enrolled face
                      final enrolledPath = _faceService.getEnrolledFacePath();
                      if (enrolledPath == null) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('No enrolled face found.')),
                          );
                        }
                        return;
                      }

                      final similarity = await _faceService.compareFaces(
                          enrolledPath, file.path);

                      // Follow threshold logic (raised to reduce false positives)
                      const matchThreshold = 0.65;
                      if (similarity >= matchThreshold) {
                        // Match confirmed - automatically use the captured image for upload
                        Navigator.pop(context, file.path);
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Face does not match.')),
                          );
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Authenticate'),
                ),
              ],
            );
          },
        ),
      );

      // Dispose camera after dialog closes
      await _faceService.dispose();

      if (!mounted) return;

      if (result != null) {
        // result is either: file path (upload), empty string (skip upload), or null (no match)
        final passImagePath = result.isNotEmpty ? result : null;
        await _handleClockInOut(passImagePath);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Face does not match. Try again.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _openEnrollmentDialog() async {
    try {
      final initialized = await _faceService.initializeCamera();
      if (!initialized) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to initialize camera.')),
        );
        return;
      }

      final result = await showDialog<bool?>(
        context: context,
        barrierDismissible: false,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Enroll Face'),
              content: SizedBox(
                width: 300,
                height: 400,
                child: Column(
                  children: [
                    Expanded(
                      child: _faceService.cameraController != null &&
                              _faceService.isCameraInitialized
                          ? CameraPreview(_faceService.cameraController!)
                          : const Center(child: CircularProgressIndicator()),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Position your face in the camera.\n Stay still for capture.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context, false);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final controller = _faceService.cameraController;
                      if (controller == null) {
                        if (mounted) {
                          Navigator.pop(context, false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Camera not initialized')),
                          );
                        }
                        return;
                      }

                      final XFile file = await controller.takePicture();

                      final saved = await _faceService
                          .saveEnrolledFaceFromXFile(file, vars.empId);

                      // Dispose camera after capture
                      await _faceService.dispose();

                      Navigator.pop(context, saved);
                    } catch (e) {
                      await _faceService.dispose();
                      if (mounted) {
                        Navigator.pop(context, false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Capture'),
                ),
              ],
            );
          },
        ),
      );

      if (!mounted) return;

      if (result == true) {
        setState(() {
          _faceEnrolled = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Face enrolled successfully!')),
        );

        // upload to server if empId available
        if (vars.empId != 0) {
          final path = _faceService.getEnrolledFacePath();
          if (path != null) {
            try {
              final uploaded =
                  await hrApiProvider.api.uploadEmployeeFace(vars.empId, path);
              if (uploaded) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Face uploaded to server')),
                  );
                }
              }
            } catch (e) {
              print('Upload error: $e');
            }
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // 1. Update the _checkInitialClockState method to check if the widget is mounted
  Future<void> _checkInitialClockState() async {
    // Only proceed if the widget is still mounted
    if (!mounted) return;

    final employeeData = employeeController.getEmployeeData();

    // Reset all clock values first to avoid showing previous user's data
    _resetClockValues();

    if (employeeData != null) {
      final empIdValue =
          employeeData['emp_id']?.toString() ?? vars.empId.toString();
      final todayAttendance =
          await _trackerService.getTodayAttendance(empIdValue);

      // Check again if still mounted after the async operation
      if (!mounted) return;

      if (todayAttendance != null) {
        setState(() {
          _canClockInOut = todayAttendance['canClockInOut'] ?? true;

          // Handle clock in/out times (null-safe parsing)
          final dynamic in1 = todayAttendance['clockInTime1'];
          if (in1 is String && in1.isNotEmpty) {
            try {
              final clockInDateTime =
                  DateFormat(AppConstants.timeFormat24h).parse(in1);
              final formattedClockIn = DateFormat(AppConstants.timeFormat12h)
                  .format(clockInDateTime);
              timeController.updateClockInTime(formattedClockIn);

              // If we have a clock in but no clock out, set for clock out
              if (todayAttendance['clockOutTime1'] == null) {
                isClockIn = false;
                // if using two logs, ensure current log points to 1
                if (_maxLogs == 2) _currentLogNumber = 1;
              }
            } catch (e) {
              print('Error parsing clockInTime1: $e');
            }
          }

          final dynamic out1 = todayAttendance['clockOutTime1'];
          if (out1 is String && out1.isNotEmpty) {
            try {
              final clockOutDateTime =
                  DateFormat(AppConstants.timeFormat24h).parse(out1);
              final formattedClockOut = DateFormat(AppConstants.timeFormat12h)
                  .format(clockOutDateTime);
              timeController.updateClockOutTime(formattedClockOut);

              // If only single pair expected, mark completed
              if (_maxLogs == 1) {
                _canClockInOut = false;
              } else {
                // two-pair mode: mark first pair complete and prepare for second
                _firstPairComplete = true;
                if (todayAttendance['clockInTime2'] == null) {
                  isClockIn = true;
                  _currentLogNumber = 2;
                }
              }
            } catch (e) {
              print('Error parsing clockOutTime1: $e');
            }
          }

          // If two log pairs are enabled, handle second pair
          if (_maxLogs == 2) {
            final dynamic in2 = todayAttendance['clockInTime2'];
            if (in2 is String && in2.isNotEmpty) {
              try {
                final clockInDateTime =
                    DateFormat(AppConstants.timeFormat24h).parse(in2);
                final formattedClockIn = DateFormat(AppConstants.timeFormat12h)
                    .format(clockInDateTime);
                timeController.updateClockInTime2(formattedClockIn);
                _currentLogNumber = 2;

                final dynamic out2check = todayAttendance['clockOutTime2'];
                if (out2check == null) {
                  isClockIn = false;
                }
              } catch (e) {
                print('Error parsing clockInTime2: $e');
              }
            }

            final dynamic out2 = todayAttendance['clockOutTime2'];
            if (out2 is String && out2.isNotEmpty) {
              try {
                final clockOutDateTime =
                    DateFormat(AppConstants.timeFormat24h).parse(out2);
                final formattedClockOut = DateFormat(AppConstants.timeFormat12h)
                    .format(clockOutDateTime);
                timeController.updateClockOutTime2(formattedClockOut);
                // All done for the day
                _canClockInOut = false;
              } catch (e) {
                print('Error parsing clockOutTime2: $e');
              }
            }
          }
        });
      }
    }
  }

  // _startAuthentication replaced with camera-based implementation above

  // 7. Update _updateTime and _updateDate to check mounted state
  void _updateTime() {
    if (!mounted) return;

    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute;
    final second = now.second;
    final amPm = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    setState(() {
      currentTime =
          "${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:${second.toString().padLeft(2, '0')} $amPm";
    });
  }

  void _updateDate() {
    if (!mounted) return;

    final now = DateTime.now();
    setState(() {
      currentDate = DateFormat(AppConstants.dateFormatFull).format(now);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _worker?.dispose(); // Dispose the worker when widget is disposed
    super.dispose();
  }

  Future<void> _handleClockInOut([String? capturedImagePath]) async {
    /*final employeeData = employeeController.getEmployeeData();
    if (employeeData == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppConstants.noEmployeeDataMessage)),
        );
      }
      return;
    }*/

    print('Handling clock ${isClockIn ? 'in' : 'out'}');

    final now = DateTime.now();
    final formattedTime = DateFormat(AppConstants.timeFormat12h).format(now);

    // Store the current state before changing it
    final wasClockingIn = isClockIn;

    // Determine log number to use based on mode
    final logNumberToUse = (_maxLogs == 2) ? _currentLogNumber : 1;

    final success = await _trackerService.logAttendance(
      vars.empId.toString(),
      now,
      isClockIn,
      logNumber: logNumberToUse,
      attendanceImagePath: capturedImagePath,
    );

    // Check if still mounted after the async operation
    if (!mounted) return;

    if (success) {
      setState(() {
        if (_maxLogs == 1) {
          if (isClockIn) {
            isClockIn = false;
            timeController.updateClockInTime(formattedTime);
          } else {
            timeController.updateClockOutTime(formattedTime);
            _canClockInOut = false;
          }
        } else {
          // two-pair mode
          if (isClockIn) {
            // clocking in for current log
            if (_currentLogNumber == 1) {
              timeController.updateClockInTime(formattedTime);
              // now wait for clock out #1
              isClockIn = false;
            } else {
              timeController.updateClockInTime2(formattedTime);
              isClockIn = false;
            }
          } else {
            // clocking out
            if (_currentLogNumber == 1) {
              timeController.updateClockOutTime(formattedTime);
              _firstPairComplete = true;
              // move to second pair
              _currentLogNumber = 2;
              isClockIn = true;
            } else {
              timeController.updateClockOutTime2(formattedTime);
              _canClockInOut = false;
            }
          }
        }
      });

      // Show success message - use the stored state values from before the change
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(wasClockingIn
              ? "Clocked in successfully"
              : "Clocked out successfully"),
          backgroundColor:
              wasClockingIn ? AppTheme.successColor : AppTheme.dangerColor,
          duration: AppConstants.snackBarDuration,
        ),
      );
    } else {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppConstants.failedAttendanceMessage),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  // 2. Update the _resetClockValues method to check if mounted
  void _resetClockValues() {
    // Reset controller values
    timeController.updateClockInTime(AppConstants.defaultTimeFormat);
    timeController.updateClockOutTime(AppConstants.defaultTimeFormat);
    timeController.updateClockInTime2(AppConstants.defaultTimeFormat);
    timeController.updateClockOutTime2(AppConstants.defaultTimeFormat);

    // Only call setState if the widget is still mounted
    if (mounted) {
      setState(() {
        isClockIn = true;
        _canClockInOut = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () => Get.toNamed(AppRoutes.menu),
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
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _canClockInOut ? _startAuthentication : null,
                      child: Container(
                        width: AppConstants.clockButtonSize,
                        height: AppConstants.clockButtonSize,
                        decoration:
                            AppTheme.clockButtonDecoration(_canClockInOut),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _canClockInOut
                                    ? (isClockIn ? Icons.login : Icons.logout)
                                    : Icons.check_circle_outline,
                                size: AppConstants.clockIconSize,
                                color: _canClockInOut
                                    ? (isClockIn
                                        ? AppTheme.successColor
                                        : AppTheme.dangerColor)
                                    : Colors.grey[400],
                              ),
                              const SizedBox(
                                  height: AppConstants.verticalSpacingSmall),
                              Text(
                                _canClockInOut
                                    ? (isClockIn ? "Clock In" : "Clock Out")
                                    : "Completed",
                                style: AppTheme.clockStatusStyle.copyWith(
                                  fontSize: AppConstants.clockStatusFontSize,
                                  color: _canClockInOut
                                      ? (isClockIn
                                          ? AppTheme.successColor
                                          : AppTheme.dangerColor)
                                      : Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppConstants.verticalSpacingLarge),
                    // Mode selector (1 or 2 log pairs)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text(
                            'One Check',
                            style: TextStyle(fontSize: 12),
                          ),
                          Switch(
                            value: _maxLogs == 2,
                            onChanged: (val) {
                              setState(() {
                                _maxLogs = val ? 2 : 1;
                                // reset values when mode changes
                                _resetClockValues();
                                _checkInitialClockState();
                              });
                            },
                          ),
                          const Text(
                            'Two Check',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    // Attendance Records
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Today\'s Attendance',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Single attendance pair
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey[50],
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Obx(() => _buildTimeCard(
                                    timeController.clockInTime.value,
                                    Icons.login,
                                    _maxLogs == 2 ? "AM In" : "AM",
                                    AppTheme.successColor)),
                                Obx(() => _buildTimeCard(
                                    timeController.clockOutTime.value,
                                    Icons.logout,
                                    _maxLogs == 2 ? "AM Out" : "PM",
                                    AppTheme.dangerColor)),
                              ],
                            ),
                          ),
                          // Second pair (only when enabled)
                          if (_maxLogs == 2) ...[
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.grey[50],
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Obx(() => _buildTimeCard(
                                      timeController.clockInTime2.value,
                                      Icons.login,
                                      "PM In",
                                      AppTheme.successColor)),
                                  Obx(() => _buildTimeCard(
                                      timeController.clockOutTime2.value,
                                      Icons.logout,
                                      "PM Out",
                                      AppTheme.dangerColor)),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppConstants.verticalSpacingLarge),
                    // Enrolled face thumbnail + Face Enrollment Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Builder(builder: (context) {
                          final path = _faceService.getEnrolledFacePath();
                          if (path != null && File(path).existsSync()) {
                            return Container(
                              margin: const EdgeInsets.only(right: 16),
                              width: 84,
                              height: 84,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: ClipOval(
                                child: Image.file(
                                  File(path),
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) =>
                                      const Icon(Icons.face),
                                ),
                              ),
                            );
                          }

                          // Placeholder when no enrolled face
                          return Container(
                            margin: const EdgeInsets.only(right: 16),
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: const Icon(Icons.face,
                                size: 40, color: Colors.grey),
                          );
                        }),
                        ElevatedButton.icon(
                          onPressed: _openEnrollmentDialog,
                          icon: const Icon(Icons.face),
                          label: Text(
                              _faceEnrolled ? 'Update Face' : 'Enroll Face'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeCard(String time, IconData icon, String label, Color color) {
    final isLogged = time != AppConstants.defaultTimeFormat;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          border: Border.all(
            color: isLogged ? color.withOpacity(0.3) : Colors.grey[300]!,
            width: 2,
          ),
          boxShadow: isLogged
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.1),
              ),
              child: Icon(
                icon,
                size: 24,
                color: isLogged ? color : Colors.grey[400],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isLogged ? color : Colors.grey[400],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Painter to draw face bounding boxes over the captured image preview.
class _FaceRectPainter extends CustomPainter {
  final List<Face> faces;
  final ui.Image image;

  _FaceRectPainter(this.faces, this.image);

  @override
  void paint(Canvas canvas, Size size) {
    if (faces.isEmpty) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Colors.greenAccent;

    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.greenAccent.withOpacity(0.15);

    final scaleX = size.width / image.width;
    final scaleY = size.height / image.height;

    for (final face in faces) {
      final r = face.boundingBox;
      final left = r.left * scaleX;
      final top = r.top * scaleY;
      final w = r.width * scaleX;
      final h = r.height * scaleY;

      final rect = Rect.fromLTWH(left, top, w, h);
      canvas.drawRect(rect, fill);
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
