# story_view [![Pub](https://img.shields.io/pub/v/story_view.svg)](https://pub.dev/packages/story_view)

Story view for apps with stories.

![story_view](assets/story_view.png)

<p float="left">
  <img src="https://i.ibb.co/Q8Wtw62/Screenshot-1584263003.png" width=200 />
  <img src="https://i.ibb.co/bz0R9bd/Screenshot-1584263008.png" width=200 />
  <img src="https://i.ibb.co/NrLSbZv/Screenshot-1584263018.png" width=200 />
</p>

🍟 Watch video demo here: [story_view demo](https://youtu.be/yHAVCsWEKQE)

👨‍🚀 Demo project here: [storyexample](https://github.com/blackmann/storyexample.git)

This a Flutter widget to display stories just like Whatsapp and Instagram. Can also be used
inline/inside ListView or Column just like Google News app. Comes with gestures
to pause, forward and go to previous page.

# Features

🕹 Still image, GIF and video support (with caching enabled)

📍 Gesture for pause, rewind and forward

⚜️ Caption for each story item

🎈 Animated progress indicator for each story item

📱 Fullscreen or inline

And useful callback to perform meta functionalities including vertical swipe gestures.

# Installation

To use this plugin, add `story_view` as a [dependency in your pubspec.yaml file](https://flutter.io/platform-plugins/).

# Usage

Import the package into your code

```dart
import "package:story_view/story_view.dart";
```

Look inside `examples/example.dart` on how to use this library. You can copy
and paste the code into your `main.dart` and run to have a quick look.

## Basics

Use [`StoryView`](https://pub.dev/documentation/story_view/latest/story_view/StoryView-class.html) to add stories to screen or view heirarchy. `StoryView` requires a list of [`StoryItem`](https://pub.dev/documentation/story_view/latest/story_view/StoryItem-class.html), each of which describes the view to be displayed on each story page, duration and so forth. This gives you the freedom to customize each page of the story.

There are shorthands provided to create common pages.

`StoryItem.text` is a shorthand to create a story page that displays only text.

`StoryItem.pageImage` creates a story item to display images with a caption.

`StoryItem.inlineImage` creates a story item that is intended to be displayed in a linear view hierarchy like `List`
or `Column`

> 🍭 Both `.inlineImage` and `pageImage` support animated GIFs.

`StoryItem.pageVideo` creates a page story item with video media. Just provide your video url and get going.

### Story controller, loaders and GIF support

While images load, it'll be a better experience to pause the stories until it's done. To achieve this effect, create a global instance of [`StoryController`](https://pub.dev/documentation/story_view/latest/story_controller/StoryController-class.html) and use the shorthand `StoryItem.pageImage` or `StoryItem.inlineImage` while passing the same controller instance to it.

```dart
...
final controller = StoryController();

@override
Widget build(context) {
  List<StoryItem> storyItems = [
    StoryItem.text(...),
    StoryItem.pageImage(...),
    StoryItem.pageImage(...),
    StoryItem.pageVideo(
      ...,
      controller: controller,
    )
  ]; // your list of stories

  return StoryView(
    storyItems,
    controller: controller, // pass controller here too
    repeat: true, // should the stories be slid forever
    onStoryShow: (s) {notifyServer(s)},
    onComplete: () {},
    onVerticalSwipeComplete: (direction) {
      if (direction == Direction.down) {
        Navigator.pop(context);
      }
    } // To disable vertical swipe gestures, ignore this parameter.
      // Preferrably for inline story view.
  )
}
```

🍭 Now, tell your users some stories.

## Docs

Find docs from here: [pub.dev/story_view](https://pub.dev/documentation/story_view/latest/)
