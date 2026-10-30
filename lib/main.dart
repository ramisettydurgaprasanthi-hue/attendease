import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/subject_provider.dart';
import 'providers/task_provider.dart';
import 'screens/main_shell.dart';
import 'services/notification_service.dart';
import 'theme/ui_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();

  final subjects = SubjectProvider();
  final tasks = TaskProvider();
  await subjects.load();
  await tasks.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: subjects),
        ChangeNotifierProvider.value(value: tasks),
      ],
      child: const MyApp(),
    ),
  );
}

ThemeData _buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final background = dark ? const Color(0xFF0F1117) : const Color(0xFFF4F5FA);
  final scheme = ColorScheme.fromSeed(
    seedColor: UiColors.primary,
    brightness: brightness,
  );
  final buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(14),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: background,
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 68,
      backgroundColor: dark ? const Color(0xFF1B1D27) : Colors.white,
      indicatorColor: UiColors.primary.withOpacity(0.15),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(shape: buttonShape),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(shape: buttonShape),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.select<SubjectProvider, bool>((p) => p.isDark);
    return MaterialApp(
      title: 'Attendance Tracker',
      debugShowCheckedModeBanner: false,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      home: const MainShell(),
      builder: (context, child) => ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: child,
          ),
        ),
      ),
    );
  }
}