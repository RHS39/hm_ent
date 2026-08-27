import 'package:flutter/material.dart';

class CatalogFilterResult {
  CatalogFilterResult({this.minPrice, this.maxPrice, this.inStock, this.minRating, this.category});
  final double? minPrice;
  final double? maxPrice;
  final bool? inStock;
  final double? minRating;
  final String? category;
}

class FilterModal extends StatefulWidget {
  const FilterModal({super.key, this.initialCategory = 'All', this.initialMinPrice, this.initialMaxPrice, this.initialInStock, this.initialMinRating});
  final String initialCategory;
  final double? initialMinPrice;
  final double? initialMaxPrice;
  final bool? initialInStock;
  final double? initialMinRating;
  @override
  State<FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends State<FilterModal> {
  late String _cat;
  RangeValues _price = const RangeValues(0, 1000);
  bool _inStock = false;
  double _rating = 0;

  static const _cats = ['All', 'Pouches', 'Chikki', 'Syrup & Kakvi', 'Blocks', 'Spiced', 'Gifting'];

  @override
  void initState() {
    super.initState();
    _cat = widget.initialCategory;
    if (widget.initialMinPrice != null || widget.initialMaxPrice != null) {
      _price = RangeValues(widget.initialMinPrice ?? 0, widget.initialMaxPrice ?? 1000);
    }
    _inStock = widget.initialInStock ?? false;
    _rating = widget.initialMinRating ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(color: isDark ? const Color(0xFF14181B) : Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(100)))),
          const SizedBox(height: 12),
          Row(children: [Text('Filters', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)), const Spacer(), TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))]),
          const Divider(),
          Text('Category', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: _cats.map((c) => ChoiceChip(label: Text(c), selected: _cat == c, onSelected: (_) => setState(() => _cat = c), selectedColor: const Color(0xFF0B0E0F), labelStyle: TextStyle(color: _cat == c ? Colors.white : null, fontWeight: FontWeight.w600))).toList()),
          const SizedBox(height: 16),
          Text('Price range: ₹${_price.start.round()} - ₹${_price.end.round()}', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
          RangeSlider(values: _price, min: 0, max: 1000, divisions: 20, activeColor: const Color(0xFF00C805), onChanged: (v) => setState(() => _price = v)),
          const SizedBox(height: 8),
          SwitchListTile(value: _inStock, onChanged: (v) => setState(() => _inStock = v), title: const Text('In-stock only', style: TextStyle(fontWeight: FontWeight.w600)), activeColor: const Color(0xFF00C805)),
          const SizedBox(height: 8),
          Text('Minimum rating: ${_rating == 0 ? 'Any' : _rating.toString()} ★', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
          Slider(value: _rating, min: 0, max: 5, divisions: 5, label: _rating.toString(), activeColor: const Color(0xFF00C805), onChanged: (v) => setState(() => _rating = v)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context, null), child: const Text('Clear'))),
            const SizedBox(width: 12),
            Expanded(child: FilledButton(onPressed: () => Navigator.pop(context, CatalogFilterResult(minPrice: _price.start == 0 ? null : _price.start, maxPrice: _price.end == 1000 ? null : _price.end, inStock: _inStock ? true : null, minRating: _rating == 0 ? null : _rating, category: _cat)), style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0B0E0F)), child: const Text('Apply'))),
          ]),
        ]),
      ),
    );
  }
}
