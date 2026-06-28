import 'package:app/core/api_client.dart';
import 'package:app/models/live_camera.dart';
import 'package:app/models/batch.dart';
import 'package:app/models/product.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

class _UploadedMedia {
  const _UploadedMedia({
    required this.path,
    required this.filename,
    required this.mediaType,
    this.mimeType,
  });

  final String path;
  final String filename;
  final String mediaType;
  final String? mimeType;

  Map<String, dynamic> toTracePayload() => {
    'path': path,
    'filename': filename,
    if (mimeType != null && mimeType!.isNotEmpty) 'mimeType': mimeType,
  };
}

class _BatchServiceException implements Exception {
  const _BatchServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class BatchService {
  BatchService({Dio? dio}) : _dio = dio ?? ApiClient.instance.dio;

  final Dio _dio;

  Future<List<Batch>> getBatches() async {
    final response = await _dio.get('/products/my/products');
    final payload = response.data;

    final items = payload is List
        ? payload
        : (payload is Map<String, dynamic>
              ? (payload['products'] as List<dynamic>? ?? const [])
              : const <dynamic>[]);

    return items
        .map((item) => _mapProductToBatch(item as Map<String, dynamic>))
        .toList();
  }

  Future<Batch> getTimeline(String batchId) async {
    final response = await _dio.get('/trace/$batchId');
    final payload = response.data as Map<String, dynamic>;

    final product = payload['product'] as Map<String, dynamic>? ?? const {};
    final events = (payload['events'] as List<dynamic>? ?? const []);

    return Batch(
      id: (product['_id'] ?? batchId).toString(),
      batchId: (product['_id'] ?? batchId).toString(),
      productName: (product['name'] ?? '').toString(),
      productType: (product['category'] ?? product['type'] ?? '').toString(),
      origin: (product['origin'] ?? '').toString(),
      description: (product['description'] ?? '').toString(),
      status: (product['status'] ?? 'active').toString(),
      initialQuantity: _numToDouble(product['initial_quantity']),
      currentQuantity: _numToDouble(product['current_quantity']),
      unit: (product['unit'] ?? 'kg').toString(),
      qrCodeUrl: (product['qrcode'] ?? '').toString(),
      liveCameras: _mapLiveCameras(product['live_cameras']),
      events: events
          .map((item) => _mapTraceEvent(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<BatchEvent> retryBlockchainEvent(String eventId) async {
    try {
      final response = await _dio.post(
        '/trace/events/$eventId/retry',
        options: Options(
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 90),
        ),
      );
      final payload = response.data as Map<String, dynamic>;
      final event =
          (payload['event'] as Map<String, dynamic>?) ??
          (payload['traceEvent'] as Map<String, dynamic>?) ??
          const <String, dynamic>{};
      return _mapTraceEvent(event);
    } on DioException catch (error) {
      final responseData = error.response?.data;
      if (responseData is Map<String, dynamic>) {
        final message =
            responseData['msg'] ??
            responseData['message'] ??
            responseData['error'];
        if (message != null && message.toString().trim().isNotEmpty) {
          throw _BatchServiceException(message.toString());
        }
      }

      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout) {
        throw const _BatchServiceException(
          'Không kết nối được tới máy chủ API. Vui lòng kiểm tra lại kết nối.',
        );
      }

      if (error.type == DioExceptionType.receiveTimeout) {
        throw const _BatchServiceException(
          'Blockchain phản hồi quá lâu. Vui lòng làm mới trạng thái trước khi thử lại.',
        );
      }

      throw _BatchServiceException(
        error.message ?? 'Không thể ghi sự kiện lên blockchain.',
      );
    }
  }

  Future<List<Product>> getTrashProducts() async {
    final response = await _dio.get('/products/trash');
    final payload = response.data;
    final items = payload is Map<String, dynamic>
        ? (payload['products'] as List<dynamic>? ?? const [])
        : const <dynamic>[];

    return items
        .whereType<Map<String, dynamic>>()
        .map(Product.fromJson)
        .toList();
  }

  Future<Product> restoreProduct(String productId) async {
    final response = await _dio.post('/products/$productId/restore');
    final payload = response.data as Map<String, dynamic>;
    final product = payload['product'] as Map<String, dynamic>? ?? const {};
    return Product.fromJson(product);
  }

  Future<void> permanentDeleteProduct(String productId) async {
    await _dio.delete('/products/$productId/permanent');
  }

  Future<void> deleteProduct(String productId) async {
    await _dio.delete('/products/$productId');
  }

  Future<void> splitProduct({
    required String productId,
    required double quantity,
    required String childName,
    required double childQuantity,
    String? note,
  }) async {
    await _dio.post(
      '/products/$productId/split',
      data: {
        'quantity': quantity,
        'note': note,
        'children': [
          {
            if (childName.trim().isNotEmpty) 'name': childName.trim(),
            'quantity': childQuantity,
          },
        ],
      },
    );
  }

  Future<void> mergeProducts({
    required String sourceA,
    required String sourceB,
    String? targetName,
    double? targetQuantity,
    String? note,
  }) async {
    final cleanTargetName = (targetName ?? '').trim();
    final data = <String, dynamic>{
      'sources': [
        {'product': sourceA},
        {'product': sourceB},
      ],
      'target': {
        if (cleanTargetName.isNotEmpty) 'name': cleanTargetName,
      },
      'note': note,
    };
    if (targetQuantity != null) data['target_quantity'] = targetQuantity;

    await _dio.post(
      '/products/merge',
      data: data,
    );
  }

  Future<void> recallProduct({
    required String productId,
    double? quantity,
    required String reason,
    String? note,
    String? location,
    String status = 'IN_PROGRESS',
  }) async {
    final data = <String, dynamic>{
      'reason': reason.trim(),
      'note': note,
      'location': location,
      'status': status,
    };
    if (quantity != null) data['quantity'] = quantity;

    await _dio.post(
      '/products/$productId/recall',
      data: data,
    );
  }

  Future<Batch> createProduct({
    required String name,
    required String category,
    required String type,
    required String description,
    required String origin,
    required double initialQuantity,
    required String unit,
  }) async {
    final response = await _dio.post(
      '/products',
      data: {
        'name': name.trim(),
        'category': category.trim(),
        'type': type,
        'description': description.trim(),
        'origin': origin.trim(),
        'initial_quantity': initialQuantity,
        'current_quantity': initialQuantity,
        'unit': unit.trim().isEmpty ? 'kg' : unit.trim(),
      },
    );
    final payload = response.data as Map<String, dynamic>;
    final product = payload['product'] as Map<String, dynamic>? ?? const {};
    return _mapProductToBatch(product);
  }

  Future<Batch> updateProduct({
    required String productId,
    required String name,
    required String category,
    required String description,
    required String origin,
    required String status,
  }) async {
    final response = await _dio.patch(
      '/products/$productId',
      data: {
        'name': name.trim(),
        'category': category.trim(),
        'description': description.trim(),
        'origin': origin.trim(),
        'status': status,
      },
    );
    final payload = response.data as Map<String, dynamic>;
    final product = payload['product'] as Map<String, dynamic>? ?? const {};
    return _mapProductToBatch(product);
  }

  Future<CreateEventResult> addFarmingEvent({
    required String batchId,
    required String actionType,
    required String note,
    required List<XFile> images,
    List<XFile> videos = const [],
    Map<String, dynamic>? details,
  }) async {
    final uploadedMedia = await _uploadMediaFiles([...images, ...videos]);
    final imagePayload = uploadedMedia
        .where((item) => item.mediaType == 'image')
        .map((item) => item.toTracePayload())
        .toList();
    final videoPayload = uploadedMedia
        .where((item) => item.mediaType == 'video')
        .map((item) => item.toTracePayload())
        .toList();

    final response = await _dio.post(
      '/trace/events',
      data: {
        'product': batchId,
        'eventType': actionType,
        'description': note,
        'details': details ?? const {},
        'images': imagePayload,
        'videos': videoPayload,
      },
    );

    final payload = response.data as Map<String, dynamic>;
    final event =
        (payload['event'] as Map<String, dynamic>?) ??
        (payload['traceEvent'] as Map<String, dynamic>?) ??
        const {};
    final blockchain =
        payload['blockchain'] as Map<String, dynamic>? ?? const {};
    final message =
        (payload['msg'] ??
                payload['message'] ??
                payload['warning'] ??
                (blockchain.isNotEmpty
                    ? 'Đã lưu nhật ký và ghi nhận xác thực thành công.'
                    : 'Đã lưu nhật ký nhưng blockchain chưa được cấu hình.'))
            .toString();

    return CreateEventResult(
      message: message,
      batchId: batchId,
      transactionHash:
          (payload['txHash'] ?? blockchain['txHash'] ?? event['txHash'] ?? '')
              .toString(),
      dataHash:
          payload['dataHash']?.toString() ??
          blockchain['dataHash']?.toString() ??
          event['dataHash']?.toString(),
      onChainStatus:
          (payload['onChainStatus'] ?? event['onChainStatus'] ?? 'pending')
              .toString(),
      warning: payload['warning']?.toString(),
    );
  }

  Batch _mapProductToBatch(Map<String, dynamic> product) {
    final events = product['events'] as List<dynamic>? ?? const [];
    return Batch(
      id: (product['_id'] ?? '').toString(),
      batchId: (product['_id'] ?? '').toString(),
      productName: (product['name'] ?? '').toString(),
      productType: (product['category'] ?? product['type'] ?? '').toString(),
      origin: (product['origin'] ?? '').toString(),
      description: (product['description'] ?? '').toString(),
      status: (product['status'] ?? 'active').toString(),
      initialQuantity: _numToDouble(product['initial_quantity']),
      currentQuantity: _numToDouble(product['current_quantity']),
      unit: (product['unit'] ?? 'kg').toString(),
      qrCodeUrl: (product['qrcode'] ?? '').toString(),
      liveCameras: _mapLiveCameras(product['live_cameras']),
      events: events
          .whereType<Map<String, dynamic>>()
          .map(_mapTraceEvent)
          .toList(),
    );
  }

  List<LiveCamera> _mapLiveCameras(dynamic raw) {
    if (raw is! List) return const [];

    return raw
        .whereType<Map<String, dynamic>>()
        .map(LiveCamera.fromJson)
        .where((camera) => camera.isActive && camera.streamUrl.isNotEmpty)
        .toList();
  }

  double _numToDouble(dynamic raw) {
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw?.toString() ?? '') ?? 0;
  }

  Future<List<LiveCamera>> getProductCameras(String productId) async {
    final response = await _dio.get('/products/$productId');
    final payload = response.data as Map<String, dynamic>;
    final product = payload['product'] as Map<String, dynamic>? ?? const {};
    final raw = product['live_cameras'] as List<dynamic>? ?? const [];

    return raw
        .whereType<Map<String, dynamic>>()
        .map(LiveCamera.fromJson)
        .toList();
  }

  Future<List<LiveCamera>> updateProductCameras({
    required String productId,
    required List<LiveCamera> cameras,
  }) async {
    final response = await _dio.patch(
      '/products/$productId/cameras',
      data: {
        'live_cameras': cameras
            .map(
              (camera) => {
                'name': camera.name.trim(),
                'stream_url': camera.streamUrl.trim(),
                'location': camera.location.trim(),
                'is_active': camera.isActive,
              },
            )
            .toList(),
      },
    );

    final payload = response.data as Map<String, dynamic>;
    final product = payload['product'] as Map<String, dynamic>? ?? const {};
    final raw = product['live_cameras'] as List<dynamic>? ?? const [];

    return raw
        .whereType<Map<String, dynamic>>()
        .map(LiveCamera.fromJson)
        .toList();
  }

  BatchEvent _mapTraceEvent(Map<String, dynamic> event) {
    return BatchEvent(
      id: (event['_id'] ?? '').toString(),
      actionType: (event['eventType'] ?? event['actionType'] ?? '').toString(),
      note: (event['description'] ?? event['note'] ?? '').toString(),
      details: event['details'] is Map<String, dynamic>
          ? (event['details'] as Map<String, dynamic>)
          : const {},
      imageUrls: (event['images'] as List<dynamic>? ?? const [])
          .map(
            (item) => item is Map<String, dynamic>
                ? _resolveMediaUrl(
                    (item['path'] ?? item['url'] ?? '').toString(),
                  )
                : _resolveMediaUrl(item.toString()),
          )
          .where((item) => item.isNotEmpty)
          .toList(),
      videoUrls: (event['videos'] as List<dynamic>? ?? const [])
          .map(
            (item) => item is Map<String, dynamic>
                ? _resolveMediaUrl(
                    (item['path'] ?? item['url'] ?? '').toString(),
                  )
                : _resolveMediaUrl(item.toString()),
          )
          .where((item) => item.isNotEmpty)
          .toList(),
      dataHash: event['dataHash']?.toString(),
      transactionHash:
          event['transactionHash']?.toString() ?? event['txHash']?.toString(),
      blockNumber: event['blockNumber'] is num
          ? (event['blockNumber'] as num).toInt()
          : null,
      actor:
          event['actor']?.toString() ??
          (event['recorded_by'] is Map<String, dynamic>
              ? (event['recorded_by']['first_name'] ?? '').toString()
              : null),
      onChainStatus: (event['onChainStatus'] ?? 'pending').toString(),
      createdAt:
          DateTime.tryParse((event['createdAt'] ?? '').toString()) ??
          DateTime.now(),
    );
  }

  Future<List<_UploadedMedia>> _uploadMediaFiles(List<XFile> files) async {
    if (files.isEmpty) return const [];

    final formData = FormData();
    for (final file in files) {
      final contentType = _guessMediaType(file.name);
      final bytes = await file.readAsBytes();
      formData.files.add(
        MapEntry(
          'files',
          MultipartFile.fromBytes(
            bytes,
            filename: file.name,
            contentType: contentType,
          ),
        ),
      );
    }

    final response = await _dio.post('/upload/media', data: formData);
    final payload = response.data;

    final list = payload is Map<String, dynamic>
        ? (payload['files'] as List<dynamic>? ?? const [])
        : const <dynamic>[];

    return list.map((item) {
      final map = item as Map<String, dynamic>;
      final path = (map['path'] ?? '').toString();
      final filename = (map['filename'] ?? '').toString();
      final mediaType = (map['mediaType'] ?? 'image').toString();
      final mimeType = map['mimeType']?.toString();

      return _UploadedMedia(
        path: path,
        filename: filename,
        mediaType: mediaType,
        mimeType: mimeType,
      );
    }).toList();
  }

  String _resolveMediaUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    final baseUri = Uri.parse(_dio.options.baseUrl);
    final rootUri = baseUri.replace(path: '/', query: '', fragment: '');
    final normalized = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return rootUri.resolve(normalized).toString();
  }

  MediaType _guessMediaType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();

    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'gif':
        return MediaType('image', 'gif');
      case 'webp':
        return MediaType('image', 'webp');
      case 'mp4':
        return MediaType('video', 'mp4');
      case 'mov':
        return MediaType('video', 'quicktime');
      case 'avi':
        return MediaType('video', 'x-msvideo');
      case 'mkv':
        return MediaType('video', 'x-matroska');
      case 'webm':
        return MediaType('video', 'webm');
      default:
        return MediaType('application', 'octet-stream');
    }
  }
}
