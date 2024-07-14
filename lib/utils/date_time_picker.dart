import 'package:flutter/cupertino.dart';

class DateTimePicker extends StatefulWidget {
  final DateTime? initialDateTime;
  final Function(DateTime)? onDateTimeChanged;
  final CupertinoDatePickerMode mode;
  final DateTime? minimumDate;

  const DateTimePicker({
    Key? key,
    this.initialDateTime,
    this.onDateTimeChanged,
    required this.mode,
    this.minimumDate,
  }) : super(key: key);

  @override
  DateTimePickerState createState() => DateTimePickerState();
}

class DateTimePickerState extends State<DateTimePicker> {
  late DateTime _selectedDateTime;

  @override
  void initState() {
    super.initState();
    _selectedDateTime = widget.initialDateTime ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: CupertinoDatePicker(
        mode: widget.mode,
        initialDateTime: _selectedDateTime,
        minimumDate: widget.minimumDate,
        onDateTimeChanged: (val) {
          setState(() {
            _selectedDateTime = val;
          });
          if (widget.onDateTimeChanged != null) {
            widget.onDateTimeChanged!(val);
          }
        },
      ),
    );
  }
}