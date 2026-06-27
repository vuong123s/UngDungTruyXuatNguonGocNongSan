import 'dart:convert';

import 'package:app/core/api_client.dart';
import 'package:app/models/disease_detection.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

class DiseaseDetectionService {
  DiseaseDetectionService({Dio? dio}) : _dio = dio ?? ApiClient.instance.dio;
  final Dio _dio;

  Future<List<DiseaseDetection>> getDetections({String? risk}) async {
    final response = await _dio.get(
      '/disease-detections',
      queryParameters: {if (risk != null && risk.isNotEmpty) 'risk': risk},
    );
    return _mapList(response.data);
  }

  Future<DiseaseDetection> createDetection({
    required String productId,
    required List<String> symptoms,
    String? notes,
    List<XFile> images = const [],
  }) async {
    final formData = FormData.fromMap({
      'product': productId,
      'symptoms': jsonEncode(symptoms),
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    });

    for (final image in images.take(5)) {
      formData.files.add(
        MapEntry(
          'images',
          await MultipartFile.fromFile(image.path, filename: image.name),
        ),
      );
    }

    final response = await _dio.post('/disease-detections', data: formData);
    final payload = response.data as Map<String, dynamic>;
    final detection =
        payload['detection'] as Map<String, dynamic>? ?? const {};
    return DiseaseDetection.fromJson(detection);
  }

  Future<void> deleteDetection(String id) async {
    await _dio.delete('/disease-detections/$id');
  }

  List<DiseaseDetection> _mapList(dynamic payload) {
    final raw = payload is Map<String, dynamic>
        ? (payload['detections'] as List<dynamic>? ?? const [])
        : (payload is List ? payload : const <dynamic>[]);
    return raw
        .whereType<Map<String, dynamic>>()
        .map(DiseaseDetection.fromJson)
        .toList();
  }
}
