import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'explore_menu.dart';

import 'main.dart' show routeObserver;

import 'unlock_method_sheet.dart';
import 'directions.dart';
import 'airport_directions_screen.dart';
import 'railway_directions_screen.dart';
import 'l10n/strings.dart';

const String baseUrl = kIsWeb
    ? 'http://localhost:3000/api'
    : 'http://10.0.2.2:3000/api';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin, RouteAware {
  final _scaffoldKey   = GlobalKey<ScaffoldState>();
  final _mapController = MapController();
  final _searchCtrl    = TextEditingController();

  bool   _loading      = true;
  bool   _mapReady     = false;
  bool   _searching    = false;
  String? _error;
  Map<String, dynamic>? _data;
  List  _allLocations  = [];
  List  _filteredLocs  = [];
  int   _selectedIdx   = 0;
  Map<String, dynamic>? _selectedLocation;
  String _selectedCity = 'All';

  // Periodic refresh
  Timer? _refreshTimer;

  // User real location
  LatLng? _userPosition;
  double  _userHeading = 0;

  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;
  late AnimationController _detailCtrl;
  late Animation<Offset>   _detailAnim;
  late AnimationController _pulseCtrl;
  Animation<double>?       _pulseAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim  = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _detailCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _detailAnim = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _detailCtrl, curve: Curves.easeOutCubic));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.06)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _searchCtrl.addListener(_onSearch);
    _fetchHomeData();
    _startLocationTracking();
    _startRefreshTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) routeObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _refreshTimer?.cancel();
    _fadeCtrl.dispose();
    _detailCtrl.dispose();
    _pulseCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // Called when returning to this screen from another route
  @override
  void didPopNext() {
    _fetchHomeData();
  }

  Future<String> _getToken() => AuthService.getToken();

  // ── LIVE LOCATION TRACKING ────────────────────────────
  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _silentRefresh();
    });
  }

  // Refresh data without showing loading spinner
  Future<void> _silentRefresh() async {
    try {
      
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('\$baseUrl/home'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer \$token'},
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200 && mounted) {
        final json = jsonDecode(response.body);
        final locs = (json['data']['locations'] as List?) ?? [];
        setState(() {
          _data         = json['data'];
          _allLocations = locs;
          _filteredLocs = _searchCtrl.text.isEmpty ? locs : _filteredLocs;
        });
      }
    } catch (e) {
      debugPrint('Silent refresh error: \$e');
    }
  }

  Future<void> _startLocationTracking() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return;

      // Get initial position
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (mounted) {
        setState(() {
          _userPosition = LatLng(pos.latitude, pos.longitude);
          _userHeading  = pos.heading;
        });
      }

      // Stream updates
      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5),
      ).listen((pos) {
        if (mounted) {
          setState(() {
            _userPosition = LatLng(pos.latitude, pos.longitude);
            _userHeading  = pos.heading;
          });
        }
      });
    } catch (e) {
      debugPrint('Location: $e');
    }
  }

  Future<void> _fetchHomeData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/home'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 401) {
        await AuthService.handleUnauthorized(mounted ? context : null);
        return;
      }
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final locs = (json['data']['locations'] as List?) ?? [];
        setState(() {
          _data         = json['data'];
          _allLocations = locs;
          // Re-apply existing filter so city selection is preserved on refresh
          final q = _searchCtrl.text.toLowerCase().trim();
          _filteredLocs = locs.where((loc) {
            final l    = loc as Map<String, dynamic>;
            final name = (l['name'] as String? ?? '').toLowerCase();
            final city = _normalizeCity(l['city']?.toString() ?? '');
            return (_selectedCity == 'All' || city == _selectedCity) &&
                   (q.isEmpty || name.contains(q));
          }).toList();
          _loading      = false;
        });
        _fadeCtrl.forward();
        if (locs.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _mapReady) {
              final first = locs[0] as Map<String, dynamic>;
              _mapController.move(LatLng(_dbl(first['lat'], 30.0444), _dbl(first['lng'], 31.2357)), 12);
            }
          });
        }
      } else {
        setState(() { _error = 'Server error (${response.statusCode}).'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = context.s.cannotConnect; _loading = false; });
    }
  }

  void _applyFilters() {
    final q = _searchCtrl.text.toLowerCase().trim();
    setState(() {
      _filteredLocs = _allLocations.where((loc) {
        final l     = loc as Map<String, dynamic>;
        final name  = (l['name'] as String? ?? '').toLowerCase();
        final city  = _normalizeCity(l['city']?.toString() ?? '');
        final matchesCity   = _selectedCity == 'All' || city == _selectedCity;
        final matchesSearch = q.isEmpty || name.contains(q);
        return matchesCity && matchesSearch;
      }).toList();
      if (_selectedIdx >= _filteredLocs.length) _selectedIdx = 0;
      _selectedLocation = null;
      _detailCtrl.reverse();
    });

    // Fly map to first filtered result
    if (_filteredLocs.isNotEmpty && _mapReady) {
      final first = _filteredLocs[0] as Map<String, dynamic>;
      final lat = _dbl(first['lat'], 30.0444);
      final lng = _dbl(first['lng'], 31.2357);
      _mapController.move(LatLng(lat, lng), _filteredLocs.length == 1 ? 15 : 12);
    }
  }

  // Normalizes city strings so "GIZA", "Giza Governorate", "giza" all become "Giza"
  static String _normalizeCity(String raw) {
    var s = raw.trim()
        .replaceAll(RegExp(r'\s*(governorate|gov\.?)\s*$', caseSensitive: false), '')
        .trim();
    return s.isEmpty ? '' : s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  void _onSearch() => _applyFilters();

  void _onCitySelected(String city) {
    setState(() => _selectedCity = city);
    _applyFilters();
  }

  void _clearSearch() {
    _searchCtrl.clear();
    setState(() => _searching = false);
    FocusScope.of(context).unfocus();
  }

  double _dbl(dynamic val, double fallback) {
    if (val == null) return fallback;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    return double.tryParse(val.toString()) ?? fallback;
  }

  void _onSelectLocation(int i, Map<String, dynamic> loc) {
    setState(() { _selectedIdx = i; _selectedLocation = loc; });
    if (_mapReady) _mapController.move(LatLng(_dbl(loc['lat'], 30.0444), _dbl(loc['lng'], 31.2357)), 15);
    _detailCtrl.forward();
    FocusScope.of(context).unfocus();
  }

  void _closeDetail() {
    _detailCtrl.reverse().then((_) { if (mounted) setState(() => _selectedLocation = null); });
  }

  List<DirectionStep> _buildDirectionSteps(Map<String, dynamic> location) {
    final locationName = (location['name']?.toString() ?? 'locker location').trim();
    return <DirectionStep>[
      const DirectionStep(
        icon: Icons.login_rounded,
        label: 'Enter from the nearest mall gate',
      ),
      DirectionStep(
        icon: Icons.straight_rounded,
        label: 'Walk straight toward $locationName',
      ),
      const DirectionStep(
        icon: Icons.turn_right_rounded,
        label: 'Turn right when you reach the main corridor',
      ),
      const DirectionStep(
        icon: Icons.lock_rounded,
        label: 'Your SmartSecure locker will be ahead',
      ),
    ];
  }

  void _openDirections(Map<String, dynamic> location) {
    final category = location['category']?.toString().toLowerCase() ?? '';
    final city     = location['city']?.toString().trim() ?? '';
    final address  = location['address']?.toString().trim() ?? '';
    final name     = location['name']?.toString() ?? 'SmartSecure Location';
    final lockerId = location['locker_id']?.toString() ?? 'N/A';

    final isAirport = category == 'airport' ||
        name.toLowerCase().contains('airport') ||
        name.toLowerCase().contains('terminal');

    final cityLine = [city, address].where((s) => s.isNotEmpty).join(' - ');

    if (isAirport) {
      Navigator.pushNamed(
        context,
        '/airport-directions',
        arguments: <String, dynamic>{
          'terminalName': name,
          'airportName':  cityLine.isEmpty ? 'Airport' : cityLine,
          'lockerId':     lockerId,
          'steps':        defaultAirportSteps(),
        },
      );
    } else if (category == 'railway' ||
        name.toLowerCase().contains('railway') ||
        name.toLowerCase().contains('train') ||
        name.toLowerCase().contains('station')) {
      Navigator.pushNamed(
        context,
        '/railway-directions',
        arguments: <String, dynamic>{
          'stationName': name,
          'cityName':    cityLine.isEmpty ? 'City' : cityLine,
          'lockerId':    lockerId,
          'steps':       defaultRailwaySteps(),
        },
      );
    } else {
      Navigator.pushNamed(
        context,
        '/directions',
        arguments: <String, dynamic>{
          'locationName': name,
          'mallName':     cityLine.isEmpty ? 'Selected Mall' : cityLine,
          'lockerId':     lockerId,
          'steps':        _buildDirectionSteps(location),
        },
      );
    }
  }

  Future<void> _goToMyLocation() async {
    if (_userPosition != null && _mapReady) {
      _mapController.move(_userPosition!, 16);
    } else {
      await _startLocationTracking();
      if (_userPosition != null && _mapReady) _mapController.move(_userPosition!, 16);
    }
  }

  void _zoomIn()  => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1);
  void _zoomOut() => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1);

  Future<void> _logout() async {
    await AuthService.signOut();
    if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
  }

  Future<void> _showExtendDialog(Map<String, dynamic> rental) async {
    int selectedHours = 1;
    final confirmed = await showDialog<int>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          backgroundColor: const Color(0xFF394057),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(context.s.extendRental, style: GoogleFonts.syne(fontWeight: FontWeight.w700, color: const Color(0xFFEEF0F6))),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('${rental['location_name']}', style: GoogleFonts.dmSans(color: const Color(0xFF6A7090), fontSize: 13)),
            const SizedBox(height: 16),
            Text(context.s.howManyHours, style: GoogleFonts.dmSans(color: const Color(0xFF9AA0B0), fontSize: 13)),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              IconButton(
                onPressed: () { if (selectedHours > 1) setDlg(() => selectedHours--); },
                icon: const Icon(Icons.remove_circle_outline, color: Color(0xFFF5A623)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F5774),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('$selectedHours h', style: GoogleFonts.syne(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFFEEF0F6))),
              ),
              IconButton(
                onPressed: () { if (selectedHours < 24) setDlg(() => selectedHours++); },
                icon: const Icon(Icons.add_circle_outline, color: Color(0xFFF5A623)),
              ),
            ]),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx),
              child: Text(context.s.cancel, style: GoogleFonts.syne(color: const Color(0xFF6A7090)))),
            TextButton(onPressed: () => Navigator.pop(ctx, selectedHours),
              child: Text(context.s.extend, style: GoogleFonts.syne(color: const Color(0xFFF5A623), fontWeight: FontWeight.w700))),
          ],
        ),
      ),
    );
    if (confirmed == null || !mounted) return;
    try {
      final token = await AuthService.getToken();
      final res = await http.put(
        Uri.parse('$baseUrl/rentals/${rental['rental_id']}/extend'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({'extra_hours': confirmed}),
      ).timeout(const Duration(seconds: 10));
      final body = jsonDecode(res.body);
      if (!mounted) return;
      if (res.statusCode == 200) {
        // Update the active rental card immediately from the response
        final updatedRental = body['rental'] as Map<String, dynamic>?;
        if (updatedRental != null && _data != null) {
          final newData = Map<String, dynamic>.from(_data!);
          final newRental = Map<String, dynamic>.from(newData['active_rental'] as Map<String, dynamic>);
          newRental['end_time']     = updatedRental['end_time'];
          newRental['total_amount'] = updatedRental['total_amount'];
          newData['active_rental']  = newRental;
          setState(() => _data = newData);
        }
        _silentRefresh(); // update wallet balance in background
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.s.extendedBy(confirmed), style: GoogleFonts.syne(color: Colors.white)),
          backgroundColor: const Color(0xFF00C9A7),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(body['message'] ?? context.s.failedToExtend, style: GoogleFonts.syne(color: Colors.white)),
          backgroundColor: const Color(0xFFE05A7A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.s.connectionError, style: GoogleFonts.syne(color: Colors.white)),
          backgroundColor: const Color(0xFFE05A7A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    // ── USER LOCATION MARKER ─────────────────────────────
    if (_userPosition != null) {
      markers.add(Marker(
        key: const ValueKey('user_location'),
        point: _userPosition!,
        width: 60, height: 60,
        child: _UserLocationMarker(heading: _userHeading),
      ));
    }

    // ── LOCKER MARKERS ────────────────────────────────────
    markers.addAll(List.generate(_filteredLocs.length, (i) {
      final loc      = _filteredLocs[i] as Map<String, dynamic>;
      final lat      = _dbl(loc['lat'], 30.0444);
      final lng      = _dbl(loc['lng'], 31.2357);
      final avail    = int.tryParse(loc['available_lockers']?.toString() ?? '0') ?? 0;
      final selected = i == _selectedIdx && _selectedLocation != null;
      return Marker(
        key: ValueKey('m_$i'),
        point: LatLng(lat, lng),
        width: selected ? 64 : 50, height: selected ? 64 : 50,
        child: GestureDetector(
          onTap: () => _onSelectLocation(i, loc),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? const Color(0xFFF5A623) : const Color(0xFF4F5774),
              border: Border.all(
                color: selected ? const Color(0xFFF5A623) : avail > 0 ? const Color(0xFFF5A623) : const Color(0xFFE05A7A),
                width: selected ? 3 : 2,
              ),
              boxShadow: [BoxShadow(
                color: selected ? const Color(0xFFF5A623).withValues(alpha: 0.55) : Colors.black.withValues(alpha: 0.3),
                blurRadius: selected ? 24 : 8,
              )],
            ),
            child: Icon(Icons.lock_rounded,
              color: selected ? const Color(0xFF2E3449) : avail > 0 ? const Color(0xFFF5A623) : const Color(0xFFE05A7A),
              size: selected ? 28 : 20),
          ),
        ),
      );
    }));

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    if (_loading) return const _LoadingView();
    if (_error != null) return _ErrorView(error: _error!, onRetry: _fetchHomeData);

    final user           = _data!['user']                 as Map<String, dynamic>?;
    final activeRental   = _data!['active_rental']        as Map<String, dynamic>?;
    final unreadCount    = (_data!['unread_notifications'] as num?)?.toInt() ?? 0;
    final bottom         = MediaQuery.of(context).padding.bottom;
    final bottomBarH     = 80.0 + bottom;
    final activeCardH    = activeRental != null ? 96.0 : 0.0;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF2E3449),
      drawer: ExploreMenu(
        user: user,
        unreadCount: unreadCount,
        onNavigate: (route) {
          Navigator.pop(context);
          Navigator.pushNamed(context, route).then((_) => _fetchHomeData());
        },
        onLogout: () { Navigator.pop(context); _logout(); },
      ),
      body: Stack(children: [

        // ── MAP ──────────────────────────────────────────
        Positioned.fill(
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(30.0444, 31.2357),
              initialZoom: 12.0,
              onMapReady: () { if (mounted) setState(() => _mapReady = true); },
              onTap: (_, __) { _closeDetail(); FocusScope.of(context).unfocus(); },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.smartsecure.app',
              ),
              MarkerLayer(markers: _buildMarkers()),
            ],
          ),
        ),

        // ── TOP OVERLAY — subtle fade, no heavy shadow ────
        Positioned(
          top: 0, left: 0, right: 0,
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF2E3449).withValues(alpha: 0.55),
                    const Color(0xFF2E3449).withValues(alpha: 0.22),
                    const Color(0xFF2E3449).withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(children: [

                      // Hamburger
                      GestureDetector(
                        onTap: () => _scaffoldKey.currentState?.openDrawer(),
                        child: Container(
                          width: 46, height: 46,
                          decoration: BoxDecoration(
                            color: const Color(0xFF434A64),
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(color: const Color(0x1FFFFFFF)),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10)],
                          ),
                          child: const Icon(Icons.menu_rounded, color: Color(0xFFEEF0F6), size: 22),
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Search bar
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _searching = true),
                          child: Container(
                            height: 46,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF434A64),
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(color: const Color(0x1FFFFFFF)),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10)],
                            ),
                            child: _searching
                                ? Row(children: [
                                    const Icon(Icons.search_rounded, color: Color(0xFFF5A623), size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        controller: _searchCtrl,
                                        autofocus: true,
                                        style: GoogleFonts.dmSans(color: const Color(0xFFEEF0F6), fontSize: 13),
                                        decoration: InputDecoration(
                                          hintText: context.s.searchLocations,
                                          hintStyle: GoogleFonts.dmSans(color: const Color(0xFF6A7090), fontSize: 13),
                                          border: InputBorder.none,
                                          isDense: true,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: _clearSearch,
                                      child: const Icon(Icons.close_rounded, color: Color(0xFF6A7090), size: 18),
                                    ),
                                  ])
                                : Row(children: [
                                    const Icon(Icons.search_rounded, color: Color(0xFF6A7090), size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(
                                      context.s.greetingFindLocker((user?['full_name'] as String? ?? 'User').split(' ').first),
                                      style: GoogleFonts.dmSans(color: const Color(0xFF6A7090), fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                    )),
                                  ]),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Wallet badge
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/wallet').then((_) => _fetchHomeData()),
                        child: Container(
                          height: 46,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF434A64),
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(color: const Color(0x1FFFFFFF)),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10)],
                          ),
                          child: Row(children: [
                            const Icon(Icons.wallet, color: Color(0xFFF5A623), size: 18),
                            const SizedBox(width: 6),
                            Text('EGP ${(double.tryParse(user?['wallet_balance']?.toString() ?? '0') ?? 0).toStringAsFixed(2)}',
                              style: GoogleFonts.syne(color: const Color(0xFFEEF0F6), fontSize: 13, fontWeight: FontWeight.w700)),
                          ]),
                        ),
                      ),
                    ]),
                  ),

                  const SizedBox(height: 10),

                  // ── CITY FILTER CHIPS ──────────────────────
                  Builder(builder: (context) {
                    final cities = ['All', ..._allLocations
                        .map((l) {
                          final raw = (l as Map<String, dynamic>)['city'];
                          return raw != null ? _normalizeCity(raw.toString()) : '';
                        })
                        .where((c) => c.isNotEmpty)
                        .toSet()
                        .toList()..sort()];
                    return SizedBox(
                      height: 32,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: cities.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final city = cities[i];
                          final sel  = city == _selectedCity;
                          return GestureDetector(
                            onTap: () => _onCitySelected(city),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: sel ? const Color(0xFFF5A623) : const Color(0xFF434A64),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: sel ? const Color(0xFFF5A623) : const Color(0x1FFFFFFF),
                                ),
                              ),
                              child: Text(
                                city == 'All' ? context.s.tabAll : city,
                                style: GoogleFonts.syne(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: sel ? const Color(0xFF2E3449) : const Color(0xFF9AA0B0),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }),

                  const SizedBox(height: 12),

                  // Location cards
                  if (_searching && _searchCtrl.text.isNotEmpty && _filteredLocs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(context.s.noLocationsFound, style: GoogleFonts.dmSans(color: const Color(0xFF6A7090), fontSize: 13)),
                    )
                  else
                    SizedBox(
                      height: 88,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredLocs.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (_, i) {
                          final loc   = _filteredLocs[i] as Map<String, dynamic>;
                          final sel   = i == _selectedIdx && _selectedLocation != null;
                          final avail = int.tryParse(loc['available_lockers']?.toString() ?? '0') ?? 0;
                          final price = double.tryParse(loc['price_from']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0.00';
                          return GestureDetector(
                            onTap: () => _onSelectLocation(i, loc),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 158, padding: const EdgeInsets.all(11),
                              decoration: BoxDecoration(
                                color: sel ? const Color(0xFFF5A623) : const Color(0xFF434A64),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: sel ? const Color(0xFFF5A623) : const Color(0x1FFFFFFF)),
                                boxShadow: [BoxShadow(
                                  color: sel ? const Color(0xFFF5A623).withValues(alpha: 0.35) : Colors.black.withValues(alpha: 0.2),
                                  blurRadius: sel ? 16 : 8)],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                    _Pill(
                                      label: avail > 0 ? context.s.lockersAvailableFree(avail) : context.s.full,
                                      color: sel
                                          ? (avail > 0 ? const Color(0xFF4F5774) : Colors.white)
                                          : (avail > 0 ? const Color(0xFF00C9A7) : const Color(0xFFE05A7A)),
                                      light: sel,
                                    ),
                                    Text('EGP $price/h', style: GoogleFonts.syne(fontSize: 10, fontWeight: FontWeight.w700,
                                      color: sel ? const Color(0xFF4F5774) : const Color(0xFFF5A623))),
                                  ]),
                                  Text(loc['name'] ?? '', style: GoogleFonts.syne(fontSize: 11, fontWeight: FontWeight.w700,
                                    color: sel ? const Color(0xFF2E3449) : const Color(0xFFEEF0F6)),
                                    maxLines: 2, overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 12),
                ]),
              ),
            ),
          ),
        ),

        // ── MAP CONTROLS ─────────────────────────────────
        Positioned(
          right: 14, bottom: bottomBarH + activeCardH + 16,
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF434A64).withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x1FFFFFFF)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 12)],
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                _MapBtn(icon: Icons.my_location_rounded, onTap: _goToMyLocation),
                Container(height: 1, color: const Color(0x1FFFFFFF)),
                _MapBtn(icon: Icons.add,    onTap: _zoomIn),
                Container(height: 1, color: const Color(0x1FFFFFFF)),
                _MapBtn(icon: Icons.remove, onTap: _zoomOut),
              ]),
            ),
          ),
        ),

        // ── ACTIVE RENTAL ────────────────────────────────
        if (activeRental != null)
          Positioned(
            bottom: bottomBarH, left: 0, right: 0,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: _ActiveRentalCard(
                rental: activeRental,
                onExtend:  () => _showExtendDialog(activeRental),
                onViewAll: () => Navigator.pushNamed(context, '/bookings'),
                onUnlock:  () => showUnlockMethodSheet(context, activeRental),
              ),
            ),
          ),

        // ── BOTTOM BAR ───────────────────────────────────
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Container(
              padding: EdgeInsets.fromLTRB(24, 14, 24, bottom + 14),
              decoration: BoxDecoration(
                color: const Color(0xFF394057),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: const Border(top: BorderSide(color: Color(0x12FFFFFF))),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20)],
              ),
              child: Row(children: [
                _BottomBtn(icon: Icons.grid_view_rounded, label: s.exploreLabel,
                  onTap: () => _scaffoldKey.currentState?.openDrawer()),
                const Spacer(),
                if (_pulseAnim != null)
                  AnimatedBuilder(
                    animation: _pulseAnim!,
                    builder: (_, child) => Transform.scale(scale: _pulseAnim!.value, child: child),
                    child: GestureDetector(
                      onTap: () {
                        final activeRental = _data?['active_rental'] as Map<String, dynamic>?;
                        if (activeRental != null) {
                          showUnlockMethodSheet(context, activeRental);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(context.s.noActiveRental),
                            behavior: SnackBarBehavior.floating,
                          ));
                        }
                      },
                      child: Container(
                        height: 52, padding: const EdgeInsets.symmetric(horizontal: 24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFF5A623), Color(0xFFE8920A)]),
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFFF5A623).withValues(alpha: 0.5), blurRadius: 20, offset: const Offset(0, 6)),
                            BoxShadow(color: const Color(0xFFF5A623).withValues(alpha: 0.2), blurRadius: 36, offset: const Offset(0, 8)),
                          ],
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF2E3449), size: 20),
                          const SizedBox(width: 8),
                          Text(s.scanToUnlock, style: GoogleFonts.syne(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF2E3449))),
                        ]),
                      ),
                    ),
                  ),
                const Spacer(),
                _BottomBtn(icon: Icons.person_outline_rounded, label: s.profileLabel,
                  onTap: () => Navigator.pushNamed(context, '/profile')),
              ]),
            ),
          ),
        ),

        // ── LOCATION DETAIL SHEET ─────────────────────────
        if (_selectedLocation != null)
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: SlideTransition(
              position: _detailAnim,
              child: _LocationDetailSheet(
                location: _selectedLocation!,
                onClose: _closeDetail,
                onBook: () => Navigator.pushNamed(context, '/book', arguments: _selectedLocation).then((_) => _fetchHomeData()),
                onDirections: () => _openDirections(_selectedLocation!),
              ),
            ),
          ),
      ]),
    );
  }
}

