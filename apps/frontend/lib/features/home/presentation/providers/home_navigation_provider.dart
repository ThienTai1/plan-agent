import 'package:flutter_riverpod/flutter_riverpod.dart';

final homeNavigationProvider = NotifierProvider<HomeNavigationNotifier, int>(
  HomeNavigationNotifier.new,
);

class HomeNavigationNotifier extends Notifier<int> {
  @override
  int build() {
    return 0;
  }

  void setIndex(int index) {
    state = index;
  }
}
