class TodoItem {
  final String id;
  final String title;
  final DateTime dueDate;
  final bool isCompleted;
  final String category;
  final double amount;

  TodoItem({
    required this.id,
    required this.title,
    required this.dueDate,
    required this.isCompleted,
    required this.category,
    required this.amount,
  });

  TodoItem copyWith({
    String? id,
    String? title,
    DateTime? dueDate,
    bool? isCompleted,
    String? category,
    double? amount,
  }) {
    return TodoItem(
      id: id ?? this.id,
      title: title ?? this.title,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      category: category ?? this.category,
      amount: amount ?? this.amount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'dueDate': dueDate.millisecondsSinceEpoch,
      'isCompleted': isCompleted,
      'category': category,
      'amount': amount,
    };
  }

  factory TodoItem.fromMap(Map<String, dynamic> map) {
    return TodoItem(
      id: map['id'],
      title: map['title'],
      dueDate: DateTime.fromMillisecondsSinceEpoch(map['dueDate']),
      isCompleted: map['isCompleted'],
      category: map['category'],
      amount: map['amount'],
    );
  }
} 