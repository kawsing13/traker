import 'package:flutter/material.dart';

class AppTheme {
  // Form field container decoration
  static BoxDecoration formFieldContainerDecoration = BoxDecoration(
    border: Border.all(color: Colors.grey.shade300),
    borderRadius: BorderRadius.circular(4),
    color: Colors.grey.shade50,
  );

  // Form field label style
  static const TextStyle formLabelStyle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 14,
  );

  // Form field value text style
  static const TextStyle formValueStyle = TextStyle(
    fontSize: 14,
    height: 1.5,
  );

  // Form field description style (for additional information)
  static const TextStyle formDescriptionStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  // Colors
  static const Color primaryColor = Colors.blue;
  static const Color secondaryColor = Colors.green;
  static const Color errorColor = Colors.red;
  static const Color backgroundColor = Colors.white;
  static const Color successColor = Colors.green;
  static const Color dangerColor = Colors.red;
  static const Color warningColor = Colors.orange;
  static const Color infoColor = Colors.blue;

  // Text Styles
  static const TextStyle titleStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );

  static const TextStyle subtitleStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: Colors.black87,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: Colors.black87,
  );

  static const TextStyle clockTimeStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );

  static const TextStyle clockDateStyle = TextStyle(
    fontSize: 16,
    color: Colors.black,
  );

  static const TextStyle clockStatusStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  // Card Decoration
  static BoxDecoration cardDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: Colors.grey.shade300),
    color: Colors.white,
  );

  // Clock Button Decoration
  static BoxDecoration clockButtonDecoration(bool isActive) {
    return BoxDecoration(
      color: isActive ? Colors.grey[300] : Colors.grey[100],
      shape: BoxShape.circle,
      boxShadow: isActive
          ? [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ]
          : [],
    );
  }

  // Time Indicator Decoration
  static BoxDecoration timeIndicatorDecoration = BoxDecoration(
    color: Colors.white,
    shape: BoxShape.circle,
    boxShadow: [
      BoxShadow(
        color: Colors.grey.withOpacity(0.2),
        spreadRadius: 1,
        blurRadius: 3,
        offset: const Offset(0, 2),
      ),
    ],
  );

  // Form Decoration
  static InputDecoration inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  // Button Styles
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  );

  static ButtonStyle outlinedButtonStyle(Color color) {
    return OutlinedButton.styleFrom(
      backgroundColor: color.withOpacity(0.15),
      side: BorderSide(color: color),
      foregroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  // Snackbar styles
  static SnackBarThemeData snackBarTheme = SnackBarThemeData(
    backgroundColor: Colors.grey[800],
    contentTextStyle: const TextStyle(color: Colors.white),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  );
}
