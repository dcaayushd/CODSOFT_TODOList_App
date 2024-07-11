import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todolist_app/models/task.dart';
import 'package:todolist_app/providers/task_provider.dart';
import 'package:todolist_app/widgets/edit_task_dialog.dart';
import 'package:intl/intl.dart';
import 'dart:async';

import '../utils/utils.dart';

class TaskListItem extends StatefulWidget {
  final Task task;

  const TaskListItem({Key? key, required this.task}) : super(key: key);

  @override
  _TaskListItemState createState() => _TaskListItemState();
}

class _TaskListItemState extends State<TaskListItem> {
  bool _isBlinking = false;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(Duration.zero, () {});

    if (isOverdue) {
      _startBlinking();
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startBlinking() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _isBlinking = !_isBlinking;
      });
    });
  }

  bool get isOverdue {
    final now = DateTime.now();
    return widget.task.dueDate != null &&
        widget.task.dueDate!.isBefore(now) &&
        !widget.task.isCompleted;
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isOverdue = this.isOverdue;

    return GestureDetector(
      onLongPress: widget.task.isCompleted
          ? null
          : () {
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return ListView(
                    children: [
                      ListTile(
                        leading: Icon(widget.task.isPinned
                            ? CupertinoIcons.pin_slash
                            : CupertinoIcons.pin),
                        title: Text(widget.task.isPinned ? 'Unpin' : 'Pin'),
                        onTap: () {
                          if (widget.task.isPinned) {
                            Provider.of<TaskProvider>(context, listen: false)
                                .unpinTask(widget.task.id);
                          } else {
                            Provider.of<TaskProvider>(context, listen: false)
                                .pinTask(widget.task.id);
                          }
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  );
                },
              );
            },
      onTap: () {
        if (!widget.task.isCompleted) {
          showDialog(
            context: context,
            builder: (context) => EditTaskDialog(task: widget.task),
          );
        }
      },
      child: Stack(
        children: [
          Card(
            elevation: 2,
            margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color:
                isOverdue && _isBlinking ? Colors.red.withOpacity(0.1) : null,
            child: ListTile(
              leading: Checkbox(
                value: widget.task.isCompleted,
                onChanged: widget.task.isCompleted
                    ? null
                    : (bool? value) {
                        Provider.of<TaskProvider>(context, listen: false)
                            .toggleTaskCompletion(widget.task.id);
                      },
                activeColor: isOverdue ? Colors.red : null,
              ),
              title: Text(
                widget.task.title,
                style: TextStyle(
                  decoration: widget.task.isCompleted
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                  decorationColor: widget.task.isCompleted
                      ? brightness == Brightness.light
                          ? Utils.getCategoryColor(widget.task.category)
                              .withOpacity(1)
                          : CupertinoColors.black
                      : null,
                  decorationThickness: 3,
                  color: isOverdue ? Colors.red : null,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isOverdue)
                    Text(
                      'Task not completed on time!',
                      style: TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  Text(
                    widget.task.description,
                    style: TextStyle(
                      color: isOverdue ? Colors.red : null,
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.tag,
                        size: 16,
                        color: isOverdue ? Colors.red : null,
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.task.category.isEmpty
                              ? 'No category selected'
                              : widget.task.category,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isOverdue ? Colors.red : null,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        CupertinoIcons.time,
                        size: 16,
                        color: isOverdue ? Colors.red : null,
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.task.dueDate != null
                              ? DateFormat('MMM d, y HH:mm')
                                  .format(widget.task.dueDate!)
                              : 'No due date',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isOverdue ? Colors.red : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: widget.task.isCompleted
                  ? null
                  : IconButton(
                      icon: Icon(
                        CupertinoIcons.pencil,
                        size: 35,
                        color: isOverdue ? Colors.red : null,
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) =>
                              EditTaskDialog(task: widget.task),
                        );
                      },
                    ),
              tileColor: isOverdue
                  ? Colors.red.withOpacity(0.1)
                  : Utils.getCategoryColor(widget.task.category)
                      .withOpacity(0.1),
            ),
          ),
          if (widget.task.isPinned && !widget.task.isCompleted)
            Positioned(
              top: 8,
              left: 8,
              child: GestureDetector(
                onTap: () {
                  Provider.of<TaskProvider>(context, listen: false)
                      .unpinTask(widget.task.id);
                },
                child: Icon(
                  CupertinoIcons.pin_fill,
                  color: isOverdue
                      ? Colors.red
                      : Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
