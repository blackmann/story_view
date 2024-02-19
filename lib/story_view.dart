export 'widgets/story_image.dart';
export 'widgets/story_video.dart';
export 'widgets/story_view.dart';
export 'controller/story_controller.dart';
export 'utils.dart';

class StoryView extends StatefulWidget {
  final List<StoryItem> storyItems;
  final StoryController controller;
  final int startAtIndex; // Nouveau paramètre pour commencer à un index spécifique

  StoryView({
    Key? key,
    required this.storyItems,
    required this.controller,
    this.startAtIndex = 0, // Valeur par défaut à 0
  }) : super(key: key);

  @override
  _StoryViewState createState() => _StoryViewState();
}

class _StoryViewState extends State<StoryView> {
  late int _currentStoryIndex;

  @override
  void initState() {
    super.initState();
    _currentStoryIndex = widget.startAtIndex; // Initialisez avec startAtIndex
    widget.controller.play(); // Assurez-vous de démarrer la lecture à l'index spécifié
  }

}
