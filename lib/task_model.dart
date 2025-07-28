import 'package:hive/hive.dart';

part 'task_model.g.dart';

@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  String category;

  @HiveField(2)
  DateTime createdAt;

  @HiveField(3)
  bool isDone;

  Task({
    required this.title,
    required this.category,
    required this.createdAt,
    this.isDone = false,
  });
}
