import 'package:flutter/material.dart';

import 'state.dart';

enum ChipKind { ok, warn, bad }

/// Holat belgisi (qoldiq, otlojenniy va h.k.). Kunduzgi va tungi rejimga moslashadi.
class StatusChip extends StatelessWidget {
  final String label;
  final ChipKind kind;

  const StatusChip({super.key, required this.label, required this.kind});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    late final Color bg;
    late final Color fg;
    switch (kind) {
      case ChipKind.ok:
        bg = dark ? const Color(0xFF1B3A2A) : const Color(0xFFE3F5EA);
        fg = dark ? const Color(0xFF7FD6A0) : const Color(0xFF16643A);
      case ChipKind.warn:
        bg = dark ? const Color(0xFF3E3216) : const Color(0xFFFFF3D6);
        fg = dark ? const Color(0xFFF2C766) : const Color(0xFF7A5200);
      case ChipKind.bad:
        bg = dark ? const Color(0xFF4A1F1F) : const Color(0xFFFDE7E7);
        fg = dark ? const Color(0xFFFF9C9C) : const Color(0xFF9B1C1C);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}

/// Narx yoki miqdor kiritish oynasi (pastdan ochiladi, o'zining raqam paneli bor).
/// [original] berilsa asl narx bilan farq va tezkor chegirma tugmalari ko'rsatiladi.
/// Bekor qilinsa null qaytadi.
Future<double?> askNumber(
  BuildContext context, {
  required String title,
  String? subtitle,
  required double initial,
  String? suffix,
  double? original,
  bool allowDecimal = false,
}) {
  return showModalBottomSheet<double>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _NumberSheet(
      title: title,
      subtitle: subtitle,
      initial: initial,
      suffix: suffix,
      original: original,
      allowDecimal: allowDecimal,
    ),
  );
}

class _NumberSheet extends StatefulWidget {
  final String title;
  final String? subtitle;
  final double initial;
  final String? suffix;
  final double? original;
  final bool allowDecimal;

  const _NumberSheet({
    required this.title,
    required this.subtitle,
    required this.initial,
    required this.suffix,
    required this.original,
    required this.allowDecimal,
  });

  @override
  State<_NumberSheet> createState() => _NumberSheetState();
}

class _NumberSheetState extends State<_NumberSheet> {
  late String _text = qty(widget.initial).replaceAll('.', ',');
  bool _fresh = true;

  double get _value => double.tryParse(_text.replaceAll(',', '.')) ?? 0;

  void _press(String k) {
    setState(() {
      if (k == '⌫') {
        _text = (_fresh || _text.isEmpty) ? '' : _text.substring(0, _text.length - 1);
        _fresh = false;
        return;
      }
      if (_fresh) {
        _text = '';
        _fresh = false;
      }
      if (k == ',') {
        if (_text.contains(',')) return;
        _text = _text.isEmpty ? '0,' : '$_text,';
        return;
      }
      if (_text.length >= 12) return;
      final dot = _text.indexOf(',');
      if (dot >= 0 && _text.length - dot > 3) return;
      if (_text == '0') _text = '';
      if (_text.isEmpty && (k == '0' || k == '00')) {
        _text = '0';
        return;
      }
      _text += k;
    });
  }

  void _setValue(double v) {
    setState(() {
      _text = qty(v.roundToDouble()).replaceAll('.', ',');
      _fresh = true;
    });
  }

  String _grouped(String t) {
    if (t.isEmpty) return '0';
    final parts = t.split(',');
    final head = parts[0].replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ' ');
    return parts.length > 1 ? '$head,${parts[1]}' : head;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final o = widget.original;
    final v = _value;
    final diff = o == null ? 0.0 : v - o;
    final pct = (o == null || o == 0) ? 0.0 : diff / o * 100;
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      [widget.allowDecimal ? ',' : '00', '0', '⌫'],
    ];

    Widget key(String k) => Expanded(
          child: Material(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _press(k),
              child: SizedBox(
                height: 52,
                child: Center(
                  child: k == '⌫'
                      ? Icon(Icons.backspace_outlined, color: scheme.onSurface)
                      : Text(k, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ),
        );

    Widget quick(String label, double value) {
      final selected = (v - value).abs() < 0.5;
      return Expanded(
        child: Material(
          color: selected ? scheme.primaryContainer : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: selected ? BorderSide.none : BorderSide(color: scheme.outlineVariant),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _setValue(value),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            if (widget.subtitle != null) ...[
              const SizedBox(height: 4),
              Text(widget.subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant)),
            ],
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: scheme.primary, width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(_grouped(_text),
                          style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  if (widget.suffix != null) ...[
                    const SizedBox(width: 8),
                    Text(widget.suffix!,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: scheme.onSurfaceVariant)),
                  ],
                ],
              ),
            ),
            if (o != null) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Asl narx: ${money(o)} so\'m',
                      style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
                  if (diff.abs() >= 0.5)
                    StatusChip(
                      label:
                          '${diff > 0 ? '+' : '−'}${money(diff.abs())} so\'m (${diff > 0 ? '+' : '−'}${pct.abs().toStringAsFixed(1)}%)',
                      kind: diff > 0 ? ChipKind.warn : ChipKind.ok,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  quick('Asl narx', o),
                  const SizedBox(width: 8),
                  quick('−5%', o * 0.95),
                  const SizedBox(width: 8),
                  quick('−10%', o * 0.90),
                  const SizedBox(width: 8),
                  quick('−20%', o * 0.80),
                ],
              ),
            ],
            const SizedBox(height: 14),
            for (final row in keys) ...[
              Row(
                children: [
                  for (var i = 0; i < row.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    key(row[i]),
                  ],
                ],
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 6),
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
                    onPressed: v > 0 ? () => Navigator.pop(context, v) : null,
                    icon: const Icon(Icons.check),
                    label: const Text('Saqlash'),
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
