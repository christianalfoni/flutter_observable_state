import 'AppState.dart';
import 'ConsoleEffect.dart';
import 'services.dart';

class AppActions {
  final _state = getIt.get<AppState>();
  final _console = getIt.get<ConsoleEffect>();

  void increaseCount() {
    _state.count.change((count) => count + 1);
    _console.log("Count increased!");
  }
}
