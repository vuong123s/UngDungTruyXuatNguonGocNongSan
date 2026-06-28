import 'package:app/core/api_client.dart';
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
    final role =
        (authData?['user']?['role'] ?? authData?['role'] ?? '').toString();

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
              final canDeleteProduct = role == 'admin';

              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(batchListProvider),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 118),
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
                            final container = ProviderScope.containerOf(
                              context,
                            );
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              AppRouter.home,
                              (_) => false,
                            );
                            Future.microtask(() {
                              container.read(authStateProvider.notifier).state =
                                  null;
                              ApiClient.instance.setToken(null);
                            });
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
                        IconButton.filledTonal(
                          tooltip: 'Thêm lô mới',
                          onPressed: () => Navigator.pushNamed(
                            context,
                            AppRouter.createProduct,
                          ),
                          icon: const Icon(Icons.add_rounded),
                        ),
                        const SizedBox(width: 6),
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
                          child: _BatchCard(
                            batch: batch,
                            allBatches: batches,
                            canDelete: canDeleteProduct,
                          ),
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

class _BatchCard extends ConsumerWidget {
  const _BatchCard({
    required this.batch,
    required this.allBatches,
    required this.canDelete,
  });

  final Batch batch;
  final List<Batch> allBatches;
  final bool canDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
    final camerasRoute = '${AppRouter.cameras}?batchId=${batch.batchId}';
    final cameraCount = batch.liveCameras.length;

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
            const SizedBox(height: 14),
            _LatestEventStrip(
              title: _labelForAction(latestEvent.actionType),
              note: latestEvent.note,
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
              _InlineInfoChip(
                icon: Icons.videocam_rounded,
                label: '$cameraCount camera',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _BatchActionNavBar(
            items: [
              _BatchNavItemData(
                icon: Icons.timeline_rounded,
                label: 'Timeline',
                color: AppColors.ink,
                onTap: () => Navigator.pushNamed(context, timelineRoute),
              ),
              _BatchNavItemData(
                icon: Icons.add_circle_outline_rounded,
                label: 'Nhật ký',
                color: AppColors.forest,
                isPrimary: true,
                onTap: () => Navigator.pushNamed(context, addEventRoute),
              ),
              _BatchNavItemData(
                icon: Icons.edit_outlined,
                label: 'Sửa',
                color: AppColors.ink,
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRouter.editProduct,
                  arguments: batch,
                ),
              ),
              _BatchNavItemData(
                icon: Icons.videocam_rounded,
                label: 'Camera',
                color: cameraCount == 0 ? AppColors.danger : AppColors.pine,
                badge: '$cameraCount',
                onTap: () => Navigator.pushNamed(context, camerasRoute),
              ),
              _BatchNavItemData(
                icon: Icons.account_tree_outlined,
                label: 'Nghiệp vụ',
                color: AppColors.forest,
                onTap: () => _showBatchWorkflowSheet(context, ref),
              ),
              if (canDelete)
                _BatchNavItemData(
                  icon: Icons.delete_outline_rounded,
                  label: 'Xóa',
                  color: AppColors.danger,
                  onTap: () => _confirmDelete(context, ref),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _runWorkflow(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() action,
    String successMessage,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await action();
      ref.invalidate(batchListProvider);
      if (navigator.canPop()) navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(error.toString()), backgroundColor: AppColors.danger),
      );
    }
  }

  void _showBatchWorkflowSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WorkflowSheet(
        batch: batch,
        allBatches: allBatches,
        onSplit: (quantity, childName, childQuantity, note) => _runWorkflow(
          context,
          ref,
          () => ref.read(batchServiceProvider).splitProduct(
                productId: batch.id,
                quantity: quantity,
                childName: childName,
                childQuantity: childQuantity,
                note: note,
              ),
          'Đã tách lô thành công.',
        ),
        onMerge: (targetBatch, targetName, targetQuantity, note) => _runWorkflow(
          context,
          ref,
          () => ref.read(batchServiceProvider).mergeProducts(
                sourceA: batch.id,
                sourceB: targetBatch.id,
                targetName: targetName,
                targetQuantity: targetQuantity,
                note: note,
              ),
          'Đã gộp lô thành công.',
        ),
        onRecall: (quantity, reason, note, location, status) => _runWorkflow(
          context,
          ref,
          () => ref.read(batchServiceProvider).recallProduct(
                productId: batch.id,
                quantity: quantity,
                reason: reason,
                note: note,
                location: location,
                status: status,
              ),
          'Đã ghi nhận thu hồi lô.',
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa lô?'),
        content: Text(
          'Lô "${batch.productName}" sẽ được chuyển vào thùng rác. Bạn có thể khôi phục lại nếu cần.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xóa lô'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(batchServiceProvider).deleteProduct(batch.id);
      ref.invalidate(batchListProvider);
      messenger.showSnackBar(
        const SnackBar(content: Text('Đã chuyển lô vào thùng rác.')),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: AppColors.danger,
        ),
      );
    }
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

class _BatchNavItemData {
  const _BatchNavItemData({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.badge,
    this.isPrimary = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final String? badge;
  final bool isPrimary;
}

class _BatchActionNavBar extends StatelessWidget {
  const _BatchActionNavBar({required this.items});

  final List<_BatchNavItemData> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withValues(alpha: 0.52)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const gap = 6.0;
          final available = constraints.maxWidth - gap * (items.length - 1);
          final fittedWidth = available / items.length;
          final itemWidth = fittedWidth.clamp(58.0, 82.0);
          final needsScroll = fittedWidth < 58;
          final row = Row(
            mainAxisSize: needsScroll ? MainAxisSize.min : MainAxisSize.max,
            children: [
              for (var index = 0; index < items.length; index++) ...[
                _BatchActionNavItem(item: items[index], width: itemWidth),
                if (index != items.length - 1) const SizedBox(width: gap),
              ],
            ],
          );

          if (!needsScroll) return row;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: row,
          );
        },
      ),
    );
  }
}

