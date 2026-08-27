import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import '../widgets/app_header.dart';
import '../constants/company_info.dart';
import '../appwrite/contact_repository.dart';
import '../services/scroll_manager.dart';

class AppColors {
  static const Color tomato = Color(0xFFE94E34);
  static const Color ink = Color(0xFF1A1A1A);
  static const Color green = Color(0xFF2E7D32);
}

class ContactUsPage extends StatelessWidget {
  const ContactUsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: AppHeader(title: 'Hari Om Traders', subtitle: 'Contact Us • hariomtraders.com'),
      body: ContactUsContent(),
    );
  }
}

class ContactUsContent extends StatefulWidget {
  const ContactUsContent({super.key});
  @override
  State<ContactUsContent> createState() => _ContactUsContentState();
}

class _ContactUsContentState extends State<ContactUsContent> {
  static const _scrollKey = 'contact';
  late final ScrollController _scrollCtrl = ScrollManager.instance.controllerFor(_scrollKey);
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _districtController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController(text: 'India');
  final _messageController = TextEditingController();
  bool _sending = false;
  bool _pinLoading = false;
  String? _pinError;
  List<String> _areaOptions = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        final saved = ScrollManager.instance.getOffset(_scrollKey);
        if (saved > 0 && (_scrollCtrl.offset - saved).abs() > 1) {
          _scrollCtrl.jumpTo(saved.clamp(0, _scrollCtrl.position.maxScrollExtent));
        }
      }
    });
  }

  @override
  void dispose() {
    // persist contact scroll offset (SingleChildScrollView)
    ScrollManager.instance.saveOffset(_scrollKey, _scrollCtrl.hasClients ? _scrollCtrl.offset : ScrollManager.instance.getOffset(_scrollKey));
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _pincodeController.dispose();
    _districtController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  String? _validatePhone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Please enter your contact number';
    final t = v.trim().replaceAll(' ', '').replaceAll('-', '');
    final digits = t.replaceAll(RegExp(r'^\+91'), '').replaceAll(RegExp(r'^0'), '');
    if (!RegExp(r'^[0-9]{10,15}$').hasMatch(digits)) return 'Enter valid 10-digit number';
    return null;
  }

  String? _validatePincode(String? v) {
    if (v == null || v.trim().isEmpty) return 'Enter pincode';
    if (!RegExp(r'^[0-9]{6}$').hasMatch(v.trim())) return 'Enter valid 6-digit pincode';
    if (_pinError != null) return _pinError;
    return null;
  }

  Future<void> _fetchPincode(String pin) async {
    final t = pin.trim();
    if (!RegExp(r'^[0-9]{6}$').hasMatch(t)) {
      setState(() { _pinError = null; _areaOptions = []; });
      return;
    }
    setState(() { _pinLoading = true; _pinError = null; });
    try {
      final res = await http.get(Uri.parse('https://api.postalpincode.in/pincode/$t')).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List && data.isNotEmpty && data[0]['Status'] == 'Success') {
          final offices = (data[0]['PostOffice'] as List?) ?? [];
          if (offices.isNotEmpty) {
            final first = offices[0] as Map;
            final district = (first['District'] ?? '').toString();
            final state = (first['State'] ?? '').toString();
            final country = (first['Country'] ?? 'India').toString();
            final areas = offices.map((e) => (e['Name'] ?? '').toString()).where((e) => e.isNotEmpty).toList();
            setState(() {
              _districtController.text = district;
              _stateController.text = state;
              _countryController.text = country.isEmpty ? 'India' : country;
              _areaOptions = areas;
              _pinError = null;
            });
            return;
          }
        }
        setState(() => _pinError = 'Invalid pincode');
      } else {
        setState(() => _pinError = 'Failed to fetch pincode');
      }
    } catch (_) {
      if (mounted) setState(() => _pinError = 'Failed to fetch pincode');
    } finally {
      if (mounted) setState(() => _pinLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    if (_sending) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusManager.instance.primaryFocus?.unfocus();
    // double-tap guard: disable immediately
    if (_sending) return;
    setState(() => _sending = true);
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();
    final pincode = _pincodeController.text.trim();
    final district = _districtController.text.trim();
    final state = _stateController.text.trim();
    final country = _countryController.text.trim().isEmpty ? 'India' : _countryController.text.trim();
    final message = _messageController.text.trim();
    bool ok = false;
    String err = '';
    try {
      ok = await AppwriteContactRepository.submit(name: name, email: email, phone: phone, address: address, pincode: pincode, district: district, state: state, country: country, message: message);
      if (!ok) err = 'Could not save – please try again';
    } catch (e) {
      ok = false;
      err = e.toString();
    }
    if (!mounted) return;
    setState(() => _sending = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thanks! We will be in touch soon.')));
      _formKey.currentState?.reset();
      _nameController.clear();
      _emailController.clear();
      _phoneController.clear();
      _addressController.clear();
      _pincodeController.clear();
      _districtController.clear();
      _stateController.clear();
      _countryController.text = 'India';
      _messageController.clear();
      setState(() {
        _areaOptions = [];
        _pinError = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err.isNotEmpty ? err : 'Failed to send')));
    }
  }

  InputDecoration _decoration(String hint, IconData icon, {Widget? suffix, String? helper, Color? helperColor}) {
    final isDark = Theme.of(context).brightness==Brightness.dark;
    return InputDecoration(
      hintText: hint,
      helperText: helper,
      helperStyle: helperColor!=null?TextStyle(color: helperColor, fontSize: 11):null,
      prefixIcon: Icon(icon, color: AppColors.green, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: isDark? const Color(0xFF14181B): Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark?const Color(0xFF23282D):const Color(0xFFE5E7EB))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark?const Color(0xFF23282D):const Color(0xFFE5E7EB))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.green, width: 1.4)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      isDense: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness==Brightness.dark;
    final bg = theme.scaffoldBackgroundColor;
    const maxW = 1180.0;
    return Container(
      color: bg,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxW),
          child: SingleChildScrollView(
            key: const PageStorageKey<String>(_scrollKey),
            controller: _scrollCtrl,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark? const Color(0xFF14181B): Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark?const Color(0xFF23282D):const Color(0xFFE5E7EB)),
                  ),
                  child: Row(children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: const Color(0xFF00C805), borderRadius: BorderRadius.circular(100)), child: const Text('CONTACT • VARANASI', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.6))),
                    const SizedBox(width: 10),
                    Expanded(child: Text(' replies within 12h • Mon-Sat 8am-6pm • Factory visits welcome', style: theme.textTheme.labelSmall?.copyWith(color: isDark?Colors.white70:const Color(0xFF374151), fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                    Icon(Icons.verified_rounded, size: 16, color: const Color(0xFF00C805).withOpacity(0.9)),
                  ]),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(builder: (context, c){
                  final isNarrow = c.maxWidth < 900;
                  final formCard = Container(
                    decoration: BoxDecoration(
                      color: isDark?const Color(0xFF14181B):Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isDark?const Color(0xFF23282D):const Color(0xFFE5E7EB)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark?0.18:0.05), blurRadius: 18, offset: const Offset(0,8))],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Container(width: 36, height: 36, decoration: BoxDecoration(color: const Color(0xFF00C805).withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.mail_rounded, color: Color(0xFF00C805), size: 18)),
                          const SizedBox(width: 10),
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Send us a note', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: isDark?Colors.white:const Color(0xFF0B0E0F))),
                            Text('Avg reply 3h • No spam • Direct to founder', style: theme.textTheme.labelSmall?.copyWith(color: isDark?Colors.white60:const Color(0xFF6B7280))),
                          ]),
                        ]),
                        const SizedBox(height: 18),
                        TextFormField(controller: _nameController, decoration: _decoration('Your name', Icons.person_outline), validator: (v)=> v==null||v.trim().isEmpty?'Please enter your name':null),
                        const SizedBox(height: 12),
                        TextFormField(controller: _emailController, keyboardType: TextInputType.emailAddress, decoration: _decoration('Email address', Icons.alternate_email), validator: (v)=> v==null||!v.contains('@')?'Please enter valid email':null),
                        const SizedBox(height: 12),
                        TextFormField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: _decoration('Contact number', Icons.phone_outlined), validator: _validatePhone),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark? const Color(0xFF1A1F24): const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isDark?const Color(0xFF23282D):const Color(0xFFE5E7EB)),
                          ),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF6B7280)),
                              const SizedBox(width: 6),
                              Text('ADDRESS', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 1.0, fontSize: 10, color: isDark?Colors.white60:const Color(0xFF9CA3AF))),
                              const Spacer(),
                              Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(100)), child: const Text('Auto-fill via pincode', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF15803D)))),
                            ]),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _pincodeController,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              onChanged: (v){
                                final t=v.trim();
                                if(RegExp(r'^[0-9]{6}$').hasMatch(t)){ _fetchPincode(t); } else { setState((){ _pinError=null; _areaOptions=[]; }); }
                              },
                              decoration: _decoration('Pincode *', Icons.pin_drop_outlined,
                                suffix: _pinLoading? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2))):
                                  (_pinError==null && _districtController.text.isNotEmpty && _pincodeController.text.length==6? const Icon(Icons.check_circle, color: AppColors.green, size:20):null),
                                helper: _pinError ?? (_areaOptions.isNotEmpty? '${_areaOptions.length} areas found • District & State auto-filled':'Enter 6-digit pincode to auto-fill District/State'),
                                helperColor: _pinError!=null?Colors.red:AppColors.green,
                              ).copyWith(counterText: ''),
                              validator: _validatePincode,
                            ),
                            if(_areaOptions.isNotEmpty)...[
                              const SizedBox(height: 8),
                              Wrap(spacing: 6, runSpacing: 6, children: _areaOptions.take(6).map((a)=> ActionChip(
                                label: Text(a, style: const TextStyle(fontSize: 11)),
                                backgroundColor: isDark? const Color(0xFF23282D): Colors.white,
                                side: BorderSide(color: isDark?const Color(0xFF2A2E32):const Color(0xFFE5E7EB)),
                                onPressed: (){ if(_addressController.text.trim().isEmpty) setState(()=> _addressController.text=a); },
                              )).toList()),
                            ],
                            const SizedBox(height: 12),
                            TextFormField(controller: _addressController, decoration: _decoration('Street / House / Area *', Icons.home_outlined), validator: (v)=> v==null||v.trim().length<3?'Please enter address':null),
                            const SizedBox(height: 12),
                            LayoutBuilder(builder: (context, bc2) {
                              final narrowFields = bc2.maxWidth < 360;
                              if (narrowFields) {
                                return Column(children: [
                                  TextFormField(controller: _districtController, decoration: _decoration('District *', Icons.location_city_outlined, suffix: _districtController.text.isNotEmpty && _pincodeController.text.length==6? const Icon(Icons.auto_awesome, size:16, color: AppColors.green):null), validator: (v)=> v==null||v.trim().isEmpty?'Enter district':null),
                                  const SizedBox(height: 12),
                                  TextFormField(controller: _stateController, decoration: _decoration('State *', Icons.map_outlined, suffix: _stateController.text.isNotEmpty && _pincodeController.text.length==6? const Icon(Icons.auto_awesome, size:16, color: AppColors.green):null), validator: (v)=> v==null||v.trim().isEmpty?'Enter state':null),
                                ]);
                              }
                              return Row(children: [
                                Expanded(child: TextFormField(controller: _districtController, decoration: _decoration('District *', Icons.location_city_outlined, suffix: _districtController.text.isNotEmpty && _pincodeController.text.length==6? const Icon(Icons.auto_awesome, size:16, color: AppColors.green):null), validator: (v)=> v==null||v.trim().isEmpty?'Enter district':null)),
                                const SizedBox(width: 12),
                                Expanded(child: TextFormField(controller: _stateController, decoration: _decoration('State *', Icons.map_outlined, suffix: _stateController.text.isNotEmpty && _pincodeController.text.length==6? const Icon(Icons.auto_awesome, size:16, color: AppColors.green):null), validator: (v)=> v==null||v.trim().isEmpty?'Enter state':null)),
                              ]);
                            }),
                            const SizedBox(height: 12),
                            TextFormField(controller: _countryController, decoration: _decoration('Country *', Icons.public_outlined), validator: (v)=> v==null||v.trim().isEmpty?'Enter country':null),
                          ]),
                        ),
                        const SizedBox(height: 12),
                        LayoutBuilder(builder: (context, bc3) {
                          final h = MediaQuery.sizeOf(context).height;
                          final lines = h < 500 ? 6 : h < 700 ? 8 : 10;
                          return TextFormField(controller: _messageController, maxLines: lines, minLines: lines, decoration: _decoration('How can we help? *', Icons.chat_bubble_outline), validator: (v)=> v==null||v.trim().isEmpty?'Please add a message':null);
                        }),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _sending?null:_sendMessage,
                            icon: _sending? const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)): const Icon(Icons.send_rounded, size:18),
                            label: Text(_sending?'Sending…':'Send message', style: const TextStyle(fontWeight: FontWeight.w800)),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF0B0E0F),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: const StadiumBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(child: Text('By sending, you agree to our privacy • Replies via email/WhatsApp', style: theme.textTheme.labelSmall?.copyWith(color: isDark?Colors.white54:const Color(0xFF9CA3AF), fontSize: 11))),
                      ]),
                    ),
                  );
                  final infoCol = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0B0E0F), Color(0xFF1C2A1E)]),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(padding: const EdgeInsets.symmetric(horizontal:10,vertical:5), decoration: BoxDecoration(color: Colors.white.withOpacity(0.10), borderRadius: BorderRadius.circular(100), border: Border.all(color: Colors.white.withOpacity(0.14))), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.spa, size:12, color: Color(0xFF22C55E)), SizedBox(width:6), Text("LET'S GROW TOGETHER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing:1.1, fontSize:10))])),
                        const SizedBox(height: 12),
                        Text("Have a question?\nWe're all ears.", style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w900, height:1.05)),
                        const SizedBox(height: 10),
                        Text('Pure jaggery • Bulk orders • Partnerships • Our small team replies in hours.', style: TextStyle(color: Colors.white.withOpacity(0.72), height:1.5, fontSize: 13)),
                        const SizedBox(height: 16),
                        _ModernContactTile(icon: Icons.mail_outline_rounded, label: 'Email us', value: CompanyInfo.email, action: () async { final uri=Uri(scheme:'mailto', path:CompanyInfo.email); if(await canLaunchUrl(uri)) launchUrl(uri); }, isDark: true),
                        const SizedBox(height: 12),
                        _ModernContactTile(icon: Icons.phone_outlined, label: 'Call the farm', value: CompanyInfo.phonesDisplay, action: () async { final uri=Uri(scheme:'tel', path:CompanyInfo.phone1.replaceAll(' ', '')); if(await canLaunchUrl(uri)) launchUrl(uri); }, isDark: true),
                        const SizedBox(height: 12),
                        _ModernContactTile(icon: Icons.location_on_outlined, label: 'Find us', value: CompanyInfo.address, isDark: true),
                      ]),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark?const Color(0xFF14181B):Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark?const Color(0xFF23282D):const Color(0xFFE5E7EB)),
                      ),
                      child: Column(children: [
                        _InfoRow(icon: Icons.schedule_rounded, title: 'Open hours', subtitle: 'Mon–Sat 8am–6pm • Sun closed', isDark: isDark),
                        const SizedBox(height: 12),
                        Divider(color: isDark?const Color(0xFF23282D):const Color(0xFFE5E7EB), height:1),
                        const SizedBox(height: 12),
                        _InfoRow(icon: Icons.bolt_rounded, title: 'Response time', subtitle: 'Avg 2–3 hours on WhatsApp', isDark: isDark),
                        const SizedBox(height: 12),
                        Divider(color: isDark?const Color(0xFF23282D):const Color(0xFFE5E7EB), height:1),
                        const SizedBox(height: 12),
                        _InfoRow(icon: Icons.verified_rounded, title: 'Trusted', subtitle: '10k+ families • FSSAI • Lab tested', isDark: isDark),
                      ]),
                    ),
                  ]);
                  if(isNarrow) return Column(children: [formCard, const SizedBox(height:16), infoCol]);
                  return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 7, child: formCard), const SizedBox(width:16), Expanded(flex:5, child: infoCol)]);
                }),
                const SizedBox(height: 18),
                Container(
                  decoration: BoxDecoration(
                    color: isDark?const Color(0xFF14181B):Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isDark?const Color(0xFF23282D):const Color(0xFFE5E7EB)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark?0.14:0.06), blurRadius: 18, offset: const Offset(0,8))],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16,14,16,10),
                      child: Row(children: [
                        Container(width:32,height:32, decoration: BoxDecoration(color: const Color(0xFF00C805).withOpacity(0.12), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.map_rounded, color: Color(0xFF00C805), size:18)),
                        const SizedBox(width:10),
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Visit our unit', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: isDark?Colors.white:const Color(0xFF0B0E0F))),
                          Text(CompanyInfo.shortAddress, style: theme.textTheme.labelSmall?.copyWith(color: isDark?Colors.white60:const Color(0xFF6B7280))),
                        ]),
                        const Spacer(),
                        OutlinedButton.icon(onPressed: () async { final url=Uri.parse('https://www.google.com/maps/search/?api=1&query=${CompanyInfo.latitude},${CompanyInfo.longitude}'); if(await canLaunchUrl(url)) launchUrl(url, mode: LaunchMode.externalApplication); }, icon: const Icon(Icons.directions_rounded, size:16), label: const Text('Directions'), style: OutlinedButton.styleFrom(shape: const StadiumBorder(), side: BorderSide(color: isDark?const Color(0xFF23282D):const Color(0xFFE5E7EB)))),
                      ]),
                    ),
                    const _MapLocationCard(),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModernContactTile extends StatelessWidget {
  const _ModernContactTile({required this.icon, required this.label, required this.value, this.action, required this.isDark});
  final IconData icon; final String label; final String value; final VoidCallback? action; final bool isDark;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: action,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withOpacity(0.08))),
        child: Row(children: [
          Container(width:36,height:36, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: const Color(0xFF0B0E0F), size:18)),
          const SizedBox(width:12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11, letterSpacing:0.6, fontWeight:FontWeight.w700)),
            const SizedBox(height:2),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
          ])),
          if(action!=null) const Icon(Icons.arrow_outward_rounded, size:16, color: Colors.white54),
        ]),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.title, required this.subtitle, required this.isDark});
  final IconData icon; final String title; final String subtitle; final bool isDark;
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width:36,height:36, decoration: BoxDecoration(color: isDark? const Color(0xFF1A1F24): const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(10), border: Border.all(color: isDark?const Color(0xFF23282D):const Color(0xFFE5E7EB))), child: Icon(icon, size:18, color: isDark?Colors.white70:const Color(0xFF374151))),
      const SizedBox(width:12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize:13, color: isDark?Colors.white:const Color(0xFF0B0E0F))),
        Text(subtitle, style: TextStyle(fontSize:12, color: isDark?Colors.white60:const Color(0xFF6B7280))),
      ])),
    ]);
  }
}

