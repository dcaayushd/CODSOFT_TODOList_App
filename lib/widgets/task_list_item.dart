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
                  }),
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

  void animatePinning() {
    _pinAnimationController.forward(from: 0).then((_) {
      _pinAnimationController.reverse();
    });
  }

  Widget _buildAlertIcon() {
    final categoryColor = Utils.getCategoryColor(widget.task.category);
    if (widget.task.hasAlert && !widget.task.isCompleted) {
      return GestureDetector(
        onTap: () {
          Provider.of<TaskProvider>(context, listen: false)
              .toggleTaskAlert(widget.task.id);
        },
        child: Icon(
          CupertinoIcons.bell_fill,
          size: 20,
          color: _isBlinking
              ? Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black
              : categoryColor,
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isOverdue = this.isOverdue;
    final categoryColor = Utils.getCategoryColor(widget.task.category);
    final isDarkMode = brightness == Brightness.dark;

    final backgroundColor = isDarkMode
        ? categoryColor.withOpacity(0.3)
        : categoryColor.withOpacity(0.1);

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
        margin: EdgeInsets.only(
          top: _isShifted ? 50 : 0,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: categoryColor.withOpacity(0.5),
              width: 1,
            ),
            color: isOverdue && _isBlinking
                ? categoryColor.withOpacity(0.2)
                : backgroundColor,
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: isOverdue ? 0 : 8,
                    ),
                    leading: isOverdue
                        ? _overdueCheckBox()
                        : Checkbox(
                            value: widget.task.isCompleted,
                            onChanged: widget.task.isCompleted || isOverdue
                                ? null
                                : (bool? value) {
                                    Provider.of<TaskProvider>(context,
                                            listen: false)
                                        .toggleTaskCompletion(widget.task.id);
                                  },
                            activeColor: categoryColor,
                            checkColor: Colors.white,
                          ),
                    title: isOverdue
                        ? Text(
                            'Task not completed in Time!',
                            style: GoogleFonts.robotoSlab(
                              textStyle: TextStyle(
                                color: Colors.red[500],
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          )
                        : Text(
                            widget.task.title,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.roboto(
                              textStyle: TextStyle(
                                decoration: widget.task.isCompleted
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                decorationColor: widget.task.isCompleted
                                    ? categoryColor.withOpacity(1)
                                    : null,
                                decorationThickness: 3,
                                // color: textColor,
                                color: categoryColor,

                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        isOverdue
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.task.title,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.roboto(
                                      textStyle: TextStyle(
                                        decoration: widget.task.isCompleted
                                            ? TextDecoration.lineThrough
                                            : TextDecoration.none,
                                        decorationColor: widget.task.isCompleted
                                            ? categoryColor.withOpacity(1)
                                            : null,
                                        decorationThickness: 3,
                                        // color: textColor,
                                        color: _isBlinking
                                            ? isDarkMode
                                                ? Colors.white
                                                : Colors.black
                                            : categoryColor,

                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    widget.task.description,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.roboto(
                                      textStyle: TextStyle(
                                        // color: textColor,
                                        color: _isBlinking
                                            ? isDarkMode
                                                ? Colors.white
                                                : Colors.black
                                            : categoryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                widget.task.description,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.roboto(
                                  textStyle: TextStyle(
                                    color: _isBlinking
                                        ? isDarkMode
                                            ? Colors.white
                                            : Colors.black
                                        : categoryColor,
                                  ),
                                ),
                              ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              CupertinoIcons.tag,
                              size: 16,
                              // color: textColor,
                              color: _isBlinking
                                  ? isDarkMode
                                      ? Colors.white
                                      : Colors.black
                                  : categoryColor,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.task.category.isEmpty
                                    ? 'No category selected'
                                    : widget.task.category,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.roboto(
                                  textStyle: TextStyle(
                                    // color: textColor,
                                    color: _isBlinking
                                        ? isDarkMode
                                            ? Colors.white
                                            : Colors.black
                                        : categoryColor,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              CupertinoIcons.time,
                              size: 16,
                              // color: textColor,
                              color: _isBlinking
                                  ? isDarkMode
                                      ? Colors.white
                                      : Colors.black
                                  : categoryColor,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.task.dueDate != null
                                    ? DateFormat('MMM d, y HH:mm')
                                        .format(widget.task.dueDate!)
                                    : 'No due date',
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.roboto(
                                  textStyle: TextStyle(
                                    // color: textColor,
                                    color: _isBlinking
                                        ? isDarkMode
                                            ? Colors.white
                                            : Colors.black
                                        : categoryColor,
                                  ),
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
                              // color: textColor,
                              color: _isBlinking
                                  ? isDarkMode
                                      ? Colors.white
                                      : Colors.black
                                  : categoryColor,
                            ),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) =>
                                    EditTaskDialog(task: widget.task),
                              );
                            },
                          ),
                  ),
                ],
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
                              // color: textColor,
                              color: _isBlinking
                                  ? isDarkMode
                                      ? Colors.white
                                      : Colors.black
                                  : categoryColor,
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
      ),
    );
  }

  Widget _overdueCheckBox() {
    return Container(
      width: 24.0,
      height: 24.0,
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(
          color: _isBlinking
              ? Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black
              : Colors.red,
          width: 2.0,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.close,
          color: _isBlinking
              ? Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black
              : Colors.red,
          size: 20.0,
        ),
      ),
    );
  }
}
