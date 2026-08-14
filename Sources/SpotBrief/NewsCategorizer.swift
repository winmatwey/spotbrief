import Foundation

/// Эвристический классификатор новостей по ключевым словам в заголовке и описании.
/// Работает полностью офлайн, без обращений к внешним AI-сервисам.
enum NewsCategorizer {

    static func categorize(_ item: NewsItem) -> NewsCategory {
        let title = item.title.lowercased()
        let body = item.rawDescription.lowercased()

        var bestCategory: NewsCategory = .society
        var bestScore = 0.0

        for category in NewsCategory.allCases where !category.keywords.isEmpty {
            var score = 0.0
            for keyword in category.keywords {
                // Фразы из нескольких слов — куда более редкий и однозначный сигнал
                // темы, чем одно общее слово ("лига чемпионов" почти всегда спорт,
                // а просто "лига" может означать и "Лигу Наций"), поэтому они весят
                // заметно больше.
                let keywordWeight = keyword.contains(" ") ? 2.5 : 1.0

                let titleHits = wholeWordOccurrences(of: keyword, in: title)
                let bodyHits = wholeWordOccurrences(of: keyword, in: body)

                // Совпадение в заголовке — куда более надёжный сигнал темы новости,
                // чем где-то в середине описания, поэтому считаем его с двойным весом.
                score += Double(titleHits) * keywordWeight * 2.0
                score += Double(bodyHits) * keywordWeight
            }
            if score > bestScore {
                bestScore = score
                bestCategory = category
            }
        }

        return bestCategory
    }

    static func categorizeAll(_ items: [NewsItem]) -> [NewsItem] {
        items.map { item in
            var mutable = item
            mutable.category = categorize(item)
            return mutable
        }
    }

    /// Считает вхождения ключевого слова/фразы как ЦЕЛОГО слова, а не подстроки —
    /// без этой проверки, например, ключ "банк" ложно засчитывался бы и внутри
    /// "банкет", "банка" или фамилии "Банкетов". Границей слова считается любой
    /// небуквенный символ (пробел, знак препинания, начало/конец текста).
    private static func wholeWordOccurrences(of keyword: String, in haystack: String) -> Int {
        guard !keyword.isEmpty else { return 0 }
        var count = 0
        var searchRange = haystack.startIndex..<haystack.endIndex
        while let range = haystack.range(of: keyword, range: searchRange) {
            let beforeOK = range.lowerBound == haystack.startIndex
                || !haystack[haystack.index(before: range.lowerBound)].isLetter
            let afterOK = range.upperBound == haystack.endIndex
                || !haystack[range.upperBound].isLetter
            if beforeOK && afterOK {
                count += 1
            }
            searchRange = range.upperBound..<haystack.endIndex
        }
        return count
    }
}
