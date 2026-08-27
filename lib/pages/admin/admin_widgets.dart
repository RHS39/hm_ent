import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../appwrite/product_repository.dart';

class Nav {
  const Nav({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

class Sidebar extends StatefulWidget {
  const Sidebar({required this.section, required this.onSelect});
  final int section;
  final ValueChanged<int> onSelect;

  @override
  State<Sidebar> createState() => SidebarState();
}

class SidebarState extends State<Sidebar> {
  bool _hovered = false;

  static const _items = [
    Nav(icon: Icons.dashboard_rounded, label: 'Overview'),
    Nav(icon: Icons.mail_rounded, label: 'Messages'),
    Nav(icon: Icons.inventory_2_rounded, label: 'Products'),
    Nav(icon: Icons.how_to_reg_rounded, label: 'Subscribers'),
    Nav(icon: Icons.group_rounded, label: 'Users'),
  ];

  static const double _collapsedWidth = 72;
  static const double _expandedWidth = 240;

  @override
  Widget build(BuildContext context) {
    final bool expanded = _hovered;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        width: expanded ? _expandedWidth : _collapsedWidth,
        decoration: BoxDecoration(
          color: const Color(0xFF0B0E0F),
          boxShadow: expanded
              ? [BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 16, offset: const Offset(4, 0))]
              : null,
        ),
        child: Column(
          children: [
            Container(
              height: 60,
              padding: EdgeInsets.symmetric(horizontal: expanded ? 20 : 0),
              alignment: expanded ? Alignment.centerLeft : Alignment.center,
              child: Row(
                mainAxisAlignment: expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                children: [
                  const Icon(Icons.spa_rounded, color: Color(0xFF00C805), size: 24),
                  if (expanded) ...[
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text('Hari Om Traders',
                          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ],
              ),
            ),
            Divider(height: 1, color: Colors.white.withOpacity(0.1)),
            const SizedBox(height: 12),
            ...List.generate(_items.length, (i) {
              final item = _items[i];
              final selected = widget.section == i;
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: expanded ? 12 : 8, vertical: 2),
                child: Tooltip(
                  message: expanded ? '' : item.label,
                  waitDuration: const Duration(milliseconds: 400),
                  child: Material(
                    color: selected ? const Color(0xFF00C805).withOpacity(0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: () => widget.onSelect(i),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: expanded ? 14 : 12, vertical: 11),
                        child: Row(
                          mainAxisAlignment: expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                          children: [
                            Icon(item.icon, size: 20, color: selected ? const Color(0xFF00C805) : Colors.white54),
                            if (expanded) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 180),
                                  opacity: expanded ? 1 : 0,
                                  child: Text(item.label,
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                          color: selected ? const Color(0xFF00C805) : Colors.white70),
                                      overflow: TextOverflow.ellipsis),
                                ),
                              ),
                            ],
                            if (expanded && selected)
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(color: Color(0xFF00C805), shape: BoxShape.circle),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
            const Spacer(),
            Divider(height: 1, color: Colors.white.withOpacity(0.1)),
            Padding(
              padding: EdgeInsets.all(expanded ? 12 : 8),
              child: Tooltip(
                message: expanded ? '' : 'Back to Store',
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: () => context.go('/'),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: expanded ? 14 : 12, vertical: 11),
                      child: Row(
                        mainAxisAlignment: expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.storefront_rounded, size: 20, color: Colors.white54),
                          if (expanded) ...[
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text('Back to Store',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white54),
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (expanded) const SizedBox(height: 4),
            if (!expanded)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Icon(Icons.chevron_right_rounded, size: 14, color: Colors.white.withOpacity(0.35)),
              ),
          ],
        ),
      ),
    );
  }
}

class ImageUrlField extends StatefulWidget {
  const ImageUrlField({required this.controller, required this.label, required this.hint, required this.setModalState});
  final TextEditingController controller;
  final String label;
  final String hint;
  final StateSetter setModalState;
  @override
  State<ImageUrlField> createState() => ImageUrlFieldState();
}

class ImageUrlFieldState extends State<ImageUrlField> {
  bool _uploading = false;
  static const _allowedExts = ['jpg', 'jpeg', 'png', 'webp', 'gif'];
  Future<void> _pick() async {
    try {
      final res = await FilePicker.platform.pickFiles(type: FileType.image, withData: true, allowMultiple: false);
      if (res == null || res.files.isEmpty) return;
      final file = res.files.first;
      final bytes = file.bytes;
      final name = file.name;
      final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
      if (ext.isNotEmpty && !_allowedExts.contains(ext)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unsupported type .$ext'), backgroundColor: const Color(0xFFDC2626)));
        return;
      }
      if (bytes == null || bytes.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not read file'), backgroundColor: Color(0xFFDC2626)));
        return;
      }
      if (bytes.lengthInBytes > 5 * 1024 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image must be < 5MB (got ${(bytes.lengthInBytes / 1024 / 1024).toStringAsFixed(1)}MB)'), backgroundColor: const Color(0xFFDC2626)));
        return;
      }
      setState(() => _uploading = true);
      widget.setModalState(() => _uploading = true);
      try {
        final url = await AppwriteProductRepository.uploadProductImage(bytes, name);
        widget.controller.text = url;
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image uploaded'), backgroundColor: Color(0xFF00C805)));
      } catch (e) {
        final msg = e.toString().toLowerCase();
        if (msg.contains('bucket') && (msg.contains('not found') || msg.contains('does not exist'))) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Storage bucket not ready — check Appwrite bucket'), backgroundColor: Color(0xFFF59E0B)));
        } else {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e'), backgroundColor: const Color(0xFFDC2626)));
        }
      } finally {
        if (mounted) setState(() => _uploading = false);
        widget.setModalState(() {});
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Picker failed: $e'), backgroundColor: const Color(0xFFDC2626)));
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: widget.controller,
            decoration: InputDecoration(
              hintText: widget.hint,
              labelText: widget.label,
              prefixIcon: const Icon(Icons.image_rounded, size: 18),
              suffixIcon: widget.controller.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear_rounded, size: 16), onPressed: () { widget.controller.clear(); widget.setModalState(() {}); setState(() {}); }) : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF00C805), width: 1.4)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _uploading
            ? const SizedBox(width: 36, height: 36, child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00C805))))
            : Container(
                decoration: BoxDecoration(color: const Color(0xFF0B0E0F), borderRadius: BorderRadius.circular(10)),
                child: IconButton(
                  tooltip: 'Upload image',
                  icon: const Icon(Icons.cloud_upload_rounded, size: 18, color: Colors.white),
                  onPressed: _pick,
                ),
              ),
      ],
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({required this.label, required this.value, required this.icon, required this.color, required this.bg});
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
              const SizedBox(height: 2),
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
            ],
          ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({required this.title, required this.action, required this.onTap});
  final String title;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0B0E0F))),
        const Spacer(),
        TextButton(
          onPressed: onTap,
          child: Text(action, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF00C805))),
        ),
      ],
    );
  }
}

