import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../managers/theme_manager.dart' as theme_manager;

class AppearanceSettingsPage extends StatefulWidget {
  const AppearanceSettingsPage({super.key});

  @override
  State<AppearanceSettingsPage> createState() => _AppearanceSettingsPageState();
}

class _AppearanceSettingsPageState extends State<AppearanceSettingsPage> {
  theme_manager.ThemeMode _selectedThemeMode = theme_manager.ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  void _loadThemeMode() {
    final themeManager = Provider.of<theme_manager.ThemeManager>(context, listen: false);
    setState(() {
      _selectedThemeMode = themeManager.themeMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<theme_manager.ThemeManager>(context);
    _selectedThemeMode = themeManager.themeMode;

    return Scaffold(
      appBar: AppBar(title: const Text('外观设置')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              '主题模式',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          RadioListTile<theme_manager.ThemeMode>(
            title: const Text('浅色模式'),
            secondary: const Icon(Icons.light_mode),
            value: theme_manager.ThemeMode.light,
            groupValue: _selectedThemeMode,
            onChanged: _setThemeMode,
          ),
          RadioListTile<theme_manager.ThemeMode>(
            title: const Text('深色模式'),
            secondary: const Icon(Icons.dark_mode),
            value: theme_manager.ThemeMode.dark,
            groupValue: _selectedThemeMode,
            onChanged: _setThemeMode,
          ),
          RadioListTile<theme_manager.ThemeMode>(
            title: const Text('跟随系统'),
            secondary: const Icon(Icons.auto_mode),
            value: theme_manager.ThemeMode.system,
            groupValue: _selectedThemeMode,
            onChanged: _setThemeMode,
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              '选择"跟随系统"将根据您设备的系统设置自动切换浅色和深色模式。',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _setThemeMode(theme_manager.ThemeMode? mode) async {
    if (mode != null) {
      final themeManager = Provider.of<theme_manager.ThemeManager>(context, listen: false);
      await themeManager.setThemeMode(mode);

      // 显示确认信息
      if (mounted) {
        String message;
        switch (mode) {
          case theme_manager.ThemeMode.light:
            message = '已切换到浅色模式';
            break;
          case theme_manager.ThemeMode.dark:
            message = '已切换到深色模式';
            break;
          case theme_manager.ThemeMode.system:
            message = '已设置为跟随系统';
            break;
        }
        
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }
}
