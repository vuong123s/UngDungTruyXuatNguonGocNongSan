import 'package:app/core/theme.dart';
import 'package:app/models/batch.dart';
import 'package:app/models/disease_detection.dart';
import 'package:app/providers/providers.dart';
import 'package:app/widgets/liquid_glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class DiseaseDetectionScreen extends ConsumerStatefulWidget {
  const DiseaseDetectionScreen({super.key});

  @override
  ConsumerState<DiseaseDetectionScreen> createState() =>
      _DiseaseDetectionScreenState();
}

class _DiseaseDetectionScreenState
    extends ConsumerState<DiseaseDetectionScreen> {
  static const _symptomOptions = [
    'Vàng lá',
    'Đốm nâu',
    'Cháy lá',
    'Héo rũ',
    'Thối rễ',
    'Phấn trắng',
    'Lỗ thủng trên lá',
    'Rệp hoặc côn trùng',
    'Xoăn lá',
    'Chậm lớn',
  ];

  final _notesController = TextEditingController();
  final _picker = ImagePicker();
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String _productId = '';
  final List<String> _selectedSymptoms = [];
  List<XFile> _images = [];
  List<Batch> _batches = [];
  List<DiseaseDetection> _detections = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });
      final results = await Future.wait([
        ref.read(batchServiceProvider).getBatches(),
        ref.read(diseaseDetectionServiceProvider).getDetections(),
      ]);
      final batches = results[0] as List<Batch>;
      final detections = results[1] as List<DiseaseDetection>;
      if (!mounted) return;
      setState(() {
        _batches = batches;
        _detections = detections;
        _productId = _productId.isNotEmpty
            ? _productId
            : batches.isNotEmpty
            ? batches.first.batchId
            : '';
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(imageQuality: 82);
    if (picked.isEmpty) return;
    setState(() => _images = picked.take(5).toList());
  }

  Future<void> _submit() async {
    if (_productId.isEmpty) {
      setState(() => _error = 'Vui lòng chọn lô cần nhận diện.');
      return;
    }
    if (_selectedSymptoms.isEmpty &&
        _notesController.text.trim().isEmpty &&
        _images.isEmpty) {
      setState(
        () => _error = 'Vui lòng chọn triệu chứng, nhập ghi chú hoặc thêm ảnh.',
      );
      return;
    }

    try {
      setState(() {
        _saving = true;
        _error = null;
      });
      final detection = await ref
          .read(diseaseDetectionServiceProvider)
          .createDetection(
            productId: _productId,
            symptoms: _selectedSymptoms,
            notes: _notesController.text,
            images: _images,
          );
      if (!mounted) return;
      setState(() {
        _detections = [detection, ..._detections];
        _selectedSymptoms.clear();
        _notesController.clear();
        _images = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu kết quả nhận diện bệnh.')),
      );
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa kết quả nhận diện?'),
        content: const Text('Thao tác này sẽ xóa bản ghi khỏi lịch sử.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(diseaseDetectionServiceProvider).deleteDetection(id);
      if (mounted) {
        setState(
          () => _detections = _detections
              .where((detection) => detection.id != id)
              .toList(),
        );
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  void _toggleSymptom(String symptom) {
    setState(() {
      if (_selectedSymptoms.contains(symptom)) {
        _selectedSymptoms.remove(symptom);
      } else {
        _selectedSymptoms.add(symptom);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhận diện bệnh cây'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: GlassPageBackground(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                  children: [
                    _HeaderCard(total: _detections.length),
                    const SizedBox(height: 14),
                    if (_error != null) ...[
                      _ErrorPanel(message: _error!, onClose: () => setState(() => _error = null)),
                      const SizedBox(height: 14),
                    ],
                    _AnalyzerCard(
                      batches: _batches,
                      productId: _productId,
                      selectedSymptoms: _selectedSymptoms,
                      symptomOptions: _symptomOptions,
                      imageCount: _images.length,
                      notesController: _notesController,
                      saving: _saving,
                      onProductChanged: (value) =>
                          setState(() => _productId = value),
                      onToggleSymptom: _toggleSymptom,
                      onPickImages: _pickImages,
                      onClearImages: () => setState(() => _images = []),
                      onSubmit: _submit,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Lịch sử nhận diện',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    if (_detections.isEmpty)
                      const GlassPanel(
                        child: Text(
                          'Chưa có kết quả nhận diện. Hãy chọn lô và ghi nhận triệu chứng đầu tiên.',
                        ),
                      )
                    else
                      ..._detections.map(
                        (detection) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _DetectionCard(
                            detection: detection,
                            onDelete: () => _delete(detection.id),
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

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.total});
  final int total;

  @override
  Widget build(BuildContext context) => GlassPanel(
    colors: [
      const Color(0xFFEAF8EF).withValues(alpha: 0.78),
      Colors.white.withValues(alpha: 0.54),
    ],
    child: Row(
      children: [
        const GlassIconCapsule(
          icon: Icons.health_and_safety_outlined,
          size: 58,
          color: AppColors.pine,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sàng lọc sâu bệnh',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                '$total kết quả đã lưu. Kết quả chỉ hỗ trợ tham khảo, cần xác nhận bởi cán bộ kỹ thuật khi rủi ro cao.',
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _AnalyzerCard extends StatelessWidget {
  const _AnalyzerCard({
    required this.batches,
    required this.productId,
    required this.selectedSymptoms,
    required this.symptomOptions,
    required this.imageCount,
    required this.notesController,
    required this.saving,
    required this.onProductChanged,
    required this.onToggleSymptom,
    required this.onPickImages,
    required this.onClearImages,
    required this.onSubmit,
  });

  final List<Batch> batches;
  final String productId;
  final List<String> selectedSymptoms;
  final List<String> symptomOptions;
  final int imageCount;
  final TextEditingController notesController;
  final bool saving;
  final ValueChanged<String> onProductChanged;
  final ValueChanged<String> onToggleSymptom;
  final VoidCallback onPickImages;
  final VoidCallback onClearImages;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) => GlassPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Phân tích mới', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          initialValue: productId.isEmpty ? null : productId,
          decoration: const InputDecoration(labelText: 'Lô nông sản'),
          items: batches
              .map(
                (batch) => DropdownMenuItem(
                  value: batch.batchId,
                  child: Text(batch.productName),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) onProductChanged(value);
          },
        ),
        const SizedBox(height: 14),
        const Text(
          'Triệu chứng quan sát',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: symptomOptions
              .map(
                (symptom) => FilterChip(
                  label: Text(symptom),
                  selected: selectedSymptoms.contains(symptom),
                  onSelected: (_) => onToggleSymptom(symptom),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: notesController,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Ghi chú thực địa',
            hintText: 'Ví dụ: lá có đốm nâu lan nhanh sau mưa...',
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPickImages,
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(
                  imageCount == 0 ? 'Chọn ảnh cây' : '$imageCount ảnh đã chọn',
                ),
              ),
            ),
            if (imageCount > 0) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: onClearImages,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: saving ? null : onSubmit,
            icon: const Icon(Icons.search_rounded),
            label: Text(saving ? 'Đang nhận diện...' : 'Nhận diện bệnh'),
          ),
        ),
      ],
    ),
  );
}

class _DetectionCard extends StatelessWidget {
  const _DetectionCard({required this.detection, required this.onDelete});
  final DiseaseDetection detection;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final top = detection.topDisease;
    final color = _riskColor(detection.overallRisk);
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GlassIconCapsule(
                icon: Icons.eco_outlined,
                color: color,
                size: 50,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      top.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text('${detection.productName} • ${_date(detection.createdAt)}'),
                  ],
                ),
              ),
              Chip(
                label: Text(_riskLabel(detection.overallRisk)),
                backgroundColor: color.withValues(alpha: 0.12),
                labelStyle: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(top.description),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                icon: Icons.percent_rounded,
                label: '${(top.confidence * 100).round()}% tin cậy',
              ),
              _InfoChip(
                icon: Icons.photo_outlined,
                label: '${detection.imageUrls.length} ảnh',
              ),
              _InfoChip(
                icon: Icons.psychology_alt_outlined,
                label: detection.modelVersion,
              ),
            ],
          ),
          if (top.recommendations.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...top.recommendations.take(3).map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 16,
                      color: AppColors.pine,
                    ),
                    const SizedBox(width: 7),
                    Expanded(child: Text(item)),
                  ],
                ),
              ),
            ),
          ],
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Xóa'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.32),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: Colors.white.withValues(alpha: 0.42)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.muted),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onClose});
  final String message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => GlassPanel(
    colors: [
      const Color(0xFFFFF1F2).withValues(alpha: 0.82),
      Colors.white.withValues(alpha: 0.46),
    ],
    child: Row(
      children: [
        const Icon(Icons.error_outline_rounded, color: AppColors.danger),
        const SizedBox(width: 10),
        Expanded(child: Text(message)),
        IconButton(onPressed: onClose, icon: const Icon(Icons.close_rounded)),
      ],
    ),
  );
}

Color _riskColor(String risk) => switch (risk) {
  'high' => AppColors.danger,
  'medium' => const Color(0xFFB7791F),
  _ => AppColors.pine,
};

String _riskLabel(String risk) => switch (risk) {
  'high' => 'NGUY CƠ CAO',
  'medium' => 'THEO DÕI',
  _ => 'RỦI RO THẤP',
};

String _date(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
