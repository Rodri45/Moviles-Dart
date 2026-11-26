import 'package:flutter_test/flutter_test.dart';
import 'package:parkwise/core/client_id.dart';

void main() {
  test('report ids are random UUIDs of version 4', () {
    final pattern = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );
    final ids = {for (var i = 0; i < 200; i++) newClientId()};

    expect(ids, hasLength(200));
    expect(ids.every(pattern.hasMatch), isTrue);
  });
}
