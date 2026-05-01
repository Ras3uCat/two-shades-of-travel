# QA — Detailed Implementation Guide

## QA Report Template

Save to `qa/reports/YYYY-MM-DD_feature_name.md`:

```markdown
# QA Report — {Feature Name}
**Date:** YYYY-MM-DD
**Status:** PASS | FAIL | PARTIAL
**Environment:** Localhost:PORT | Staging
**Feature File:** planning/features/01_active/NNN_feature.md
**Tested By:** QA Agent

---

## Acceptance Criteria Results
| # | Criterion | Result | Notes |
|---|---|---|---|
| 1 | User can complete checkout | PASS | — |
| 2 | is_premium flips after payment | FAIL | Still false after 30s |

---

## Regression Check
| Flow | Result | Notes |
|---|---|---|
| Signup → verify → login | PASS | — |
| Session persists after refresh | PASS | — |
| Core feature still works | PASS | — |
| Stripe checkout (if changed) | FAIL | See errors below |

---

## Errors Found

### Critical
```
POST /api/payments/intent → 500
{"error": "STRIPE_SECRET_KEY not set in environment"}
```

### Minor
- Checkout button text overflows on iPhone SE viewport

---

## Recommendation
**BLOCK** — return to payments engineer.
Fix: Verify `STRIPE_SECRET_KEY` is set in Supabase Edge Function environment.
```

## Flutter Widget Test Template

```dart
// test/features/auth/views/login_view_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/mockito.dart';
import 'package:myapp/features/auth/auth.dart';
import 'package:myapp/controllers/auth_controller.dart';

class MockAuthController extends GetxController with Mock implements AuthController {}

void main() {
  late MockAuthController mockCtrl;

  setUp(() {
    Get.testMode = true;
    mockCtrl = MockAuthController();
    Get.put<AuthController>(mockCtrl);
  });

  tearDown(() => Get.reset());

  testWidgets('shows error when login fails', (tester) async {
    when(mockCtrl.isLoading).thenReturn(false.obs);
    when(mockCtrl.hasError).thenReturn(true.obs);
    when(mockCtrl.errorMessage).thenReturn('Invalid credentials'.obs);

    await tester.pumpWidget(
      GetMaterialApp(home: const LoginView()),
    );
    await tester.pump();

    expect(find.text('Invalid credentials'), findsOneWidget);
  });

  testWidgets('calls login on button tap', (tester) async {
    when(mockCtrl.isLoading).thenReturn(false.obs);
    when(mockCtrl.hasError).thenReturn(false.obs);

    await tester.pumpWidget(
      GetMaterialApp(home: const LoginView()),
    );

    await tester.enterText(find.byKey(const Key('email_field')), 'test@test.com');
    await tester.enterText(find.byKey(const Key('password_field')), 'password123');
    await tester.tap(find.text('Login'));
    await tester.pump();

    verify(mockCtrl.login(email: 'test@test.com', password: 'password123')).called(1);
  });
}
```

## Repository Unit Test Template

```dart
// test/features/payments/repositories/payments_repository_test.dart
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:myapp/core/network/api_client.dart';
import 'package:myapp/features/payments/repositories/payments_repository.dart';

@GenerateMocks([ApiClient])
void main() {
  late PaymentsRepository repo;
  late MockApiClient mockClient;

  setUp(() {
    mockClient = MockApiClient();
    Get.put<ApiClient>(mockClient);
    repo = PaymentsRepository();
  });

  tearDown(() => Get.reset());

  group('createPaymentIntent', () {
    test('returns clientSecret on 200', () async {
      when(mockClient.post(any, data: anyNamed('data'))).thenAnswer(
        (_) async => Response(
          data: {'client_secret': 'pi_test_secret'},
          requestOptions: RequestOptions(),
          statusCode: 200,
        ),
      );

      final result = await repo.createPaymentIntent(
        amountCents: 999,
        currency: 'usd',
      );

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Expected Right'),
        (secret) => expect(secret, 'pi_test_secret'),
      );
    });

    test('returns ApiFailure on 500', () async {
      when(mockClient.post(any, data: anyNamed('data'))).thenThrow(
        DioException(
          requestOptions: RequestOptions(),
          response: Response(
            statusCode: 500,
            requestOptions: RequestOptions(),
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      final result = await repo.createPaymentIntent(
        amountCents: 999,
        currency: 'usd',
      );

      expect(result.isLeft(), true);
    });
  });
}
```

## Integration Test Template

```dart
// integration_test/auth_flow_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:myapp/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Full auth flow: signup → login → dashboard', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Navigate to signup
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();

    // Fill form
    await tester.enterText(
      find.byKey(const Key('signup_email')),
      'test+${DateTime.now().millisecondsSinceEpoch}@test.com',
    );
    await tester.enterText(find.byKey(const Key('signup_password')), 'Test1234!');
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Should land on email verification screen
    expect(find.text('Check your email'), findsOneWidget);
  });
}
```

## Running Tests

```bash
# Unit + widget tests
flutter test

# Specific file
flutter test test/controllers/payments_controller_test.dart

# With coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# Integration tests (requires running device/emulator)
flutter test integration_test/auth_flow_test.dart
```
