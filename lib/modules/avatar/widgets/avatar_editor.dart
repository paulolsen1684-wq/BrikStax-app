// lib/modules/avatar/widgets/avatar_editor.dart
//
// Figure tabs (Head/Hat/Torso/Legs/Item) run on the pixel-art catalog
// (data/pixel_cosmetics.dart). _pixelGrid now mirrors _bgGrid's shape --
// Unlocked/Locked groups, each subdivided by rarity tier -- now that
// PixelCosmetic has real rarity data and loot_service.dart's reward pool
// actually gates most of the catalog behind earning it (see
// AvatarState.starterIds). The "None" tile on the two optional slots (hat,
// item) sits in its own ungated section above both groups, since clearing
// a slot isn't something that needs unlocking.
//
// Background is untouched: still its own tab/picker (_bgGrid/_BgTile)
// against the sprite catalog's now-backgrounds-only data, since none of
// the pixel-art cutover touched backgrounds.

import 'package:flutter/material.dart';
import '../data/sprite_cosmetics.dart';
import '../data/pixel_cosmetics.dart';
import '../data/backgrounds_art.dart' as bgArt;
import '../models/avatar_state.dart';
import '../services/achievement_service.dart';
import '../widgets/pixel_avatar_widget.dart';
import 'den_scene.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_themes.dart';

class AvatarEditorScreen extends StatefulWidget {
  const AvatarEditorScreen({super.key});
  @override State<AvatarEditorScreen> createState() => _EditorState();
}

