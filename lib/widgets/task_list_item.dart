import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todolist_app/models/task.dart';
import 'package:todolist_app/providers/task_provider.dart';
import 'package:todolist_app/widgets/delete_task_dialog.dart';
import 'package:todolist_app/widgets/edit_task_dialog.dart';
import 'package:intl/intl.dart';
import 'dart:async';

import '../utils/utils.dart';

class TaskListItem extends StatefulWidget {
  final Task task;
  final bool isFirstTask;
  static OverlayEntry? currentOverlay;
  static GlobalKey<_TaskListItemState>? activeTaskKey;

  const TaskListItem({Key? key, required this.task, this.isFirstTask = false})
      : super(key: key);

  @override
  _TaskListItemState createState() => _TaskListItemState();

  static void showReactionContainer(BuildContext context, Task task,
      GlobalKey<_TaskListItemState> taskKey, bool isFirstTask) {
    if (currentOverlay != null) {
      currentOverlay!.remove();
      currentOverlay = null;
      if (activeTaskKey != null) {
        activeTaskKey!.currentState?.setShifted(false);
      }
    }

    activeTaskKey = taskKey;
    taskKey.currentState?.setShifted(true);

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    currentOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                currentOverlay?.remove();
                currentOverlay = null;
                taskKey.currentState?.setShifted(false);
              },
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            left: offset.dx + (size.width / 2) - 75,
            top: isFirstTask ? offset.dy + size.height : offset.dy - 60,
            child: Material(
              color: Colors.transparent,
              child: TaskReactionContainer(
                task: task,
                onClose: () {
                  currentOverlay?.remove();
                  currentOverlay = null;
                  taskKey.currentState?.setShifted(false);
                },
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(currentOverlay!);
  }
}

class _TaskListItemState extends State<TaskListItem> {
  bool _isBlinking = false;
  bool _isShifted = false;
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

  void setShifted(bool shifted) {
    setState(() {
      _isShifted = shifted;
    });
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isOverdue = this.isOverdue;

    return GestureDetector(
      onLongPressStart: (details) {
        if (!widget.task.isCompleted) {
          TaskListItem.showReactionContainer(context, widget.task,
              GlobalKey<_TaskListItemState>(), widget.isFirstTask);
        }
      },
      onTap: () {
        if (!widget.task.isCompleted) {
          showDialog(
            context: context,
            builder: (context) => EditTaskDialog(task: widget.task),
          );
        }
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        margin: EdgeInsets.only(top: _isShifted ? 50 : 0),
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
      ),
    );
  }
}

class TaskReactionContainer extends StatefulWidget {
  final Task task;
  final VoidCallback onClose;

  const TaskReactionContainer({
    Key? key,
    required this.task,
    required this.onClose,
  }) : super(key: key);

  @override
  _TaskReactionContainerState createState() => _TaskReactionContainerState();
}

class _TaskReactionContainerState extends State<TaskReactionContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _opacityAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _closeContainer() {
    _controller.reverse().then((_) {
      widget.onClose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = Utils.getCategoryColor(widget.task.category);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * _scaleAnimation.value),
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Container(
              width: 150,
              decoration: BoxDecoration(
                color: categoryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: categoryColor.withOpacity(0.1),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    context,
                    icon: widget.task.isPinned
                        ? CupertinoIcons.pin_slash
                        : CupertinoIcons.pin,
                    color: isDarkMode ? Colors.white : Colors.black,
                    opacity: 1.0,
                    onTap: () {
                      if (widget.task.isPinned) {
                        Provider.of<TaskProvider>(context, listen: false)
                            .unpinTask(widget.task.id);
                      } else {
                        Provider.of<TaskProvider>(context, listen: false)
                            .pinTask(widget.task.id);
                      }
                      _closeContainer();
                    },
                  ),
                  _buildActionButton(
                    context,
                    icon: CupertinoIcons.pencil,
                    color: categoryColor,
                    opacity: 1.0,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => EditTaskDialog(task: widget.task),
                      );
                      _closeContainer();
                    },
                  ),
                  _buildActionButton(
                    context,
                    icon: CupertinoIcons.delete,
                    color: Colors.red,
                    opacity: 1.0,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) =>
                            DeleteTaskDialog(taskTitle: widget.task.title),
                      ).then((result) {
                        if (result == true) {
                          Provider.of<TaskProvider>(context, listen: false)
                              .deleteTask(widget.task.id);
                        }
                        _closeContainer();
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton(BuildContext context,
      {required IconData icon,
      required Color color,
      required double opacity,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(10),
        child: Icon(icon, color: color.withOpacity(opacity), size: 24),
      ),
    );
  }
}
