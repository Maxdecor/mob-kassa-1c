import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../state.dart';

/// Top sotuvchilar: eng ko'p sotilgan tovarlar va eng yaxshi sotuvchilar (summa bilan).
class TopScreen extends StatefulWidget {
  const TopScreen({super.key});

  @override
  State<TopScreen> createState() => TopScreenState();
}

class TopScreenState extends State<TopScreen> {
  int _days = 0;
  int _tab = 0;
  TopData? _data;
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
      final data = await app.api!.top(from, now);
      if (mounted) setState(() => _data = data);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final data = _data;
    final items = data == null ? const <TopItem>[] : (_tab == 0 ? data.goods : data.sellers);
    final maxSum = items.isEmpty ? 1.0 : items.map((e) => e.sum).reduce((a, b) => a > b ? a : b);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Top sotuvchilar'),
        actions: [IconButton(onPressed: reload, icon: const Icon(Icons.refresh))],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Align(
              alignment: Alignment.centerLeft,
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
          ),
          if (_busy) const LinearProgressIndicator(minHeight: 2),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(_error!, style: TextStyle(color: scheme.error)),
            ),
          Expanded(
            child: data == null
                ? const SizedBox.shrink()
                : ListView(
                    padding: const EdgeInsets.only(bottom: 12),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                        child: _Summary(data: data),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: SegmentedButton<int>(
                          showSelectedIcon: false,
                          segments: const [
                            ButtonSegment(
                                value: 0, icon: Icon(Icons.inventory_2_outlined), label: Text('Tovarlar')),
                            ButtonSegment(value: 1, icon: Icon(Icons.person_outline), label: Text('Sotuvchilar')),
                          ],
                          selected: {_tab},
                          onSelectionChanged: (s) => setState(() => _tab = s.first),
                        ),
                      ),
                      if (items.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Text(
                              _tab == 1 ? 'Sotuvchilar ma\'lumoti yo\'q' : 'Bu davrda sotuv yo\'q',
                              style: TextStyle(color: scheme.onSurfaceVariant),
                            ),
                          ),
                        ),
                      for (var i = 0; i < items.length; i++) ...[
                        if (i > 0) const Divider(),
                        _TopRow(
                          rank: i + 1,
                          item: items[i],
                          sub: _tab == 0
                              ? '${qty(items[i].quantity)} ${items[i].unit}'.trim()
                              : '${items[i].receipts} ta chek',
                          share: maxSum <= 0 ? 0 : items[i].sum / maxSum,
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  final TopData data;
  const _Summary({required this.data});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final on = scheme.onPrimaryContainer;
    Widget metric(String label, String value) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: on)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: on)),
          ],
        );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Jami savdo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: on)),
          const SizedBox(height: 6),
          Text('${money(data.total)} so\'m',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: on)),
          const SizedBox(height: 12),
          Row(
            children: [
              metric('Cheklar', '${data.receipts} ta'),
              const SizedBox(width: 28),
              metric('O\'rtacha chek', '${money(data.average)} so\'m'),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopRow extends StatelessWidget {
  final int rank;
  final TopItem item;
  final String sub;
  final double share;

  const _TopRow({required this.rank, required this.item, required this.sub, required this.share});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final top3 = rank <= 3;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: top3 ? scheme.primaryContainer : scheme.surfaceContainerHigh,
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: top3 ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(sub, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: share.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: scheme.surfaceContainerHigh,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(money(item.sum), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
