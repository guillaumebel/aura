import 'package:aura/aura.dart';
import 'package:aura/lava_lamp.dart';
import 'package:aura/utils/context_extensions.dart';
import 'package:flutter/material.dart';

enum AppMode { aura, lavaLamp }

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin {
  AppMode _currentMode = AppMode.aura;
  bool _isFabMenuOpen = false;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _toggleFabMenu() {
    setState(() {
      _isFabMenuOpen = !_isFabMenuOpen;
    });
    if (_isFabMenuOpen) {
      _fabAnimationController.forward();
    } else {
      _fabAnimationController.reverse();
    }
  }

  void _switchMode(AppMode mode) {
    setState(() {
      _currentMode = mode;
      _isFabMenuOpen = false;
    });
    _fabAnimationController.reverse();
  }

  Widget _buildFabMenuItem({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return AnimatedBuilder(
      animation: _fabAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fabAnimation.value,
          child: FloatingActionButton.extended(
            heroTag: label,
            onPressed: onPressed,
            label: Text(label),
            icon: Icon(icon),
            backgroundColor: Theme.of(context).colorScheme.secondary,
            foregroundColor: Theme.of(context).colorScheme.onSecondary,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _currentMode == AppMode.aura
            ? const AuraPage(showFab: false)
            : const LavaLampPage(showFab: false),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        spacing: 16,
        children: [
          _buildFabMenuItem(
            label: context.localizations.auraMode,
            icon: Icons.wb_sunny,
            onPressed: () => _switchMode(AppMode.aura),
          ),

          _buildFabMenuItem(
            label: context.localizations.lavaLampMode,
            icon: Icons.bubble_chart,
            onPressed: () => _switchMode(AppMode.lavaLamp),
          ),

          FloatingActionButton(
            onPressed: _toggleFabMenu,
            tooltip: context.localizations.chooseMode,
            child: AnimatedBuilder(
              animation: _fabAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle:
                      _fabAnimation.value * 0.785398, // 45 degrees in radians
                  child: Icon(_isFabMenuOpen ? Icons.close : Icons.menu),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
