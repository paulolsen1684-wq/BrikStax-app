// lib/models/brickset_extras.dart
//
// BrickSet-sourced extras for Set Detail: instructions links, the average
// user star rating, and additional gallery images. Kept separate from
// LegoSet (which is our own local collection model, only ever populated
// from user input + Rebrickable) since none of this is stored locally --
// it's fetched fresh per Set Detail view, same lifecycle as Api.fetchSetDetails'
// retail/exitDate pair.

class BrickSetInstruction {
  final String url;
  final String description;
  const BrickSetInstruction({required this.url, required this.description});
}

class BrickSetExtras {
  /// Average user rating out of 5, or null if BrickSet has no ratings yet
  /// for this set (its own `rating` field comes back as 0 in that case,
  /// which we treat as "no data" rather than a real zero-star rating).
  final double? rating;
  final int ratingCount;
  final int reviewCount;
  final String? bricksetUrl;
  final List<BrickSetInstruction> instructions;
  final List<String> additionalImages;

  const BrickSetExtras({
    this.rating,
    this.ratingCount = 0,
    this.reviewCount = 0,
    this.bricksetUrl,
    this.instructions = const [],
    this.additionalImages = const [],
  });

  bool get hasRating => rating != null && ratingCount > 0;
  bool get hasInstructions => instructions.isNotEmpty;
  bool get hasExtraImages => additionalImages.isNotEmpty;
}
