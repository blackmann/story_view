import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../utils.dart';
import '../controller/story_controller.dart';

/// Utitlity to load image (gif, png, jpg, etc) media just once. Resource is
/// cached to disk with default configurations of [DefaultCacheManager].
class ImageLoader {
  ui.Codec? frames;

  String url;

  Map<String, dynamic>? requestHeaders;

  LoadState state = LoadState.loading; // by default

  ImageLoader(this.url, {this.requestHeaders});

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

        ui.instantiateImageCodec(imageBytes).then((codec) {
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

  final BoxFit? fit;

  final StoryController? controller;
  final Widget? loadingWidget;
  final Widget? errorWidget;

  StoryImage(
    this.imageLoader, {
    Key? key,
    this.controller,
    this.fit,
    this.loadingWidget,
    this.errorWidget,
  }) : super(key: key ?? UniqueKey());

  /// Use this shorthand to fetch images/gifs from the provided [url]
  factory StoryImage.url(
    String url, {
    StoryController? controller,
    Map<String, dynamic>? requestHeaders,
    BoxFit fit = BoxFit.fitWidth,
    Widget? loadingWidget,
    Widget? errorWidget,
    Key? key,
  }) {
    return StoryImage(
        ImageLoader(
          url,
          requestHeaders: requestHeaders,
        ),
        controller: controller,
        fit: fit,
        loadingWidget: loadingWidget,
        errorWidget: errorWidget,
        key: key,
    );
  }

  @override
  State<StatefulWidget> createState() => StoryImageState();
}

class StoryImageState extends State<StoryImage> {
  ui.Image? currentFrame;

  Timer? _timer;

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
          this._timer?.cancel();
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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: ImageContentView(
        imageLoader: widget.imageLoader,
        fit: widget.fit,
        currentFrame: this.currentFrame,
        loadingWidget: widget.loadingWidget,
        errorWidget: widget.errorWidget,
      ),
    );
  }
}

/**
 * @name ImageContentView
 * @description Stateless widget that displays an image based on loading state: success, failure, or loading.
 */
class ImageContentView extends StatelessWidget {
  final ImageLoader imageLoader;
  final BoxFit? fit;
  final ui.Image? currentFrame;
  final Widget? loadingWidget;
  final Widget? errorWidget;

  const ImageContentView({
    Key? key,
    required this.imageLoader,
    required this.fit,
    required this.currentFrame,
    this.loadingWidget,
    this.errorWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (imageLoader.state) {
      case LoadState.success:
        return RawImage(
          image: currentFrame,
          fit: fit,
        );
      case LoadState.failure:
        return Center(
          child: errorWidget ??
              const Text(
                "Image failed to load.",
                style: TextStyle(color: Colors.white),
              ),
        );
      default:
        return Center(
          child: loadingWidget ??
              const SizedBox(
                width: 70,
                height: 70,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
              ),
        );
    }
  }
}

