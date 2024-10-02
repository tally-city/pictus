<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages).
-->

Simple and useful flutter library for picking/editing images on the go.

## Features

- Pick images from gallery and edit them
- Advanced camera for capturing images and edit them on the go

## Getting started

Just import the library and use it as in the example.

## Usage
First install the library:
``` console
flutter pub add pictus
```
Then, to use the pick, or capture features, simply use them by calling `Pictus.pickImage` or `Pictus.capture` like this:

```dart
// inside your stateful widget
List<XFile> images;

// then in some button press or other interaction
Pictus.pickImage(
  context,
  maxHeight: 1000,
  maxWidth: 1000,
  source: ImageSource.gallery,
  tools: [PhotoEditTool.crop],
  maxNumberOfImages: 3,
).then((value) {
  setState(() {
    if (value != null) images = value;
  });
});
```

## Additional information

To be filled in the future
