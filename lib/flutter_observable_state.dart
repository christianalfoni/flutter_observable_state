import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart' as rx;

Observer currentObserver;

class Observer {
  Map<rx.Observable, StreamSubscription> _subscriptions = Map();
  rx.BehaviorSubject _subject = rx.BehaviorSubject();

  Observer() {
    _subject.onCancel = () {
      _clear();
    };
  }

  _clear() {
    _subscriptions.forEach((observable, subscription) {
      subscription.cancel();
    });
    _subscriptions.clear();
  }

  addListener(rx.Observable rxObservable) {
    if (_subscriptions.containsKey(rxObservable)) {
      return;
    }

    _subscriptions[rxObservable] = rxObservable.skip(1).listen((data) {
      _subject.add(data);
    });
  }

  StreamBuilder getStreamBuilder(Widget Function() cb) {
    return StreamBuilder(
        stream: _subject.stream,
        builder: (_, __) {
          _clear();

          final observer = currentObserver;
          currentObserver = this;
          final result = cb();
          currentObserver = observer;

          return result;
        });
  }
}

class ObserverWidget extends StatefulWidget {
  final Widget Function() cb;
  ObserverWidget(this.cb);
  State createState() => _ObserverWidgetState();
}

class _ObserverWidgetState extends State<ObserverWidget> {
  Observer _observer;

  _ObserverWidgetState() {
    _observer = Observer();
  }

  @override
  void dispose() {
    _observer._clear();
    super.dispose();
  }

  @override
  Widget build(context) {
    return _observer.getStreamBuilder(widget.cb);
  }
}

Widget observe(Widget Function() cb) {
  return ObserverWidget(cb);
}

class Observable<T> {
  StreamSubscription<T> _stream;
  rx.BehaviorSubject<T> _subject;
  rx.Observable<T> get $stream => _subject.stream;

  T get() {
    if (currentObserver != null) {
      currentObserver.addListener($stream);
    }

    return _subject.value;
  }

  void setStream(Stream<T> stream) {
    if (_stream != null) {
      _stream.cancel();
    }

    if (stream == null) {
      return;
    }

    _stream = stream.listen((value) => _subject.add(value));
  }

  void set(T newValue) {
    _subject.add(newValue);
  }

  void change(T Function(T) cb) {
    _subject.add(cb(_subject.value));
  }

  Observable(T initialValue) {
    this._subject = rx.BehaviorSubject.seeded(initialValue);
  }
}

class Computed<T> extends Observer {
  T Function() cb;
  bool _isDirty = true;
  dynamic _cachedResult;

  Computed(this.cb) : super() {
    _subject.stream.listen((_) {
      _isDirty = true;
    });
  }

  T get() {
    if (_isDirty) {
      _clear();
      var previousObserver = currentObserver;
      currentObserver = this;
      _cachedResult = cb();
      currentObserver = previousObserver;
      _isDirty = false;
    }

    if (currentObserver != null &&
        !_subscriptions.containsKey(_subject.stream)) {
      final observer = currentObserver;
      observer._subscriptions[_subject.stream] = _subject.stream.listen((data) {
        observer._subject.add(data);
      });
    }

    return _cachedResult;
  }
}
