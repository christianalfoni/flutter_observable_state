import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

Observer currentObserver;

class Observer {
  Map<Stream, StreamSubscription> _subscriptions = Map();
  BehaviorSubject _subject;

  Observer() {
    _subject = BehaviorSubject.seeded(null);
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

  addListener(Stream rxObservable) {
    if (_subscriptions.containsKey(rxObservable)) {
      return;
    }

    _subscriptions[rxObservable] = rxObservable.skip(1).listen((data) {
      _subject.add(data);
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
  StreamSubscription _listenSubscription;
  bool _isMounted = false;

  _ObserverWidgetState() {
    _observer = Observer();
  }

  @override
  void initState() {
    _listenSubscription = _observer._subject.stream.listen((data) {
      if (_isMounted) {
        setState(() {});
      }
    });
    _isMounted = true;
    super.initState();
  }

  @override
  void dispose() {
    _isMounted = false;
    _listenSubscription.cancel();
    _observer._clear();
    super.dispose();
  }

  @override
  Widget build(context) {
    _observer._clear();

    final observer = currentObserver;
    currentObserver = this._observer;
    final result = widget.cb();
    currentObserver = observer;

    return result;
  }
}

class Reaction extends Observer {
  dynamic Function() trackCb;
  void Function() cb;

  Reaction(this.trackCb, this.cb) : super() {
    _subject.stream.skip(1).listen((_) {
      cb();
    });

    var previousObserver = currentObserver;
    currentObserver = this;
    trackCb();
    currentObserver = previousObserver;
  }

  void dispose() {
    _clear();
  }
}

Widget observe(Widget Function() cb) {
  return ObserverWidget(cb);
}

class Observable<T> {
  StreamSubscription<T> _stream;
  BehaviorSubject<T> _subject;
  Stream<T> get $stream => _subject.stream;

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
    this._subject = BehaviorSubject.seeded(initialValue);
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

    if (currentObserver != null) {
      final observer = currentObserver;
      currentObserver.addListener(_subject);
      /*
      observer._subscriptions[_subject.stream] = _subject.stream.listen((data) {
        observer._subject.add(data);
      });
      */
    }

    return _cachedResult;
  }
}
