import '../models/task.dart';

class TaskService {
  List<Task> _tasks = [];

  List<Task> getTasks() {
    return List.unmodifiable(_tasks);
  }

  void setTasks(List<Task> tasks) {
    _tasks = tasks;
  }

  void addTask(Task task) {
    _tasks.add(task);
  }

  void updateTask(Task updatedTask) {
    final index = _tasks.indexWhere((task) => task.id == updatedTask.id);
    if (index != -1) {
      _tasks[index] = updatedTask;
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