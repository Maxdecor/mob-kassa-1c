import 'package:flutter_test/flutter_test.dart';

import 'package:mob_kassa/models.dart';

void main() {
  test('CartLine summasi kopeykagacha yaxlitlanadi', () {
    const p = Product(
      id: '1',
      code: '1',
      name: 'Test',
      article: '',
      unit: 'dona',
      price: 9500.333,
      stock: 5,
      barcode: '4780001234567',
    );
    final line = CartLine(p, qty: 3);
    expect(line.sum, 28501.0);
  });

  test('ReceiptSummary JSON ni to\'g\'ri o\'qiydi', () {
    final r = ReceiptSummary.fromJson({
      'id': 'a',
      'number': '000001',
      'date': '2026-10-24T16:48:00',
      'posted': false,
      'deferred': true,
      'status': '',
      'total': 60400,
      'items': 3,
    });
    expect(r.deferred, true);
    expect(r.total, 60400.0);
    expect(r.items, 3);
    expect(r.date?.hour, 16);
  });
}
