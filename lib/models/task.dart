import 'package:uuid/uuid.dart';

class Task {
  final String id;
  String title;
  String description;
  String category;
  DateTime? dueDate;
  bool isCompleted;
  bool isPinned;
  bool isOverdue;
  final DateTime createdAt;
  bool hasAlert;
  DateTime? alertDateTime;

  Task({
    String? id,
    required this.title,
    this.description = '',
    required this.category,
    this.dueDate,
    this.isCompleted = false,
    this.isPinned = false,
    this.isOverdue = false,
    DateTime? createdAt,
    this.hasAlert = false,
    this.alertDateTime,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Task copyWith({
    String? title,
    String? description,
    String? category,
    DateTime? dueDate,
    bool? isCompleted,
    bool? isPinned,
    bool? isOverdue,
    bool? hasAlert,
    DateTime? alertDateTime,
  }) {
    return Task(
      // id: this.id,
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      isPinned: isPinned ?? this.isPinned,
      isOverdue: isOverdue ?? this.isOverdue,
      // createdAt: this.createdAt,
      createdAt: createdAt,
      hasAlert: hasAlert ?? this.hasAlert,
      alertDateTime: alertDateTime ?? this.alertDateTime,
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
      'isPinned': isPinned,
      'isOverdue': isOverdue,
      'createdAt': createdAt.toIso8601String(),
      'hasAlert': hasAlert,
      'alertDateTime': alertDateTime?.toIso8601String(),
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String? ?? const Uuid().v4(),
      title: json['title'] as String? ?? 'Untitled Task',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'Other',
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      isCompleted: json['isCompleted'] as bool? ?? false,
      isPinned: json['isPinned'] as bool? ?? false,
      isOverdue: json['isOverdue'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      hasAlert: json['hasAlert'] as bool? ?? false,
      alertDateTime: json['alertDateTime'] != null
          ? DateTime.parse(json['alertDateTime'] as String)
          : null,
    );
  }
}
