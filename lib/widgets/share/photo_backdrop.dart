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
// become a compact "sticker" overlaid on a 9:16 canvas sized for Instagram/
// Snapchat Stories.
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_themes.dart';

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
  return File(picked.path);
}

/// Composites [card] as a sticker over [photo] on a 9:16 canvas sized for
/// Instagram/Snapchat Stories. Returns [card] unchanged when [photo] is
/// null -- every share screen's existing plain-card look is the default;
/// this only changes anything once the user opts into a photo backdrop.
///
/// [card] is capped at [maxStickerHeight] regardless of what's passed in --
/// this is the actual fix for the original "sticker swallows the whole
/// photo" bug (den_share_screen.dart's/set_share_screen.dart's/
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
  const PhotoBackdropCard({
    super.key,
    required this.photo,
    required this.card,
    this.scrim = true,
  });

  static const double canvasW = 540;
  static const double canvasH = 960; // 9:16 -- Instagram/Snapchat Story shape
  static const double maxStickerHeight = canvasH * .34;

  @override
  Widget build(BuildContext context) {
    if (photo == null) return card;
    final capped = ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: maxStickerHeight),
      child: card,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        width: canvasW,
        height: canvasH,
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
