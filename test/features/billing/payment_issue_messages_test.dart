import 'package:flutter_test/flutter_test.dart';

import 'package:atlas_flutter_app/features/billing/services/payment_issue_messages.dart';

void main() {
  final t0 = DateTime(2026, 11, 16, 9);

  test('asks the first time, then not again within the interval', () {
    final throttle = PaymentIssueMessageThrottle();
    expect(throttle.shouldShow(t0), isTrue);
    expect(throttle.shouldShow(t0.add(const Duration(minutes: 5))), isFalse);
    expect(throttle.shouldShow(t0.add(const Duration(hours: 5, minutes: 59))), isFalse);
  });

  test('asks again once the interval has passed, and restarts the clock', () {
    final throttle = PaymentIssueMessageThrottle();
    expect(throttle.shouldShow(t0), isTrue);
    final later = t0.add(const Duration(hours: 6));
    expect(throttle.shouldShow(later), isTrue);
    expect(throttle.shouldShow(later.add(const Duration(hours: 1))), isFalse);
  });

  test('the interval is configurable', () {
    final throttle = PaymentIssueMessageThrottle(interval: const Duration(minutes: 10));
    expect(throttle.shouldShow(t0), isTrue);
    expect(throttle.shouldShow(t0.add(const Duration(minutes: 10))), isTrue);
  });
}
