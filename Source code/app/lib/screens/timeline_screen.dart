import 'dart:math' as math;

import 'package:app/core/router.dart';
import 'package:app/core/theme.dart';
import 'package:app/models/batch.dart';
import 'package:app/providers/providers.dart';
import 'package:app/widgets/blockchain_badge.dart';
import 'package:app/widgets/liquid_glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';

class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key, this.initialBatchId});

  final String? initialBatchId;

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen> {
  final TextEditingController _manualBatchIdController =
      TextEditingController();
  String? _activeBatchId;

  @override
  void initState() {
    super.initState();
    _activeBatchId = widget.initialBatchId;
    if (_activeBatchId != null) {
      _manualBatchIdController.text = _activeBatchId!;
    }
  }

  @override
  void dispose() {
    _manualBatchIdController.dispose();
    super.dispose();
  }

  void _loadManualBatchId() {
    final value = _manualBatchIdController.text.trim();
    if (value.isEmpty) return;

    setState(() => _activeBatchId = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dòng thời gian truy xuất'),
        actions: [
          IconButton(
            onPressed: () {
              if (_activeBatchId == null || _activeBatchId!.isEmpty) return;
              ref.invalidate(batchTimelineProvider(_activeBatchId!));
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: GlassPageBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
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
                          'Thông tin truy xuất lô nông sản',
                          style: TextStyle(
                            color: Color(0xFFEAF8EE),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Nhập mã lô hoặc quét QR để xem lịch sử cập nhật.',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontSize: 24, color: Colors.white),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Hiển thị đầy đủ thông tin lô, các công đoạn canh tác và minh chứng xác nhận nếu có.',
                          style: TextStyle(
                            color: Color(0xFFEFF8F0),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            GlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tìm lô nông sản',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _manualBatchIdController,
                    decoration: const InputDecoration(
                      labelText: 'Mã lô',
                      hintText: 'Nhập mã lô hoặc mã đọc từ QR',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                    onSubmitted: (_) => _loadManualBatchId(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _loadManualBatchId,
                          icon: const Icon(Icons.timeline_rounded),
                          label: const Text('Xem truy xuất'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              Navigator.pushNamed(context, AppRouter.scanner),
                          icon: const Icon(Icons.qr_code_scanner_rounded),
                          label: const Text('Quét QR'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (_activeBatchId == null || _activeBatchId!.isEmpty)
              const _EmptyTimelineState()
            else
              ref
                  .watch(batchTimelineProvider(_activeBatchId!))
                  .when(
                    loading: () => const Padding(
                      padding: EdgeInsets.only(top: 48),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (error, _) => _TimelineErrorState(
                      message: 'Không tải được thông tin truy xuất.\n$error',
                      onRetry: () => ref.invalidate(
                        batchTimelineProvider(_activeBatchId!),
                      ),
                    ),
                    data: (batch) => _TimelineView(batch: batch),
                  ),
          ],
        ),
      ),
    );
  }
}

class _TimelineView extends StatefulWidget {
  const _TimelineView({required this.batch});

  final Batch batch;

  @override
  State<_TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends State<_TimelineView> {
  String? _selectedEventId;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedTypeFilter = 'ALL';
  String _selectedStatusFilter = 'ALL';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allEvents = [...widget.batch.events]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final confirmedCount = allEvents
        .where((event) => event.onChainStatus == 'confirmed')
        .length;

    final availableTypes =
        allEvents.map((event) => event.actionType).toSet().toList()..sort();

    final events = allEvents.where((event) {
      final matchesType =
          _selectedTypeFilter == 'ALL' ||
          event.actionType == _selectedTypeFilter;
      final matchesStatus =
          _selectedStatusFilter == 'ALL' ||
          event.onChainStatus == _selectedStatusFilter;

      if (!matchesType || !matchesStatus) return false;
      if (_searchQuery.trim().isEmpty) return true;

      final q = _searchQuery.trim().toLowerCase();
      final detailsText = event.details.entries
          .map((entry) => '${entry.key} ${entry.value}')
          .join(' ')
          .toLowerCase();

      final textBlob = [
        _labelForAction(event.actionType),
        event.note,
        detailsText,
        event.actor ?? '',
      ].join(' ').toLowerCase();

      return textBlob.contains(q);
    }).toList();

    BatchEvent? selectedEvent;
    for (final item in events) {
      if (item.id == _selectedEventId) {
        selectedEvent = item;
        break;
      }
    }
    selectedEvent ??= events.isNotEmpty ? events.last : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const GlassIconCapsule(
                    icon: Icons.inventory_2_rounded,
                    size: 56,
                    color: AppColors.pine,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.batch.productName,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text('Mã lô: ${widget.batch.batchId}'),
                        if (widget.batch.origin.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text('Xuất xứ: ${widget.batch.origin}'),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (widget.batch.description.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(widget.batch.description),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _SummaryStat(
                      value: '${events.length}',
                      label: 'Tổng sự kiện',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryStat(
                      value: '$confirmedCount',
                      label: 'Đã xác nhận',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text('Dòng thời gian', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        const Text(
          'Dạng mốc công đoạn: mỗi mốc hiển thị icon + thời gian. Chạm vào mốc để xem đầy đủ thông tin.',
        ),
        const SizedBox(height: 14),
        GlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
                decoration: const InputDecoration(
                  labelText: 'Tìm kiếm nhật ký',
                  hintText:
                      'Theo công đoạn, ghi chú, người thực hiện, chi tiết...',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedTypeFilter,
                      decoration: const InputDecoration(
                        labelText: 'Phân loại công đoạn',
                        prefixIcon: Icon(Icons.category_rounded),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: 'ALL',
                          child: Text('Tất cả công đoạn'),
                        ),
                        ...availableTypes.map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(_labelForAction(type)),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _selectedTypeFilter = value);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedStatusFilter,
                      decoration: const InputDecoration(
                        labelText: 'Trạng thái',
                        prefixIcon: Icon(Icons.verified_rounded),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'ALL',
                          child: Text('Tất cả trạng thái'),
                        ),
                        DropdownMenuItem(
                          value: 'confirmed',
                          child: Text('Đã xác nhận'),
                        ),
                        DropdownMenuItem(
                          value: 'pending',
                          child: Text('Đang chờ'),
                        ),
                        DropdownMenuItem(
                          value: 'failed',
                          child: Text('Thất bại'),
                        ),
                        DropdownMenuItem(
                          value: 'skipped',
                          child: Text('Bỏ qua blockchain'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _selectedStatusFilter = value);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (events.isEmpty)
          const GlassPanel(
            child: Text(
              'Không có nhật ký phù hợp với bộ lọc/từ khóa hiện tại.',
            ),
          )
        else ...[
          _InteractiveProcessTimeline(
            events: events,
            selectedEventId: selectedEvent?.id,
            onSelect: (event) {
              setState(() => _selectedEventId = event.id);
            },
          ),
          const SizedBox(height: 14),
          if (selectedEvent != null)
            _SelectedTimelineEventDetail(
              key: ValueKey(selectedEvent.id),
              event: selectedEvent,
            ),
        ],
      ],
    );
  }
}

class _InteractiveProcessTimeline extends StatelessWidget {
  const _InteractiveProcessTimeline({
    required this.events,
    required this.selectedEventId,
    required this.onSelect,
  });

  final List<BatchEvent> events;
  final String? selectedEventId;
  final ValueChanged<BatchEvent> onSelect;

  @override
  Widget build(BuildContext context) {
    const itemWidth = 124.0;
    final minWidth = MediaQuery.sizeOf(context).width - 78;
    final timelineWidth = math.max(minWidth, events.length * itemWidth);

    return GlassPanel(
      padding: const EdgeInsets.fromLTRB(10, 20, 10, 14),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: timelineWidth,
          height: 214,
          child: Stack(
            children: [
              Positioned(
                left: itemWidth / 2,
                right: itemWidth / 2,
                top: 106,
                child: Container(
                  height: 5,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: LinearGradient(
                      colors: [
                        AppColors.pine.withValues(alpha: 0.35),
                        AppColors.leaf.withValues(alpha: 0.6),
                        AppColors.pine.withValues(alpha: 0.35),
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: events.asMap().entries.map((entry) {
                  final index = entry.key;
                  final event = entry.value;

                  return SizedBox(
                    width: itemWidth,
                    child: _TimelineMilestoneNode(
                      event: event,
                      isSelected: selectedEventId == event.id,
                      showLabelAbove: index.isEven,
                      onTap: () => onSelect(event),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelineMilestoneNode extends StatelessWidget {
  const _TimelineMilestoneNode({
    required this.event,
    required this.isSelected,
    required this.showLabelAbove,
    required this.onTap,
  });

  final BatchEvent event;
  final bool isSelected;
  final bool showLabelAbove;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accentColor = _actionColor(event.actionType);
    final displayTime = DateFormat('HH:mm • dd/MM').format(event.createdAt);

    return Stack(
      children: [
        Positioned(
          top: showLabelAbove ? 6 : null,
          bottom: showLabelAbove ? null : 8,
          left: 8,
          right: 8,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: isSelected ? 0.5 : 0.3),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? accentColor.withValues(alpha: 0.9)
                    : Colors.white.withValues(alpha: 0.68),
                width: isSelected ? 1.4 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _labelForAction(event.actionType),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.ink,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  displayTime,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.muted.withValues(alpha: 0.95),
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: showLabelAbove ? 86 : 110,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 2,
              height: 20,
              color: accentColor.withValues(alpha: 0.35),
            ),
          ),
        ),
        Positioned(
          top: 90,
          left: 0,
          right: 0,
          child: Center(
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(999),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                width: isSelected ? 44 : 38,
                height: isSelected ? 44 : 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: isSelected
                        ? accentColor
                        : _statusColor(event.onChainStatus),
                    width: isSelected ? 3 : 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.26),
                      blurRadius: isSelected ? 18 : 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  _iconForAction(event.actionType),
                  size: isSelected ? 22 : 19,
                  color: accentColor,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SelectedTimelineEventDetail extends StatelessWidget {
  const _SelectedTimelineEventDetail({super.key, required this.event});

  final BatchEvent event;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: GlassPanel(
        key: ValueKey(event.id),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _actionColor(
                      event.actionType,
                    ).withValues(alpha: 0.16),
                    border: Border.all(
                      color: _actionColor(
                        event.actionType,
                      ).withValues(alpha: 0.45),
                    ),
                  ),
                  child: Icon(
                    _iconForAction(event.actionType),
                    color: _actionColor(event.actionType),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _labelForAction(event.actionType),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat(
                          'dd/MM/yyyy - HH:mm',
                        ).format(event.createdAt),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                BlockchainBadge(
                  status: event.onChainStatus,
                  txHash: event.transactionHash,
                ),
              ],
            ),
            if (event.note.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                event.note,
                style: const TextStyle(color: AppColors.ink, height: 1.5),
              ),
            ],
            if (event.details.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text(
                'Chi tiết công đoạn',
                style: TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              ...event.details.entries
                  .where((entry) => entry.value.toString().trim().isNotEmpty)
                  .map(
                    (entry) => _DataLine(
                      label: _detailLabel(entry.key),
                      value: entry.value.toString(),
                    ),
                  ),
            ],
            if (event.imageUrls.isNotEmpty) ...[
              const SizedBox(height: 14),
              SizedBox(
                height: 90,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: event.imageUrls.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        event.imageUrls[index],
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 90,
                          height: 90,
                          color: Colors.white.withValues(alpha: 0.22),
                          child: const Icon(
                            Icons.broken_image_outlined,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            if (event.videoUrls.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text(
                'Video minh chứng',
                style: TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 94,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: event.videoUrls.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final videoUrl = event.videoUrls[index];

                    return _VideoPreviewChip(
                      videoUrl: videoUrl,
                      onTap: () {
                        showDialog<void>(
                          context: context,
                          builder: (_) =>
                              _VideoPlayerDialog(videoUrl: videoUrl),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 14),
            _DataLine(
              label: 'Mã giao dịch',
              value: event.transactionHash ?? 'Đang chờ xác nhận',
            ),
            if (event.dataHash != null && event.dataHash!.isNotEmpty)
              _DataLine(label: 'Mã băm dữ liệu', value: event.dataHash!),
            if (event.actor != null && event.actor!.isNotEmpty)
              _DataLine(label: 'Người thực hiện', value: event.actor!),
          ],
        ),
      ),
    );
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'confirmed':
      return AppColors.pine;
    case 'failed':
      return AppColors.danger;
    default:
      return const Color(0xFFC9871B);
  }
}

Color _actionColor(String actionType) {
  switch (actionType) {
    case 'SEEDING':
      return const Color(0xFFC9871B);
    case 'FERTILIZING':
      return const Color(0xFF4C8E4A);
    case 'WATERING':
      return const Color(0xFF2D94CB);
    case 'PEST_CONTROL':
      return const Color(0xFF8B5ED8);
    case 'HARVESTING':
      return const Color(0xFFC2673A);
    case 'PACKAGING':
      return const Color(0xFF6A6EE5);
    case 'SHIPPING':
      return const Color(0xFF366DCE);
    default:
      return AppColors.pine;
  }
}

IconData _iconForAction(String actionType) {
  switch (actionType) {
    case 'SEEDING':
      return Icons.grass_rounded;
    case 'FERTILIZING':
      return Icons.science_rounded;
    case 'WATERING':
      return Icons.water_drop_rounded;
    case 'PEST_CONTROL':
      return Icons.bug_report_rounded;
    case 'HARVESTING':
      return Icons.agriculture_rounded;
    case 'PACKAGING':
      return Icons.inventory_2_rounded;
    case 'SHIPPING':
      return Icons.local_shipping_rounded;
    default:
      return Icons.timeline_rounded;
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

String _detailLabel(String key) {
  const labels = {
    'seedType': 'Loại giống',
    'seedAmount': 'Lượng giống',
    'seedUnit': 'Đơn vị giống',
    'fertilizerType': 'Loại phân',
    'dosage': 'Lưu lượng / liều lượng',
    'dosageUnit': 'Đơn vị liều lượng',
    'method': 'Phương pháp',
    'waterVolume': 'Lượng nước',
    'waterUnit': 'Đơn vị nước',
    'wateringMethod': 'Phương pháp tưới',
    'pestName': 'Đối tượng sâu bệnh',
    'treatment': 'Biện pháp xử lý',
    'yield': 'Sản lượng',
    'yieldUnit': 'Đơn vị sản lượng',
    'qualityGrade': 'Phân hạng chất lượng',
    'packageType': 'Quy cách đóng gói',
    'packageCount': 'Số lượng kiện',
    'vehicle': 'Phương tiện vận chuyển',
    'destination': 'Điểm đến',
    'distanceKm': 'Quãng đường (km)',
  };

  return labels[key] ?? key;
}

class _VideoPreviewChip extends StatelessWidget {
  const _VideoPreviewChip({required this.videoUrl, required this.onTap});

  final String videoUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fileName = _videoName(videoUrl);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: GlassPanel(
        radius: 20,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        colors: [
          Colors.white.withValues(alpha: 0.34),
          Colors.white.withValues(alpha: 0.16),
        ],
        child: SizedBox(
          width: 200,
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.pine.withValues(alpha: 0.16),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: AppColors.pine,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  fileName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _videoName(String input) {
    final uri = Uri.tryParse(input);
    if (uri != null && uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.last;
    }

    final parts = input.split('/');
    return parts.isNotEmpty ? parts.last : input;
  }
}

class _VideoPlayerDialog extends StatefulWidget {
  const _VideoPlayerDialog({required this.videoUrl});

  final String videoUrl;

  @override
  State<_VideoPlayerDialog> createState() => _VideoPlayerDialogState();
}

class _VideoPlayerDialogState extends State<_VideoPlayerDialog> {
  VideoPlayerController? _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
    );

    try {
      await controller.initialize();
      await controller.setLooping(true);
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() => _controller = controller);
      await controller.play();
    } catch (_) {
      await controller.dispose();
      if (!mounted) return;
      setState(() {
        _error = 'Không thể phát video này.';
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Video nhật ký',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppColors.danger),
                  ),
                )
              else if (_controller == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 26),
                  child: CircularProgressIndicator(),
                )
              else
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: AspectRatio(
                    aspectRatio: _controller!.value.aspectRatio == 0
                        ? 16 / 9
                        : _controller!.value.aspectRatio,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        VideoPlayer(_controller!),
                        VideoProgressIndicator(
                          _controller!,
                          allowScrubbing: true,
                          colors: VideoProgressColors(
                            playedColor: AppColors.pine,
                            backgroundColor: Colors.black.withValues(
                              alpha: 0.25,
                            ),
                            bufferedColor: AppColors.leaf.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 10,
                          bottom: 16,
                          child: FilledButton.tonalIcon(
                            onPressed: () {
                              if (_controller!.value.isPlaying) {
                                _controller!.pause();
                              } else {
                                _controller!.play();
                              }
                              setState(() {});
                            },
                            icon: Icon(
                              _controller!.value.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                            ),
                            label: Text(
                              _controller!.value.isPlaying
                                  ? 'Tạm dừng'
                                  : 'Phát',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      radius: 22,
      padding: const EdgeInsets.all(16),
      colors: [
        Colors.white.withValues(alpha: 0.34),
        Colors.white.withValues(alpha: 0.14),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
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

class _DataLine extends StatelessWidget {
  const _DataLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
              color: AppColors.ink,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTimelineState extends StatelessWidget {
  const _EmptyTimelineState();

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Column(
        children: [
          const GlassIconCapsule(
            icon: Icons.qr_code_2_rounded,
            size: 66,
            color: AppColors.pine,
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có lô nào được chọn.',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Hãy quét QR hoặc nhập mã lô để xem toàn bộ thông tin truy xuất của lô nông sản.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _TimelineErrorState extends StatelessWidget {
  const _TimelineErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Column(
        children: [
          const GlassIconCapsule(
            icon: Icons.error_outline_rounded,
            size: 66,
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
    );
  }
}
