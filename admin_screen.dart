import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

import 'auth_service.dart';
import 'l10n/strings.dart';

const String _base = kIsWeb
    ? 'http://localhost:3000/api'
    : 'http://10.0.2.2:3000/api';

const _kBg      = Color(0xFF2E3449);
const _kSurface = Color(0xFF434A64);
const _kCard    = Color(0xFF394057);
const _kAccent  = Color(0xFFF5A623);
const _kGreen   = Color(0xFF00C9A7);
const _kRed     = Color(0xFFE05A7A);
const _kPurple  = Color(0xFF7B8FFF);
const _kBlue    = Color(0xFF4FC3F7);
const _kText    = Color(0xFFEEF0F6);
const _kMuted   = Color(0xFF6A7090);
const _kBorder  = Color(0x18FFFFFF);

String _formatDate(String? iso) {
  if (iso == null || iso.isEmpty) return '—';
  try {
    final dt = DateTime.parse(iso).toLocal();
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  } catch (_) {
    return iso;
  }
}

String _fmtRevenue(dynamic v) {
  final n = double.tryParse(v?.toString() ?? '0') ?? 0;
  if (n >= 1000000) return 'EGP ${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000)    return 'EGP ${(n / 1000).toStringAsFixed(1)}k';
  return 'EGP ${n.toStringAsFixed(0)}';
}