class _EditorState extends State<AvatarEditorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  static const _tabDefs = [
    (PixelSlot.head,  '🙂', 'Head'),
    (PixelSlot.hat,   '🎩', 'Hat'),
    (PixelSlot.torso, '👕', 'Torso'),
    (PixelSlot.legs,  '👖', 'Legs'),
    (PixelSlot.item,  '🎒', 'Item'),
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _tabDefs.length + 1, vsync: this); // +1 for Den/BG
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  String? _equippedIdForSlot(AvatarState avatarState, PixelSlot slot) => switch (slot) {
    PixelSlot.head  => avatarState.headId,
    PixelSlot.hat   => avatarState.hatId,
    PixelSlot.torso => avatarState.torsoId,
    PixelSlot.legs  => avatarState.legsId,
    PixelSlot.item  => avatarState.itemId,
  };

  @override
  Widget build(BuildContext context) {
    final bt = context.bt;

    return ListenableBuilder(
      listenable: AchievementService.instance,
      builder: (_, __) {
        final svc = AchievementService.instance;
        final avatarState = svc.state;

        return Scaffold(
          backgroundColor: bt.surface,
          body: Column(children: [
            _header(bt),
            _preview(bt, avatarState),
            _tabBar(bt),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  ..._tabDefs.map((t) => _pixelGrid(bt, t.$1, svc, avatarState)),
                  _denTab(bt, svc, avatarState),
                ],
              ),
            ),
          ]),
        );
      },
    );
  }

  Widget _header(BrikStaxColors bt) => SafeArea(
    bottom: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: bt.cardBg,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: bt.cardBorder, width: BT.bw),
            ),
            child: Icon(Icons.arrow_back_ios_new, color: bt.tx, size: 16),
          ),
        ),
        const SizedBox(width: 12),
        Text('My Minifig', style: BT.display(size: 26, color: bt.tx)),
      ]),
    ),
  );

  // Small floating sparkle/star/dot accents around the backdrop -- a full
  // standing figure doesn't suit a strict circle crop (too much dead space
  // at the shoulders, feet risk clipping), so instead of the reference's
  // circular badge we borrow its playful decorative-flourish energy on a
  // softened rounded-square backdrop.
  static const _sparkles = [
    (Icons.star_rounded, -.38, -.40, 14.0),
    (Icons.auto_awesome, .40, -.34, 11.0),
    (Icons.favorite_rounded, -.42, .30, 12.0),
    (Icons.circle, .38, .38, 6.0),
  ];

  Widget _preview(BrikStaxColors bt, AvatarState avatarState) {
    final palette = bgArt.bgPalettes[avatarState.backgroundId] ?? bgArt.bgPalettes['bg_cream']!;
    return Container(
    padding: const EdgeInsets.symmetric(vertical: 18),
    decoration: BoxDecoration(
      color: bt.cardBg,
      border: Border(bottom: BorderSide(color: bt.cardBorder, width: BT.bw)),
    ),
    child: Center(
      child: Container(
        // 168 -> 210, +25% on explicit request. PixelAvatarWidget's size
        // below scaled the same +25% to keep the same fill proportion.
        width: 210, height: 210,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [palette.avatarBg, Color.lerp(palette.avatarBg, Colors.black, .25)!],
            radius: .85,
          ),
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: bt.cardBorder, width: BT.bw),
          boxShadow: [BoxShadow(color: bt.shadowColor, offset: const Offset(3, 3))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(alignment: Alignment.center, children: [
          for (final s in _sparkles)
            Align(
              alignment: Alignment(s.$2, s.$3),
              child: Icon(s.$1, size: s.$4, color: palette.accent.withOpacity(.55)),
            ),
          Align(
            // This preview builds PixelAvatarWidget directly rather than
            // through AvatarWidget, so it needs its own left-bias -- the
            // Align added to AvatarWidget for the same "leave room for the
            // item" reason doesn't reach this screen. Same -0.35 starting
            // value as there, for consistency; tune independently if this
            // 168x168 box needs a different bias.
            alignment: const Alignment(-0.35, 0),
            child: PixelAvatarWidget(
              // Box was 168 tall (120 -> 132 rendered size across two
              // earlier passes), now 210 -- size scaled the same +25%,
              // 132 -> 165, to keep the same fill proportion. Left
              // uncapped since nothing clipped in practice (ClipRect
              // inside PixelAvatarWidget itself plus this Container's
              // clipBehavior both still apply); revisit if a real render
              // shows clipping at the top/bottom of the hat or feet.
              size: 165,
              state: PixelAvatarState(
                headId: avatarState.headId,
                hatId: avatarState.hatId,
                torsoId: avatarState.torsoId,
                legsId: avatarState.legsId,
                itemId: avatarState.itemId,
              ),
            ),
          ),
        ]),
      ),
    ),
  );
  }

  Widget _tabBar(BrikStaxColors bt) => Container(
    color: bt.surface,
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: TabBar(
      controller: _tabs,
      isScrollable: true,
      indicatorSize: TabBarIndicatorSize.tab,
      indicator: BoxDecoration(
        color: bt.primary.withOpacity(.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: bt.primary, width: BT.bw),
      ),
      dividerColor: Colors.transparent,
      labelColor: bt.tx,
      unselectedLabelColor: bt.txMuted,
      labelStyle: BT.mono(size: 9),
      unselectedLabelStyle: BT.mono(size: 9),
      tabs: [
        ..._tabDefs.map((t) => Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(t.$2, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 5), Text(t.$3),
        ]))),
        Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Text('🏠', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 5),
          Text('Den', style: BT.mono(size: 9, color: bt.txMuted)),
        ])),
      ],
    ),
  );

  // Hat/Item are optional and get a leading "None" tile to clear them,
  // ungated by lock state. Head/Torso/Legs must always have something
  // equipped so they skip it. Everything else groups Unlocked/Locked then
  // by rarity tier, same shape as _bgGrid/_bgTierSection below.
  Widget _pixelGrid(BrikStaxColors bt, PixelSlot slot, AchievementService svc, AvatarState avatarState) {
    final items = pixelCosmeticsForSlot(slot);
    final equippedId = _equippedIdForSlot(avatarState, slot);
    final optional = slot == PixelSlot.hat || slot == PixelSlot.item;
    final unlockedIds = svc.state.unlockedIds;

    final unlocked = items.where((c) => unlockedIds.contains(c.id)).toList();
    final locked   = items.where((c) => !unlockedIds.contains(c.id)).toList();

    const tierOrder = [
      SpriteRarity.common, SpriteRarity.uncommon, SpriteRarity.rare,
      SpriteRarity.epic, SpriteRarity.legendary,
    ];

    return CustomScrollView(slivers: [
      if (optional)
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: .74),
            delegate: SliverChildListDelegate([
              _NoneTile(equipped: equippedId == null, onTap: () => svc.unequipPixel(slot)),
            ]),
          ),
        ),
      if (unlocked.isNotEmpty) ...[
        _statusHeader(bt, 'UNLOCKED'),
        for (final tier in tierOrder) ..._pixelTierSection(bt, unlocked, tier, svc, equippedId),
      ],
      if (locked.isNotEmpty) ...[
        _statusHeader(bt, 'LOCKED'),
        for (final tier in tierOrder) ..._pixelTierSection(bt, locked, tier, svc, equippedId),
      ],
      const SliverToBoxAdapter(child: SizedBox(height: 20)),
    ]);
  }

  List<Widget> _pixelTierSection(BrikStaxColors bt, List<PixelCosmetic> all, SpriteRarity tier,
      AchievementService svc, String? equippedId) {
    final items = all.where((c) => c.rarity.asSpriteRarity == tier).toList();
    if (items.isEmpty) return [];
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
          child: Row(children: [
            Container(width: 10, height: 10,
                decoration: BoxDecoration(color: tier.color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(tier.label.toUpperCase(), style: BT.display(size: 13, color: bt.tx)),
          ]),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: .74),
          delegate: SliverChildBuilderDelegate(
            (_, i) {
              final cosmetic = items[i];
              return _PixelTile(
                cosmetic: cosmetic,
                unlocked: svc.state.unlockedIds.contains(cosmetic.id),
                equipped: equippedId == cosmetic.id,
                onTap: () => svc.equipPixel(cosmetic),
              );
            },
            childCount: items.length,
          ),
        ),
      ),
    ];
  }

  // Bold divider between status groups -- still used by the background
  // grid below, which does have real unlocked/locked groups.
  Widget _statusHeader(BrikStaxColors bt, String label) => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 0),
      child: Row(children: [
        Expanded(child: Divider(color: bt.cardBorder, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(label, style: BT.mono(size: 10, color: bt.txMuted, weight: FontWeight.w700)),
        ),
        Expanded(child: Divider(color: bt.cardBorder, height: 1)),
      ]),
    ),
  );

  // The Den tab embeds the exact same live scene as the full Brick Den
  // screen (den_scene.dart's DenSceneContent) rather than the old flat
  // background swatch grid -- background-picking itself moves into a
  // bottom sheet (still the same _bgGrid content below) reached via the
  // floating button, so switching backgrounds is still possible without
  // making the primary tab content a picker grid instead of the actual Den.
  Widget _denTab(BrikStaxColors bt, AchievementService svc, AvatarState avatarState) {
    // _header above deliberately excludes bottom safe area (SafeArea
    // (bottom: false, ...)) since it's a top header -- nothing downstream
    // in the Column (preview/tabBar/TabBarView) re-adds it, so this
    // button's own bottom:16 was measured from the raw Stack edge, not
    // from above Android's on-screen nav bar. Add the real device inset
    // (0 on gesture-nav devices/iOS, the 3-button nav bar's height on
    // devices that still use one) on top of the visual 16px margin.
    final navInset = MediaQuery.of(context).padding.bottom;
    return Stack(children: [
      const DenSceneContent(),
      Positioned(
        right: 16, bottom: 16 + navInset,
        child: GestureDetector(
          onTap: () => _openBackgroundPicker(context, bt, svc, avatarState),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: BT.yellow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: BT.ink, width: BT.bw),
              boxShadow: BT.shadow,
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.wallpaper, color: BT.ink, size: 16),
              const SizedBox(width: 7),
              Text('Change Background',
                  style: BT.body(size: 12, color: BT.ink, weight: FontWeight.w700)),
            ]),
          ),
        ),
      ),
    ]);
  }

  void _openBackgroundPicker(BuildContext context, BrikStaxColors bt,
      AchievementService svc, AvatarState avatarState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: bt.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: bt.cardBorder, width: BT.bw),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false, initialChildSize: .85,
        minChildSize: .5, maxChildSize: .95,
        builder: (_, scroll) => SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(children: [
                Center(child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: bt.surface3,
                      borderRadius: BorderRadius.circular(2)))),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(children: [
                Text('Background', style: BT.display(size: 20, color: bt.tx)),
              ]),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: AchievementService.instance,
                builder: (_, __) => _bgGrid(
                    bt, AchievementService.instance, AchievementService.instance.state),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // Background lives in the sprite catalog (now backgrounds-only) --
  // unaffected by the pixel-art cutover. Still its own grid/tile because
  // _BgTile's preview is a color swatch, not an Image.asset.
  Widget _bgGrid(BrikStaxColors bt, AchievementService svc, AvatarState avatarState) {
    final items = spriteCosmeticsForSlot(CosmeticSlot.background);
    final equippedId = avatarState.backgroundId;
    final unlockedIds = svc.state.unlockedIds;

    final unlocked = items.where((c) => unlockedIds.contains(c.id)).toList();
    final locked   = items.where((c) => !unlockedIds.contains(c.id)).toList();

    const tierOrder = [
      SpriteRarity.common, SpriteRarity.uncommon, SpriteRarity.rare,
      SpriteRarity.epic, SpriteRarity.legendary,
    ];

    return CustomScrollView(slivers: [
      if (unlocked.isNotEmpty) ...[
        _statusHeader(bt, 'UNLOCKED'),
        for (final tier in tierOrder) ..._bgTierSection(bt, unlocked, tier, svc, equippedId),
      ],
      if (locked.isNotEmpty) ...[
        _statusHeader(bt, 'LOCKED'),
        for (final tier in tierOrder) ..._bgTierSection(bt, locked, tier, svc, equippedId),
      ],
      const SliverToBoxAdapter(child: SizedBox(height: 20)),
    ]);
  }

  List<Widget> _bgTierSection(BrikStaxColors bt, List<SpriteCosmetic> all, SpriteRarity tier,
      AchievementService svc, String? equippedId) {
    final items = all.where((c) => c.rarity == tier).toList();
    if (items.isEmpty) return [];
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
          child: Row(children: [
            Container(width: 10, height: 10,
                decoration: BoxDecoration(color: tier.color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(tier.label.toUpperCase(), style: BT.display(size: 13, color: bt.tx)),
          ]),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: .74),
          delegate: SliverChildBuilderDelegate(
            (_, i) {
              final cosmetic = items[i];
              return _BgTile(
                cosmetic: cosmetic,
                unlocked: svc.state.unlockedIds.contains(cosmetic.id),
                equipped: equippedId == cosmetic.id,
                onTap: () => svc.equipSprite(cosmetic),
              );
            },
            childCount: items.length,
          ),
        ),
      ),
    ];
  }
}