// ── USER LOCATION MARKER ──────────────────────────────────
class _UserLocationMarker extends StatefulWidget {
  final double heading;
  const _UserLocationMarker({required this.heading});
  @override
  State<_UserLocationMarker> createState() => _UserLocationMarkerState();
}

class _UserLocationMarkerState extends State<_UserLocationMarker> with SingleTickerProviderStateMixin {
  late AnimationController _rippleCtrl;
  late Animation<double>   _rippleAnim;

  @override
  void initState() {
    super.initState();
    _rippleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();
    _rippleAnim = CurvedAnimation(parent: _rippleCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() { _rippleCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Stack(alignment: Alignment.center, children: [

      // Ripple ring
      AnimatedBuilder(
        animation: _rippleAnim,
        builder: (_, __) => Container(
          width:  20 + (_rippleAnim.value * 40),
          height: 20 + (_rippleAnim.value * 40),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFF5A623).withValues(alpha: (1 - _rippleAnim.value) * 0.5),
              width: 1.5,
            ),
          ),
        ),
      ),

      // Direction cone
      Transform.rotate(
        angle: widget.heading * (math.pi / 180),
        child: CustomPaint(
          size: const Size(60, 60),
          painter: _DirectionConePainter(),
        ),
      ),

      // Center dot
      Container(
        width: 18, height: 18,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFF5A623),
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: [
            BoxShadow(color: const Color(0xFFF5A623).withValues(alpha: 0.6), blurRadius: 10),
          ],
        ),
      ),
    ]);
  }
}

