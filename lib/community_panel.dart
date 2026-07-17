import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

const Color _folkRed = Color(0xFFD62828);
const Color _folkYellow = Color(0xFFF4B400);
const Color _folkOrange = Color(0xFFF46A1A);
const Color _folkGreen = Color(0xFF138A36);
const Color _folkCream = Color(0xFFFFF4D6);
const Color _folkWhite = Color(0xFFFFFFFF);
const Color _folkInk = Color(0xFF202020);
const Color _folkMuted = Color(0xFF6C675F);

class CommunityPanel extends StatefulWidget {
  const CommunityPanel({super.key});

  @override
  State<CommunityPanel> createState() => _CommunityPanelState();
}

class _CommunityPanelState extends State<CommunityPanel> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _adminEmailController = TextEditingController();
  final TextEditingController _adminPasswordController =
      TextEditingController();
  final TextEditingController _shoutController = TextEditingController();

  StreamSubscription<User?>? _authSubscription;

  bool _authReady = false;
  bool _isAdmin = false;
  bool _showAdminLogin = false;
  bool _hidePassword = true;
  bool _authBusy = false;
  bool _commentBusy = false;
  bool _shoutBusy = false;
  String? _authError;

  @override
  void initState() {
    super.initState();
    _authSubscription = _auth.authStateChanges().listen(_handleAuthChanged);
    _ensureSignedIn();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _nameController.dispose();
    _commentController.dispose();
    _adminEmailController.dispose();
    _adminPasswordController.dispose();
    _shoutController.dispose();
    super.dispose();
  }

  Future<void> _ensureSignedIn() async {
    if (_auth.currentUser != null) return;

    try {
      await _auth.signInAnonymously();
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _authReady = false;
        _authError = _authErrorMessage(error);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _authReady = false;
        _authError = 'কমিউনিটি সংযোগ তৈরি করা যাচ্ছে না। আবার চেষ্টা করুন।';
      });
    }
  }

  Future<void> _handleAuthChanged(User? user) async {
    if (!mounted) return;

    if (user == null) {
      setState(() {
        _authReady = false;
        _isAdmin = false;
      });
      return;
    }

    final String uid = user.uid;
    bool admin = false;
    String? errorMessage;

    try {
      final DocumentSnapshot<Map<String, dynamic>> adminDocument =
          await _firestore.collection('admins').doc(uid).get();
      admin = adminDocument.exists;
    } on FirebaseException {
      errorMessage = 'কমিউনিটি ডেটা যাচাই করা যাচ্ছে না।';
    }

    if (!mounted || _auth.currentUser?.uid != uid) return;

    setState(() {
      _authReady = true;
      _isAdmin = admin;
      _authError = errorMessage;
      if (admin) {
        _showAdminLogin = false;
      }
    });

    if (admin) {
      await _loadCurrentShout();
    }
  }

  Future<void> _loadCurrentShout() async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> document = await _firestore
          .collection('shouts')
          .doc('current')
          .get();
      final String message =
          document.data()?['message']?.toString().trim() ?? '';

      if (!mounted) return;
      _shoutController.text = message;
    } catch (_) {
      // The live shout stream will show an error if the read fails.
    }
  }

  Future<void> _loginAsAdmin() async {
    final String email = _adminEmailController.text.trim();
    final String password = _adminPasswordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Admin email এবং password লিখুন।');
      return;
    }

    setState(() {
      _authBusy = true;
    });

    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = credential.user;
      if (user == null) {
        throw StateError('Admin user was not returned.');
      }

      final DocumentSnapshot<Map<String, dynamic>> adminDocument =
          await _firestore.collection('admins').doc(user.uid).get();

      if (!adminDocument.exists) {
        await _auth.signOut();
        await _auth.signInAnonymously();
        throw StateError('This account is not an admin.');
      }

      _adminPasswordController.clear();
      if (!mounted) return;
      setState(() {
        _showAdminLogin = false;
        _isAdmin = true;
      });
      _showSnackBar('Admin login সফল হয়েছে।');
      await _loadCurrentShout();
    } on FirebaseAuthException catch (error) {
      _showSnackBar(_authErrorMessage(error));
    } on StateError {
      _showSnackBar('এই account-এর Admin permission নেই।');
    } catch (_) {
      _showSnackBar('Admin login করা যাচ্ছে না। আবার চেষ্টা করুন।');
    } finally {
      if (mounted) {
        setState(() {
          _authBusy = false;
        });
      }
    }
  }

  Future<void> _logoutAdmin() async {
    setState(() {
      _authBusy = true;
    });

    try {
      await _auth.signOut();
      await _auth.signInAnonymously();
      _adminPasswordController.clear();
      _shoutController.clear();
      if (!mounted) return;
      setState(() {
        _isAdmin = false;
        _showAdminLogin = false;
      });
      _showSnackBar('Admin logout হয়েছে।');
    } catch (_) {
      _showSnackBar('Logout করা যাচ্ছে না। আবার চেষ্টা করুন।');
    } finally {
      if (mounted) {
        setState(() {
          _authBusy = false;
        });
      }
    }
  }

  Future<void> _sendComment() async {
    final String name = _nameController.text.trim();
    final String message = _commentController.text.trim();

    if (name.isEmpty) {
      _showSnackBar('আপনার নাম লিখুন।');
      return;
    }

    if (message.isEmpty) {
      _showSnackBar('আপনার মন্তব্য লিখুন।');
      return;
    }

    if (name.length > 40 || message.length > 300) {
      _showSnackBar('নাম বা মন্তব্য নির্ধারিত সীমার চেয়ে বড় হয়েছে।');
      return;
    }

    if (_auth.currentUser == null) {
      await _ensureSignedIn();
    }

    final User? user = _auth.currentUser;
    if (user == null) {
      _showSnackBar('কমিউনিটি সংযোগ পাওয়া যাচ্ছে না।');
      return;
    }

    setState(() {
      _commentBusy = true;
    });

    try {
      await _firestore.collection('comments').add(<String, dynamic>{
        'name': name,
        'message': message,
        'userId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _commentController.clear();
      _showSnackBar('আপনার মন্তব্য প্রকাশিত হয়েছে।');
    } on FirebaseException {
      _showSnackBar('মন্তব্য পাঠানো যাচ্ছে না। আবার চেষ্টা করুন।');
    } finally {
      if (mounted) {
        setState(() {
          _commentBusy = false;
        });
      }
    }
  }

  Future<void> _publishShout() async {
    if (!_isAdmin || _auth.currentUser == null) return;

    final String message = _shoutController.text.trim();
    if (message.isEmpty) {
      _showSnackBar('Shout message লিখুন।');
      return;
    }

    setState(() {
      _shoutBusy = true;
    });

    try {
      await _firestore
          .collection('shouts')
          .doc('current')
          .set(<String, dynamic>{
            'message': message,
            'adminUid': _auth.currentUser!.uid,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      _showSnackBar('Admin Shout প্রকাশিত হয়েছে।');
    } on FirebaseException {
      _showSnackBar('Shout প্রকাশ করা যাচ্ছে না।');
    } finally {
      if (mounted) {
        setState(() {
          _shoutBusy = false;
        });
      }
    }
  }

  Future<void> _clearShout() async {
    if (!_isAdmin) return;

    final bool confirmed = await _confirmAction(
      title: 'Shout সরাবেন?',
      message:
          'বর্তমান Admin Shout সকল ব্যবহারকারীর অ্যাপ থেকে সরিয়ে দেওয়া হবে।',
      confirmLabel: 'REMOVE',
    );

    if (!confirmed) return;

    setState(() {
      _shoutBusy = true;
    });

    try {
      await _firestore.collection('shouts').doc('current').delete();
      _shoutController.clear();
      _showSnackBar('Admin Shout সরানো হয়েছে।');
    } on FirebaseException {
      _showSnackBar('Shout সরানো যাচ্ছে না।');
    } finally {
      if (mounted) {
        setState(() {
          _shoutBusy = false;
        });
      }
    }
  }

  Future<void> _deleteComment(String documentId) async {
    if (!_isAdmin) return;

    final bool confirmed = await _confirmAction(
      title: 'মন্তব্য মুছবেন?',
      message: 'এই মন্তব্যটি স্থায়ীভাবে মুছে যাবে।',
      confirmLabel: 'DELETE',
    );

    if (!confirmed) return;

    try {
      await _firestore.collection('comments').doc(documentId).delete();
      _showSnackBar('মন্তব্য মুছে দেওয়া হয়েছে।');
    } on FirebaseException {
      _showSnackBar('মন্তব্য মুছতে সমস্যা হয়েছে।');
    }
  }

  Future<bool> _confirmAction({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('CANCEL'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(backgroundColor: _folkRed),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  String _authErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'সঠিক Admin email লিখুন।';
      case 'invalid-credential':
      case 'user-not-found':
      case 'wrong-password':
        return 'Admin email অথবা password সঠিক নয়।';
      case 'user-disabled':
        return 'এই Admin account বন্ধ করা হয়েছে।';
      case 'too-many-requests':
        return 'অনেকবার চেষ্টা করা হয়েছে। কিছুক্ষণ পরে আবার চেষ্টা করুন।';
      case 'network-request-failed':
        return 'ইন্টারনেট সংযোগ পরীক্ষা করুন।';
      case 'operation-not-allowed':
        return 'Firebase Authentication provider চালু নেই।';
      default:
        return 'Authentication সম্পন্ন করা যাচ্ছে না।';
    }
  }

  String _formatTimestamp(Object? value) {
    if (value is! Timestamp) return 'এইমাত্র';

    final DateTime dateTime = value.toDate().toLocal();
    final String day = dateTime.day.toString().padLeft(2, '0');
    final String month = dateTime.month.toString().padLeft(2, '0');
    final String hour = dateTime.hour.toString().padLeft(2, '0');
    final String minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day/$month • $hour:$minute';
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _folkYellow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _folkInk, width: 3),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildHeader(),
            const SizedBox(height: 12),
            _buildConnectionNotice(),
            if (_showAdminLogin && !_isAdmin) ...<Widget>[
              const SizedBox(height: 12),
              _buildAdminLoginCard(),
            ],
            const SizedBox(height: 14),
            _buildLiveShout(),
            if (_isAdmin) ...<Widget>[
              const SizedBox(height: 14),
              _buildAdminShoutControls(),
            ],
            const SizedBox(height: 18),
            _buildCommentComposer(),
            const SizedBox(height: 18),
            _buildCommentsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: <Widget>[
        const Icon(Icons.campaign_rounded, color: _folkRed, size: 28),
        const SizedBox(width: 9),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'SHOUT & LIVE COMMENTS',
                style: TextStyle(
                  color: _folkRed,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'RADIO CHARU কমিউনিটির সঙ্গে যুক্ত থাকুন',
                style: TextStyle(
                  color: _folkInk,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        if (_isAdmin)
          OutlinedButton.icon(
            onPressed: _authBusy ? null : _logoutAdmin,
            style: OutlinedButton.styleFrom(
              foregroundColor: _folkRed,
              side: const BorderSide(color: _folkRed, width: 2),
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            icon: const Icon(Icons.logout_rounded, size: 17),
            label: const Text(
              'LOGOUT',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
            ),
          )
        else
          OutlinedButton.icon(
            onPressed: _authBusy
                ? null
                : () {
                    setState(() {
                      _showAdminLogin = !_showAdminLogin;
                    });
                  },
            style: OutlinedButton.styleFrom(
              foregroundColor: _folkInk,
              side: const BorderSide(color: _folkInk, width: 2),
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            icon: const Icon(Icons.admin_panel_settings_rounded, size: 17),
            label: const Text(
              'ADMIN',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
            ),
          ),
      ],
    );
  }

  Widget _buildConnectionNotice() {
    if (!_authReady && _authError == null) {
      return const Row(
        children: <Widget>[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: _folkGreen,
            ),
          ),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'কমিউনিটি সংযোগ তৈরি হচ্ছে...',
              style: TextStyle(
                color: _folkInk,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      );
    }

    if (_authError != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _folkWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _folkRed, width: 2),
        ),
        child: Row(
          children: <Widget>[
            const Icon(Icons.error_outline_rounded, color: _folkRed),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                _authError!,
                style: const TextStyle(
                  color: _folkInk,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Retry',
              onPressed: _ensureSignedIn,
              icon: const Icon(Icons.refresh_rounded, color: _folkGreen),
            ),
          ],
        ),
      );
    }

    return Row(
      children: <Widget>[
        Icon(
          _isAdmin ? Icons.verified_user_rounded : Icons.people_alt_rounded,
          color: _isAdmin ? _folkRed : _folkGreen,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _isAdmin ? 'Admin mode চালু আছে' : 'Live community সংযোগ প্রস্তুত',
            style: const TextStyle(
              color: _folkInk,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdminLoginCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _folkWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _folkInk, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'ADMIN LOGIN',
            style: TextStyle(
              color: _folkRed,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _adminEmailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const <String>[AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'Admin email',
              prefixIcon: Icon(Icons.email_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 11),
          TextField(
            controller: _adminPasswordController,
            obscureText: _hidePassword,
            textInputAction: TextInputAction.done,
            autofillHints: const <String>[AutofillHints.password],
            onSubmitted: (_) {
              if (!_authBusy) {
                _loginAsAdmin();
              }
            },
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _hidePassword = !_hidePassword;
                  });
                },
                icon: Icon(
                  _hidePassword
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _authBusy ? null : _loginAsAdmin,
              style: FilledButton.styleFrom(
                backgroundColor: _folkGreen,
                foregroundColor: _folkWhite,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              icon: _authBusy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: _folkWhite,
                      ),
                    )
                  : const Icon(Icons.login_rounded),
              label: const Text(
                'LOGIN AS ADMIN',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveShout() {
    if (!_authReady) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _firestore.collection('shouts').doc('current').snapshots(),
      builder:
          (
            BuildContext context,
            AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snapshot,
          ) {
            if (snapshot.hasError) {
              return _messageCard(
                icon: Icons.warning_amber_rounded,
                title: 'SHOUT পাওয়া যাচ্ছে না',
                message: 'ইন্টারনেট সংযোগ পরীক্ষা করুন।',
                color: _folkOrange,
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(color: _folkRed),
                ),
              );
            }

            final Map<String, dynamic>? data = snapshot.data?.data();
            final String message = data?['message']?.toString().trim() ?? '';

            if (message.isEmpty) {
              return _messageCard(
                icon: Icons.notifications_none_rounded,
                title: 'ADMIN SHOUT',
                message: 'এই মুহূর্তে কোনো বিশেষ ঘোষণা নেই।',
                color: _folkGreen,
              );
            }

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _folkRed,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _folkWhite, width: 3),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Row(
                    children: <Widget>[
                      Icon(Icons.campaign_rounded, color: _folkWhite, size: 23),
                      SizedBox(width: 8),
                      Text(
                        'ADMIN SHOUT',
                        style: TextStyle(
                          color: _folkWhite,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    style: const TextStyle(
                      color: _folkWhite,
                      fontSize: 16,
                      height: 1.45,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'আপডেট: ${_formatTimestamp(data?['updatedAt'])}',
                    style: const TextStyle(
                      color: _folkWhite,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          },
    );
  }

  Widget _messageCard({
    required IconData icon,
    required String title,
    required String message,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _folkWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: color, size: 27),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: const TextStyle(
                    color: _folkInk,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminShoutControls() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _folkWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _folkRed, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'MANAGE ADMIN SHOUT',
            style: TextStyle(
              color: _folkRed,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _shoutController,
            minLines: 2,
            maxLines: 4,
            maxLength: 240,
            decoration: const InputDecoration(
              hintText: 'সকল ব্যবহারকারীর জন্য একটি ঘোষণা লিখুন...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.icon(
                  onPressed: _shoutBusy ? null : _publishShout,
                  style: FilledButton.styleFrom(
                    backgroundColor: _folkGreen,
                    foregroundColor: _folkWhite,
                  ),
                  icon: const Icon(Icons.send_rounded),
                  label: const Text(
                    'PUBLISH',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _shoutBusy ? null : _clearShout,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _folkRed,
                    side: const BorderSide(color: _folkRed, width: 2),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text(
                    'REMOVE',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentComposer() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _folkWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _folkGreen, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(Icons.edit_note_rounded, color: _folkGreen, size: 25),
              SizedBox(width: 8),
              Text(
                'আপনার মন্তব্য লিখুন',
                style: TextStyle(
                  color: _folkGreen,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            maxLength: 40,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'আপনার নাম',
              prefixIcon: Icon(Icons.person_outline_rounded),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _commentController,
            minLines: 2,
            maxLines: 4,
            maxLength: 300,
            decoration: const InputDecoration(
              labelText: 'আপনার মন্তব্য',
              alignLabelWithHint: true,
              prefixIcon: Padding(
                padding: EdgeInsets.only(bottom: 45),
                child: Icon(Icons.chat_bubble_outline_rounded),
              ),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: !_authReady || _commentBusy ? null : _sendComment,
              style: FilledButton.styleFrom(
                backgroundColor: _folkOrange,
                foregroundColor: _folkWhite,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              icon: _commentBusy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: _folkWhite,
                      ),
                    )
                  : const Icon(Icons.send_rounded),
              label: const Text(
                'SEND COMMENT',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsList() {
    if (!_authReady) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Row(
          children: <Widget>[
            Icon(Icons.forum_rounded, color: _folkInk, size: 24),
            SizedBox(width: 8),
            Text(
              'LIVE COMMENTS',
              style: TextStyle(
                color: _folkInk,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _firestore
              .collection('comments')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder:
              (
                BuildContext context,
                AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot,
              ) {
                if (snapshot.hasError) {
                  return _messageCard(
                    icon: Icons.warning_amber_rounded,
                    title: 'COMMENTS পাওয়া যাচ্ছে না',
                    message:
                        'ইন্টারনেট সংযোগ অথবা Firestore Rules পরীক্ষা করুন।',
                    color: _folkRed,
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(18),
                      child: CircularProgressIndicator(color: _folkGreen),
                    ),
                  );
                }

                final List<QueryDocumentSnapshot<Map<String, dynamic>>>
                documents =
                    snapshot.data?.docs ??
                    <QueryDocumentSnapshot<Map<String, dynamic>>>[];

                if (documents.isEmpty) {
                  return _messageCard(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'প্রথম মন্তব্যটি আপনিই লিখুন',
                    message: 'এখনো কোনো Live Comment প্রকাশিত হয়নি।',
                    color: _folkGreen,
                  );
                }

                return Container(
                  // Five compact comment rows remain visible; older comments
                  // stay available by scrolling within this single panel.
                  height: 388,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: _folkWhite,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: _folkInk, width: 1.5),
                  ),
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemExtent: 77,
                      itemCount: documents.length,
                      itemBuilder: (BuildContext context, int index) {
                        final QueryDocumentSnapshot<Map<String, dynamic>>
                        document = documents[index];
                        final bool isLastComment =
                            index == documents.length - 1;
                        return Column(
                          children: <Widget>[
                            Expanded(child: _buildCommentCard(document)),
                            if (!isLastComment)
                              const SizedBox(
                                height: 2,
                                width: double.infinity,
                                child: ColoredBox(color: Color(0xFF969696)),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                );
              },
        ),
      ],
    );
  }

  Widget _buildCommentCard(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final Map<String, dynamic> data = document.data();
    final String name = data['name']?.toString().trim().isNotEmpty == true
        ? data['name'].toString().trim()
        : 'শ্রোতা';
    final String message = data['message']?.toString().trim() ?? '';
    final String userId = data['userId']?.toString() ?? '';
    final bool isOwnComment = _auth.currentUser?.uid == userId;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      color: isOwnComment ? const Color(0xFFFFF0E5) : _folkWhite,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CircleAvatar(
            radius: 19,
            backgroundColor: isOwnComment ? _folkOrange : _folkGreen,
            foregroundColor: _folkWhite,
            child: Text(
              String.fromCharCode(name.runes.first).toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        isOwnComment ? '$name • আপনি' : name,
                        style: const TextStyle(
                          color: _folkRed,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      _formatTimestamp(data['createdAt']),
                      style: const TextStyle(
                        color: _folkMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _folkInk,
                    fontSize: 14,
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (_isAdmin) ...<Widget>[
            const SizedBox(width: 4),
            IconButton(
              tooltip: 'Delete comment',
              onPressed: () => _deleteComment(document.id),
              icon: const Icon(Icons.delete_outline_rounded, color: _folkRed),
            ),
          ],
        ],
      ),
    );
  }
}
