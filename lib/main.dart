import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todolist_app/providers/task_provider.dart';
import 'package:todolist_app/providers/theme_provider.dart';
import 'package:todolist_app/screens/task_list_screen.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final taskProvider = TaskProvider();
  await taskProvider.loadTasks();
  final themeProvider = ThemeProvider();
  await themeProvider.loadThemePreference();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: taskProvider),
        ChangeNotifierProvider.value(value: themeProvider),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Todo List App',
          theme: ThemeData(
            brightness: Brightness.light,
            // appBarTheme: const AppBarTheme(color: Color(0xFFF6F0EB)),
            // scaffoldBackgroundColor: const Color(0xFFF6F0EB),
            // dialogBackgroundColor: const Color(0xFFF6F0EB),
            primarySwatch: Colors.blue,
            textTheme: GoogleFonts.poppinsTextTheme(
              Theme.of(context).textTheme,
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            // appBarTheme: const AppBarTheme(color: Color(0xFF3F3E45)),
            // scaffoldBackgroundColor: const Color(0xFF3F3E45),
            // dialogBackgroundColor: const Color(0xFF3F3E45),
            primarySwatch: Colors.blue,
            textTheme: GoogleFonts.poppinsTextTheme(
              Theme.of(context).textTheme.apply(bodyColor: Colors.white),
            ),
          ),
          themeMode:
              themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const TaskListScreen(),
        );
      },
    );
  }
}
