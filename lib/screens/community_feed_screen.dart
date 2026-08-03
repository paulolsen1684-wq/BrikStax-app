// lib/screens/community_feed_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../theme/app_theme.dart';
import '../theme/app_themes.dart';
import '../utils/haptics.dart';
import '../widgets/skeleton_loader.dart';
import '../modules/community/models/community_post.dart';
import '../modules/community/services/community_service.dart';
import '../modules/avatar/services/dev_mode.dart';
import '../services/feature_flag_service.dart';
import '../services/device_identity.dart';
import '../utils/image_privacy.dart';

class CommunityFeedScreen extends StatelessWidget {
  const CommunityFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dev mode always bypasses the gate. Otherwise this only unlocks when
    // the Worker's /features flag says it's ready — flip
    // FEATURE_COMMUNITY_FEED=true in Cloudflare dashboard vars, no app
    // update needed.
    final unlocked = DevMode.instance.isOn ||
        FeatureFlagService.instance.communityFeedEnabled;
    return unlocked
        ? const _CommunityFeedBody()
        : const _CommunityComingSoon();
  }
}

class _CommunityComingSoon extends StatelessWidget {
  const _CommunityComingSoon();

  @override
  Widget build(BuildContext context) {
    final bt = context.bt;
    return Scaffold(
      backgroundColor: bt.surface,
      body: SafeArea(
        child: Column(children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            decoration: BoxDecoration(
              color: bt.surface,
              border: Border(
                  bottom: BorderSide(color: bt.cardBorder, width: BT.bw)),
            ),
            child: Row(children: [
              Text('Community', style: BT.display(size: 26, color: bt.tx)),
            ]),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(
                    color: BT.yellow,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: BT.ink, width: BT.bw),
                    boxShadow: BT.shadow,
                  ),
                  child: const Center(
                    child: Icon(Icons.photo_library_outlined,
                        size: 64, color: BT.ink),
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: BT.ink,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text('COMING SOON',
                      style: BT.display(size: 14, color: BT.yellow)),
                ),
                const SizedBox(height: 20),
                Text('Community Feed', style: BT.display(size: 30, color: bt.tx)),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Share photos of your collection and see what other '
                    'BrikStax collectors are building.',
                    style: BT.mono(size: 12, color: bt.tx2),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _CommunityFeedBody extends StatefulWidget {
  const _CommunityFeedBody();
  @override State<_CommunityFeedBody> createState() => _CommunityFeedBodyState();
}

class _CommunityFeedBodyState extends State<_CommunityFeedBody> {
  final _svc = CommunityService.instance;

  @override
  void initState() {
    super.initState();
    _svc.fetchFeed();
  }

  @override
  Widget build(BuildContext context) {
    final bt = context.bt;

    return Scaffold(
      backgroundColor: bt.surface,
      body: Column(children: [
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: bt.surface,
            border: Border(
                bottom: BorderSide(color: bt.cardBorder, width: BT.bw)),
          ),
          child: SafeArea(
            bottom: false,
            child: Row(children: [
              Text('Community', style: BT.display(size: 26, color: bt.tx)),
              const Spacer(),
              GestureDetector(
                onTap: () => _svc.fetchFeed(),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: bt.cardBg,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: bt.cardBorder, width: BT.bw),
                  ),
                  child: Icon(Icons.refresh, color: bt.tx, size: 18),
                ),
              ),
            ]),
          ),
        ),

        Expanded(
          child: ListenableBuilder(
            listenable: _svc,
            builder: (_, __) {
              if (_svc.loading && _svc.feed.isEmpty) {
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 12),
                  itemCount: 3,
                  itemBuilder: (_, __) => Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    decoration: BoxDecoration(
                      color: bt.cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: bt.cardBorder, width: BT.bw),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: SkeletonBox(width: 80, height: 10),
                      ),
                      AspectRatio(
                        aspectRatio: 4 / 3,
                        child: SkeletonBox(
                            borderRadius: BorderRadius.zero),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: SkeletonBox(width: double.infinity, height: 12),
                      ),
                    ]),
                  ),
                );
              }
              if (_svc.error != null && _svc.feed.isEmpty) {
                return _ErrorState(bt: bt, onRetry: () => _svc.fetchFeed());
              }
              if (_svc.feed.isEmpty) {
                return _EmptyState(bt: bt);
              }
              return RefreshIndicator(
                onRefresh: () => _svc.fetchFeed(),
                color: BT.yellow,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(0, 12, 0, 90),
                  itemCount: _svc.feed.length,
                  itemBuilder: (_, i) => _PostCard(post: _svc.feed[i], bt: bt),
                ),
              );
            },
          ),
        ),
      ]),

      floatingActionButton: GestureDetector(
        onTap: () => _showUploadSheet(context),
        child: Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: BT.yellow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: BT.ink, width: BT.bw),
            boxShadow: BT.shadow,
          ),
          child: const Icon(Icons.add, color: BT.ink, size: 26),
        ),
      ),
    );
  }

  void _showUploadSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _UploadSheet(),
    ).then((submitted) {
      // If the sheet reported a successful submission, refresh isn't
      // needed here (new posts are pending, not visible in feed yet) —
      // but we still want to make sure any snackbar has room to show.
      if (submitted == true && mounted) {
        // no-op placeholder for future "your post is pending" banner
      }
    });
  }
}

