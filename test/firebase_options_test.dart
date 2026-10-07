import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:atelierpro_mobile/firebase_options.dart';

void main() {
  test('refuse de créer des options Firebase avec une configuration absente', () {
    dotenv.clean();
    expect(
      () => DefaultFirebaseOptions.web,
      throwsA(anything),
    );
  });

  test('charge correctement les options selon la plateforme quand env est fourni', () {
    dotenv.testLoad(fileInput: '''
FIREBASE_PROJECT_ID=test-project
FIREBASE_STORAGE_BUCKET=test-bucket
FIREBASE_MESSAGING_SENDER_ID=123456789
FIREBASE_WEB_API_KEY=test-web-key
FIREBASE_WEB_APP_ID=1:123456789:web:abcdef
FIREBASE_ANDROID_API_KEY=test-android-key
FIREBASE_ANDROID_APP_ID=1:123456789:android:abcdef
''');

    final webOptions = DefaultFirebaseOptions.web;
    expect(webOptions.apiKey, equals('test-web-key'));
    expect(webOptions.projectId, equals('test-project'));

    final androidOptions = DefaultFirebaseOptions.android;
    expect(androidOptions.apiKey, equals('test-android-key'));
    expect(androidOptions.projectId, equals('test-project'));

    final platformOptions = DefaultFirebaseOptions.currentPlatform;
    expect(platformOptions.projectId, equals('test-project'));

    dotenv.clean();
  });
}
