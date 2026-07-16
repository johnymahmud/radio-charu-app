import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:app_settings/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'community_panel.dart';

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

class _RadioHomePageState extends State<RadioHomePage>
    with WidgetsBindingObserver {
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
  bool _wasBackgrounded = false;

  static const String _backgroundPlaybackDoneKey =
    'background_playback_setup_done';
  static const String _backgroundPlaybackSnoozeUntilKey =
    'background_playback_snooze_until';

final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

bool _waitingForBackgroundSettings = false;
bool _backgroundDialogOpen = false;

bool _directPlayerMode = false;
bool _directPlayerOpening = false;
bool _playbackTrackingReady = false;
bool _resumeWanted = false;
bool _smartResumeRunning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_scheduleBackgroundPlaybackPrompt());

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
         onPageFinished: (String url) {
  if (!mounted) return;

  final bool isDirectCasterPage = url.startsWith(
    'https://widgets.cloud.caster.fm/player/',
  );

  setState(() {
    _playerLoading = false;
    _directPlayerMode = isDirectCasterPage;
    _playbackTrackingReady = false;

    if (isDirectCasterPage) {
      _directPlayerOpening = false;
    }
  });

  if (isDirectCasterPage) {
    unawaited(
      Future<void>.delayed(
        const Duration(milliseconds: 500),
        () async {
          if (!mounted || !_directPlayerMode) return;

          await _installPlaybackTracking();
        },
      ),
    );

    return;
  }

  if (url.startsWith(_playerUrl) &&
      !_directPlayerOpening) {
    _directPlayerOpening = true;

    unawaited(
      Future<void>.delayed(
        const Duration(milliseconds: 900),
        () async {
          if (!mounted) return;

          await _openDirectCasterPlayer();
        },
      ),
    );
  }
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

Future<void> _scheduleBackgroundPlaybackPrompt() async {
  final bool setupDone =
      await _preferences.getBool(_backgroundPlaybackDoneKey) ?? false;

  if (setupDone) return;

  final int snoozeUntil = await _preferences.getInt(
        _backgroundPlaybackSnoozeUntilKey,
      ) ??
      0;

  if (DateTime.now().millisecondsSinceEpoch < snoozeUntil) {
    return;
  }

  await Future<void>.delayed(
    const Duration(milliseconds: 1500),
  );

  if (!mounted || _backgroundDialogOpen) return;

  await _showBackgroundPlaybackDialog();
}

Future<void> _showBackgroundPlaybackDialog() async {
  if (!mounted || _backgroundDialogOpen) return;

  _backgroundDialogOpen = true;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE7F8EC),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_clock_rounded,
                      color: folkGreen,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Screen Lock-এও Radio শুনুন',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'স্ক্রিন লক থাকলেও রেডিও চালু রাখতে Radio Charu-এর Battery Settings থেকে “Allow background activity”, “Allow background usage” অথবা “Unrestricted” চালু করুন।',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'এই সেটিং সাধারণত একবারই করতে হয়।',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();

                        unawaited(
                          _openBackgroundPlaybackSettings(),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: folkGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                      icon: const Icon(
                        Icons.settings_rounded,
                      ),
                      label: const Text(
                        'OPEN SETTINGS',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                tooltip: 'Close',
                onPressed: () async {
                  final int snoozeUntil = DateTime.now()
                      .add(const Duration(days: 3))
                      .millisecondsSinceEpoch;

                  await _preferences.setInt(
                    _backgroundPlaybackSnoozeUntilKey,
                    snoozeUntil,
                  );

                  if (!dialogContext.mounted) return;

                  Navigator.of(dialogContext).pop();
                },
                icon: const Icon(
                  Icons.close_rounded,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );

  _backgroundDialogOpen = false;
}

Future<void> _showBackgroundPlaybackConfirmationDialog() async {
  if (!mounted || _backgroundDialogOpen) return;

  _backgroundDialogOpen = true;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        icon: const Icon(
          Icons.check_circle_outline_rounded,
          color: folkGreen,
          size: 46,
        ),
        title: const Text(
          'Background Playback চালু করেছেন?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
        content: const Text(
          'Radio Charu-এর Battery Settings থেকে Background Activity অথবা Background Usage চালু করা হয়ে থাকলে DONE চাপুন।',
          textAlign: TextAlign.center,
          style: TextStyle(
            height: 1.4,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();

              unawaited(
                _openBackgroundPlaybackSettings(),
              );
            },
            child: const Text(
              'OPEN AGAIN',
              style: TextStyle(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          FilledButton(
            onPressed: () async {
              await _preferences.setBool(
                _backgroundPlaybackDoneKey,
                true,
              );

              if (!dialogContext.mounted) return;

              Navigator.of(dialogContext).pop();

              if (!mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Background playback setup সম্পন্ন হয়েছে।',
                  ),
                  duration: Duration(seconds: 3),
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: folkGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'DONE',
              style: TextStyle(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      );
    },
  );

  _backgroundDialogOpen = false;
}

Future<void> _openBackgroundPlaybackSettings() async {
  _waitingForBackgroundSettings = true;

  try {
    await AppSettings.openAppSettings(
      type: AppSettingsType.settings,
    );
  } catch (error) {
    _waitingForBackgroundSettings = false;

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Settings খোলা যায়নি। ফোনের Settings থেকে Radio Charu-এর Battery অথবা Background Activity চালু করুন।',
        ),
        duration: Duration(seconds: 4),
      ),
    );
  }
}

@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  super.didChangeAppLifecycleState(state);

  if (state == AppLifecycleState.paused ||
      state == AppLifecycleState.inactive ||
      state == AppLifecycleState.hidden) {
    _wasBackgrounded = true;
    return;
  }

 if (state == AppLifecycleState.resumed && _wasBackgrounded) {
  _wasBackgrounded = false;

  if (!mounted) return;

  if (_waitingForBackgroundSettings) {
  _waitingForBackgroundSettings = false;

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;

    unawaited(
      _showBackgroundPlaybackConfirmationDialog(),
    );
  });

  return;
}

unawaited(_attemptSmartResume());

}
}

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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

