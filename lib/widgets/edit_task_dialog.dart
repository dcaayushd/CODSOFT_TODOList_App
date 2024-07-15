import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../providers/task_provider.dart';
import '../utils/utils.dart';

class EditTaskDialog extends StatefulWidget {
  final Task task;

  const EditTaskDialog({Key? key, required this.task}) : super(key: key);

  @override
  EditTaskDialogState createState() => EditTaskDialogState();
}

class EditTaskDialogState extends State<EditTaskDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late String _selectedCategory;
  DateTime? _dueDateTime;
  late bool _isPinned;
  bool _hasAlert = false;
  DateTime? _alertDateTime;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController =
        TextEditingController(text: widget.task.description);
    _selectedCategory = widget.task.category;
    _dueDateTime = widget.task.dueDate;
    _isPinned = widget.task.isPinned;
    _hasAlert = widget.task.hasAlert;
    _alertDateTime = widget.task.alertDateTime;
    _updateAlertDateTime();
  }

  void _updateAlertDateTime() {
    if (_hasAlert && _dueDateTime != null) {
      final now = DateTime.now();
      final thirtyMinutesBeforeDue =
          _dueDateTime!.subtract(const Duration(minutes: 30));
      if (thirtyMinutesBeforeDue.isAfter(now)) {
        _alertDateTime = thirtyMinutesBeforeDue;
      } else {
        _alertDateTime = now;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return AlertDialog(
      title: const Text('Edit Task'),
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
            Text(
              'Category',
              style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
            ),
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
                                : CupertinoColors.black,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Due Date and Time',
              style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
            ),
            Row(
              children: [
                Expanded(
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _showDueDateTimePicker,
                    child: Text(
                      _dueDateTime == null
                          ? 'Select Date'
                          : DateFormat('MMM d, y').format(_dueDateTime!),
                    ),
                  ),
                ),
                Expanded(
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _showDueDateTimePicker,
                    child: Text(
                      _dueDateTime == null
                          ? 'Select Time'
                          : DateFormat('h:mm a').format(_dueDateTime!),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Set Alert',
                  style:
                      CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                ),
                const SizedBox(width: 8),
                CupertinoSwitch(
                  value: _hasAlert,
                  onChanged: (value) {
                    setState(() {
                      _hasAlert = value;
                      _updateAlertDateTime();
                    });
                  },
                ),
              ],
            ),
            if (_hasAlert) ...[
              const SizedBox(height: 8),
              Text(
                'Alert Date and Time',
                style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
              ),
              Row(
                children: [
                  Expanded(
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _showAlertDateTimePicker,
                      child: Text(_alertDateTime == null
                          ? 'Select Date'
                          : DateFormat('MMM d, y').format(_alertDateTime!)),
                    ),
                  ),
                  Expanded(
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _showAlertDateTimePicker,
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
          child: const Text('Save'),
          onPressed: () async {
            if (_titleController.text.isNotEmpty) {
              if (_hasAlert && _alertDateTime != null && _dueDateTime != null) {
                if (_alertDateTime!.isAfter(_dueDateTime!)) {
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

              final updatedTask = Task(
                id: widget.task.id,
                title: _titleController.text,
                description: _descriptionController.text,
                category: _selectedCategory,
                dueDate: _dueDateTime,
                isCompleted: widget.task.isCompleted,
                isPinned: _isPinned,
                hasAlert: _hasAlert,
                alertDateTime: _hasAlert ? _alertDateTime : null,
                isOverdue: _dueDateTime != null &&
                    _dueDateTime!.isBefore(DateTime.now()),
              );

              await Provider.of<TaskProvider>(context, listen: false)
                  .updateTask(updatedTask);
              Navigator.of(context).pop();
            }
          },
        ),
      ],
    );
  }

  void _showDueDateTimePicker() {
    final now = DateTime.now();
    final initialDate = _dueDateTime ?? now.add(const Duration(minutes: 45));
    final minimumDate = now.add(const Duration(days: 0));

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => Container(
        height: 216,
        padding: const EdgeInsets.only(top: 6.0),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SafeArea(
          top: false,
          child: CupertinoDatePicker(
            initialDateTime:
                initialDate.isAfter(minimumDate) ? initialDate : minimumDate,
            minimumDate: minimumDate,
            mode: CupertinoDatePickerMode.dateAndTime,
            use24hFormat: false,
            onDateTimeChanged: (DateTime newDateTime) {
              setState(() {
                _dueDateTime = newDateTime;
                _updateAlertDateTime();
              });
            },
          ),
        ),
      ),
    );
  }

  void _showAlertDateTimePicker() {
    final now = DateTime.now();
    final initialDate = _alertDateTime ?? now.add(const Duration(minutes: 30));

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => Container(
        height: 216,
        padding: const EdgeInsets.only(top: 6.0),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SafeArea(
          top: false,
          child: CupertinoDatePicker(
            initialDateTime: initialDate,
            maximumDate: _dueDateTime,
            minimumDate: now,
            mode: CupertinoDatePickerMode.dateAndTime,
            use24hFormat: false,
            onDateTimeChanged: (DateTime newDateTime) {
              setState(() {
                _alertDateTime = newDateTime;
              });
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
