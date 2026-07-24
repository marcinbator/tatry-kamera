import 'package:flutter/material.dart';

import '../data/cams_urls.dart';

class ImageTab extends StatefulWidget {
  final String imageUrl;

  const ImageTab({super.key, required this.imageUrl});

  @override
  ImageTabState createState() => ImageTabState();
}

class ImageTabState extends State<ImageTab> with WidgetsBindingObserver {
  static const int _stepMinutes = 10;
  static const int _maxStepsBack = 72; // 12h / 10min steps

  late final String _camCode;
  int _stepsBack = 0;

  @override
  void initState() {
    super.initState();
    _camCode = camCodeFromUrl(widget.imageUrl);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _stepsBack != 0) {
      setState(() {
        _stepsBack = 0;
      });
    }
  }

  DateTime get _selectedTime {
    final now = DateTime.now();
    final snapped = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      (now.minute ~/ _stepMinutes) * _stepMinutes,
    );
    return snapped.subtract(Duration(minutes: _stepMinutes * _stepsBack));
  }

  String get _displayUrl {
    if (_stepsBack == 0) return widget.imageUrl;
    return buildHistoryUrl(_camCode, _selectedTime);
  }

  void _changeSteps(int newSteps) {
    setState(() {
      _stepsBack = newSteps.clamp(0, _maxStepsBack);
    });
  }

  String _formatTime(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.day)}.${two(t.month)} ${two(t.hour)}:${two(t.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 5,
              child: SizedBox.expand(
                child: Image.network(
                  _displayUrl,
                  key: ValueKey(_displayUrl),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        'Brak zdjęcia dla wybranej godziny',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        _buildHistoryControls(),
      ],
    );
  }

  Widget _buildHistoryControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 84, 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _stepsBack == 0 ? 'Na żywo' : _formatTime(_selectedTime),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.fast_rewind),
                tooltip: '10 minut wcześniej',
                onPressed: _stepsBack < _maxStepsBack
                    ? () => _changeSteps(_stepsBack + 1)
                    : null,
              ),
              Expanded(
                child: Slider(
                  min: 0,
                  max: _maxStepsBack.toDouble(),
                  divisions: _maxStepsBack,
                  value: (_maxStepsBack - _stepsBack).toDouble(),
                  label:
                      _stepsBack == 0 ? 'Na żywo' : _formatTime(_selectedTime),
                  onChanged: (v) => _changeSteps(_maxStepsBack - v.round()),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.fast_forward),
                tooltip: '10 minut później',
                onPressed:
                    _stepsBack > 0 ? () => _changeSteps(_stepsBack - 1) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
