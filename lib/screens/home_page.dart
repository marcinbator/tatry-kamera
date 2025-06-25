import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  Map<String, String> appImagesUrls = imagesUrls;
  late Map<String, bool> _camsSelection;
  Key _sliderKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _camsSelection = {for (var entry in imagesUrls.entries) entry.key: true};
    _loadSavedCameraSelection();
  }

  void _loadSavedCameraSelection() async {
    final prefs = await SharedPreferences.getInstance();
    final savedKeys = prefs.getStringList('selectedCams');
    if (savedKeys != null) {
      setState(() {
        _camsSelection = {
          for (var key in imagesUrls.keys) key: savedKeys.contains(key),
        };
        appImagesUrls = {
          for (var entry in _camsSelection.entries)
            if (entry.value) entry.key: imagesUrls[entry.key]!,
        };
        _sliderKey = UniqueKey();
      });
    }
  }

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

  void _enableListEditor() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Wybierz kamery",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 300,
                    child: ListView(
                      children: _camsSelection.keys.map((camName) {
                        return CheckboxListTile(
                          title: Text(camName),
                          value: _camsSelection[camName],
                          onChanged: (value) {
                            modalSetState(() {
                              _camsSelection[camName] = value ?? false;
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final selectedKeys = _camsSelection.entries
                          .where((entry) => entry.value)
                          .map((entry) => entry.key)
                          .toList();
                      SharedPreferences.getInstance().then((prefs) {
                        prefs.setStringList('selectedCams', selectedKeys);
                      });

                      setState(() {
                        appImagesUrls = {
                          for (var entry in _camsSelection.entries)
                            if (entry.value) entry.key: imagesUrls[entry.key]!,
                        };
                        _sliderKey = UniqueKey();
                      });
                      Navigator.pop(context);
                    },
                    child: const Text("Zastosuj"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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
                    ClipOval(child: Image.asset('assets/logo.png', height: 40)),
                    const SizedBox(width: 20),
                    const Text("Kamery TOPR", style: TextStyle(color: white)),
                  ],
                ),
              ),
            )
          : null,
      body: DefaultTabController(
        key: _sliderKey,
        length: appImagesUrls.length,
        child: Column(
          children: [
            TabBar(
              tabs: appImagesUrls.keys.map((name) => Tab(text: name)).toList(),
              isScrollable: true,
            ),
            Expanded(
              child: TabBarView(
                children: appImagesUrls.entries
                    .map((entry) => ImageTab(imageUrl: entry.value))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "listButton",
            onPressed: _enableListEditor,
            mini: true,
            child: const Icon(Icons.list),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: "rotateButton",
            onPressed: _toggleOrientation,
            child: const Icon(Icons.screen_rotation),
          ),
        ],
      ),
    );
  }
}
