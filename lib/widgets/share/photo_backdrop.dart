// lib/widgets/share/photo_backdrop.dart
//
// Shared "share this card over your own photo" helper, used by the Den,
// Collection, and Set share screens so none of them reinvent their own
// photo picker or compositing. Picking reuses the same camera/gallery
// bottom-sheet pattern community_feed_screen.dart already established --
// the native picker's own built-in camera button isn't reliable across
// Android skins, so this asks explicitly instead.
//
// When no photo is picked, PhotoBackdropCard just renders [card] unchanged
// -- every share screen's existing plain-card look (a themed card straight
// to the feed) is the default. Only once a photo is picked does the card
// become a compact "sticker" overlaid on a fixed-ratio canvas.
//
// Two formats, added 2026-08-17 (see ShareFormat) -- Story (9:16, the
// original shape, best for Instagram/Snapchat Stories) and Post (4:5,
// better for a normal feed post where a tall 9:16 image gets awkwardly
// cropped). Applies to BOTH this photo-backdrop path AND the plain
// card-only path via FixedRatioCanvas below -- card-only mode never had a
// fixed canvas before this, just the card's own natural height.
//
// Crop step added 2026-08-19: picking used to hand the raw photo straight
// to PhotoBackdropCard, which BoxFit.cover-crops it into the canvas with
// zero user visibility into what actually gets cut off. pickBackdropPhoto
// now runs the picked photo through image_cropper (already a pubspec
// dependency, and Android's native crop activity + BrikStaxCropTheme were
// already fully set up in AndroidManifest.xml/styles.xml -- just never
// wired into any Dart code before this), so what the user frames in the
// crop UI is exactly what shows in the final card, not a guess.
//
// Crop lock dropped 2026-08-20, real user complaint: the crop step used to
// force-lock to [format]'s exact aspect ratio (9:16/4:5), and BoxFit.cover
// then filled the canvas edge-to-edge with whatever that produced -- for a
// photo that isn't naturally that tall/narrow, the only way to satisfy the
// lock was to crop out real content (there was no way to "zoom out" past
// the source photo's own bounds, a hard platform limit of the native crop
// tool, not a bug in this code). Fixed two ways together, since either one
// alone doesn't help: the crop step is now freeform (no forced ratio), and
// PhotoBackdropCard below switched from BoxFit.cover to BoxFit.contain
// over a cream stud-textured background (reusing FixedRatioCanvas's own
// backdrop) -- whatever shape the user crops to now just letterboxes onto
// the canvas as a visible border instead of being force-cropped further.
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_themes.dart';
import '../../services/whats_new_service.dart';
import '../whats_new_banner.dart';

enum ShareFormat { story, post }

extension ShareFormatX on ShareFormat {
  String get label => this == ShareFormat.story ? 'Story · 9:16' : 'Post · 4:5';
  double get width => 540;
  // Post corrected 2026-08-19 from a guessed 3:4 to Instagram's actual feed
  // ratio (4:5, their max-height standard) -- 540 * 5/4 = 675. Story's 9:16
  // was already correct (also IG's real Story/Reel ratio), unchanged.
  double get height => this == ShareFormat.story ? 960 : 675;
  double get maxStickerHeight => height * .34;
}

/// The Story/Post segmented toggle, shared across all three share screens.
class FormatToggle extends StatelessWidget {
  final ShareFormat format;
  final ValueChanged<ShareFormat> onChanged;
  const FormatToggle({super.key, required this.format, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget seg(ShareFormat f) {
      final on = format == f;
      return Expanded(child: GestureDetector(
        onTap: () => onChanged(f),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: on ? BT.yellow : BT.white,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: BT.ink, width: BT.bw),
            boxShadow: on ? null : BT.shadowSm,
          ),
          child: Text(f.label, textAlign: TextAlign.center,
              style: BT.mono(size: 10, color: BT.ink)),
        ),
      ));
    }
    return Row(children: [seg(ShareFormat.story), const SizedBox(width: 8), seg(ShareFormat.post)]);
  }
}

