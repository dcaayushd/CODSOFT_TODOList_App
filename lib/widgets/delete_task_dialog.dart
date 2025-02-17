import 'package:flutter/material.dart';

class DeleteTaskDialog extends StatelessWidget {
  final String taskTitle;

  const DeleteTaskDialog({Key? key, required this.taskTitle}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete Task'),
      content: Text('Are you sure you want to delete "$taskTitle"?'),
      actions: [
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        TextButton(
          child: const Text('Delete', style: TextStyle(color: Colors.red)),
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}