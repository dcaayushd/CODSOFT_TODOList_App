import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../providers/task_provider.dart';
import '../utils/utils.dart';
import '../widgets/edit_task_dialog.dart';
import '../widgets/task_reaction_container.dart';
import '../services/notification_service.dart';

class TaskListItem extends StatefulWidget {
  final Task task;
  final bool isFirstTask;
  static OverlayEntry? currentOverlay;
  static GlobalKey<TaskListItemState>? activeTaskKey;

  const TaskListItem({Key? key, required this.task, this.isFirstTask = false})
      : super(key: key);

  @override
  TaskListItemState createState() => TaskListItemState();

  static void showReactionContainer(BuildContext context, Task task,
      GlobalKey<TaskListItemState> taskKey, bool isFirstTask) {
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
            left: offset.dx + (size.width / 2) - 100,
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
                onPinAnimationTrigger: () {
                  taskKey.currentState?.animatePinning();
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

class TaskListItemState extends State<TaskListItem>
    with TickerProviderStateMixin {
  bool _isBlinking = false;
  bool _isShifted = false;
  late Timer _timer;
  late NotificationService _notificationService;
  late AnimationController _pinAnimationController;
  late Animation<double> _pinAnimation;

  @override
  void initState() {
    super.initState();
    _timer = Timer(Duration.zero, () {});
    _notificationService = NotificationService();
    _notificationService.init();

    _pinAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _pinAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _pinAnimationController,
      curve: Curves.easeInOut,
    ));

    if (isOverdue) {
      _startBlinking();
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _pinAnimationController.dispose();
    super.dispose();
  }

  void _startBlinking() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
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

  Widget _buildAlertIcon() {
    final categoryColor = Utils.getCategoryColor(widget.task.category);
    if (widget.task.hasAlert && !isOverdue) {
      return GestureDetector(
        onTap: () {
          Provider.of<TaskProvider>(context, listen: false)
              .toggleTaskAlert(widget.task.id);
        },
        child: Icon(
          CupertinoIcons.bell_fill,
          size: 20,
          color: categoryColor,
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  void animatePinning() {
    _pinAnimationController.forward(from: 0).then((_) {
      _pinAnimationController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isOverdue = this.isOverdue;
    final categoryColor = Utils.getCategoryColor(widget.task.category);

    return GestureDetector(
      onLongPressStart: (details) {
        if (!widget.task.isCompleted) {
          TaskListItem.showReactionContainer(context, widget.task,
              GlobalKey<TaskListItemState>(), widget.isFirstTask);
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
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(top: _isShifted ? 50 : 0),
        child: Stack(
          children: [
            Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: isOverdue && _isBlinking
                  ? categoryColor.withOpacity(0.1)
                  : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isOverdue)
                    Container(
                      color: categoryColor.withOpacity(.1),
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 8,
                          top: 8,
                          right: 8,
                          // bottom: 4,
                        ),
                        child: Center(
                          child: Text(
                            'Task not completed !',
                            style: GoogleFonts.parisienne(
                              textStyle: TextStyle(
                                color: Colors.red[700],
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: isOverdue ? 0 : 8,
                    ),
                    leading: Checkbox(
                      value: widget.task.isCompleted,
                      onChanged: widget.task.isCompleted
                          ? null
                          : (bool? value) {
                              Provider.of<TaskProvider>(context, listen: false)
                                  .toggleTaskCompletion(widget.task.id);
                            },
                      activeColor: categoryColor,
                      checkColor: Colors.white,
                    ),
                    title: Text(
                      widget.task.title,
                      style: TextStyle(
                        decoration: widget.task.isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        decorationColor: widget.task.isCompleted
                            ? brightness == Brightness.light
                                ? categoryColor.withOpacity(1)
                                : categoryColor.withOpacity(1)
                            : null,
                        decorationThickness: 3,
                        // color: isOverdue ? Colors.red : null,
                        color: categoryColor.withOpacity(1),
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.task.description,
                          style: TextStyle(
                            // color: isOverdue ? Colors.red : null,
                            color: categoryColor.withOpacity(1),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              CupertinoIcons.tag,
                              size: 16,
                              // color: isOverdue ? Colors.red : null,
                              color: categoryColor.withOpacity(1),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.task.category.isEmpty
                                    ? 'No category selected'
                                    : widget.task.category,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  // color: isOverdue ? Colors.red : null,
                                  color: categoryColor.withOpacity(1),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              CupertinoIcons.time,
                              size: 16,
                              // color: isOverdue ? Colors.red : null,
                              color: categoryColor.withOpacity(1),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.task.dueDate != null
                                    ? DateFormat('MMM d, y HH:mm')
                                        .format(widget.task.dueDate!)
                                    : 'No due date',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  // color: isOverdue ? Colors.red : null,
                                  color: categoryColor.withOpacity(1),
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
                              color: categoryColor,
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
                        ? categoryColor.withOpacity(0.1)
                        : categoryColor.withOpacity(0.1),
                  ),
                ],
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
                  child: AnimatedBuilder(
                    animation: _pinAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 1.0 + (_pinAnimation.value * 0.3),
                        child: Opacity(
                          opacity: 1.0 - (_pinAnimation.value * 0.3),
                          child: Icon(
                            CupertinoIcons.pin_fill,
                            color: categoryColor,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            if (!widget.task.isCompleted)
              Positioned(
                top: 8,
                right: 8,
                child: _buildAlertIcon(),
              ),
          ],
        ),
      ),
    );
  }
}