// ─────────────────────────────────────────────────────────────────────────────
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  Map<String, dynamic>? _stats;
  List _users       = [];
  List _rentals     = [];
  List _lockers     = [];
  List _locations   = [];
  List _lockerTypes = [];
  List _analytics        = [];
  List _locationStats    = [];
  List _recentActivity   = [];

  bool _loadingStats   = true;
  bool _loadingUsers   = true;
  bool _loadingRentals = true;
  bool _loadingLockers = true;

  String _userSearch         = '';
  String _userRoleFilter     = 'all';
  String _rentalStatusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) _onTabChanged(_tabCtrl.index);
    });
    _loadAll();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<String> _token() => AuthService.getToken();

  Future<Map<String, dynamic>> _get(String path) async {
    final token = await _token();
    final res = await http.get(Uri.parse('$_base$path'),
        headers: {'Authorization': 'Bearer $token'})
        .timeout(const Duration(seconds: 10));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _post(String path, Map body) async {
    final token = await _token();
    final res = await http.post(Uri.parse('$_base$path'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode(body))
        .timeout(const Duration(seconds: 10));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _put(String path, Map body) async {
    final token = await _token();
    final res = await http.put(Uri.parse('$_base$path'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode(body))
        .timeout(const Duration(seconds: 10));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _delete(String path) async {
    final token = await _token();
    final res = await http.delete(Uri.parse('$_base$path'),
        headers: {'Authorization': 'Bearer $token'})
        .timeout(const Duration(seconds: 10));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<void> _loadAll() async {
    await Future.wait(
        [_fetchStats(), _fetchUsers(), _fetchRentals(), _fetchLockers()]);
    _fetchLocations();
    _fetchLockerTypes();
    _fetchAnalytics();
    _fetchLocationPerformance();
    _fetchRecentActivity();
  }

  void _onTabChanged(int i) {
    if (i == 0 && _stats == null)    _fetchStats();
    if (i == 1 && _users.isEmpty)   _fetchUsers();
    if (i == 2 && _rentals.isEmpty) _fetchRentals();
    if (i == 3 && _lockers.isEmpty) _fetchLockers();
  }

  Future<void> _fetchStats() async {
    setState(() => _loadingStats = true);
    try {
      final body = await _get('/admin/stats');
      if (body['success'] == true && mounted) {
        setState(() {
          _stats = body['stats'];
          _loadingStats = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  Future<void> _fetchUsers() async {
    setState(() => _loadingUsers = true);
    try {
      final body = await _get('/admin/users');
      if (body['success'] == true && mounted) {
        setState(() {
          _users = body['users'] as List;
          _loadingUsers = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingUsers = false);
    }
  }

  Future<void> _fetchRentals() async {
    setState(() => _loadingRentals = true);
    try {
      final body = await _get('/admin/rentals');
      if (body['success'] == true && mounted) {
        setState(() {
          _rentals = body['rentals'] as List;
          _loadingRentals = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingRentals = false);
    }
  }

  Future<void> _fetchLockers() async {
    setState(() => _loadingLockers = true);
    try {
      final body = await _get('/admin/lockers');
      if (body['success'] == true && mounted) {
        setState(() {
          _lockers = body['lockers'] as List;
          _loadingLockers = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingLockers = false);
    }
  }

  Future<void> _fetchLocations() async {
    try {
      final body = await _get('/locations');
      if (body['success'] == true && mounted) {
        setState(() => _locations = body['locations'] as List);
      }
    } catch (_) {}
  }

  Future<void> _fetchLockerTypes() async {
    try {
      final body = await _get('/lockers/types');
      if (body['success'] == true && mounted) {
        setState(() => _lockerTypes = body['types'] as List);
      }
    } catch (_) {}
  }

  Future<void> _fetchAnalytics() async {
    try {
      final body = await _get('/admin/analytics');
      if (body['success'] == true && mounted) {
        setState(() => _analytics = body['analytics'] as List);
      }
    } catch (_) {}
  }

  Future<void> _fetchLocationPerformance() async {
    try {
      final body = await _get('/admin/location-performance');
      if (body['success'] == true && mounted) {
        setState(() => _locationStats = body['stats'] as List);
      }
    } catch (_) {}
  }

  Future<void> _fetchRecentActivity() async {
    try {
      final body = await _get('/admin/recent-activity');
      if (body['success'] == true && mounted) {
        setState(() => _recentActivity = body['activity'] as List);
      }
    } catch (_) {}
  }

  // ── FILTERED DATA ──────────────────────────────────────────
  List get _filteredUsers {
    var list = _users;
    if (_userRoleFilter != 'all') {
      list = list
          .where((u) =>
              (u['role'] as String? ?? 'customer') == _userRoleFilter)
          .toList();
    }
    if (_userSearch.isNotEmpty) {
      final q = _userSearch.toLowerCase();
      list = list.where((u) {
        final name  = (u['full_name'] as String? ?? '').toLowerCase();
        final email = (u['email'] as String? ?? '').toLowerCase();
        return name.contains(q) || email.contains(q);
      }).toList();
    }
    return list;
  }

  List get _filteredRentals {
    if (_rentalStatusFilter == 'all') return _rentals;
    return _rentals
        .where((r) => (r['status'] as String? ?? '') == _rentalStatusFilter)
        .toList();
  }

  int _rentalCount(String status) {
    if (status == 'all') return _rentals.length;
    return _rentals.where((r) => r['status'] == status).length;
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: GoogleFonts.syne(
              color: Colors.white, fontWeight: FontWeight.w600)),
      backgroundColor: error ? _kRed : _kGreen,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── FORCE CANCEL ────────────────────────────────────────────
  Future<void> _forceCancel(Map r) async {
    final ok = await _confirmDialog('Cancel Rental',
        'Force-cancel rental for ${r['full_name']}? Funds will be refunded.');
    if (!ok) return;
    try {
      final body =
          await _put('/admin/rentals/${r['rental_id']}/cancel', {});
      if (body['success'] == true) {
        _snack('Rental cancelled & refunded.');
        _fetchRentals();
        _fetchStats();
      } else {
        _snack(body['message'] ?? 'Failed.', error: true);
      }
    } catch (_) {
      _snack('Connection error.', error: true);
    }
  }

  // ── UPDATE LOCKER STATUS ─────────────────────────────────────
  Future<void> _changeLockerStatus(Map locker) async {
    const statuses = ['available', 'maintenance', 'out_of_service'];
    final chosen = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Set Status',
            style: GoogleFonts.syne(
                color: _kText, fontWeight: FontWeight.w700)),
        content: Column(
            mainAxisSize: MainAxisSize.min,
            children: statuses
                .map((s) => ListTile(
                      title: Text(s,
                          style: GoogleFonts.dmSans(color: _kText)),
                      leading: GestureDetector(
                        onTap: () => Navigator.pop(context, s),
                        child: Container(
                          width: 20, height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: locker['status'] == s ? _kAccent : _kMuted,
                              width: 2,
                            ),
                            color: locker['status'] == s
                                ? _kAccent.withValues(alpha: 0.2)
                                : Colors.transparent,
                          ),
                          child: locker['status'] == s
                              ? Center(child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: _kAccent, shape: BoxShape.circle)))
                              : null,
                        ),
                      ),
                      onTap: () => Navigator.pop(context, s),
                    ))
                .toList()),
      ),
    );
    if (chosen == null || chosen == locker['status']) return;
    try {
      final body = await _put(
          '/admin/lockers/${locker['locker_id']}/status',
          {'status': chosen});
      if (body['success'] == true) {
        _snack('Status updated.');
        _fetchLockers();
        _fetchStats();
      } else {
        _snack(body['message'] ?? 'Failed.', error: true);
      }
    } catch (_) {
      _snack('Connection error.', error: true);
    }
  }

  // ── DELETE LOCKER ────────────────────────────────────────────
  Future<void> _deleteLocker(Map locker) async {
    final ok = await _confirmDialog('Delete Locker',
        'Delete locker ${locker['locker_code']}? This cannot be undone.');
    if (!ok) return;
    try {
      final body =
          await _delete('/admin/lockers/${locker['locker_id']}');
      if (body['success'] == true) {
        _snack('Locker deleted.');
        _fetchLockers();
        _fetchStats();
        _fetchLocations();
      } else {
        _snack(body['message'] ?? 'Failed.', error: true);
      }
    } catch (_) {
      _snack('Connection error.', error: true);
    }
  }

  // ── ADD LOCATION ─────────────────────────────────────────────
  Future<void> _showAddLocation() async {
    final nameCtrl    = TextEditingController();
    final addressCtrl = TextEditingController();
    final cityCtrl    = TextEditingController();
    final latCtrl     = TextEditingController();
    final lngCtrl     = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _kCard,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Add Location',
            style: GoogleFonts.syne(
                color: _kText, fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          _AdminField(ctrl: nameCtrl, label: 'Name'),
          const SizedBox(height: 10),
          _AdminField(ctrl: addressCtrl, label: 'Address'),
          const SizedBox(height: 10),
          _AdminField(ctrl: cityCtrl, label: 'City'),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
                child: _AdminField(
                    ctrl: latCtrl,
                    label: 'Latitude',
                    type: TextInputType.number)),
            const SizedBox(width: 8),
            Expanded(
                child: _AdminField(
                    ctrl: lngCtrl,
                    label: 'Longitude',
                    type: TextInputType.number)),
          ]),
        ])),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: GoogleFonts.syne(color: _kMuted))),
          TextButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty ||
                  addressCtrl.text.isEmpty ||
                  cityCtrl.text.isEmpty) { return; }
              Navigator.pop(context);
              try {
                final body = await _post('/admin/locations', {
                  'name': nameCtrl.text.trim(),
                  'address': addressCtrl.text.trim(),
                  'city': cityCtrl.text.trim(),
                  'lat': double.tryParse(latCtrl.text) ?? 0,
                  'lng': double.tryParse(lngCtrl.text) ?? 0,
                });
                if (body['success'] == true) {
                  _snack('Location added.');
                  _fetchLocations();
                  _fetchStats();
                } else {
                  _snack(body['message'] ?? 'Failed.', error: true);
                }
              } catch (_) {
                _snack('Connection error.', error: true);
              }
            },
            child: Text('Add',
                style: GoogleFonts.syne(
                    color: _kAccent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── ADD LOCKER ────────────────────────────────────────────────
  Future<void> _showAddLocker() async {
    if (_locations.isEmpty || _lockerTypes.isEmpty) {
      _snack('Load locations and locker types first.', error: true);
      return;
    }
    final priceCtrl = TextEditingController();
    String? selectedLocationId =
        _locations.first['location_id']?.toString();
    String? selectedTypeId =
        _lockerTypes.first['locker_type_id']?.toString();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          backgroundColor: _kCard,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Text('Add Locker',
              style: GoogleFonts.syne(
                  color: _kText, fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            _DropdownField(
              label: 'Location',
              value: selectedLocationId,
              items: _locations
                  .map((l) => DropdownMenuItem(
                        value: l['location_id']?.toString(),
                        child: Text(l['name'] ?? '',
                            style: GoogleFonts.dmSans(
                                color: _kText, fontSize: 13)),
                      ))
                  .toList(),
              onChanged: (v) =>
                  setDlg(() => selectedLocationId = v),
            ),
            const SizedBox(height: 10),
            _DropdownField(
              label: 'Locker Type',
              value: selectedTypeId,
              items: _lockerTypes
                  .map((t) => DropdownMenuItem(
                        value: t['locker_type_id']?.toString(),
                        child: Text(
                            '${t['type_name']} - EGP ${t['price_per_hour']}/hr',
                            style: GoogleFonts.dmSans(
                                color: _kText, fontSize: 13)),
                      ))
                  .toList(),
              onChanged: (v) => setDlg(() => selectedTypeId = v),
            ),
            const SizedBox(height: 10),
            _AdminField(
              ctrl: priceCtrl,
              label: 'Custom Price/hr (optional)',
              type: const TextInputType.numberWithOptions(decimal: true),
            ),
          ])),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel',
                    style: GoogleFonts.syne(color: _kMuted))),
            TextButton(
              onPressed: () async {
                if (selectedLocationId == null ||
                    selectedTypeId == null) { return; }
                Navigator.pop(ctx);
                try {
                  final payload = <String, dynamic>{
                    'location_id':
                        int.parse(selectedLocationId!),
                    'locker_type_id':
                        int.parse(selectedTypeId!),
                  };
                  final customPrice =
                      double.tryParse(priceCtrl.text.trim());
                  if (customPrice != null && customPrice > 0) {
                    payload['price_per_hour'] = customPrice;
                  }
                  final body =
                      await _post('/admin/lockers', payload);
                  if (body['success'] == true) {
                    _snack(
                        'Locker added: ${body['locker']?['locker_code'] ?? ''}');
                    _fetchLockers();
                    _fetchStats();
                  } else {
                    _snack(body['message'] ?? 'Failed.',
                        error: true);
                  }
                } catch (_) {
                  _snack('Connection error.', error: true);
                }
              },
              child: Text('Add',
                  style: GoogleFonts.syne(
                      color: _kAccent,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  // ── ADD USER ─────────────────────────────────────────────────
  Future<void> _showAddUser() async {
    final nameCtrl  = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passCtrl  = TextEditingController();
    String selectedRole = 'customer';
    String? errorMsg;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          backgroundColor: _kCard,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Text('Add User',
              style: GoogleFonts.syne(
                  color: _kText, fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            _AdminField(ctrl: nameCtrl, label: 'Full Name'),
            const SizedBox(height: 10),
            _AdminField(
                ctrl: emailCtrl,
                label: 'Email',
                type: TextInputType.emailAddress),
            const SizedBox(height: 10),
            _AdminField(
                ctrl: phoneCtrl,
                label: 'Phone',
                type: TextInputType.phone),
            const SizedBox(height: 10),
            _AdminField(ctrl: passCtrl, label: 'Password'),
            const SizedBox(height: 10),
            _DropdownField(
              label: 'Role',
              value: selectedRole,
              items: [
                DropdownMenuItem(
                    value: 'customer',
                    child: Text('Customer',
                        style:
                            GoogleFonts.dmSans(color: _kText))),
                DropdownMenuItem(
                    value: 'admin',
                    child: Text('Admin',
                        style:
                            GoogleFonts.dmSans(color: _kText))),
                DropdownMenuItem(
                    value: 'technician',
                    child: Text('Technician',
                        style:
                            GoogleFonts.dmSans(color: _kText))),
              ],
              onChanged: (v) =>
                  setDlg(() => selectedRole = v ?? 'customer'),
            ),
            if (errorMsg != null) ...[
              const SizedBox(height: 8),
              Text(errorMsg!,
                  style:
                      GoogleFonts.dmSans(color: _kRed, fontSize: 12)),
            ],
          ])),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel',
                    style: GoogleFonts.syne(color: _kMuted))),
            TextButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty ||
                    emailCtrl.text.isEmpty ||
                    passCtrl.text.isEmpty) {
                  setDlg(() =>
                      errorMsg = 'Name, email and password are required.');
                  return;
                }
                Navigator.pop(ctx);
                try {
                  final body = await _post('/admin/users', {
                    'full_name': nameCtrl.text.trim(),
                    'email': emailCtrl.text.trim(),
                    'phone': phoneCtrl.text.trim(),
                    'password': passCtrl.text,
                    'role': selectedRole,
                  });
                  if (body['success'] == true) {
                    _snack('User added.');
                    _fetchUsers();
                    _fetchStats();
                  } else {
                    _snack(body['message'] ?? 'Failed.',
                        error: true);
                  }
                } catch (_) {
                  _snack('Connection error.', error: true);
                }
              },
              child: Text('Add',
                  style: GoogleFonts.syne(
                      color: _kAccent,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  // ── DELETE USER ───────────────────────────────────────────────
  Future<void> _deleteUser(Map user) async {
    final ok = await _confirmDialog(
        'Delete User',
        'Delete "${user['full_name']}"? This cannot be undone.');
    if (!ok) return;
    try {
      final body =
          await _delete('/admin/users/${user['user_id']}');
      if (body['success'] == true) {
        _snack('User deleted.');
        _fetchUsers();
        _fetchStats();
      } else {
        _snack(body['message'] ?? 'Failed.', error: true);
      }
    } catch (_) {
      _snack('Connection error.', error: true);
    }
  }

  // ── EDIT PRICING ─────────────────────────────────────────────
  Future<void> _editPricing(Map type) async {
    final hourCtrl = TextEditingController(
        text: type['price_per_hour']?.toString() ?? '');
    final dayCtrl = TextEditingController(
        text: type['price_per_day']?.toString() ?? '');
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _kCard,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('${type['type_name']} Pricing',
            style: GoogleFonts.syne(
                color: _kText, fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(type['dimensions'] ?? '',
              style: GoogleFonts.dmSans(color: _kMuted, fontSize: 12)),
          const SizedBox(height: 14),
          _AdminField(
              ctrl: hourCtrl,
              label: 'Price per Hour (EGP)',
              type: TextInputType.number),
          const SizedBox(height: 10),
          _AdminField(
              ctrl: dayCtrl,
              label: 'Price per Day (EGP)',
              type: TextInputType.number),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  Text('Cancel', style: GoogleFonts.syne(color: _kMuted))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final body = await _put(
                    '/admin/locker-types/${type['locker_type_id']}/price',
                    {
                      'price_per_hour':
                          double.tryParse(hourCtrl.text) ?? 0,
                      'price_per_day':
                          double.tryParse(dayCtrl.text) ?? 0,
                    });
                if (body['success'] == true) {
                  _snack('Pricing updated.');
                  _fetchLockerTypes();
                  _fetchLockers();
                } else {
                  _snack(body['message'] ?? 'Failed.', error: true);
                }
              } catch (_) {
                _snack('Connection error.', error: true);
              }
            },
            child: Text('Save',
                style: GoogleFonts.syne(
                    color: _kAccent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── DELETE LOCATION ───────────────────────────────────────────
  Future<void> _deleteLocation(Map loc) async {
    final ok = await _confirmDialog('Delete Location',
        'Delete "${loc['name']}"? All its lockers will also be removed.');
    if (!ok) return;
    try {
      final body =
          await _delete('/admin/locations/${loc['location_id']}');
      if (body['success'] == true) {
        _snack('Location deleted.');
        _fetchLocations();
        _fetchStats();
        _fetchLockers();
      } else {
        _snack(body['message'] ?? 'Failed.', error: true);
      }
    } catch (_) {
      _snack('Connection error.', error: true);
    }
  }

  Future<bool> _confirmDialog(String title, String content) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: _kCard,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Text(title,
                style: GoogleFonts.syne(
                    color: _kText, fontWeight: FontWeight.w700)),
            content: Text(content,
                style: GoogleFonts.dmSans(color: _kMuted)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('Cancel',
                      style: GoogleFonts.syne(color: _kMuted))),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text('Confirm',
                      style: GoogleFonts.syne(
                          color: _kRed, fontWeight: FontWeight.w700))),
            ],
          ),
        ) ??
        false;
  }

  Color _statusColor(String status) => switch (status) {
        'active'    => _kGreen,
        'completed' => _kBlue,
        'cancelled' => _kRed,
        'overdue'   => _kRed,
        _           => _kMuted,
      };

  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final s      = context.s;
    final top    = MediaQuery.of(context).padding.top;
    final bottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: _kBg,
      body: Column(children: [
        // ── HEADER ────────────────────────────────────────────
        Container(
          padding: EdgeInsets.fromLTRB(20, top + 16, 20, 0),
          decoration: const BoxDecoration(
              color: _kCard,
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(28))),
          child: Column(children: [
            Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                      color: const Color(0xFF4F5774),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: _kText, size: 16),
                ),
              ),
              const SizedBox(width: 14),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.adminPanelTitle,
                    style: GoogleFonts.syne(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _kText)),
                Text('SmartSecure Management',
                    style:
                        GoogleFonts.dmSans(fontSize: 11, color: _kMuted)),
              ]),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _kRed.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                      color: _kRed.withValues(alpha: 0.3)),
                ),
                child: Text('ADMIN',
                    style: GoogleFonts.syne(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: _kRed)),
              ),
            ]),
            const SizedBox(height: 16),
            TabBar(
              controller: _tabCtrl,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicator: BoxDecoration(
                  color: _kAccent,
                  borderRadius: BorderRadius.circular(99)),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              labelStyle: GoogleFonts.syne(
                  fontSize: 12, fontWeight: FontWeight.w700),
              unselectedLabelStyle:
                  GoogleFonts.syne(fontSize: 12),
              labelColor: _kBg,
              unselectedLabelColor: _kMuted,
              tabs: const [
                Tab(text: 'Dashboard'),
                Tab(text: 'Users'),
                Tab(text: 'Rentals'),
                Tab(text: 'Lockers'),
              ],
            ),
            const SizedBox(height: 4),
          ]),
        ),

        Expanded(
          child: TabBarView(controller: _tabCtrl, children: [
            _buildDashboard(bottom),
            _buildUsers(bottom),
            _buildRentals(bottom),
            _buildLockers(bottom),
          ]),
        ),
      ]),
    );
  }

  // ── DASHBOARD TAB ──────────────────────────────────────────
  Widget _buildDashboard(double bottom) {
    if (_loadingStats) {
      return const Center(
          child: CircularProgressIndicator(
              color: _kAccent, strokeWidth: 2));
    }
    final s = _stats ?? {};
    return RefreshIndicator(
      color: _kAccent,
      backgroundColor: _kCard,
      onRefresh: () => Future.wait([
        _fetchStats(), _fetchLocations(), _fetchAnalytics(),
        _fetchLocationPerformance(), _fetchRecentActivity(),
      ]),
      child: ListView(
        padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 20),
        children: [
          // ── 6-CARD STATS GRID ────────────────────────────
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              mainAxisExtent: 88,
            ),
            children: [
              _SmallStatCard(
                  label: 'Users',
                  value: '${s['total_users'] ?? 0}',
                  color: _kPurple,
                  icon: Icons.people_rounded),
              _SmallStatCard(
                  label: 'Active',
                  value: '${s['active_rentals'] ?? 0}',
                  color: _kGreen,
                  icon: Icons.lock_rounded),
              _SmallStatCard(
                  label: 'Free',
                  value: '${s['available_lockers'] ?? 0}',
                  color: _kAccent,
                  icon: Icons.lock_open_rounded),
              _SmallStatCard(
                  label: 'Revenue',
                  value: _fmtRevenue(s['total_revenue']),
                  color: _kGreen,
                  icon: Icons.payments_rounded),
              _SmallStatCard(
                  label: 'Locations',
                  value: '${s['total_locations'] ?? 0}',
                  color: _kBlue,
                  icon: Icons.location_on_rounded),
              _SmallStatCard(
                  label: 'Overdue',
                  value: '${s['overdue_rentals'] ?? 0}',
                  color: _kRed,
                  icon: Icons.warning_amber_rounded),
            ],
          ),

          const SizedBox(height: 16),

          // ── SYSTEM HEALTH ROW ─────────────────────────────
          _SystemHealthRow(stats: s),

          const SizedBox(height: 16),

          // ── REVENUE LINE CHART ────────────────────────────
          if (_analytics.isNotEmpty) ...[
            _RevenueLineChart(data: _analytics),
            const SizedBox(height: 14),
            _BookingsBarChart(data: _analytics),
            const SizedBox(height: 14),
          ] else ...[
            const _EmptyChartPlaceholder(
              icon: Icons.show_chart_rounded,
              label: 'Revenue & bookings charts will appear once rentals are recorded.',
            ),
            const SizedBox(height: 14),
          ],

          // ── LOCKER STATUS DONUT ───────────────────────────
          if (_lockers.isNotEmpty) ...[
            _LockerStatusChart(lockers: _lockers),
            const SizedBox(height: 14),
          ],

          // ── LOCATION PERFORMANCE ──────────────────────────
          if (_locationStats.isNotEmpty) ...[
            _LocationPerformanceChart(stats: _locationStats),
            const SizedBox(height: 14),
          ],

          // ── RECENT ACTIVITY ───────────────────────────────
          if (_recentActivity.isNotEmpty) ...[
            _RecentActivityFeed(activity: _recentActivity),
            const SizedBox(height: 24),
          ] else ...[
            const _EmptyChartPlaceholder(
              icon: Icons.history_rounded,
              label: 'No recent activity. Activity log will update in real time.',
            ),
            const SizedBox(height: 14),
          ],

          // ── LOCATIONS ─────────────────────────────────────
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Locations (${_locations.length})',
                    style: GoogleFonts.syne(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _kText)),
                GestureDetector(
                  onTap: _showAddLocation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [_kAccent, Color(0xFFE8920A)]),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.add_rounded,
                          color: _kBg, size: 16),
                      const SizedBox(width: 4),
                      Text('Add Location',
                          style: GoogleFonts.syne(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _kBg)),
                    ]),
                  ),
                ),
              ]),
          const SizedBox(height: 12),

          ..._locations.map((loc) => _LocationRow(
                location: loc as Map<String, dynamic>,
                onDelete: () => _deleteLocation(loc),
              )),

          if (_locations.isEmpty)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: _kSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _kBorder),
              ),
              child: Column(children: [
                const Icon(Icons.location_off_outlined,
                    color: _kMuted, size: 32),
                const SizedBox(height: 8),
                Text('No locations added yet',
                    style: GoogleFonts.syne(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _kMuted)),
                const SizedBox(height: 4),
                Text('Tap "Add Location" to create your first location.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(fontSize: 11, color: _kMuted)),
              ]),
            ),
        ],
      ),
    );
  }

  // ── USERS TAB ──────────────────────────────────────────────
  Widget _buildUsers(double bottom) {
    if (_loadingUsers) {
      return const Center(
          child: CircularProgressIndicator(
              color: _kAccent, strokeWidth: 2));
    }

    final roleCounts = <String, int>{
      'all': _users.length,
      'customer': 0,
      'admin': 0,
      'technician': 0,
    };
    for (final u in _users) {
      final r = u['role'] as String? ?? 'customer';
      roleCounts[r] = (roleCounts[r] ?? 0) + 1;
    }

    final filtered = _filteredUsers;

    return RefreshIndicator(
      color: _kAccent,
      backgroundColor: _kCard,
      onRefresh: _fetchUsers,
      child: ListView(
        padding: EdgeInsets.fromLTRB(20, 16, 20, bottom + 20),
        children: [
          // Header row
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Users (${_users.length})',
                style: GoogleFonts.syne(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _kText)),
            GestureDetector(
              onTap: _showAddUser,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [_kAccent, Color(0xFFE8920A)]),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.person_add_rounded,
                      color: _kBg, size: 15),
                  const SizedBox(width: 4),
                  Text('Add User',
                      style: GoogleFonts.syne(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _kBg)),
                ]),
              ),
            ),
          ]),
          const SizedBox(height: 12),

          // Role summary cards
          Row(children: [
            _RoleSummaryCard(
                label: 'Customers',
                count: roleCounts['customer'] ?? 0,
                color: _kGreen),
            const SizedBox(width: 8),
            _RoleSummaryCard(
                label: 'Admins',
                count: roleCounts['admin'] ?? 0,
                color: _kRed),
            const SizedBox(width: 8),
            _RoleSummaryCard(
                label: 'Technicians',
                count: roleCounts['technician'] ?? 0,
                color: _kPurple),
          ]),
          const SizedBox(height: 12),

          // Search bar
          Container(
            decoration: BoxDecoration(
                color: _kSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kBorder)),
            child: TextField(
              onChanged: (v) => setState(() => _userSearch = v),
              style: GoogleFonts.dmSans(color: _kText, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search by name or email…',
                hintStyle:
                    GoogleFonts.dmSans(color: _kMuted, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: _kMuted, size: 18),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Role filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['all', 'customer', 'admin', 'technician']
                  .map((role) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _userRoleFilter = role),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: _userRoleFilter == role
                                  ? _kAccent
                                  : _kSurface,
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(
                                  color: _userRoleFilter == role
                                      ? _kAccent
                                      : _kBorder),
                            ),
                            child: Text(
                              '${role[0].toUpperCase()}${role.substring(1)} (${roleCounts[role] ?? 0})',
                              style: GoogleFonts.syne(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _userRoleFilter == role
                                    ? _kBg
                                    : _kMuted,
                              ),
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),

          // User list
          ...filtered.map((user) => _UserRow(
                user: user as Map<String, dynamic>,
                onDelete: () => _deleteUser(user),
              )),

          if (filtered.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(children: [
                  const Icon(Icons.search_off_rounded,
                      color: _kMuted, size: 40),
                  const SizedBox(height: 8),
                  Text('No users match your search',
                      style: GoogleFonts.dmSans(
                          color: _kMuted, fontSize: 13)),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  // ── RENTALS TAB ────────────────────────────────────────────
  Widget _buildRentals(double bottom) {
    if (_loadingRentals) {
      return const Center(
          child: CircularProgressIndicator(
              color: _kAccent, strokeWidth: 2));
    }

    final filtered = _filteredRentals;

    return RefreshIndicator(
      color: _kAccent,
      backgroundColor: _kCard,
      onRefresh: _fetchRentals,
      child: ListView(
        padding: EdgeInsets.fromLTRB(20, 16, 20, bottom + 20),
        children: [
          Row(children: [
            Text('Rentals (${_rentals.length})',
                style: GoogleFonts.syne(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _kText)),
          ]),
          const SizedBox(height: 10),

          // Status filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                'all',
                'active',
                'completed',
                'cancelled',
                'overdue',
              ]
                  .map((status) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(
                              () => _rentalStatusFilter = status),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: _rentalStatusFilter == status
                                  ? _statusColor(status)
                                  : _kSurface,
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(
                                  color: _rentalStatusFilter == status
                                      ? _statusColor(status)
                                      : _kBorder),
                            ),
                            child: Text(
                              '${status[0].toUpperCase()}${status.substring(1)} (${_rentalCount(status)})',
                              style: GoogleFonts.syne(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _rentalStatusFilter == status
                                    ? _kBg
                                    : _kMuted,
                              ),
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),

          ...filtered.map((r) {
            final rental = r as Map<String, dynamic>;
            return _AdminRentalRow(
              rental: rental,
              onCancel: rental['status'] == 'active'
                  ? () => _forceCancel(rental)
                  : null,
            );
          }),

          if (filtered.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(children: [
                  const Icon(Icons.inventory_2_outlined,
                      color: _kMuted, size: 40),
                  const SizedBox(height: 8),
                  Text('No rentals in this category',
                      style: GoogleFonts.dmSans(
                          color: _kMuted, fontSize: 13)),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  // ── LOCKERS TAB ────────────────────────────────────────────
  Widget _buildLockers(double bottom) {
    if (_loadingLockers) {
      return const Center(
          child: CircularProgressIndicator(
              color: _kAccent, strokeWidth: 2));
    }

    final statusCounts = <String, int>{
      'available': 0,
      'occupied': 0,
      'maintenance': 0,
      'out_of_service': 0,
    };
    for (final lk in _lockers) {
      final s = lk['status'] as String? ?? 'available';
      statusCounts[s] = (statusCounts[s] ?? 0) + 1;
    }

    return RefreshIndicator(
      color: _kAccent,
      backgroundColor: _kCard,
      onRefresh: _fetchLockers,
      child: ListView(
        padding: EdgeInsets.fromLTRB(20, 16, 20, bottom + 20),
        children: [
          // Status summary strip
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
                color: _kSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _kBorder)),
            child: Row(children: [
              _LockerStatusPill(
                  label: 'Free',
                  count: statusCounts['available'] ?? 0,
                  color: _kGreen),
              _LockerStatusPill(
                  label: 'In Use',
                  count: statusCounts['occupied'] ?? 0,
                  color: _kAccent),
              _LockerStatusPill(
                  label: 'Maint.',
                  count: statusCounts['maintenance'] ?? 0,
                  color: _kPurple),
              _LockerStatusPill(
                  label: 'Offline',
                  count: statusCounts['out_of_service'] ?? 0,
                  color: _kRed),
            ]),
          ),
          const SizedBox(height: 16),

          // Pricing table
          if (_lockerTypes.isNotEmpty) ...[
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Size Pricing',
                      style: GoogleFonts.syne(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _kText)),
                  Text('tap row to edit',
                      style:
                          GoogleFonts.dmSans(fontSize: 11, color: _kMuted)),
                ]),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                  color: _kSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _kBorder)),
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  child: Row(children: [
                    SizedBox(
                        width: 38,
                        child: Text('Size',
                            style: GoogleFonts.syne(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _kMuted))),
                    Expanded(
                        child: Text('Dimensions',
                            style: GoogleFonts.syne(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _kMuted))),
                    SizedBox(
                        width: 68,
                        child: Text('/hr',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.syne(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _kMuted))),
                    SizedBox(
                        width: 68,
                        child: Text('/day',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.syne(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _kMuted))),
                    const SizedBox(width: 24),
                  ]),
                ),
                Container(height: 1, color: _kBorder),
                ..._lockerTypes.asMap().entries.map((e) {
                  final t = e.value as Map<String, dynamic>;
                  final isLast = e.key == _lockerTypes.length - 1;
                  return Column(children: [
                    GestureDetector(
                      onTap: () => _editPricing(t),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 11),
                        child: Row(children: [
                          SizedBox(
                              width: 38,
                              child: Text(t['type_name'] ?? '',
                                  style: GoogleFonts.syne(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: _kAccent))),
                          Expanded(
                              child: Text(t['dimensions'] ?? '',
                                  style: GoogleFonts.dmSans(
                                      fontSize: 11, color: _kMuted))),
                          SizedBox(
                              width: 68,
                              child: Text('EGP ${t['price_per_hour']}',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.syne(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: _kText))),
                          SizedBox(
                              width: 68,
                              child: Text('EGP ${t['price_per_day']}',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.syne(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: _kText))),
                          const Icon(Icons.edit_outlined,
                              size: 14, color: _kMuted),
                        ]),
                      ),
                    ),
                    if (!isLast) Container(height: 1, color: _kBorder),
                  ]);
                }),
              ]),
            ),
            const SizedBox(height: 20),
          ],

          // Add Locker button
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            GestureDetector(
              onTap: _showAddLocker,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [_kAccent, Color(0xFFE8920A)]),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.add_rounded, color: _kBg, size: 16),
                  const SizedBox(width: 4),
                  Text('Add Locker',
                      style: GoogleFonts.syne(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _kBg)),
                ]),
              ),
            ),
          ]),
          const SizedBox(height: 12),

          ..._lockers.map((lk) => _AdminLockerRow(
                locker: lk as Map<String, dynamic>,
                onChangeStatus: () => _changeLockerStatus(lk),
                onDelete: () => _deleteLocker(lk),
              )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ── SMALL STAT CARD (3-column grid) ──────────────────────────
class _SmallStatCard extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  const _SmallStatCard(
      {required this.label,
      required this.value,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 15),
              ),
              const Spacer(),
              Container(
                width: 6,
                height: 6,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(value,
                  style: GoogleFonts.syne(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _kText),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              Text(label,
                  style: GoogleFonts.dmSans(fontSize: 10, color: _kMuted),
                  overflow: TextOverflow.ellipsis),
            ]),
          ],
        ),
      );
}