// Same border/rarity-strip/lock treatment as _BgTile now that pixel items
// can actually be locked -- see PixelItemTunerScreen's rarity data and
// loot_service.dart's reward pool.
class _PixelTile extends StatelessWidget {
  final PixelCosmetic cosmetic;
  final bool unlocked, equipped;
  final VoidCallback onTap;
  const _PixelTile({required this.cosmetic, required this.unlocked, required this.equipped, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bt = context.bt;
    final rarity = cosmetic.rarity.color;
    final badgeText = ThemeData.estimateBrightnessForColor(bt.primary) == Brightness.dark
        ? Colors.white : BT.ink;
    // A locked isSecret item hides its name/preview entirely (sparkle icon,
    // "???") instead of the ordinary lock treatment -- an ordinary locked
    // item still tells you what it is as something to work toward; a
    // secret is meant to be a genuine surprise the first time it's
    // granted. Has no effect once unlocked. Mirrors SpriteCosmetic.isSecret
    // 's identical rule on the old catalog's _SpriteTile.
    final hideSecret = !unlocked && cosmetic.isSecret;
    return GestureDetector(
      onTap: unlocked ? onTap : null,
      child: Container(
        decoration: BoxDecoration(
          color: bt.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: equipped ? bt.primary : (unlocked ? rarity.withOpacity(.85) : bt.cardBorder),
            width: equipped ? 2.5 : 2,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(children: [
          Container(height: 5, color: unlocked ? rarity : bt.cardBorder),
          Positioned.fill(
            top: 5, bottom: 24,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: unlocked
                  ? Image.asset(cosmetic.assetPath,
                      fit: BoxFit.contain, filterQuality: FilterQuality.medium)
                  : Center(child: Icon(
                      hideSecret ? Icons.auto_awesome : Icons.lock_outline,
                      color: bt.txMuted, size: 32)),
            ),
          ),
          Positioned(
            bottom: 6, left: 10, right: 10,
            child: Text(hideSecret ? '???' : cosmetic.name,
                style: BT.body(size: 12, color: unlocked ? bt.tx : bt.txMuted),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          if (equipped)
            Positioned(
              top: 8, right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(color: bt.primary, borderRadius: BorderRadius.circular(5)),
                child: Text('EQUIPPED', style: BT.mono(size: 6, color: badgeText, weight: FontWeight.w700)),
              ),
            ),
        ]),
      ),
    );
  }
}

// Clears the hat/item slot -- these are the only two optional slots, so
// this tile only ever shows up on those two grids.
class _NoneTile extends StatelessWidget {
  final bool equipped;
  final VoidCallback onTap;
  const _NoneTile({required this.equipped, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bt = context.bt;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bt.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: equipped ? bt.primary : bt.cardBorder, width: equipped ? 2.5 : 2),
        ),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.block, color: bt.txMuted, size: 28),
            const SizedBox(height: 6),
            Text('None', style: BT.body(size: 12, color: bt.tx2)),
          ]),
        ),
      ),
    );
  }
}

