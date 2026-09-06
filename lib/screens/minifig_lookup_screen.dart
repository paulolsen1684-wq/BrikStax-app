// lib/screens/minifig_lookup_screen.dart
//
// Minifig search — was "type the exact Rebrickable fig-num" (e.g.
// "fig-000001"), which nobody has memorized the way a set number printed on
// a box is memorable. Reworked 2026-09-06 into real search: a name field
// (Rebrickable's own `search` param) plus a theme filter to narrow results,
// both confirmed against Rebrickable's real OpenAPI spec via
// Api.searchMinifigs. Results are a list to pick from, not a single-card
// exact match -- the closer analogue is set_lookup_screen.dart's debounced
// field, but the result shape here is a list, not one breakdown card, since
// a name search is expected to return several candidates.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:uuid/uuid.dart';
import '../models/minifig.dart';
import '../services/api.dart';
import '../services/minifig_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_themes.dart';
import '../widgets/atoms.dart';
import 'minifig_detail_screen.dart';

/// Curated shortlist for the theme filter row -- the full Rebrickable theme
/// tree runs several hundred entries; these are the ones a minifig
/// collector is most likely tapping for. "Other" (handled separately, not
/// in this list) opens the full top-level list as a fallback. IDs verified
/// directly against Rebrickable's live /lego/themes/ response, not guessed.
const List<(int, String)> _curatedThemes = [
  (158, 'Star Wars'),
  (246, 'Harry Potter'),
  (696, 'Marvel'),
  (695, 'DC'),
  (435, 'Ninjago'),
  (52,  'City'),
  (494, 'Friends'),
  (608, 'Disney'),
  (535, 'Minifigures'),
  (721, 'Icons'),
  (22,  'Creator'),
  (602, 'Jurassic World'),
  (577, 'Minecraft'),
  (576, 'Ideas'),
];

class MinifigLookupScreen extends StatefulWidget {
  const MinifigLookupScreen({super.key});
  @override State<MinifigLookupScreen> createState() => _State();
}

class _State extends State<MinifigLookupScreen> {
  final _nameCtrl = TextEditingController();
  static const _uuid = Uuid();

  int? _themeId;       // null = All
  String _themeLabel = 'All';

  bool _searching = false;
  String? _error;
  List<Map<String, dynamic>> _results = const [];

