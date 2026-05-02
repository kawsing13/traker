import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
//import '../../config/constants.dart';

class DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? selectedDate;
  final Function(DateTime) onDateSelected;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool enabled;
  final String? dateFormat;
  final String? hintText;

  const DatePickerField({
    super.key,
    required this.label,
    required this.selectedDate,
    required this.onDateSelected,
    this.firstDate,
    this.lastDate,
    this.enabled = true,
    this.dateFormat,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        InkWell(
          onTap: enabled ? () => _selectDate(context) : null,
          child: InputDecorator(
            decoration: InputDecoration(
              hintText: hintText ?? 'Select Date',
              border: const OutlineInputBorder(),
              enabled: enabled,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    selectedDate != null
                        ? DateFormat(dateFormat ?? 'MM/dd/yyyy')
                            .format(selectedDate!)
                        : hintText ?? 'Select Date',
                    style: TextStyle(
                      color: selectedDate != null
                          ? Colors.black
                          : Colors.grey[600],
                    ),
                  ),
                ),
                Icon(Icons.calendar_today, size: 20, color: Colors.grey[600]),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    // Make sure initialDate is valid by ensuring it's not before firstDate
    DateTime initialDate = selectedDate ?? DateTime.now();
    DateTime effectiveFirstDate =
        firstDate ?? DateTime.now().subtract(const Duration(days: 30));
    DateTime effectiveLastDate =
        lastDate ?? DateTime.now().add(const Duration(days: 365));

    // Adjust initialDate if it's before firstDate
    if (initialDate.isBefore(effectiveFirstDate)) {
      initialDate = effectiveFirstDate;
    }

    // Also ensure initialDate is not after lastDate
    if (initialDate.isAfter(effectiveLastDate)) {
      initialDate = effectiveLastDate;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: effectiveFirstDate,
      lastDate: effectiveLastDate,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onDateSelected(picked);
    }
  }
}

class TimePickerField extends StatelessWidget {
  final String label;
  final TimeOfDay? selectedTime;
  final Function(TimeOfDay) onTimeSelected;
  final bool enabled;
  final String? hintText;

  const TimePickerField({
    super.key,
    required this.label,
    required this.selectedTime,
    required this.onTimeSelected,
    this.enabled = true,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        InkWell(
          onTap: enabled ? () => _selectTime(context) : null,
          child: InputDecorator(
            decoration: InputDecoration(
              hintText: hintText ?? 'Select Time',
              border: const OutlineInputBorder(),
              enabled: enabled,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedTime != null
                      ? selectedTime!.format(context)
                      : hintText ?? 'Select Time',
                  style: TextStyle(
                    color:
                        selectedTime != null ? Colors.black : Colors.grey[600],
                  ),
                ),
                Icon(Icons.access_time, size: 20, color: Colors.grey[600]),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black, // Ensures text is black
            ),
            timePickerTheme: TimePickerThemeData(
              dayPeriodTextColor: Colors.black, // AM/PM text color
              hourMinuteTextColor: Colors.black, // Hour/minute display color
              dayPeriodBorderSide:
                  const BorderSide(color: Colors.grey), // AM/PM border
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              hourMinuteShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              dialTextColor: Colors.black, // Dial numbers color
              entryModeIconColor: AppTheme.primaryColor,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor, // Button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onTimeSelected(picked);
    }
  }
}

// A new DateRangePickerField for forms that need date ranges
class DateRangePickerField extends StatelessWidget {
  final String label;
  final DateTimeRange? selectedDateRange;
  final Function(DateTimeRange) onDateRangeSelected;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool enabled;
  final String? dateFormat;
  final String? hintText;

  const DateRangePickerField({
    super.key,
    required this.label,
    required this.selectedDateRange,
    required this.onDateRangeSelected,
    this.firstDate,
    this.lastDate,
    this.enabled = true,
    this.dateFormat,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        InkWell(
          onTap: enabled ? () => _selectDateRange(context) : null,
          child: InputDecorator(
            decoration: InputDecoration(
              hintText: hintText ?? 'Select Date Range',
              border: const OutlineInputBorder(),
              enabled: enabled,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    selectedDateRange != null
                        ? '${DateFormat(dateFormat ?? 'MM/dd/yyyy').format(selectedDateRange!.start)} - ${DateFormat(dateFormat ?? 'MM/dd/yyyy').format(selectedDateRange!.end)}'
                        : hintText ?? 'Select Date Range',
                    style: TextStyle(
                      color: selectedDateRange != null
                          ? Colors.black
                          : Colors.grey[600],
                    ),
                  ),
                ),
                Icon(Icons.date_range, size: 20, color: Colors.grey[600]),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDateRange(BuildContext context) async {
    // Get effective dates
    DateTime effectiveFirstDate =
        firstDate ?? DateTime.now().subtract(const Duration(days: 365));
    DateTime effectiveLastDate =
        lastDate ?? DateTime.now().add(const Duration(days: 365));

    // Create a valid initial date range if needed
    DateTimeRange? initialRange = selectedDateRange;
    if (initialRange == null) {
      // Default to current week
      final now = DateTime.now();
      initialRange = DateTimeRange(
        start: now,
        end: now.add(const Duration(days: 7)),
      );
    }

    // Ensure start date is valid
    if (initialRange.start.isBefore(effectiveFirstDate)) {
      initialRange = DateTimeRange(
        start: effectiveFirstDate,
        end: initialRange.end,
      );
    }

    // Ensure end date is valid
    if (initialRange.end.isAfter(effectiveLastDate)) {
      initialRange = DateTimeRange(
        start: initialRange.start,
        end: effectiveLastDate,
      );
    }

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: initialRange,
      firstDate: effectiveFirstDate,
      lastDate: effectiveLastDate,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onDateRangeSelected(picked);
    }
  }
}