// Preview tile for the Background grid -- same border/equipped treatment as
// _PixelTile. Shows the real generated Den photo (assets/avatar/dens/<id>
// .png) via bgArt.denImageAsset() when one exists (48 of 52 ids do), falling
// back to the procedural wall/floor gradient swatch only for the 4 that
// don't (bg_workbench, bg_snowfield, bg_maproom, bg_shadowrealm as of this
// writing -- see backgrounds_art.dart). This tile used to always render the
// procedural swatch regardless of real art existing, which is why every
// background in the picker read as a flat color block even for ids with a
// real photo.
class _BgTile extends StatelessWidget {
  final SpriteCosmetic cosmetic;
  final bool unlocked, equipped;
  final VoidCallback onTap;
  const _BgTile({required this.cosmetic, required this.unlocked, required this.equipped, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bt = context.bt;
    final rarity = cosmetic.rarity.color;
    final palette = bgArt.bgPalettes[cosmetic.id];
    final imageAsset = bgArt.denImageAsset(cosmetic.id);
    final badgeText = ThemeData.estimateBrightnessForColor(bt.primary) == Brightness.dark
        ? Colors.white : BT.ink;
    return GestureDetector(
      onTap: unlocked ? onTap : null,
      child: Container(
        decoration: BoxDecoration(
          color: bt.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: equipped ? bt.primary : (unlocked ? rarity.withOpacity(.85) : bt.cardBorder),
            width: equipped ? 2.5 : 2,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(children: [
          Container(height: 5, color: unlocked ? rarity : bt.cardBorder),
          Positioned.fill(
            top: 5,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 24),
              child: !unlocked
                  ? Icon(Icons.lock_outline, color: bt.txMuted, size: 32)
                  : imageAsset != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(imageAsset,
                              fit: BoxFit.cover, filterQuality: FilterQuality.medium),
                        )
                      : (palette == null
                          ? const SizedBox.shrink()
                          : Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                                  colors: [palette.denWall, palette.avatarBg],
                                ),
                                border: Border.all(color: palette.accent.withOpacity(.6), width: 1.5),
                              ),
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: FractionallySizedBox(
                                  heightFactor: .3, widthFactor: 1,
                                  child: Container(color: palette.denFloor),
                                ),
                              ),
                            )),
            ),
          ),
          Positioned(
            bottom: 6, left: 10, right: 10,
            child: Text(cosmetic.name,
                style: BT.body(size: 12, color: unlocked ? bt.tx : bt.txMuted),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          if (equipped)
            Positioned(
              top: 8, right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(color: bt.primary, borderRadius: BorderRadius.circular(5)),
                child: Text('EQUIPPED', style: BT.mono(size: 6, color: badgeText, weight: FontWeight.w700)),
              ),
            ),
        ]),
      ),
    );
  }
}
