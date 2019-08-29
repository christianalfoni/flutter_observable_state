# flutter_observable_state
Observable state for flutter applications

## Motivation
Coming from the world of state management in Javascript/Typescript, I felt that the current solutions to state management with Flutter was too verbose. Building libraries like [CerebralJS](https://www.cerebraljs.com) and [OvermindJS](https://overmindjs.org), I took inspiration from that work and built this simple approach to managing state in Flutter.

## The concept

```dart
class AppState {
  final count = Observable(0);
}
```

Now you have an observable piece of state, lets use it in a widget.

```dart
// For simplicity we just instantiate, please read
// further for proper setup
final _state = AppState()

class MyWidget extends StatelessWidget {
  @override
  Widget build(context) {
    return Container(
      child: observe(() => (
        Row(
          children: [
            Text(_state.count.get()),
            FlatButton(
              onPressed: () {
                _state.count.change((count) => count + 1)
              },
              child: Text("Increase count")
            )
          ]
        )
      ))
    )
  }
}
```

Any widgets returned within the scope of the `observe` function will rerender when any state it accesses changes. You can use as many `observe` you want within a widget, even nest them. 

## Organizing your project

When you think about state as application state you will rather define and change the state of the application outside of your widgets. You will still need local widget state, but you primarily want to put your state outside the widgets. To effectively share this state and the logic to change it with all widgets of your application it is highly recommended to use the [get_it](https://pub.dev/packages/get_it) project. Let us create our initial setup.

We want to create two classes. **AppState** and **Actions**. We can use **get_it** to create a single instance of these classes, which can then be used in any widget.

```dart
// services.dart
import 'package:my_project/AppState.dart';
import 'package:my_project/Actions.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt();

void initialize() {
  getIt.registerSingleton(AppState());
  getIt.registerSingleton(Actions());
}
```

You can use this file to also register effects you want to perform. For example classes that manages communication with Firebase etc.

```dart
// AppState.dart
import 'package:flutter_observable_state/flutter_observable_state.dart';

class AppState {
  final count = Observable(0);
}

// Actions.dart
import 'package:my_project/AppState.dart';
import 'package:my_project/services.dart';

class Actions {
  final _state = getIt.get<AppState>();

  void changeCount(int count) {
    _state.count.change((currentCount) => currentCount + count)
  }
}
```

Now in a widget you are able to do:

```dart
class MyWidget extends StatelessWidget {
  final _state = getIt.get<AppState>()
  final _actions = getIt.get<Actions>()

  @override
  Widget build(context) {
    return Container(
      child: observe(() => (
        Row(
          children: [
            Text(_state.count.get()),
            FlatButton(
              onPressed: () {
                _actions.changeCount(1)
              },
              child: Text("Increase count")
            )
          ]
        )
      ))
    )
  }
}
```

We have now effectively allowed any widget to access our count and any widget can change it, making sure that any widget observing the state will rerender.

## API

### Observable

Create an observable value.

```dart
Observable(0);
Observable<List<String>> = Observable([]);
Observable<User>(null);
```

### Observable.get

Get the value of an **Observable**.

```dart
var count = Observable(0);

count.get(); // 0
```

### Observable.set

Set the value of an **Observable**.

```dart
var count = Observable(0);

count.set(1);
```

### Observable.change

Change the value of an **Observable**.

```dart
var count = Observable(0);

count.change((currentCount) => currentCount + 1);
```

### Observable.setStream

Connect a stream of values, making the **Observable** update whenever the stream passes a new value.

```dart
var user = Observable<FirebaseUser>(null);

user.setStream(FirebaseAuth.instance.onAuthStateChanged);

// Unset stream
user.setStream(null);
```

When a stream is set you can still **set** and **change** to a new value.

### Computed

You can derive state. This works much like the **observe**, but it only flags the computed as dirty. The next time something **get**s the value, it will be recalculated.

```dart
var foo = Observable('bar');
var upperFoo = Computed(() => foo.get().toUpperCase());
```

You will typically define computeds with your **AppState** class.

```dart
class AppState {
  final foo = Observable('bar');

  Computed<String> upperFoo;

  AppState() {
    upperFoo = Computed(() => foo.get().toUpperCase());
  }
}
```

### observe

To observe state in widgets you use the **observe** function. It returns a **StreamBuilder** and can be used wherever you typically insert a child widget.

```dart
class MyWidget extends StatelessWidget {
  final _state = getIt.get<AppState>();

  @override
  Widget build(context) {
    return Container(
      child: observe(() => (
        Text(_state.foo.get())
      ))    
    )
  }
}
```

### Reaction

You can observe state and react to it. This is useful when you need to do some imperative logic inside your widgets. For example here we are controlling an overlay from our application state:

```dart
class MyWidget extends StatefulWidget {
  @override
  createState() => MyWidgetState();
}

class MyWidgetState extends State<MyWidget> {
  final _state = getIt.get<AppState>();
  Reaction reaction;
  OverlayEntry overlay;

  @override
  void initState() {
    reaction = Reaction(
      () => _state.isOverlayOpen.get(),
      () => {
        if (_state.isOverlayOpen.get() && overlay == null) {
          overlay = _createOverlayEntry();
          Overlay.of(context).insert(overlay);
        } else if (!_state.isOverlayOpen.get() && overlay != null) {
          overlay.remove();
          overlay = null;
        }
      }
    )
    super.initState();
  }

  @override
  Widget build(context) {
    return Container(
      child: observe(() => (
        Text(_state.foo.get())
      ))
    )
  }
}
```

## Models

You can use **Observable** with whatever classes you want, even inside widgets. Typically though you want to use it with classes representing models. For example you want to track optimistically adding a like to posts.

```dart
// Post.dart
class Post {
  String id;
  String title;
  String description;
  Observable<bool> likesCount;

  Post.fromJSON(Map<String, dynamic> json) :
    id = json["id"],
    title = json["title"],
    description = json["description"],
    likesCount = Observable(json["likesCount"]);
}

// AppState.dart
class AppState {
  final posts = Observable<List<Post>>([]);
}

// Actions.dart
class Actions {
  final _state = getIt.get<AppState>();
  final _api = getIt.get<Api>();

  void initialize() {
    _state.posts.setStream(_api.$posts);
  }

  void likePost(Post post) {
    post.likesCount.change((likesCount) => likesCount + 1);
    _api.likePost(post.id);
  }
}
```

## How does it work?

Dart is a single threaded language, meaning that only one **observe** can run at any time. That means the library orchestrates the execution of **observe** and **Computed** with the execution of any **Observable.get** globally. The **Computed** are considered to live as long as the application lives, while **observe** uses the **StreamBuilder** where it clears out existing subscriptions when it builds and when the widget is disposed.