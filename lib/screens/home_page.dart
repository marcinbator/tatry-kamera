import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../components/image_tab.dart';
import '../data/cams_urls.dart';
import '../data/colors.dart';
import '../data/widget_service.dart';

class TOPRCamsHomePage extends StatefulWidget {
  const TOPRCamsHomePage({super.key});

  @override
  State<TOPRCamsHomePage> createState() => _TOPRCamsHomePageState();
}

class _TOPRCamsHomePageState extends State<TOPRCamsHomePage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  bool isPortrait = true;
  Map<String, String> appImagesUrls = imagesUrls;
  late Map<String, bool> _camsSelection;
  List<String> _camsOrder = [];
  bool _imageZoomed = false;

  late TabController _tabController;
  String? _pendingFocusCam;
  bool _selectionLoaded = false;

  Orientation? _lastOrientation;
  Key _tabBarKey = UniqueKey();

  void _handleZoomChanged(bool zoomed) {
    if (zoomed != _imageZoomed) {
      setState(() {
        _imageZoomed = zoomed;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: appImagesUrls.length, vsync: this);
    _loadSavedCameraSelection();
    _showWalkthroughIfFirstTime();
    ToprWidgetService.syncWidget();
    _openWidgetSettingsIfConfiguring();
    _consumeLaunchCameraIfAny();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _consumeLaunchCameraIfAny();
    }
  }

  void _consumeLaunchCameraIfAny() async {
    final camName = await ToprWidgetService.consumeLaunchCamera();
    if (camName == null || !mounted) return;
    _focusCamera(camName);
  }

  void _focusCamera(String camName) {
    if (!_selectionLoaded) {
      // Camera selection/order is still loading; let _rebuildTabController
      // pick this up once it's known, instead of jumping to a possibly
      // stale (unfiltered) index now.
      _pendingFocusCam = camName;
      return;
    }
    final index = appImagesUrls.keys.toList().indexOf(camName);
    if (index < 0) return;
    _tabController.animateTo(index);
  }

  void _rebuildTabController() {
    final oldController = _tabController;
    int initialIndex = 0;
    if (_pendingFocusCam != null) {
      final idx = appImagesUrls.keys.toList().indexOf(_pendingFocusCam!);
      _pendingFocusCam = null;
      if (idx >= 0) initialIndex = idx;
    } else if (appImagesUrls.isNotEmpty) {
      initialIndex = oldController.index.clamp(0, appImagesUrls.length - 1);
    }
    _tabController = TabController(
      length: appImagesUrls.length,
      vsync: this,
      initialIndex: appImagesUrls.isEmpty ? 0 : initialIndex,
    );
    oldController.dispose();
  }

  void _openWidgetSettingsIfConfiguring() async {
    final configuring = await ToprWidgetService.isConfiguring();
    if (!configuring || !mounted) return;
    _openWidgetSettings(fromConfigure: true);
  }

  void _showWalkthroughIfFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenWalkthrough = prefs.getBool('hasSeenWalkthrough') ?? false;

    if (!hasSeenWalkthrough) {
      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Witaj w Kamery TOPR!"),
            content: const Text(
              "• Przeglądaj kamery przesuwając obrazy.\n\n"
              "• Dotknij ikonki listy (na dole) aby wybrać i uporządkować kamery.\n\n"
              "• Dotknij ikonki obrotu aby zmienić orientację ekranu.\n\n"
              "Miłego korzystania!",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("OK"),
              ),
            ],
          );
        },
      );

      await prefs.setBool('hasSeenWalkthrough', true);
    }
  }

  void _loadSavedCameraSelection() async {
    final prefs = await SharedPreferences.getInstance();
    final savedKeys = prefs.getStringList('selectedCams');
    final savedOrder = prefs.getStringList('camsOrder');

    if (savedKeys != null && savedKeys.any((k) => !imagesUrls.containsKey(k))) {
      await prefs.remove('selectedCams');
      await prefs.remove('camsOrder');
    }

    _camsOrder = (savedOrder ?? imagesUrls.keys.toList())
        .where((key) => imagesUrls.containsKey(key))
        .toList();
    _camsSelection = {
      for (var key in imagesUrls.keys)
        if (_camsOrder.contains(key)) key: savedKeys?.contains(key) ?? true,
    };

    setState(() {
      appImagesUrls = {
        for (var key in _camsOrder)
          if (_camsSelection[key] ?? false) key: imagesUrls[key]!,
      };
      _selectionLoaded = true;
      _rebuildTabController();
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
                      await ToprWidgetService.syncWidget();

                      if (!mounted) return;

                      setState(() {
                        appImagesUrls = {
                          for (var key in _camsOrder)
                            if (_camsSelection[key] ?? false)
                              key: imagesUrls[key]!,
                        };
                        _rebuildTabController();
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

  void _openWidgetSettings({bool fromConfigure = false}) async {
    final currentCam = await ToprWidgetService.getSelectedCam();
    final scanMode = await ToprWidgetService.isScanMode();
    if (!mounted) return;
    String selectedCam = currentCam;
    bool isScan = scanMode;

    Future<void> applySelection() async {
      if (isScan) {
        await ToprWidgetService.setScanMode();
      } else {
        await ToprWidgetService.setSelectedCam(selectedCam);
      }
    }

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
                    "Widget na ekranie głównym",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Wybierz miejsce, które ma być pokazywane na widgecie.",
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 350,
                    child: ListView(
                      children: [
                        RadioListTile<String>(
                          title: const Text("Pokaz slajdów (wszystkie kamery)"),
                          value: scanCamValue,
                          groupValue: isScan ? scanCamValue : selectedCam,
                          activeColor: darkGreen,
                          onChanged: (value) {
                            modalSetState(() {
                              isScan = true;
                            });
                          },
                        ),
                        const Divider(height: 1),
                        ...appImagesUrls.keys.map((camName) {
                          return RadioListTile<String>(
                            title: Text(camName),
                            value: camName,
                            groupValue: isScan ? scanCamValue : selectedCam,
                            activeColor: darkGreen,
                            onChanged: (value) {
                              modalSetState(() {
                                isScan = false;
                                selectedCam = value ?? selectedCam;
                              });
                            },
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (fromConfigure)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: darkGreen,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          await applySelection();
                          await ToprWidgetService.finishConfiguration();
                        },
                        child: const Text("Zapisz"),
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor:
                                  Theme.of(context).colorScheme.onSurface,
                              side: const BorderSide(color: green, width: 1.5),
                            ),
                            onPressed: () async {
                              await applySelection();
                              if (context.mounted) Navigator.pop(context);
                            },
                            child: const Text("Zapisz"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: darkGreen,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () async {
                              await applySelection();
                              await ToprWidgetService.requestPinWidget();
                              if (context.mounted) Navigator.pop(context);
                            },
                            child: const Text("Zapisz i dodaj"),
                          ),
                        ),
                      ],
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
    final orientation = MediaQuery.of(context).orientation;
    final isPortrait = orientation == Orientation.portrait;
    if (_lastOrientation != null && _lastOrientation != orientation) {
      // Force the TabBar to remount so it recomputes its scroll offset for
      // the new width and keeps the selected tab in view.
      _tabBarKey = UniqueKey();
    }
    _lastOrientation = orientation;
    return Scaffold(
      appBar: isPortrait
          ? PreferredSize(
              preferredSize: const Size.fromHeight(60.0),
              child: AppBar(
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
      body: Column(
        children: [
          TabBar(
            key: _tabBarKey,
            controller: _tabController,
            tabs: appImagesUrls.keys.map((name) => Tab(text: name)).toList(),
            isScrollable: true,
            onTap: (_) => _handleZoomChanged(false),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: _imageZoomed
                  ? const NeverScrollableScrollPhysics()
                  : null,
              children: appImagesUrls.entries
                  .map(
                    (entry) => ImageTab(
                      imageUrl: entry.value,
                      onZoomChanged: _handleZoomChanged,
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
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
            heroTag: "widgetButton",
            onPressed: _openWidgetSettings,
            mini: true,
            child: const Icon(Icons.widgets),
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
