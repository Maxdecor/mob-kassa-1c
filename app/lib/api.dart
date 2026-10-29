import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'models.dart';

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}

/// 1C HTTP-servis "mobkassa" bilan ishlaydi (Basic autentifikatsiya).
class Api {
  final String baseUrl;
  final String user;
  final String pass;
  final http.Client _client = http.Client();

  Api(this.baseUrl, this.user, this.pass);

  String get _root => '${baseUrl.trim().replaceAll(RegExp(r'/+$'), '')}/hs/mobkassa';

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, String?> query = const {},
    Object? body,
  }) async {
    final params = <String, String>{
      for (final e in query.entries)
        if (e.value != null && e.value!.isNotEmpty) e.key: e.value!,
    };
    var uri = Uri.parse('$_root$path');
    if (params.isNotEmpty) uri = uri.replace(queryParameters: params);

    final req = http.Request(method, uri);
    req.headers['Authorization'] = 'Basic ${base64Encode(utf8.encode('$user:$pass'))}';
    req.headers['Accept'] = 'application/json';
    if (body != null) {
      req.headers['Content-Type'] = 'application/json; charset=utf-8';
      req.body = jsonEncode(body);
    }

    http.Response res;
    try {
      final streamed = await _client.send(req).timeout(const Duration(seconds: 30));
      res = await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw const ApiException('Server javob bermadi. Internet va manzilni tekshiring.');
    } on SocketException {
      throw const ApiException('Serverga ulanib bo\'lmadi. Manzil va internetni tekshiring.');
    } on http.ClientException {
      throw const ApiException('Serverga ulanib bo\'lmadi. Manzil va internetni tekshiring.');
    } on HandshakeException {
      throw const ApiException('Xavfsiz ulanish (SSL) xatosi.');
    }

    dynamic data;
    try {
      data = jsonDecode(utf8.decode(res.bodyBytes));
    } catch (_) {
      data = null;
    }

    if (res.statusCode == 401 || res.statusCode == 403) {
      throw const ApiException('Login yoki parol noto\'g\'ri, yoki huquq yo\'q.');
    }
    if (res.statusCode >= 400) {
      final msg = (data is Map && data['error'] != null)
          ? data['error'].toString()
          : 'Server xatosi (${res.statusCode})';
      throw ApiException(msg);
    }
    if (data == null) {
      throw const ApiException('Server noto\'g\'ri javob berdi. Manzilni tekshiring.');
    }
    return data;
  }

  Future<ServerInfo> info() async =>
      ServerInfo.fromJson(await _send('GET', '/info') as Map<String, dynamic>);

  Future<List<Product>> products({
    String? q,
    String? barcode,
    String? warehouse,
    String? priceType,
    int limit = 50,
  }) async {
    final data = await _send('GET', '/products', query: {
      'q': q,
      'barcode': barcode,
      'warehouse': warehouse,
      'pricetype': priceType,
      'limit': '$limit',
    });
    return (data as List).map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<ReceiptSummary>> receipts(DateTime from, DateTime to) async {
    String d(DateTime x) => x.toIso8601String().substring(0, 10);
    final data = await _send('GET', '/receipts', query: {'from': d(from), 'to': d(to)});
    return (data as List).map((e) => ReceiptSummary.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<TopData> top(DateTime from, DateTime to) async {
    String d(DateTime x) => x.toIso8601String().substring(0, 10);
    final data = await _send('GET', '/top', query: {'from': d(from), 'to': d(to)});
    return TopData.fromJson(data as Map<String, dynamic>);
  }

  Future<ReceiptDetail> receipt(String id) async =>
      ReceiptDetail.fromJson(await _send('GET', '/receipts/$id') as Map<String, dynamic>);

  Future<Map<String, dynamic>> createReceipt({
    required String organization,
    required String warehouse,
    required String cashRegister,
    required String priceType,
    required bool deferred,
    required String payment,
    required List<CartLine> lines,
  }) async {
    final data = await _send('POST', '/receipts', body: {
      'organization': organization,
      'warehouse': warehouse,
      'cashRegister': cashRegister,
      'priceType': priceType,
      'deferred': deferred,
      'payment': payment,
      'lines': [
        for (final l in lines) {'id': l.product.id, 'quantity': l.qty, 'price': l.price},
      ],
    });
    return data as Map<String, dynamic>;
  }

  /// Zakup narxi. Ruxsat bo'lmasa ApiException (403). Topilmasa null.
  Future<double?> cost(String productId) async {
    final data = await _send('GET', '/cost', query: {'id': productId}) as Map<String, dynamic>;
    return data['found'] == true ? toDouble(data['price']) : null;
  }

  /// Chekni qaytarish. [lines] bo'sh bo'lsa to'liq qaytariladi.
  Future<Map<String, dynamic>> returnReceipt(String id, List<({int number, double quantity})> lines) async {
    final data = await _send('POST', '/receipts/$id/return', body: {
      'lines': [
        for (final l in lines) {'lineNumber': l.number, 'quantity': l.quantity},
      ],
    });
    return data as Map<String, dynamic>;
  }

  Future<void> postReceipt(String id) async {
    await _send('POST', '/receipts/$id/post', body: <String, dynamic>{});
  }
}
