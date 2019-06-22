import 'dart:math';
import 'dart:ui';
import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Indicates where the progress indicators should be placed.
enum ProgressPosition { top, bottom }

/// This is used to specify the height of the progress indicator. Inline stories
/// should use [small]
enum IndicatorHeight { small, large }

/// This is a representation of a story item (or page).
class StoryItem {
  /// Specifies how long the page should be displayed. It should be a reasonable
  /// amount of time greater than 0 milliseconds.
  final Duration duration;

  /// Has this page been shown already? This is used to indicate that the page
  /// has been displayed. If some pages are supposed to be skipped in a story,
  /// mark them as shown `shown = true`.
  ///
  /// However, during initialization of the story view, all pages after the
  /// last unshown page will have their `shown` attribute altered to false. This
  /// is because the next item to be displayed is taken by the last unshown
  /// story item.
  bool shown;

  /// The page content
  final Widget view;

  StoryItem(
    this.view, {
    this.duration = const Duration(seconds: 3),
    this.shown = false,
  }) : assert(duration != null, "[duration] should not be null");

  /// Short hand to create text-only page.
  ///
  /// [title] is the text to be displayed on [backgroundColor]. The text color
  /// alternates between [Colors.black] and [Colors.white] depending on the
  /// calculated contrast. This is to ensure readability of text.
  ///
  /// Works for inline and full-page stories. See [StoryView.inline] for more on
  /// what inline/full-page means.
  static StoryItem text(
    String title,
    Color backgroundColor, {
    bool shown = false,
    double fontSize = 18,
    bool roundedTop = false,
    bool roundedBottom = false,
  }) {
    double contrast = ContrastHelper.contrast([
      backgroundColor.red,
      backgroundColor.green,
      backgroundColor.blue,
    ], [
      255,
      255,
      255
    ] /** white text */);

    return StoryItem(
        Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(roundedTop ? 8 : 0),
              bottom: Radius.circular(roundedBottom ? 8 : 0),
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: contrast > 1.8 ? Colors.white : Colors.black,
                fontSize: fontSize,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          //color: backgroundColor,
        ),
        shown: shown);
  }

  /// Shorthand for a full-page image content.
  ///
  /// You can provide any image provider for [image].
  static StoryItem pageImage(
    ImageProvider image, {
    BoxFit imageFit = BoxFit.fitWidth,
    String caption,
    bool shown = false,
  }) {
    assert(imageFit != null, "[imageFit] should not be null");
    return StoryItem(
        Container(
          color: Colors.black,
          child: Stack(
            children: <Widget>[
              Center(
                child: Image(
                  image: image,
                  height: double.infinity,
                  width: double.infinity,
                  fit: imageFit,
                ),
              ),
              SafeArea(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(
                      bottom: 24,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    color:
                        caption != null ? Colors.black54 : Colors.transparent,
                    child: caption != null
                        ? Text(
                            caption,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          )
                        : SizedBox(),
                  ),
                ),
              )
            ],
          ),
        ),
        shown: false);
  }

  /// Shorthand for creating inline image page.
  static StoryItem inlineImage(
    ImageProvider image, {
    Text caption,
    bool shown = false,
    bool roundedTop = true,
    bool roundedBottom = false,
  }) {
    return StoryItem(
      Container(
        decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(roundedTop ? 8 : 0),
              bottom: Radius.circular(roundedBottom ? 8 : 0),
            ),
            image: DecorationImage(
              image: image,
              fit: BoxFit.cover,
            )),
        child: Container(
          margin: EdgeInsets.only(
            bottom: 16,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 8,
          ),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Container(
              child: caption == null ? SizedBox() : caption,
              width: double.infinity,
            ),
          ),
        ),
      ),
      shown: shown,
    );
  }
}

/// Widget to display stories just like Whatsapp and Instagram. Can also be used
/// inline/inside lists just like Google News app. Comes with gestures
/// to pause, forward and go to previous page.
class StoryView extends StatefulWidget {
  /// The pages to displayed.
  final List<StoryItem> storyItems;

  /// Callback for when a full cycle of story is shown. This will be called
  /// each time the full story completes when [repeat] is set to `true`.
  final VoidCallback onComplete;

  /// Callback for when a story is currently being shown.
  final ValueChanged<StoryItem> onStoryShow;