class _BatchActionNavItem extends StatelessWidget {
  const _BatchActionNavItem({required this.item, required this.width});

  final _BatchNavItemData item;
  final double width;

  @override
  Widget build(BuildContext context) {
    final background = item.isPrimary
        ? item.color
        : item.color.withValues(alpha: item.color == AppColors.danger ? 0.08 : 0.1);
    final foreground = item.isPrimary ? Colors.white : item.color;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: item.onTap,
        child: SizedBox(
          width: width,
          height: 64,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(item.icon, color: foreground, size: 21),
                  if (item.badge != null)
                    Positioned(
                      right: -13,
                      top: -9,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: foreground.withValues(alpha: item.isPrimary ? 0.22 : 0.12),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: foreground.withValues(alpha: 0.22),
                          ),
                        ),
                        child: Text(
                          item.badge!,
                          style: TextStyle(
                            color: foreground,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: foreground,
                  fontSize: width < 64 ? 9.5 : 10.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LatestEventStrip extends StatelessWidget {
  const _LatestEventStrip({required this.title, required this.note});

  final String title;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.pine.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.update_rounded,
              color: AppColors.pine,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cập nhật gần nhất',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                if (note.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    note,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
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

class _WorkflowSheet extends StatefulWidget {
  const _WorkflowSheet({
    required this.batch,
    required this.allBatches,
    required this.onSplit,
    required this.onMerge,
    required this.onRecall,
  });

  final Batch batch;
  final List<Batch> allBatches;
  final Future<void> Function(
    double quantity,
    String childName,
    double childQuantity,
    String note,
  ) onSplit;
  final Future<void> Function(
    Batch targetBatch,
    String targetName,
    double? targetQuantity,
    String note,
  ) onMerge;
  final Future<void> Function(
    double? quantity,
    String reason,
    String note,
    String location,
    String status,
  ) onRecall;

  @override
  State<_WorkflowSheet> createState() => _WorkflowSheetState();
}

class _WorkflowSheetState extends State<_WorkflowSheet> {
  String _mode = 'split';
  bool _submitting = false;
  Batch? _mergeTarget;
  String _recallStatus = 'IN_PROGRESS';
  final _splitQuantity = TextEditingController();
  final _childName = TextEditingController();
  final _childQuantity = TextEditingController();
  final _splitNote = TextEditingController();
  final _mergeName = TextEditingController();
  final _mergeQuantity = TextEditingController();
  final _mergeNote = TextEditingController();
  final _recallQuantity = TextEditingController();
  final _recallReason = TextEditingController();
  final _recallNote = TextEditingController();
  final _recallLocation = TextEditingController();

  @override
  void initState() {
    super.initState();
    final candidates = widget.allBatches.where((item) => item.id != widget.batch.id);
    _mergeTarget = candidates.isEmpty ? null : candidates.first;
  }

  @override
  void dispose() {
    _splitQuantity.dispose();
    _childName.dispose();
    _childQuantity.dispose();
    _splitNote.dispose();
    _mergeName.dispose();
    _mergeQuantity.dispose();
    _mergeNote.dispose();
    _recallQuantity.dispose();
    _recallReason.dispose();
    _recallNote.dispose();
    _recallLocation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      if (_mode == 'split') {
        final quantity = _parseRequired(_splitQuantity.text, 'Số lượng tách');
        final childQuantity = _childQuantity.text.trim().isEmpty
            ? quantity
            : _parseRequired(_childQuantity.text, 'Số lượng lô con');
        await widget.onSplit(
          quantity,
          _childName.text,
          childQuantity,
          _splitNote.text,
        );
      } else if (_mode == 'merge') {
        final target = _mergeTarget;
        if (target == null) throw Exception('Vui lòng chọn lô để gộp');
        await widget.onMerge(
          target,
          _mergeName.text,
          _parseOptional(_mergeQuantity.text),
          _mergeNote.text,
        );
      } else {
        if (_recallReason.text.trim().isEmpty) {
          throw Exception('Vui lòng nhập lý do thu hồi');
        }
        await widget.onRecall(
          _parseOptional(_recallQuantity.text),
          _recallReason.text,
          _recallNote.text,
          _recallLocation.text,
          _recallStatus,
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString()),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  double _parseRequired(String raw, String label) {
    final value = double.tryParse(raw.trim().replaceAll(',', '.'));
    if (value == null || value <= 0) {
      throw Exception('$label phải lớn hơn 0');
    }
    return value;
  }

  double? _parseOptional(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final value = double.tryParse(trimmed.replaceAll(',', '.'));
    if (value == null || value <= 0) {
      throw Exception('Số lượng phải lớn hơn 0');
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: GlassPanel(
        radius: 30,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        colors: [
          Colors.white.withValues(alpha: 0.94),
          const Color(0xFFEAF6E7),
        ],
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.muted.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.batch.productName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Tồn: ${_formatQuantity(widget.batch.currentQuantity)} ${widget.batch.unit}',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'split',
                      icon: Icon(Icons.call_split_rounded),
                      label: Text('Tách'),
                    ),
                    ButtonSegment(
                      value: 'merge',
                      icon: Icon(Icons.merge_type_rounded),
                      label: Text('Gộp'),
                    ),
                    ButtonSegment(
                      value: 'recall',
                      icon: Icon(Icons.warning_amber_rounded),
                      label: Text('Thu hồi'),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (value) => setState(() => _mode = value.first),
                ),
                const SizedBox(height: 16),
                if (_mode == 'split') _buildSplitForm(),
                if (_mode == 'merge') _buildMergeForm(),
                if (_mode == 'recall') _buildRecallForm(),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(_submitting ? 'Đang xử lý...' : 'Xác nhận'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSplitForm() {
    return Column(
      children: [
        _NumberField(
          controller: _splitQuantity,
          label: 'Số lượng tách',
          hint: 'Ví dụ: 25',
          onChanged: (value) {
            if (_childQuantity.text.trim().isEmpty) {
              _childQuantity.text = value;
            }
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _childName,
          decoration: const InputDecoration(
            labelText: 'Tên lô con',
            hintText: 'Để trống để hệ thống tự đặt tên',
            prefixIcon: Icon(Icons.inventory_2_outlined),
          ),
        ),
        const SizedBox(height: 12),
        _NumberField(
          controller: _childQuantity,
          label: 'Số lượng lô con',
          hint: 'Bằng số lượng tách nếu chỉ tạo một lô con',
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _splitNote,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Ghi chú',
            prefixIcon: Icon(Icons.notes_rounded),
          ),
        ),
      ],
    );
  }

  Widget _buildMergeForm() {
    final candidates = widget.allBatches
        .where((item) => item.id != widget.batch.id)
        .toList();
    return Column(
      children: [
        DropdownButtonFormField<Batch>(
          initialValue: _mergeTarget,
          items: candidates
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text(
                    '${item.productName} - ${_formatQuantity(item.currentQuantity)} ${item.unit}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => _mergeTarget = value),
          decoration: const InputDecoration(
            labelText: 'Lô gộp cùng',
            prefixIcon: Icon(Icons.inventory_rounded),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _mergeName,
          decoration: const InputDecoration(
            labelText: 'Tên lô sau gộp',
            hintText: 'Để trống để hệ thống tự đặt tên',
            prefixIcon: Icon(Icons.label_outline_rounded),
          ),
        ),
        const SizedBox(height: 12),
        _NumberField(
          controller: _mergeQuantity,
          label: 'Số lượng sau gộp',
          hint: 'Để trống để dùng toàn bộ tồn của 2 lô',
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _mergeNote,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Ghi chú',
            prefixIcon: Icon(Icons.notes_rounded),
          ),
        ),
      ],
    );
  }

  Widget _buildRecallForm() {
    return Column(
      children: [
        _NumberField(
          controller: _recallQuantity,
          label: 'Số lượng thu hồi',
          hint: 'Để trống để thu hồi toàn bộ tồn',
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _recallStatus,
          items: const [
            DropdownMenuItem(
              value: 'IN_PROGRESS',
              child: Text('Đang thực hiện'),
            ),
            DropdownMenuItem(value: 'COMPLETED', child: Text('Hoàn tất')),
          ],
          onChanged: (value) => setState(() => _recallStatus = value ?? 'IN_PROGRESS'),
          decoration: const InputDecoration(
            labelText: 'Trạng thái thu hồi',
            prefixIcon: Icon(Icons.flag_outlined),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _recallLocation,
          decoration: const InputDecoration(
            labelText: 'Địa điểm',
            prefixIcon: Icon(Icons.place_outlined),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _recallReason,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Lý do thu hồi',
            prefixIcon: Icon(Icons.report_problem_outlined),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _recallNote,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Ghi chú',
            prefixIcon: Icon(Icons.notes_rounded),
          ),
        ),
      ],
    );
  }

  String _formatQuantity(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    this.hint,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: const Icon(Icons.scale_outlined),
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