// ── Post card ──────────────────────────────────────────────────────────────
class _PostCard extends StatelessWidget {
  final CommunityPost  post;
  final BrikStaxColors bt;
  const _PostCard({required this.post, required this.bt});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    decoration: BoxDecoration(
      color: bt.cardBg,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: bt.cardBorder, width: BT.bw),
      boxShadow: [BoxShadow(color: bt.shadowColor, offset: const Offset(3, 3))],
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(children: [
          Expanded(child: Text(post.timeAgo,
              style: BT.mono(size: 9, color: bt.tx3))),
          if (post.setNum != null)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: BT.yellow,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: BT.ink, width: 1.5),
              ),
              child: Text('#${post.setNum}',
                  style: BT.mono(size: 9, color: BT.ink)),
            ),
        ]),
      ),
      // Every photo is cropped to 4:3 at submit time (see _pickImage), so
      // this AspectRatio matches what was actually saved — no re-cropping,
      // no surprise chopped edges.
      AspectRatio(
        aspectRatio: 4 / 3,
        child: Image.network(
          post.imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (_, child, progress) => progress == null
              ? child
              : Container(
                  color: bt.surface2,
                  child: const Center(child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(BT.yellow)))),
          errorBuilder: (_, __, ___) => Container(
            color: bt.surface2,
            child: Icon(Icons.broken_image_outlined,
                color: bt.txMuted, size: 32),
          ),
        ),
      ),
      if (post.caption != null && post.caption!.isNotEmpty)
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(post.caption!,
              style: BT.body(size: 13, color: bt.tx2)),
        ),
    ]),
  );
}

// ── Empty / error states ──────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final BrikStaxColors bt;
  const _EmptyState({required this.bt});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('📸', style: TextStyle(fontSize: 44)),
        const SizedBox(height: 16),
        Text('No posts yet', style: BT.display(size: 22, color: bt.tx)),
        const SizedBox(height: 8),
        Text(
          'Be the first to share a photo of your collection. '
          'Tap + to submit — approved posts show up here.',
          style: BT.mono(size: 11, color: bt.tx2),
          textAlign: TextAlign.center,
        ),
      ]),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  final BrikStaxColors bt;
  final VoidCallback   onRetry;
  const _ErrorState({required this.bt, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.wifi_off, size: 40, color: bt.txMuted),
        const SizedBox(height: 12),
        Text('Couldn\'t load the feed',
            style: BT.body(size: 15, color: bt.tx)),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: onRetry,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: BT.yellow,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: BT.ink, width: BT.bw),
            ),
            child: Text('Retry', style: BT.body(size: 14, color: BT.ink)),
          ),
        ),
      ]),
    ),
  );
}

