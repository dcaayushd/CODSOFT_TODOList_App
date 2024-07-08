import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todolist_app/models/task.dart';
import 'package:todolist_app/providers/task_provider.dart';
import 'package:intl/intl.dart';

class EditTaskDialog extends StatefulWidget {
  final Task task;

  EditTaskDialog({Key? key, required this.task}) : super(key: key);

  @override
  _EditTaskDialogState createState() => _EditTaskDialogState();
}

class _EditTaskDialogState extends State<EditTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late String _selectedCategory;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(text: widget.task.description);
    _selectedCategory = widget.task.category;
    if (widget.task.dueDate != null) {
      _selectedDate = widget.task.dueDate;
      _selectedTime = TimeOfDay.fromDateTime(widget.task.dueDate!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

    return AlertDialog(
      title: Text('Edit Task'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
              SizedBox(height: 16),
              Text('Category', style: Theme.of(context).textTheme.titleMedium),
              Wrap(
                spacing: 8,
                children: taskProvider.categories.map((category) {
                  return ChoiceChip(
                    label: Text(category),
                    selected: _selectedCategory == category,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    backgroundColor:
                        _getCategoryColor(category).withOpacity(0.1),
                    selectedColor: _getCategoryColor(category).withOpacity(0.3),
                  );
                }).toList(),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => _showDatePicker(context),
                      child: Text(_selectedDate == null
                          ? 'Select Date'
                          : DateFormat('MMM d, y').format(_selectedDate!)),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
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
      ),
      actions: [
        TextButton(
          child: Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton(
          child: Text('Save'),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
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
              );
              taskProvider.updateTask(updatedTask);
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
        color: Colors.white,
        child: CupertinoDatePicker(
          mode: CupertinoDatePickerMode.date,
          initialDateTime: _selectedDate ?? DateTime.now(),
          onDateTimeChanged: (val) {
            setState(() {
              _selectedDate = val;
            });
          },
        ),
      ),
    );
  }

  void _showTimePicker(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 200,
        color: Colors.white,
        child: CupertinoDatePicker(
          mode: CupertinoDatePickerMode.time,
          initialDateTime: _selectedTime != null
              ? DateTime(2021, 1, 1, _selectedTime!.hour, _selectedTime!.minute)
              : DateTime.now(),
          onDateTimeChanged: (val) {
            setState(() {
              _selectedTime = TimeOfDay.fromDateTime(val);
            });
          },
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Personal':
        return Colors.blue;
      case 'Work':
        return Colors.red;
      case 'Shopping':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }
}