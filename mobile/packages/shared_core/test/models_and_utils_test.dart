import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/shared_core.dart';

void main() {
  group('EmailValidator Tests', () {
    test('validates standard email formats', () {
      expect(EmailValidator.isValid('user@example.com'), true);
      expect(EmailValidator.isValid('mechanic.servio@servio.lk'), true);
      expect(EmailValidator.isValid('support@app.io'), true);
    });

    test('rejects invalid email formats', () {
      expect(EmailValidator.isValid('invalid-email'), false);
      expect(EmailValidator.isValid('user@'), false);
      expect(EmailValidator.isValid('@domain.com'), false);
      expect(EmailValidator.isValid('user@domain'), false);
    });

    test('validate helper returns error strings', () {
      expect(EmailValidator.validate(null), 'Please enter your email');
      expect(EmailValidator.validate(''), 'Please enter your email');
      expect(EmailValidator.validate('bademail'), 'Please enter a valid email');
      expect(EmailValidator.validate('good@email.com'), null);
    });
  });

  group('AppointmentModel Tests', () {
    test('parses camelCase and snake_case correctly', () {
      final json = {
        'id': 1,
        'userId': 'u-123',
        'vehicleId': 10,
        'vehicleMake': 'Toyota',
        'vehicleModel': 'Aqua',
        'vehicleYear': 2017,
        'licensePlate': 'CBA-1234',
        'serviceType': 'Oil Change',
        'appointmentDate': '2026-09-02T10:00:00',
        'status': 'CONFIRMED',
        'estimatedCost': 15000.0,
      };

      final model = AppointmentModel.fromJson(json);
      expect(model.id, 1);
      expect(model.vehicleDisplay, 'Toyota Aqua 2017');
      expect(model.plateDisplay, 'CBA-1234');
      expect(model.statusLabel, 'Confirmed');
      expect(model.formattedCost, 'LKR 15,000');
      expect(model.toJson()['serviceType'], 'Oil Change');
    });
  });

  group('VehicleModel Tests', () {
    test('parses vehicle fields and handles display properties', () {
      final json = {
        'id': 5,
        'userId': 'u-456',
        'make': 'Honda',
        'model': 'Civic',
        'year': 2020,
        'licensePlate': 'WP-CAA-5566',
        'vin': '1HGCR2F83HA000000',
      };

      final model = VehicleModel.fromJson(json);
      expect(model.id, 5);
      expect(model.displayName, 'Honda Civic');
      expect(model.detailLine, 'WP-CAA-5566 · 2020');
      expect(model.toRequestMap()['make'], 'Honda');
    });
  });

  group('ServiceModel & OfferModel Tests', () {
    test('parses service category and promotional offer models', () {
      final catJson = {
        'id': 1,
        'name': 'Detailing',
        'description': 'Car wash and detailing',
        'services': [
          {
            'id': 10,
            'name': 'Interior Vacuum',
            'basePrice': 3500.0,
            'options': [
              {
                'id': 100,
                'name': 'Seat Shampoo',
                'priceAdjustment': 2000.0,
              }
            ]
          }
        ]
      };

      final category = ServiceCategoryModel.fromJson(catJson);
      expect(category.name, 'Detailing');
      expect(category.services.length, 1);
      expect(category.services[0].formattedBasePrice, 'LKR 3,500.00');
      expect(category.services[0].options[0].formattedPrice, '+LKR 2,000');

      final offerJson = {
        'id': 1,
        'title': 'Monsoon Discount',
        'description': '20% off all wiper blade and rain services',
        'discountPercentage': 20.0,
        'bannerUrl': 'https://example.com/banner.png',
        'isActive': true,
      };

      final offer = OfferModel.fromJson(offerJson);
      expect(offer.title, 'Monsoon Discount');
      expect(offer.formattedDiscount, '20% OFF');
      expect(offer.isActive, true);
    });
  });
}