class _ContactDetail extends StatelessWidget {
  const _ContactDetail({required this.icon, required this.label, required this.value});
  final IconData icon; final String label; final String value;
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width:45,height:45, decoration: BoxDecoration(color: const Color(0xFFE4EBDD), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: AppColors.green)),
      const SizedBox(width:13),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize:12)),
        const SizedBox(height:3),
        Text(value, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold))
      ]))
    ]);
  }
}

class _MapLocationCard extends StatefulWidget {
  const _MapLocationCard();
  @override
  State<_MapLocationCard> createState() => _MapLocationCardState();
}

class _MapLocationCardState extends State<_MapLocationCard> {
  static const _latitude = CompanyInfo.latitude;
  static const _longitude = CompanyInfo.longitude;
  static const _minZoom = 3.0;
  static const _maxZoom = 19.0;
  final _mapController = MapController();
  void _changeZoom(double amount) {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, (currentZoom + amount).clamp(_minZoom, _maxZoom));
  }
  void _resetZoom() => _mapController.move(const LatLng(_latitude, _longitude), 14);
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness==Brightness.dark;
    final size = MediaQuery.sizeOf(context);
    // Responsive map height: 45vh clamped 220..380, respects short landscape
    final double mapH = (size.height * 0.42).clamp(220, 380).toDouble();
    final bool isLandscapeShort = size.height < 500;
    final double effectiveH = isLandscapeShort ? 260 : mapH;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          height: effectiveH,
          width: double.infinity,
          child: Stack(children: [
            FlutterMap(
              mapController: _mapController,
              options: const MapOptions(initialCenter: LatLng(_latitude, _longitude), initialZoom: 14, minZoom: _minZoom, maxZoom: _maxZoom),
              children: [
                TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.hmenterprises.app'),
                MarkerLayer(markers: [
                  Marker(point: const LatLng(_latitude, _longitude), width: 150, height: 90, child: Column(children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal:11,vertical:7), decoration: BoxDecoration(color: isDark?const Color(0xFF1F2429):Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: const [BoxShadow(color: Color(0x24000000), blurRadius:8, offset: Offset(0,3))]), child: const Text('Hari Om Traders', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.ink, fontSize:12, fontWeight:FontWeight.bold))),
                    const Icon(Icons.location_on, color: AppColors.tomato, size:42),
                  ]))
                ]),
              ],
            ),
            Positioned(top:12,right:12, child: Column(children: [
              _MapButton(icon: Icons.add, tooltip: 'Zoom in', onPressed: ()=>_changeZoom(1)),
              _MapButton(icon: Icons.remove, tooltip: 'Zoom out', onPressed: ()=>_changeZoom(-1)),
              _MapButton(icon: Icons.center_focus_strong, tooltip: 'Reset', onPressed: _resetZoom),
            ])),
          ]),
        ),
        Padding(padding: const EdgeInsets.only(top:6,left:8,bottom:8), child: GestureDetector(onTap: ()=> launchUrl(Uri.parse('https://www.openstreetmap.org/copyright')), child: const Text('Map data © OpenStreetMap contributors', style: TextStyle(color: Colors.grey, fontSize:10, decoration: TextDecoration.underline)))),
      ]),
    );
  }
}

class _MapButton extends StatelessWidget {
  const _MapButton({required this.icon, required this.tooltip, required this.onPressed});
  final IconData icon; final String tooltip; final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) {
    return Material(color: Colors.white, child: IconButton(onPressed: onPressed, tooltip: tooltip, icon: Icon(icon), color: AppColors.green, visualDensity: VisualDensity.compact));
  }
}
