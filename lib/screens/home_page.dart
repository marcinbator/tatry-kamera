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
  List<String> _camsOrder = [];

  Key _sliderKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _loadSavedCameraSelection();
  }

  void _loadSavedCameraSelection() async {
    final prefs = await SharedPreferences.getInstance();
    final savedKeys = prefs.getStringList('selectedCams');
    final savedOrder = prefs.getStringList('camsOrder');

    _camsOrder = savedOrder ?? imagesUrls.keys.toList();
    _camsSelection = {
      for (var key in imagesUrls.keys) key: savedKeys?.contains(key) ?? true,
    };

    setState(() {
      appImagesUrls = {
        for (var key in _camsOrder)
          if (_camsSelection[key] ?? false) key: imagesUrls[key]!,
      };
      _sliderKey = UniqueKey();
    });
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
                    height: 400,
                    child: ReorderableListView(
                      onReorder: (oldIndex, newIndex) {
                        modalSetState(() {
                          if (newIndex > oldIndex) newIndex -= 1;
                          final item = _camsOrder.removeAt(oldIndex);
                          _camsOrder.insert(newIndex, item);
                        });
                      },
                      children: _camsOrder.map((camName) {
                        return CheckboxListTile(
                          key: ValueKey(camName),
                          title: Text(camName),
                          value: _camsSelection[camName],
                          onChanged: (value) {
                            modalSetState(() {
                              _camsSelection[camName] = value ?? false;
                            });
                          },
                          secondary: Icon(Icons.drag_handle),
                          activeColor: darkGreen,
                          checkColor: white,
                        );
                      }).toList(),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkGreen,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      final selectedKeys = _camsOrder
                          .where((k) => _camsSelection[k] ?? false)
                          .toList();

                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setStringList('selectedCams', selectedKeys);
                      await prefs.setStringList('camsOrder', _camsOrder);

                      if (!mounted) return;

                      setState(() {
                        appImagesUrls = {
                          for (var key in _camsOrder)
                            if (_camsSelection[key] ?? false)
                              key: imagesUrls[key]!,
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
