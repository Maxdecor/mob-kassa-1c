import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart';
import 'models.dart';

String money(double v) =>
    NumberFormat('#,##0.##', 'en').format(v).replaceAll(',', ' ');

String qty(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(3).replaceAll(RegExp(r'0+$'), '');

class AppState extends ChangeNotifier {
  late final SharedPreferences _p;

  String baseUrl = '';
  String user = '';
  String pass = '';
  String orgId = '';
  String warehouseId = '';
  String warehouseName = '';
  String kkmId = '';
  String kkmName = '';
  String priceTypeId = '';

  Api? api;
  final List<CartLine> cart = [];
  ThemeMode themeMode = ThemeMode.system;
  bool canSeeCost = false;
  final Map<String, double?> _costCache = {};

  bool get loggedIn => api != null;

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    notifyListeners();
    await _p.setString('themeMode', mode.name);
  }

  Future<void> load() async {
    _p = await SharedPreferences.getInstance();
    final savedTheme = _p.getString('themeMode');
    themeMode = ThemeMode.values.firstWhere(
      (m) => m.name == savedTheme,
      orElse: () => ThemeMode.system,
    );
    canSeeCost = _p.getBool('canSeeCost') ?? false;
    baseUrl = _p.getString('baseUrl') ?? '';
    user = _p.getString('user') ?? '';
    pass = _p.getString('pass') ?? '';
    orgId = _p.getString('orgId') ?? '';
    warehouseId = _p.getString('warehouseId') ?? '';
    warehouseName = _p.getString('warehouseName') ?? '';
    kkmId = _p.getString('kkmId') ?? '';
    kkmName = _p.getString('kkmName') ?? '';
    priceTypeId = _p.getString('priceTypeId') ?? '';
    if (baseUrl.isNotEmpty && user.isNotEmpty && warehouseId.isNotEmpty) {
      api = Api(baseUrl, user, pass);
    }
  }

  Future<void> signIn({
    required String baseUrl,
    required String user,
    required String pass,
    required Ref org,
    required Ref warehouse,
    required Ref kkm,
    required Ref priceType,
    required bool canSeeCost,
  }) async {
    this.canSeeCost = canSeeCost;
    _costCache.clear();
    await _p.setBool('canSeeCost', canSeeCost);
    this.baseUrl = baseUrl;
    this.user = user;
    this.pass = pass;
    orgId = org.id;
    warehouseId = warehouse.id;
    warehouseName = warehouse.name;
    kkmId = kkm.id;
    kkmName = kkm.name;
    priceTypeId = priceType.id;
    await _p.setString('baseUrl', baseUrl);
    await _p.setString('user', user);
    await _p.setString('pass', pass);
    await _p.setString('orgId', orgId);
    await _p.setString('warehouseId', warehouseId);
    await _p.setString('warehouseName', warehouseName);
    await _p.setString('kkmId', kkmId);
    await _p.setString('kkmName', kkmName);
    await _p.setString('priceTypeId', priceTypeId);
    api = Api(baseUrl, user, pass);
    cart.clear();
    notifyListeners();
  }

  Future<void> signOut() async {
    await _p.remove('pass');
    pass = '';
    api = null;
    cart.clear();
    notifyListeners();
  }

  /// Zakup narxi (keshlanadi). Ruxsat bo'lmasa ApiException tashlaydi.
  Future<double?> costOf(String productId) async {
    if (_costCache.containsKey(productId)) return _costCache[productId];
    final v = await api!.cost(productId);
    _costCache[productId] = v;
    return v;
  }

  /// Ilova ochilganda ruxsatni serverdan yangilaydi (admin registrni o'zgartirgan bo'lishi mumkin).
  Future<void> refreshAccess() async {
    try {
      final info = await api!.info();
      if (info.canSeeCost != canSeeCost) {
        canSeeCost = info.canSeeCost;
        _costCache.clear();
        await _p.setBool('canSeeCost', canSeeCost);
        notifyListeners();
      }
    } catch (_) {
      // tarmoq yo'q bo'lsa saqlangan qiymat qoladi
    }
  }

  double get total => cart.fold(0.0, (s, l) => s + l.sum);

  void addToCart(Product p) {
    final i = cart.indexWhere((l) => l.product.id == p.id);
    if (i >= 0) {
      cart[i].qty += 1;
    } else {
      cart.add(CartLine(p));
    }
    notifyListeners();
  }

  void changeQty(CartLine l, double delta) {
    l.qty += delta;
    if (l.qty <= 0) cart.remove(l);
    notifyListeners();
  }

  void setPrice(CartLine l, double price) {
    l.price = price;
    notifyListeners();
  }

  void setQty(CartLine l, double value) {
    l.qty = value;
    notifyListeners();
  }

  void removeLine(CartLine l) {
    cart.remove(l);
    notifyListeners();
  }

  void clearCart() {
    cart.clear();
    notifyListeners();
  }
}

final app = AppState();
