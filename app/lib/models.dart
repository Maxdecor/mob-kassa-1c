double toDouble(dynamic v) {
  if (v is num) return v.toDouble();
  return double.tryParse('$v') ?? 0;
}

class Ref {
  final String id;
  final String name;
  const Ref(this.id, this.name);

  factory Ref.fromJson(Map<String, dynamic> j) =>
      Ref(j['id'] as String, (j['name'] as String?) ?? '');

  static List<Ref> list(dynamic v) {
    if (v is! List) return const [];
    return v.map((e) => Ref.fromJson(e as Map<String, dynamic>)).toList();
  }
}

class ServerInfo {
  final String user;
  final List<Ref> organizations;
  final List<Ref> warehouses;
  final List<Ref> cashRegisters;
  final List<Ref> priceTypes;
  final bool canSeeCost;

  const ServerInfo({
    required this.user,
    required this.organizations,
    required this.warehouses,
    required this.cashRegisters,
    required this.priceTypes,
    required this.canSeeCost,
  });

  factory ServerInfo.fromJson(Map<String, dynamic> j) => ServerInfo(
        user: (j['user'] as String?) ?? '',
        organizations: Ref.list(j['organizations']),
        warehouses: Ref.list(j['warehouses']),
        cashRegisters: Ref.list(j['cashRegisters']),
        priceTypes: Ref.list(j['priceTypes']),
        canSeeCost: j['canSeeCost'] == true,
      );
}

class Product {
  final String id;
  final String code;
  final String name;
  final String article;
  final String unit;
  final double price;
  final double stock;
  final String barcode;

  const Product({
    required this.id,
    required this.code,
    required this.name,
    required this.article,
    required this.unit,
    required this.price,
    required this.stock,
    required this.barcode,
  });

  factory Product.fromJson(Map<String, dynamic> j) => Product(
        id: j['id'] as String,
        code: (j['code'] as String?) ?? '',
        name: (j['name'] as String?) ?? '',
        article: (j['article'] as String?) ?? '',
        unit: (j['unit'] as String?) ?? '',
        price: toDouble(j['price']),
        stock: toDouble(j['stock']),
        barcode: (j['barcode'] as String?) ?? '',
      );
}

class CartLine {
  final Product product;
  double qty;
  double price;

  CartLine(this.product, {this.qty = 1, double? price}) : price = price ?? product.price;

  double get sum => (qty * price * 100).round() / 100;
}

/// Top ro'yxat qatori: tovar (quantity, unit) yoki sotuvchi (receipts).
class TopItem {
  final String name;
  final String unit;
  final double quantity;
  final int receipts;
  final double sum;

  const TopItem({
    required this.name,
    required this.unit,
    required this.quantity,
    required this.receipts,
    required this.sum,
  });

  factory TopItem.fromJson(Map<String, dynamic> j) => TopItem(
        name: (j['name'] as String?) ?? '',
        unit: (j['unit'] as String?) ?? '',
        quantity: toDouble(j['quantity']),
        receipts: toDouble(j['receipts']).round(),
        sum: toDouble(j['sum']),
      );
}

class TopData {
  final double total;
  final int receipts;
  final double average;
  final List<TopItem> goods;
  final List<TopItem> sellers;

  const TopData({
    required this.total,
    required this.receipts,
    required this.average,
    required this.goods,
    required this.sellers,
  });

  factory TopData.fromJson(Map<String, dynamic> j) => TopData(
        total: toDouble(j['total']),
        receipts: toDouble(j['receipts']).round(),
        average: toDouble(j['average']),
        goods: _items(j['goods']),
        sellers: _items(j['sellers']),
      );

  static List<TopItem> _items(dynamic v) {
    if (v is! List) return const [];
    return v.map((e) => TopItem.fromJson(e as Map<String, dynamic>)).toList();
  }
}

class ReceiptSummary {
  final String id;
  final String number;
  final DateTime? date;
  final bool posted;
  final bool deferred;
  final String status;
  final double total;
  final int items;

  const ReceiptSummary({
    required this.id,
    required this.number,
    required this.date,
    required this.posted,
    required this.deferred,
    required this.status,
    required this.total,
    required this.items,
  });

  factory ReceiptSummary.fromJson(Map<String, dynamic> j) => ReceiptSummary(
        id: j['id'] as String,
        number: (j['number'] as String?) ?? '',
        date: DateTime.tryParse((j['date'] as String?) ?? ''),
        posted: j['posted'] == true,
        deferred: j['deferred'] == true,
        status: (j['status'] as String?) ?? '',
        total: toDouble(j['total']),
        items: toDouble(j['items']).round(),
      );
}

class ReceiptLine {
  final int number;
  final String name;
  final String article;
  final String unit;
  final double quantity;
  final double price;
  final double sum;

  const ReceiptLine({
    required this.number,
    required this.name,
    required this.article,
    required this.unit,
    required this.quantity,
    required this.price,
    required this.sum,
  });

  factory ReceiptLine.fromJson(Map<String, dynamic> j) => ReceiptLine(
        number: toDouble(j['number']).round(),
        name: (j['name'] as String?) ?? '',
        article: (j['article'] as String?) ?? '',
        unit: (j['unit'] as String?) ?? '',
        quantity: toDouble(j['quantity']),
        price: toDouble(j['price']),
        sum: toDouble(j['sum']),
      );
}

class ReceiptDetail {
  final String id;
  final String number;
  final DateTime? date;
  final bool posted;
  final bool deferred;
  final double total;
  final List<ReceiptLine> lines;

  const ReceiptDetail({
    required this.id,
    required this.number,
    required this.date,
    required this.posted,
    required this.deferred,
    required this.total,
    required this.lines,
  });

  factory ReceiptDetail.fromJson(Map<String, dynamic> j) => ReceiptDetail(
        id: j['id'] as String,
        number: (j['number'] as String?) ?? '',
        date: DateTime.tryParse((j['date'] as String?) ?? ''),
        posted: j['posted'] == true,
        deferred: j['deferred'] == true,
        total: toDouble(j['total']),
        lines: ((j['lines'] as List?) ?? const [])
            .map((e) => ReceiptLine.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
