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
          appBar: AppBar(
            centerTitle: true,
            title: const Text('Todo List'),
            elevation: 0,
            actions: [
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, child) {
                  return IconButton(
                    icon: Icon(
                      themeProvider.isDarkMode
                          ? CupertinoIcons.sun_max
                          : CupertinoIcons.moon,
                    ),
                    onPressed: () {
                      themeProvider.toggleTheme();
                    },
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search tasks',
                    prefixIcon: const Icon(CupertinoIcons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              ValueListenableBuilder<int>(
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
              SizedBox(
                height: 2,
                child: ValueListenableBuilder<int>(
                  valueListenable: _currentPageNotifier,
                  builder: (context, currentPage, child) {
                    return Row(
                      children: [
                        Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            color: currentPage == 0
                                ? Theme.of(context).colorScheme.secondary
                                : Colors.transparent,
                          ),
                        ),
                        Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            color: currentPage == 1
                                ? Theme.of(context).colorScheme.secondary
                                : Colors.transparent,
                          ),
                        ),
                        Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            color: currentPage == 2
                                ? Theme.of(context).colorScheme.secondary
                                : Colors.transparent,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    _currentPageNotifier.value = index;
                  },
                  children: [
                    _buildTaskList(categorizedTasks['pending']!, false),
                    _buildTaskList(categorizedTasks['completed']!, true),
                    _buildTaskList(categorizedTasks['overdue']!, false,
                        isOverdue: true),
                  ],
                ),
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

  Widget _buildCategoryButton(BuildContext context, String title, int count,
      int page, int currentPage) {
    return Expanded(
      child: TextButton(
        onPressed: () {
          _pageController.animateToPage(page,
              duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        },
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$title ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: currentPage == page
                      ? Theme.of(context).colorScheme.secondary
                      : Colors.grey,
                ),
              ),
              Text(
                '($count)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: currentPage == page
                      ? Theme.of(context).colorScheme.secondary
                      : Colors.grey,
                ),
              ),
            ],
          ),
        ),
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
              borderRadius: BorderRadius.circular(12),
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
            child: TaskListItem(task: task, isFirstTask: index == 0),
          ),
        );
      },
    );
  }
}
