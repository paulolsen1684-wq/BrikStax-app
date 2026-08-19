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
// original shape, best for Instagram/Snapchat Stories) and Post (3:4,
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
// wired into any Dart code before this) locked to the same aspect ratio as
// [format], so what the user frames in the crop UI is exactly what shows
// in the final card, not a guess.
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_themes.dart';

enum ShareFormat { story, post }

extension ShareFormatX on ShareFormat {
  String get label => this == ShareFormat.story ? 'Story · 9:16' : 'Post · 3:4';
  double get width => 540;
  double get height => this == ShareFormat.story ? 960 : 720; // 3:4 at width 540
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

/// Picks a photo (camera or gallery), then crops it to exactly [format]'s
/// aspect ratio via image_cropper's native platform UI -- what the user
/// frames here is exactly what shows in the final card, not left to an
/// unseen BoxFit.cover guess. Returns null if the user cancels either step.
Future<File?> pickBackdropPhoto(BuildContext context, {required ShareFormat format}) async {
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

  // Locked to format's exact aspect ratio -- no "pick your own ratio" menu,
  // since the canvas it'll actually be shown on is already fixed. Colors
  // match BrikStax's ink/yellow brand pair; Android additionally already
  // has BrikStaxCropTheme wired up natively (AndroidManifest.xml/styles.xml).
  final cropped = await ImageCropper().cropImage(
    sourcePath: picked.path,
    aspectRatio: CropAspectRatio(ratioX: format.width, ratioY: format.height),
    compressQuality: 90,
    uiSettings: [
      AndroidUiSettings(
        toolbarTitle: 'Crop Photo',
        toolbarColor: BT.ink,
        toolbarWidgetColor: BT.yellow,
        activeControlsWidgetColor: BT.yellow,
        statusBarLight: false,
        lockAspectRatio: true,
        hideBottomControls: true, // ratio's fixed -- no reason to offer switching it
      ),
      IOSUiSettings(
        title: 'Crop Photo',
        aspectRatioLockEnabled: true,
        resetAspectRatioEnabled: false,
        aspectRatioPickerButtonHidden: true,
      ),
    ],
  );
  if (cropped == null) return null; // user backed out of the crop step
  return File(cropped.path);
}

/// Composites [card] as a sticker over [photo] on a canvas sized to
/// [format] (Story 9:16 or Post 3:4). Returns [card] unchanged when [photo]
/// is null -- every share screen's existing plain-card look is the default;
/// this only changes anything once the user opts into a photo backdrop.
///
/// [card] is capped at [format]'s maxStickerHeight regardless of what's
/// passed in -- this is the actual fix for the original "sticker swallows
/// the whole photo" bug (den_share_screen.dart's/set_share_screen.dart's/
/// collection_share_screen.dart's own card widgets are still full-size
/// when used standalone with no photo; only in this photo-backdrop path
/// do they need to earn their keep as a small overlay instead).
///
/// [scrim] controls the bottom darkening gradient: on by default for
/// stickers that are just floating typography with no background of their
/// own (Den's Robinhood-style minimal sticker genuinely needs it for
/// legibility against an arbitrary photo) -- turned off by screens whose
/// sticker already supplies its own contrast (Set's opaque slab card,
/// Collection's translucent-but-blurred glass panel), where stacking the
/// scrim underneath just double-darkens for no benefit.
class PhotoBackdropCard extends StatelessWidget {
  final File?  photo;
  final Widget card;
  final bool   scrim;
  final ShareFormat format;
  const PhotoBackdropCard({
    super.key,
    required this.photo,
    required this.card,
    this.scrim = true,
    this.format = ShareFormat.story,
  });

  @override
  Widget build(BuildContext context) {
    if (photo == null) return card;
    final capped = ConstrainedBox(
      constraints: BoxConstraints(maxHeight: format.maxStickerHeight),
      child: card,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        width: format.width,
        height: format.height,
        child: Stack(fit: StackFit.expand, children: [
          Image.file(photo!, fit: BoxFit.cover),
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
