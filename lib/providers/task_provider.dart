import 'package:flutter/foundation.dart';
import 'package:todolist_app/models/task.dart';
import 'package:todolist_app/services/task_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class TaskProvider with ChangeNotifier {
  final TaskService _taskService = TaskService();

  List<Task> get tasks => _taskService.getTasks();

  Future<void> loadTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? taskStrings = prefs.getStringList('tasks');
    if (taskStrings != null) {
      List<Task> loadedTasks = taskStrings
          .map((taskString) => Task.fromJson(json.decode(taskString)))
          .toList();
      _taskService.setTasks(loadedTasks);
      notifyListeners();
    }
  }

  Future<void> _saveTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> taskStrings = tasks
        .map((task) => json.encode(task.toJson()))
        .toList();
    await prefs.setStringList('tasks', taskStrings);
  }

  void addTask(String title) {
    _taskService.addTask(title);
    _saveTasks();
    notifyListeners();
  }

  void updateTask(String id, String title) {
    _taskService.updateTask(id, title);
    _saveTasks();
    notifyListeners();
  }

  void deleteTask(String id) {
    _taskService.deleteTask(id);
    _saveTasks();
    notifyListeners();
  }

  void toggleTaskCompletion(String id) {
    _taskService.toggleTaskCompletion(id);
    _saveTasks();
    notifyListeners();
  }
}