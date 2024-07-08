import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todolist_app/providers/task_provider.dart';
import 'package:todolist_app/screens/task_list_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => TaskProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'TODO List',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          brightness: Brightness.light,
          fontFamily: 'Roboto',
        ),
        darkTheme: ThemeData(
          primarySwatch: Colors.blue,
          brightness: Brightness.dark,
          fontFamily: 'Roboto',
        ),
        themeMode: ThemeMode.system,
        home: const TaskListScreen(),
      ),
    );
  }
}
