import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../state.dart';
import '../widgets.dart';
import 'payment.dart';
import 'products.dart';

/// Asosiy kassa ekrani. Qidiruv maydoni doim tanlangan: HID skaner
/// shtrix-kodni yozib Enter bosadi, tovar o'zi savatga tushadi.
class KassaScreen extends StatefulWidget {
  const KassaScreen({super.key});

  @override
  State<KassaScreen> createState() => _KassaScreenState();
}

class _KassaScreenState extends State<KassaScreen> {
  final _c = TextEditingController();
  final _f = FocusNode();
  bool _busy = false;

  @override
  void dispose() {
    _c.dispose();
    _f.dispose();
    super.dispose();
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(text),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ));
  }

  void _add(Product p) {
    app.addToCart(p);
    _toast(p.stock <= 0 ? 'Qoldiq yo\'q, lekin qo\'shildi: ${p.name}' : 'Qo\'shildi: ${p.name}');
  }

  Future<void> _search(String raw) async {
    final text = raw.trim();
    if (text.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      final isCode = RegExp(r'^\d{6,}$').hasMatch(text);
      var list = await app.api!.products(
        barcode: isCode ? text : null,
        q: isCode ? null : text,
        warehouse: app.warehouseId,
        priceType: app.priceTypeId,
      );
      var byBarcode = isCode;
      if (list.isEmpty && isCode) {
        byBarcode = false;
        list = await app.api!.products(q: text, warehouse: app.warehouseId, priceType: app.priceTypeId);
      }
      if (!mounted) return;
      _c.clear();
      if (list.isEmpty) {
        _toast('Tovar topilmadi: $text');
      } else if (list.length == 1 && (byBarcode || text.length >= 3)) {
        _add(list.first);
      } else {
        await _pick(list);
      }
    } on ApiException catch (e) {
      if (mounted) _toast(e.message);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        _f.requestFocus();
      }
    }
  }

  Future<void> _pick(List<Product> list) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(sheet).size.height * 0.7),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (_, i) => ProductTile(
              product: list[i],
              onAdd: () {
                Navigator.pop(sheet);
                _add(list[i]);
              },
            ),
          ),
        ),
      ),
    );
  }

  void _pay() {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const PaymentScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kassa'),
        actions: [
          IconButton(
            tooltip: dark ? 'Kunduzgi rejim' : 'Tungi rejim',
            icon: Icon(dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            onPressed: () => app.setThemeMode(dark ? ThemeMode.light : ThemeMode.dark),
          ),
          ListenableBuilder(
            listenable: app,
            builder: (_, __) => app.cart.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: 'Savatni tozalash',
                    icon: const Icon(Icons.delete_sweep_outlined),
                    onPressed: () => app.clearCart(),
                  ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: TextField(
              controller: _c,
              focusNode: _f,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onSubmitted: _search,
              decoration: InputDecoration(
                hintText: 'Nomi yoki shtrix-kod (skaner)',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _busy
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : Icon(Icons.qr_code_scanner, color: scheme.primary),
              ),
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: app,
              builder: (context, _) {
                if (app.cart.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shopping_basket_outlined, size: 56, color: scheme.outline),
                        const SizedBox(height: 12),
                        Text('Savat bo\'sh', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text('Tovarni qidiring yoki skanerlang',
                            style: TextStyle(color: scheme.onSurfaceVariant)),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  itemCount: app.cart.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _CartTile(line: app.cart[i]),
                );
              },
            ),
          ),
          ListenableBuilder(
            listenable: app,
            builder: (context, _) => Container(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Jami · ${app.cart.length} ta',
                              style: TextStyle(fontSize: 15, color: scheme.onSurfaceVariant)),
                          Text('${money(app.total)} so\'m',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: app.cart.isEmpty ? null : _pay,
                          icon: const Icon(Icons.payments_outlined),
                          label: const Text('To\'lovga o\'tish'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Zakup narxi va foyda (faqat ruxsat berilgan foydalanuvchilar uchun).
class _CostRow extends StatelessWidget {
  final double? cost;
  final double price;
  const _CostRow({required this.cost, required this.price});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = cost;
    final on = scheme.onTertiaryContainer;
    final profit = c == null ? 0.0 : price - c;
    final pct = (c == null || c == 0) ? 0.0 : profit / c * 100;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: scheme.tertiaryContainer, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(Icons.lock_open_outlined, size: 18, color: on),
          const SizedBox(width: 10),
          Expanded(
            child: c == null
                ? Text('Zakup narxi topilmadi', style: TextStyle(color: on))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Zakup narxi: ${money(c)} so\'m',
                          style: TextStyle(fontWeight: FontWeight.w600, color: on)),
                      const SizedBox(height: 2),
                      Text(
                        'Foyda: ${profit >= 0 ? '+' : '−'}${money(profit.abs())} so\'m (${pct.toStringAsFixed(1)}%) har birida',
                        style: TextStyle(fontSize: 12, color: on),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// Savat qatori: tovar nomi to'liq kenglikda, pastda narx (bosib o'zgartiriladi),
/// miqdor boshqaruvi va qator summasi.
class _CartTile extends StatefulWidget {
  final CartLine line;
  const _CartTile({required this.line});

  @override
  State<_CartTile> createState() => _CartTileState();
}

class _CartTileState extends State<_CartTile> {
  CartLine get line => widget.line;
  bool _showCost = false;
  bool _loading = false;
  double? _cost;

  /// Chapga svayp: zakup narxini ko'rsatadi yoki yashiradi (faqat ruxsat berilganlarga).
  Future<void> _toggleCost() async {
    if (_showCost) {
      setState(() => _showCost = false);
      return;
    }
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final c = await app.costOf(line.product.id);
      if (!mounted) return;
      setState(() {
        _cost = c;
        _showCost = true;
      });
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(e.message), behavior: SnackBarBehavior.floating));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editPrice(BuildContext context) async {
    final v = await askNumber(
      context,
      title: 'Narxni o\'zgartirish',
      subtitle: line.product.name,
      initial: line.price,
      suffix: 'so\'m',
      original: line.product.price > 0 ? line.product.price : null,
    );
    if (v != null) app.setPrice(line, v);
  }

  Future<void> _editQty(BuildContext context) async {
    final v = await askNumber(
      context,
      title: 'Miqdor',
      subtitle: line.product.name,
      initial: line.qty,
      suffix: line.product.unit.isEmpty ? null : line.product.unit,
      allowDecimal: true,
    );
    if (v != null) app.setQty(line, v);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final changed = line.price != line.product.price;
    return Dismissible(
      key: ValueKey(line.product.id),
      direction: app.canSeeCost ? DismissDirection.horizontal : DismissDirection.startToEnd,
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.endToStart) {
          await _toggleCost();
          return false;
        }
        return true;
      },
      background: Container(
        decoration: BoxDecoration(color: scheme.errorContainer, borderRadius: BorderRadius.circular(16)),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
      ),
      secondaryBackground: Container(
        decoration: BoxDecoration(color: scheme.tertiaryContainer, borderRadius: BorderRadius.circular(16)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Zakup narxi',
                style: TextStyle(fontWeight: FontWeight.w600, color: scheme.onTertiaryContainer)),
            const SizedBox(width: 8),
            Icon(Icons.visibility_outlined, color: scheme.onTertiaryContainer),
          ],
        ),
      ),
      onDismissed: (_) => app.removeLine(line),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              line.product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.25),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                InkWell(
                  onTap: () => _editPrice(context),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: changed ? scheme.tertiaryContainer : scheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(money(line.price), style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(width: 6),
                        Icon(Icons.edit_outlined, size: 15, color: scheme.primary),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.remove),
                        onPressed: () => app.changeQty(line, -1),
                      ),
                      InkWell(
                        onTap: () => _editQty(context),
                        borderRadius: BorderRadius.circular(8),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 34),
                          child: Text(
                            qty(line.qty),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.add),
                        onPressed: () => app.changeQty(line, 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  changed ? 'Asl narx: ${money(line.product.price)}' : '',
                  style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                ),
                Text('${money(line.sum)} so\'m',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: scheme.primary)),
              ],
            ),
            if (_showCost) ...[
              const SizedBox(height: 10),
              _CostRow(cost: _cost, price: line.price),
            ],
          ],
        ),
      ),
    );
  }
}