// Direction cone painter
class _DirectionConePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFF5A623).withValues(alpha: 0.45),
          const Color(0xFFF5A623).withValues(alpha: 0.0),
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: size.height / 2));

    final path = ui.Path()
      ..moveTo(cx, cy)
      ..lineTo(cx - 14, cy - size.height * 0.48)
      ..lineTo(cx + 14, cy - size.height * 0.48)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_DirectionConePainter old) => false;
}

// ── MAP BUTTON ────────────────────────────────────────────
class _MapBtn extends StatelessWidget {
  final IconData icon; final VoidCallback onTap;
  const _MapBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: SizedBox(width: 44, height: 44, child: Icon(icon, color: const Color(0xFFEEF0F6), size: 20)),
  );
}

// ── BOTTOM BAR BUTTON ─────────────────────────────────────
class _BottomBtn extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap;
  const _BottomBtn({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: const Color(0xFF6A7090), size: 24),
      const SizedBox(height: 4),
      Text(label, style: GoogleFonts.dmSans(fontSize: 10, color: const Color(0xFF6A7090), fontWeight: FontWeight.w500)),
    ]),
  );
}

// ── ACTIVE RENTAL CARD ────────────────────────────────────
class _ActiveRentalCard extends StatefulWidget {
  final Map<String, dynamic> rental;
  final VoidCallback? onExtend;
  final VoidCallback? onViewAll;
  final VoidCallback? onUnlock;
  const _ActiveRentalCard({required this.rental, this.onExtend, this.onViewAll, this.onUnlock});
  @override
  State<_ActiveRentalCard> createState() => _ActiveRentalCardState();
}

