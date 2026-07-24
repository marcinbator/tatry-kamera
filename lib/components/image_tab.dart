import 'package:flutter/material.dart';

import '../data/cams_urls.dart';

class ImageTab extends StatefulWidget {
  final String imageUrl;
  final ValueChanged<bool>? onZoomChanged;

  const ImageTab({super.key, required this.imageUrl, this.onZoomChanged});

  @override
  ImageTabState createState() => ImageTabState();
}

class ImageTabState extends State<ImageTab>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  static const int _stepMinutes = 10;
  static const int _maxStepsBack = 72; // 12h / 10min steps
  static const double _doubleTapScale = 3.0;
  static const int _prefetchWindow = 3;

  late final String _camCode;
  int _stepsBack = 0;

  String? _shownUrl;
  String? _requestedUrl;

  final TransformationController _transformationController =
      TransformationController();
  late final AnimationController _zoomAnimationController;
  Animation<Matrix4>? _zoomAnimation;
  bool _isZoomed = false;
  Offset _doubleTapLocalPosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    _camCode = camCodeFromUrl(widget.imageUrl);
    WidgetsBinding.instance.addObserver(this);
    _zoomAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..addListener(() {
        if (_zoomAnimation != null) {
          _transformationController.value = _zoomAnimation!.value;
        }
      });
    _shownUrl = widget.imageUrl;
    _requestUrl(_displayUrl);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prefetchAround(_stepsBack);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _zoomAnimationController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _reportZoomState() {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    final zoomed = scale > 1.01;
    if (zoomed != _isZoomed) {
      _isZoomed = zoomed;
      widget.onZoomChanged?.call(zoomed);
    }
  }

  void _animateTransformTo(Matrix4 target) {
    _zoomAnimation = Matrix4Tween(
      begin: _transformationController.value,
      end: target,
    ).animate(
      CurveTween(curve: Curves.easeOut).animate(_zoomAnimationController),
    );
    _zoomAnimationController.forward(from: 0);
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    _doubleTapLocalPosition = details.localPosition;
  }

  void _handleDoubleTap() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    Matrix4 target;
    if (currentScale > 1.01) {
      target = Matrix4.identity();
    } else {
      final pos = _doubleTapLocalPosition;
      target = Matrix4.identity()
        ..translate(pos.dx, pos.dy)
        ..scale(_doubleTapScale)
        ..translate(-pos.dx, -pos.dy);
    }
    _animateTransformTo(target);
    Future.microtask(_reportZoomState);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_stepsBack != 0) {
        setState(() {
          _stepsBack = 0;
        });
      }
      _requestUrl(_urlForSteps(0));
      _prefetchAround(0);
    }
  }

  DateTime get _selectedTime => _timeForSteps(_stepsBack);

  DateTime _timeForSteps(int steps) {
    final now = DateTime.now();
    final snapped = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      (now.minute ~/ _stepMinutes) * _stepMinutes,
    );
    return snapped.subtract(Duration(minutes: _stepMinutes * steps));
  }

  String _urlForSteps(int steps) {
    if (steps == 0) return widget.imageUrl;
    return buildHistoryUrl(_camCode, _timeForSteps(steps));
  }

  String get _displayUrl => _urlForSteps(_stepsBack);

  void _changeSteps(int newSteps) {
    final clamped = newSteps.clamp(0, _maxStepsBack);
    setState(() {
      _stepsBack = clamped;
    });
    _requestUrl(_urlForSteps(clamped));
    _prefetchAround(clamped);
  }

  void _requestUrl(String url) {
    _requestedUrl = url;
    final stream = NetworkImage(url).resolve(const ImageConfiguration());
    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, synchronousCall) {
        stream.removeListener(listener);
        if (!mounted || _requestedUrl != url) return;
        setState(() {
          _shownUrl = url;
        });
      },
      onError: (error, stackTrace) {
        stream.removeListener(listener);
        // keep showing the previously loaded image
      },
    );
    stream.addListener(listener);
  }

  void _prefetchAround(int center) {
    for (var offset = 1; offset <= _prefetchWindow; offset++) {
      for (final step in [center - offset, center + offset]) {
        if (step < 0 || step > _maxStepsBack) continue;
        precacheImage(NetworkImage(_urlForSteps(step)), context)
            .catchError((_) {});
      }
    }
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
            child: GestureDetector(
              onDoubleTapDown: _handleDoubleTapDown,
              onDoubleTap: _handleDoubleTap,
              child: InteractiveViewer(
                transformationController: _transformationController,
                minScale: 1,
                maxScale: 5,
                onInteractionUpdate: (_) => _reportZoomState(),
                onInteractionEnd: (_) => _reportZoomState(),
                child: SizedBox.expand(
                  child: Image.network(
                    _shownUrl ?? widget.imageUrl,
                    key: ValueKey(_shownUrl ?? widget.imageUrl),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        size: 48,
                        color: Colors.grey,
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