Future<void> _checkPlayerState() async {
  try {
    final Object rawResult =
        await _playerController.runJavaScriptReturningResult(
      r'''
      (() => {
        const clean = (value) =>
          (value ?? '')
            .toString()
            .replace(/\s+/g, ' ')
            .trim();

        const roots = [document];

        for (let rootIndex = 0; rootIndex < roots.length; rootIndex++) {
          const elements = Array.from(
            roots[rootIndex].querySelectorAll('*')
          );

          for (const element of elements) {
            if (element.shadowRoot) {
              roots.push(element.shadowRoot);
            }
          }
        }

        const queryAll = (selector) => {
          const results = [];

          for (const root of roots) {
            results.push(
              ...Array.from(root.querySelectorAll(selector))
            );
          }

          return results;
        };

        const buttonNodes = queryAll(
          'button, [role="button"], input[type="button"], input[type="submit"]'
        );

        const playerButtons = buttonNodes
          .map((node, index) => {
            const text = clean(
              node.innerText ||
              node.value ||
              node.getAttribute('aria-label') ||
              node.getAttribute('title')
            );

            return {
              index,
              tag: node.tagName,
              text,
              id: node.id || '',
              className: clean(node.className),
            };
          })
          .filter((item) =>
            /play|pause|resume|stop/i.test(item.text)
          )
          .slice(0, 20);

        const audios = queryAll('audio').map(
          (audio, index) => ({
            index,
            paused: audio.paused,
            ended: audio.ended,
            muted: audio.muted,
            currentTime: audio.currentTime,
            readyState: audio.readyState,
            networkState: audio.networkState,
            currentSrc: audio.currentSrc || '',
            src: audio.src || '',
          })
        );

        const iframes = queryAll('iframe').map(
          (frame, index) => {
            let access = 'blocked';
            let childAudioCount = null;
            let childPlayerButtons = [];

            try {
              const childDocument =
                frame.contentDocument ||
                (
                  frame.contentWindow &&
                  frame.contentWindow.document
                );

              if (childDocument) {
                access = 'accessible';

                childAudioCount =
                  childDocument.querySelectorAll('audio').length;

                childPlayerButtons = Array.from(
                  childDocument.querySelectorAll(
                    'button, [role="button"]'
                  )
                )
                  .map((button) =>
                    clean(
                      button.innerText ||
                      button.getAttribute('aria-label') ||
                      button.getAttribute('title')
                    )
                  )
                  .filter((text) =>
                    /play|pause|resume|stop/i.test(text)
                  )
                  .slice(0, 10);
              }
            } catch (error) {
              access =
                'blocked:' +
                (
                  error && error.name
                    ? error.name
                    : 'security-error'
                );
            }

            return {
              index,
              src: frame.getAttribute('src') || '',
              title: frame.getAttribute('title') || '',
              access,
              childAudioCount,
              childPlayerButtons,
            };
          }
        );

        return JSON.stringify({
          pageUrl: location.href,
          pageTitle: document.title,
          readyState: document.readyState,
          visibilityState: document.visibilityState,
          hasFocus: document.hasFocus(),
          rootCount: roots.length,
          audioCount: audios.length,
          iframeCount: iframes.length,
          playerButtonCount: playerButtons.length,
          playerButtons,
          audios,
          iframes,
        });
      })()
      ''',
    );

    String resultText = rawResult.toString();

    try {
      final dynamic firstDecode = jsonDecode(resultText);

      if (firstDecode is String) {
        resultText = firstDecode;
      }
    } catch (_) {
      // Some Android WebView versions already return a plain string.
    }

    String readableResult;

    try {
      final dynamic decodedResult = jsonDecode(resultText);

      readableResult = const JsonEncoder.withIndent(
        '  ',
      ).convert(decodedResult);
    } catch (_) {
      readableResult = resultText;
    }

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text(
            'PLAYER DIAGNOSTIC',
            style: TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight:
                  MediaQuery.of(dialogContext).size.height * 0.60,
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                readableResult,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('CLOSE'),
            ),
          ],
        );
      },
    );
  } catch (error) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Player diagnostic ব্যর্থ হয়েছে: $error',
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }
}

