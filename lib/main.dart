import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const RadioCharuApp());
}

// Bangladeshi folk-inspired solid pop colors.
const folkRed = Color(0xFFD62828);
const folkYellow = Color(0xFFF4B400);
const folkOrange = Color(0xFFF46A1A);
const folkGreen = Color(0xFF138A36);
const folkCream = Color(0xFFFFF4D6);
const folkWhite = Color(0xFFFFFFFF);
const folkInk = Color(0xFF202020);
const folkMuted = Color(0xFF6C675F);

class RadioCharuApp extends StatelessWidget {
  const RadioCharuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RADIO CHARU',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: folkCream,
        colorScheme: ColorScheme.fromSeed(
          seedColor: folkRed,
          primary: folkRed,
          secondary: folkOrange,
          surface: folkWhite,
        ),
        fontFamily: 'Roboto',
      ),
      home: const RadioHomePage(),
    );
  }
}

class RadioHomePage extends StatefulWidget {
  const RadioHomePage({super.key});

  @override
  State<RadioHomePage> createState() => _RadioHomePageState();
}

class _RadioHomePageState extends State<RadioHomePage> {
  static const String _playerUrl =
      'https://johnymahmud.github.io/radio-charu-app/';

  static const String _statusUrl =
      'https://sapircast.caster.fm:17055/admin/publicstats.json';

  static const String _mountPoint = '/hQJ4i';
  
  static final Uri _facebookUrl =
    Uri.parse('https://www.facebook.com/CharuTV/');

  static final Uri _youtubeUrl =
    Uri.parse('https://www.youtube.com/@RadioCharu');

  late final WebViewController _playerController;
  Timer? _statusTimer;

  bool _playerLoading = true;
  bool _checkingStatus = true;
  bool _serverOnline = false;
  bool _onAir = false;

  int _listeners = 0;

  String _stationName = 'RADIO CHARU';
  String _description = 'বাংলাদেশ থেকে ভালোবাসার সম্প্রচার';
  String _statusMessage = 'লাইভ স্ট্যাটাস দেখা হচ্ছে...';

