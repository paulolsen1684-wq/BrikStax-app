// lib/utils/ebay_affiliate.dart
//
// Builds eBay Partner Network (EPN) affiliate search links. Separate from
// the RapidAPI eBay pricing integration (services/api.dart) -- that's a
// paid market-data API for showing prices in-app, this is eBay's own
// affiliate program for earning commission when someone clicks through.
//
// EBAY_CAMPAIGN_ID ships blank until the EPN application is approved --
// campid is required for commission attribution, so a link built with a
// blank id just won't earn anything, but it still works as a plain eBay
// search link in the meantime (nothing breaks for the user).
const String _kEbayCampaignId = '5339171029';

/// A link to eBay's sold/completed listings for [setNum]/[setName] -- "what
/// did this actually sell for," not just asking prices from active
/// listings. [source] tags which part of the app the click came from
/// (EPN's customid param), for your own click-through reporting.
String ebayAffiliateSoldSearchUrl({
  required String setNum,
  String? setName,
  String source = 'app',
}) {
  final params = <String, String>{
    '_nkw': 'LEGO $setNum${setName != null && setName.isNotEmpty ? ' $setName' : ''}',
    'LH_Sold': '1',
    'LH_Complete': '1',
    'mkevt': '1',
    'mkcid': '1',
    'toolid': '10001',
    'customid': source,
    if (_kEbayCampaignId.isNotEmpty) 'campid': _kEbayCampaignId,
  };
  return Uri.https('www.ebay.com', '/sch/i.html', params).toString();
}
