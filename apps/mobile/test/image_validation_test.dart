import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:ofrivo_mobile/core/validation/image_validation.dart';

void main() {
  late Directory directory;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('ofrivo-image-test-');
  });

  tearDown(() {
    if (directory.existsSync()) directory.deleteSync(recursive: true);
  });

  test('accepts a supported image signature and rejects a spoofed extension',
      () async {
    final valid = File('${directory.path}${Platform.pathSeparator}photo.jpg')
      ..writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10]);
    final spoofed = File('${directory.path}${Platform.pathSeparator}photo.png')
      ..writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xE0]);

    expect(await ImageValidation.validatePath(valid.path), isNull);
    expect(await ImageValidation.validatePath(spoofed.path), isNotNull);
  });

  test('enforces count, duplicate, missing-file, and size boundaries',
      () async {
    final first = File('${directory.path}${Platform.pathSeparator}one.jpg')
      ..writeAsBytesSync([0xFF, 0xD8, 0xFF]);
    final second = File('${directory.path}${Platform.pathSeparator}two.jpg')
      ..writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xE0]);

    expect((await ImageValidation.validatePaths(
            [first.path, second.path], maxCount: 1))
        .error, isNotNull);
    expect((await ImageValidation.validatePaths(
            [first.path, first.path], maxCount: 2))
        .error, isNotNull);
    expect(
        await ImageValidation.validatePath(
            '${directory.path}${Platform.pathSeparator}missing.jpg'),
        isNotNull);
    expect(await ImageValidation.validatePath(first.path, maxBytes: 2),
        isNotNull);
  });
}
