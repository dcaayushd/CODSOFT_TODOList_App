import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todolist_app/models/task.dart';
import 'package:todolist_app/providers/task_provider.dart';
import 'package:todolist_app/widgets/edit_task_dialog.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class TaskListItem extends StatelessWidget {
  final Task task;

  const TaskListItem({Key? key, required this.task}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Slidable(
      endActionPane: ActionPane(
        motion: ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) {
              Provider.of<TaskProvider>(context, listen: false)
                  .deleteTask(task.id);
            },
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
          ),
        ],
      ),
      child: Card(
        elevation: 2,
        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: ListTile(
          leading: Checkbox(
            value: task.isCompleted,
            onChanged: (bool? value) {
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
            ),
          ),
          trailing: IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => EditTaskDialog(task: task),
              );
            },
          ),
        ),
      ),
    );
  }
}