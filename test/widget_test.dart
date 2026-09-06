import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart_delivery/features/auth/domain/models/delivery_man_body_model.dart';
import 'package:sixam_mart_delivery/features/profile/domain/models/driver_onboarding_model.dart';

void main() {
  test('driver onboarding response preserves payout and document state', () {
    final DriverOnboardingModel onboarding = DriverOnboardingModel.fromJson({
      'status': 'provisionally_approved',
      'payout_locked': true,
      'can_work': true,
      'documents_due_at': '2026-09-21T12:00:00+02:00',
      'days_remaining': 14,
      'documents': [
        {
          'type': 'driving_licence',
          'label': 'Driving licence',
          'status': 'approved',
          'uploaded': true,
          'required_for_work': true,
          'required_for_payout': true,
        },
        {
          'type': 'bank_confirmation',
          'label': 'Bank confirmation',
          'status': 'missing',
          'uploaded': false,
          'required_for_work': false,
          'required_for_payout': true,
        },
      ],
    });

    expect(onboarding.status, 'provisionally_approved');
    expect(onboarding.canWork, isTrue);
    expect(onboarding.payoutLocked, isTrue);
    expect(onboarding.daysRemaining, 14);
    expect(onboarding.documents, hasLength(2));
    expect(onboarding.documents.first.requiredForWork, isTrue);
    expect(onboarding.documents.last.uploaded, isFalse);
    expect(onboarding.documents.last.requiredForPayout, isTrue);
  });

  test('driver registration sends canonical verification consent', () {
    final Map<String, String> payload = DeliveryManBodyModel(
      fName: 'Test',
      lName: 'Driver',
      phone: '+27820000000',
      email: 'driver@example.com',
      password: 'not-a-real-password',
      identityNumber: 'TEST-LICENCE',
      earning: '1',
      zoneId: '1',
      vehicleId: '1',
    ).toJson();

    expect(payload['identity_type'], 'driving_license');
    expect(payload['identity_number'], 'TEST-LICENCE');
    expect(payload['external_verification_consent'], '1');
    expect(payload.containsKey('verification_consent'), isFalse);
  });
}