Future<void> _installPlaybackTracking() async {
  if (!_directPlayerMode) return;

  try {
    await _playerController.runJavaScript(
      r'''
      (() => {
        if (window.__radioTrackingInstalled) {
          return;
        }

        window.__radioTrackingInstalled = true;
        window.__radioUserWantsPlayback = false;
        window.__radioLastUserAction = 'none';
        window.__radioLastUserActionAt = 0;

        document.addEventListener(
          'click',
          (event) => {
            const target =
              event.target instanceof Element
                ? event.target
                : null;

            const button = target
              ? target.closest(
                  'button, [role="button"]'
                )
              : null;

            if (!button) return;

            const text = (
              button.innerText ||
              button.getAttribute('aria-label') ||
              button.getAttribute('title') ||
              ''
            )
              .replace(/\s+/g, ' ')
              .trim();

            if (/^play$/i.test(text)) {
              window.__radioUserWantsPlayback = true;
              window.__radioLastUserAction = 'play';
              window.__radioLastUserActionAt = Date.now();
            }

            if (/^pause$/i.test(text)) {
              window.__radioUserWantsPlayback = false;
              window.__radioLastUserAction = 'pause';
              window.__radioLastUserActionAt = Date.now();
            }
          },
          true
        );
      })()
      ''',
    );

    if (!mounted) return;

    setState(() {
      _playbackTrackingReady = true;
    });
  } catch (_) {
    if (!mounted) return;

    setState(() {
      _playbackTrackingReady = false;
    });
  }
}

