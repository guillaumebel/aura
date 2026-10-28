import 'dart:async';
import 'dart:math' as math;

import 'package:aura/utils/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:keep_screen_on/keep_screen_on.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The whole screen is the lamp. No visible controls:
/// - drag up / down: intensity
/// - drag left / right: warmth (warm amber <-> cool white)
/// - double tap: back to neutral white at full intensity
/// A thin indicator appears only while a gesture is in progress.
class AuraPage extends StatefulWidget {
  const AuraPage({super.key});

  @override
  State<AuraPage> createState() => _AuraPageState();
}

enum _Axis { none, intensity, warmth }

class _AuraPageState extends State<AuraPage> {
  static const double minKelvin = 1800;
  static const double maxKelvin = 8000;
  static const double defaultKelvin = 6200;
  static const double defaultIntensity = 1.0;

  /// Below this intensity the light colour itself is dimmed too, so the lamp
  /// can go darker than the screen's minimum backlight (night light).
  static const double nightThreshold = 0.15;

  /// Distance (px) before a drag commits to one axis.
  static const double axisLockSlop = 12;

  static const _kIntensity = 'aura.intensity';
  static const _kKelvin = 'aura.kelvin';
  static const _kOnboarded = 'aura.onboarded';

  double _intensity = defaultIntensity;
  double _kelvin = defaultKelvin;
  bool _showOnboarding = false;

