import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:frontend/features/profile/presentation/providers/achievements_provider.dart';

class GalleryPage extends ConsumerWidget {
  static const String routeName = '/gallery';

  const GalleryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(achievementsProvider);

    return Scaffold(
      backgroundColor: AppPallete.getBackgroundColor(context),
      body: SafeArea(
        child: achievementsAsync.when(
          data: (groups) {
            final totalWins = groups.fold<int>(0, (sum, group) => sum + group.items.length);
            
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 1. Header with Stats Summary
                SliverToBoxAdapter(
                  child: _buildTimelineHeader(context, totalWins),
                ),

                // 2. Timeline List
                if (groups.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(context),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final group = groups[index];
                          return _TimelineGroupWidget(
                            group: group,
                            isLastGroup: index == groups.length - 1,
                          );
                        },
                        childCount: groups.length,
                      ),
                    ),
                  ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error loading history: $err')),
        ),
      ),
    );
  }

  Widget _buildTimelineHeader(BuildContext context, int totalWins) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppPallete.getSurfaceContainerLow(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                  onPressed: () => Navigator.pop(context),
                  color: AppPallete.getTextPrimary(context),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'TOTAL WINS',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppPallete.getTextMuted(context),
                    ),
                  ),
                  Text(
                    '$totalWins',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppPallete.getPrimaryColor(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'Legacy\nTimeline',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: AppPallete.getTextPrimary(context),
              letterSpacing: -1.0,
              height: 1.0,
            ),
          ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
          const SizedBox(height: 12),
          Text(
            'Reflect on your journey and celebrate the goals you\'ve conquered.',
            style: TextStyle(
              fontSize: 15,
              color: AppPallete.getTextSecondary(context),
              height: 1.5,
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
          const SizedBox(height: 32),
          Divider(
            color: AppPallete.getBorderColor(context).withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppPallete.getSurfaceContainerLow(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.medal,
                size: 48,
                color: AppPallete.getTextMuted(context),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Achievements Yet',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppPallete.getTextPrimary(context),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your legacy starts here. Complete your first goal to see it on the timeline.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppPallete.getTextSecondary(context),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineGroupWidget extends StatelessWidget {
  final AchievementGroup group;
  final bool isLastGroup;

  const _TimelineGroupWidget({
    required this.group,
    required this.isLastGroup,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month/Year Header
        Padding(
          padding: const EdgeInsets.only(bottom: 24, top: 16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 2,
                color: AppPallete.getPrimaryColor(context).withValues(alpha: 0.3),
              ),
              const SizedBox(width: 12),
              Text(
                group.title,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppPallete.getPrimaryColor(context),
                  letterSpacing: 1.2,
                ),
              ).animate().fadeIn(),
            ],
          ),
        ),
        
        // Events in this group
        ...group.items.asMap().entries.map((entry) {
          final isLastInGroup = entry.key == group.items.length - 1;
          return _TimelineItemWidget(
            item: entry.value,
            showLine: !(isLastGroup && isLastInGroup),
          ).animate().fadeIn(delay: (entry.key * 100).ms).slideY(begin: 0.1);
        }).toList(),
      ],
    );
  }
}

class _TimelineItemWidget extends StatelessWidget {
  final AchievementItem item;
  final bool showLine;

  const _TimelineItemWidget({
    required this.item,
    this.showLine = true,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline Axis
          SizedBox(
            width: 44,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppPallete.getSurface(context),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: item.type == 'Goal' 
                        ? AppPallete.getPrimaryColor(context)
                        : AppPallete.secondaryColor,
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppPallete.getPrimaryColor(context).withValues(alpha: 0.2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                if (showLine)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppPallete.getBorderColor(context).withValues(alpha: 0.3),
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Goal Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppPallete.getCardColor(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppPallete.getBorderColor(context).withValues(alpha: 0.8),
                    width: 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (item.emoji != null)
                          Text(item.emoji!, style: const TextStyle(fontSize: 18))
                        else
                          Icon(
                            item.type == 'Goal' ? LucideIcons.trophy : LucideIcons.flag,
                            size: 18,
                            color: AppPallete.getTextPrimary(context),
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.title,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppPallete.getTextPrimary(context),
                            ),
                          ),
                        ),
                        Text(
                          DateFormat('MMM dd').format(item.date),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppPallete.getTextMuted(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(left: 30),
                      child: Text(
                        item.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppPallete.getTextSecondary(context).withValues(alpha: 0.8),
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.only(left: 30),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: (item.type == 'Goal' ? AppPallete.getPrimaryColor(context) : AppPallete.secondaryColor).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.verified_rounded,
                                  size: 10,
                                  color: item.type == 'Goal' ? AppPallete.getPrimaryColor(context) : AppPallete.secondaryColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  item.type.toUpperCase(),
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: item.type == 'Goal' ? AppPallete.getPrimaryColor(context) : AppPallete.secondaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'COMPLETED',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppPallete.getTextMuted(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
