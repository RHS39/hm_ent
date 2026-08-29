import 'package:flutter/material.dart';
import 'admin_widgets.dart';
import '../../appwrite/product_repository.dart';
import '../../services/product_store.dart';

class ProductsSection extends StatefulWidget {
  const ProductsSection({
    super.key,
    required this.products,
    required this.isMobile,
    this.onProductTap,
  });

  final List<Map<String, dynamic>> products;
  final bool isMobile;
  final ValueChanged<Map<String, dynamic>>? onProductTap;

  @override
  State<ProductsSection> createState() => _ProductsSectionState();
}

class _ProductsSectionState extends State<ProductsSection> {
  String _prodSearch = '';
  String _prodCategoryFilter = 'all';
  bool _formBusy = false;
  late final VoidCallback _storeListener;

  @override
  void initState() {
    super.initState();
    _storeListener = () {
      if (mounted) setState(() {});
    };
    ProductStore.instance.addListener(_storeListener);
  }

  @override
  void dispose() {
    ProductStore.instance.removeListener(_storeListener);
    super.dispose();
  }

  // Single source of truth: prefer live store; fall back to prop if store empty (initial load race)
  List<Map<String, dynamic>> get _products {
    final store = ProductStore.instance.products;
    if (store.isNotEmpty) return store;
    return widget.products;
  }

  List<Map<String, dynamic>> get _filteredProducts {
    var list = List<Map<String, dynamic>>.from(_products);
    if (_prodCategoryFilter != 'all') {
      list = list.where((p) => (p['category'] ?? '') == _prodCategoryFilter).toList();
    }
    if (_prodSearch.isNotEmpty) {
      final q = _prodSearch.toLowerCase();
      list = list.where((p) =>
        (p['name'] ?? '').toString().toLowerCase().contains(q) ||
        (p['description'] ?? '').toString().toLowerCase().contains(q)
      ).toList();
    }
    return list;
  }

  String _nextProductId() {
    int maxId = 0;
    for (final p in _products) {
      final v = int.tryParse((p['product_id'] ?? '').toString().trim());
      if (v != null && v > maxId) maxId = v;
    }
    final next = maxId + 1;
    return next.toString().padLeft(2, '0');
  }

