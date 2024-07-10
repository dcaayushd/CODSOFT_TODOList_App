import 'package:flutter/cupertino.dart';
// import 'package:intl/intl.dart';

class DateTimePicker extends StatefulWidget {
  final DateTime? initialDateTime;
  final Function(DateTime)? onDateTimeChanged;
  final CupertinoDatePickerMode mode;

  DateTimePicker({
    Key? key,
    this.initialDateTime,
    this.onDateTimeChanged,
    required this.mode,
  }) : super(key: key);

  @override
  _DateTimePickerState createState() => _DateTimePickerState();
}

class _DateTimePickerState extends State<DateTimePicker> {
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
