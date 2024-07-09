import 'package:uuid/uuid.dart';

class Task {
  final String id;
  String title;
  String description;
  String category;
  DateTime? dueDate;
  bool isCompleted;

  Task({
    String? id,
    required this.title,
    this.description = '',
    required this.category,
    this.dueDate,
    this.isCompleted = false,
  }) : id = id ?? Uuid().v4();

  Task copyWith({
    String? title,
    String? description,
    String? category,
    DateTime? dueDate,
    bool? isCompleted,
  }) {
    return Task(
      id: this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'dueDate': dueDate?.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String? ?? Uuid().v4(),
      title: json['title'] as String? ?? 'Untitled Task',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'Other',
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate'] as String) : null,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}