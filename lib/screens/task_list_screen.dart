import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:todolist_app/providers/task_provider.dart';
import 'package:todolist_app/providers/theme_provider.dart';
import 'package:todolist_app/widgets/task_list_item.dart';
import 'package:todolist_app/widgets/add_task_dialog.dart';
import 'package:todolist_app/widgets/delete_task_dialog.dart';

import '../models/task.dart';

class TaskListScreen extends StatefulWidget {
  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
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
        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: Text('Todo List'),
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
                    prefixIcon: Icon(CupertinoIcons.search),
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
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            _pageController.animateToPage(0,
                                duration: Duration(milliseconds: 300),
                                curve: Curves.easeInOut);
                          },
                          child: Text(
                            'Remaining Tasks (${taskProvider.remainingTasks.length})',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: currentPage == 0
                                  ? Theme.of(context).colorScheme.secondary
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            _pageController.animateToPage(1,
                                duration: Duration(milliseconds: 300),
                                curve: Curves.easeInOut);
                          },
                          child: Text(
                            'Completed Tasks (${taskProvider.completedTasks.length})',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: currentPage == 1
                                  ? Theme.of(context).colorScheme.secondary
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            _pageController.animateToPage(2,
                                duration: Duration(milliseconds: 300),
                                curve: Curves.easeInOut);
                          },
                          child: Text(
                            'Overdue Tasks (${taskProvider.overdueTasks.length})',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: currentPage == 2
                                  ? Theme.of(context).colorScheme.secondary
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              Container(
                height: 2,
                child: ValueListenableBuilder<int>(
                  valueListenable: _currentPageNotifier,
                  builder: (context, currentPage, child) {
                    return Row(
                      children: [
                        Expanded(
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 300),
                            color: currentPage == 0
                                ? Theme.of(context).colorScheme.secondary
                                : Colors.transparent,
                          ),
                        ),
                        Expanded(
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 300),
                            color: currentPage == 1
                                ? Theme.of(context).colorScheme.secondary
                                : Colors.transparent,
                          ),
                        ),
                        Expanded(
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 300),
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
                    _buildTaskList(taskProvider, false),
                    _buildTaskList(taskProvider, true),
                    _buildOverdueTaskList(taskProvider),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              final result = await showDialog(
                context: context,
                builder: (context) => AddTaskDialog(),
              );
              if (result == true) {
                setState(() {
                  _lastAddedTaskTime = DateTime.now();
                });
                // Reset the highlight after 1 minute
                Future.delayed(Duration(minutes: 1), () {
                  setState(() {
                    _lastAddedTaskTime = null;
                  });
                });
              }
            },
            icon: Icon(CupertinoIcons.add),
            label: Text('Add Task'),
          ),
        );
      },
    );
  }

  Widget _buildTaskList(TaskProvider taskProvider, bool showCompleted) {
    final List<Task> filteredTasks;
    if (_searchQuery.isEmpty) {
      filteredTasks = showCompleted
          ? taskProvider.completedTasks
          : taskProvider.remainingTasks;
    } else {
      final searchResults = taskProvider.searchTasks(_searchQuery);
      filteredTasks = showCompleted
          ? searchResults['completed']!
          : searchResults['remaining']!;
    }

    if (filteredTasks.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isEmpty
              ? 'No tasks yet'
              : 'No matching tasks in this category',
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredTasks.length,
      itemBuilder: (context, index) {
        final task = filteredTasks[index];
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
            padding: EdgeInsets.only(right: 20),
            child: Icon(CupertinoIcons.delete, color: Colors.white),
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
            taskProvider.deleteTask(task.id);
          },
          child: AnimatedContainer(
            duration: Duration(seconds: 1),
            curve: Curves.easeInOut,
            color: isNewlyAdded ? Colors.yellow.withOpacity(0.3) : null,
            child: TaskListItem(task: task),
          ),
        );
      },
    );
  }

  Widget _buildOverdueTaskList(TaskProvider taskProvider) {
    final List<Task> filteredTasks;
    if (_searchQuery.isEmpty) {
      filteredTasks = taskProvider.overdueTasks;
    } else {
      final searchResults = taskProvider.searchTasks(_searchQuery);
      filteredTasks = searchResults['overdue']!;
    }

    if (filteredTasks.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isEmpty
              ? 'No overdue tasks'
              : 'No matching overdue tasks',
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredTasks.length,
      itemBuilder: (context, index) {
        final task = filteredTasks[index];
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
            padding: EdgeInsets.only(right: 20),
            child: Icon(CupertinoIcons.delete, color: Colors.white),
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
            taskProvider.deleteTask(task.id);
          },
          child: AnimatedContainer(
            duration: Duration(seconds: 1),
            curve: Curves.easeInOut,
            color: isNewlyAdded ? Colors.yellow.withOpacity(0.3) : null,
            child: TaskListItem(task: task),
          ),
        );
      },
    );
  }
}