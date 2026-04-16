import 'package:app/core/router.dart';
import 'package:app/core/theme.dart';
import 'package:app/models/batch.dart';
import 'package:app/providers/providers.dart';
import 'package:app/widgets/liquid_glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FarmerDashboardScreen extends ConsumerStatefulWidget {
  const FarmerDashboardScreen({super.key});

  @override
  ConsumerState<FarmerDashboardScreen> createState() =>
      _FarmerDashboardScreenState();
}

class _FarmerDashboardScreenState extends ConsumerState<FarmerDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final batchesAsync = ref.watch(batchListProvider);
    final authData = ref.watch(authStateProvider);

    return Scaffold(
      body: GlassPageBackground(
        child: SafeArea(
          child: batchesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _ErrorState(
              message: 'Không tải được danh sách lô nông sản.\n$error',
              onRetry: () => ref.invalidate(batchListProvider),
            ),
            data: (batches) {
              final normalizedQuery = _searchQuery.trim().toLowerCase();
              final displayedBatches = normalizedQuery.isEmpty
                  ? batches
                  : batches.where((batch) {
                      final haystack = [
                        batch.batchId,
                        batch.productName,
                        batch.productType,
                        batch.origin,
                        batch.status,
                      ].join(' ').toLowerCase();
                      return haystack.contains(normalizedQuery);
                    }).toList();

              final confirmedCount = batches
                  .expand((batch) => batch.events)
                  .where((event) => event.onChainStatus == 'confirmed')
                  .length;
              final mediaCount = batches
                  .expand((batch) => batch.events)
                  .fold<int>(
                    0,
                    (sum, event) =>
                        sum + event.imageUrls.length + event.videoUrls.length,
                  );

              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(batchListProvider),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Xin chào,',
                                style: TextStyle(
                                  color: AppColors.muted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                (authData?['user']?['name'] ??
                                        authData?['name'] ??
                                        'Người vận hành')
                                    .toString(),
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineMedium,
                              ),
                            ],
                          ),
                        ),
                        _NotificationBellButton(),
                        const SizedBox(width: 10),
                        InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () {
                            ref.read(authStateProvider.notifier).state = null;
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              AppRouter.home,
                              (_) => false,
                            );
                          },
                          child: const GlassIconCapsule(
                            icon: Icons.logout_rounded,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    GlassPanel(
                      padding: const EdgeInsets.all(0),
                      colors: [
                        Colors.white.withValues(alpha: 0.66),
                        const Color(0xBDE4F2D8),
                      ],
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF2A7F45), Color(0xFF5AA265)],
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(22),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Quản lý lô nông sản',
                                  style: TextStyle(
                                    color: Color(0xFFEAF8EE),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Theo dõi danh sách lô, xem lịch sử truy xuất và cập nhật từng công đoạn sản xuất.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontSize: 24,
                                        color: Colors.white,
                                      ),
                                ),
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    _MetricTile(
                                      value: '${batches.length}',
                                      label: 'Lô đang theo dõi',
                                      icon: Icons.inventory_2_rounded,
                                    ),
                                    _MetricTile(
                                      value: '$confirmedCount',
                                      label: 'Mốc đã xác nhận',
                                      icon: Icons.verified_rounded,
                                    ),
                                    _MetricTile(
                                      value: '$mediaCount',
                                      label: 'Media minh chứng',
                                      icon: Icons.photo_library_rounded,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.add_circle_outline_rounded,
                            title: 'Thêm nhật ký',
                            subtitle: 'Ghi nhận hoạt động',
                            accentColor: const Color(0xFF2F8F4D),
                            tag: 'Ghi nhận',
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRouter.addEvent,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.qr_code_scanner_rounded,
                            title: 'Quét QR',
                            subtitle: 'Mở thông tin truy xuất',
                            accentColor: const Color(0xFF406CBE),
                            tag: 'Tra cứu nhanh',
                            onTap: () =>
                                Navigator.pushNamed(context, AppRouter.scanner),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Danh sách lô',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => ref.invalidate(batchListProvider),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Làm mới'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    GlassPanel(
                      radius: 22,
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                      colors: [
                        Colors.white.withValues(alpha: 0.44),
                        Colors.white.withValues(alpha: 0.18),
                      ],
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                        },
                        decoration: InputDecoration(
                          labelText: 'Tìm kiếm lô',
                          hintText: 'Theo mã lô, tên sản phẩm, xuất xứ...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _searchQuery.trim().isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Hiển thị ${displayedBatches.length}/${batches.length} lô',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (batches.isEmpty)
                      const GlassPanel(
                        child: Text(
                          'Chưa có lô nào để hiển thị. Hãy tạo trước vài lô mẫu để thuận tiện thao tác khi demo.',
                        ),
                      )
                    else if (displayedBatches.isEmpty)
                      GlassPanel(
                        child: Text(
                          'Không tìm thấy lô phù hợp với từ khóa "${_searchQuery.trim()}".',
                        ),
                      )
                    else
                      ...displayedBatches.map(
                        (batch) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _BatchCard(batch: batch),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 146,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFEAF8EE),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.tag,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final String tag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: onTap,
      child: GlassPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withValues(alpha: 0.14),
                border: Border.all(color: accentColor.withValues(alpha: 0.28)),
              ),
              child: Icon(icon, color: accentColor),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                tag,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(subtitle),
          ],
        ),
      ),
    );
  }
}

