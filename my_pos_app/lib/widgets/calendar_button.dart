import 'package:flutter/material.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';

class CalendarButton extends StatelessWidget {
  final List<DateTime?> initialDates;
  final Function(List<DateTime?>) onDatesChanged;

  CalendarButton({
    required this.initialDates,
    required this.onDatesChanged,
  });

  Future<void> _showCalendarDatePicker2Dialog(BuildContext context) async {
    var results = await showCalendarDatePicker2Dialog(
      context: context,
      config: CalendarDatePicker2WithActionButtonsConfig(
        calendarType: CalendarDatePicker2Type.single,
      ),
      dialogSize: const Size(325, 400),
      value: initialDates,
      borderRadius: BorderRadius.circular(15),
    );

    if (results != null && results.isNotEmpty) {
      onDatesChanged(results);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _showCalendarDatePicker2Dialog(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF2D71F8), // Cyan background color
      ),
      child: Text(
        'Select Date (${initialDates.isNotEmpty ? initialDates.first!.toLocal().toString().split(' ')[0] : 'Select Date'})',
        style: TextStyle(color: Colors.white), // White text color
      ),
    );
  }
}