class AdminDataTable extends StatefulWidget {
  const AdminDataTable({required this.columns, required this.rows, required this.emptyMessage, this.statusColumnIndex, this.actionColumnIndex, this.onRowTap});
  final List<String> columns;
  final List<List<String>> rows;
  final String emptyMessage;
  final int? statusColumnIndex;
  final int? actionColumnIndex;
  final ValueChanged<int>? onRowTap;

  @override
  State<AdminDataTable> createState() => AdminDataTableState();
}

class AdminDataTableState extends State<AdminDataTable> {
  final ScrollController _horizontalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active': return const Color(0xFF059669);
      case 'pending': return const Color(0xFFD97706);
      case 'unsubscribed': return const Color(0xFF6B7280);
      case 'bounced': return const Color(0xFFDC2626);
      case 'complained': return const Color(0xFF7C3AED);
      default: return const Color(0xFF6B7280);
    }
  }

  Color _statusBg(String status) {
    switch (status.toLowerCase()) {
      case 'active': return const Color(0xFFECFDF5);
      case 'pending': return const Color(0xFFFFFBEB);
      case 'unsubscribed': return const Color(0xFFF9FAFB);
      case 'bounced': return const Color(0xFFFEF2F2);
      case 'complained': return const Color(0xFFF5F3FF);
      default: return const Color(0xFFF9FAFB);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.rows.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          children: [
            Icon(Icons.inbox_rounded, size: 40, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            Text(widget.emptyMessage, style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Scrollbar(
            controller: _horizontalController,
            thumbVisibility: true,
            trackVisibility: true,
            thickness: 10,
            radius: const Radius.circular(8),
            interactive: true,
            notificationPredicate: (notif) => notif.metrics.axis == Axis.horizontal,
            child: SingleChildScrollView(
              controller: _horizontalController,
              scrollDirection: Axis.horizontal,
              child: DataTable(
            columns: widget.columns
                .map((c) => DataColumn(
                      label: Text(c.isEmpty ? ' ' : c, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF6B7280))),
                    ))
                .toList(),
            rows: widget.rows
                .asMap()
                .entries
                .map((entry) {
                  final rowIndex = entry.key;
                  final row = entry.value;
                  return DataRow(
                    onSelectChanged: widget.onRowTap != null ? (_) => widget.onRowTap!(rowIndex) : null,
                    cells: row.asMap().entries.map((cellEntry) {
                      final cell = cellEntry.value;
                      final idx = cellEntry.key;
                      final isStatusCol = widget.statusColumnIndex != null && idx == widget.statusColumnIndex;
                      final isActionCol = widget.actionColumnIndex != null && idx == widget.actionColumnIndex;
                    if (isStatusCol) {
                      return DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _statusBg(cell),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            cell,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _statusColor(cell)),
                          ),
                        ),
                      );
                    }
                    if (isActionCol) {
                      return DataCell(
                        InkWell(
                          onTap: widget.onRowTap != null ? () => widget.onRowTap!(rowIndex) : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00C805),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('Edit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                          ),
                        ),
                      );
                    }
                    return DataCell(
                      Text(cell, style: const TextStyle(fontSize: 13, color: Color(0xFF0B0E0F))),
                    );
                  }).toList(),
                );
              })
              .toList(),
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF9FAFB)),
          dataRowColor: WidgetStateProperty.all(Colors.white),
          border: TableBorder(
            horizontalInside: BorderSide(color: Colors.grey.shade100),
          ),
          horizontalMargin: 16,
          columnSpacing: 24,
        ),
        ),
       ),
       ),
        const SizedBox(height: 6),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.swipe_rounded, size: 14, color: Color(0xFF9CA3AF)),
            SizedBox(width: 4),
            Text('← Scroll horizontally to see all columns →', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }
}

