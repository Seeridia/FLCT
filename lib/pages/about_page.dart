import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Future<void> _launchUrl() async {
    final Uri url = Uri.parse('https://github.com/Seeridia/FLCT');
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('关于'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/icon/icon.png',
                width: 100,
                height: 100,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'FLCT Alpha',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            FutureBuilder<String>(
              future: DefaultAssetBundle.of(context)
                  .loadString('pubspec.yaml')
                  .then((yaml) {
                try {
                  final lines = yaml.split('\n');
                  for (final line in lines) {
                    if (line.trim().startsWith('version:')) {
                      final version = line.split('version:')[1].trim();
                      return version;
                    }
                  }
                  return '未知';
                } catch (e) {
                  return '未知';
                }
              }),
              builder: (context, snapshot) {
                return Text(
                  '版本: ${snapshot.data ?? '未知'}',
                  style: const TextStyle(fontSize: 16),
                );
              },
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: _launchUrl,
              icon: const Icon(Icons.link),
              label: const Text('GitHub 仓库'),
            ),
          ],
        ),
      ),
    );
  }
}