// ── LOCATION ROW ─────────────────────────────────────────────
class _LocationRow extends StatelessWidget {
  final Map<String, dynamic> location;
  final VoidCallback onDelete;
  const _LocationRow({required this.location, required this.onDelete});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kBorder)),
        child: Row(children: [
          const Icon(Icons.location_on_rounded,
              color: _kAccent, size: 18),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(location['name'] ?? '',
                    style: GoogleFonts.syne(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _kText)),
                Text(
                    '${location['city'] ?? ''}${location['address'] != null ? '  ·  ${location['address']}' : ''}',
                    style: GoogleFonts.dmSans(
                        fontSize: 11, color: _kMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(
                '${location['available_lockers'] ?? 0}/${location['total_lockers'] ?? 0}',
                style: GoogleFonts.syne(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _kGreen)),
            Text('free/total',
                style:
                    GoogleFonts.dmSans(fontSize: 9, color: _kMuted)),
          ]),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onDelete,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                  color: _kRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.delete_outline_rounded,
                  color: _kRed, size: 16),
            ),
          ),
        ]),
      );
}

// ── USER ROW ──────────────────────────────────────────────────
class _UserRow extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback? onDelete;
  const _UserRow({required this.user, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final role  = user['role'] as String? ?? 'customer';
    final color = role == 'admin'
        ? _kRed
        : role == 'technician'
            ? _kPurple
            : _kGreen;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBorder)),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle),
          child: Center(
              child: Text(
            (user['full_name'] as String? ?? 'U').isNotEmpty
                ? (user['full_name'] as String)[0].toUpperCase()
                : 'U',
            style: GoogleFonts.syne(
                fontSize: 18, fontWeight: FontWeight.w800, color: color),
          )),
        ),
        const SizedBox(width: 12),
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(user['full_name'] ?? '',
                  style: GoogleFonts.syne(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _kText)),
              Text(user['email'] ?? '',
                  style:
                      GoogleFonts.dmSans(fontSize: 11, color: _kMuted)),
              const SizedBox(height: 3),
              Row(children: [
                const Icon(Icons.lock_outline_rounded,
                    size: 10, color: _kMuted),
                const SizedBox(width: 3),
                Text(
                    '${user['total_rentals'] ?? 0} rentals  ·  EGP ${double.tryParse(user['wallet_balance']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0.00'} wallet',
                    style: GoogleFonts.dmSans(
                        fontSize: 10,
                        color: _kMuted.withValues(alpha: 0.8))),
              ]),
              if (user['created_at'] != null) ...[
                const SizedBox(height: 2),
                Row(children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 10, color: _kMuted),
                  const SizedBox(width: 3),
                  Text('Joined ${_formatDate(user['created_at'] as String?)}',
                      style: GoogleFonts.dmSans(
                          fontSize: 10,
                          color: _kMuted.withValues(alpha: 0.6))),
                ]),
              ],
            ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: color.withValues(alpha: 0.3))),
            child: Text(role.toUpperCase(),
                style: GoogleFonts.syne(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ),
          if (onDelete != null) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: onDelete,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                    color: _kRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.delete_outline_rounded,
                    color: _kRed, size: 14),
              ),
            ),
          ],
        ]),
      ]),
    );
  }
}

