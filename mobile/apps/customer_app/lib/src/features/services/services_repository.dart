import 'package:flutter/foundation.dart';
import 'package:shared_core/shared_core.dart';

// ─── SERVICES REPOSITORY (communicates with Spring Boot REST API) ───────────

class ServicesRepository {
  final ApiClient _apiClient;

  ServicesRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Fetches all active service categories with their nested services and options via GET /api/services/categories.
  Future<List<ServiceCategoryModel>> getServiceCategories() async {
    try {
      final response = await _apiClient.get<List<ServiceCategoryModel>>(
        '/services/categories',
        fromJson: (data) {
          if (data is List) {
            return data
                .map((e) => ServiceCategoryModel.fromJson(e as Map<String, dynamic>))
                .toList();
          }
          return <ServiceCategoryModel>[];
        },
      );

      return response.data ?? <ServiceCategoryModel>[];
    } catch (e) {
      debugPrint('Error fetching service categories from backend: $e');
      rethrow;
    }
  }

  /// Fetches featured services for the home screen suggestions via GET /api/services/featured.
  Future<List<ServiceModel>> getFeaturedServices() async {
    try {
      final response = await _apiClient.get<List<ServiceModel>>(
        '/services/featured',
        fromJson: (data) {
          if (data is List) {
            return data
                .map((e) => ServiceModel.fromJson(e as Map<String, dynamic>))
                .toList();
          }
          return <ServiceModel>[];
        },
      );

      return response.data ?? <ServiceModel>[];
    } catch (e) {
      debugPrint('Error fetching featured services from backend: $e');
      rethrow;
    }
  }

  /// Fetches active promotional offers via GET /api/services/offers.
  Future<List<OfferModel>> getActiveOffers() async {
    try {
      final response = await _apiClient.get<List<OfferModel>>(
        '/services/offers',
        fromJson: (data) {
          if (data is List) {
            return data
                .map((e) => OfferModel.fromJson(e as Map<String, dynamic>))
                .toList();
          }
          return <OfferModel>[];
        },
      );

      return response.data ?? <OfferModel>[];
    } catch (e) {
      debugPrint('Error fetching active offers from backend: $e');
      return <OfferModel>[];
    }
  }

  /// Searches services by query string via GET /api/services/search?q=...
  Future<List<ServiceModel>> searchServices(String query) async {
    try {
      final response = await _apiClient.get<List<ServiceModel>>(
        '/services/search',
        queryParameters: {'q': query},
        fromJson: (data) {
          if (data is List) {
            return data
                .map((e) => ServiceModel.fromJson(e as Map<String, dynamic>))
                .toList();
          }
          return <ServiceModel>[];
        },
      );

      return response.data ?? <ServiceModel>[];
    } catch (e) {
      debugPrint('Error searching services: $e');
      return <ServiceModel>[];
    }
  }
}
