import 'package:flutter/foundation.dart';
import 'package:todolist_app/models/task.dart';
import 'package:todolist_app/services/task_service.dart';
import 'package:todolist_app/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class TaskProvider with ChangeNotifier {
  final TaskService _taskService = TaskService();
  final NotificationService _notificationService = NotificationService();
  List<String> _categories = ['Learning', 'Working', 'General', 'Other'];

  List<Task> get tasks => List.from(_taskService.getTasks());
  List<String> get categories => _categories;

  List<Task> _sortTasks(List<Task> tasks) {
    List<Task> sortedTasks = List.from(tasks);
    sortedTasks.sort((a, b) {
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1;
      }
      if (a.dueDate == null && b.dueDate == null) return 0;
      if (a.dueDate == null) return 1;
      if (b.dueDate == null) return -1;
      return a.dueDate!.compareTo(b.dueDate!);
    });
    return sortedTasks;
  }

  List<Task> get completedTasks =>
      _sortTasks(tasks.where((task) => task.isCompleted).toList());

  List<Task> get remainingTasks =>
      _sortTasks(tasks.where((task) => !task.isCompleted).toList());

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
    List<String> taskStrings =
        tasks.map((task) => json.encode(task.toJson())).toList();
    await prefs.setStringList('tasks', taskStrings);
    await prefs.setStringList('categories', _categories);
  }

  void addTask(Task task) {
    _taskService.addTask(task);
    _notificationService.scheduleNotification(task);
    _saveTasks();
    notifyListeners();

    // Schedule a re-sort after 1 minute
    Future.delayed(Duration(minutes: 1), () {
      notifyListeners();
    });
  }

  void updateTask(Task updatedTask) {
    int index =
        _taskService.getTasks().indexWhere((task) => task.id == updatedTask.id);
    if (index != -1) {
      Task existingTask = _taskService.getTasks()[index];
      updatedTask.isPinned =
          existingTask.isPinned; // Preserve the pinned status
      _taskService.updateTask(updatedTask);
      _notificationService.cancelNotification(existingTask);
      _notificationService.scheduleNotification(updatedTask);
      _saveTasks();
      notifyListeners();
    }
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

  void pinTask(String id) {
    Task task = tasks.firstWhere((task) => task.id == id);
    task.isPinned = true;
    _taskService.updateTask(task);
    _saveTasks();
    notifyListeners();
  }

  void unpinTask(String id) {
    Task task = tasks.firstWhere((task) => task.id == id);
    task.isPinned = false;
    _taskService.updateTask(task);
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
    final formattedQuery = query.toLowerCase();

    DateTime? parseDate(String input) {
      List<String> formats = [
        'MMM',
        'MMMM',
        'MM',
        'yyyy-MM-dd',
        'yyyy/MM/dd',
        'MM-dd',
        'MM/dd'
      ];

      for (var format in formats) {
        try {
          DateFormat dateFormat = DateFormat(format);
          return dateFormat.parseStrict(input);
        } catch (_) {
          continue;
        }
      }

      return null;
    }

    DateTime? searchDate = parseDate(formattedQuery);

    return _sortTasks(tasks.where((task) {
      final taskTitle = task.title.toLowerCase();
      final taskDescription = task.description.toLowerCase();
      final taskDueDate = task.dueDate;
      final taskDueDateString = taskDueDate != null
          ? DateFormat('MMM d, y').format(taskDueDate).toLowerCase()
          : '';
      final taskCategory = task.category.toLowerCase();

      bool matchesQuery = taskTitle.contains(formattedQuery) ||
          taskDescription.contains(formattedQuery) ||
          (taskDueDate != null &&
              (taskDueDateString.contains(formattedQuery) ||
                  taskDueDate == searchDate)) ||
          taskCategory.contains(formattedQuery);

      return matchesQuery;
    }).toList());
  }
}