class _BatchCard extends StatelessWidget {
  const _BatchCard({required this.batch});

  final Batch batch;

  @override
  Widget build(BuildContext context) {
    final sortedEvents = [...batch.events]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final confirmedCount = sortedEvents
        .where((event) => event.onChainStatus == 'confirmed')
        .length;
    final mediaCount = sortedEvents.fold<int>(
      0,
      (sum, event) => sum + event.imageUrls.length + event.videoUrls.length,
    );
    final latestEvent = sortedEvents.isEmpty ? null : sortedEvents.last;
    final timelineRoute = '${AppRouter.timeline}?batchId=${batch.batchId}';
    final addEventRoute = '${AppRouter.addEvent}?batchId=${batch.batchId}';

    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const GlassIconCapsule(
                icon: Icons.inventory_2_outlined,
                size: 54,
                color: AppColors.pine,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      batch.productName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('Mã lô: ${batch.batchId}'),
                    if (batch.origin.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text('Xuất xứ: ${batch.origin}'),
                    ],
                  ],
                ),
              ),
              _StatusPill(status: batch.status),
            ],
          ),
          if (latestEvent != null) ...[
            const SizedBox(height: 16),
            GlassPanel(
              radius: 22,
              padding: const EdgeInsets.all(14),
              colors: [
                Colors.white.withValues(alpha: 0.32),
                Colors.white.withValues(alpha: 0.14),
              ],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cập nhật gần nhất',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _labelForAction(latestEvent.actionType),
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (latestEvent.note.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      latestEvent.note,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InlineInfoChip(
                icon: Icons.timeline_rounded,
                label: '${sortedEvents.length} mốc',
              ),
              _InlineInfoChip(
                icon: Icons.verified_rounded,
                label: '$confirmedCount đã xác nhận',
              ),
              _InlineInfoChip(
                icon: Icons.perm_media_rounded,
                label: '$mediaCount media',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, timelineRoute),
                  icon: const Icon(Icons.timeline_rounded),
                  label: const Text('Xem dòng thời gian'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => Navigator.pushNamed(context, addEventRoute),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Thêm nhật ký'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _labelForAction(String actionType) {
    switch (actionType) {
      case 'SEEDING':
        return 'Gieo hạt';
      case 'FERTILIZING':
        return 'Bón phân';
      case 'WATERING':
        return 'Tưới nước';
      case 'PEST_CONTROL':
        return 'Chăm sóc / Kiểm soát sâu bệnh';
      case 'HARVESTING':
        return 'Thu hoạch';
      case 'PACKAGING':
        return 'Đóng gói';
      case 'SHIPPING':
        return 'Vận chuyển';
      default:
        return actionType;
    }
  }
}

class _InlineInfoChip extends StatelessWidget {
  const _InlineInfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.26),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.42)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.muted),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'completed' => const Color(0xFF2E956A),
      'draft' => const Color(0xFFA46A1F),
      _ => AppColors.pine,
    };

    final label = switch (status) {
      'completed' => 'HOÀN TẤT',
      'draft' => 'BẢN NHÁP',
      'active' => 'ĐANG THEO DÕI',
      _ => status.toUpperCase(),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 11,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: GlassPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const GlassIconCapsule(
                icon: Icons.cloud_off_rounded,
                size: 62,
                color: AppColors.danger,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(height: 1.5),
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('Thử lại')),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationBellButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCountAsync = ref.watch(unreadNotificationCountProvider);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.pushNamed(context, AppRouter.notifications),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const GlassIconCapsule(
            icon: Icons.notifications_outlined,
            color: AppColors.ink,
          ),
          unreadCountAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (error, stackTrace) => const SizedBox.shrink(),
            data: (count) {
              if (count == 0) return const SizedBox.shrink();
              return Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    count > 99 ? '99+' : count.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
