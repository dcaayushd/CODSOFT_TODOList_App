import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todolist_app/providers/task_provider.dart';

import 'package:todolist_app/widgets/task_list_item.dart';
import 'package:todolist_app/widgets/add_task_dialog.dart';

import '../providers/theme.provider.dart';

class TaskListScreen extends StatelessWidget {
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
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          return ListView.builder(
            itemCount: taskProvider.tasks.length,
            itemBuilder: (context, index) {
              final task = taskProvider.tasks[index];
              return TaskListItem(task: task);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AddTaskDialog(),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
