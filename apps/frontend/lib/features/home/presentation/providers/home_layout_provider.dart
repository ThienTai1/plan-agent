import 'package:flutter_riverpod/flutter_riverpod.dart';

enum HomeWidgetType { activeGoals, pinnedProjects, dailyQuote, analystChart }

class HomeLayoutState {
  final List<HomeWidgetType> visibleWidgets;
  final List<HomeWidgetType> hiddenWidgets;
  final String? backgroundImagePath; // Asset path or file path
  final bool isEditing;
  final double backgroundOpacity;
  final double blurIntensity;
  final double glassOpacity;
  final Map<HomeWidgetType, String> widgetSizes;

  const HomeLayoutState({
    this.visibleWidgets = const [
      HomeWidgetType.activeGoals,
      HomeWidgetType.pinnedProjects,
      HomeWidgetType.analystChart,
    ],
    this.hiddenWidgets = const [HomeWidgetType.dailyQuote],
    this.backgroundImagePath,
    this.isEditing = false,
    this.backgroundOpacity = 0.5,
    this.blurIntensity = 10.0,
    this.glassOpacity = 0.2,
    this.widgetSizes = const {HomeWidgetType.activeGoals: 'compact'},
  });

  HomeLayoutState copyWith({
    List<HomeWidgetType>? visibleWidgets,
    List<HomeWidgetType>? hiddenWidgets,
    String? backgroundImagePath,
    bool? isEditing,
    double? backgroundOpacity,
    double? blurIntensity,
    double? glassOpacity,
    Map<HomeWidgetType, String>? widgetSizes,
  }) {
    return HomeLayoutState(
      visibleWidgets: visibleWidgets ?? this.visibleWidgets,
      hiddenWidgets: hiddenWidgets ?? this.hiddenWidgets,
      backgroundImagePath: backgroundImagePath ?? this.backgroundImagePath,
      isEditing: isEditing ?? this.isEditing,
      backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
      blurIntensity: blurIntensity ?? this.blurIntensity,
      glassOpacity: glassOpacity ?? this.glassOpacity,
      widgetSizes: widgetSizes ?? this.widgetSizes,
    );
  }
}

class HomeLayoutNotifier extends Notifier<HomeLayoutState> {
  @override
  HomeLayoutState build() {
    // TODO: Load from local storage
    return const HomeLayoutState();
  }

  void toggleEditMode() {
    state = state.copyWith(isEditing: !state.isEditing);
  }

  void reorderWidgets(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final List<HomeWidgetType> newWidgets = List.from(state.visibleWidgets);
    final HomeWidgetType item = newWidgets.removeAt(oldIndex);
    newWidgets.insert(newIndex, item);
    state = state.copyWith(visibleWidgets: newWidgets);
  }

  void setBackgroundImage(String? path) {
    state = state.copyWith(backgroundImagePath: path);
  }

  void setBackgroundOpacity(double opacity) {
    state = state.copyWith(backgroundOpacity: opacity);
  }

  void setBlurIntensity(double intensity) {
    state = state.copyWith(blurIntensity: intensity);
  }

  void setGlassOpacity(double opacity) {
    state = state.copyWith(glassOpacity: opacity);
  }

  void setWidgetSize(HomeWidgetType type, String size) {
    final newSizes = Map<HomeWidgetType, String>.from(state.widgetSizes);
    newSizes[type] = size;
    state = state.copyWith(widgetSizes: newSizes);
  }

  void toggleWidgetVisibility(HomeWidgetType type) {
    if (state.visibleWidgets.contains(type)) {
      final newVisible = List<HomeWidgetType>.from(state.visibleWidgets)
        ..remove(type);
      final newHidden = List<HomeWidgetType>.from(state.hiddenWidgets)
        ..add(type);
      state = state.copyWith(
        visibleWidgets: newVisible,
        hiddenWidgets: newHidden,
      );
    } else {
      final newHidden = List<HomeWidgetType>.from(state.hiddenWidgets)
        ..remove(type);
      final newVisible = List<HomeWidgetType>.from(state.visibleWidgets)
        ..add(type);
      state = state.copyWith(
        visibleWidgets: newVisible,
        hiddenWidgets: newHidden,
      );
    }
  }
}

final homeLayoutProvider =
    NotifierProvider<HomeLayoutNotifier, HomeLayoutState>(
      HomeLayoutNotifier.new,
    );