// ── Upload sheet ───────────────────────────────────────────────────────────
// Fixed: uses DraggableScrollableSheet so content scrolls properly when the
// keyboard opens, instead of overflowing off the bottom of a fixed-height
// Container. Also shows a clear success/rate-limited/error confirmation
// after submitting instead of just silently popping the sheet.
class _UploadSheet extends StatefulWidget {
  const _UploadSheet();
  @override State<_UploadSheet> createState() => _UploadSheetState();
}

class _UploadSheetState extends State<_UploadSheet> {
  final _captionCtrl = TextEditingController();
  final _setNumCtrl  = TextEditingController();
  File? _image;
  bool  _submitting  = false;
  Duration? _cooldown;

  @override
  void initState() {
    super.initState();
    _checkCooldown();
  }

  Future<void> _checkCooldown() async {
    final remaining = await CommunityService.instance.cooldownRemaining();
    if (mounted) setState(() => _cooldown = remaining);
  }

  @override
  void dispose() {
    _captionCtrl.dispose();
    _setNumCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    // Explicit chooser instead of relying solely on the native Photo
    // Picker's built-in camera button — that behavior varies across
    // Android versions/vendor skins (confirmed: didn't show reliably on
    // this test device), so asking directly is more predictable.
    final bt = context.bt;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: bt.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: bt.cardBorder, width: BT.bw),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: bt.cardBorder,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: bt.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: bt.cardBorder, width: BT.bw),
                ),
                child: Row(children: [
                  Icon(Icons.photo_camera_outlined,
                      color: bt.tx, size: 20),
                  const SizedBox(width: 12),
                  Text('Take a photo',
                      style: BT.body(size: 14, color: bt.tx)),
                ]),
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: bt.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: bt.cardBorder, width: BT.bw),
                ),
                child: Row(children: [
                  Icon(Icons.photo_library_outlined,
                      color: bt.tx, size: 20),
                  const SizedBox(width: 12),
                  Text('Choose from gallery',
                      style: BT.body(size: 14, color: bt.tx)),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );

    if (source == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: source, maxWidth: 1600, imageQuality: 85);
    if (picked == null) return;

    // Fixed 4:3 crop — the user drags/pinches to choose WHICH PART of the
    // photo to keep, but the aspect ratio itself is locked so every feed
    // photo displays consistently.
    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      compressQuality: 85,
      aspectRatio: const CropAspectRatio(ratioX: 4, ratioY: 3),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Choose what to share',
          toolbarColor: const Color(0xFF0A0907),
          toolbarWidgetColor: const Color(0xFFFFCB00),
          statusBarColor: const Color(0xFF0A0907),
          backgroundColor: const Color(0xFF121212),
          activeControlsWidgetColor: const Color(0xFFFFCB00),
          lockAspectRatio: true,
        ),
      ],
    );
    if (cropped == null) return;

    // Strip EXIF/GPS metadata before this photo ever gets attached to an
    // upload. Re-encodes the file from scratch so no location data,
    // device info, or other metadata survives — see ImagePrivacy for why
    // this approach is more reliable than assuming the cropper already
    // did it.
    final cleaned = await ImagePrivacy.stripMetadata(File(cropped.path));
    setState(() => _image = cleaned ?? File(cropped.path));
  }


  String _formatCooldown(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  Future<void> _submit() async {
    if (_image == null) return;
    setState(() => _submitting = true);

    final result = await CommunityService.instance.submitPost(
      userId:  DeviceIdentity.instance.id,
      image:   _image!,
      caption: _captionCtrl.text,
      setNum:  _setNumCtrl.text,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (result.ok) {
      BrikHaptics.heavy();
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        duration: const Duration(seconds: 4),
        backgroundColor: BT.green,
        content: Row(children: const [
          Icon(Icons.check_circle, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Expanded(child: Text(
            'Submitted! It\'ll appear in the feed once approved.',
            style: TextStyle(color: Colors.white),
          )),
        ]),
      ));
    } else if (result.rateLimited) {
      setState(() => _cooldown = result.cooldownRemaining);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          'You can post again in ${_formatCooldown(result.cooldownRemaining!)}.',
        ),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.errorMessage ?? 'Upload failed — try again'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bt = context.bt;
    final onCooldown = _cooldown != null && _cooldown! > Duration.zero;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: bt.cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: bt.cardBorder, width: BT.bw)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                Center(child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: bt.cardBorder,
                      borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Text('Share a photo', style: BT.display(size: 22, color: bt.tx)),
                const SizedBox(height: 14),

                if (onCooldown)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: BT.yellowBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: BT.yellow3, width: BT.bw),
                    ),
                    child: Row(children: [
                      const Icon(Icons.timer_outlined,
                          color: BT.gold, size: 18),
                      const SizedBox(width: 10),
                      Expanded(child: Text(
                        'You can share another photo in '
                        '${_formatCooldown(_cooldown!)}.',
                        style: BT.mono(size: 11, color: BT.gold),
                      )),
                    ]),
                  ),

                GestureDetector(
                  onTap: onCooldown ? null : _pickImage,
                  child: Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      color: bt.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: bt.cardBorder, width: BT.bw),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _image != null
                        ? Image.file(_image!, fit: BoxFit.cover,
                            width: double.infinity)
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_outlined,
                                  size: 32, color: bt.txMuted),
                              const SizedBox(height: 8),
                              Text('Tap to choose a photo',
                                  style: BT.mono(size: 11, color: bt.tx3)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 14),

                Text('SET NUMBER (OPTIONAL)',
                    style: BT.mono(size: 9, color: bt.tx3)),
                const SizedBox(height: 5),
                Container(
                  decoration: BoxDecoration(
                    color: bt.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: bt.cardBorder, width: BT.bw),
                  ),
                  child: TextField(
                    controller: _setNumCtrl,
                    enabled: !onCooldown,
                    keyboardType: TextInputType.number,
                    style: BT.mono(size: 14, color: bt.tx),
                    decoration: InputDecoration(
                      hintText: 'e.g. 75192',
                      hintStyle: BT.mono(size: 14, color: bt.txMuted),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                Text('CAPTION', style: BT.mono(size: 9, color: bt.tx3)),
                const SizedBox(height: 5),
                Container(
                  decoration: BoxDecoration(
                    color: bt.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: bt.cardBorder, width: BT.bw),
                  ),
                  child: TextField(
                    controller: _captionCtrl,
                    enabled: !onCooldown,
                    maxLines: 3,
                    style: BT.body(size: 13, color: bt.tx),
                    decoration: InputDecoration(
                      hintText: 'Tell the community about it…',
                      hintStyle: BT.mono(size: 12, color: bt.txMuted),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                GestureDetector(
                  onTap: (_image == null || _submitting || onCooldown)
                      ? null : _submit,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: (_image == null || onCooldown)
                          ? bt.surface2 : BT.yellow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: (_image == null || onCooldown)
                              ? bt.cardBorder : BT.ink,
                          width: BT.bw),
                      boxShadow: (_image == null || onCooldown)
                          ? [] : BT.shadow,
                    ),
                    child: _submitting
                        ? const Center(child: SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(BT.ink))))
                        : Text(
                            onCooldown
                                ? 'Come back in ${_formatCooldown(_cooldown!)}'
                                : 'Submit for review',
                            textAlign: TextAlign.center,
                            style: BT.body(size: 15,
                                color: (_image == null || onCooldown)
                                    ? bt.txMuted : BT.ink)),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Photos are reviewed before appearing in the feed. '
                  'Only share photos you took yourself. One post every 6 hours.',
                  style: BT.mono(size: 9, color: bt.tx3),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
