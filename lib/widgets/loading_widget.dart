import 'package:flutter/material.dart';
import 'package:story_view/widgets/straight_lines_prosessing.dart';

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({Key? key, required this.progressing}) : super(key: key);
  final bool progressing;
  @override
  Widget build(BuildContext context) {
    if(progressing) {
      return StraightLineProgress(progressing: progressing);
    }
    else {
      return const SizedBox.shrink();
    }
  }
}
