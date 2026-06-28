import 'dart:ui';

import 'package:app/core/router.dart';
import 'package:app/core/theme.dart';
import 'package:app/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppTabScaffold extends StatelessWidget {
  const AppTabScaffold({
    super.key,
    required this.child,
    required this.selectedTab,
  });

  final Widget child;
  final AppTab selectedTab;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: AppBottomTabBar(selectedTab: selectedTab),
    );
  }
}

enum AppTab { journal, scanner, quality, farmingArea, disease, trash }

class AppBottomTabBar extends ConsumerWidget {
  const AppBottomTabBar({super.key, required this.selectedTab});

  final AppTab selectedTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authData = ref.watch(authStateProvider);
    final role =
        (authData?['user']?['role'] ?? authData?['role'] ?? '').toString();
    final canManageTrash = role == 'admin' || role == 'manager';
    final tabs = [
      _AppTabItemData(
        tab: AppTab.journal,
        icon: Icons.add_circle_outline_rounded,
        label: 'Nhật ký',
        color: const Color(0xFF2F8F4D),
        route: AppRouter.farmer,
      ),
      _AppTabItemData(
        tab: AppTab.scanner,
        icon: Icons.qr_code_scanner_rounded,
        label: 'Quét QR',
        color: const Color(0xFF406CBE),
        route: AppRouter.scanner,
      ),
      _AppTabItemData(
        tab: AppTab.quality,
        icon: Icons.science_outlined,
        label: 'Kiểm nghiệm',
        color: const Color(0xFF7A5BB8),
        route: '${AppRouter.management}?tab=0',
      ),
      _AppTabItemData(
        tab: AppTab.farmingArea,
        icon: Icons.landscape_outlined,
        label: 'Vùng trồng',
        color: const Color(0xFFB2762C),
        route: '${AppRouter.management}?tab=1',
      ),
      _AppTabItemData(
        tab: AppTab.disease,
        icon: Icons.health_and_safety_outlined,
        label: 'Bệnh cây',
        color: const Color(0xFFB83232),
        route: AppRouter.diseaseDetection,
      ),
      if (canManageTrash)
        _AppTabItemData(
          tab: AppTab.trash,
          icon: Icons.delete_outline_rounded,
          label: 'Thùng rác',
          color: const Color(0xFF64748B),
          route: AppRouter.productTrash,
        ),
    ];

    return SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: AppColors.forest.withValues(alpha: 0.14),
              blurRadius: 24,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.78),
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.84)),
                ),
              ),
              child: Row(
                children: [
                  for (final tab in tabs)
                    Expanded(
                      child: _AppBottomTabItem(
                        item: tab,
                        selected: tab.tab == selectedTab,
                        onTap: () => _openTab(context, tab),
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

  void _openTab(BuildContext context, _AppTabItemData item) {
    if (item.tab == selectedTab) return;
    Navigator.pushReplacementNamed(context, item.route);
  }
}

class _AppTabItemData {
  const _AppTabItemData({
    required this.tab,
    required this.icon,
    required this.label,
    required this.color,
    required this.route,
  });

  final AppTab tab;
  final IconData icon;
  final String label;
  final Color color;
  final String route;
}

class _AppBottomTabItem extends StatelessWidget {
  const _AppBottomTabItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _AppTabItemData item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? item.color : AppColors.muted;
    final iconBackground = selected
        ? item.color.withValues(alpha: 0.14)
        : Colors.transparent;
    final labelWeight = selected ? FontWeight.w900 : FontWeight.w700;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: Tooltip(
        message: item.label,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: SizedBox(
              height: 64,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    width: 36,
                    height: 30,
                    decoration: BoxDecoration(
                      color: iconBackground,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(item.icon, color: foreground, size: 21),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        item.label,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: foreground,
                          fontSize: 10.5,
                          fontWeight: labelWeight,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    width: selected ? 28 : 4,
                    height: 3,
                    decoration: BoxDecoration(
                      color: selected ? item.color : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
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
}