// ── ADMIN RENTAL ROW ──────────────────────────────────────────
class _AdminRentalRow extends StatelessWidget {
  final Map<String, dynamic> rental;
  final VoidCallback? onCancel;
  const _AdminRentalRow({required this.rental, this.onCancel});

  @override
  Widget build(BuildContext context) {
    final status = rental['status'] as String? ?? '';
    final color  = {'active': _kGreen, 'cancelled': _kRed, 'overdue': _kRed, 'completed': _kBlue}[status] ?? _kMuted;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.15))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
            Text(rental['full_name'] ?? '',
                style: GoogleFonts.syne(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _kText)),
            Text(rental['email'] ?? '',
                style: GoogleFonts.dmSans(
                    fontSize: 11, color: _kMuted)),
          ])),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: color.withValues(alpha: 0.3))),
            child: Text(
                status.isNotEmpty
                    ? status[0].toUpperCase() + status.substring(1)
                    : '',
                style: GoogleFonts.syne(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          const Icon(Icons.location_on_rounded,
              color: _kMuted, size: 13),
          const SizedBox(width: 4),
          Expanded(
              child: Text(
                  '${rental['location_name']} · ${rental['locker_code']}${rental['locker_size'] != null ? ' (${rental['locker_size']})' : ''}',
                  style:
                      GoogleFonts.dmSans(fontSize: 12, color: _kMuted))),
          Text(
              'EGP ${double.tryParse(rental['total_amount']?.toString() ?? '0')?.toStringAsFixed(2) ?? '—'}',
              style: GoogleFonts.syne(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _kAccent)),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          const Icon(Icons.schedule_rounded, color: _kMuted, size: 11),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              '${_formatDate(rental['start_time'] as String?)} → ${rental['end_time'] != null ? _formatDate(rental['end_time'] as String?) : 'ongoing'}',
              style: GoogleFonts.dmSans(
                  fontSize: 10,
                  color: _kMuted.withValues(alpha: 0.7)),
            ),
          ),
        ]),
        if (onCancel != null) ...[
          const SizedBox(height: 10),
          GestureDetector(
            onTap: onCancel,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                  color: _kRed.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: _kRed.withValues(alpha: 0.3))),
              child: Center(
                  child: Text('Force Cancel & Refund',
                      style: GoogleFonts.syne(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _kRed))),
            ),
          ),
        ],
      ]),
    );
  }
}

