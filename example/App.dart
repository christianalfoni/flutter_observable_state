import 'package:flutter/material.dart';
import 'package:flutter_observable_state/flutter_observable_state.dart';

import 'AppActions.dart';
import 'AppState.dart';
import 'services.dart';

class App extends StatelessWidget {
  final _state = getIt.get<AppState>();
  final _actions = getIt.get<AppActions>();

  @override
  Widget build(context) {
    return MaterialApp(
        title: 'Example',
        home: observe(() => (Center(
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                  Text(_state.count.get().toString()),
                  FlatButton(
                      onPressed: () {
                        _actions.increaseCount();
                      },
                      child: Text("Increase"))
                ])))));
  }
}