Future<bool> _attemptSmartResume() async {
  if (!mounted ||
      !_directPlayerMode ||
      !_playbackTrackingReady ||
      _smartResumeRunning) {
    return false;
  }

  _smartResumeRunning = true;

  try {
    await Future<void>.delayed(
      const Duration(milliseconds: 350),
    );

    if (!mounted || !_directPlayerMode) {
      return false;
    }

    final Object rawResult =
        await _playerController.runJavaScriptReturningResult(
      r'''
      (() => {
        const audio = document.querySelector('audio');

        const wantsPlayback =
          window.__radioUserWantsPlayback === true;

        const buttons = Array.from(
          document.querySelectorAll(
            'button, [role="button"]'
          )
        );

        const isVisible = (element) => {
          const style =
            window.getComputedStyle(element);

          return style.display !== 'none' &&
              style.visibility !== 'hidden' &&
              element.offsetParent !== null;
        };

        const playButton = buttons.find(
          (button) => {
            const text = (
              button.innerText ||
              button.getAttribute('aria-label') ||
              button.getAttribute('title') ||
              ''
            )
              .replace(/\s+/g, ' ')
              .trim();

            return /^play$/i.test(text) &&
                isVisible(button);
          }
        );

        const result = {
          audioFound: Boolean(audio),
          resumeWanted: wantsPlayback,
          beforePaused:
            audio ? audio.paused : null,
          action: 'none',
          error: '',
        };

        if (!audio) {
          result.action = 'audio-not-found';
          return JSON.stringify(result);
        }

        if (!wantsPlayback) {
          result.action = 'resume-not-wanted';
          return JSON.stringify(result);
        }

        if (!audio.paused) {
          result.action = 'already-playing';
          return JSON.stringify(result);
        }

        window.__radioAutoResumeError = '';

        if (playButton) {
          playButton.click();
          result.action = 'clicked-visible-play';
          return JSON.stringify(result);
        }

        try {
          const playResult = audio.play();

          if (playResult && playResult.catch) {
            playResult.catch((error) => {
              window.__radioAutoResumeError =
                String(error);
            });
          }

          result.action = 'called-audio-play';
        } catch (error) {
          result.action = 'play-call-failed';
          result.error = String(error);
        }

        return JSON.stringify(result);
      })()
      ''',
    );

    String resultText = rawResult.toString();

    try {
      final dynamic firstDecode =
          jsonDecode(resultText);

      if (firstDecode is String) {
        resultText = firstDecode;
      }
    } catch (_) {}

    Map<String, dynamic>? result;

    try {
      final dynamic decoded =
          jsonDecode(resultText);

      if (decoded is Map<String, dynamic>) {
        result = decoded;
      }
    } catch (_) {}

    if (result == null) {
      return false;
    }

    _resumeWanted =
        result['resumeWanted'] == true;

    final String action =
        result['action']?.toString() ?? '';

    if (action == 'already-playing') {
      return true;
    }

    if (action != 'clicked-visible-play' &&
        action != 'called-audio-play') {
      return false;
    }

    await Future<void>.delayed(
      const Duration(milliseconds: 2600),
    );

    if (!mounted || !_directPlayerMode) {
      return false;
    }

    final Object verificationRaw =
        await _playerController
            .runJavaScriptReturningResult(
      r'''
      (() => {
        const audio = document.querySelector('audio');

        return JSON.stringify({
          audioFound: Boolean(audio),
          paused: audio ? audio.paused : null,
          readyState:
            audio ? audio.readyState : null,
          networkState:
            audio ? audio.networkState : null,
          error:
            window.__radioAutoResumeError || '',
        });
      })()
      ''',
    );

    String verificationText =
        verificationRaw.toString();

    try {
      final dynamic firstDecode =
          jsonDecode(verificationText);

      if (firstDecode is String) {
        verificationText = firstDecode;
      }
    } catch (_) {}

    try {
      final dynamic verification =
          jsonDecode(verificationText);

      if (verification is Map<String, dynamic>) {
        return verification['audioFound'] == true &&
            verification['paused'] == false;
      }
    } catch (_) {}

    return false;
  } catch (_) {
    return false;
  } finally {
    _smartResumeRunning = false;
  }
}