  @override
  void initState() {
    super.initState();

    _playerController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(folkCream)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _playerLoading = true;
            });
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() {
              _playerLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(_playerUrl));

    _loadRadioStatus();

    _statusTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _loadRadioStatus(),
    );
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadRadioStatus() async {
    if (mounted) {
      setState(() {
        _checkingStatus = true;
      });
    }

    try {
      final response = await http
          .get(Uri.parse(_statusUrl))
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) {
        throw Exception('Status code ${response.statusCode}');
      }

      final dynamic decoded = jsonDecode(response.body);

      Map<String, dynamic>? serverData;

      if (decoded is List) {
        for (final dynamic item in decoded) {
          if (item is Map && item.containsKey('source')) {
            serverData = Map<String, dynamic>.from(item);
            break;
          }
        }
      }

      final dynamic allSources = serverData?['source'];

      Map<String, dynamic>? liveSource;

      if (allSources is Map) {
        final dynamic selectedSource = allSources[_mountPoint];

        if (selectedSource is Map) {
          liveSource = Map<String, dynamic>.from(selectedSource);
        }
      }

      final bool isLive = liveSource != null;

      final String rawName =
          liveSource?['server_name']?.toString().trim() ?? '';

      final String rawDescription =
          liveSource?['server_description']?.toString().trim() ?? '';

      final int listenerCount =
          int.tryParse('${liveSource?['listeners'] ?? 0}') ?? 0;

      if (!mounted) return;

      setState(() {
        _serverOnline = true;
        _onAir = isLive;
        _listeners = listenerCount;

        _stationName = rawName.isEmpty || rawName == 'no name'
            ? 'RADIO CHARU'
            : rawName;

        _description = rawDescription.isEmpty ||
                rawDescription == 'Unspecified description'
            ? 'বাংলাদেশ থেকে ভালোবাসার সম্প্রচার'
            : rawDescription;

        _statusMessage = isLive
            ? 'রেডিও এখন সরাসরি সম্প্রচারে আছে'
            : 'সার্ভার চালু আছে, কিন্তু সম্প্রচার বন্ধ';

        _checkingStatus = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _serverOnline = false;
        _onAir = false;
        _listeners = 0;
        _statusMessage =
            'লাইভ স্ট্যাটাস পাওয়া যাচ্ছে না। ইন্টারনেট সংযোগ পরীক্ষা করুন।';
        _checkingStatus = false;
      });
    }
  }
  Future<void> _openSocialLink(Uri url) async {
  final bool opened = await launchUrl(
    url,
    mode: LaunchMode.externalApplication,
  );

  if (!opened && mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'লিংকটি খোলা যাচ্ছে না। আবার চেষ্টা করুন।',
        ),
      ),
    );
  }
}
  Future<void> _reloadPlayer() async {
    setState(() {
      _playerLoading = true;
    });

    await _playerController.reload();
    await _loadRadioStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: folkRed,
          backgroundColor: folkWhite,
          onRefresh: _loadRadioStatus,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              _buildHeader(),
              const _FolkColorStrip(),
              _buildStatusSection(),
              _buildPlayerSection(),
              _buildStationSection(),
              _buildSocialSection(),
              _buildCommunityPreview(),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: folkGreen,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: folkYellow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: folkWhite,
                width: 3,
              ),
            ),
            child: const Icon(
              Icons.radio_rounded,
              color: folkRed,
              size: 34,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RADIO CHARU',
                  style: TextStyle(
                    color: folkWhite,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'কথা, গান ও মানুষের সংযোগ',
                  style: TextStyle(
                    color: folkWhite,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: _onAir ? folkRed : folkOrange,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: folkWhite,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: folkWhite,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _onAir ? 'ON AIR' : 'OFF AIR',
                  style: const TextStyle(
                    color: folkWhite,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatusBox(
                  icon: Icons.cell_tower_rounded,
                  label: 'BROADCAST',
                  value: _onAir ? 'LIVE' : 'OFF AIR',
                  color: _onAir ? folkRed : folkOrange,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatusBox(
                  icon: Icons.headphones_rounded,
                  label: 'LISTENERS',
                  value: '$_listeners',
                  color: folkGreen,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatusBox(
                  icon: Icons.graphic_eq_rounded,
                  label: 'QUALITY',
                  value: '96 KBPS',
                  color: folkOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: folkWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _serverOnline ? folkGreen : folkRed,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                if (_checkingStatus)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: folkOrange,
                    ),
                  )
                else
                  Icon(
                    _onAir
                        ? Icons.podcasts_rounded
                        : Icons.info_outline_rounded,
                    color: _onAir ? folkRed : folkOrange,
                    size: 25,
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _statusMessage,
                    style: const TextStyle(
                      color: folkInk,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh status',
                  onPressed: _checkingStatus ? null : _loadRadioStatus,
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: folkGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.play_circle_fill_rounded,
            title: 'LIVE PLAYER',
            color: folkRed,
          ),
          const SizedBox(height: 10),
          Container(
            height: 405,
            decoration: BoxDecoration(
              color: folkWhite,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: folkRed,
                width: 3,
              ),
              boxShadow: const [
                BoxShadow(
                  color: folkYellow,
                  offset: Offset(7, 7),
                  blurRadius: 0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                children: [
                  WebViewWidget(
                    controller: _playerController,
                  ),
                  if (_playerLoading)
                    Container(
                      color: folkCream,
                      alignment: Alignment.center,
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            color: folkRed,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Player loading...',
                            style: TextStyle(
                              color: folkInk,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _reloadPlayer,
              style: FilledButton.styleFrom(
                backgroundColor: folkOrange,
                foregroundColor: folkWhite,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text(
                'RELOAD PLAYER',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStationSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: folkWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: folkGreen,
            width: 3,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(
              icon: Icons.info_rounded,
              title: 'ABOUT THE STATION',
              color: folkGreen,
            ),
            const SizedBox(height: 14),
            Text(
              _stationName,
              style: const TextStyle(
                color: folkRed,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _description,
              style: const TextStyle(
                color: folkInk,
                height: 1.5,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
Widget _buildSocialSection() {
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
    child: Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: folkWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: folkOrange,
          width: 3,
        ),
        boxShadow: const [
          BoxShadow(
            color: folkYellow,
            offset: Offset(6, 6),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.connect_without_contact_rounded,
            title: 'FOLLOW RADIO CHARU',
            color: folkOrange,
          ),
          const SizedBox(height: 8),
          const Text(
            'আমাদের সামাজিক যোগাযোগমাধ্যমে যুক্ত থাকুন',
            style: TextStyle(
              color: folkInk,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _openSocialLink(_facebookUrl),
                  style: FilledButton.styleFrom(
                    backgroundColor: folkGreen,
                    foregroundColor: folkWhite,
                    padding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(
                    Icons.facebook_rounded,
                    size: 24,
                  ),
                  label: const Text(
                    'FACEBOOK',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _openSocialLink(_youtubeUrl),
                  style: FilledButton.styleFrom(
                    backgroundColor: folkRed,
                    foregroundColor: folkWhite,
                    padding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(
                    Icons.smart_display_rounded,
                    size: 25,
                  ),
                  label: const Text(
                    'YOUTUBE',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
  Widget _buildCommunityPreview() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: folkYellow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: folkInk,
            width: 3,
          ),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(
              icon: Icons.campaign_rounded,
              title: 'SHOUT & LIVE COMMENTS',
              color: folkRed,
            ),
            SizedBox(height: 10),
            Text(
              'পরবর্তী ধাপে Firebase সংযোগ করে Admin Shout এবং '
              'Realtime Live Comments চালু করা হবে।',
              style: TextStyle(
                color: folkInk,
                fontSize: 14,
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FolkColorStrip extends StatelessWidget {
  const _FolkColorStrip();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 9,
      child: Row(
        children: [
          Expanded(child: ColoredBox(color: folkRed)),
          Expanded(child: ColoredBox(color: folkYellow)),
          Expanded(child: ColoredBox(color: folkOrange)),
          Expanded(child: ColoredBox(color: folkGreen)),
          Expanded(child: ColoredBox(color: folkWhite)),
        ],
      ),
    );
  }
}

class _StatusBox extends StatelessWidget {
  const _StatusBox({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 104,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: folkWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color,
          width: 3,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 25,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: folkMuted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.color,
  });

  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: color,
          size: 25,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ],
    );
  }
}