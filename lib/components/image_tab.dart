import 'package:flutter/cupertino.dart';

class ImageTab extends StatefulWidget {
  final String imageUrl;

  const ImageTab({super.key, required this.imageUrl});

  @override
  ImageTabState createState() => ImageTabState();
}

class ImageTabState extends State<ImageTab> {
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
