import 'package:flutter/foundation.dart';
import 'package:todolist_app/models/task.dart';
import 'package:todolist_app/services/task_service.dart';
import 'package:todolist_app/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'dart:async';

class TaskProvider with ChangeNotifier {
  final TaskService _taskService = TaskService();
  final NotificationService _notificationService = NotificationService();
  List<String> _categories = ['Learning', 'Working', 'General', 'Other'];
  Timer? _overdueCheckTimer;

  List<Task> get tasks => List.from(_taskService.getTasks());
  List<String> get categories => _categories;

  List<Task> get overdueTasks => _sortTasks(tasks
      .where((task) =>
          task.dueDate != null &&
          task.dueDate!.isBefore(DateTime.now()) &&
          !task.isCompleted)
      .toList());

  Future<void> checkAndUpdateOverdueTasks() async {
    final now = DateTime.now();
    bool hasChanges = false;

    for (var task in tasks) {
      if (task.dueDate != null &&
          task.dueDate!.isBefore(now) &&
          !task.isCompleted &&
          !task.isOverdue) {
        task.isOverdue = true;
        hasChanges = true;
      }
    }

    if (hasChanges) {
      await _saveTasks();
      notifyListeners();
    }
  }

  void startPeriodicOverdueCheck() {
    // Check for overdue tasks every minute
    _overdueCheckTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      checkAndUpdateOverdueTasks();
    });
  }

  void stopPeriodicOverdueCheck() {
    _overdueCheckTimer?.cancel();
    _overdueCheckTimer = null;
  }

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

  List<Task> get remainingTasks => _sortTasks(
      tasks.where((task) => !task.isCompleted && !task.isOverdue).toList());

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
      await checkAndUpdateOverdueTasks();
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

  Future<void> addTask(Task task) async {
    _taskService.addTask(task);
    _notificationService.scheduleNotification(task);
    await checkAndUpdateOverdueTasks();
    await _saveTasks();
    notifyListeners();
  }

  Future<void> updateTask(Task updatedTask) async {
    int index =
        _taskService.getTasks().indexWhere((task) => task.id == updatedTask.id);
    if (index != -1) {
      Task existingTask = _taskService.getTasks()[index];
      updatedTask.isPinned = existingTask.isPinned;
      _taskService.updateTask(updatedTask);
      _notificationService.cancelNotification(existingTask);
      _notificationService.scheduleNotification(updatedTask);
      await _saveTasks();
      notifyListeners();
    }
  }

  Future<void> deleteTask(String id) async {
    _taskService.deleteTask(id);
    await _saveTasks();
    notifyListeners();
  }

  Future<void> toggleTaskCompletion(String id) async {
    _taskService.toggleTaskCompletion(id);
    Task task = tasks.firstWhere((task) => task.id == id);
    if (task.isCompleted) {
      _notificationService.cancelNotification(task);
    } else {
      _notificationService.scheduleNotification(task);
    }
    await _saveTasks();
    notifyListeners();
  }

  Future<void> pinTask(String id) async {
    Task task = tasks.firstWhere((task) => task.id == id);
    task.isPinned = true;
    _taskService.updateTask(task);
    await _saveTasks();
    notifyListeners();
  }

  Future<void> unpinTask(String id) async {
    Task task = tasks.firstWhere((task) => task.id == id);
    task.isPinned = false;
    _taskService.updateTask(task);
    await _saveTasks();
    notifyListeners();
  }

  Future<void> addCategory(String category) async {
    if (!_categories.contains(category)) {
      _categories.add(category);
      await _saveTasks();
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
