import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AnalyticsTimeline {
  sevenDays("7D", 7),
  thirtyDays("30D", 30),
  ninetyDays("90D", 90),
  all("All", 3650); // Arbitrary large number for "All"

  final String label;
  final int days;
  const AnalyticsTimeline(this.label, this.days);
}

class AnalyticsTimelineNotifier extends Notifier<AnalyticsTimeline> {
  @override
  AnalyticsTimeline build() {
    return AnalyticsTimeline.sevenDays;
  }

  void setTimeline(AnalyticsTimeline timeline) {
    state = timeline;
  }
}

final analyticsTimelineProvider =
    NotifierProvider<AnalyticsTimelineNotifier, AnalyticsTimeline>(
      AnalyticsTimelineNotifier.new,
    );