class _ActiveRentalCardState extends State<_ActiveRentalCard> {
  Timer? _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = _calcRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _remaining = _calcRemaining());
    });
  }

  @override
  void didUpdateWidget(_ActiveRentalCard old) {
    super.didUpdateWidget(old);
    if (old.rental['end_time'] != widget.rental['end_time']) {
      setState(() => _remaining = _calcRemaining());
    }
  }

  bool get _hasStarted {
    final start = DateTime.tryParse(widget.rental['start_time'] ?? '');
    if (start == null) return true;
    return !DateTime.now().isBefore(start);
  }

  bool get _isLowTime => _hasStarted && _remaining.inSeconds <= 15 * 60;

  Duration _calcRemaining() {
    final now = DateTime.now();
    final start = DateTime.tryParse(widget.rental['start_time'] ?? '');
    // Before start: count down to start_time
    if (start != null && now.isBefore(start)) {
      final rem = start.difference(now);
      return rem.isNegative ? Duration.zero : rem;
    }
    // After start: count down to end_time
    final end = DateTime.tryParse(widget.rental['end_time'] ?? '') ?? now;
    final rem = end.difference(now);
    return rem.isNegative ? Duration.zero : rem;
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final h           = _remaining.inHours.clamp(0, 99);
    final m           = (_remaining.inMinutes % 60).clamp(0, 59);
    final s           = (_remaining.inSeconds % 60).clamp(0, 59);
    final code        = widget.rental['locker_code'] as String? ?? '—';
    final activeCount = (widget.rental['active_rentals_count'] as num?)?.toInt() ?? 1;
    final started     = _hasStarted;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF394057), borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF5A623).withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(color: const Color(0xFFF5A623).withValues(alpha: 0.12), blurRadius: 20),
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 12),
        ],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Container(width: 38, height: 38,
            decoration: BoxDecoration(color: const Color(0xFFF5A623).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(11)),
            child: const Icon(Icons.lock_open_rounded, color: Color(0xFFF5A623), size: 18)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF00C9A7), shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text(activeCount > 1 ? '${started ? 'ACTIVE' : 'UPCOMING'} RENTAL · 1 OF $activeCount' : (started ? 'ACTIVE RENTAL' : 'UPCOMING RENTAL'),
                style: GoogleFonts.syne(fontSize: 8, fontWeight: FontWeight.w700, color: started ? const Color(0xFF00C9A7) : const Color(0xFF7B8FFF))),
              if (activeCount > 1) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: widget.onViewAll,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C9A7).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: const Color(0xFF00C9A7).withValues(alpha: 0.4)),
                    ),
                    child: Text(context.s.seeAll, style: GoogleFonts.syne(fontSize: 7, fontWeight: FontWeight.w700, color: const Color(0xFF00C9A7))),
                  ),
                ),
              ],
            ]),
            Text(widget.rental['location_name'] ?? '', style: GoogleFonts.syne(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFFEEF0F6)), maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
            SizedBox(
              width: 120,
              height: 120,
              child: CustomPaint(
                painter: _WallClockPainter(
                  hours: h,
                  minutes: m,
                  seconds: s,
                  color: _isLowTime
                      ? const Color(0xFFFF3B30)
                      : (started ? const Color(0xFFF5A623) : const Color(0xFF7B8FFF)),
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(started ? context.s.remaining : context.s.untilStart,
              style: GoogleFonts.dmSans(fontSize: 8, color: const Color(0xFF6A7090))),
          ]),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          // Access code chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF5A623).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: const Color(0xFFF5A623).withValues(alpha: 0.3)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.key_rounded, color: Color(0xFFF5A623), size: 12),
              const SizedBox(width: 5),
              Text(code, style: GoogleFonts.syne(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFFF5A623), letterSpacing: 2)),
            ]),
          ),
          const Spacer(),
          // Unlock button — only shown once rental has started
          if (started) ...[
            GestureDetector(
              onTap: widget.onUnlock,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF00C9A7), Color(0xFF00A88F)]),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.lock_open_rounded, color: Color(0xFF2E3449), size: 13),
                  const SizedBox(width: 4),
                  Text(context.s.unlock, style: GoogleFonts.syne(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF2E3449))),
                ]),
              ),
            ),
            const SizedBox(width: 8),
          ],
          // Extend button — only shown once rental has started
          if (started) GestureDetector(
            onTap: widget.onExtend,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF7B8FFF).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: const Color(0xFF7B8FFF).withValues(alpha: 0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF7B8FFF), size: 13),
                const SizedBox(width: 4),
                Text(context.s.extend, style: GoogleFonts.syne(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF7B8FFF))),
              ]),
            ),
          ),
        ]),
      ]),
    );
  }
}