Future<void> _openDirectCasterPlayer() async {
  try {
    final Object rawResult =
        await _playerController.runJavaScriptReturningResult(
      r'''
      (() => {
        const frame = document.querySelector(
          'iframe[src*="widgets.cloud.caster.fm"]'
        );

        return frame ? frame.src : '';
      })()
      ''',
    );

    String widgetUrl = rawResult.toString().trim();

    try {
      final dynamic decoded = jsonDecode(widgetUrl);

      if (decoded is String) {
        widgetUrl = decoded;
      }
    } catch (_) {
      widgetUrl = widgetUrl.replaceAll('"', '');
    }

    if (!widgetUrl.startsWith(
      'https://widgets.cloud.caster.fm/',
    )) {
      throw Exception(
        'Caster widget URL পাওয়া যায়নি।',
      );
    }

    if (!mounted) return;

    setState(() {
      _playerLoading = true;
    });

    await _playerController.loadRequest(
      Uri.parse(widgetUrl),
    );
  } catch (error) {
    if (!mounted) return;

    setState(() {
      _playerLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Direct player test চালু করা যায়নি: $error',
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }
}

Future<void> _restoreWrappedPlayer() async {
  if (!mounted) return;

  setState(() {
    _playerLoading = true;
  });

  await _playerController.loadRequest(
    Uri.parse(_playerUrl),
  );

  await _loadRadioStatus();
}

Future<void> _testDirectResume() async {
  try {
    final Object initialRaw =
        await _playerController.runJavaScriptReturningResult(
      r'''
      (() => {
        const audio = document.querySelector('audio');

        const buttons = Array.from(
          document.querySelectorAll('button')
        );

        const isVisible = (element) => {
          const style = window.getComputedStyle(element);

          return style.display !== 'none' &&
              style.visibility !== 'hidden' &&
              element.offsetParent !== null;
        };

        const playButton = buttons.find((button) => {
          const text =
            (button.innerText || '').trim();

          return /^play$/i.test(text) &&
              isVisible(button);
        });

        const result = {
          audioFound: Boolean(audio),
          beforePaused: audio ? audio.paused : null,
          beforeReadyState: audio ? audio.readyState : null,
          beforeNetworkState: audio ? audio.networkState : null,
          visiblePlayFound: Boolean(playButton),
          action: 'none',
          error: '',
        };

        if (!audio) {
          result.action = 'audio-not-found';
          return JSON.stringify(result);
        }

        if (!audio.paused) {
          result.action = 'already-playing';
          return JSON.stringify(result);
        }

        window.__radioResumeError = '';

        if (playButton) {
          playButton.click();
          result.action = 'clicked-visible-play';
          return JSON.stringify(result);
        }

        try {
          const playResult = audio.play();

          if (playResult && playResult.catch) {
            playResult.catch((error) => {
              window.__radioResumeError =
                String(error);
            });
          }

          result.action = 'called-audio-play';
        } catch (error) {
          result.action = 'play-call-failed';
          result.error = String(error);
        }

        return JSON.stringify(result);
      })()
      ''',
    );

    await Future<void>.delayed(
      const Duration(milliseconds: 1800),
    );

    final Object finalRaw =
        await _playerController.runJavaScriptReturningResult(
      r'''
      (() => {
        const audio = document.querySelector('audio');

        return JSON.stringify({
          audioFound: Boolean(audio),
          afterPaused: audio ? audio.paused : null,
          afterEnded: audio ? audio.ended : null,
          afterCurrentTime:
            audio ? audio.currentTime : null,
          afterReadyState:
            audio ? audio.readyState : null,
          afterNetworkState:
            audio ? audio.networkState : null,
          resumeError:
            window.__radioResumeError || '',
        });
      })()
      ''',
    );

    String initialText = initialRaw.toString();
    String finalText = finalRaw.toString();

    try {
      final dynamic decoded = jsonDecode(initialText);

      if (decoded is String) {
        initialText = decoded;
      }
    } catch (_) {}

    try {
      final dynamic decoded = jsonDecode(finalText);

      if (decoded is String) {
        finalText = decoded;
      }
    } catch (_) {}

    String readableInitial = initialText;
    String readableFinal = finalText;

    try {
      readableInitial = const JsonEncoder.withIndent(
        '  ',
      ).convert(jsonDecode(initialText));
    } catch (_) {}

    try {
      readableFinal = const JsonEncoder.withIndent(
        '  ',
      ).convert(jsonDecode(finalText));
    } catch (_) {}

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text(
            'RESUME ENGINE TEST',
            style: TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight:
                  MediaQuery.of(dialogContext).size.height *
                      0.58,
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                'ATTEMPT\n$readableInitial\n\n'
                'RESULT\n$readableFinal',
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('CLOSE'),
            ),
          ],
        );
      },
    );
  } catch (error) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Resume engine test ব্যর্থ হয়েছে: $error',
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }
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
              const CommunityPanel(),
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

          _AnimatedRadioSpectrum(
            isActive: _onAir,
          ),

          const SizedBox(height: 12),

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

const SizedBox(height: 10),

SizedBox(
  width: double.infinity,
  child: OutlinedButton.icon(
    onPressed: _checkPlayerState,
    style: OutlinedButton.styleFrom(
      foregroundColor: folkGreen,
      side: const BorderSide(
        color: folkGreen,
        width: 2,
      ),
      padding: const EdgeInsets.symmetric(
        vertical: 13,
      ),
    ),
    icon: const Icon(
      Icons.manage_search_rounded,
    ),
    label: const Text(
      'CHECK PLAYER STATE',
      style: TextStyle(
        fontWeight: FontWeight.w900,
        letterSpacing: 0.4,
      ),
    ),
  ),
),

const SizedBox(height: 10),

