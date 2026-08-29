import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../services/csv_export_helper.dart';

class SubscribersSection extends StatefulWidget {
  const SubscribersSection({
    required this.subscribers,
    required this.isMobile,
    this.onRefresh,
  });

  final List<Map<String, dynamic>> subscribers;
  final bool isMobile;
  final VoidCallback? onRefresh;

  @override
  State<SubscribersSection> createState() => _SubscribersSectionState();
}

class _SubscribersSectionState extends State<SubscribersSection> {
  String _subSearch = '';
  String _subStatusFilter = 'all';
  String _subSortBy = 'newest';
  int _page = 1;
  static const int _pageSize = 10;

  List<Map<String, dynamic>> get _filteredSubscribers {
    var list = List<Map<String, dynamic>>.from(widget.subscribers);
    if (_subStatusFilter != 'all') {
      list = list.where((s) => (s['status'] ?? '') == _subStatusFilter).toList();
    }
    if (_subSearch.isNotEmpty) {
      final q = _subSearch.toLowerCase();
      list = list.where((s) => (s['email'] ?? '').toString().toLowerCase().contains(q)).toList();
    }
    switch (_subSortBy) {
      case 'oldest':
        list.sort((a, b) => (a['subscribed_at'] ?? '').toString().compareTo((b['subscribed_at'] ?? '').toString()));
        break;
      case 'email':
        list.sort((a, b) => (a['email'] ?? '').toString().compareTo((b['email'] ?? '').toString()));
        break;
      case 'newest':
      default:
        list.sort((a, b) => (b['subscribed_at'] ?? '').toString().compareTo((a['subscribed_at'] ?? '').toString()));
    }
    return list;
  }

