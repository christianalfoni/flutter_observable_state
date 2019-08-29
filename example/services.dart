import 'package:get_it/get_it.dart';

import 'AppActions.dart';
import 'AppState.dart';
import 'ConsoleEffect.dart';

final getIt = GetIt();

void initialize() {
  getIt.registerSingleton(AppState());
  getIt.registerSingleton(ConsoleEffect());
  getIt.registerSingleton(AppActions());
}
