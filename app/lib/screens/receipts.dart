import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../api.dart';
import '../models.dart';
import '../state.dart';
import '../widgets.dart';

final _dateFmt = DateFormat('dd.MM.yyyy HH:mm');

/// Cheklar ro'yxati. Chekni bosganda ichidagi tovarlar ochiladi.
class ReceiptsScreen extends StatefulWidget {
  const ReceiptsScreen({super.key});

  @override
  State<ReceiptsScreen> createState() => ReceiptsScreenState();
}

class ReceiptsScreenState extends State<ReceiptsScreen> {
  int _days = 0;
  List<ReceiptSummary> _items = const [];
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final now = DateTime.now();
      final from = DateTime(now.year, now.month, now.day).subtract(Duration(days: _days));
      final list = await app.api!.receipts(from, now);
      if (mounted) setState(() => _items = list);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _open(ReceiptSummary r) async {
    final changed = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => ReceiptDetailScreen(summary: r)));
    if (changed == true) reload();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cheklar'),
        actions: [IconButton(onPressed: reload, icon: const Icon(Icons.refresh))],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Wrap(
              spacing: 8,
              children: [
                for (final e in const {0: 'Bugun', 6: '7 kun', 29: '30 kun'}.entries)
                  ChoiceChip(
                    label: Text(e.value),
                    selected: _days == e.key,
                    onSelected: (_) {
                      setState(() => _days = e.key);
                      reload();
                    },
                  ),
              ],
            ),
          ),
          if (_busy) const LinearProgressIndicator(minHeight: 2),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(_error!, style: TextStyle(color: scheme.error)),
            ),
          Expanded(
            child: _items.isEmpty && !_busy
                ? const Center(child: Text('Cheklar yo\'q'))
                : ListView.separated(
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final r = _items[i];
                      return ListTile(
                        onTap: () => _open(r),
                        title: Text('Chek №${r.number}'),
                        subtitle: Text(
                            '${r.date == null ? '' : _dateFmt.format(r.date!)}  ·  ${r.items} ta pozitsiya'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${money(r.total)} so\'m', style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            StatusChip(
                              label: r.deferred ? 'Otlojenniy' : 'Urilgan',
                              kind: r.deferred ? ChipKind.warn : ChipKind.ok,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Qaytarish oynasi: qaysi tovardan nechta qaytariladi (chek ichidan tanlanadi).
class _ReturnSheet extends StatefulWidget {
  final ReceiptDetail detail;
  const _ReturnSheet({required this.detail});

  @override
  State<_ReturnSheet> createState() => _ReturnSheetState();
}

class _ReturnSheetState extends State<_ReturnSheet> {
  late final Map<int, double> _qty = {for (final l in widget.detail.lines) l.number: l.quantity};
  late final Set<int> _on = {for (final l in widget.detail.lines) l.number};

  double get _total => widget.detail.lines
      .where((l) => _on.contains(l.number))
      .fold(0.0, (s, l) => s + _qty[l.number]! * l.price);

  void _step(ReceiptLine l, double delta) {
    final lo = l.quantity < 1 ? l.quantity : 1.0;
    final next = (_qty[l.number]! + delta).clamp(lo, l.quantity).toDouble();
    setState(() => _qty[l.number] = next);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final d = widget.detail;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Qaytariladigan tovarlar', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Chek №${d.number}', style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.45),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: d.lines.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (_, i) {
                  final l = d.lines[i];
                  final on = _on.contains(l.number);
                  return Row(
                    children: [
                      Checkbox(
                        value: on,
                        onChanged: (v) => setState(() => v == true ? _on.add(l.number) : _on.remove(l.number)),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text('${money(l.price)} so\'m · sotilgan: ${qty(l.quantity)} ${l.unit}'.trim(),
                                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.remove),
                        onPressed: on ? () => _step(l, -1) : null,
                      ),
                      SizedBox(
                        width: 36,
                        child: Text(qty(_qty[l.number]!),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.add),
                        onPressed: on ? () => _step(l, 1) : null,
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Qaytariladigan summa', style: TextStyle(color: scheme.onSurfaceVariant)),
                Text('${money(_total)} so\'m', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Bekor qilish'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _on.isEmpty
                        ? null
                        : () => Navigator.pop(context, [
                              for (final l in d.lines)
                                if (_on.contains(l.number)) (number: l.number, quantity: _qty[l.number]!),
                            ]),
                    icon: const Icon(Icons.undo),
                    label: const Text('Qaytarish'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ReceiptDetailScreen extends StatefulWidget {
  final ReceiptSummary summary;
  const ReceiptDetailScreen({super.key, required this.summary});

  @override
  State<ReceiptDetailScreen> createState() => _ReceiptDetailScreenState();
}

class _ReceiptDetailScreenState extends State<ReceiptDetailScreen> {
  ReceiptDetail? _detail;
  String? _error;
  bool _busy = false;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await app.api!.receipt(widget.summary.id);
      if (mounted) setState(() => _detail = d);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _return(ReceiptDetail d) async {
    final picked = await showModalBottomSheet<List<({int number, double quantity})>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ReturnSheet(detail: d),
    );
    if (picked == null || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final original = {for (final l in d.lines) l.number: l.quantity};
      final isFull = picked.length == d.lines.length && picked.every((p) => original[p.number] == p.quantity);
      final res = await app.api!.returnReceipt(
        widget.summary.id,
        isFull ? const <({int number, double quantity})>[] : picked,
      );
      _changed = true;
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text('Qaytarish №${res['number']} bajarildi'),
          behavior: SnackBarBehavior.floating,
        ));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _post() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await app.api!.postReceipt(widget.summary.id);
      _changed = true;
      await _load();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _detail;
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: Scaffold(
        appBar: AppBar(title: Text('Chek №${widget.summary.number}')),
        body: d == null
            ? Center(
                child: _error != null
                    ? Text(_error!, style: TextStyle(color: theme.colorScheme.error))
                    : const CircularProgressIndicator())
            : Column(
                children: [
                  ListTile(
                    title: Text(d.date == null ? '' : _dateFmt.format(d.date!)),
                    trailing: Text(d.deferred ? 'Otlojenniy' : 'Urilgan',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.separated(
                      itemCount: d.lines.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final l = d.lines[i];
                        return ListTile(
                          title: Text(l.name),
                          subtitle: Text('${qty(l.quantity)} ${l.unit} × ${money(l.price)}'),
                          trailing: Text(money(l.sum), style: const TextStyle(fontWeight: FontWeight.w600)),
                        );
                      },
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Jami (${d.lines.length} ta pozitsiya)', style: theme.textTheme.titleMedium),
                              Text('${money(d.total)} so\'m', style: theme.textTheme.titleLarge),
                            ],
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 8),
                            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
                          ],
                          if (d.deferred) ...[
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: _busy ? null : _post,
                                child: const Padding(padding: EdgeInsets.all(6), child: Text('Chekni urish')),
                              ),
                            ),
                          ],
                          if (d.posted) ...[
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _busy ? null : () => _return(d),
                                icon: const Icon(Icons.undo),
                                label: const Text('Qaytarish (vozvrat)'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