// ── WALL CLOCK PAINTER ────────────────────────────────────
class _WallClockPainter extends CustomPainter {
  final int hours;
  final int minutes;
  final int seconds;
  final Color color;

  const _WallClockPainter({
    required this.hours,
    required this.minutes,
    required this.seconds,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Face background
    canvas.drawCircle(center, radius, Paint()..color = color.withValues(alpha: 0.10));

    // Outer bezel (double ring)
    canvas.drawCircle(center, radius - 1,
      Paint()
        ..color = color.withValues(alpha: 0.60)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5);
    canvas.drawCircle(center, radius - 5,
      Paint()
        ..color = color.withValues(alpha: 0.20)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8);

    // Tick marks — near outer edge only, leaving room for numbers inside
    for (int i = 0; i < 60; i++) {
      final isHour = i % 5 == 0;
      if (isHour) continue; // hour positions handled by numbers; draw minute ticks only
      final angle = i * 2 * math.pi / 60 - math.pi / 2;
      final outerR = radius - 7;
      final innerR = radius - 12;
      canvas.drawLine(
        Offset(center.dx + outerR * math.cos(angle), center.dy + outerR * math.sin(angle)),
        Offset(center.dx + innerR * math.cos(angle), center.dy + innerR * math.sin(angle)),
        Paint()
          ..color = color.withValues(alpha: 0.30)
          ..strokeWidth = 0.9
          ..strokeCap = StrokeCap.round);
    }

    // Hour numbers 1–12
    for (int i = 1; i <= 12; i++) {
      final angle = i * math.pi / 6 - math.pi / 2;
      final numR = radius * 0.72;
      final x = center.dx + numR * math.cos(angle);
      final y = center.dy + numR * math.sin(angle);
      final tp = TextPainter(
        text: TextSpan(
          text: '$i',
          style: TextStyle(
            color: color.withValues(alpha: 0.90),
            fontSize: radius * 0.22,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
    }

    // Hour hand
    final hourAngle = ((hours % 12) + minutes / 60.0) / 12 * 2 * math.pi - math.pi / 2;
    _drawHand(canvas, center, radius * 0.44, hourAngle, color, 3.5);

    // Minute hand
    final minuteAngle = (minutes + seconds / 60.0) / 60 * 2 * math.pi - math.pi / 2;
    _drawHand(canvas, center, radius * 0.60, minuteAngle, color, 2.2);

    // Second hand + counter-weight tail
    final secondAngle = seconds / 60 * 2 * math.pi - math.pi / 2;
    _drawHand(canvas, center, radius * 0.64, secondAngle, color.withValues(alpha: 0.75), 1.1);
    _drawHand(canvas, center, -radius * 0.18, secondAngle, color.withValues(alpha: 0.75), 1.1);

    // Center cap
    canvas.drawCircle(center, 5.0, Paint()..color = color);
    canvas.drawCircle(center, 2.2, Paint()..color = Colors.white.withValues(alpha: 0.50));
  }

  void _drawHand(Canvas canvas, Offset center, double length, double angle, Color handColor, double width) {
    canvas.drawLine(
      center,
      Offset(center.dx + length * math.cos(angle), center.dy + length * math.sin(angle)),
      Paint()
        ..color = handColor
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_WallClockPainter old) =>
      old.hours != hours || old.minutes != minutes || old.seconds != seconds || old.color != color;
}

// ── LOCATION DETAIL SHEET ─────────────────────────────────
class _LocationDetailSheet extends StatelessWidget {
  final Map<String, dynamic> location;
  final VoidCallback onClose, onBook, onDirections;
  const _LocationDetailSheet({required this.location, required this.onClose, required this.onBook, required this.onDirections});
  @override
  Widget build(BuildContext context) {
    final avail  = int.tryParse(location['available_lockers']?.toString() ?? '0') ?? 0;
    final total  = int.tryParse(location['total_lockers']?.toString()    ?? '0') ?? 0;
    final price  = double.tryParse(location['price_from']?.toString()    ?? '0')?.toStringAsFixed(2) ?? '0.00';
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(color: Color(0xFF394057), borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      padding: EdgeInsets.fromLTRB(24, 0, 24, bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Stack(alignment: Alignment.center, children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0x30FFFFFF), borderRadius: BorderRadius.circular(99))),
            Positioned(right: 0, child: GestureDetector(onTap: onClose,
              child: Container(width: 32, height: 32, decoration: const BoxDecoration(color: Color(0xFF4F5774), shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded, color: Color(0xFF6A7090), size: 16)))),
          ]),
        ),
        Row(children: [
          Container(width: 46, height: 46,
            decoration: BoxDecoration(color: const Color(0xFFF5A623).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.location_on_rounded, color: Color(0xFFF5A623), size: 22)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(location['name'] ?? '', style: GoogleFonts.syne(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFFEEF0F6))),
            Text(location['city'] ?? '', style: GoogleFonts.dmSans(fontSize: 13, color: const Color(0xFF6A7090))),
          ])),
          _Pill(label: avail > 0 ? context.s.lockersAvailableFree(avail) : context.s.full, color: avail > 0 ? const Color(0xFF00C9A7) : const Color(0xFFE05A7A)),
        ]),
        const SizedBox(height: 20),
        Row(children: [
          _StatBox(label: context.s.statAvailable, value: '$avail / $total', icon: Icons.lock_open_rounded,  color: const Color(0xFF00C9A7)),
          const SizedBox(width: 10),
          _StatBox(label: context.s.statFrom,      value: 'EGP $price/h',    icon: Icons.payments_outlined,   color: const Color(0xFFF5A623)),
          const SizedBox(width: 10),
          _StatBox(label: context.s.locAddress,   value: location['address'] ?? 'N/A', icon: Icons.map_outlined, color: const Color(0xFF7B8FFF)),
        ]),
        const SizedBox(height: 22),
        Row(children: [
          Expanded(child: GestureDetector(onTap: onDirections,
            child: Container(height: 52,
              decoration: BoxDecoration(color: const Color(0xFF4F5774), borderRadius: BorderRadius.circular(999), border: Border.all(color: const Color(0x18FFFFFF))),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.directions_rounded, color: Color(0xFFEEF0F6), size: 18),
                const SizedBox(width: 8),
                Text(context.s.directions, style: GoogleFonts.syne(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFFEEF0F6))),
              ])))),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: GestureDetector(onTap: onBook,
            child: Container(height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFF5A623), Color(0xFFE8920A)]),
                borderRadius: BorderRadius.circular(999),
                boxShadow: [BoxShadow(color: const Color(0xFFF5A623).withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 4))]),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.lock_open_rounded, color: Color(0xFF2E3449), size: 18),
                const SizedBox(width: 8),
                Text(context.s.bookLocker, style: GoogleFonts.syne(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF2E3449))),
              ])))),
        ]),
      ]),
    );
  }
}

