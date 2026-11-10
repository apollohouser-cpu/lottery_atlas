"""Compose app-facing instant details without mixing inventory and printed runs."""
import copy


def compose(products, images, instructions, structures, exclusions):
    def indexed(rows, key):
        result = {}
        for row in rows:
            identity = row[key]
            if not isinstance(identity, str) or not identity or identity in result:
                raise ValueError('Invalid or duplicate product identity')
            result[identity] = row
        return result

    catalog = indexed(products['games'], 'id')
    sources = indexed(images, 'gameId')
    guides = indexed(instructions, 'gameId')
    tiers = indexed(structures, 'gameId')
    omitted = indexed(exclusions, 'gameId')
    if (not catalog or set(catalog) != set(sources) or set(catalog) != set(guides)
            or set(tiers) & set(omitted) or set(tiers) | set(omitted) != set(catalog)):
        raise ValueError('Incomplete or overlapping product detail coverage')
    result = []
    for gid in sorted(catalog, key=int):
        product, source, guide = catalog[gid], sources[gid], guides[gid]
        disposition = tiers.get(gid, omitted.get(gid))
        if product['detailImage'] != source['sourceUrl']:
            raise ValueError('Catalog detail source mismatch')
        for record in (guide, disposition):
            for key, source_key in [('sourceUrl', 'sourceUrl'),
                                    ('sourceSha256', 'sha256'),
                                    ('sourceRetrievedAt', 'retrievedAt')]:
                if record.get(key) != source[source_key]:
                    raise ValueError('Product detail provenance mismatch')
        # Keep instruction-screen history separate from the later tier decision.
        instruction = {k: copy.deepcopy(v) for k, v in guide.items()
                       if k != 'tierCoverage'}
        result.append({
            'gameId': gid,
            'product': copy.deepcopy(product),
            'instructions': instruction,
            'prizeStructureStatus': 'reviewed' if gid in tiers else 'excluded',
            'prizeStructure': copy.deepcopy(tiers.get(gid)),
            'prizeStructureExclusion': copy.deepcopy(omitted.get(gid)),
            'inventoryScope': 'Published top prizes only; not all-tier remaining inventory.',
            'printedStructureScope': 'Printed prize combinations and run quantities; not dated claims or remaining prizes.',
            'actualClaimsAvailable': False,
            'retailerInventoryAvailable': False,
        })
    return result
