class Task {
  String id;
  String title;
  bool isCompleted;

  Task({required this.id, required this.title, this.isCompleted = false});

  Task copyWith({String? title, bool? isCompleted}) {
    return Task(
      id: this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      isCompleted: json['isCompleted'],
    );
  }
}