class ProductCard extends StatelessWidget {
  const ProductCard({required this.product, required this.onEdit});
  final Map<String, dynamic> product;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final productId = (product['product_id'] ?? '').toString();
    final name = (product['name'] ?? '').toString();
    final category = (product['category'] ?? '').toString();
    final price = product['price'] ?? 0;
    final stock = product['stock_quantity'] ?? 0;
    final icon = (product['icon'] ?? 'spa').toString();
    final desc = (product['description'] ?? '').toString();
    final img1 = (product['image_url'] ?? '').toString();

    return GestureDetector(
      onTap: onEdit,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(iconFromName(icon), size: 22, color: const Color(0xFF00C805)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (productId.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(4)),
                              child: Text('#$productId', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF2563EB))),
                            ),
                          if (productId.isNotEmpty) const SizedBox(width: 6),
                          Expanded(child: Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0B0E0F)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(100)),
                            child: Text(category, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF059669))),
                          ),
                          const SizedBox(width: 8),
                          Text('₹$price', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0B0E0F))),
                          const SizedBox(width: 8),
                          Text('Stock: $stock', style: TextStyle(fontSize: 11, color: stock > 0 ? const Color(0xFF059669) : const Color(0xFFDC2626))),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF9CA3AF)),
              ],
            ),
            if (desc.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(desc, style: TextStyle(fontSize: 11, color: Colors.grey.shade600), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            if (img1.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.image_rounded, size: 12, color: Color(0xFF9CA3AF)),
                  const SizedBox(width: 4),
                  Text(
                    'image_url',
                    style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class UserCard extends StatelessWidget {
  const UserCard({required this.user, required this.onTap});
  final Map<String, dynamic> user;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final name = (user['name'] ?? '—').toString();
    final email = (user['email'] ?? '').toString();
    final phone = (user['phone'] ?? '').toString();
    final role = (user['role'] ?? 'customer').toString();
    final status = (user['status'] ?? 'active').toString();
    final isAdmin = role == 'admin';
    final initial = name.isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    String joined = '—';
    final raw = user[r'$createdAt'] ?? user['created_at'] ?? user[r'$created_at'] ?? '';
    if (raw.toString().isNotEmpty) {
      try {
        final dt = DateTime.parse(raw.toString()).toLocal();
        joined = '${dt.day}/${dt.month}/${dt.year}';
      } catch (_) {
        joined = raw.toString().substring(0, 10);
      }
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(radius: 20, backgroundColor: isAdmin ? const Color(0xFF7C3AED) : const Color(0xFFE0E7FF), child: Text(initial, style: TextStyle(color: isAdmin ? Colors.white : const Color(0xFF4F46E5), fontWeight: FontWeight.w800))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Expanded(child: Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0B0E0F)), maxLines: 1, overflow: TextOverflow.ellipsis)), const SizedBox(width: 6), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: isAdmin ? const Color(0xFFF5F3FF) : const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(100), border: Border.all(color: isAdmin ? const Color(0xFFDDD6FE) : const Color(0xFFE5E7EB))), child: Text(isAdmin ? 'ADMIN' : 'CUSTOMER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: isAdmin ? const Color(0xFF7C3AED) : const Color(0xFF6B7280))))]),
              const SizedBox(height: 2),
              Text(email, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Row(children: [Icon(Icons.phone_rounded, size: 11, color: const Color(0xFF9CA3AF)), const SizedBox(width: 4), Text(phone.isEmpty ? '—' : phone, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))), const Spacer(), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: status == 'active' ? const Color(0xFFECFDF5) : status == 'blocked' ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(100)), child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: status == 'active' ? const Color(0xFF059669) : status == 'blocked' ? const Color(0xFFDC2626) : const Color(0xFFD97706))))]),
            ])),
            const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF9CA3AF)),
          ]),
          const SizedBox(height: 8),
          Row(children: [Icon(Icons.calendar_today_rounded, size: 11, color: const Color(0xFF9CA3AF)), const SizedBox(width: 4), Text('Joined $joined', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))), const Spacer(), Text('Tap to view', style: TextStyle(fontSize: 11, color: Colors.grey.shade400))]),
        ]),
      ),
    );
  }
}

