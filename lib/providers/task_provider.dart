import 'package:flutter/foundation.dart';
import 'package:todolist_app/models/task.dart';
import 'package:todolist_app/services/task_service.dart';
import 'package:todolist_app/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class TaskProvider with ChangeNotifier {
  final TaskService _taskService = TaskService();
  final NotificationService _notificationService = NotificationService();
  List<String> _categories = ['Personal', 'Work', 'Shopping', 'Other'];

  List<Task> get tasks => _taskService.getTasks();
  List<String> get categories => _categories;

  List<Task> get completedTasks => tasks.where((task) => task.isCompleted).toList();
  List<Task> get remainingTasks => tasks.where((task) => !task.isCompleted).toList();

  TaskProvider() {
    _notificationService.init();
  }

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
    _categories = prefs.getStringList('categories') ?? _categories;
  }

  Future<void> _saveTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> taskStrings = tasks
        .map((task) => json.encode(task.toJson()))
        .toList();
    await prefs.setStringList('tasks', taskStrings);
    await prefs.setStringList('categories', _categories);
  }

  void addTask(Task task) {
    _taskService.addTask(task);
    _notificationService.scheduleNotification(task);
    _saveTasks();
    notifyListeners();
  }

  void updateTask(Task updatedTask) {
    _taskService.updateTask(updatedTask);
    _notificationService.cancelNotification(updatedTask);
    _notificationService.scheduleNotification(updatedTask);
    _saveTasks();
    notifyListeners();
  }

  void deleteTask(String id) {
    Task task = tasks.firstWhere((task) => task.id == id);
    _taskService.deleteTask(id);
    _notificationService.cancelNotification(task);
    _saveTasks();
    notifyListeners();
  }

  void toggleTaskCompletion(String id) {
    _taskService.toggleTaskCompletion(id);
    Task task = tasks.firstWhere((task) => task.id == id);
    if (task.isCompleted) {
      _notificationService.cancelNotification(task);
    } else {
      _notificationService.scheduleNotification(task);
    }
    _saveTasks();
    notifyListeners();
  }

  void addCategory(String category) {
    if (!_categories.contains(category)) {
      _categories.add(category);
      _saveTasks();
      notifyListeners();
    }
  }

  List<Task> searchTasks(String query) {
    return tasks.where((task) =>
        task.title.toLowerCase().contains(query.toLowerCase()) ||
        task.description.toLowerCase().contains(query.toLowerCase())).toList();
  }
}