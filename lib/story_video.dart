import 'dart:async';

import 'package:flutter/material.dart';
import 'story_view.dart';
import 'package:video_player/video_player.dart';

class StoryVideo extends StatefulWidget {
  StoryController storyController;
  VideoPlayerController playerController;

  StoryVideo(this.playerController, this.storyController);

  @override
  State<StatefulWidget> createState() {
    return StoryVideoState();
  }
}

class StoryVideoState extends State<StoryVideo> {
  Future<void> playerLoader;

  StreamSubscription _streamSubscription;

  @override
  void initState() {
    super.initState();
    this.playerLoader = widget.playerController.initialize();

    if (widget.storyController != null) {
      _streamSubscription =
          widget.storyController.playbackNotifier.listen((playbackState) {
        if (playbackState == PlaybackState.pause) {
          widget.playerController.pause();
        } else {
          widget.playerController.play();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: playerLoader,
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          widget.storyController?.play();

          return AspectRatio(
            aspectRatio: widget.playerController.value.aspectRatio,
            child: VideoPlayer(widget.playerController),
          );
        }

        widget.storyController?.pause();

        return Center(
          child: Container(
            width: 70,
            height: 70,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 3,
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    // widget.playerController.dispose();
    _streamSubscription?.cancel();
    super.dispose();
  }
}
