import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'task_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(TaskAdapter());

  await Hive.openBox<Task>('tasks');
  await Hive.openBox('settings');

  runApp(TodoApp());
}

class TodoApp extends StatefulWidget {
  @override
  State<TodoApp> createState() => _TodoAppState();
}

class _TodoAppState extends State<TodoApp> {
  late Box settingsBox;
  late bool isDarkMode;

  @override
  void initState() {
    super.initState();
    settingsBox = Hive.box('settings');
    isDarkMode = settingsBox.get('darkMode', defaultValue: false);
  }

  void toggleTheme(bool value) {
    setState(() {
      isDarkMode = value;
      settingsBox.put('darkMode', isDarkMode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To-Do App',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: TodoHomePage(
        isDarkMode: isDarkMode,
        onToggleTheme: toggleTheme,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class TodoHomePage extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onToggleTheme;

  const TodoHomePage({
    Key? key,
    required this.isDarkMode,
    required this.onToggleTheme,
  }) : super(key: key);

  @override
  _TodoHomePageState createState() => _TodoHomePageState();
}

class _TodoHomePageState extends State<TodoHomePage> {
  late Box<Task> taskBox;
  String selectedFilter = 'All';

  String searchQuery = '';
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    taskBox = Hive.box<Task>('tasks');
  }

  void _addTask() {
    String newTask = '';
    String selectedCategory = 'General';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              autofocus: true,
              onChanged: (value) {
                newTask = value;
              },
              decoration: InputDecoration(hintText: 'Enter task...'),
            ),
            SizedBox(height: 10),
            DropdownButton<String>(
              isExpanded: true,
              value: selectedCategory,
              onChanged: (value) {
                if (value != null) {
                  selectedCategory = value;
                }
              },
              items: ['General', 'Work', 'Personal', 'Study']
                  .map((category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ))
                  .toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (newTask.trim().isNotEmpty) {
                taskBox.add(Task(
                  title: newTask.trim(),
                  category: selectedCategory,
                ));
                setState(() {});
                Navigator.pop(context);
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  void _removeTask(int index) {
    taskBox.deleteAt(index);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('📝 My Tasks'),
        actions: [
          Row(
            children: [
              Icon(Icons.light_mode),
              Switch(
                value: widget.isDarkMode,
                onChanged: widget.onToggleTheme,
              ),
              Icon(Icons.dark_mode),
              SizedBox(width: 8),
            ],
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: selectedFilter,
              isExpanded: true,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedFilter = value;
                  });
                }
              },
              items: ['All', 'General', 'Work', 'Personal', 'Study']
                  .map((category) => DropdownMenuItem(
                        value: category,
                        child: Text('Show: $category'),
                      ))
                  .toList(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search tasks...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),
          ),
          Expanded(
            child: taskBox.isEmpty
                ? Center(
                    child: Text(
                      'No tasks yet...',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: taskBox.length,
                    itemBuilder: (context, index) {
                      final task = taskBox.getAt(index);
                      if (selectedFilter == 'All' ||
                          task?.category == selectedFilter) {
                        return ListTile(
                          title: Text(task?.title ?? ''),
                          subtitle:
                              Text('Category: ${task?.category ?? "N/A"}'),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeTask(index),
                          ),
                        );
                      } else {
                        return SizedBox.shrink();
                      }
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
        child: Icon(Icons.add),
        tooltip: 'Add Task',
      ),
    );
  }
}
