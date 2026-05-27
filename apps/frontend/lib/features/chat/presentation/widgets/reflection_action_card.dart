import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:frontend/features/chat/presentation/widgets/action_cards.dart';

/// Reflection Action Card — Weekly review template with guided questions and CTA.
class ReflectionActionCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback? onNavigate;

  const ReflectionActionCard({
    super.key,
    required this.data,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final weekSummary = data['week_summary'] ?? '';
    final questions = (data['questions'] as List?) ?? [];
    final ctaLabel = data['cta_label'] ?? 'Start Journal Entry';

    return ChatActionCard(
      category: 'Reflection',
      title: 'Weekly Review',
      icon: LucideIcons.sparkles,
      accentColor: const Color(0xFF8B5CF6),
      showCategory: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (weekSummary.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                    const Color(0xFF8B5CF6).withValues(alpha: 0.02),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'THE WEEK IN REVIEW',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.8),
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    weekSummary,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: AppPallete.getTextPrimary(context).withValues(alpha: 0.9),
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ),
            ),
          
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'DEEP REFLECTION',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: AppPallete.getTextMuted(context),
                letterSpacing: 1,
              ),
            ),
          ),
          
          ...List.generate(questions.length, (index) {
            final q = questions[index] as Map<String, dynamic>;
            return _buildQuestionItem(context, q, index + 1);
          }),

          const SizedBox(height: 12),
          _buildCTAButton(context, ctaLabel),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildCTAButton(BuildContext context, String label) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onNavigate,
        icon: const Icon(LucideIcons.pen_tool, size: 14),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8B5CF6),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionItem(
    BuildContext context,
    Map<String, dynamic> question,
    int number,
  ) {
    final prompt = question['prompt'] ?? '';
    final placeholder = question['placeholder'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPallete.getSurfaceContainerLow(context).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppPallete.getBorderColor(context).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number.',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prompt,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppPallete.getTextPrimary(context),
                    height: 1.4,
                    letterSpacing: -0.2,
                  ),
                ),
                if (placeholder != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    placeholder,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppPallete.getTextMuted(context),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
