import 'dart:async';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shimmer/shimmer.dart';

import '../controller/story_controller.dart';
import '../utils/utils.dart';

/// Utitlity to load image (gif, png, jpg, etc) media just once. Resource is
/// cached to disk with default configurations of [DefaultCacheManager].
class ImageLoader {
  ui.Codec? frames;

  String url;
  String storyId;

  Map<String, dynamic>? requestHeaders;

  LoadState state = LoadState.loading; // by default

  ImageLoader(this.url, this.storyId, {this.requestHeaders});

  /// Load image from disk cache first, if not found then load from network.
  /// `onComplete` is called when [imageBytes] become available.
  void loadImage(VoidCallback onComplete) {
    if (this.frames != null) {
      this.state = LoadState.success;
      onComplete();
    }

    final fileStream = DefaultCacheManager().getFileStream(this.url,
        headers: this.requestHeaders as Map<String, String>?);

    fileStream.listen(
      (fileResponse) {
        if (!(fileResponse is FileInfo)) return;
        // the reason for this is that, when the cache manager fetches
        // the image again from network, the provided `onComplete` should
        // not be called again
        if (this.frames != null) {
          return;
        }

        final imageBytes = fileResponse.file.readAsBytesSync();

        this.state = LoadState.success;

        PaintingBinding.instance!.instantiateImageCodec(imageBytes).then(
            (codec) {
          this.frames = codec;
          onComplete();
        }, onError: (error) {
          this.state = LoadState.failure;
          onComplete();
        });
      },
      onError: (error) {
        this.state = LoadState.failure;
        onComplete();
      },
    );
  }
}

/// Widget to display animated gifs or still images. Shows a loader while image
/// is being loaded. Listens to playback states from [controller] to pause and
/// forward animated media.
class StoryImage extends StatefulWidget {
  final ImageLoader imageLoader;
  final bool isRepost;
  final String userName;
  final String userProfile;
  final BoxFit? fit;

  final StoryController? controller;

  StoryImage(
    this.imageLoader,
    this.isRepost,
    this.userName,
    this.userProfile, {
    Key? key,
    this.controller,
    this.fit,
  }) : super(key: key ?? UniqueKey());

  /// Use this shorthand to fetch images/gifs from the provided [url]
  factory StoryImage.url(
    String url,
    String storyId,
    bool isRepost,
    String userName,
    String userProfile, {
    StoryController? controller,
    Map<String, dynamic>? requestHeaders,
    BoxFit fit = BoxFit.fitWidth,
    Key? key,
  }) {
    return StoryImage(
        ImageLoader(
          url,
          storyId,
          requestHeaders: requestHeaders,
        ),
        isRepost,
        userName,
        userProfile,
        controller: controller,
        fit: fit,
        key: key);
  }

  @override
  State<StatefulWidget> createState() => StoryImageState();
}

class StoryImageState extends State<StoryImage> {
  ui.Image? currentFrame;

  Timer? _timer;
  int? _resumeTimerDuration;
  StreamSubscription<PlaybackState>? _streamSubscription;

  @override
  void initState() {
    super.initState();

    if (widget.controller != null) {
      this._streamSubscription =
          widget.controller!.playbackNotifier.listen((playbackState) {
        // for the case of gifs we need to pause/play
        if (widget.imageLoader.frames == null) {
          return;
        }

        if (playbackState == PlaybackState.pause) {
          this._resumeTimerDuration = this._timer?.tick;
          this._timer?.cancel();
        } else if (playbackState == PlaybackState.resume) {
          //_timer = Timer(_resumeTimerDuration, () { });
          this._timer =
              Timer(Duration(milliseconds: _resumeTimerDuration ?? 0), forward);
        } else {
          forward();
        }
      });
    }

    widget.controller?.pause();

    widget.imageLoader.loadImage(() async {
      if (mounted) {
        if (widget.imageLoader.state == LoadState.success) {
          widget.controller?.play();
          forward();
        } else {
          // refresh to show error
          setState(() {});
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _streamSubscription?.cancel();

    super.dispose();
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  void forward() async {
    this._timer?.cancel();

    if (widget.controller != null &&
        widget.controller!.playbackNotifier.stream.value ==
            PlaybackState.pause) {
      return;
    }

    final nextFrame = await widget.imageLoader.frames!.getNextFrame();

    this.currentFrame = nextFrame.image;

    if (nextFrame.duration > Duration(milliseconds: 0)) {
      this._timer = Timer(nextFrame.duration, forward);
    }

    setState(() {});
  }

  void resume() async {
    if (widget.controller != null &&
        widget.controller!.playbackNotifier.stream.value ==
            PlaybackState.pause) {
      return;
    }
    this._streamSubscription?.resume();
  }

  Widget getContentView() {
    switch (widget.imageLoader.state) {
      case LoadState.success:
        return widget.isRepost == true
            ? Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(50.0),
                    child: RawImage(
                      image: this.currentFrame,
                      fit: widget.fit,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(58.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 15,
                          backgroundImage: NetworkImage(widget.userProfile),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(widget.userName),
                        ),
                      ],
                    ),
                  )
                ],
              )
            : RawImage(
                image: this.currentFrame,
                fit: widget.fit,
              );
      case LoadState.failure:
        return Center(
            child: Text(
          "Image failed to load.",
          style: TextStyle(
            color: Colors.white,
          ),
        ));
      default:
        return Shimmer.fromColors(
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
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.isRepost == true
        ? Stack(
            children: [
              ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaY: 15, sigmaX: 15),
                //SigmaX and Y are just for X and Y directions
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  child: Center(
                    child: RawImage(
                      image: this.currentFrame,
                      fit: widget.fit,
                    ),
                  ),
                ),
              ),
              Center(
                child: getContentView(),
              ),
            ],
          )
        : Container(
            width: double.infinity,
            height: double.infinity,
            child: getContentView(),
          );
  }
}
