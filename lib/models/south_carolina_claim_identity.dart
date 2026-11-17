import 'dart:convert';

/// Identity of a reported claim group, independent of rolling-report row order.
/// Counts are intentionally excluded so corrected counts replace prior counts.
String southCarolinaClaimId(Map<String, dynamic> row) {
  final fields = [
    'drawDate',
    'prizeAmount',
    'gameName',
    'county',
    'retailerName',
    'retailerAddress',
    'city',
  ];
  final key = fields
      .map(
        (field) => row[field].toString().trim().toLowerCase().replaceAll(
          RegExp(r'\s+'),
          ' ',
        ),
      )
      .join('|');
  return 'sc-claim-${base64Url.encode(utf8.encode(key)).replaceAll('=', '')}';
}
