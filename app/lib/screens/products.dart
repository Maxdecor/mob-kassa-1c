import 'package:flutter/material.dart';

import '../models.dart';
import '../state.dart';
import '../widgets.dart';

/// Tovar qatori (kassadagi qidiruv natijalarida): nom to'liq kenglikda,
/// pastda shtrix-kod, narx va qoldiq.
class ProductTile extends StatelessWidget {
  final Product product;
  final VoidCallback onAdd;

  const ProductTile({super.key, required this.product, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final inStock = product.stock > 0;
    final sub = [
      if (product.barcode.isNotEmpty) product.barcode,
      if (product.article.isNotEmpty) 'Art: ${product.article}',
    ].join('  ·  ');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.25),
                ),
                if (sub.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(sub, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('${money(product.price)} so\'m',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: scheme.primary)),
                    const SizedBox(width: 10),
                    StatusChip(
                      label: 'Qoldiq: ${qty(product.stock)}',
                      kind: inStock ? ChipKind.ok : ChipKind.bad,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            onPressed: onAdd,
            icon: const Icon(Icons.add_shopping_cart),
            tooltip: 'Savatga',
          ),
        ],
      ),
    );
  }
}
