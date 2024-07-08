import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todolist_app/models/task.dart';
import 'package:todolist_app/providers/task_provider.dart';

class EditTaskDialog extends StatelessWidget {
  final Task task;
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;

  EditTaskDialog({Key? key, required this.task}) : super(key: key) {
    _titleController = TextEditingController(text: task.title);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Task'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Task Title',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a task title';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton(
          child: const Text('Save'),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Provider.of<TaskProvider>(context, listen: false)
                  .updateTask(task);
              Navigator.of(context).pop();
            }
          },
        ),
      ],
    );
  }
}