  // Full top-level theme list, fetched lazily the first time "Other" opens
  // and cached for the rest of this screen's life -- no reason to re-fetch
  // ~70 themes every time the sheet reopens.
  List<Map<String, dynamic>>? _allThemes;
  bool _loadingAllThemes = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(_onQueryChange);
  }

  @override
  void dispose() {
    _nameCtrl.removeListener(_onQueryChange);
    _nameCtrl.dispose();
    super.dispose();
  }

  void _onQueryChange() {
    final v = _nameCtrl.text;
    Future.delayed(const Duration(milliseconds: 650), () {
      if (mounted && _nameCtrl.text == v) _search();
    });
  }

  Future<void> _search() async {
    final name = _nameCtrl.text.trim();
    // Require at least one real filter -- an empty name AND "All" themes
    // would otherwise fetch an arbitrary unfiltered slice of the entire
    // minifig catalog, which isn't a meaningful result set for anyone.
    if (name.isEmpty && _themeId == null) {
      setState(() { _results = const []; _error = null; });
      return;
    }
    setState(() { _searching = true; _error = null; });
    final results = await Api.instance.searchMinifigs(
      name: name.isEmpty ? null : name,
      themeId: _themeId,
    );
    if (!mounted) return;
    setState(() {
      _searching = false;
      _results = results;
      _error = results.isEmpty ? 'No minifigs found' : null;
    });
  }

  Future<void> _pickTheme(int? id, String label) async {
    setState(() { _themeId = id; _themeLabel = label; });
    await _search();
  }

  Future<void> _openOtherThemes() async {
    if (_allThemes == null && !_loadingAllThemes) {
      setState(() => _loadingAllThemes = true);
      final themes = await Api.instance.fetchTopLevelThemes();
      if (!mounted) return;
      setState(() { _allThemes = themes; _loadingAllThemes = false; });
    }
    if (!mounted) return;
    final bt = context.bt;
    final picked = await showModalBottomSheet<(int, String)>(
      context: context,
      isScrollControlled: true,
      backgroundColor: bt.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: bt.cardBorder, width: BT.bw),
      ),
      builder: (ctx) => _AllThemesSheet(themes: _allThemes, loading: _loadingAllThemes),
    );
    if (picked != null) await _pickTheme(picked.$1, picked.$2);
  }

  Future<void> _add(Map<String, dynamic> rb) async {
    final fig = rb['set_num'] as String? ?? '';
    if (fig.isEmpty) return;
    final item = Minifig(
      id: _uuid.v4(),
      figNum: fig,
      name: rb['name'] as String? ?? '',
      imageUrl: rb['set_img_url'] as String?,
      numParts: rb['num_parts'] as int?,
      addedAt: DateTime.now(),
    );
    await MinifigService.instance.add(item);
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(
        builder: (_) => MinifigDetailScreen(figNum: fig)));
  }

  @override
  Widget build(BuildContext context) {
    final bt = context.bt;
    final svc = context.watch<MinifigService>();

    return Scaffold(
      backgroundColor: bt.surface,
      body: SafeArea(
        child: Column(children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            decoration: BoxDecoration(
              color: bt.surface,
              border: Border(bottom: BorderSide(color: bt.cardBorder, width: BT.bw)),
            ),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: bt.cardBg,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: bt.cardBorder, width: BT.bw),
                    boxShadow: [BoxShadow(color: bt.shadowColor, offset: const Offset(2, 2))],
                  ),
                  child: Icon(Icons.arrow_back_ios_new, color: bt.tx, size: 16),
                ),
              ),
              const SizedBox(width: 12),
              Text('Find a Minifig', style: BT.display(size: 24, color: bt.tx)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Name', style: BT.mono(size: 9, color: bt.tx3)),
              const SizedBox(height: 5),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: bt.cardBorder, width: BT.bw),
                  boxShadow: [BoxShadow(color: bt.shadowColor, offset: const Offset(2, 2))],
                ),
                child: TextField(
                  controller: _nameCtrl,
                  style: BT.mono(size: 14, color: bt.tx),
                  decoration: InputDecoration(
                    hintText: 'e.g. Luke Skywalker',
                    hintStyle: BT.mono(size: 13, color: bt.txMuted),
                    prefixIcon: Icon(Icons.search, size: 18, color: bt.txMuted),
                    suffixIcon: _searching
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: SizedBox(width: 16, height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(BT.green))),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    fillColor: bt.cardBg,
                    filled: true,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('Theme', style: BT.mono(size: 9, color: bt.tx3)),
              const SizedBox(height: 8),
              SizedBox(
                height: 34,
                child: ListView(scrollDirection: Axis.horizontal, children: [
                  _themeChip(bt, null, 'All'),
                  for (final t in _curatedThemes) _themeChip(bt, t.$1, t.$2),
                  GestureDetector(
                    onTap: _openOtherThemes,
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: (_themeId != null &&
                                !_curatedThemes.any((t) => t.$1 == _themeId))
                            ? bt.tx : bt.cardBg,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: bt.cardBorder, width: BT.bw),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(
                          (_themeId != null && !_curatedThemes.any((t) => t.$1 == _themeId))
                              ? _themeLabel : 'Other',
                          style: BT.body(size: 12, weight: FontWeight.w600,
                              color: (_themeId != null &&
                                      !_curatedThemes.any((t) => t.$1 == _themeId))
                                  ? bt.surface : bt.tx),
                        ),
                        const SizedBox(width: 3),
                        Icon(Icons.expand_more, size: 14,
                            color: (_themeId != null &&
                                    !_curatedThemes.any((t) => t.$1 == _themeId))
                                ? bt.surface : bt.tx),
                      ]),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Align(alignment: Alignment.centerLeft,
                  child: Text(_error!, style: BT.body(size: 13, color: bt.tx2))),
            ),
          Expanded(
            child: _results.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _error == null
                            ? 'Search by name or pick a theme to get started.'
                            : '',
                        textAlign: TextAlign.center,
                        style: BT.body(size: 13, color: bt.tx2),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
                    itemCount: _results.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _resultRow(bt, svc, _results[i]),
                  ),
          ),
        ]),
      ),
    );
  }

  Widget _themeChip(BrikStaxColors bt, int? id, String label) {
    final selected = _themeId == id;
    return GestureDetector(
      onTap: () => _pickTheme(id, label),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? bt.tx : bt.cardBg,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: bt.cardBorder, width: BT.bw),
        ),
        child: Text(label, style: BT.body(size: 12, weight: FontWeight.w600,
            color: selected ? bt.surface : bt.tx)),
      ),
    );
  }

  Widget _resultRow(BrikStaxColors bt, MinifigService svc, Map<String, dynamic> rb) {
    final fig = rb['set_num'] as String? ?? '';
    final name = rb['name'] as String? ?? fig;
    final image = rb['set_img_url'] as String?;
    final parts = rb['num_parts'] as int?;
    final owned = svc.contains(fig);

    return GestureDetector(
      // Owned -> straight to detail, same as before. Not owned -> a
      // confirm-before-add preview (bigger picture, see _showPreview)
      // instead of adding on a single tap -- minifigs reuse a lot of
      // body/head molds across variants, so a 64px list thumbnail alone
      // isn't always enough to be sure it's the right one.
      onTap: () => owned
          ? Navigator.push(context, MaterialPageRoute(
              builder: (_) => MinifigDetailScreen(figNum: fig)))
          : _showPreview(rb),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bt.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: bt.cardBorder, width: BT.bw),
        ),
        child: Row(children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: bt.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: bt.cardBorder, width: BT.bw),
            ),
            clipBehavior: Clip.antiAlias,
            child: image != null
                ? CachedNetworkImage(imageUrl: image, fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Icon(Icons.emoji_people, color: bt.txMuted))
                : Icon(Icons.emoji_people, color: bt.txMuted),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: BT.body(size: 13, weight: FontWeight.w700, color: bt.tx),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(
              [fig, if (parts != null) '$parts parts'].join(' · '),
              style: BT.mono(size: 10, color: bt.tx3),
            ),
          ])),
          if (owned)
            const Icon(Icons.check_circle, color: BT.green, size: 22)
          else
            GestureDetector(
              onTap: () => _showPreview(rb),
              child: Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                  color: BT.yellow,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: BT.ink, width: BT.bw),
                ),
                child: const Icon(Icons.add, color: BT.ink, size: 18),
              ),
            ),
        ]),
      ),
    );
  }

  // Confirm-before-add: a big (200px) picture + name + fig-num, so a search
  // result that looked plausible as a small list thumbnail can actually be
  // confirmed before it lands in the collection -- LEGO reuses molds across
  // variants (troopers, pilots, etc. especially) often enough that a 64px
  // row thumbnail alone isn't a reliable "yes, that one" check.
  Future<void> _showPreview(Map<String, dynamic> rb) async {
    final bt = context.bt;
    final fig = rb['set_num'] as String? ?? '';
    final name = rb['name'] as String? ?? fig;
    final image = rb['set_img_url'] as String?;
    final parts = rb['num_parts'] as int?;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: bt.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: bt.cardBorder, width: BT.bw),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SheetHandle(),
            const SizedBox(height: 16),
            Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                color: bt.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: bt.cardBorder, width: BT.bw),
              ),
              clipBehavior: Clip.antiAlias,
              child: image != null
                  ? CachedNetworkImage(imageUrl: image, fit: BoxFit.contain,
                      errorWidget: (_, __, ___) => Icon(Icons.emoji_people, color: bt.txMuted, size: 48))
                  : Icon(Icons.emoji_people, color: bt.txMuted, size: 48),
            ),
            const SizedBox(height: 16),
            Text(name, textAlign: TextAlign.center,
                style: BT.display(size: 18, color: bt.tx)),
            const SizedBox(height: 4),
            Text(
              [fig, if (parts != null) '$parts parts'].join(' · '),
              style: BT.mono(size: 11, color: bt.tx3),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => Navigator.pop(ctx, true),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: BT.yellow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: BT.ink, width: BT.bw),
                ),
                child: Center(child: Text('Add to my minifigs',
                    style: BT.body(size: 14, weight: FontWeight.w700, color: BT.ink))),
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => Navigator.pop(ctx, false),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Center(child: Text('Not this one',
                    style: BT.body(size: 13, color: bt.tx2))),
              ),
            ),
          ]),
        ),
      ),
    );

    if (confirmed == true) await _add(rb);
  }
}

