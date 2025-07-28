import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:todo_app/task_model.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(TaskAdapter());

  await Hive.openBox<Task>('tasks');
  await Hive.openBox('settings');

  tz.initializeTimeZones();
  final String localTimeZone = await FlutterNativeTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(localTimeZone));

  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosInit = DarwinInitializationSettings();
  const initSettings =
      InitializationSettings(android: androidInit, iOS: iosInit);
  await flutterLocalNotificationsPlugin.initialize(initSettings);

  runApp(TodoApp());
}

class TodoApp extends StatefulWidget {
  @override
  State<TodoApp> createState() => _TodoAppState();
}

class _TodoAppState extends State<TodoApp> {
  late Box settingsBox;
  late bool isDarkMode;
  late Locale _locale;

  @override
  void initState() {
    super.initState();
    settingsBox = Hive.box('settings');
    isDarkMode = settingsBox.get('darkMode', defaultValue: false);
    final savedLocale = settingsBox.get('locale', defaultValue: 'en');
    _locale = Locale(savedLocale);
  }

  void toggleTheme(bool value) {
    setState(() {
      isDarkMode = value;
      settingsBox.put('darkMode', isDarkMode);
    });
  }

  void changeLanguage(String code) {
    setState(() {
      _locale = Locale(code);
      settingsBox.put('locale', code);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: _locale,
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      debugShowCheckedModeBanner: false,
      home: TodoHomePage(
        isDarkMode: isDarkMode,
        onToggleTheme: toggleTheme,
        onChangeLanguage: changeLanguage,
        currentLanguage: _locale.languageCode,
      ),
    );
  }
}

class TodoHomePage extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onToggleTheme;
  final Function(String) onChangeLanguage;
  final String currentLanguage;

  const TodoHomePage({
    Key? key,
    required this.isDarkMode,
    required this.onToggleTheme,
    required this.onChangeLanguage,
    required this.currentLanguage,
  }) : super(key: key);

  @override
  _TodoHomePageState createState() => _TodoHomePageState();
}

class _TodoHomePageState extends State<TodoHomePage> {
  late Box<Task> taskBox;
  String selectedFilter = 'All';
  String selectedSort = 'Newest';
  String searchQuery = '';
  TextEditingController searchController = TextEditingController();

  final filterOptions = [
    'All',
    'Completed',
    'Active',
    'General',
    'Work',
    'Personal',
    'Study',
  ];

  @override
  void initState() {
    super.initState();
    taskBox = Hive.box<Task>('tasks');
  }

