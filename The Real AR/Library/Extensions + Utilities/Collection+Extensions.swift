// MARK: - Helper

// Filters the given collections to their interesection where comparator returns that the values are
// the same
// Returns an array of filtered collections
func filterByIntersection<C: Collection, E>(
    _ collections: [C],
    where comparator: (E, E) -> Bool
) -> [[E]] where E == C.Element {
    var results: [[E]] = []

    for currentCollection in collections {
        var resultingCollection: [E] = []

        for item1 in currentCollection {
            let keepItem = collections.reduce(true, { (isContained, c) -> Bool in
                isContained && c.contains(where: { (item2) -> Bool in
                    comparator(item1, item2)
                })
            })
            if keepItem {
                resultingCollection.append(item1)
            }
        }

        results.append(resultingCollection)
    }

    return results
}
