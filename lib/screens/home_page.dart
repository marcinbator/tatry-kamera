import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../components/image_tab.dart';
import '../data/cams_urls.dart';
import '../data/colors.dart';

class TOPRCamsHomePage extends StatefulWidget {
  const TOPRCamsHomePage({super.key});

  @override
  State<TOPRCamsHomePage> createState() => _TOPRCamsHomePageState();
}

class _TOPRCamsHomePageState extends State<TOPRCamsHomePage> {
  bool isPortrait = true;

  void _toggleOrientation() {
    if (isPortrait) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeRight,
        DeviceOrientation.landscapeLeft,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
    setState(() {
      isPortrait = !isPortrait;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;
    return Scaffold(
      appBar: isPortrait
          ? PreferredSize(
              preferredSize: const Size.fromHeight(60.0),
              child: AppBar(
                backgroundColor: black,
                title: Row(
                  children: [
                    ClipOval(child: Image.asset('assets/icon.png', height: 40)),
                    const SizedBox(width: 20),
                    const Text("Kamery TOPR", style: TextStyle(color: white)),
                  ],
                ),
              ),
            )
          : null,
      body: DefaultTabController(
        length: imagesUrls.length,
        child: Column(
          children: [
            TabBar(
              tabs: imagesUrls.keys.map((name) => Tab(text: name)).toList(),
              isScrollable: true,
            ),
            Expanded(
              child: TabBarView(
                children: imagesUrls.entries
                    .map((entry) => ImageTab(imageUrl: entry.value))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleOrientation,
        child: const Icon(Icons.screen_rotation),
      ),
    );
  }
}