  void _addTask() {
    final t = AppLocalizations.of(context)!;
    String newTask = '';
    String selectedCategory = 'General';
    DateTime? selectedTime;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(t.addTask),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                autofocus: true,
                onChanged: (value) => newTask = value,
                decoration: InputDecoration(hintText: t.enterTask),
              ),
              SizedBox(height: 10),
              DropdownButton<String>(
                isExpanded: true,
                value: selectedCategory,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedCategory = value);
                  }
                },
                items: ['General', 'Work', 'Personal', 'Study']
                    .map((cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(cat),
                        ))
                    .toList(),
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Text(selectedTime == null
                      ? '${t.remindAt}: --'
                      : '${t.remindAt}: ${selectedTime!.hour}:${selectedTime!.minute.toString().padLeft(2, '0')}'),
                  Spacer(),
                  TextButton(
                    onPressed: () async {
                      final now = DateTime.now();
                      final pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (pickedTime != null) {
                        setState(() {
                          selectedTime = DateTime(
                            now.year,
                            now.month,
                            now.day,
                            pickedTime.hour,
                            pickedTime.minute,
                          );
                        });
                      }
                    },
                    child: Text(t.pickTime),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                if (newTask.trim().isNotEmpty) {
                  final now = DateTime.now();
                  final notifyTime =
                      selectedTime ?? now.add(Duration(minutes: 1));

                  taskBox.add(Task(
                    title: newTask.trim(),
                    category: selectedCategory,
                    createdAt: now,
                  ));

                  _scheduleNotification(newTask.trim(), notifyTime);
                  setState(() {});
                  Navigator.pop(context);
                }
              },
              child: Text(t.add),
            ),
          ],
        ),
      ),
    );
  }

  void _scheduleNotification(String title, DateTime when) async {
    const androidDetails = AndroidNotificationDetails(
      'todo_channel',
      'To-Do Reminders',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'Reminder',
      title,
      tz.TZDateTime.from(when, tz.local),
      details,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    final tasks = taskBox.values.toList();

    final filteredTasks = tasks.where((task) {
      final matchesStatus = selectedFilter == 'Completed'
          ? task.isDone
          : selectedFilter == 'Active'
              ? !task.isDone
              : true;

      final matchesCategory =
          ['General', 'Work', 'Personal', 'Study'].contains(selectedFilter)
              ? task.category == selectedFilter
              : true;

      final matchesSearch = searchQuery.isEmpty ||
          task.title.toLowerCase().contains(searchQuery.toLowerCase());

      return matchesStatus && matchesCategory && matchesSearch;
    }).toList();

    filteredTasks.sort((a, b) {
      switch (selectedSort) {
        case 'A → Z':
          return a.title.compareTo(b.title);
        case 'Z → A':
          return b.title.compareTo(a.title);
        case 'Newest':
          return b.createdAt.compareTo(a.createdAt);
        case 'Oldest':
          return a.createdAt.compareTo(b.createdAt);
        default:
          return 0;
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('📝 ${t.title}'),
        actions: [
          Icon(Icons.light_mode),
          Switch(
            value: widget.isDarkMode,
            onChanged: widget.onToggleTheme,
          ),
          Icon(Icons.dark_mode),
          PopupMenuButton<String>(
            onSelected: widget.onChangeLanguage,
            icon: Icon(Icons.language),
            itemBuilder: (_) => [
              PopupMenuItem(value: 'en', child: Text(t.english)),
              PopupMenuItem(value: 'ar', child: Text(t.arabic)),
            ],
          ),
          SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // فیلتر
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: selectedFilter,
              isExpanded: true,
              onChanged: (value) {
                if (value != null) setState(() => selectedFilter = value);
              },
              items: filterOptions
                  .map((cat) => DropdownMenuItem(
                        value: cat,
                        child: Text('${t.filter}: $cat'),
                      ))
                  .toList(),
            ),
          ),
          // جستجو
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: t.searchHint,
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (val) => setState(() => searchQuery = val),
            ),
          ),
          // مرتب‌سازی
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: selectedSort,
              isExpanded: true,
              onChanged: (value) {
                if (value != null) setState(() => selectedSort = value);
              },
              items: ['A → Z', 'Z → A', 'Newest', 'Oldest']
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text('${t.sort}: $s'),
                      ))
                  .toList(),
            ),
          ),
          // لیست تسک‌ها
          Expanded(
            child: filteredTasks.isEmpty
                ? Center(child: Text(t.noTasks))
                : ListView.builder(
                    itemCount: filteredTasks.length,
                    itemBuilder: (_, index) {
                      final task = filteredTasks[index];
                      return ListTile(
                        leading: Checkbox(
                          value: task.isDone,
                          onChanged: (val) {
                            task.isDone = val ?? false;
                            task.save();
                            setState(() {});
                          },
                        ),
                        title: Text(
                          task.title,
                          style: TextStyle(
                            decoration:
                                task.isDone ? TextDecoration.lineThrough : null,
                            color: task.isDone ? Colors.grey : null,
                          ),
                        ),
                        subtitle: Text(task.category),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            task.delete();
                            setState(() {});
                          },
                        ),
                      );
                    },
                  ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
        child: Icon(Icons.add),
      ),
    );
  }
}
