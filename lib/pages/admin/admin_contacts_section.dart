import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/csv_export_helper.dart';
import '../../appwrite/contact_repository.dart';

class ContactsSection extends StatefulWidget {
  const ContactsSection({
    required this.contacts,
    required this.isMobile,
    this.onContactTap,
    this.onRefresh,
  });

  final List<Map<String, dynamic>> contacts;
  final bool isMobile;
  final ValueChanged<Map<String, dynamic>>? onContactTap;
  final VoidCallback? onRefresh;

  @override
  State<ContactsSection> createState() => _ContactsSectionState();
}

class _ContactsSectionState extends State<ContactsSection> {
  String _contactSearch = '';

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
      return raw.toString().substring(0, 10);
    }
  }

  List<Map<String, dynamic>> get _filteredContacts {
    final q = _contactSearch.trim().toLowerCase();
    var filtered = List<Map<String, dynamic>>.from(widget.contacts);
    if (q.isNotEmpty) {
      filtered = filtered.where((c) {
        return (c['name'] ?? '').toString().toLowerCase().contains(q) ||
            (c['email'] ?? '').toString().toLowerCase().contains(q) ||
            (c['message'] ?? '').toString().toLowerCase().contains(q) ||
            (c['phone'] ?? '').toString().contains(q);
      }).toList();
    }
    filtered.sort((a, b) => (b['created_at'] ?? '').toString().compareTo((a['created_at'] ?? '').toString()));
    return filtered;
  }

  int get _newCount => widget.contacts.where((c) => (c['status'] ?? '').toString().toLowerCase() == 'new').length;

  void _showContactDialog(Map<String, dynamic> c) {
    final name = (c['name'] ?? '—').toString();
    final email = (c['email'] ?? '—').toString();
    final phone = (c['phone'] ?? '—').toString();
    final address = (c['address'] ?? '').toString();
    final pincode = (c['pincode'] ?? '').toString();
    final district = (c['district'] ?? '').toString();
    final state = (c['state'] ?? '').toString();
    final country = (c['country'] ?? '').toString();
    final message = (c['message'] ?? '').toString();
    final status = (c['status'] ?? 'new').toString();
    final raw = c[r'$createdAt'] ?? c['created_at'] ?? c[r'$created_at'] ?? c['createdAt'] ?? c['date'] ?? '';
    DateTime? dt;
    if (raw != null && raw.toString().isNotEmpty) {
      try {
        dt = DateTime.parse(raw.toString()).toLocal();
      } catch (_) {}
    }
    final timeAgo = dt != null ? _formatDate(dt.toIso8601String()) : '—';
    String formattedDate = '—';
    String formattedTime = '';
    if (dt != null) {
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      final hh = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final ap = dt.hour >= 12 ? 'PM' : 'AM';
      formattedDate = '${dt.day.toString().padLeft(2,'0')} ${months[dt.month-1]} ${dt.year}';
      formattedTime = '${hh.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')} $ap';
    } else if (raw.toString().isNotEmpty) {
      formattedDate = raw.toString().substring(0, raw.toString().length > 19 ? 19 : raw.toString().length);
    }
    final initial = name.isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    final isNew = status.toLowerCase() == 'new';
    final wordCount = message.trim().isEmpty ? 0 : message.trim().split(RegExp(r'\s+')).length;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 4,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF00C805), Color(0xFF0B0E0F)]),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF00C805), Color(0xFF059669)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [BoxShadow(color: const Color(0xFF00C805).withOpacity(0.3), blurRadius: 12, offset: const Offset(0,4))],
                            ),
                            child: Center(child: Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18))),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0B0E0F))),
                              const SizedBox(height: 3),
                              Row(children: [
                                const Icon(Icons.alternate_email_rounded, size: 13, color: Color(0xFF6B7280)),
                                const SizedBox(width: 4),
                                Flexible(child: Text(email, style: const TextStyle(fontSize: 12, color: Color(0xFF2563EB), fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                              ]),
                              const SizedBox(height: 2),
                              Row(children: [
                                const Icon(Icons.phone_rounded, size: 13, color: Color(0xFF6B7280)),
                                const SizedBox(width: 4),
                                Text(phone, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w600)),
                              ]),
                            ]),
                          ),
                          const SizedBox(width: 10),
                          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: isNew ? const Color(0xFFECFDF5) : const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(100),
                                border: Border.all(color: isNew ? const Color(0xFF86EFAC) : const Color(0xFFE5E7EB)),
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Container(width: 6, height: 6, decoration: BoxDecoration(color: isNew ? const Color(0xFF00C805) : const Color(0xFF9CA3AF), shape: BoxShape.circle)),
                                const SizedBox(width: 6),
                                Text(isNew ? 'NEW' : status.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: isNew ? const Color(0xFF059669) : const Color(0xFF6B7280))),
                              ]),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE5E7EB))),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                const Icon(Icons.schedule_rounded, size: 12, color: Color(0xFF6B7280)),
                                const SizedBox(width: 4),
                                Text(timeAgo, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
                              ]),
                            ),
                          ]),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFF9FAFB), Colors.white], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: const Color(0xFF0B0E0F), borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.calendar_today_rounded, size: 16, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                const Text('RECEIVED ON', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.0, color: Color(0xFF9CA3AF))),
                                const SizedBox(height: 2),
                                Text(formattedDate == '—' ? '—' : '$formattedDate • $formattedTime', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0B0E0F))),
                                const SizedBox(height: 2),
                                Text(dt != null ? '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year} ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')} • $timeAgo' : 'Time not available', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                              ]),
                            ),
                            if (dt != null)
                              IconButton(
                                tooltip: 'Copy timestamp',
                                icon: const Icon(Icons.content_copy_rounded, size: 16, color: Color(0xFF6B7280)),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: dt!.toIso8601String()));
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Timestamp copied'), backgroundColor: Color(0xFF0B0E0F)));
                                },
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        if (phone.isNotEmpty && phone != '—') _mailMetaCard(Icons.phone_rounded, 'Phone', phone),
                        if (address.isNotEmpty) _mailMetaCard(Icons.home_rounded, 'Address', address),
                        if (district.isNotEmpty || state.isNotEmpty) _mailMetaCard(Icons.location_on_rounded, 'Location', '$district${district.isNotEmpty && state.isNotEmpty ? ', ' : ''}$state${country.isNotEmpty ? ' • $country' : ''}'),
                        if (pincode.isNotEmpty) _mailMetaCard(Icons.pin_drop_rounded, 'Pincode', pincode),
                      ]),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0,4))],
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.mail_rounded, size: 14, color: Color(0xFF2563EB))),
                            const SizedBox(width: 8),
                            const Text('MESSAGE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF6B7280), letterSpacing: 0.8)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(100)),
                              child: Text('$wordCount words • ${message.length} chars', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
                            ),
                          ]),
                          const SizedBox(height: 12),
                          Divider(height: 1, color: Colors.grey.shade100),
                          const SizedBox(height: 12),
                          SelectableText(message.isEmpty ? '— No message —' : message, style: const TextStyle(fontSize: 14, height: 1.7, color: Color(0xFF0B0E0F))),
                        ]),
                      ),
                      const SizedBox(height: 20),
                      Row(children: [
                        Expanded(child: OutlinedButton.icon(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close_rounded, size: 16), label: const Text('Close'), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), side: const BorderSide(color: Color(0xFFE5E7EB)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))))),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: email));
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Email $email copied'), backgroundColor: const Color(0xFF00C805)));
                            },
                            icon: const Icon(Icons.reply_rounded, size: 16),
                            label: const Text('Reply / Copy'),
                            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF00C805), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))),
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mailMetaCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(7), border: Border.all(color: const Color(0xFFE5E7EB))), child: Icon(icon, size: 13, color: const Color(0xFF6B7280))),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: Color(0xFF9CA3AF))),
          const SizedBox(height: 1),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0B0E0F))),
        ]),
      ]),
    );
  }

  Future<void> _exportContacts(List<Map<String, dynamic>> data) async {
    final csv = StringBuffer();
    csv.writeln('Name,Email,Phone,Address,Pincode,District,State,Country,Message,Status,Created At');
    for (final c in data) {
      final name = (c['name'] ?? '').toString().replaceAll(',', ';');
      final email = (c['email'] ?? '').toString().replaceAll(',', ';');
      final phone = (c['phone'] ?? '').toString().replaceAll(',', ';');
      final address = (c['address'] ?? '').toString().replaceAll(',', ';');
      final pincode = (c['pincode'] ?? '').toString().replaceAll(',', ';');
      final district = (c['district'] ?? '').toString().replaceAll(',', ';');
      final st = (c['state'] ?? '').toString().replaceAll(',', ';');
      final country = (c['country'] ?? '').toString().replaceAll(',', ';');
      final message = (c['message'] ?? '').toString().replaceAll(',', ';').replaceAll('\n', ' ');
      final status = (c['status'] ?? '').toString().replaceAll(',', ';');
      final createdAt = (c['created_at'] ?? c[r'$createdAt'] ?? '').toString().replaceAll(',', ';');
      csv.writeln('$name,$email,$phone,$address,$pincode,$district,$st,$country,$message,$status,$createdAt');
    }
    final csvBytes = Uint8List.fromList(csv.toString().codeUnits);
    final now = DateTime.now();
    final fileName = 'contacts_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}.csv';

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

  Future<void> _handleContactTap(Map<String, dynamic> c) async {
    final docId = (c['id'] ?? c[r'$id'] ?? '').toString();
    final isNew = (c['status'] ?? '').toString().toLowerCase() == 'new';
    if (isNew && docId.isNotEmpty) {
      setState(() {
        c['status'] = 'read';
      });
      try {
        await AppwriteContactRepository.updateStatus(docId, 'read');
      } catch (_) {}
    }
    widget.onContactTap?.call({...c, 'status': isNew ? 'read' : c['status']});
    _showContactDialog({...c, 'status': isNew ? 'read' : (c['status'] ?? 'new').toString()});
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredContacts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.mail_rounded, size: 18, color: Color(0xFF2563EB)),
            ),
            const SizedBox(width: 10),
            const Flexible(child: Text('Contacts', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0B0E0F)))),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: () => _exportContacts(filtered),
              icon: const Icon(Icons.download_rounded, size: 16),
              label: const Text('Export CSV', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF6B7280),
                side: const BorderSide(color: Color(0xFFE5E7EB)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: widget.onRefresh,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              tooltip: 'Refresh',
              style: IconButton.styleFrom(foregroundColor: const Color(0xFF6B7280)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildInboxHeader(filtered),
        const SizedBox(height: 12),
        if (widget.isMobile)
          ..._buildMobileList(filtered)
        else
          _buildDesktopTable(filtered),
      ],
    );
  }

  Widget _buildInboxHeader(List<Map<String, dynamic>> filtered) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.inbox_rounded, size: 18, color: Color(0xFF2563EB)),
          ),
          const SizedBox(width: 10),
          const Flexible(child: Text('Inbox', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0B0E0F)))),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(100)),
            child: Text('${filtered.length} messages', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF059669))),
          ),
          if (_newCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xFF00C805), borderRadius: BorderRadius.circular(100)),
              child: Text('$_newCount new', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ],
          const Spacer(),
          IconButton(onPressed: widget.onRefresh, tooltip: 'Refresh inbox', icon: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF6B7280))),
        ]),
        const SizedBox(height: 12),
        TextField(
          onChanged: (v) => setState(() => _contactSearch = v),
          decoration: InputDecoration(
            hintText: 'Search by name, email or message…',
            prefixIcon: const Icon(Icons.search_rounded, size: 18),
            suffixIcon: _contactSearch.isNotEmpty ? IconButton(icon: const Icon(Icons.close_rounded, size: 16), onPressed: () => setState(() => _contactSearch = '')) : null,
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.4)),
          ),
        ),
      ]),
    );
  }

  List<Widget> _buildMobileList(List<Map<String, dynamic>> filtered) {
    if (filtered.isEmpty && widget.contacts.isEmpty) {
      return [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE5E7EB))),
          child: Column(children: [
            Container(width: 72, height: 72, decoration: BoxDecoration(color: const Color(0xFFF3F4F6), shape: BoxShape.circle), child: const Icon(Icons.mark_email_unread_rounded, size: 32, color: Color(0xFF9CA3AF))),
            const SizedBox(height: 16),
            const Text('Inbox empty', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0B0E0F))),
            const SizedBox(height: 6),
            Text('Contact form messages will appear here', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
          ]),
        ),
      ];
    }

    if (filtered.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text('No messages match "$_contactSearch"', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
        ),
      ];
    }

    return [
      Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Color(0xFFE5E7EB))),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            ...filtered.map((c) {
              final name = (c['name'] ?? '—').toString();
              final email = (c['email'] ?? '').toString();
              final message = (c['message'] ?? '').toString();
              final preview = message.length > 70 ? '${message.substring(0, 70)}…' : message;
              final status = (c['status'] ?? 'new').toString();
              final isNew = status.toLowerCase() == 'new';
              final initial = name.isNotEmpty ? name.trim()[0].toUpperCase() : '?';
              return Material(
                color: isNew ? const Color(0xFFECFDF5).withOpacity(0.35) : Colors.white,
                child: InkWell(
                  onTap: () => _handleContactTap(c),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
                    child: Row(
                      children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: isNew ? const Color(0xFF00C805) : Colors.transparent, shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        CircleAvatar(radius: 18, backgroundColor: isNew ? const Color(0xFF00C805) : const Color(0xFFE5E7EB), child: Text(initial, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: isNew ? Colors.white : const Color(0xFF6B7280)))),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Expanded(child: Text(name, style: TextStyle(fontSize: 13, fontWeight: isNew ? FontWeight.w800 : FontWeight.w600, color: const Color(0xFF0B0E0F)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: isNew ? const Color(0xFFDCFCE7) : const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(100)),
                                child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isNew ? const Color(0xFF059669) : const Color(0xFF6B7280))),
                              ),
                            ]),
                            const SizedBox(height: 2),
                            Text(email, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text(preview.isEmpty ? '— no message —' : preview, style: TextStyle(fontSize: 11, color: isNew ? const Color(0xFF0B0E0F) : const Color(0xFF6B7280), fontWeight: isNew ? FontWeight.w600 : FontWeight.w400), maxLines: 2, overflow: TextOverflow.ellipsis),
                          ]),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF9CA3AF)),
                      ],
                    ),
                  ),
                ),
              );
            }),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(color: Color(0xFFF9FAFB), border: Border(top: BorderSide(color: Color(0xFFE5E7EB)))),
              child: Row(children: [
                const Icon(Icons.mail_outline_rounded, size: 14, color: Color(0xFF9CA3AF)),
                const SizedBox(width: 6),
                Text('${filtered.length} conversations • Tap to read full message', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w500)),
                const Spacer(),
                TextButton.icon(onPressed: widget.onRefresh, icon: const Icon(Icons.refresh_rounded, size: 14), label: const Text('Refresh', style: TextStyle(fontSize: 12)), style: TextButton.styleFrom(foregroundColor: const Color(0xFF6B7280), visualDensity: VisualDensity.compact)),
              ]),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _buildDesktopTable(List<Map<String, dynamic>> filtered) {
    if (filtered.isEmpty && widget.contacts.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE5E7EB))),
        child: Column(children: [
          Container(width: 72, height: 72, decoration: BoxDecoration(color: const Color(0xFFF3F4F6), shape: BoxShape.circle), child: const Icon(Icons.mark_email_unread_rounded, size: 32, color: Color(0xFF9CA3AF))),
          const SizedBox(height: 16),
          const Text('Inbox empty', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0B0E0F))),
          const SizedBox(height: 6),
          Text('Contact form messages will appear here', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
        ]),
      );
    }

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE5E7EB))),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(color: Color(0xFFF9FAFB), border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))),
            child: Row(children: [
              const SizedBox(width: 8),
              const SizedBox(width: 130, child: Text('Date', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF6B7280), letterSpacing: 0.6))),
              const SizedBox(width: 8),
              const Expanded(flex: 3, child: Text('From', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF6B7280), letterSpacing: 0.6))),
              const Expanded(flex: 5, child: Text('Message', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF6B7280), letterSpacing: 0.6))),
              const SizedBox(width: 8),
            ]),
          ),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text('No messages match "$_contactSearch"', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
            )
          else
            ...filtered.map((c) {
              final name = (c['name'] ?? '—').toString();
              final email = (c['email'] ?? '').toString();
              final message = (c['message'] ?? '').toString();
              final preview = message.length > 70 ? '${message.substring(0, 70)}…' : message;
              final status = (c['status'] ?? 'new').toString();
              final isNew = status.toLowerCase() == 'new';
              final initial = name.isNotEmpty ? name.trim()[0].toUpperCase() : '?';
              String fullDateTime = '';
              final raw = c['created_at'] ?? c[r'$createdAt'] ?? c[r'$created_at'];
              if (raw != null) {
                try {
                  final dt = DateTime.parse(raw.toString()).toLocal();
                  fullDateTime = '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year} ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
                } catch (_) {
                  fullDateTime = _formatDate(c['created_at']);
                }
              } else {
                fullDateTime = _formatDate(c['created_at']);
              }
              return Material(
                color: isNew ? const Color(0xFFECFDF5).withOpacity(0.35) : Colors.white,
                child: InkWell(
                  onTap: () => _handleContactTap(c),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
                    child: Row(
                      children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: isNew ? const Color(0xFF00C805) : Colors.transparent, shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 130,
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(fullDateTime, style: TextStyle(fontSize: 11, fontWeight: isNew ? FontWeight.w800 : FontWeight.w600, color: isNew ? const Color(0xFF0B0E0F) : const Color(0xFF374151)), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 3),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: isNew ? const Color(0xFFDCFCE7) : const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(100)),
                              child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isNew ? const Color(0xFF059669) : const Color(0xFF6B7280))),
                            ),
                          ]),
                        ),
                        const SizedBox(width: 10),
                        CircleAvatar(radius: 18, backgroundColor: isNew ? const Color(0xFF00C805) : const Color(0xFFE5E7EB), child: Text(initial, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: isNew ? Colors.white : const Color(0xFF6B7280)))),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(name, style: TextStyle(fontSize: 13, fontWeight: isNew ? FontWeight.w800 : FontWeight.w600, color: const Color(0xFF0B0E0F)), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text(email, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ]),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 5,
                          child: Text(preview.isEmpty ? '— no message —' : preview, style: TextStyle(fontSize: 12, color: isNew ? const Color(0xFF0B0E0F) : const Color(0xFF6B7280), fontWeight: isNew ? FontWeight.w700 : FontWeight.w400), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF9CA3AF)),
                      ],
                    ),
                  ),
                ),
              );
            }),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(color: Color(0xFFF9FAFB), border: Border(top: BorderSide(color: Color(0xFFE5E7EB)))),
            child: Row(children: [
              const Icon(Icons.mail_outline_rounded, size: 14, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 6),
              Text('${filtered.length} conversations • Tap to read full message', style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w500)),
              const Spacer(),
              TextButton.icon(onPressed: widget.onRefresh, icon: const Icon(Icons.refresh_rounded, size: 14), label: const Text('Refresh', style: TextStyle(fontSize: 12)), style: TextButton.styleFrom(foregroundColor: const Color(0xFF6B7280), visualDensity: VisualDensity.compact)),
            ]),
          ),
        ],
      ),
    );
  }
}
