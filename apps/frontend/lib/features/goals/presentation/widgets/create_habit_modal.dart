import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:frontend/features/goals/domain/models/habit.dart';
import 'package:frontend/features/goals/presentation/providers/habits_notifier.dart';
import 'package:frontend/core/common/providers/app_user_notifier.dart';
import 'package:uuid/uuid.dart';

class CreateHabitModal extends ConsumerStatefulWidget {
  const CreateHabitModal({super.key});

  @override
  ConsumerState<CreateHabitModal> createState() => _CreateHabitModalState();
}

class _CreateHabitModalState extends ConsumerState<CreateHabitModal> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _repeat = 'daily';

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final habit = Habit(
        id: const Uuid().v4(),
        userId: ref.read(appUserNotifierProvider)?.id ?? '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        startDate: DateTime.now(),
        status: 'active',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        customProperties: {
          'recurrence_rule': _repeat,
          'completions': [],
          'streak': 0,
        },
      );

      ref.read(habitsNotifierProvider.notifier).createHabit(habit).then((_) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Habit created successfully!')),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppPallete.getBackgroundColor(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDragHandle(),
                  const SizedBox(height: 20),
                  Text(
                    'New Habit',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppPallete.getTextPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _titleController,
                    style: TextStyle(color: AppPallete.getTextPrimary(context)),
                    decoration: InputDecoration(
                      hintText: 'What habit do you want to build?',
                      hintStyle: TextStyle(color: AppPallete.getTextMuted(context)),
                      filled: true,
                      fillColor: AppPallete.getSecondarySurface(context),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (v) => v!.isEmpty ? 'Please enter a title' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    style: TextStyle(color: AppPallete.getTextPrimary(context)),
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Why is this habit important?',
                      hintStyle: TextStyle(color: AppPallete.getTextMuted(context)),
                      filled: true,
                      fillColor: AppPallete.getSecondarySurface(context),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildRepeatSelector(),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppPallete.getPrimaryColor(context),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('Create Habit', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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

  Widget _buildRepeatSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Frequency',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppPallete.getTextSecondary(context),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _repeatChip('daily', 'Daily'),
            const SizedBox(width: 8),
            _repeatChip('weekly', 'Weekly'),
            const SizedBox(width: 8),
            _repeatChip('monthly', 'Monthly'),
          ],
        ),
      ],
    );
  }

  Widget _repeatChip(String value, String label) {
    final isSelected = _repeat == value;
    return ChoiceChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (val) => setState(() => _repeat = value),
      selectedColor: AppPallete.getPrimaryColor(context).withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppPallete.getPrimaryColor(context) : AppPallete.getTextSecondary(context),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