  void _showProductForm({Map<String, dynamic>? product}) {
    if (_formBusy) return;
    _formBusy = true;
    final isEdit = product != null;
    final nameCtrl = TextEditingController(text: product?['name'] ?? '');
    final priceCtrl = TextEditingController(text: product?['price']?.toString() ?? '');
    final descCtrl = TextEditingController(text: product?['description'] ?? '');
    final rawStock = product?['stock_quantity'] ?? product?['stock'];
    final stockVal = rawStock is int ? rawStock : int.tryParse(rawStock?.toString() ?? '') ?? 100;
    final stockCtrl = TextEditingController(text: stockVal.toString());
    final rawMoq = product?['moq'];
    final moqVal = rawMoq is int ? rawMoq : (rawMoq is double ? rawMoq.toInt() : int.tryParse(rawMoq?.toString() ?? '') ?? 2);
    final moqCtrl = TextEditingController(text: moqVal.toString());
    final productIdCtrl = TextEditingController(text: product?['product_id']?.toString() ?? '');
    final image1Ctrl = TextEditingController(text: (product?['image_url'] ?? product?['image'])?.toString() ?? '');
    final image2Ctrl = TextEditingController(text: product?['image_2']?.toString() ?? '');
    final image3Ctrl = TextEditingController(text: product?['image_3']?.toString() ?? '');
    String icon = (product?['icon']?.toString().trim().isNotEmpty ?? false) ? product!['icon'].toString() : 'spa';
    if (!allIconNames.contains(icon)) icon = 'spa';
    final rawCategory = (product?['category']?.toString().trim() ?? 'Other');
    String category = productCategories.contains(rawCategory) ? rawCategory : (rawCategory.toLowerCase() == 'jaggery' ? 'Other' : 'Other');
    if (!productCategories.contains(category)) category = 'Other';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(isEdit ? Icons.edit_rounded : Icons.add_rounded, size: 20, color: const Color(0xFF00C805)),
                    const SizedBox(width: 8),
                    Text(isEdit ? 'Edit Product' : 'Add Product', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: productIdCtrl,
                  decoration: _inputDec('Product ID (e.g. 01, 02)', Icons.tag_rounded),
                  keyboardType: TextInputType.number,
                  maxLength: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: _inputDec('Product name', Icons.inventory_2_rounded),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: priceCtrl,
                        decoration: _inputDec('Price (₹)', Icons.currency_rupee_rounded),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: stockCtrl,
                        decoration: _inputDec('Stock', Icons.store_rounded),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: moqCtrl,
                  decoration: InputDecoration(
                    hintText: 'MOQ (min order qty)',
                    prefixIcon: const Icon(Icons.shopping_cart_rounded, size: 18),
                    filled: true,
                    fillColor: const Color(0xFFFEF3C7),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFFDE68A))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFFDE68A))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFF59E0B), width: 1.4)),
                    suffixIcon: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(100)),
                      child: const Text('MOQ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFD97706))),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: _inputDec('Description', Icons.description_rounded),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: _inputDec('Category', Icons.category_rounded),
                  items: productCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setModalState(() => category = v ?? 'Other'),
                ),
                const SizedBox(height: 12),
                Text('Icon', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: allIconNames.map((name) {
                    final selected = icon == name;
                    return GestureDetector(
                      onTap: () => setModalState(() => icon = name),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: selected ? const Color(0xFFECFDF5) : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected ? const Color(0xFF00C805) : const Color(0xFFE5E7EB),
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Icon(iconFromName(name), size: 20, color: selected ? const Color(0xFF00C805) : const Color(0xFF6B7280)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Row(children: [
                  Text('Product Images', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                  const Spacer(),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(100)), child: const Text('3 uploads', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF2563EB)))),
                ]),
                const SizedBox(height: 8),
                ImageUrlField(controller: image1Ctrl, label: 'Image 1 (Primary)', hint: 'Image 1 URL or upload', setModalState: setModalState),
                const SizedBox(height: 8),
                ImageUrlField(controller: image2Ctrl, label: 'Image 2', hint: 'Image 2 URL or upload', setModalState: setModalState),
                const SizedBox(height: 8),
                ImageUrlField(controller: image3Ctrl, label: 'Image 3', hint: 'Image 3 URL or upload', setModalState: setModalState),
                const SizedBox(height: 20),
                Row(
                  children: [
                    if (isEdit)
                      OutlinedButton.icon(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: ctx,
                            builder: (d) => AlertDialog(
                              title: const Text('Delete Product'),
                              content: Text('Delete "${product['name']}"?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
                                TextButton(onPressed: () => Navigator.pop(d, true), child: const Text('Delete', style: TextStyle(color: Color(0xFFDC2626)))),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            final res = await ProductStore.instance.delete(product['id'].toString());
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(res.ok ? 'Product deleted' : res.message),
                                backgroundColor: res.ok ? const Color(0xFF00C805) : const Color(0xFFDC2626),
                              ));
                              setState(() {});
                            }
                          }
                        },
                        icon: const Icon(Icons.delete_rounded, size: 16),
                        label: const Text('Delete'),
                        style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFDC2626), side: const BorderSide(color: Color(0xFFDC2626))),
                      ),
                    const Spacer(),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed: () async {
                        final name = nameCtrl.text.trim();
                        final price = double.tryParse(priceCtrl.text.trim()) ?? 0;
                        final stock = int.tryParse(stockCtrl.text.trim()) ?? -1;
                        final desc = descCtrl.text.trim();
                        var pid = productIdCtrl.text.trim();
                        final img1 = image1Ctrl.text.trim();
                        final img2 = image2Ctrl.text.trim();
                        final img3 = image3Ctrl.text.trim();
                        if (name.isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Product name is required')));
                          return;
                        }
                        if (desc.isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Description is required')));
                          return;
                        }
                        if (price <= 0) {
                          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Valid price (>0) required')));
                          return;
                        }
                        if (stock < 0) {
                          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Stock must be >=0')));
                          return;
                        }
                        var moq = int.tryParse(moqCtrl.text.trim()) ?? 2;
                        if (moq < 1) moq = 1;
                        if (moq > 999) moq = 999;
                        if (pid.isEmpty) {
                          pid = isEdit ? (product['product_id']?.toString() ?? '00') : _nextProductId();
                        }
                        if (pid.length == 1) pid = pid.padLeft(2, '0');
                        final existingIds = _products.map((p) => p['product_id']?.toString()).toSet();
                        final originalPid = product?['product_id']?.toString() ?? '';
                        if (!isEdit && existingIds.contains(pid)) {
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Product ID "$pid" already exists — using next available')));
                          pid = _nextProductId();
                        } else if (isEdit && pid != originalPid && existingIds.contains(pid)) {
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Product ID "$pid" already in use')));
                          return;
                        }
                        bool ok;
                        String msg;
                        try {
                          if (isEdit) {
                            final res = await ProductStore.instance.update(
                                id: product['id'].toString(),
                                productId: pid,
                                name: name,
                                price: price,
                                description: desc,
                                icon: icon,
                                category: category,
                                stock: stock,
                                moq: moq,
                                image1: img1.isNotEmpty ? img1 : null,
                                image2: img2.isNotEmpty ? img2 : null,
                                image3: img3.isNotEmpty ? img3 : null);
                            ok = res.ok;
                            msg = res.message;
                          } else {
                            final res = await ProductStore.instance.create(
                                productId: pid,
                                name: name,
                                price: price,
                                description: desc,
                                icon: icon,
                                category: category,
                                stock: stock,
                                moq: moq,
                                image1: img1.isNotEmpty ? img1 : null,
                                image2: img2.isNotEmpty ? img2 : null,
                                image3: img3.isNotEmpty ? img3 : null);
                            ok = res.ok;
                            msg = res.message;
                          }
                        } catch (e) {
                          ok = false;
                          msg = e.toString();
                        }
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(ok ? (isEdit ? 'Product updated' : 'Product created') : 'Failed: $msg'),
                            backgroundColor: ok ? const Color(0xFF00C805) : const Color(0xFFDC2626),
                            behavior: SnackBarBehavior.floating,
                          ));
                          if (ok && mounted) setState(() {});
                        }
                      },
                      icon: Icon(isEdit ? Icons.check_rounded : Icons.add_rounded, size: 16),
                      label: Text(isEdit ? 'Update' : 'Create'),
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFF00C805)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).whenComplete(() { _formBusy = false; });
  }

  InputDecoration _inputDec(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 18),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF00C805), width: 1.4)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredProducts;
    final categories = ['all', ...{..._products.map((p) => (p['category'] ?? '').toString())}.toList()..sort()];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.inventory_2_rounded, size: 20, color: Color(0xFF00C805)),
            const SizedBox(width: 8),
            Flexible(
              child: Text('Products (${_products.length})', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0B0E0F))),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => _showProductForm(),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add Product', style: TextStyle(fontSize: 12)),
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF00C805), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: categories.map((cat) {
              final selected = _prodCategoryFilter == cat;
              final count = cat == 'all' ? _products.length : _products.where((p) => (p['category'] ?? '') == cat).length;
              final label = cat == 'all' ? 'All' : cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text('$label ($count)', style: TextStyle(fontSize: 12, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: selected ? Colors.white : const Color(0xFF374151))),
                  selected: selected,
                  onSelected: (_) => setState(() => _prodCategoryFilter = cat),
                  selectedColor: const Color(0xFF00C805),
                  backgroundColor: Colors.white,
                  side: BorderSide(color: selected ? const Color(0xFF00C805) : const Color(0xFFE5E7EB)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          onChanged: (v) => setState(() => _prodSearch = v),
          decoration: InputDecoration(
            hintText: 'Search products...',
            prefixIcon: const Icon(Icons.search_rounded, size: 18),
            suffixIcon: _prodSearch.isNotEmpty
              ? IconButton(icon: const Icon(Icons.close_rounded, size: 16), onPressed: () => setState(() => _prodSearch = ''))
              : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF00C805), width: 1.4)),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Showing ${filtered.length} of ${_products.length} products',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 10),
        if (filtered.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE5E7EB))),
            child: Column(
              children: [
                Icon(Icons.inventory_2_rounded, size: 40, color: Colors.grey.shade300),
                const SizedBox(height: 10),
                Text(_products.isEmpty ? 'No products yet. Add your first product!' : 'No products match your search', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                if (_products.isEmpty) ...[
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _showProductForm(),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Add Product'),
                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFF00C805)),
                  ),
                ],
              ],
            ),
          )
        else if (widget.isMobile)
          ...filtered.map((p) => ProductCard(product: p, onEdit: () => _showProductForm(product: p)))
        else
          AdminDataTable(
            columns: const ['#', 'ID', 'Name', 'Category', 'Price', 'Stock', 'Description', 'Image', ''],
            rows: filtered.asMap().entries.map((entry) {
              final i = entry.key + 1;
              final p = entry.value;
              final desc = (p['description'] ?? '').toString();
              final stockVal = (p['stock_quantity'] ?? 0).toString();
              final img = (p['image_url'] ?? p['image'] ?? '').toString();
              return [
                '$i',
                (p['product_id'] ?? '').toString(),
                (p['name'] ?? '').toString(),
                (p['category'] ?? '').toString(),
                '₹${p['price'] ?? 0}',
                stockVal,
                desc.length > 40 ? '${desc.substring(0, 40)}...' : desc,
                img.isEmpty ? '—' : (img.length > 30 ? '${img.substring(0, 30)}...' : img),
                'EDIT',
              ];
            }).toList(),
            emptyMessage: 'No products match',
            actionColumnIndex: 8,
            onRowTap: (rowIndex) => _showProductForm(product: filtered[rowIndex]),
          ),
      ],
    );
  }
}