// ── ADMIN LOCKER ROW ──────────────────────────────────────────
class _AdminLockerRow extends StatelessWidget {
  final Map<String, dynamic> locker;
  final VoidCallback onChangeStatus, onDelete;
  const _AdminLockerRow(
      {required this.locker,
      required this.onChangeStatus,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final status = locker['status'] as String? ?? '';
    final color  = {
          'available':    _kGreen,
          'occupied':     _kAccent,
          'maintenance':  _kPurple
        }[status] ??
        _kRed;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBorder)),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12)),
          child: Center(
              child: Text(
            _sizeInitial(locker['type_name'] as String? ?? '?'),
            style: GoogleFonts.syne(
                fontSize: 16, fontWeight: FontWeight.w800, color: color),
          )),
        ),
        const SizedBox(width: 12),
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
          Text('${locker['locker_code']} · ${locker['type_name']}',
              style: GoogleFonts.syne(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _kText)),
          Text(locker['location_name'] ?? '',
              style: GoogleFonts.dmSans(fontSize: 11, color: _kMuted)),
          const SizedBox(height: 2),
          Row(children: [
            Text('EGP ${locker['price_per_hour']}/hr',
                style: GoogleFonts.dmSans(
                    fontSize: 10, color: _kMuted.withValues(alpha: 0.7))),
            if (locker['dimensions'] != null) ...[
              Text('  ·  ',
                  style: GoogleFonts.dmSans(
                      fontSize: 10, color: _kMuted.withValues(alpha: 0.5))),
              Text(locker['dimensions'],
                  style: GoogleFonts.dmSans(
                      fontSize: 10, color: _kMuted.withValues(alpha: 0.7))),
            ],
          ]),
          if (locker['last_maintenance'] != null)
            Text(
                'Last maint: ${_formatDate(locker['last_maintenance'] as String?)}',
                style: GoogleFonts.dmSans(
                    fontSize: 9, color: _kMuted.withValues(alpha: 0.5))),
        ])),
        Column(children: [
          GestureDetector(
            onTap: onChangeStatus,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(99),
                  border:
                      Border.all(color: color.withValues(alpha: 0.3))),
              child: Text(status,
                  style: GoogleFonts.syne(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: color)),
            ),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: onDelete,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                  color: _kRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.delete_outline_rounded,
                  color: _kRed, size: 14),
            ),
          ),
        ]),
      ]),
    );
  }

  String _sizeInitial(String s) {
    final lower = s.toLowerCase();
    if (lower.contains('small'))  return 'S';
    if (lower.contains('medium')) return 'M';
    if (lower.contains('large'))  return 'L';
    if (lower.contains('extra'))  return 'XL';
    return s.isNotEmpty ? s[0].toUpperCase() : '?';
  }
}