  String _formatDate(dynamic raw) {
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
      final s = raw.toString();
      return s.length > 10 ? s.substring(0, 10) : s;
    }
  }

  Future<void> _exportSubscribers(List<Map<String, dynamic>> data) async {
    final csv = StringBuffer();
    csv.writeln('Email,Status,Source,Subscribed At,Updated At');
    for (final s in data) {
      final email = (s['email'] ?? '').toString().replaceAll(',', ';');
      final status = (s['status'] ?? '').toString().replaceAll(',', ';');
      final source = (s['source'] ?? '').toString().replaceAll(',', ';');
      final subscribedAt = (s['subscribed_at'] ?? '').toString().replaceAll(',', ';');
      final updatedAt = (s['updated_at'] ?? '').toString().replaceAll(',', ';');
      csv.writeln('$email,$status,$source,$subscribedAt,$updatedAt');
    }
    final csvBytes = Uint8List.fromList(csv.toString().codeUnits);
    final now = DateTime.now();
    final fileName = 'subscribers_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}.csv';

    try {
      await downloadCsvFile(csvBytes, fileName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CSV exported ($fileName) — ${data.length} rows'),
            backgroundColor: const Color(0xFF00C805),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _resetPage() => _page = 1;

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredSubscribers;
    final allSubs = widget.subscribers;
    final statusCounts = <String, int>{
      'all': allSubs.length,
      'active': allSubs.where((s) => s['status'] == 'active').length,
      'pending': allSubs.where((s) => s['status'] == 'pending').length,
      'unsubscribed': allSubs.where((s) => s['status'] == 'unsubscribed').length,
      'bounced': allSubs.where((s) => s['status'] == 'bounced').length,
    };
    // pagination — clamp without mutating state during build
    final totalPages = (filtered.isEmpty ? 1 : (filtered.length / _pageSize).ceil());
    final effectivePage = _page.clamp(1, totalPages);
    // schedule correction if stale (avoids setState during build)
    if (effectivePage != _page) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _page != effectivePage) setState(() => _page = effectivePage);
      });
    }
    final paginated = filtered.skip((effectivePage - 1) * _pageSize).take(_pageSize).toList();
    final startIdx = (effectivePage - 1) * _pageSize;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(filtered),
        const SizedBox(height: 12),
        _buildStatusChips(statusCounts),
        const SizedBox(height: 12),
        if (widget.isMobile) _buildMobileSearchSort() else _buildDesktopSearchSort(),
        const SizedBox(height: 10),
        Text(
          'Showing ${filtered.length} of ${allSubs.length} subscribers',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 12),
        if (widget.isMobile)
          ...paginated.map((s) => _MobileSubscriberCard(subscriber: s, formatDate: _formatDate))
        else
          _buildDirectoryCard(paginated, startIdx, totalPages, filtered.length),
        if (widget.isMobile && paginated.isNotEmpty) _buildMobilePagination(totalPages),
        if (widget.isMobile && filtered.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
            child: const Center(child: Text('No subscribers match your filters', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)))),
          ),
      ],
    );
  }

  // ── HEADER ──
  Widget _buildHeader(List<Map<String, dynamic>> filtered) {
    final exportBtn = ElevatedButton.icon(
      onPressed: () => _exportSubscribers(filtered),
      icon: const Icon(Icons.download_rounded, size: 14, color: Colors.white),
      label: const Text('Export CSV', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF00C805),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(0, 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
    final refreshBtn = Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: widget.onRefresh,
        icon: const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFF6B7280)),
        tooltip: 'Refresh',
      ),
    );

    if (widget.isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.how_to_reg_rounded, size: 16, color: Color(0xFF00C805)),
              const SizedBox(width: 6),
              const Flexible(child: Text('Subscribers', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0B0E0F)))),
              const Spacer(),
              refreshBtn,
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(width: double.infinity, child: exportBtn),
        ],
      );
    }

    return Row(
      children: [
        const Icon(Icons.how_to_reg_rounded, size: 16, color: Color(0xFF00C805)),
        const SizedBox(width: 6),
        const Flexible(child: Text('Subscribers', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0B0E0F)))),
        const Spacer(),
        exportBtn,
        const SizedBox(width: 8),
        refreshBtn,
      ],
    );
  }

  Widget _buildStatusChips(Map<String, int> statusCounts) {
    const order = ['all', 'active', 'pending', 'unsubscribed', 'bounced'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: order.map((key) {
          final count = statusCounts[key] ?? 0;
          final selected = _subStatusFilter == key;
          final label = key[0].toUpperCase() + key.substring(1);
          final isAll = key == 'all';
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => setState(() {
                _subStatusFilter = key;
                _resetPage();
              }),
              borderRadius: BorderRadius.circular(100),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFF00C805) : Colors.white,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: selected ? const Color(0xFF00C805) : const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (selected && isAll) const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                    if (selected && isAll) const SizedBox(width: 4),
                    Text('$label ($count)', style: TextStyle(fontSize: 12, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: selected ? Colors.white : const Color(0xFF374151))),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  InputDecoration _searchDecoration() {
    return InputDecoration(
      hintText: 'Search by email...',
      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
      prefixIcon: const Icon(Icons.search_rounded, size: 16, color: Color(0xFF6B7280)),
      suffixIcon: _subSearch.isNotEmpty
          ? IconButton(icon: const Icon(Icons.close_rounded, size: 14), onPressed: () => setState(() { _subSearch = ''; _resetPage(); }))
          : null,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF00C805), width: 1.2)),
    );
  }

  Widget _buildSortDropdown() {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _subSortBy,
          isExpanded: true,
          isDense: true,
          style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
          icon: const Icon(Icons.arrow_drop_down_rounded, size: 18, color: Color(0xFF6B7280)),
          items: const [
            DropdownMenuItem(value: 'newest', child: Text('Newest first', style: TextStyle(fontSize: 12))),
            DropdownMenuItem(value: 'oldest', child: Text('Oldest first', style: TextStyle(fontSize: 12))),
            DropdownMenuItem(value: 'email', child: Text('Email A-Z', style: TextStyle(fontSize: 12))),
          ],
          onChanged: (v) => setState(() { _subSortBy = v ?? 'newest'; _resetPage(); }),
        ),
      ),
    );
  }

  Widget _buildMobileSearchSort() {
    return Column(
      children: [
        TextField(onChanged: (v) => setState(() { _subSearch = v; _resetPage(); }), decoration: _searchDecoration()),
        const SizedBox(height: 8),
        _buildSortDropdown(),
      ],
    );
  }

  Widget _buildDesktopSearchSort() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: TextField(onChanged: (v) => setState(() { _subSearch = v; _resetPage(); }), decoration: _searchDecoration())),
        const SizedBox(width: 10),
        Expanded(flex: 2, child: _buildSortDropdown()),
      ],
    );
  }

  // ── DIRECTORY CARD (split tables) ──
  Widget _buildDirectoryCard(List<Map<String, dynamic>> paginated, int startIdx, int totalPages, int totalFiltered) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // two panels
          LayoutBuilder(builder: (ctx, c) {
            final isNarrow = c.maxWidth < 700;
            if (isNarrow) {
              return Column(
                children: [
                  _PrimaryContactTable(rows: paginated, startIdx: startIdx, formatDate: _formatDate),
                  const SizedBox(height: 12),
                  _ActivityMetaTable(rows: paginated, startIdx: startIdx, formatDate: _formatDate),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _PrimaryContactTable(rows: paginated, startIdx: startIdx, formatDate: _formatDate)),
                const SizedBox(width: 12),
                Expanded(child: _ActivityMetaTable(rows: paginated, startIdx: startIdx, formatDate: _formatDate)),
              ],
            );
          }),
          if (paginated.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFF3F4F6))),
              child: const Center(child: Text('No subscribers match your filters', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)))),
            ),
          const SizedBox(height: 12),
          Container(height: 1, color: const Color(0xFFF3F4F6)),
          const SizedBox(height: 10),
          Builder(builder: (context) {
            final displayPage = (startIdx ~/ _pageSize) + 1;
            final isFirst = displayPage <= 1;
            final isLast = displayPage >= totalPages;
            return Row(
              children: [
                const Spacer(),
                Text('Page $displayPage of $totalPages', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF6B7280))),
                const Spacer(),
                _PageBtn(
                  label: 'Prev',
                  icon: Icons.chevron_left_rounded,
                  iconBefore: true,
                  enabled: !isFirst,
                  onTap: () => setState(() => _page = (displayPage - 1).clamp(1, totalPages)),
                ),
                const SizedBox(width: 6),
                _PageBtn(
                  label: 'Next',
                  icon: Icons.chevron_right_rounded,
                  iconBefore: false,
                  enabled: !isLast,
                  onTap: () => setState(() => _page = (displayPage + 1).clamp(1, totalPages)),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMobilePagination(int totalPages) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Row(
        children: [
          const Spacer(),
          Text('Page $_page of $totalPages', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          const Spacer(),
          _PageBtn(label: 'Prev', icon: Icons.chevron_left_rounded, iconBefore: true, enabled: _page > 1, onTap: () => setState(() => _page--)),
          const SizedBox(width: 6),
          _PageBtn(label: 'Next', icon: Icons.chevron_right_rounded, iconBefore: false, enabled: _page < totalPages, onTap: () => setState(() => _page++)),
        ],
      ),
    );
  }
}

// ── Primary Contact Info table ──
class _PrimaryContactTable extends StatelessWidget {
  const _PrimaryContactTable({required this.rows, required this.startIdx, required this.formatDate});
  final List<Map<String, dynamic>> rows;
  final int startIdx;
  final String Function(dynamic) formatDate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Primary Contact Info', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0B0E0F))),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE5E7EB))),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: const BoxDecoration(color: Color(0xFFF3F4F6), border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))),
                child: const Row(
                  children: [
                    SizedBox(width: 28, child: Text('#', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6B7280)))),
                    Expanded(child: Text('Email', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6B7280)))),
                    SizedBox(width: 80, child: Text('Status', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6B7280)))),
                  ],
                ),
              ),
              ...rows.asMap().entries.map((entry) {
                final idx = startIdx + entry.key + 1;
                final s = entry.value;
                final email = (s['email'] ?? '').toString();
                final status = (s['status'] ?? '').toString();
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
                  child: Row(
                    children: [
                      SizedBox(width: 28, child: Text('$idx', style: const TextStyle(fontSize: 12, color: Color(0xFF111827)))),
                      Expanded(child: Text(email, style: const TextStyle(fontSize: 12, color: Color(0xFF111827)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(100)),
                        child: Text(status, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF16A34A))),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Activity and Meta table ──
class _ActivityMetaTable extends StatelessWidget {
  const _ActivityMetaTable({required this.rows, required this.startIdx, required this.formatDate});
  final List<Map<String, dynamic>> rows;
  final int startIdx;
  final String Function(dynamic) formatDate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Activity and Meta', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0B0E0F))),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE5E7EB))),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: const BoxDecoration(color: Color(0xFFF3F4F6), border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))),
                child: const Row(
                  children: [
                    SizedBox(width: 28, child: Text('#', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6B7280)))),
                    Expanded(flex: 2, child: Text('Source', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6B7280)))),
                    Expanded(child: Text('Subscribed', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6B7280)))),
                    Expanded(child: Text('Updated', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6B7280)))),
                  ],
                ),
              ),
              ...rows.asMap().entries.map((entry) {
                final idx = startIdx + entry.key + 1;
                final s = entry.value;
                final source = (s['source'] ?? '').toString();
                final sub = formatDate(s['subscribed_at']);
                final upd = formatDate(s['updated_at']);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
                  child: Row(
                    children: [
                      SizedBox(width: 28, child: Text('$idx', style: const TextStyle(fontSize: 12, color: Color(0xFF111827)))),
                      Expanded(flex: 2, child: Text(source, style: const TextStyle(fontSize: 12, color: Color(0xFF111827)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      Expanded(child: Text(sub, style: const TextStyle(fontSize: 12, color: Color(0xFF111827)))),
                      Expanded(child: Text(upd, style: const TextStyle(fontSize: 12, color: Color(0xFF111827)))),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class _PageBtn extends StatelessWidget {
  const _PageBtn({required this.label, required this.icon, required this.iconBefore, required this.enabled, required this.onTap});
  final String label;
  final IconData icon;
  final bool iconBefore;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (iconBefore) Icon(icon, size: 14, color: enabled ? const Color(0xFF374151) : const Color(0xFF9CA3AF)),
        if (iconBefore) const SizedBox(width: 2),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: enabled ? const Color(0xFF374151) : const Color(0xFF9CA3AF))),
        if (!iconBefore) const SizedBox(width: 2),
        if (!iconBefore) Icon(icon, size: 14, color: enabled ? const Color(0xFF374151) : const Color(0xFF9CA3AF)),
      ],
    );
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: enabled ? const Color(0xFFE5E7EB) : const Color(0xFFF3F4F6)),
        ),
        child: child,
      ),
    );
  }
}

class _MobileSubscriberCard extends StatelessWidget {
  const _MobileSubscriberCard({required this.subscriber, required this.formatDate});
  final Map<String, dynamic> subscriber;
  final String Function(dynamic) formatDate;

  @override
  Widget build(BuildContext context) {
    final email = (subscriber['email'] ?? '').toString();
    final status = (subscriber['status'] ?? '').toString();
    final source = (subscriber['source'] ?? '').toString();
    final sub = formatDate(subscriber['subscribed_at']);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(email, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0B0E0F)))),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(100)), child: Text(status, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF16A34A)))),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _meta(Icons.link_rounded, source),
              _meta(Icons.access_time_rounded, sub),
            ],
          ),
        ],
      ),
    );
  }

  Widget _meta(IconData icon, String text) => Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 12, color: const Color(0xFF9CA3AF)), const SizedBox(width: 4), Text(text, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)))]); 
}
