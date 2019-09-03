# story_view [![Pub](https://img.shields.io/pub/v/story_view.svg)](https://pub.dev/packages/story_view)

Story view for apps with stories.

<p float="left">
  <img src="https://i.ibb.co/nqXTcTK/sv.gif" width=400 />
</p>


This a Flutter widget to display stories just like Whatsapp and Instagram. Can also be used
inline/inside ListView or Column just like Google News app. Comes with gestures
to pause, forward and go to previous page.

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

### Story controller, loaders and GIF support
While images load, it'll be a better experience to pause the stories until it's done. To achieve this effect, create a global instance of [`StoryController`]([`StoryItem`](https://pub.dev/documentation/story_view/latest/story_view/StoryController-class.html)) and use the shorthand `StoryItem.pageGif` or `StoryItem.inlineGif` while passing the controller to it.

🍭 `StoryItem.pageGif` and `StoryItem.inlineGif` can also load non-animated graphic media like PNG, JPG, etc.


```dart
...
final controller = StoryControlelr();

@override
Widget build(context) {
  List<StoryItem> storyItems = [
    StoryItem.text(...),
    StoryItem.pageImage(...),
    StoryItem.pageImage(...),
    StoryItem.pageGif(...,
      controller: controller,
      ...)
  ]; // your list of stories

  return StoryView(
    storyItems,
    controller: controller, // pass controller here too
    repeat: true, // should the stories be slid forever
    onStoryShow: (s) {notifyServer(s)}
  )
}
```