class SubscriberCard extends StatelessWidget {
  const SubscriberCard({required this.subscriber});
  final Map<String, dynamic> subscriber;

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active': return const Color(0xFF059669);
      case 'pending': return const Color(0xFFD97706);
      case 'unsubscribed': return const Color(0xFF6B7280);
      case 'bounced': return const Color(0xFFDC2626);
      default: return const Color(0xFF6B7280);
    }
  }

  Color _statusBg(String status) {
    switch (status.toLowerCase()) {
      case 'active': return const Color(0xFFECFDF5);
      case 'pending': return const Color(0xFFFFFBEB);
      case 'unsubscribed': return const Color(0xFFF9FAFB);
      case 'bounced': return const Color(0xFFFEF2F2);
      default: return const Color(0xFFF9FAFB);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = (subscriber['email'] ?? '').toString();
    final status = (subscriber['status'] ?? '').toString();
    final source = (subscriber['source'] ?? '').toString();
    final subscribedAt = subscriber['subscribed_at'];

    String fmtDate(dynamic raw) {
      if (raw == null) return '—';
      try {
        final d = DateTime.parse(raw.toString());
        final now = DateTime.now();
        final diff = now.difference(d);
        if (diff.inMinutes < 1) return 'Just now';
        if (diff.inHours < 1) return '${diff.inMinutes}m ago';
        if (diff.inDays < 1) return '${diff.inHours}h ago';
        if (diff.inDays < 7) return '${diff.inDays}d ago';
        return '${d.day}/${d.month}/${d.year}';
      } catch (_) {
        return raw.toString().substring(0, 10);
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(email, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0B0E0F))),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusBg(status),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _statusColor(status))),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _metaChip(Icons.link_rounded, source),
              const SizedBox(width: 8),
              _metaChip(Icons.access_time_rounded, fmtDate(subscribedAt)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metaChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
      ],
    );
  }
}
