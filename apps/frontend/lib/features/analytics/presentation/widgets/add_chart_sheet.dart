import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:frontend/core/database/local_queries_providers.dart';
import 'package:uuid/uuid.dart';
import 'package:frontend/features/analytics/domain/models/analyst_chart.dart';
import 'package:frontend/features/analytics/presentation/providers/analyst_charts_provider.dart';

class AddChartSheet extends ConsumerStatefulWidget {
  final AnalystChart? chart;
  const AddChartSheet({super.key, this.chart});

  @override
  ConsumerState<AddChartSheet> createState() => _AddChartSheetState();
}

class _AddChartSheetState extends ConsumerState<AddChartSheet> {
  late TextEditingController _titleController;
  late ChartType _type;
  late ChartMetricType _metricType;
  late List<Color> _colors;
  String? _sourceGoalId;
  late TextEditingController _customPropertyController;
  late AggregationType _aggregationType;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.chart?.title);
    _type = widget.chart?.type ?? ChartType.line;
    _metricType = widget.chart?.metricType ?? ChartMetricType.taskCompletion;
    _colors =
        widget.chart?.colors ?? [Colors.blue, Colors.blue.withValues(alpha: 0.3)];
    _sourceGoalId = widget.chart?.sourceGoalId;
    _customPropertyController = TextEditingController(
      text: widget.chart?.customPropertyName,
    );
    _aggregationType = widget.chart?.aggregationType ?? AggregationType.sum;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _customPropertyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: AppPallete.getBackgroundColor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "New Insight Chart",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppPallete.getTextPrimary(context),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: "Chart Title",
                hintText: "e.g. Daily Focus Score",
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Metric Source",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppPallete.getTextSecondary(context),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ChartMetricType>(
              initialValue: _metricType,
              items: ChartMetricType.values.map((m) {
                return DropdownMenuItem(
                  value: m,
                  child: Text(m.name.toUpperCase()),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _metricType = val);
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: AppPallete.getCardColor(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            if (_metricType == ChartMetricType.custom) ...[
              const SizedBox(height: 24),
              Text(
                "Source Project",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppPallete.getTextSecondary(context),
                ),
              ),
              const SizedBox(height: 12),
              ref
                  .watch(allGoalsProvider)
                  .when(
                    data: (goals) => DropdownButtonFormField<String>(
                      initialValue: _sourceGoalId,
                      hint: const Text("Select Project"),
                      items: goals.map((g) {
                        return DropdownMenuItem(
                          value: g['id'] as String,
                          child: Text(g['title'] as String),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _sourceGoalId = val),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppPallete.getCardColor(context),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (e, s) => Text("Error loading projects: $e"),
                  ),
              const SizedBox(height: 16),
              TextField(
                controller: _customPropertyController,
                decoration: const InputDecoration(
                  labelText: "Custom Property Key (e.g. amount, pages)",
                  hintText: "Must match property in task's customProperties",
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Aggregation Method",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppPallete.getTextSecondary(context),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<AggregationType>(
                initialValue: _aggregationType,
                items: AggregationType.values.map((a) {
                  return DropdownMenuItem(
                    value: a,
                    child: Text(a.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _aggregationType = val);
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppPallete.getCardColor(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
            Text(
              "Visual Style",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppPallete.getTextSecondary(context),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildTypeChip(ChartType.line, Icons.show_chart, "Line"),
                const SizedBox(width: 8),
                _buildTypeChip(ChartType.bar, Icons.bar_chart, "Bar"),
                const SizedBox(width: 8),
                _buildTypeChip(ChartType.pie, Icons.pie_chart, "Pie"),
              ],
            ),
            const SizedBox(height: 24),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildColorOption([
                    Colors.blue,
                    Colors.blue.withValues(alpha: 0.3),
                  ]),
                  _buildColorOption([
                    Colors.purple,
                    Colors.purple.withValues(alpha: 0.3),
                  ]),
                  _buildColorOption([
                    Colors.amber,
                    Colors.amber.withValues(alpha: 0.3),
                  ]),
                  _buildColorOption([
                    Colors.green,
                    Colors.green.withValues(alpha: 0.3),
                  ]),
                  _buildColorOption([
                    Colors.pink,
                    Colors.pink.withValues(alpha: 0.3),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  if (_titleController.text.trim().isEmpty) return;

                  final newChart = AnalystChart(
                    id: widget.chart?.id ?? const Uuid().v4(),
                    title: _titleController.text.trim(),
                    type: _type,
                    data:
                        widget.chart?.data ??
                        (widget.chart != null
                            ? []
                            : [
                                ChartDataPoint("Mon", 12.0),
                                ChartDataPoint("Tue", 15.0),
                                ChartDataPoint("Wed", 8.0),
                                ChartDataPoint("Thu", 22.0),
                                ChartDataPoint("Fri", 18.0),
                                ChartDataPoint("Sat", 25.0),
                                ChartDataPoint("Sun", 30.0),
                              ]),
                    colors: _colors,
                    metricType: _metricType,
                    sourceGoalId: _sourceGoalId,
                    customPropertyName: _metricType == ChartMetricType.custom
                        ? _customPropertyController.text.trim()
                        : null,
                    aggregationType: _aggregationType,
                  );

                  if (widget.chart == null) {
                    ref.read(analystChartsProvider.notifier).addChart(newChart);
                  } else {
                    ref
                        .read(analystChartsProvider.notifier)
                        .updateChart(newChart);
                  }
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPallete.getPrimaryColor(context),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  widget.chart == null ? "Create Chart" : "Save Changes",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorOption(List<Color> palette) {
    final isSelected = _colors.first.toARGB32() == palette.first.toARGB32();
    return GestureDetector(
      onTap: () => setState(() => _colors = palette),
      child: Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: palette.first,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: palette.first.withValues(alpha: 0.4),
                blurRadius: 8,
                spreadRadius: 2,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(ChartType type, IconData icon, String label) {
    final isSelected = _type == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _type = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppPallete.getPrimaryColor(context).withValues(alpha: 0.1)
                : AppPallete.getCardColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppPallete.getPrimaryColor(context)
                  : AppPallete.getBorderColor(context),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected
                    ? AppPallete.getPrimaryColor(context)
                    : AppPallete.getTextSecondary(context),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? AppPallete.getPrimaryColor(context)
                      : AppPallete.getTextSecondary(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