  /// Where the progress indicator should be placed.
  final ProgressPosition progressPosition;

  /// Should the story be repeated forever?
  final bool repeat;

  /// If you would like to display the story as full-page, then set this to
  /// `false`. But in case you would display this as part of a page (eg. in
  /// a [ListView] or [Column]) then set this to `true`.
  final bool inline;

  StoryView(
    this.storyItems, {
    this.onComplete,
    this.onStoryShow,
    this.progressPosition = ProgressPosition.top,
    this.repeat = false,
    this.inline = false,
  })  : assert(storyItems != null && storyItems.length > 0,
            "[storyItems] should not be null or empty"),
        assert(progressPosition != null, "[progressPosition] cannot be null"),
        assert(
          repeat != null,
          "[repeat] cannot be null",
        ),
        assert(inline != null, "[inline] cannot be null");

  @override
  State<StatefulWidget> createState() {
    return StoryViewState();
  }
}

class StoryViewState extends State<StoryView> with TickerProviderStateMixin {
  StoryViewState();

  AnimationController animationController;
  Animation<double> currentAnimation;
  Timer debouncer;

  StoryItem get lastShowing =>
      widget.storyItems.firstWhere((it) => !it.shown, orElse: () => null);

  @override
  void initState() {
    super.initState();

    // All pages after the first unshown page should have their shown value as
    // false

    final firstPage = widget.storyItems.firstWhere((it) {
      return !it.shown;
    }, orElse: () {
      widget.storyItems.forEach((it2) {
        it2.shown = false;
      });

      return null;
    });

    if (firstPage != null) {
      final lastShownPos = widget.storyItems.indexOf(firstPage);
      widget.storyItems.sublist(lastShownPos).forEach((it) {
        it.shown = false;
      });
    }

    play();
  }

  @override
  void dispose() {
    animationController?.dispose();
    super.dispose();
  }

  void play() {
    animationController?.dispose();
    // get the next playing page
    final storyItem = widget.storyItems.firstWhere((it) {
      return !it.shown;
    });

    if (widget.onStoryShow != null) {
      widget.onStoryShow(storyItem);
    }

    animationController =
        AnimationController(duration: storyItem.duration, vsync: this);

    animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        storyItem.shown = true;
        if (widget.storyItems.last != storyItem) {
          beginPlay();
        } else {
          // done playing
          onComplete();
        }
      }
    });

    currentAnimation = Tween(begin: 0.0, end: 1.0).animate(animationController);
    animationController.forward();
  }

  void beginPlay() {
    setState(() {});
    play();
  }

  void onComplete() {
    if (widget.onComplete != null) {
      widget.onComplete();
    } else {
      print("Done");
    }

    if (widget.repeat) {
      widget.storyItems.forEach((it) {
        it.shown = false;
      });

      beginPlay();
    }
  }

  void goBack() {
    animationController.stop();

    if (this.lastShowing == null) {
      widget.storyItems.last.shown = false;
    }

    if (this.lastShowing == widget.storyItems.first) {
      beginPlay();
    } else {
      this.lastShowing.shown = false;
      int lastPos = widget.storyItems.indexOf(this.lastShowing);
      final previous = widget.storyItems[lastPos - 1];

      previous.shown = false;

      beginPlay();
    }
  }

  void goForward() {
    if (this.lastShowing != widget.storyItems.last) {
      animationController.stop();

      // get last showing
      final _last = this.lastShowing;

      if (_last != null) {
        _last.shown = true;
        if (_last != widget.storyItems.last) {
          beginPlay();
        }
      }
    }
  }

  void pause() {
    this.animationController?.stop(canceled: false);
  }

  void unpause() {
    this.animationController?.forward();
  }

  Widget get currentView => widget.storyItems
      .firstWhere((it) => !it.shown, orElse: () => widget.storyItems.last)
      .view;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Stack(
        children: <Widget>[
          currentView,
          Align(
            alignment: widget.progressPosition == ProgressPosition.top
                ? Alignment.topCenter
                : Alignment.bottomCenter,
            child: SafeArea(
              bottom: widget.inline ? false : true,
              // we use SafeArea here for notched and bezeles phones
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: PageBar(
                  widget.storyItems
                      .map((it) => PageData(it.duration, it.shown))
                      .toList(),
                  this.currentAnimation,
                  key: UniqueKey(),
                  indicatorHeight: widget.inline
                      ? IndicatorHeight.small
                      : IndicatorHeight.large,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            heightFactor: 1,
            child: RawGestureDetector(
              gestures: <Type, GestureRecognizerFactory>{
                TapGestureRecognizer:
                    GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
                        () => TapGestureRecognizer(), (instance) {
                  instance
                    ..onTapDown = (details) {
                      pause();
                      debouncer?.cancel();
                      debouncer = Timer(Duration(milliseconds: 500), () {});
                    }
                    ..onTapUp = (details) {
                      if (debouncer?.isActive == true) {
                        debouncer.cancel();
                        debouncer = null;

                        goForward();
                      } else {
                        debouncer.cancel();
                        debouncer = null;

                        unpause();
                      }
                    };
                })
              },
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            heightFactor: 1,
            child: SizedBox(
              child: GestureDetector(
                onTap: () {
                  goBack();
                },
              ),
              width: 70,
            ),
          ),
        ],
      ),
    );
  }
}

