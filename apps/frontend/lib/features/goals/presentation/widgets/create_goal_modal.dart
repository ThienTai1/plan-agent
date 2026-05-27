import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/common/providers/app_user_notifier.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:frontend/core/common/domain/models/goal.dart';
import 'package:frontend/features/goals/presentation/providers/goals_providers.dart';
import 'package:frontend/core/database/local_queries_providers.dart';
import 'package:frontend/features/goals/presentation/widgets/goal_icon_picker.dart';
import 'package:frontend/core/common/widgets/app_date_picker_sheet.dart';

class CreateGoalModal extends ConsumerStatefulWidget {
  const CreateGoalModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateGoalModal(),
    );
  }

  @override
  ConsumerState<CreateGoalModal> createState() => _CreateGoalModalState();
}

class _CreateGoalModalState extends ConsumerState<CreateGoalModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  DateTimeRange? _selectedRange;
  String? _selectedEmoji;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final picked = await AppDatePickerSheet.showRange(
      context: context,
      title: 'Goal Duration',
      subtitle: 'When do you want to achieve this?',
      initialRange: _selectedRange,
    );
    if (picked != null) {
      setState(() => _selectedRange = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRange == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a goal duration')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = ref.read(appUserNotifierProvider)?.id ?? '';
      final goal = Goal(
        id: '',
        userId: userId,
        title: _titleController.text.trim(),
        currentState: null,
        startDate: _selectedRange!.start,
        endDate: _selectedRange!.end,
        status: 'active',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        icon: _selectedEmoji,
        customProperties: null,
      );

      final repository = ref.read(goalsRepositoryProvider);
      final res = await repository.createGoal(goal);
      
      if (mounted) {
        res.fold(
          (l) => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l.message)),
          ),
          (r) {
            ref.invalidate(allGoalsProvider);
            ref.invalidate(activeGoalsProvider);
            Navigator.pop(context);
          },
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 12,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 40,
      ),
      decoration: BoxDecoration(
        color: AppPallete.getBackgroundColor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDragHandle(),
          const SizedBox(height: 12),
          Text(
            'New Goal',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppPallete.getTextPrimary(context),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 32),
          Form(
            key: _formKey,
            child: Column(
              children: [
                _buildIconPicker(),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _titleController,
                  autofocus: true,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppPallete.getTextPrimary(context),
                  ),
                  decoration: AppPallete.getInputDecoration(
                    context,
                    hintText: 'What is your main goal?',
                  ).copyWith(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Please enter a goal'
                      : null,
                ),
                const SizedBox(height: 24),
                _buildDatePicker(),
                const SizedBox(height: 32),
                _buildSubmitButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppPallete.getTextMuted(context).withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildIconPicker() {
    return GestureDetector(
      onTap: () {
        GoalIconPicker.show(context, (emoji) {
          setState(() => _selectedEmoji = emoji);
        });
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppPallete.getSecondarySurface(context),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppPallete.getBorderColor(context).withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: Center(
          child: _selectedEmoji == null
              ? Icon(
                  Icons.add_reaction_outlined,
                  size: 32,
                  color: AppPallete.getTextSecondary(context),
                )
              : Text(
                  _selectedEmoji!,
                  style: const TextStyle(fontSize: 40),
                ),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () => _pickDateRange(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: AppPallete.getCardColor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppPallete.getBorderColor(context).withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              color: AppPallete.getPrimaryColor(context),
              size: 20,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Goal Duration',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppPallete.getTextSecondary(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedRange == null
                        ? 'Select start & end dates'
                        : '${_selectedRange!.start.year}-${_selectedRange!.start.month.toString().padLeft(2, '0')}-${_selectedRange!.start.day.toString().padLeft(2, '0')} '
                            'to ${_selectedRange!.end.year}-${_selectedRange!.end.month.toString().padLeft(2, '0')}-${_selectedRange!.end.day.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppPallete.getTextPrimary(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppPallete.getTextMuted(context),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppPallete.getPrimaryColor(context),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Create Goal',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}
