import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../providers/task_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/add_task_dialog.dart';
import '../widgets/delete_task_dialog.dart';
import '../widgets/task_list_item.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  TaskListScreenState createState() => TaskListScreenState();
}

class TaskListScreenState extends State<TaskListScreen> {
  String _searchQuery = '';
  DateTime? _lastAddedTaskTime;
  late PageController _pageController;
  final ValueNotifier<int> _currentPageNotifier = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    Future.microtask(() {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      taskProvider.checkAndUpdateOverdueTasks();
      taskProvider.startPeriodicOverdueCheck();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _currentPageNotifier.dispose();
    Provider.of<TaskProvider>(context, listen: false)
        .stopPeriodicOverdueCheck();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        Map<String, List<Task>> categorizedTasks = _searchQuery.isEmpty
            ? {
                'pending': taskProvider.pendingTasks,
                'completed': taskProvider.completedTasks,
                'overdue': taskProvider.overdueTasks,
              }
            : taskProvider.searchTasks(_searchQuery);

        return Scaffold(
          body: Column(
            children: [
              _buildTopContainer(context, categorizedTasks),
              Expanded(
                child: _buildTaskListContent(categorizedTasks),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              final result = await showDialog(
                context: context,
                builder: (context) => const AddTaskDialog(),
              );
              if (result == true) {
                setState(() {
                  _lastAddedTaskTime = DateTime.now();
                });
                // Reset the highlight after 1 minute
                Future.delayed(const Duration(minutes: 1), () {
                  setState(() {
                    _lastAddedTaskTime = null;
                  });
                });
              }
            },
            icon: const Icon(CupertinoIcons.add),
            label: const Text('Add Task'),
          ),
        );
      },
    );
  }

  Widget _buildTopContainer(
      BuildContext context, Map<String, List<Task>> categorizedTasks) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF4B3986) : const Color(0xFFE7DEFD),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(35),
          bottomRight: Radius.circular(35),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Spacer(),
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: Text(
                        'Todo List',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: Icon(
                          isDarkMode
                              ? CupertinoIcons.sun_max
                              : CupertinoIcons.moon,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                        onPressed: () {
                          themeProvider.toggleTheme();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search tasks',
                  hintStyle: TextStyle(
                      color: (isDarkMode ? Colors.white : Colors.black)
                          .withOpacity(0.7)),
                  prefixIcon: Icon(CupertinoIcons.search,
                      color: isDarkMode ? Colors.white : Colors.black),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: (isDarkMode ? Colors.white : Colors.black)
                      .withOpacity(0.1),
                ),
                style:
                    TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ValueListenableBuilder<int>(
                valueListenable: _currentPageNotifier,
                builder: (context, currentPage, child) {
                  return Row(
                    children: [
                      _buildCategoryButton(context, 'Pending',
                          categorizedTasks['pending']!.length, 0, currentPage),
                      _buildCategoryButton(
                          context,
                          'Completed',
                          categorizedTasks['completed']!.length,
                          1,
                          currentPage),
                      _buildCategoryButton(context, 'Overdue',
                          categorizedTasks['overdue']!.length, 2, currentPage),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskListContent(Map<String, List<Task>> categorizedTasks) {
    return PageView(
      controller: _pageController,
      onPageChanged: (index) {
        _currentPageNotifier.value = index;
      },
      children: [
        _buildTaskList(categorizedTasks['pending']!, false),
        _buildTaskList(categorizedTasks['completed']!, true),
        _buildTaskList(categorizedTasks['overdue']!, false, isOverdue: true),
      ],
    );
  }

  Widget _buildCategoryButton(BuildContext context, String title, int count,
      int page, int currentPage) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () {
              _pageController.animateToPage(page,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: currentPage == page
                        ? (isDarkMode ? Colors.white : Colors.black)
                        : (isDarkMode ? Colors.white70 : Colors.black54),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: currentPage == page
                        ? (isDarkMode ? Colors.white : Colors.black)
                        : (isDarkMode ? Colors.white70 : Colors.black54),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 3,
            width: 40,
            decoration: BoxDecoration(
              color: currentPage == page
                  ? (isDarkMode ? Colors.white : Colors.black)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(List<Task> tasks, bool showCompleted,
      {bool isOverdue = false}) {
    if (tasks.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isEmpty
              ? 'No ${isOverdue ? 'overdue' : showCompleted ? 'completed' : 'pending'} tasks'
              : 'No matching tasks in this category',
        ),
      );
    }

    return ListView.builder(
      // padding: EdgeInsets.zero,
      // padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        final isNewlyAdded = _lastAddedTaskTime != null &&
            task.createdAt.isAfter(_lastAddedTaskTime!);

        return Dismissible(
          key: Key(task.id),
          background: Container(
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(CupertinoIcons.delete, color: Colors.white),
          ),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            final result = await showDialog(
              context: context,
              builder: (context) => DeleteTaskDialog(taskTitle: task.title),
            );
            return result == true;
          },
          onDismissed: (direction) {
            Provider.of<TaskProvider>(context, listen: false)
                .deleteTask(task.id);
          },
          child: AnimatedContainer(
            duration: const Duration(seconds: 1),
            curve: Curves.easeInOut,
            color: isNewlyAdded ? Colors.yellow.withOpacity(0.3) : null,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 2),
              decoration: BoxDecoration(
                color: isNewlyAdded ? Colors.yellow.withOpacity(0.3) : null,
                borderRadius: BorderRadius.circular(20),
              ),
              child: TaskListItem(task: task, isFirstTask: index == 0),
            ),
          ),
        );
      },
    );
  }
}