// ── STAT BOX ──────────────────────────────────────────────
class _StatBox extends StatelessWidget {
  final String label, value; final IconData icon; final Color color;
  const _StatBox({required this.label, required this.value, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: 0.15))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 15), const SizedBox(height: 5),
        Text(value, style: GoogleFonts.syne(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFFEEF0F6)), maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(label, style: GoogleFonts.dmSans(fontSize: 10, color: const Color(0xFF6A7090))),
      ]),
    ),
  );
}

// ── PILL ──────────────────────────────────────────────────
class _Pill extends StatelessWidget {
  final String label; final Color color; final bool light;
  const _Pill({required this.label, required this.color, this.light = false});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: light ? 0.2 : 0.12), borderRadius: BorderRadius.circular(99),
      border: Border.all(color: color.withValues(alpha: light ? 0.4 : 0.3))),
    child: Text(label, style: GoogleFonts.syne(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
  );
}

// ── LOADING ───────────────────────────────────────────────
class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF2E3449),
    body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const CircularProgressIndicator(color: Color(0xFFF5A623), strokeWidth: 2),
      const SizedBox(height: 16),
      Text(context.s.loading, style: const TextStyle(color: Color(0xFF6A7090), fontSize: 14)),
    ])),
  );
}

// ── ERROR ─────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String error; final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF2E3449),
    body: Center(child: Padding(padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.wifi_off_rounded, color: Color(0xFF6A7090), size: 52),
        const SizedBox(height: 16),
        Text(error, textAlign: TextAlign.center, style: GoogleFonts.dmSans(color: const Color(0xFF6A7090), fontSize: 14)),
        const SizedBox(height: 24),
        GestureDetector(onTap: onRetry,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFF5A623), Color(0xFFE8920A)]), borderRadius: BorderRadius.circular(99)),
            child: Text(context.s.retry, style: GoogleFonts.syne(fontWeight: FontWeight.w700, color: const Color(0xFF2E3449))),
          )),
      ]))),
  );
}