/// "Other" theme picker -- full top-level theme list with its own quick
/// filter field, since ~70 entries is too many to just scroll blind.
class _AllThemesSheet extends StatefulWidget {
  final List<Map<String, dynamic>>? themes;
  final bool loading;
  const _AllThemesSheet({required this.themes, required this.loading});
  @override State<_AllThemesSheet> createState() => _AllThemesSheetState();
}

class _AllThemesSheetState extends State<_AllThemesSheet> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final bt = context.bt;
    final all = widget.themes ?? const [];
    final shown = _filter.isEmpty
        ? all
        : all.where((t) => (t['name'] as String? ?? '')
            .toLowerCase()
            .contains(_filter.toLowerCase())).toList();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(children: [
            const SizedBox(height: 8),
            const SheetHandle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Row(children: [
                Text('All themes', style: BT.display(size: 20, color: bt.tx)),
                const Spacer(),
                if (widget.loading)
                  SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(bt.tx3))),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: bt.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: bt.cardBorder, width: BT.bw),
                ),
                child: TextField(
                  onChanged: (v) => setState(() => _filter = v),
                  style: BT.mono(size: 13, color: bt.tx),
                  decoration: InputDecoration(
                    hintText: 'Filter themes…',
                    hintStyle: BT.mono(size: 12, color: bt.txMuted),
                    prefixIcon: Icon(Icons.search, size: 16, color: bt.txMuted),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: shown.isEmpty
                  ? Center(child: Text(
                      widget.loading ? 'Loading…' : 'No matching themes',
                      style: BT.body(size: 13, color: bt.tx2)))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 20),
                      itemCount: shown.length,
                      itemBuilder: (_, i) {
                        final t = shown[i];
                        final id = t['id'] as int;
                        final name = t['name'] as String? ?? 'Theme $id';
                        return ListTile(
                          title: Text(name, style: BT.body(size: 14, color: bt.tx)),
                          onTap: () => Navigator.pop(context, (id, name)),
                        );
                      },
                    ),
            ),
          ]),
        ),
      ),
    );
  }
}
