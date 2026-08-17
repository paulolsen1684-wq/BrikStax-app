// lib/services/affiliate_links.dart
//
// Amazon/eBay affiliate SEARCH links for a LEGO set. There's no specific
// product URL for an arbitrary set -- Rebrickable doesn't give us an ASIN
// or eBay listing id -- so unlike the Worker's buildAmazonAffiliateLink/
// buildEbayAffiliateLink (which tag one human-curated deal URL), these
// build a search results page instead, with the same tag/campaign id
// already attached from the start. See K.amazonTag/K.ebayCampaignId for
// why embedding these client-side is fine (public identifiers, not keys).
import 'constants.dart';

String amazonSearchUrl(String setNum, String name) {
  final q = Uri.encodeQueryComponent('LEGO $setNum $name'.trim());
  return 'https://www.amazon.com/s?k=$q&tag=${K.amazonTag}';
}

String ebaySearchUrl(String setNum, String name) {
  final q = Uri.encodeQueryComponent('LEGO $setNum $name'.trim());
  return 'https://www.ebay.com/sch/i.html?_nkw=$q'
      '&mkevt=1&mkcid=1&toolid=10001&customid=wishlist'
      '&campid=${K.ebayCampaignId}';
}
