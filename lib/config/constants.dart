class AppConstants {
  // Time Tracker Constants
  static const String clockInText = "Clock In";
  static const String clockOutText = "Clock Out";
  static const String completedText = "Completed";
  static const String defaultTimeFormat = "--:--:-- --";

  // Time format patterns
  static const String timeFormat24h = 'HH:mm:ss';
  static const String timeFormat12h = 'hh:mm:ss a';
  static const String dateFormatFull = 'EEEE, MMMM d';
  static const String dateFormatDB = 'yyyy-MM-dd';
  static const String dateFormatDisplay = 'MM/dd/yyyy';

  // Authentication messages
  static const String authClockInMessage = 'Please authenticate to clock in';
  static const String authClockOutMessage = 'Please authenticate to clock out';
  static const String authFailedMessage = 'Authentication failed';
  static const String biometricUnavailableMessage =
      'Biometric authentication not available';
  static const String faceAuthUnavailableMessage =
      'Face authentication not available';
  static const String biometricFallbackMessage =
      'Face not available — using other available biometrics';

  // Success and error messages
  static const String clockInSuccessMessage = 'Clocked In successfully!';
  static const String clockOutSuccessMessage = 'Clocked Out successfully!';
  static const String attendanceCompletedMessage =
      'You have already completed your attendance for today';
  static const String noEmployeeDataMessage = 'Employee data not found';
  static const String failedAttendanceMessage =
      'Failed to log attendance. Please try again.';

  // Form messages
  static const String formSavedMessage = 'Form saved successfully';
  static const String formUpdatedMessage = 'Form updated successfully';
  static const String formFinalizedMessage = 'Form finalized successfully';
  static const String formVoidedMessage = 'Form voided successfully';
  static const String formFieldsRequiredMessage =
      'Please fill in all required fields';
  static const String formCannotVoidMessage = 'Cannot void unsaved form';
  static const String formSaveFirstMessage = 'Please save the form first';

  // Form dialogs
  static const String finalizeFormTitle = 'Finalize Form';
  static const String finalizeFormMessage =
      'Are you sure you want to finalize this form? This action cannot be undone.';
  static const String voidFormTitle = 'Void Form';
  static const String voidFormMessage =
      'Are you sure you want to void this form? This action cannot be undone.';

  // Form status text
  static const String statusVoided = 'VOIDED';
  static const String statusNotSubmitted = 'NOT SUBMITTED';
  static const String statusApproved = 'APPROVED';
  static const String statusRejected = 'REJECTED';
  static const String statusPending = 'PENDING';

  // Widget dimensions
  static const double clockButtonSize = 200.0;
  static const double clockIconSize = 40.0;
  static const double timeIndicatorIconSize = 30.0;
  static const double clockStatusFontSize = 16.0;
  static const double timeIndicatorPadding = 12.0;
  static const double timeIndicatorFontSize = 12.0;
  static const double verticalSpacingLarge = 60.0;
  static const double verticalSpacingSmall = 8.0;
  static const double formPadding = 16.0;

  // Animation durations
  static const Duration snackBarDuration = Duration(seconds: 2);
  static const Duration clockRefreshRate = Duration(seconds: 1);
  static const Duration transitionDuration = Duration(milliseconds: 300);
}