/// Card-only mode's canvas: pins [card] to [format]'s aspect ratio on a
/// stud-textured backdrop (reuses StudBackground, the same LEGO-stud dot
/// pattern already used for empty states elsewhere in the app) instead of
/// the card's own bare natural height. Width is fixed at [format.width];
/// height is *at least* [format.height] but grows for a card that needs
/// more room -- ConstrainedBox's minHeight + Center's own well-defined
/// shrink-wrap-under-unbounded-max behavior means this never crops content,
/// it just stops being exactly on-ratio in the rare case a card is taller
/// than expected (safer than a hard-fixed height that could silently clip).
class FixedRatioCanvas extends StatelessWidget {
  final Widget card;
  final ShareFormat format;
  const FixedRatioCanvas({super.key, required this.card, required this.format});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: BT.ink, width: BT.bw),
      boxShadow: BT.shadow,
    ),
    clipBehavior: Clip.antiAlias,
    child: ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: format.width, maxWidth: format.width, minHeight: format.height,
      ),
      child: StudBackground(color: BT.cream, child: Center(child: card)),
    ),
  );
}

/// Picks a photo (camera or gallery), then crops it via image_cropper's
/// native platform UI -- freeform, no forced aspect ratio (see the header
/// comment above for why: a locked ratio meant "zoom out" wasn't possible,
/// since a crop tool can't show more than the source photo actually
/// captured). Whatever shape the user crops to gets letterboxed onto the
/// canvas by PhotoBackdropCard, not force-filled. Returns null if the user
/// cancels either step.
Future<File?> pickBackdropPhoto(BuildContext context) async {
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: bt.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: bt.cardBorder, width: BT.bw),
              ),
              child: Row(children: [
                Icon(Icons.photo_camera_outlined, color: bt.tx, size: 20),
                const SizedBox(width: 12),
                Text('Take a photo', style: BT.body(size: 14, color: bt.tx)),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: bt.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: bt.cardBorder, width: BT.bw),
              ),
              child: Row(children: [
                Icon(Icons.photo_library_outlined, color: bt.tx, size: 20),
                const SizedBox(width: 12),
                Text('Choose from gallery', style: BT.body(size: 14, color: bt.tx)),
              ]),
            ),
          ),
        ]),
      ),
    ),
  );
  if (source == null) return null;
  final picked = await ImagePicker()
      .pickImage(source: source, maxWidth: 1600, imageQuality: 90);
  if (picked == null) return null;

  // Freeform -- no aspectRatio passed, lockAspectRatio:false on both
  // platforms -- so the user can crop to whatever shape actually fits what
  // they want in frame; PhotoBackdropCard letterboxes the result onto the
  // fixed-ratio canvas instead of forcing it to match. Colors still match
  // BrikStax's ink/yellow brand pair; Android additionally already has
  // BrikStaxCropTheme wired up natively (AndroidManifest.xml/styles.xml).
  //
  // A persistent 3x3 rule-of-thirds grid (showCropGrid, added 2026-08-19
  // per user request for "focus" guidance on the crop screen itself) sits
  // permanently over the crop box, not just while dragging -- since this
  // is a real native screen (Android's UCropActivity / iOS's
  // TOCropViewController), not a Flutter widget, there's no way to
  // overlay custom Flutter UI on it; this grid option is the actual
  // native crop tool's own composition-guide feature, just switched on
  // and styled to match. iOS's native cropper already shows its own
  // built-in grid while dragging as standard platform behavior -- nothing
  // to configure there.
  final cropped = await ImageCropper().cropImage(
    sourcePath: picked.path,
    compressQuality: 90,
    uiSettings: [
      AndroidUiSettings(
        toolbarTitle: 'Crop Photo',
        toolbarColor: BT.ink,
        toolbarWidgetColor: BT.yellow,
        activeControlsWidgetColor: BT.yellow,
        statusBarLight: false,
        lockAspectRatio: false,
        showCropGrid: true,
        cropGridRowCount: 3,
        cropGridColumnCount: 3,
        cropGridColor: BT.yellow.withOpacity(.7),
        cropGridStrokeWidth: 1,
        cropFrameColor: BT.yellow,
      ),
      IOSUiSettings(
        title: 'Crop Photo',
        aspectRatioLockEnabled: false,
        resetAspectRatioEnabled: true,
        aspectRatioPickerButtonHidden: true,
      ),
    ],
  );
  if (cropped == null) return null; // user backed out of the crop step

  // "Crop & frame your own photo" quest task -- see whats_new_service.dart.
  // One shared call site here covers all three share screens, unlike the
  // open/format tasks which need their own hook per screen.
  final result = await WhatsNewService.instance.completeTask('crop_own_photo');
  if (context.mounted) showWhatsNewFeedback(context, result);

  return File(cropped.path);
}