// ── ROLE SUMMARY CARD ─────────────────────────────────────────
class _RoleSummaryCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _RoleSummaryCard(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$count',
                    style: GoogleFonts.syne(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: color)),
                Text(label,
                    style: GoogleFonts.dmSans(
                        fontSize: 10, color: _kMuted)),
              ]),
        ),
      );
}

// ── SYSTEM HEALTH ROW ─────────────────────────────────────────
class _SystemHealthRow extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _SystemHealthRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    final total     = (stats['total_lockers']     as num?)?.toInt() ?? 0;
    final available = (stats['available_lockers']  as num?)?.toInt() ?? 0;
    final occupied  = (stats['active_rentals']     as num?)?.toInt() ?? 0;
    final overdue   = (stats['overdue_rentals']    as num?)?.toInt() ?? 0;
    final maintenance = total - available - occupied;
    final pct = total > 0 ? (available / total * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.monitor_heart_outlined, color: _kGreen, size: 15),
          const SizedBox(width: 6),
          Text('System Health',
              style: GoogleFonts.syne(
                  fontSize: 12, fontWeight: FontWeight.w700, color: _kText)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _kGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('$pct% free',
                style: GoogleFonts.syne(fontSize: 10, color: _kGreen, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 6,
            child: Row(children: [
              if (total > 0) ...[
                Flexible(flex: available,    child: Container(color: _kGreen)),
                Flexible(flex: occupied,     child: Container(color: _kAccent)),
                Flexible(flex: overdue > 0 ? overdue : 0, child: Container(color: _kRed)),
                Flexible(flex: maintenance > 0 ? maintenance : 0, child: Container(color: _kPurple)),
                if (total - available - occupied - (overdue > 0 ? overdue : 0) - (maintenance > 0 ? maintenance : 0) > 0)
                  Flexible(flex: total - available - occupied - (overdue > 0 ? overdue : 0) - (maintenance > 0 ? maintenance : 0), child: Container(color: _kMuted)),
              ] else
                Expanded(child: Container(color: _kMuted)),
            ]),
          ),
        ),
        const SizedBox(height: 8),
        Row(children: [
          _HealthDot(color: _kGreen,  label: 'Free ($available)'),
          const SizedBox(width: 12),
          _HealthDot(color: _kAccent, label: 'In use ($occupied)'),
          const SizedBox(width: 12),
          if (overdue > 0) ...[
            _HealthDot(color: _kRed, label: 'Overdue ($overdue)'),
            const SizedBox(width: 12),
          ],
          if (maintenance > 0)
            _HealthDot(color: _kPurple, label: 'Maint. ($maintenance)'),
        ]),
      ]),
    );
  }
}

