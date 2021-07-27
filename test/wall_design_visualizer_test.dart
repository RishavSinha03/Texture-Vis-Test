import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wall_design_visualizer/wall_design_visualizer.dart';

void main() {
  const MethodChannel channel = MethodChannel('wall_design_visualizer');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await WallDesignVisualizer.platformVersion, '42');
  });
}
