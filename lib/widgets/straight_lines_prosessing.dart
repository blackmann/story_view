import 'dart:math' as math;

import 'package:flutter/material.dart';

class StraightLineProgress extends StatefulWidget {
  const StraightLineProgress({Key? key, required this.progressing, this.height}) : super(key: key);
  final bool progressing;
  final double? height;
  @override
  State<StraightLineProgress> createState() => _StraightLineProgressState();
}

class _StraightLineProgressState extends State<StraightLineProgress> with TickerProviderStateMixin {
  late AnimationController controller;
  @override
  void initState() {
    controller = AnimationController(duration: const Duration(milliseconds: 450), vsync: this)
      ..repeat()
      ..addListener(listener);
    super.initState();
  }

  @override
  void didUpdateWidget(StraightLineProgress oldWidget) {
    if (oldWidget.progressing != widget.progressing) {
      if (widget.progressing && !controller.isAnimating) {
        controller.repeat();
        controller.addListener(listener);
      } else if (!widget.progressing && !controller.isAnimating) {
        controller.removeListener(listener);
        controller.stop();
      }
    }
    super.didUpdateWidget(oldWidget);
  }

  void listener() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    if (mounted) {
      controller.removeListener(listener);
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.progressing) {
      return SizedBox(
        height: widget.height ?? 2,
        width: MediaQuery.of(context).size.width,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Transform.rotate(
                angle: -math.pi,
                child: ProgressIndicatorItem(controller: controller),
              ),
            ),
            Flexible(child: ProgressIndicatorItem(controller: controller)),
          ],
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}

class ProgressIndicatorItem extends StatelessWidget {
  const ProgressIndicatorItem({Key? key, required this.controller}) : super(key: key);
  final AnimationController controller;
  @override
  Widget build(BuildContext context) {
    return LinearProgressIndicator(
      backgroundColor: const Color.fromRGBO(200, 200, 200, 0.5),
      value: controller.view.value,
      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
    );
  }
}
