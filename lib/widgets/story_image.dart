import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:story_view/widgets/loading_widget.dart';

import '../controller/story_controller.dart';
import '../utils.dart';

/// Utitlity to load image (gif, png, jpg, etc) media just once. Resource is
/// cached to disk with default configurations of [DefaultCacheManager].
class ImageLoader {

  ImageLoader(this.url, {this.requestHeaders});
  ui.Codec? frames;

  String url;

  Map<String, dynamic>? requestHeaders;

  LoadState state = LoadState.loading;

  /// Load image from disk cache first, if not found then load from network.
  /// `onComplete` is called when [imageBytes] become available.
  void loadImage(VoidCallback onComplete) {
    if (frames != null) {
      state = LoadState.success;
      onComplete();
    }

    final fileStream = DefaultCacheManager().getFileStream(url, headers: requestHeaders as Map<String, String>?);

    fileStream.listen(
      (fileResponse) {
        if (!(fileResponse is FileInfo)) return;
        // the reason for this is that, when the cache manager fetches
        // the image again from network, the provided `onComplete` should
        // not be called again
        if (frames != null) {
          return;
        }

        final imageBytes = fileResponse.file.readAsBytesSync();

        state = LoadState.success;

        PaintingBinding.instance!.instantiateImageCodec(imageBytes).then((codec) {
          frames = codec;
          onComplete();
        }, onError: (error) {
          state = LoadState.failure;
          onComplete();
        });
      },
      onError: (error) {
        state = LoadState.failure;
        onComplete();
      },
    );
  }
}

/// Widget to display animated gifs or still images. Shows a loader while image
/// is being loaded. Listens to playback states from [controller] to pause and
/// forward animated media.
class StoryImage extends StatefulWidget {
  StoryImage(
    this.imageLoader, {
    Key? key,
    this.controller,
    this.fit,
  }) : super(key: key ?? UniqueKey());

  /// Use this shorthand to fetch images/gifs from the provided [url]
  factory StoryImage.url(
    String url, {
    StoryController? controller,
    Map<String, dynamic>? requestHeaders,
    BoxFit fit = BoxFit.fitWidth,
    Key? key,
  }) {
    return StoryImage(
        ImageLoader(
          url,
          requestHeaders: requestHeaders,
        ),
        controller: controller,
        fit: fit,
        key: key);
  }
  final ImageLoader imageLoader;

  final BoxFit? fit;

  final StoryController? controller;

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
      _streamSubscription = widget.controller!.playbackNotifier.listen((playbackState) {
        // for the case of gifs we need to pause/play
        if (widget.imageLoader.frames == null) {
          return;
        }

        if (playbackState == PlaybackState.pause) {
          _timer?.cancel();
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

  Future<void> forward() async {
    _timer?.cancel();

    if (widget.controller != null && widget.controller!.playbackNotifier.stream.value == PlaybackState.pause) {
      return;
    }

    final nextFrame = await widget.imageLoader.frames!.getNextFrame();

    currentFrame = nextFrame.image;

    if (nextFrame.duration > const Duration(milliseconds: 0)) {
      _timer = Timer(nextFrame.duration, forward);
    }

    setState(() {});
  }

  Widget getContentView() {
    switch (widget.imageLoader.state) {
      case LoadState.success:
        return RawImage(
          image: currentFrame,
          fit: widget.fit,
        );
      case LoadState.failure:
        return const Center(
            child: Text(
          "Image failed to load.",
          style: TextStyle(
            color: Colors.white,
          ),
        ));
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          getContentView(),
          Positioned(
            bottom: 0,
            child: LoadingWidget(progressing: widget.imageLoader.state == LoadState.loading),
          )
        ],
      ),
    );
  }
}
