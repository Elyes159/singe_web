import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:system_tray/system_tray.dart';
import 'services/settings_service.dart';
import 'ui/main_window.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  final settings = SettingsService();
  await settings.init();

  // Tray is disabled for stealth during exams
  await initSystemTray();

  runApp(const MyApp());
}

Future<void> initSystemTray() async {
  String path = Platform.isWindows
      ? 'assets/app_icon.ico'
      : 'assets/app_icon.png';

  final AppWindow appWindow = AppWindow();
  final SystemTray systemTray = SystemTray();

  await systemTray.initSystemTray(title: "ChromeHelper", iconPath: path);

  final Menu menu = Menu();
  await menu.buildFrom([
    MenuItemLabel(label: 'Show/Hide', onClicked: (menuItem) => toggleWindow()),
    MenuItemLabel(label: 'Settings', onClicked: (menuItem) => openSettings()),
    MenuSeparator(),
    MenuItemLabel(label: 'Exit', onClicked: (menuItem) => exit(0)),
  ]);

  await systemTray.setContextMenu(menu);

  // Handle system tray click
  systemTray.registerSystemTrayEventHandler((eventName) {
    if (eventName == kSystemTrayEventClick) {
      toggleWindow();
    } else if (eventName == kSystemTrayEventRightClick) {
      systemTray.popUpContextMenu();
    }
  });
}

Future<void> toggleWindow() async {
  const channel = MethodChannel('com.google.chrome.helper/bridge');
  try {
    await channel.invokeMethod('toggleVisibility');
  } catch (e) {
    debugPrint("Toggle error: $e");
  }
}

void openSettings() {
  // Logic to switch to settings view
  // For now, we'll just use a GlobalKey or a simple state management
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MainWindow(),
    );
  }
}
