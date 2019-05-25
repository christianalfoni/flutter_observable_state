// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_observable_state/flutter_observable_state.dart';
import 'package:rxdart/rxdart.dart' as rx;

class TestWidget extends StatelessWidget {
  StreamBuilder observer;
  
  TestWidget(this.observer);

  @override
  Widget build(context) {
    return Container(
      child: this.observer
    );
  }
}

class State {
  final foo = Observable("bar");
  Computed<String> upperFoo;

  State() {
    upperFoo = Computed(() => foo.get().toUpperCase());
  }
}

void main() {
  testWidgets('Updates when setting state', (WidgetTester tester) async {
    final state = State();

    await tester.pumpWidget(TestWidget(observe(() {
      return Text(state.foo.get(), textDirection: TextDirection.ltr);
    })));

    expect(find.text('bar'), findsOneWidget);

    state.foo.set("bar2");
    await tester.pump(Duration.zero);

    expect(find.text('bar2'), findsOneWidget);
  });

  testWidgets('Updates when changing state', (WidgetTester tester) async {
    final state = State();

    await tester.pumpWidget(TestWidget(observe(() {
      return Text(state.foo.get(), textDirection: TextDirection.ltr);
    })));

    expect(find.text('bar'), findsOneWidget);

    state.foo.change((text) => text.toUpperCase());
    await tester.pump(Duration.zero);

    expect(find.text('BAR'), findsOneWidget);
  });

  testWidgets('Updates when changing state', (WidgetTester tester) async {
    final state = State();

    await tester.pumpWidget(TestWidget(observe(() {
      return Text(state.foo.get(), textDirection: TextDirection.ltr);
    })));

    expect(find.text('bar'), findsOneWidget);

    state.foo.change((text) => text.toUpperCase());
    await tester.pump(Duration.zero);

    expect(find.text('BAR'), findsOneWidget);
  });


  testWidgets('Updates when stream updates', (WidgetTester tester) async {
    final state = State();
    var stream = rx.BehaviorSubject<String>();

    state.foo.setStream(stream);

    await tester.pumpWidget(TestWidget(observe(() {
      return Text(state.foo.get(), textDirection: TextDirection.ltr);
    })));

    expect(find.text('bar'), findsOneWidget);

    stream.add("bar2");
    await tester.pump(Duration.zero);

    expect(find.text('bar2'), findsOneWidget);
  });

  testWidgets('Computed state', (WidgetTester tester) async {
    final state = State();

    await tester.pumpWidget(TestWidget(observe(() {
      return Text(state.upperFoo.get(), textDirection: TextDirection.ltr);
    })));

    expect(find.text('BAR'), findsOneWidget);

    state.foo.set("baz");
    await tester.pump(Duration.zero);

    expect(find.text('BAZ'), findsOneWidget);
  });
}
