import 'package:aura/utils/context_extensions.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:keep_screen_on/keep_screen_on.dart';
import 'package:screen_brightness/screen_brightness.dart';

class AuraPage extends StatefulWidget {
  const AuraPage({super.key, this.showFab = true});

  final bool showFab;

  @override
  State<AuraPage> createState() => _AuraPageState();
}

class _AuraPageState extends State<AuraPage> {
  double _brightnessValue = 0;
  bool _visible = false;
  Color _backgroundColor = Colors.white;

  @override
  void initState() {
    super.initState();
    // Initialize brightness value to current screen brightness
    KeepScreenOn.turnOn();
  }

  @override
  void dispose() {
    KeepScreenOn.turnOff();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: widget.showFab
          ? FloatingActionButton(
              onPressed: () async {
                final newColor = await showColorPickerDialog(
                  context,
                  _backgroundColor,
                );
                setState(() {
                  _backgroundColor = newColor;
                });
              },
              tooltip: context.localizations.chooseBackgroundColor,
              child: const Icon(Icons.color_lens),
            )
          : null,
      body: GestureDetector(
        onTap: () {
          setState(() {
            _visible = !_visible;
          });
        },
        onVerticalDragUpdate: (details) => setState(() {
          _brightnessValue -= details.delta.dy;
          if (_brightnessValue < 0) _brightnessValue = 0;
          if (_brightnessValue > 100) _brightnessValue = 100;
          ScreenBrightness.instance.setApplicationScreenBrightness(
            _brightnessValue / 100,
          );
        }),
        child: Container(
          color: _backgroundColor,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Spacer(),

              AnimatedOpacity(
                duration: Duration(milliseconds: 300),
                opacity: _visible ? 1.0 : 0.0,

                child: Column(
                  children: [
                    Container(
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black,
                            _backgroundColor.withValues(alpha: .5),
                            _backgroundColor.withValues(alpha: .25),
                            _backgroundColor.withValues(alpha: .10),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      color: Colors.black,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            child: ColorIndicator(
                              width: 44,
                              height: 44,
                              borderRadius: 8,
                              color: _backgroundColor,
                              onSelectFocus: false,
                              onSelect: () async {
                                final newColor = await showColorPickerDialog(
                                  context,
                                  _backgroundColor,
                                );
                                setState(() {
                                  _backgroundColor = newColor;
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: Slider(
                              value: _brightnessValue.toDouble(),
                              min: 0,
                              max: 100,
                              divisions: 100,
                              label: _brightnessValue.toStringAsFixed(0),
                              onChanged: (double value) async {
                                setState(() {
                                  _brightnessValue = value;
                                });

                                try {
                                  await ScreenBrightness.instance
                                      .setApplicationScreenBrightness(
                                        value / 100,
                                      );
                                } catch (e) {
                                  throw "Failed to set brightness";
                                }
                              },
                            ),
                          ),
                          SizedBox(width: 59),
                        ],
                      ),
                    ),
                    Container(height: 18, color: Colors.black),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
