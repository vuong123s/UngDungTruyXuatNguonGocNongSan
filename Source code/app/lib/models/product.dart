import 'package:app/models/farming_area.dart';

class Product {
  final String id;
  final String name;
  final String? description;
  final String category;
  final String origin;
  final String type; // plant | animal
  final List<String> images;
  final String? onChainBatchId;
  final String? batchTxHash;
  final String status; // draft | active | completed
  final FarmingArea? farmingArea;
  final DateTime? cultivationTime;
  final Map<String, dynamic>? createdBy;
  final DateTime? createdAt;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    required this.origin,
    required this.type,
    required this.images,
    this.onChainBatchId,
    this.batchTxHash,
    required this.status,
    this.farmingArea,
    this.cultivationTime,
    this.createdBy,
    this.createdAt,
  });

  /// `batchId` dùng trên blockchain đang lấy trực tiếp từ `_id`.
  String get batchId => id;

  /// Nhãn hiển thị loại sản phẩm
  String get typeLabel => type == 'animal' ? 'Chăn nuôi' : 'Trồng trọt';
  String get typeIcon => type == 'animal' ? '🐄' : '🌾';

  /// Nhãn hiển thị trạng thái
  String get statusLabel {
    switch (status) {
      case 'active':
        return 'Đang sản xuất';
      case 'completed':
        return 'Hoàn thành';
      default:
        return 'Nháp';
    }
  }

  /// Tên người tạo
  String get createdByName {
    if (createdBy == null) return 'N/A';
    final first = createdBy!['first_name'] ?? '';
    final last = createdBy!['last_name'] ?? '';
    return '$first $last'.trim();
  }

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['_id'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    category: json['category'] as String? ?? '',
    origin: json['origin'] as String? ?? '',
    type: json['type'] as String? ?? 'plant',
    images: _parseImages(json['images']),
    onChainBatchId: json['onChainBatchId'] as String?,
    batchTxHash: json['batchTxHash'] as String?,
    status: json['status'] as String? ?? 'draft',
    farmingArea: json['farming_area'] is Map<String, dynamic>
        ? FarmingArea.fromJson(json['farming_area'] as Map<String, dynamic>)
        : null,
    cultivationTime: json['cultivation_time'] != null
        ? DateTime.tryParse(json['cultivation_time'] as String)
        : null,
    createdBy: json['created_by'] as Map<String, dynamic>?,
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'] as String)
        : null,
  );

  static List<String> _parseImages(dynamic raw) {
    if (raw == null) return [];
    if (raw is! List) return [];
    return raw
        .map((e) {
          if (e is Map) return (e['path'] as String?) ?? '';
          return e.toString();
        })
        .where((s) => s.isNotEmpty)
        .toList();
  }
}
