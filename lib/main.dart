import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'managers/theme_manager.dart' as theme_manager;
import 'pages/appointment_page.dart';
import 'pages/history_page.dart';
import 'pages/settings_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();


  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
    overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
  );

  final themeManager = theme_manager.ThemeManager();

  runApp(
    ChangeNotifierProvider(create: (_) => themeManager, child: const MyApp()),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? token;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      token = prefs.getString('token');
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<theme_manager.ThemeManager>(context);

    return MaterialApp(
      title: 'FLCT Alpha',
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: _getThemeMode(themeManager.themeMode),
      home:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : (token != null ? const HomePage() : const TokenInputPage()),
    );
  }

  // Convert our ThemeMode enum to Flutter's ThemeMode
  ThemeMode _getThemeMode(theme_manager.ThemeMode mode) {
    switch (mode) {
      case theme_manager.ThemeMode.light:
        return ThemeMode.light;
      case theme_manager.ThemeMode.dark:
        return ThemeMode.dark;
      case theme_manager.ThemeMode.system:
        return ThemeMode.system;
    }
  }

  // Build light theme data
  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
    );
  }

  // Build dark theme data
  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
      ),
    );
  }
}

class TokenInputPage extends StatefulWidget {
  const TokenInputPage({super.key});

  @override
  State<TokenInputPage> createState() => _TokenInputPageState();
}

class _TokenInputPageState extends State<TokenInputPage> {
  final _tokenController = TextEditingController();
  final _prefs = SharedPreferences.getInstance();
  bool _showWebView = false;
  bool _isLoading = false;
  late final WebViewController _webViewController;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _webViewController =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onNavigationRequest: (NavigationRequest request) {
                final url = request.url;
                if (url.startsWith('http://')) {
                  final httpsUrl = url.replaceFirst('http://', 'https://');
                  _webViewController.loadRequest(Uri.parse(httpsUrl));
                  return NavigationDecision.prevent;
                }
                return NavigationDecision.navigate;
              },
              onUrlChange: (UrlChange change) {
                if (change.url != null && change.url!.contains('token=')) {
                  final uri = Uri.parse(change.url!);
                  final token = uri.queryParameters['token'];
                  if (token != null) {
                    _tokenController.text = token;
                    setState(() {
                      _showWebView = false;
                    });
                  }
                }
              },
            ),
          );
  }

  void _openWebView() {
    setState(() {
      _showWebView = true;
      _webViewController.loadRequest(
        Uri.parse('https://aiot.fzu.edu.cn/api/ibs'),
      );
    });
  }

  Future<void> _saveToken() async {
    if (_tokenController.text.isEmpty) {
      _showSnackBar('请输入token');
      return;
    }

    setState(() => _isLoading = true);

    final bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('注意'),
          content: const SingleChildScrollView(
            child: Text(
              '1. 请勿滥用，本软件仅用于学习和测试！请在24小时之内卸载该软件\n\n'
              '2. 利用本软件或其提供的接口、文档等造成不良影响及后果与本人无关\n\n'
              '3. 请妥善保管 token 值。\n\n'
              '4. 软件目前还在开发中，目前仍是 Alpha 版本，可能存在功能缺失、bug等情况。',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('拒绝'),
              onPressed: () {
                Navigator.of(context).pop(false);
                SystemNavigator.pop();
              },
            ),
            TextButton(
              child: const Text('接受'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (result == true) {
      final prefs = await _prefs;
      await prefs.setString('token', _tokenController.text);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('输入Token'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions:
            _showWebView
                ? [
                  TextButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('完成登录'),
                    onPressed: () async {
                      final currentUrl = await _webViewController.currentUrl();
                      if (currentUrl != null && currentUrl.contains('token=')) {
                        final tokenIndex = currentUrl.indexOf('token=');
                        final token = currentUrl.substring(tokenIndex + 6);
                        setState(() {
                          _tokenController.text = token;
                          _showWebView = false;
                        });
                        return;
                      }
                      if (!mounted) return;
                      _showSnackBar('未能获取到有效的token，请重试');
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _showWebView = false),
                  ),
                ]
                : null,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _showWebView
              ? WebViewWidget(controller: _webViewController)
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      child: const Text(
                        '获取Token说明：\n\n自动获取：点击下方的"自动获取"按钮，完成登录后点击右上角的完成登录，系统会自动填入token\n\n注意：token是您的身份凭证，请妥善保管',
                        style: TextStyle(fontSize: 16),
                        textAlign: TextAlign.left,
                      )
                    ),
                    TextField(
                      controller: _tokenController,
                      decoration: const InputDecoration(
                        labelText: 'Token',
                        border: OutlineInputBorder(),
                        hintText: '请输入您的token',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: _saveToken,
                          child: const Text('确认'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: _openWebView,
                          icon: const Icon(Icons.web),
                          label: const Text('自动获取'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
    );
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final List<Widget> _pages = const [AppointmentPage(), HistoryPage()];
  final List<String> _titles = const ['FLCT Alpha', '预约历史'];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarColor: colorScheme.surface,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness:
            brightness == Brightness.light ? Brightness.dark : Brightness.light,
        statusBarIconBrightness:
            brightness == Brightness.light ? Brightness.dark : Brightness.light,
        statusBarBrightness:
            brightness == Brightness.light ? Brightness.light : Brightness.dark,
      ),
    );

    return Scaffold(
      extendBody: true,
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: [
          if (_currentIndex == 0)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
            ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: colorScheme.outlineVariant.withOpacity(0.2),
              width: 0.5,
            ),
          ),
        ),
        child: NavigationBar(
          elevation: 0,
          height: 80,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          indicatorColor: colorScheme.secondaryContainer,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          selectedIndex: _currentIndex,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.add_box_outlined),
              selectedIcon: Icon(Icons.add_box),
              label: '首页',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history),
              label: '历史',
            ),
          ],
        ),
      ),
    );
  }
}
