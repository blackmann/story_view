import 'dart:async';

import 'package:flutter/material.dart';
import 'package:story_view/widgets/loading_widget.dart';
import 'package:video_player/video_player.dart';

import '../controller/story_controller.dart';
import '../utils.dart';

class VideoLoader {
  VideoLoader(this.url, {this.requestHeaders, this.playerController});
  String url;

  VideoPlayerController? playerController;

  Map<String, dynamic>? requestHeaders;

  LoadState state = LoadState.loading;

  void loadVideo(VoidCallback onComplete) {
    if (url.isNotEmpty) {
      onComplete();
    }
    // if (this.videoFile != null) {
    //   this.state = LoadState.success;
    //   onComplete();
    // }
    //
    // final fileStream = DefaultCacheManager()
    //     .getFileStream(this.url, headers: this.requestHeaders as Map<String, String>?);
    //
    // fileStream.listen((fileResponse) {
    //   if (fileResponse is FileInfo) {
    //     if (this.videoFile == null) {
    //       this.state = LoadState.success;
    //       this.videoFile = fileResponse.file;
    //       onComplete();
    //     }
    //   }
    // });
  }
}

class StoryVideo extends StatefulWidget {
  StoryVideo(this.videoLoader, {this.storyController, Key? key}) : super(key: key ?? UniqueKey());
  final StoryController? storyController;
  final VideoLoader videoLoader;

  static StoryVideo url(String url,
      {StoryController? controller,
      Map<String, dynamic>? requestHeaders,
      VideoPlayerController? playerController,
      Key? key}) {
    return StoryVideo(
      VideoLoader(url, requestHeaders: requestHeaders, playerController: playerController),
      storyController: controller,
      key: key,
    );
  }

  @override
  State<StatefulWidget> createState() {
    return StoryVideoState();
  }
}

class StoryVideoState extends State<StoryVideo> {
  Future<void>? playerLoader;

  StreamSubscription? _streamSubscription;

  VideoPlayerController? playerController;

  @override
  void initState() {
    super.initState();
    widget.storyController?.pause();
    widget.videoLoader.loadVideo(() {
      playerController = VideoPlayerController.network(widget.videoLoader.url);
      playerController?.initialize().then((v) {
        setState(() {
          widget.videoLoader.state = LoadState.success;
          widget.storyController?.play();
        });
      });
      if (widget.storyController != null) {
        _streamSubscription = widget.storyController?.playbackNotifier.listen((playbackState) {
          if (playbackState == PlaybackState.pause) {
            playerController?.pause();
          } else {
            playerController?.play();
          }
        });
      }
    });
  }

  Widget getContentView() {
    if (widget.videoLoader.state == LoadState.success &&
        playerController != null &&
        playerController!.value.isInitialized) {
      return Center(
        child: AspectRatio(
          aspectRatio: playerController!.value.aspectRatio,
          child: VideoPlayer(playerController!),
        ),
      );
    }

    return widget.videoLoader.state != LoadState.loading
        ? const Center(
            child: Text(
            "Media failed to load.",
            style: TextStyle(
              color: Colors.white,
            ),
          ))
        : const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      height: double.infinity,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          getContentView(),
          Positioned(
            bottom: 0,
            child: LoadingWidget(progressing: widget.videoLoader.state == LoadState.loading),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    if (mounted && playerController != null) {
      playerController?.dispose();
    }
    _streamSubscription?.cancel();
    super.dispose();
  }
}
