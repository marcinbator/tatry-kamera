import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    var darkGreen = Color.fromRGBO(20, 61, 16, 1);
    var green = Color.fromRGBO(31, 105, 24, 1);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: darkGreen,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: AppBarTheme(
          backgroundColor: darkGreen,
          titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
        ),
        tabBarTheme: TabBarThemeData(
          labelColor: green,
          unselectedLabelColor: Colors.white,
          indicator: UnderlineTabIndicator(
            borderSide: BorderSide(color: darkGreen, width: 2),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: darkGreen,
          foregroundColor: Colors.white,
        ),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool isPortrait = true;

  final Map<String, String> imagesUrls = {
    "Morskie Oko": "https://pogoda.topr.pl/download/current/mors.jpeg",
    "Dolina Pięciu Stawów": "https://pogoda.topr.pl/download/current/psps.jpeg",
    "Kasprowy Wierch": "https://pogoda.topr.pl/download/current/kwgs.jpeg",
    "Hala Gąsienicowa": "https://pogoda.topr.pl/download/current/hala.jpeg",
    "Dolina Chochołowska": "https://pogoda.topr.pl/download/current/dcho.jpeg",
    "Tatry Wysokie (Czarna Góra)":
        "https://pogoda.topr.pl/download/current/czgr.jpeg",
    "Tatry Zachodnie (Kościelisko)":
        "https://pogoda.topr.pl/download/current/kscw.jpeg",
  };

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
      appBar:
          isPortrait
              ? PreferredSize(
                preferredSize: const Size.fromHeight(60.0),
                child: AppBar(
                  backgroundColor: Colors.black,
                  title: Row(
                    children: [
                      ClipOval(
                        child: Image.asset('assets/icon.png', height: 40),
                      ),
                      const SizedBox(width: 20),
                      const Text(
                        "Kamery TOPR",
                        style: TextStyle(color: Colors.white),
                      ),
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
                children:
                    imagesUrls.entries
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

class ImageTab extends StatefulWidget {
  final String imageUrl;

  const ImageTab({super.key, required this.imageUrl});

  @override
  _ImageTabState createState() => _ImageTabState();
}

class _ImageTabState extends State<ImageTab> {
  late String imageUrl;

  @override
  void initState() {
    super.initState();
    imageUrl = widget.imageUrl;
  }

  @override
  Widget build(BuildContext context) {
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    if (!isPortrait) {
      return SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.network(
                imageUrl,
                width: MediaQuery.of(context).size.width * 0.67,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              imageUrl,
              fit: BoxFit.contain,
              width: MediaQuery.of(context).size.width,
            ),
          ],
        ),
      );
    }
  }
}
