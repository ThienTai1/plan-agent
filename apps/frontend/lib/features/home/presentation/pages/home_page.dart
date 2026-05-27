import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/calendar/presentation/pages/daily_timeline_page.dart';
import 'package:frontend/features/home/presentation/providers/home_navigation_provider.dart';
import 'package:frontend/features/home/presentation/widgets/home_bottom_nav_bar.dart';
import 'package:frontend/features/home/presentation/widgets/create_options_sheet.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:frontend/features/goals/presentation/pages/goals_list_page.dart';
import 'package:frontend/features/tasks/presentation/pages/tasks_list_page.dart';
import 'package:frontend/features/profile/presentation/pages/profile_page.dart';
import 'package:frontend/core/common/providers/app_user_notifier.dart';
import 'package:frontend/core/common/widgets/connectivity_banner.dart';

class HomeScreen extends ConsumerStatefulWidget {
  static const String routeName = '/';

  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // 0: Today, 1: Goals, 2: Tasks, 3: Profile
  final List<Widget> _views = [
    const DailyTimelinePage(),
    const GoalsListPage(),
    const TasksListPage(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(homeNavigationProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 1100;
    // Ensure index is within display bounds
    final displayIndex = selectedIndex < _views.length ? selectedIndex : 0;

    if (!isDesktop) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: false,
        body: Container(
          decoration: AppPallete.getBackgroundDecoration(context),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                const ConnectivityBanner(),
                Expanded(
                  child: PopScope(
                    canPop: false,
                    onPopInvokedWithResult: (didPop, result) {
                      if (didPop) return;
                      // Return to home tab if not already there
                      if (selectedIndex != 0) {
                        ref.read(homeNavigationProvider.notifier).setIndex(0);
                      }
                    },
                    child: IndexedStack(index: displayIndex, children: _views),
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: const HomeBottomNavBar(),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Container(
        decoration: AppPallete.getBackgroundDecoration(context),
        child: Row(
          children: [
            _DesktopSidebar(
              selectedIndex: displayIndex,
              onSelect: (index) =>
                  ref.read(homeNavigationProvider.notifier).setIndex(index),
              onCreate: () => _showCreateOptions(context),
            ),
            Expanded(
              child: Column(
                children: [
                  const ConnectivityBanner(),
                  Expanded(
                    child: IndexedStack(index: displayIndex, children: _views),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onCreate;

  const _DesktopSidebar({
    required this.selectedIndex,
    required this.onSelect,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      decoration: BoxDecoration(
        color: AppPallete.getSurfaceContainerLow(context),
        border: Border(
          right: BorderSide(
            color: AppPallete.getBorderColor(context).withValues(alpha: 0.05),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            _NavIcon(
              icon: LucideIcons.calendar,
              isSelected: selectedIndex == 0,
              onTap: () => onSelect(0),
            ),
            const SizedBox(height: 8),
            _NavIcon(
              icon: LucideIcons.folder,
              isSelected: selectedIndex == 1,
              onTap: () => onSelect(1),
            ),
            const SizedBox(height: 8),
            _NavIcon(
              icon: LucideIcons.clipboard_list,
              isSelected: selectedIndex == 2,
              onTap: () => onSelect(2),
            ),
            const SizedBox(height: 8),
            _ProfileNavIcon(
              isSelected: selectedIndex == 3,
              onTap: () => onSelect(3),
            ),
            const Spacer(),
            GestureDetector(
              onTap: onCreate,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppPallete.getPrimaryColor(context),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.add,
                  color: AppPallete.isDarkMode(context)
                      ? AppPallete.darkBackgroundColor
                      : Colors.white,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavIcon({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isSelected
              ? (AppPallete.isDarkMode(context)
                    ? AppPallete.darkSurfaceColor
                    : Colors.white)
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isSelected
              ? AppPallete.getTextPrimary(context)
              : AppPallete.getTextSecondary(context),
          size: 22,
        ),
      ),
    );
  }
}

class _ProfileNavIcon extends ConsumerWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const _ProfileNavIcon({required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appUserNotifierProvider);
    final initials = user?.fullName?.isNotEmpty == true
        ? user!.fullName![0].toUpperCase()
        : '?';
    final avatarUrl = user?.avatarUrl;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isSelected
              ? (AppPallete.isDarkMode(context)
                    ? AppPallete.darkSurfaceColor
                    : Colors.white)
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: CircleAvatar(
            radius: 11,
            backgroundColor: isSelected
                ? AppPallete.getPrimaryColor(context)
                : AppPallete.getBorderColor(context).withValues(alpha: 0.2),
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null
                ? Text(
                    initials,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : AppPallete.getTextPrimary(context),
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

void _showCreateOptions(BuildContext context) {
  FocusManager.instance.primaryFocus?.unfocus();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const CreateOptionsSheet(),
  );
}
