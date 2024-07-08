import 'package:todolist_app/models/task.dart';
import 'package:uuid/uuid.dart';

class TaskService {
  List<Task> _tasks = [];
  final _uuid = Uuid();

  List<Task> getTasks() {
    return List.unmodifiable(_tasks);
  }

  void setTasks(List<Task> tasks) {
    _tasks = tasks;
  }

  void addTask(String title) {
    _tasks.add(Task(id: _uuid.v4(), title: title));
  }

  void updateTask(String id, String title) {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index != -1) {
      _tasks[index] = _tasks[index].copyWith(title: title);
    }
  }

  void deleteTask(String id) {
    _tasks.removeWhere((task) => task.id == id);
  }

  void toggleTaskCompletion(String id) {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index != -1) {
      _tasks[index] = _tasks[index].copyWith(isCompleted: !_tasks[index].isCompleted);
    }
  }
}