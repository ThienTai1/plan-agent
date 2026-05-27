import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:frontend/features/chat/presentation/widgets/action_cards.dart';


/// Displays a checklist of bundled actions from the V3 LangGraph agent.
class BundleConfirmationWidget extends StatefulWidget {
  final List<Map<String, dynamic>> pendingActions;
  final Function(List<List<Map<String, dynamic>>>)? onConfirmList; // Legacy fallback if needed
  final Function(List<Map<String, dynamic>>) onConfirm;
  final VoidCallback onCancel;

  const BundleConfirmationWidget({
    super.key,
    required this.pendingActions,
    required this.onConfirm,
    required this.onCancel,
    this.onConfirmList,
  });

  @override
  State<BundleConfirmationWidget> createState() =>
      _BundleConfirmationWidgetState();
}

class _BundleConfirmationWidgetState extends State<BundleConfirmationWidget> {
  late List<bool> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.filled(widget.pendingActions.length, true);
  }

  @override
  Widget build(BuildContext context) {
    final actionCount = widget.pendingActions.where((a) {
      final type = (a['type'] ?? a['action'] ?? '').toString();
      return !ActionCardFactory.isInformational(type);
    }).length;
    final hasActions = actionCount > 0;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: EdgeInsets.zero,
      decoration: null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [



          // Checklist
          ...widget.pendingActions.asMap().entries.map((entry) {
            final i = entry.key;
            final action = entry.value;
            return _buildActionRow(context, i, action);
          }),

          if (hasActions) ...[
            const SizedBox(height: 16),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppPallete.getTextSecondary(context),
                      side:
                          BorderSide(color: AppPallete.getBorderColor(context)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selected.any((s) => s)
                        ? () {
                            final confirmed = <Map<String, dynamic>>[];
                            for (int i = 0;
                                i < widget.pendingActions.length;
                                i++) {
                              if (_selected[i]) {
                                confirmed.add(widget.pendingActions[i]);
                              }
                            }
                            widget.onConfirm(confirmed);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppPallete.getPrimaryColor(context),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                        'Confirm (${_selected.where((s) => s).length})'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionRow(
    BuildContext context,
    int index,
    Map<String, dynamic> action,
  ) {
    final type = (action['type'] ?? action['action'] ?? '').toString();
    final isInfo = ActionCardFactory.isInformational(type);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          if (!isInfo)
            Checkbox(
              value: _selected[index],
              onChanged: (v) {
                setState(() => _selected[index] = v ?? false);
              },
              activeColor: AppPallete.getPrimaryColor(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            )
          else
            const SizedBox(width: 4), // Small indent for info cards to align slightly
          Expanded(
            child: Opacity(
              opacity: isInfo || _selected[index] ? 1.0 : 0.5,
              child: ActionCardFactory(
                action: action,
                onConfirm: (_) {}, // No-op, handled by bundle
                onCancel: () {}, // No-op
                isCompact: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
