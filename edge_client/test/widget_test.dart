import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edge_client/main.dart';
import 'package:edge_client/models/user_profile.dart';
import 'package:edge_client/screens/login_screen.dart';
import 'package:edge_client/services/auth_service.dart';

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _createMockHttpClient();
  }
}

HttpClient _createMockHttpClient() {
  final client = _MockHttpClient();
  return client;
}

class _MockHttpClient extends Fake implements HttpClient {
  @override
  bool autoUncompress = true;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return _MockHttpClientRequest();
  }
}

class _MockHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  Future<HttpClientResponse> close() async {
    return _MockHttpClientResponse();
  }
}

class _MockHttpHeaders extends Fake implements HttpHeaders {
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
}

// 1x1 transparent PNG bytes
final List<int> _kTransparentImage = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
  0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
  0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
  0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
  0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
  0x60, 0x82,
];

class _MockHttpClientResponse extends Fake implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  int get contentLength => _kTransparentImage.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([_kTransparentImage]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

void main() {
  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
  });

  testWidgets('SkinGuardEdgeApp smoke test renders executive dashboard', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Pre-authenticate for the smoke test so dashboard shell is accessed directly
    AuthService.currentUserNotifier.value = UserProfile(
      id: 'demo-judge',
      fullName: 'Fatima Al-Mansouri, RN',
      email: 'demo@skinguard.ae',
      role: 'clinician_navigator',
    );

    await tester.pumpWidget(const SkinGuardEdgeApp());
    expect(find.text('SkinGuard AI'), findsOneWidget);
    expect(find.text('2-STEP CLINICAL ARCHITECTURE'), findsOneWidget);
    expect(find.text('ENTER CLINICAL GATEWAY'), findsOneWidget);

    // Tap to enter clinical gateway
    await tester.tap(find.text('ENTER CLINICAL GATEWAY'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify executive active tab is Dashboard
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Start Lesion Scan Now'), findsOneWidget);

    // Tap Scan Wizard nav item (by camera enhance icon)
    await tester.tap(find.byIcon(Icons.camera_enhance_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Scan Wizard is now active
    expect(find.text('Scan Wizard'), findsOneWidget);
    expect(find.text('Patient Context & Demographics'), findsOneWidget);
  });

  testWidgets('LoginScreen renders authentication UI and quick demo access', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(onLoginSuccess: () {}),
      ),
    );

    expect(find.text('SkinGuard UAE'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Remember Me'), findsOneWidget);
    expect(find.text('Forgot Password?'), findsOneWidget);
    expect(find.text('1-Tap Sign In'), findsOneWidget);
  });
}
