import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class AIAssistantSheet extends StatefulWidget {
  const AIAssistantSheet({super.key});

  @override
  State<AIAssistantSheet> createState() => _AIAssistantSheetState();
}

class _AIAssistantSheetState extends State<AIAssistantSheet> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: AppPallete.getSurface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: AppPallete.getBorderColor(context).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              // Purple AI Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFEAFF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Icon(
                    LucideIcons.sparkles,
                    color: Color(0xFF6C4DDA),
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Welcome Text
              Text(
                'Hi! I\'m your AI Agent 👋',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppPallete.getTextPrimary(context),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'I can help you plan your day, break down goals, track progress, and give smart suggestions to keep you on track.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppPallete.getTextSecondary(context).withValues(alpha: 0.8),
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Feature Grid (2x2)
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: [
                  _buildFeatureCard(
                    context,
                    title: 'Goal Breakdown',
                    description: 'Turn big goals into actionable tasks',
                    icon: LucideIcons.target,
                    iconColor: const Color(0xFF6C4DDA),
                    iconBg: const Color(0xFFEFEAFF),
                    onTap: () => _handleQuickAction('🎯 Break down a goal'),
                  ),
                  _buildFeatureCard(
                    context,
                    title: 'Progress Insights',
                    description: 'Analyze your productivity patterns',
                    icon: LucideIcons.trending_up,
                    iconColor: const Color(0xFF00B4D8),
                    iconBg: const Color(0xFFE0F7FA),
                    hasNotification: true,
                    onTap: () => _handleQuickAction('📊 My progress report'),
                  ),
                  _buildFeatureCard(
                    context,
                    title: 'Daily Planning',
                    description: 'Build your optimal schedule',
                    icon: LucideIcons.calendar,
                    iconColor: const Color(0xFF00C853),
                    iconBg: const Color(0xFFE8F5E9),
                    onTap: () => _handleQuickAction('📅 Plan my day'),
                  ),
                  _buildFeatureCard(
                    context,
                    title: 'Smart Suggestions',
                    description: 'Get priority & habit recommendations',
                    icon: LucideIcons.lightbulb,
                    iconColor: const Color(0xFFFFB300),
                    iconBg: const Color(0xFFFFF8E1),
                    onTap: () => _handleQuickAction('💡 Suggest priorities'),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Try Asking
              Text(
                'Try asking...',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppPallete.getTextMuted(context),
                ),
              ),
              const SizedBox(height: 16),
              
              // Suggestion Chips
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildSuggestionChip('📅 Plan my day'),
                  _buildSuggestionChip('🎯 Break down a goal'),
                  _buildSuggestionChip('📊 My progress report'),
                  _buildSuggestionChip('💡 Suggest priorities'),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Chat Input
              TextField(
                controller: _controller,
                style: TextStyle(color: AppPallete.getTextPrimary(context)),
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  hintStyle: TextStyle(
                    color: AppPallete.getTextMuted(context),
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: AppPallete.getSecondarySurface(context),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppPallete.getPrimaryColor(context),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _handleSendMessage,
                      icon: const Icon(LucideIcons.send, size: 18),
                      color: Colors.white,
                    ),
                  ),
                ),
                onSubmitted: (_) => _handleSendMessage(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required VoidCallback onTap,
    bool hasNotification = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppPallete.getBorderColor(context).withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(icon, color: iconColor, size: 18),
                    ),
                  ),
                  if (hasNotification)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppPallete.getTextPrimary(context),
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppPallete.getTextSecondary(context).withValues(alpha: 0.7),
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String label) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleQuickAction(label),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppPallete.getBorderColor(context).withValues(alpha: 0.4),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppPallete.getTextPrimary(context),
            ),
          ),
        ),
      ),
    );
  }

  void _handleQuickAction(String action) {
    _controller.text = action;
    _handleSendMessage();
  }

  void _handleSendMessage() {
    if (_controller.text.isNotEmpty) {
      _controller.clear();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI is thinking...'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
