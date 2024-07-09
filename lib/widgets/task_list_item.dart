import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todolist_app/models/task.dart';
import 'package:todolist_app/providers/task_provider.dart';
import 'package:todolist_app/widgets/edit_task_dialog.dart';
import 'package:intl/intl.dart';

class TaskListItem extends StatelessWidget {
  final Task task;

  const TaskListItem({Key? key, required this.task}) : super(key: key);

  Color _getCategoryColor() {
    switch (task.category) {
      case 'Learning':
        return Colors.blue;
      case 'Working':
        return Colors.red;
      case 'General':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Checkbox(
          value: task.isCompleted,
          onChanged: task.isCompleted
              ? null
              : (bool? value) {
                  Provider.of<TaskProvider>(context, listen: false)
                      .toggleTaskCompletion(task.id);
                },
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isCompleted
                ? TextDecoration.lineThrough
                : TextDecoration.none,
            decorationColor: task.isCompleted
                ? brightness == Brightness.light
                    ? _getCategoryColor().withOpacity(1)
                    : CupertinoColors.black
                : null,
            decorationThickness: 3,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task.description),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(CupertinoIcons.tag, size: 16),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    task.category.isEmpty
                        ? 'No category selected'
                        : task.category,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 8),
                Icon(CupertinoIcons.time, size: 16),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    task.dueDate != null
                        ? DateFormat('MMM d, y HH:mm').format(task.dueDate!)
                        : 'No due date',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: task.isCompleted
            ? null
            : IconButton(
                icon: Icon(CupertinoIcons.pencil),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => EditTaskDialog(task: task),
                  );
                },
              ),
        tileColor: _getCategoryColor().withOpacity(0.1),
      ),
    );
  }
}
