import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todolist_app/providers/task_provider.dart';
import 'package:todolist_app/providers/theme_provider.dart';
import 'package:todolist_app/widgets/task_list_item.dart';
import 'package:todolist_app/widgets/add_task_dialog.dart';

class TaskListScreen extends StatefulWidget {
  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  bool _showCompleted = false;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Todo List'),
        elevation: 0,
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return IconButton(
                icon: Icon(
                  themeProvider.isDarkMode ? Icons.wb_sunny : Icons.nights_stay,
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
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _showCompleted = false;
                  });
                },
                child: Text(
                  'Pending Tasks',
                ),
                style: TextButton.styleFrom(
                  foregroundColor: !_showCompleted
                      ? Theme.of(context).colorScheme.secondary
                      : Colors.grey,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _showCompleted = true;
                  });
                },
                style: TextButton.styleFrom(
                  foregroundColor: _showCompleted
                      ? Theme.of(context).colorScheme.secondary
                      : Colors.grey,
                ),
                child: Text('Completed Tasks'),
              ),
            ],
          ),
          Container(
            height: 2,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    color: !_showCompleted
                        ? Theme.of(context).colorScheme.secondary
                        : Colors.transparent,
                  ),
                ),
                Expanded(
                  child: Container(
                    color: _showCompleted
                        ? Theme.of(context).colorScheme.secondary
                        : Colors.transparent,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<TaskProvider>(
              builder: (context, taskProvider, child) {
                final filteredTasks = _searchQuery.isEmpty
                    ? (_showCompleted
                        ? taskProvider.completedTasks
                        : taskProvider.remainingTasks)
                    : taskProvider.searchTasks(_searchQuery);

                if (filteredTasks.isEmpty) {
                  return Center(
                    child: Text('No tasks yet'),
                  );
                }

                return ListView.builder(
                  itemCount: filteredTasks.length,
                  itemBuilder: (context, index) {
                    final task = filteredTasks[index];
                    return Dismissible(
                      key: Key(task.id),
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.only(right: 20),
                        child: Icon(Icons.delete, color: Colors.white),
                      ),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) {
                        taskProvider.deleteTask(task.id);
                      },
                      child: TaskListItem(task: task),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AddTaskDialog(),
          );
        },
        icon: Icon(Icons.add),
        label: Text('Add Task'),
      ),
    );
  }
}
