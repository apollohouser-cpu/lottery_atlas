"""Compile validated Arizona observations for app integration.

This module does not publish, collect sources, or declare state acceptance.
Raw captures stay private; source-specific acquisition dates remain unchanged.
"""
import copy
from arizona_snapshot import validate

LIMITATIONS = [
    'Browser DOM observations; direct HTTP collection remains unavailable.',
    'Results are bounded recent selections, not complete historical coverage.',
    'Actual payout reports, winner counts and retailer joins are unavailable.',
    'Remaining prizes are source-listed prize counts, not tickets or retailer inventory.',
    'Progressive jackpot observations are not guaranteed prizes or actual payouts.',
    'Product rule images may have empty alternative text; symbol interpretation is unavailable.',
    'Instant Tabs per-game coverage and complete promotion/retired history are unavailable.',
    'Source rule conflicts and ending-date ambiguities remain explicitly disclosed.',
]
PRODUCT_FIELDS = ('gameNumber','header','sourceUrl','retrievedAt','sourceStatus',
                  'overallOddsOneIn','tiers','prizeDetails','inventoryAvailable',
                  'symbolInterpretationAvailable')


def compile_coverage(candidate, retained):
    validated = validate(candidate, retained)
    products = {}
    for kind, rows in validated['products'].items():
        products[kind] = []
        for row in rows:
            product = {k:copy.deepcopy(row[k]) for k in PRODUCT_FIELDS}
            # Image-dependent text is not presented as complete instructions.
            product['rulePresentation'] = {
                'status':'official-source-required' if row['rules']['images'] else 'literal-text',
                'text':row['rules']['text'] if not row['rules']['images'] else None,
                'sourceUrl':row['sourceUrl'],
                'reason':'Consult official illustrated instructions for matching symbols.' if row['rules']['images'] else None,
            }
            if kind == 'fast-play':
                for key in ('progressiveJackpotObserved','progressiveJackpotGuaranteed','faq'):
                    product[key] = copy.deepcopy(row[key])
            products[kind].append(product)
    return {
        'schemaVersion':1,'stateCode':'AZ',
        'recordType':'supported-coverage-candidate',
        'productionReady':False,
        'acquisitionMethod':'browser-dom-observation',
        'atomicSourceCollection':False,
        'drawGroups':copy.deepcopy(validated['draws']['groups']),
        'drawProvenance':copy.deepcopy(validated['draws']['provenance']),
        'products':products,
        'rules':copy.deepcopy(validated['rules']),
        'ruleDetails':copy.deepcopy(validated['details']),
        'endingNotices':copy.deepcopy(validated['endings']),
        'limitations':list(LIMITATIONS),
    }