/// Capsule holding the duration and shown property of each story. Passed down
/// to the pages bar to render the page indicators.
class PageData {
  Duration duration;
  bool shown;

  PageData(this.duration, this.shown);
}

/// Horizontal bar displaying a row of [StoryProgressIndicator] based on the
/// [pages] provided.
class PageBar extends StatefulWidget {
  final List<PageData> pages;
  final Animation<double> animation;
  final IndicatorHeight indicatorHeight;

  PageBar(
    this.pages,
    this.animation, {
    this.indicatorHeight = IndicatorHeight.large,
    Key key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return PageBarState();
  }
}

class PageBarState extends State<PageBar> {
  double spacing = 4;

  @override
  void initState() {
    super.initState();

    int count = widget.pages.length;
    spacing = count > 15 ? 1 : count > 10 ? 2 : 4;

    widget.animation.addListener(() {
      setState(() {});
    });
  }

  bool isPlaying(PageData page) {
    return widget.pages.firstWhere((it) => !it.shown, orElse: () => null) ==
        page;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: widget.pages.map((it) {
        return Expanded(
          child: Container(
            padding: EdgeInsets.only(
                right: widget.pages.last == it ? 0 : this.spacing),
            child: StoryProgressIndicator(
              isPlaying(it) ? widget.animation.value : it.shown ? 1 : 0,
              indicatorHeight:
                  widget.indicatorHeight == IndicatorHeight.large ? 5 : 3,
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Custom progress bar. Supposed to be lighter than the
/// original [ProgressIndicator], and rounded at the sides.
class StoryProgressIndicator extends StatelessWidget {
  /// From `0.0` to `1.0`, determines the progress of the indicator
  final double value;
  final double indicatorHeight;

  StoryProgressIndicator(
    this.value, {
    this.indicatorHeight = 5,
  }) : assert(indicatorHeight != null && indicatorHeight > 0,
            "[indicatorHeight] should not be null or less than 1");

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.fromHeight(
        this.indicatorHeight,
      ),
      foregroundPainter: IndicatorOval(
        Colors.white.withOpacity(0.8),
        this.value,
      ),
      painter: IndicatorOval(
        Colors.white.withOpacity(0.4),
        1.0,
      ),
    );
  }
}

class IndicatorOval extends CustomPainter {
  final Color color;
  final double widthFactor;

  IndicatorOval(this.color, this.widthFactor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = this.color;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, size.width * this.widthFactor, size.height),
            Radius.circular(3)),
        paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

/// Concept source: https://stackoverflow.com/a/9733420
class ContrastHelper {
  static double luminance(int r, int g, int b) {
    final a = [r, g, b].map((it) {
      double value = it.toDouble() / 255.0;
      return value <= 0.03928
          ? value / 12.92
          : pow((value + 0.055) / 1.055, 2.4);
    }).toList();

    return a[0] * 0.2126 + a[1] * 0.7152 + a[2] * 0.0722;
  }

  static double contrast(rgb1, rgb2) {
    return luminance(rgb2[0], rgb2[1], rgb2[2]) /
        luminance(rgb1[0], rgb1[1], rgb1[2]);
  }
}