SizedBox(
  width: double.infinity,
  child: FilledButton.icon(
    onPressed: _openDirectCasterPlayer,
    style: FilledButton.styleFrom(
      backgroundColor: folkRed,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(
        vertical: 13,
      ),
    ),
    icon: const Icon(
      Icons.open_in_browser_rounded,
    ),
    label: const Text(
      'TEST DIRECT PLAYER',
      style: TextStyle(
        fontWeight: FontWeight.w900,
        letterSpacing: 0.4,
      ),
    ),
  ),
),

const SizedBox(height: 10),

SizedBox(
  width: double.infinity,
  child: FilledButton.icon(
    onPressed: _testDirectResume,
    style: FilledButton.styleFrom(
      backgroundColor: folkGreen,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(
        vertical: 13,
      ),
    ),
    icon: const Icon(
      Icons.play_circle_outline_rounded,
    ),
    label: const Text(
      'TEST RESUME ENGINE',
      style: TextStyle(
        fontWeight: FontWeight.w900,
        letterSpacing: 0.4,
      ),
    ),
  ),
),

const SizedBox(height: 10),

SizedBox(
  width: double.infinity,
  child: OutlinedButton.icon(
    onPressed: _restoreWrappedPlayer,
    style: OutlinedButton.styleFrom(
      foregroundColor: folkGreen,
      side: const BorderSide(
        color: folkGreen,
        width: 2,
      ),
      padding: const EdgeInsets.symmetric(
        vertical: 13,
      ),
    ),
    icon: const Icon(
      Icons.restore_page_rounded,
    ),
    label: const Text(
      'RESTORE NORMAL PLAYER',
      style: TextStyle(
        fontWeight: FontWeight.w900,
        letterSpacing: 0.4,
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

class _AnimatedRadioSpectrum extends StatefulWidget {
  const _AnimatedRadioSpectrum({
    required this.isActive,
  });

  final bool isActive;

  @override
  State<_AnimatedRadioSpectrum> createState() =>
      _AnimatedRadioSpectrumState();
}

class _AnimatedRadioSpectrumState extends State<_AnimatedRadioSpectrum>
    with SingleTickerProviderStateMixin {
  static const List<double> _phaseOffsets = [
    0.00,
    0.18,
    0.43,
    0.71,
    0.27,
    0.58,
    0.86,
    0.12,
    0.37,
    0.65,
    0.93,
    0.22,
    0.49,
    0.77,
    0.33,
    0.61,
    0.89,
  ];

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1350),
    );

    if (widget.isActive) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(
    covariant _AnimatedRadioSpectrum oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isActive == widget.isActive) return;

    if (widget.isActive) {
      _controller.repeat();
    } else {
      _controller
        ..stop()
        ..value = 0.0;
    }
  }

  double _barHeight(int index) {
    if (!widget.isActive) {
      return 8.0 + ((index % 5) * 1.6);
    }

    final double phase =
        (_controller.value + _phaseOffsets[index]) % 1.0;

    final double primaryWave =
        1.0 - ((phase * 2.0) - 1.0).abs();

    final double shiftedPhase = (phase + 0.37) % 1.0;

    final double secondaryWave =
        1.0 - ((shiftedPhase * 2.0) - 1.0).abs();

    return 8.0 +
        (primaryWave * 28.0) +
        (secondaryWave * 10.0);
  }

  Color _barColor(int index) {
    switch (index % 3) {
      case 0:
        return folkRed;
      case 1:
        return folkYellow;
      default:
        return folkGreen;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 96,
      padding: const EdgeInsets.fromLTRB(16, 11, 16, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF10351F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.isActive
              ? folkGreen
              : Colors.white24,
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(
            color: folkYellow,
            offset: Offset(5, 5),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: widget.isActive
                      ? folkRed
                      : Colors.white38,
                  shape: BoxShape.circle,
                  boxShadow: widget.isActive
                      ? [
                          const BoxShadow(
                            color: folkRed,
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.isActive
                    ? 'ON AIR RHYTHM'
                    : 'SIGNAL STANDBY',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              Text(
                widget.isActive ? 'LIVE' : 'OFF AIR',
                style: TextStyle(
                  color: widget.isActive
                      ? folkYellow
                      : Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (
                BuildContext context,
                Widget? child,
              ) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List<Widget>.generate(
                    _phaseOffsets.length,
                    (int index) {
                      final Color color = _barColor(index);

                      return Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            width: 5,
                            height: _barHeight(index),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius:
                                  BorderRadius.circular(99),
                              boxShadow: widget.isActive
                                  ? [
                                      BoxShadow(
                                        color: color.withAlpha(90),
                                        blurRadius: 6,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
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