/// Composites [card] as a sticker over [photo] on a canvas sized to
/// [format] (Story 9:16 or Post 4:5). Returns [card] unchanged when [photo]
/// is null -- every share screen's existing plain-card look is the default;
/// this only changes anything once the user opts into a photo backdrop.
///
/// [card] is capped at [format]'s maxStickerHeight by default -- this is
/// the actual fix for the original "sticker swallows the whole photo" bug
/// (den_share_screen.dart's/set_share_screen.dart's/collection_share_screen
/// .dart's own card widgets are still full-size when used standalone with
/// no photo; only in this photo-backdrop path do they need to earn their
/// keep as a small overlay instead). Set [capSticker] to false to opt a
/// specific sticker out of that cap when it's been deliberately built to
/// show full card-parity content instead of staying compact (Collection's
/// glass sticker, 2026-08-19, after the user asked for the same data shown
/// with or without a photo) -- the content in that case is still naturally
/// bounded (every list it draws from is already `.take(3)`-capped), so
/// there's no risk of genuinely unbounded growth, just a taller sticker
/// than the 34%-of-canvas default allows.
///
/// [scrim] controls the bottom darkening gradient: on by default for
/// stickers that are just floating typography with no background of their
/// own (Den's Robinhood-style minimal sticker genuinely needs it for
/// legibility against an arbitrary photo) -- turned off by screens whose
/// sticker already supplies its own contrast (Set's opaque slab card,
/// Collection's translucent-but-blurred glass panel), where stacking the
/// scrim underneath just double-darkens for no benefit.
///
/// The photo itself is composited with BoxFit.contain over a cream
/// stud-textured backdrop (StudBackground, the same one FixedRatioCanvas
/// uses for card-only mode), not BoxFit.cover -- changed 2026-08-20 for the
/// same reason the crop step above went freeform: cover forces the photo to
/// fill the canvas edge-to-edge, which meant the *only* way to fit a
/// differently-shaped photo onto a fixed 9:16/4:5 canvas was to crop
/// content away. contain shows the whole photo and lets the leftover space
/// read as a deliberate border/mat around it instead of forcing a crop.
class PhotoBackdropCard extends StatelessWidget {
  final File?  photo;
  final Widget card;
  final bool   scrim;
  final ShareFormat format;
  final bool   capSticker;
  const PhotoBackdropCard({
    super.key,
    required this.photo,
    required this.card,
    this.scrim = true,
    this.format = ShareFormat.story,
    this.capSticker = true,
  });

  @override
  Widget build(BuildContext context) {
    if (photo == null) return card;
    final capped = capSticker
        ? ConstrainedBox(
            constraints: BoxConstraints(maxHeight: format.maxStickerHeight),
            child: card,
          )
        : card;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        width: format.width,
        height: format.height,
        child: Stack(fit: StackFit.expand, children: [
          StudBackground(color: BT.cream, child: const SizedBox.expand()),
          Image.file(photo!, fit: BoxFit.contain),
          if (scrim)
            // Full-bleed gradient so the sticker's own typography stays
            // legible against an arbitrary photo, same idea as a Story
            // sticker's own drop shadow/backing.
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 44),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(.6)],
                  ),
                ),
                child: Center(child: capped),
              ),
            )
          else
            Positioned(left: 16, right: 16, bottom: 16, child: capped),
        ]),
      ),
    );
  }
}
