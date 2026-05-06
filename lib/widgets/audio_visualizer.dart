import 'dart:math';
import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class AudioVisualizer extends StatefulWidget {
  final bool isPlaying;
  final int barCount;
  
  const AudioVisualizer({
    super.key, 
    required this.isPlaying,
    this.barCount = 30,
  });

  @override
  State<AudioVisualizer> createState() => _AudioVisualizerState();
}

class _AudioVisualizerState extends State<AudioVisualizer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();
  late List<double> _heights;

  @override
  void initState() {
    super.initState();
    _heights = List.generate(widget.barCount, (_) => _random.nextDouble());
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addListener(() {
        setState(() {
          for (int i = 0; i < widget.barCount; i++) {
            _heights[i] = _random.nextDouble();
          }
        });
      });

    if (widget.isPlaying) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AudioVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(widget.barCount, (index) {
          // Si no está sonando, las barras se quedan a una altura mínima
          final heightFactor = widget.isPlaying ? (_heights[index] * 0.8 + 0.2) : 0.1;
          
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 4,
            height: 60 * heightFactor,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(widget.isPlaying ? 255 : 100),
              borderRadius: BorderRadius.circular(2),
              boxShadow: widget.isPlaying ? [
                BoxShadow(
                  color: AppColors.primary.withAlpha(100),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                )
              ] : null,
            ),
          );
        }),
      ),
    );
  }
}
