import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../providers/task_provider.dart';
import '../utils/date_time_picker.dart';
import '../utils/utils.dart';

class AddTaskDialog extends StatefulWidget {
  const AddTaskDialog({super.key});

  @override
  AddTaskDialogState createState() => AddTaskDialogState();
}

class AddTaskDialogState extends State<AddTaskDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  String _selectedCategory = '';
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _hasAlert = false;
  DateTime? _alertDateTime;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

    return AlertDialog(
      title: const Text('Add Task'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CupertinoTextField(
              controller: _titleController,
              placeholder: 'Title',
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(8),
              ),
              style: const TextStyle(color: CupertinoColors.label),
            ),
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: _descriptionController,
              placeholder: 'Description',
              padding: const EdgeInsets.all(8),
              maxLines: 3,
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(8),
              ),
              style: const TextStyle(color: CupertinoColors.label),
            ),
            const SizedBox(height: 16),
            Text('Category',
                style: CupertinoTheme.of(context).textTheme.textStyle),
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: taskProvider.categories.map((category) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: _selectedCategory == category
                              ? Utils.getCategoryColor(category)
                              : CupertinoColors.systemGrey5,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            color: _selectedCategory == category
                                ? CupertinoColors.white
                                : CupertinoColors.label,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Due Date and Time',
                style: CupertinoTheme.of(context).textTheme.textStyle),
            Row(
              children: [
                Expanded(
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => _showDatePicker(context),
                    child: Text(
                      _selectedDate == null
                          ? 'Select Date'
                          : DateFormat('MMM d, y').format(_selectedDate!),
                    ),
                  ),
                ),
                Expanded(
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => _showTimePicker(context),
                    child: Text(
                      _selectedTime == null
                          ? 'Select Time'
                          : _selectedTime!.format(context),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('Set Alert',
                    style: CupertinoTheme.of(context).textTheme.textStyle),
                const SizedBox(width: 8),
                CupertinoSwitch(
                  value: _hasAlert,
                  onChanged: (value) {
                    setState(() {
                      _hasAlert = value;
                      if (_hasAlert && _alertDateTime == null) {
                        _alertDateTime = _selectedDate
                            ?.subtract(const Duration(minutes: 30));
                      }
                    });
                  },
                ),
              ],
            ),
            if (_hasAlert) ...[
              const SizedBox(height: 8),
              Text('Alert Date and Time',
                  style: CupertinoTheme.of(context).textTheme.textStyle),
              Row(
                children: [
                  Expanded(
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => _showAlertDatePicker(context),
                      child: Text(_alertDateTime == null
                          ? 'Select Date'
                          : DateFormat('MMM d, y').format(_alertDateTime!)),
                    ),
                  ),
                  Expanded(
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => _showAlertTimePicker(context),
                      child: Text(_alertDateTime == null
                          ? 'Select Time'
                          : DateFormat('h:mm a').format(_alertDateTime!)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Colors.red,
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          child: const Text('Add'),
          onPressed: () async {
            if (_titleController.text.isNotEmpty) {
              final dueDate = _selectedDate != null && _selectedTime != null
                  ? DateTime(
                      _selectedDate!.year,
                      _selectedDate!.month,
                      _selectedDate!.day,
                      _selectedTime!.hour,
                      _selectedTime!.minute,
                    )
                  : null;

              if (_hasAlert && _alertDateTime != null && dueDate != null) {
                if (_alertDateTime!.isAfter(dueDate)) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Invalid Alert Time'),
                      content: const Text(
                          'Alert time cannot be after the due date.'),
                      actions: [
                        TextButton(
                          child: const Text('OK'),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  );
                  return;
                }
              }

              final newTask = Task(
                title: _titleController.text,
                description: _descriptionController.text,
                category: _selectedCategory,
                dueDate: dueDate,
                hasAlert: _hasAlert,
                alertDateTime: _hasAlert ? _alertDateTime : null,
              );

              await taskProvider.addTask(newTask);
              Navigator.of(context).pop();
            }
          },
        ),
      ],
    );
  }

  void _showDatePicker(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 200,
        color: CupertinoTheme.of(context).brightness == Brightness.light
            ? CupertinoColors.systemBackground
            : Colors.black,
        child: DateTimePicker(
          initialDateTime: _selectedDate ?? DateTime.now(),
          mode: CupertinoDatePickerMode.date,
          onDateTimeChanged: (val) {
            setState(() {
              _selectedDate = val;
            });
          },
        ),
      ),
    ).then((_) {
      if (_selectedDate == null) {
        setState(() {
          _selectedDate = DateTime.now();
        });
      }
    });
  }

  void _showTimePicker(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 200,
        color: CupertinoTheme.of(context).brightness == Brightness.light
            ? CupertinoColors.systemBackground
            : Colors.black,
        child: DateTimePicker(
          initialDateTime: _selectedTime != null
              ? DateTime(2023, 1, 1, _selectedTime!.hour, _selectedTime!.minute)
              : DateTime.now(),
          mode: CupertinoDatePickerMode.time,
          onDateTimeChanged: (val) {
            setState(() {
              _selectedTime = TimeOfDay.fromDateTime(val);
            });
          },
        ),
      ),
    ).then((_) {
      if (_selectedTime == null) {
        setState(() {
          _selectedTime = TimeOfDay.now();
        });
      }
    });
  }

  void _showAlertDatePicker(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 200,
        color: CupertinoTheme.of(context).brightness == Brightness.light
            ? CupertinoColors.systemBackground
            : CupertinoColors.black,
        child: DateTimePicker(
          initialDateTime: _alertDateTime ?? DateTime.now(),
          mode: CupertinoDatePickerMode.date,
          onDateTimeChanged: (val) {
            setState(() {
              _alertDateTime = DateTime(
                val.year,
                val.month,
                val.day,
                _alertDateTime?.hour ?? 0,
                _alertDateTime?.minute ?? 0,
              );
            });
          },
        ),
      ),
    ).then((_) {
      if (_alertDateTime == null) {
        setState(() {
          _alertDateTime = DateTime.now();
        });
      }
    });
  }

  void _showAlertTimePicker(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 200,
        color: CupertinoTheme.of(context).brightness == Brightness.light
            ? CupertinoColors.systemBackground
            : CupertinoColors.black,
        child: DateTimePicker(
          initialDateTime: _alertDateTime ?? DateTime.now(),
          mode: CupertinoDatePickerMode.time,
          onDateTimeChanged: (val) {
            setState(() {
              _alertDateTime = DateTime(
                _alertDateTime?.year ?? DateTime.now().year,
                _alertDateTime?.month ?? DateTime.now().month,
                _alertDateTime?.day ?? DateTime.now().day,
                val.hour,
                val.minute,
              );
            });
          },
        ),
      ),
    ).then((_) {
      if (_alertDateTime == null) {
        setState(() {
          _alertDateTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}

