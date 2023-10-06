import 'dart:async';
import 'dart:io';

import 'package:cached_video_player/cached_video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shimmer/shimmer.dart';

import '../controller/story_controller.dart';
import '../utils/utils.dart';

class VideoLoader {
  String url;
  String storyIndex;

  File? videoFile;

  Map<String, dynamic>? requestHeaders;

  LoadState state = LoadState.loading;

  VideoLoader(this.url, this.storyIndex, {this.requestHeaders});

  void loadVideo(VoidCallback onComplete) {
    if (this.videoFile != null) {
      this.state = LoadState.success;
      onComplete();
    }

    final fileStream = DefaultCacheManager().getFileStream(this.url,
        headers: this.requestHeaders as Map<String, String>?);

    fileStream.listen((fileResponse) {
      if (fileResponse is FileInfo) {
        if (this.videoFile == null) {
          this.state = LoadState.success;
          this.videoFile = fileResponse.file;
          onComplete();
        }
      }
    });
  }
}

class StoryVideo extends StatefulWidget {
  final StoryController? storyController;
  final VideoLoader videoLoader;
  final bool isHLS;

  StoryVideo(this.videoLoader,
      {this.storyController, this.isHLS = false, Key? key})
      : super(key: key ?? UniqueKey());

  static StoryVideo url(String url, String storyId,
      {StoryController? controller,
      required bool isHLS,
      Map<String, dynamic>? requestHeaders,
      Key? key}) {
    return StoryVideo(VideoLoader(url, storyId, requestHeaders: requestHeaders),
        storyController: controller, key: key, isHLS: isHLS);
  }

  @override
  State<StatefulWidget> createState() {
    return StoryVideoState();
  }
}

class StoryVideoState extends State<StoryVideo> {
  Future<void>? playerLoader;

  StreamSubscription? _streamSubscription;

  CachedVideoPlayerController? playerController;

  @override
  void initState() {
    super.initState();

    widget.storyController!.pause();

    widget.videoLoader.loadVideo(() {
      if (widget.videoLoader.state == LoadState.success) {
        /// if video is HLS, need to load it from network, if is a downloaded file, need to load it from local cache
        if (widget.isHLS) {
          this.playerController =
              CachedVideoPlayerController.network(widget.videoLoader.url);
        } else {
          this.playerController =
              CachedVideoPlayerController.file(widget.videoLoader.videoFile!);
        }
        this.playerController!.initialize().then((v) {
          setState(() {});
          widget.storyController!.play();
        });

        if (widget.storyController != null) {
          _streamSubscription =
              widget.storyController!.playbackNotifier.listen((playbackState) {
            if (playbackState == PlaybackState.pause) {
              playerController!.pause();
            } else {
              playerController!.play();
            }
          });
        }
      } else {
        setState(() {});
      }
    });
  }

  Widget getContentView() {
    if (widget.videoLoader.state == LoadState.success &&
        playerController!.value.isInitialized) {
      return Center(
        child: AspectRatio(
          aspectRatio: playerController!.value.aspectRatio,
          child: CachedVideoPlayer(playerController!),
        ),
      );
    }

    return widget.videoLoader.state == LoadState.loading ||
            !playerController!.value.isInitialized == true
        ? Shimmer.fromColors(
            baseColor: Color(0xFF222124),
            highlightColor: Colors.grey.withOpacity(0.2),
            child: Container(
              color: Colors.black,
              child: Container(
                decoration: ShapeDecoration(
                  color: Colors.grey[500]!,
                  shape: const RoundedRectangleBorder(),
                ),
              ),
            ),
          )
        : Center(
            child: Text(
            "Media failed to load.",
            style: TextStyle(
              color: Colors.white,
            ),
          ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      height: double.infinity,
      width: double.infinity,
      child: getContentView(),
    );
  }

  @override
  void dispose() {
    playerController?.dispose();
    _streamSubscription?.cancel();
    super.dispose();
  }
}