class _HealthDot extends StatelessWidget {
  final Color color;
  final String label;
  const _HealthDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.dmSans(fontSize: 10, color: _kMuted)),
      ]);
}

// ── EMPTY CHART PLACEHOLDER ───────────────────────────────────
class _EmptyChartPlaceholder extends StatelessWidget {
  final IconData icon;
  final String label;
  const _EmptyChartPlaceholder({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBorder),
        ),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _kMuted.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _kMuted, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: GoogleFonts.dmSans(fontSize: 12, color: _kMuted)),
          ),
        ]),
      );
}

// ── LOCKER STATUS PILL ────────────────────────────────────────
class _LockerStatusPill extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _LockerStatusPill(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Text('$count',
              style: GoogleFonts.syne(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: color)),
          Text(label,
              style: GoogleFonts.dmSans(fontSize: 10, color: _kMuted),
              textAlign: TextAlign.center),
        ]),
      );
}

// ── HELPER WIDGETS ────────────────────────────────────────────
class _AdminField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final TextInputType type;
  const _AdminField(
      {required this.ctrl,
      required this.label,
      this.type = TextInputType.text});

  @override
  Widget build(BuildContext context) => TextField(
        controller: ctrl,
        keyboardType: type,
        style: GoogleFonts.dmSans(color: _kText, fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.dmSans(color: _kMuted, fontSize: 12),
          filled: true,
          fillColor: const Color(0xFF4F5774),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kBorder)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kBorder)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: _kAccent, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 12),
        ),
      );
}

class _DropdownField extends StatelessWidget {
  final String label;
  final String? value;
  final List<DropdownMenuItem<String>> items;
  final Function(String?) onChanged;
  const _DropdownField(
      {required this.label,
      required this.value,
      required this.items,
      required this.onChanged});

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
        initialValue: value,
        items: items,
        onChanged: onChanged,
        dropdownColor: _kCard,
        style: GoogleFonts.dmSans(color: _kText, fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.dmSans(color: _kMuted, fontSize: 12),
          filled: true,
          fillColor: const Color(0xFF4F5774),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kBorder)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kBorder)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: _kAccent, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 12),
        ),
      );
}

// ─────────────────────────────────────────────────────────────
// ── REVENUE LINE CHART ────────────────────────────────────────
class _RevenueLineChart extends StatelessWidget {
  final List data;
  const _RevenueLineChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final spots = data.asMap().entries.map((e) {
      final rev =
          double.tryParse(e.value['revenue']?.toString() ?? '0') ?? 0;
      return FlSpot(e.key.toDouble(), rev);
    }).toList();

    final maxY = spots.fold<double>(1.0, (m, s) => s.y > m ? s.y : m) * 1.25;
    final days = data
        .map((d) => d['day'] as String? ?? '')
        .toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 16, 12),
      decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _kBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Row(children: [
            const Icon(Icons.show_chart_rounded,
                color: _kAccent, size: 16),
            const SizedBox(width: 6),
            Text('Revenue Trend',
                style: GoogleFonts.syne(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _kText)),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: _kAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6)),
              child: Text('7 Days',
                  style:
                      GoogleFonts.dmSans(fontSize: 10, color: _kAccent)),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 150,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY / 4,
                getDrawingHorizontalLine: (_) => const FlLine(
                    color: Color(0x12FFFFFF), strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 46,
                    getTitlesWidget: (v, _) => v == 0
                        ? const SizedBox()
                        : Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Text(
                              v >= 1000
                                  ? '${(v / 1000).toStringAsFixed(1)}k'
                                  : v.toInt().toString(),
                              style: GoogleFonts.dmSans(
                                  fontSize: 9, color: _kMuted),
                              textAlign: TextAlign.right,
                            ),
                          ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i < 0 || i >= days.length) {
                        return const SizedBox();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(days[i],
                            style: GoogleFonts.dmSans(
                                fontSize: 9, color: _kMuted)),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: (data.length - 1).toDouble().clamp(1.0, double.infinity),
              minY: 0,
              maxY: maxY,
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => _kCard,
                  getTooltipItems: (spots) => spots
                      .map((s) => LineTooltipItem(
                            'EGP ${s.y.toStringAsFixed(0)}',
                            GoogleFonts.syne(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _kAccent),
                          ))
                      .toList(),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.35,
                  color: _kAccent,
                  barWidth: 2.5,
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        _kAccent.withValues(alpha: 0.28),
                        _kAccent.withValues(alpha: 0.02),
                      ],
                    ),
                  ),
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (_, __, ___, ____) =>
                        FlDotCirclePainter(
                      radius: 3,
                      color: _kAccent,
                      strokeWidth: 2,
                      strokeColor: _kBg,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

// ── BOOKINGS BAR CHART ────────────────────────────────────────
class _BookingsBarChart extends StatelessWidget {
  final List data;
  const _BookingsBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxY = data.fold<double>(1.0, (m, d) {
          final b =
              double.tryParse(d['bookings']?.toString() ?? '0') ?? 0;
          return b > m ? b : m;
        }) *
        1.35;
    final days = data.map((d) => d['day'] as String? ?? '').toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 16, 12),
      decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _kBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Row(children: [
            const Icon(Icons.bar_chart_rounded,
                color: _kPurple, size: 16),
            const SizedBox(width: 6),
            Text('Daily Bookings',
                style: GoogleFonts.syne(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _kText)),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: _kPurple.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6)),
              child: Text('7 Days',
                  style:
                      GoogleFonts.dmSans(fontSize: 10, color: _kPurple)),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => _kCard,
                  getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                    '${rod.toY.toInt()} bookings',
                    GoogleFonts.syne(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _kPurple),
                  ),
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i < 0 || i >= days.length) {
                        return const SizedBox();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(days[i],
                            style: GoogleFonts.dmSans(
                                fontSize: 9, color: _kMuted)),
                      );
                    },
                  ),
                ),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: data.asMap().entries.map((e) {
                final b =
                    double.tryParse(e.value['bookings']?.toString() ?? '0') ??
                        0;
                return BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: b,
                      gradient: const LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Color(0xFF5B6EFF), _kPurple],
                      ),
                      width: 18,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6)),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── LOCKER STATUS DONUT CHART ─────────────────────────────────
