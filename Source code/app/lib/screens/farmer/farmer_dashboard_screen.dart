import 'package:app/core/router.dart';
import 'package:app/core/theme.dart';
import 'package:app/models/batch.dart';
import 'package:app/providers/providers.dart';
import 'package:app/widgets/liquid_glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FarmerDashboardScreen extends ConsumerWidget {
  const FarmerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              final confirmedCount = batches
                  .expand((batch) => batch.events)
                  .where((event) => event.onChainStatus == 'confirmed')
                  .length;

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
                      padding: const EdgeInsets.all(22),
                      colors: [
                        Colors.white.withValues(alpha: 0.56),
                        const Color(0xB8D8E6FF),
                      ],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Quản lý lô nông sản',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Theo dõi danh sách lô, xem lịch sử truy xuất và cập nhật từng công đoạn sản xuất.',
                            style: Theme.of(
                              context,
                            ).textTheme.headlineSmall?.copyWith(fontSize: 24),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _MetricTile(
                                  value: '${batches.length}',
                                  label: 'Lô đang theo dõi',
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _MetricTile(
                                  value: '$confirmedCount',
                                  label: 'Sự kiện đã xác nhận',
                                ),
                              ),
                            ],
                          ),
                        ],
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
                    if (batches.isEmpty)
                      const GlassPanel(
                        child: Text(
                          'Chưa có lô nào để hiển thị. Hãy tạo trước vài lô mẫu để thuận tiện thao tác khi demo.',
                        ),
                      )
                    else
                      ...batches.map(
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
  const _MetricTile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(16),
      radius: 22,
      colors: [
        Colors.white.withValues(alpha: 0.46),
        Colors.white.withValues(alpha: 0.14),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(label),
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
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
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
            GlassIconCapsule(icon: icon, size: 46, color: AppColors.pine),
            const SizedBox(height: 18),
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
    final latestEvent = sortedEvents.isEmpty ? null : sortedEvents.last;
    final timelineRoute = '${AppRouter.trace}?productId=${batch.batchId}';
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
            error: (_, _) => const SizedBox.shrink(),
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
