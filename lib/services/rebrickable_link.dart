// lib/services/rebrickable_link.dart
//
// Direct link to a set's real Rebrickable page. Unlike affiliate_links.dart's
// Amazon/eBay links (no ASIN/listing id available for an arbitrary set, so
// those fall back to a search results page), Rebrickable's own set number
// IS the real identifier -- confirmed live (rebrickable.com/sets/{num}-1/
// resolves with a 200 with or without the name-slug suffix Rebrickable's
// own site normally appends), so no extra API call or stored field is
// needed to build this, just the set's own number.
String rebrickableUrl(String num) {
  final clean = num.replaceAll(RegExp(r'-\d+$'), '');
  return 'https://rebrickable.com/sets/$clean-1/';
}
