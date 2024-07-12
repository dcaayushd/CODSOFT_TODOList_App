import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../providers/task_provider.dart';
import '../utils/utils.dart';
import '../widgets/delete_task_dialog.dart';
import '../widgets/edit_task_dialog.dart';

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
  late TaskProvider taskProvider;
  bool _isClosing = false;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    taskProvider = Provider.of<TaskProvider>(context, listen: false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _closeContainer() {
    if (!_isClosing && mounted) {
      setState(() {
        _isClosing = true;
      });
      _controller.reverse().then((_) {
        if (mounted) {
          widget.onClose();
        }
      });
    }
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
                        taskProvider.unpinTask(widget.task.id);
                      } else {
                        taskProvider.pinTask(widget.task.id);
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
                      _closeContainer();
                      showDialog(
                        context: context,
                        builder: (context) =>
                            DeleteTaskDialog(taskTitle: widget.task.title),
                      ).then((result) {
                        if (result == true) {
                          taskProvider.deleteTask(widget.task.id);
                        }
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