  _Axis _dragAxis = _Axis.none;
  Offset _dragSlop = Offset.zero;
  _Axis _indicator = _Axis.none;
  bool _indicatorVisible = false;
  Timer? _hideTimer;
  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _quietly(() => KeepScreenOn.turnOn());
    _load();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _quietly(() => KeepScreenOn.turnOff());
    _quietly(
      () => ScreenBrightness.instance.resetApplicationScreenBrightness(),
    );
    super.dispose();
  }

  static Future<void> _quietly(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      debugPrint('Aura: platform call failed: $e');
    }
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _prefs = prefs;
      _intensity = prefs.getDouble(_kIntensity) ?? defaultIntensity;
      _kelvin = prefs.getDouble(_kKelvin) ?? defaultKelvin;
      _showOnboarding = !(prefs.getBool(_kOnboarded) ?? false);
    });
    _applyBrightness();
  }

  void _save() {
    final prefs = _prefs;
    if (prefs == null) return;
    prefs.setDouble(_kIntensity, _intensity);
    prefs.setDouble(_kKelvin, _kelvin);
  }

  void _applyBrightness() {
    final value = _intensity.clamp(0.0, 1.0);
    _quietly(
      () => ScreenBrightness.instance.setApplicationScreenBrightness(value),
    );
  }

  void _dismissOnboarding() {
    if (!_showOnboarding) return;
    _showOnboarding = false;
    _prefs?.setBool(_kOnboarded, true);
  }

  // ---- Gestures -----------------------------------------------------------

  void _onPanStart(DragStartDetails details) {
    _dragAxis = _Axis.none;
    _dragSlop = Offset.zero;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_dragAxis == _Axis.none) {
      _dragSlop += details.delta;
      if (_dragSlop.distance < axisLockSlop) return;
      _dragAxis = _dragSlop.dx.abs() > _dragSlop.dy.abs()
          ? _Axis.warmth
          : _Axis.intensity;
    }

    final size = MediaQuery.sizeOf(context);
    _hideTimer?.cancel();
    setState(() {
      _dismissOnboarding();
      _indicator = _dragAxis;
      _indicatorVisible = true;
      if (_dragAxis == _Axis.intensity) {
        _intensity = (_intensity - details.delta.dy / (size.height * 0.6))
            .clamp(0.0, 1.0);
      } else {
        _kelvin =
            (_kelvin +
                    details.delta.dx /
                        (size.width * 0.9) *
                        (maxKelvin - minKelvin))
                .clamp(minKelvin, maxKelvin);
      }
    });
    if (_dragAxis == _Axis.intensity) _applyBrightness();
  }

  void _onPanEnd(DragEndDetails details) {
    if (_dragAxis == _Axis.none) return;
    _dragAxis = _Axis.none;
    _scheduleHide();
    _save();
  }

  void _onDoubleTap() {
    HapticFeedback.lightImpact();
    setState(() {
      _dismissOnboarding();
      _intensity = defaultIntensity;
      _kelvin = defaultKelvin;
    });
    _applyBrightness();
    _save();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _indicatorVisible = false);
    });
  }

  void _nudgeIntensity(double delta) {
    setState(() {
      _dismissOnboarding();
      _intensity = (_intensity + delta).clamp(0.0, 1.0);
    });
    _applyBrightness();
    _save();
  }

  // ---- Colour -------------------------------------------------------------

  Color get _lightColor {
    final base = kelvinToColor(_kelvin);
    if (_intensity >= nightThreshold) return base;
    final f = 0.22 + 0.78 * (_intensity / nightThreshold);
    return Color.lerp(Colors.black, base, f)!;
  }

  /// Colour used for the transient indicators: a quiet shade of the light.
  static Color inkFor(Color light) => light.computeLuminance() > 0.35
      ? Color.lerp(light, Colors.black, 0.52)!
      : Color.lerp(light, Colors.white, 0.45)!;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final light = _lightColor;
    final ink = inkFor(light);
    final percent = (_intensity * 100).round();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Semantics(
        label: l10n.lightLabel,
        hint: l10n.gestureHint,
        value: '$percent %',
        increasedValue: '${math.min(100, percent + 10)} %',
        decreasedValue: '${math.max(0, percent - 10)} %',
        onIncrease: () => _nudgeIntensity(0.1),
        onDecrease: () => _nudgeIntensity(-0.1),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          onDoubleTap: _onDoubleTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 90),
            color: light,
            child: ExcludeSemantics(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _Fade(
                    visible: _showOnboarding,
                    child: _Onboarding(ink: ink),
                  ),
                  _Fade(
                    visible:
                        _indicatorVisible && _indicator == _Axis.intensity,
                    child: _IntensityIndicator(value: _intensity, ink: ink),
                  ),
                  _Fade(
                    visible: _indicatorVisible && _indicator == _Axis.warmth,
                    child: _WarmthIndicator(
                      kelvin: _kelvin,
                      position:
                          (_kelvin - minKelvin) / (maxKelvin - minKelvin),
                      ink: ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Approximates the colour of a black-body light source (Tanner Helland),
/// softened slightly towards white so warm tones stay pleasant on a screen.
Color kelvinToColor(double kelvin) {
  final t = kelvin / 100;
  double r, g, b;
  if (t <= 66) {
    r = 255;
    g = 99.4708025861 * math.log(t) - 161.1195681661;
  } else {
    r = 329.698727446 * math.pow(t - 60, -0.1332047592);
    g = 288.1221695283 * math.pow(t - 60, -0.0755148492);
  }
  if (t >= 66) {
    b = 255;
  } else if (t <= 19) {
    b = 0;
  } else {
    b = 138.5177312231 * math.log(t - 10) - 305.0447927307;
  }
  int c(double v) => v.clamp(0, 255).round();
  final raw = Color.fromARGB(255, c(r), c(g), c(b));
  return Color.lerp(Colors.white, raw, 0.82)!;
}

class _Fade extends StatelessWidget {
  const _Fade({required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: Duration(milliseconds: visible ? 150 : 600),
        curve: Curves.easeOut,
        child: child,
      ),
    );
  }
}

const _numeralStyle = TextStyle(
  fontSize: 72,
  fontWeight: FontWeight.w200,
  letterSpacing: -1.4,
  fontFeatures: [FontFeature.tabularFigures()],
);

class _IntensityIndicator extends StatelessWidget {
  const _IntensityIndicator({required this.value, required this.ink});

  final double value;
  final Color ink;

  static const double trackHeight = 320;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: Text(
            '${(value * 100).round()}',
            style: _numeralStyle.copyWith(color: ink),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 17),
            child: SizedBox(
              width: 8,
              height: trackHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 3,
                    width: 2,
                    top: 0,
                    bottom: 0,
                    child: _line(ink.withValues(alpha: 0.22)),
                  ),
                  Positioned(
                    left: 3,
                    width: 2,
                    bottom: 0,
                    height: trackHeight * value,
                    child: _line(ink.withValues(alpha: 0.7)),
                  ),
                  Positioned(
                    left: 0,
                    bottom: trackHeight * value - 4,
                    child: _dot(ink),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WarmthIndicator extends StatelessWidget {
  const _WarmthIndicator({
    required this.kelvin,
    required this.position,
    required this.ink,
  });

  final double kelvin;
  final double position;
  final Color ink;

  static const double trackWidth = 240;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final rounded = (kelvin / 100).round() * 100;
    return Stack(
      children: [
        Center(
          child: Text.rich(
            TextSpan(
              text: '$rounded',
              children: const [
                TextSpan(
                  text: ' K',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w300),
                ),
              ],
            ),
            style: _numeralStyle.copyWith(color: ink),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.only(bottom: 96 + bottomInset),
            child: SizedBox(
              width: trackWidth,
              height: 8,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 3,
                    height: 2,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(1),
                        border: Border.all(
                          color: ink.withValues(alpha: 0.2),
                          width: 0.5,
                        ),
                        gradient: LinearGradient(
                          colors: [
                            for (final k in const [1800, 3000, 4500, 6500, 8000])
                              kelvinToColor(k.toDouble()),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: trackWidth * position - 4,
                    top: 0,
                    child: _dot(ink),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Onboarding extends StatelessWidget {
  const _Onboarding({required this.ink});

  final Color ink;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final label = TextStyle(
      color: ink,
      fontSize: 15,
      letterSpacing: 0.3,
      fontWeight: FontWeight.w400,
    );
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomPaint(
            size: const Size(20, 64),
            painter: _DoubleArrowPainter(color: ink, vertical: true),
          ),
          const SizedBox(height: 14),
          Text(l10n.intensity, style: label),
          const SizedBox(height: 56),
          CustomPaint(
            size: const Size(64, 20),
            painter: _DoubleArrowPainter(color: ink, vertical: false),
          ),
          const SizedBox(height: 14),
          Text(l10n.warmth, style: label),
        ],
      ),
    );
  }
}

class _DoubleArrowPainter extends CustomPainter {
  const _DoubleArrowPainter({required this.color, required this.vertical});

  final Color color;
  final bool vertical;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.25
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path();
    if (vertical) {
      final x = size.width / 2;
      path
        ..moveTo(x, 4)
        ..lineTo(x, size.height - 4)
        ..moveTo(x - 6, 10)
        ..lineTo(x, 4)
        ..lineTo(x + 6, 10)
        ..moveTo(x - 6, size.height - 10)
        ..lineTo(x, size.height - 4)
        ..lineTo(x + 6, size.height - 10);
    } else {
      final y = size.height / 2;
      path
        ..moveTo(4, y)
        ..lineTo(size.width - 4, y)
        ..moveTo(10, y - 6)
        ..lineTo(4, y)
        ..lineTo(10, y + 6)
        ..moveTo(size.width - 10, y - 6)
        ..lineTo(size.width - 4, y)
        ..lineTo(size.width - 10, y + 6);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_DoubleArrowPainter old) =>
      old.color != color || old.vertical != vertical;
}

Widget _line(Color color) => DecoratedBox(
  decoration: BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(1),
  ),
);

Widget _dot(Color color) => Container(
  width: 8,
  height: 8,
  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
);
