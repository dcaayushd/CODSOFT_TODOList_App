import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todolist_app/models/task.dart';
import 'package:todolist_app/providers/task_provider.dart';
import 'package:intl/intl.dart';

import '../utils/utils.dart';
import '../utils/date_time_picker.dart';

class EditTaskDialog extends StatefulWidget {
  final Task task;

  EditTaskDialog({Key? key, required this.task}) : super(key: key);

  @override
  _EditTaskDialogState createState() => _EditTaskDialogState();
}

class _EditTaskDialogState extends State<EditTaskDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late String _selectedCategory;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  late bool _isPinned;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController =
        TextEditingController(text: widget.task.description);
    _selectedCategory = widget.task.category;
    if (widget.task.dueDate != null) {
      _selectedDate = widget.task.dueDate;
      _selectedTime = TimeOfDay.fromDateTime(widget.task.dueDate!);
    }
    _isPinned = widget.task.isPinned;
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

    return AlertDialog(
      title: Text('Edit Task'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoTextField(
              controller: _titleController,
              placeholder: 'Title',
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(8),
              ),
              style: TextStyle(color: CupertinoColors.label),
            ),
            SizedBox(height: 8),
            CupertinoTextField(
              controller: _descriptionController,
              placeholder: 'Description',
              padding: EdgeInsets.all(8),
              maxLines: 3,
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(8),
              ),
              style: TextStyle(color: CupertinoColors.label),
            ),
            SizedBox(height: 16),
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
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        margin: EdgeInsets.symmetric(horizontal: 4),
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
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => _showDatePicker(context),
                    child: Text(_selectedDate == null
                        ? 'Select Date'
                        : DateFormat('MMM d, y').format(_selectedDate!)),
                  ),
                ),
                Expanded(
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => _showTimePicker(context),
                    child: Text(_selectedTime == null
                        ? 'Select Time'
                        : _selectedTime!.format(context)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: 80,
              child: CupertinoDialogAction(
                child: Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(),
                isDestructiveAction: true,
              ),
            ),
            SizedBox(
              width: 80,
              child: CupertinoDialogAction(
                child: Text('Save'),
                isDefaultAction: true,
                onPressed: () {
                  if (_titleController.text.isNotEmpty) {
                    final updatedTask = Task(
                      id: widget.task.id,
                      title: _titleController.text,
                      description: _descriptionController.text,
                      category: _selectedCategory,
                      dueDate: _selectedDate != null && _selectedTime != null
                          ? DateTime(
                              _selectedDate!.year,
                              _selectedDate!.month,
                              _selectedDate!.day,
                              _selectedTime!.hour,
                              _selectedTime!.minute,
                            )
                          : null,
                      isCompleted: widget.task.isCompleted,
                      isPinned: _isPinned,
                    );
                    taskProvider.updateTask(updatedTask);
                    Navigator.of(context).pop();
                  }
                },
              ),
            ),
          ],
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

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
