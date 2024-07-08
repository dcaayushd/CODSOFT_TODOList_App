import 'package:flutter/foundation.dart';
import 'package:todolist_app/models/task.dart';
import 'package:todolist_app/services/task_service.dart';

class TaskProvider with ChangeNotifier {
  final TaskService _taskService = TaskService();

  List<Task> get tasks => _taskService.getTasks();

  void addTask(String title) {
    _taskService.addTask(title);
    notifyListeners();
  }

  void updateTask(String id, String title) {
    _taskService.updateTask(id, title);
    notifyListeners();
  }

  void deleteTask(String id) {
    _taskService.deleteTask(id);
    notifyListeners();
  }

  void toggleTaskCompletion(String id) {
    _taskService.toggleTaskCompletion(id);
    notifyListeners();
  }
}