class _LockerStatusChart extends StatefulWidget {
  final List lockers;
  const _LockerStatusChart({required this.lockers});

  @override
  State<_LockerStatusChart> createState() => _LockerStatusChartState();
}

class _LockerStatusChartState extends State<_LockerStatusChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final lk in widget.lockers) {
      final s = lk['status'] as String? ?? 'available';
      counts[s] = (counts[s] ?? 0) + 1;
    }
    final total = widget.lockers.length;

    final items = [
      ('Available', 'available',      _kGreen),
      ('Occupied',  'occupied',       _kAccent),
      ('Maint.',    'maintenance',    _kPurple),
      ('Offline',   'out_of_service', _kRed),
    ];

    final sections = <PieChartSectionData>[];
    int si = 0;
    for (int i = 0; i < items.length; i++) {
      final (_, key, color) = items[i];
      final count = counts[key] ?? 0;
      if (count == 0) { si++; continue; }
      final isTouched = _touchedIndex == si;
      sections.add(PieChartSectionData(
        color: color,
        value: count.toDouble(),
        title: isTouched ? '$count' : '',
        radius: isTouched ? 58 : 50,
        titleStyle: GoogleFonts.syne(
            fontSize: 12, fontWeight: FontWeight.w800, color: _kBg),
      ));
      si++;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _kBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.donut_large_rounded,
              color: _kGreen, size: 16),
          const SizedBox(width: 6),
          Text('Locker Utilization',
              style: GoogleFonts.syne(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _kText)),
          const Spacer(),
          Text('$total total',
              style: GoogleFonts.dmSans(fontSize: 11, color: _kMuted)),
        ]),
        const SizedBox(height: 16),
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          SizedBox(
            height: 150,
            width: 150,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 42,
                sectionsSpace: 2,
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          response?.touchedSection == null) {
                        _touchedIndex = -1;
                      } else {
                        _touchedIndex = response!
                            .touchedSection!.touchedSectionIndex;
                      }
                    });
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: items.map((item) {
                final (label, key, color) = item;
                final count = counts[key] ?? 0;
                final pct = total > 0
                    ? (count / total * 100).round()
                    : 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                          color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(label,
                            style: GoogleFonts.dmSans(
                                fontSize: 12, color: _kMuted))),
                    Text('$count',
                        style: GoogleFonts.syne(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _kText)),
                    Text('  $pct%',
                        style: GoogleFonts.dmSans(
                            fontSize: 10, color: _kMuted)),
                  ]),
                );
              }).toList(),
            ),
          ),
        ]),
      ]),
    );
  }
}

// ── LOCATION PERFORMANCE CHART ────────────────────────────────
class _LocationPerformanceChart extends StatelessWidget {
  final List stats;
  const _LocationPerformanceChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final maxRevenue = stats.fold<double>(1.0, (m, s) {
      final rev = double.tryParse(s['revenue']?.toString() ?? '0') ?? 0;
      return rev > m ? rev : m;
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.leaderboard_rounded, color: _kBlue, size: 16),
          const SizedBox(width: 6),
          Text('Top Locations by Revenue',
              style: GoogleFonts.syne(
                  fontSize: 13, fontWeight: FontWeight.w700, color: _kText)),
        ]),
        const SizedBox(height: 16),
        ...stats.map((s) {
          final rev   = double.tryParse(s['revenue']?.toString() ?? '0') ?? 0;
          final count = s['count'] as int? ?? 0;
          final frac  = (rev / maxRevenue).clamp(0.0, 1.0);
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(s['name'] ?? '—',
                      style: GoogleFonts.syne(
                          fontSize: 12, fontWeight: FontWeight.w700, color: _kText),
                      overflow: TextOverflow.ellipsis),
                ),
                Text('$count rentals',
                    style: GoogleFonts.dmSans(fontSize: 10, color: _kMuted)),
                const SizedBox(width: 8),
                Text(_fmtRevenue(s['revenue']),
                    style: GoogleFonts.syne(
                        fontSize: 11, fontWeight: FontWeight.w700, color: _kBlue)),
              ]),
              const SizedBox(height: 6),
              Stack(children: [
                Container(
                    height: 6,
                    decoration: BoxDecoration(
                        color: _kCard, borderRadius: BorderRadius.circular(99))),
                FractionallySizedBox(
                  widthFactor: frac,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [_kBlue, Color(0xFF29B6F6)]),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              ]),
            ]),
          );
        }),
      ]),
    );
  }
}

// ── RECENT ACTIVITY FEED ──────────────────────────────────────
class _RecentActivityFeed extends StatelessWidget {
  final List activity;
  const _RecentActivityFeed({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.history_rounded, color: _kAccent, size: 16),
          const SizedBox(width: 6),
          Text('Recent Rentals',
              style: GoogleFonts.syne(
                  fontSize: 13, fontWeight: FontWeight.w700, color: _kText)),
          const Spacer(),
          Text('Latest ${activity.length}',
              style: GoogleFonts.dmSans(fontSize: 11, color: _kMuted)),
        ]),
        const SizedBox(height: 12),
        ...activity.map((a) {
          final status = a['status'] as String? ?? '';
          final color  = {
            'active':    _kGreen,
            'completed': _kBlue,
            'cancelled': _kRed,
            'overdue':   _kRed,
          }[status] ?? _kMuted;
          final amount =
              double.tryParse(a['total_amount']?.toString() ?? '0') ?? 0;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: _kCard, borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(a['user_name'] ?? '—',
                      style: GoogleFonts.syne(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _kText)),
                  Text(
                      '${a['location_name'] ?? '—'}  ·  ${a['locker_code'] ?? '—'}',
                      style: GoogleFonts.dmSans(fontSize: 10, color: _kMuted)),
                ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('EGP ${amount.toStringAsFixed(0)}',
                    style: GoogleFonts.syne(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _kAccent)),
                Text(_formatDate(a['start_time'] as String?),
                    style: GoogleFonts.dmSans(fontSize: 9, color: _kMuted)),
              ]),
            ]),
          );
        }),
      ]),
    );
  }
}
