import Foundation
import NaturalLanguage

/// Простой экстрактивный суммаризатор: работает офлайн, без сторонних API.
/// Для короткого RSS-описания просто возвращает его очищенным.
/// Для длинного текста выбирает наиболее "важные" и при этом
/// непохожие друг на друга предложения (упрощённый TextRank + MMR).
enum NewsSummarizer {

    private static let stopWords: Set<String> = [
        "и", "в", "во", "не", "что", "он", "на", "я", "с", "со", "как", "а", "то",
        "все", "она", "так", "его", "но", "да", "ты", "к", "у", "же", "вы", "за",
        "бы", "по", "только", "ее", "мне", "было", "вот", "от", "меня", "еще",
        "нет", "о", "из", "ему", "теперь", "когда", "даже", "ну", "вдруг", "ли",
        "если", "уже", "или", "ни", "быть", "был", "него", "до", "вас", "нибудь",
        "опять", "уж", "вам", "сказал", "для", "этого", "этой", "этот", "эти",
        "тем", "которые", "которая", "который", "также", "после", "может", "будет",
        "чем", "при", "об", "их", "им", "своей", "своего", "свои", "чтобы"
    ]

    /// Жёсткий потолок длины итоговой сводки в символах. Работает как страховка
    /// уровнем ниже HTML-фильтрации: если у какого-то сайта окажется нетипичная
    /// вёрстка и в текст всё же просочится посторонний блок без нормальной
    /// пунктуации (из-за чего разбивка на предложения не сработает как надо),
    /// сводка всё равно не разрастётся на весь текст страницы.
    private static let maxSummaryLength = 1200

    /// Сжимает текст до нескольких (по умолчанию до 6) информативных предложений.
    /// Если в исходном тексте предложений меньше — возвращает столько, сколько есть.
    /// Общая версия, не завязанная на `NewsItem`, — так же используется для
    /// суммаризации полного текста статьи, подгруженного по ссылке.
    static func summarize(title: String, text: String, maxSentences: Int = 6) -> String {
        let source = text.isEmpty ? title : text
        var sentences = dedupedSentences(splitIntoSentences(source))

        // Заголовок уже показан отдельно в интерфейсе — если источник
        // повторяет его первой фразой, не дублируем это в сводке.
        sentences = sentences.filter { !isNearDuplicate($0, of: title) }

        guard !sentences.isEmpty else {
            // Раньше здесь возвращался необрезанный `source`. Но когда описания
            // нет вовсе (`text.isEmpty`), source — это сам заголовок, и после
            // фильтрации совпадений с заголовком мы падали именно на этот
            // случай: сводка становилась дословной копией заголовка. Теперь
            // отдаём пустую строку, если то, что осталось, всё равно
            // не отличается от заголовка — интерфейс показывает вместо
            // сводки заглушку "нет описания", а не дублирует его.
            let fallback = capLength(source)
            return isNearDuplicate(fallback, of: title) ? "" : fallback
        }

        guard sentences.count > maxSentences else {
            return capLength(sentences.joined(separator: " "))
        }

        let scored = scoreSentences(sentences)
        let selected = selectDiverseSentences(from: scored, limit: maxSentences)
            .sorted { $0.index < $1.index } // сохраняем исходный порядок
            .map { $0.sentence }

        return capLength(selected.joined(separator: " "))
    }

    /// Обрезает текст по последней границе предложения в пределах лимита, а не
    /// посреди слова — так обрезанный текст выглядит опрятно, а не обрывается на полуслове.
    private static func capLength(_ text: String) -> String {
        guard text.count > maxSummaryLength else { return text }
        let cutIndex = text.index(text.startIndex, offsetBy: maxSummaryLength)
        let truncated = String(text[..<cutIndex])
        if let lastBoundary = truncated.range(of: "[.!?…]\\s", options: [.regularExpression, .backwards]) {
            return String(truncated[..<lastBoundary.upperBound]).trimmingCharacters(in: .whitespaces)
        }
        return truncated.trimmingCharacters(in: .whitespaces) + "…"
    }

    /// Сжимает описание новости из RSS. Обычно RSS `<description>` — это
    /// короткий тизер на 1–2 предложения, поэтому и результат ограничен
    /// тем, сколько текста вообще есть; для развёрнутой выжимки используется
    /// `summarize(title:text:)` над полным текстом статьи (см. ArticleContentFetcher).
    static func summarize(_ item: NewsItem, maxSentences: Int = 8) -> String {
        summarize(title: item.title, text: item.rawDescription, maxSentences: maxSentences)
    }

    /// Ключевые слова новости — для чипов-тегов в интерфейсе.
    /// Берёт самые частые значимые слова из заголовка и описания.
    static func keywords(for item: NewsItem, limit: Int = 4) -> [String] {
        let words = tokenize(item.title) + tokenize(item.rawDescription)
        var frequency: [String: Int] = [:]
        var firstSeenOrder: [String] = []
        for word in words {
            if frequency[word] == nil { firstSeenOrder.append(word) }
            frequency[word, default: 0] += 1
        }
        return firstSeenOrder
            .sorted { (frequency[$0] ?? 0) > (frequency[$1] ?? 0) }
            .prefix(limit)
            .map { $0.capitalized }
    }

    /// Убирает предложения-дубликаты, в т.ч. почти одинаковые (перефразированные),
    /// которые попадают в ленту из-за повторов текста анонса в самом источнике —
    /// например, когда лид-абзац почти слово в слово повторяется в теле статьи.
    private static func dedupedSentences(_ rawSentences: [String]) -> [String] {
        var result: [String] = []
        for sentence in rawSentences {
            let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            guard !result.contains(where: { isNearDuplicate($0, of: trimmed) }) else { continue }
            result.append(trimmed)
        }
        return result
    }

    /// Схожесть двух фраз по пересечению значимых слов (индекс Жаккара).
    /// Ловит не только точные повторы, но и переформулировки, где почти
    /// все ключевые слова совпадают, а порядок или окончания — нет.
    private static func isNearDuplicate(_ a: String, of b: String, threshold: Double = 0.6) -> Bool {
        let wordsA = Set(tokenize(a))
        let wordsB = Set(tokenize(b))
        guard !wordsA.isEmpty, !wordsB.isEmpty else { return a.caseInsensitiveCompare(b) == .orderedSame }
        let intersection = wordsA.intersection(wordsB).count
        let union = wordsA.union(wordsB).count
        guard union > 0 else { return false }
        return Double(intersection) / Double(union) >= threshold
    }

    /// Формирует сводный дайджест по категории: список заголовков с краткими описаниями.
    static func digest(for category: NewsCategory, items: [NewsItem], language: AppLanguage, limit: Int = 5) -> String {
        let selected = items
            .filter { $0.category == category }
            .sorted { ($0.pubDate ?? .distantPast) > ($1.pubDate ?? .distantPast) }
            .prefix(limit)

        guard !selected.isEmpty else {
            return L10n.tf("digest.empty", language, category.localizedName(language))
        }

        var lines: [String] = []
        for (index, item) in selected.enumerated() {
            let line = item.summary.isEmpty ? "\(index + 1). \(item.title)" : "\(index + 1). \(item.title) — \(item.summary)"
            lines.append(line)
        }
        return lines.joined(separator: "\n")
    }

    /// Минимум предложений, который должно содержать краткое содержание, когда
    /// в источнике вообще есть, из чего его набрать. Тизера из RSS `<description>`
    /// (обычно 1–2 предложения) для этого почти никогда не хватает — реальный
    /// набор нужной длины даёт только полный текст статьи, поэтому именно
    /// `minSentences` служит сигналом для `NewsAggregatorService`: если сводка,
    /// построенная по тизеру, короче этого порога, значит нужно догрузить
    /// полный текст и пересчитать сводку по нему (см. `expandShortSummaries`).
    static let minSentences = 5

    /// Число предложений в уже готовом тексте — используется, чтобы понять,
    /// хватает ли текущей сводки, или её нужно расширять по полному тексту статьи.
    static func sentenceCount(in text: String) -> Int {
        splitIntoSentences(text).count
    }

    // MARK: - Внутренняя механика

    private struct ScoredSentence {
        let sentence: String
        let score: Double
        let index: Int
        let words: Set<String>
    }

    /// Разбивает текст на предложения через NLTokenizer вместо наивного
    /// разделения по точкам. Раньше split по "." резал текст и на сокращениях
    /// ("т.д.", "г.", "т.е."), и на десятичных числах ("3.5%"), из-за чего
    /// в краткое содержание попадали "битые" обрывки слов и цифр.
    private static func splitIntoSentences(_ text: String) -> [String] {
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text
        var sentences: [String] = []
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            let sentence = text[range].trimmingCharacters(in: .whitespacesAndNewlines)
            if sentence.count > 3 {
                sentences.append(sentence)
            }
            return true
        }
        return sentences
    }

    private static func scoreSentences(_ sentences: [String]) -> [ScoredSentence] {
        // Частота значимых слов по всему тексту
        var wordFrequency: [String: Int] = [:]
        let allWords = sentences.flatMap { tokenize($0) }
        for word in allWords {
            wordFrequency[word, default: 0] += 1
        }

        return sentences.enumerated().map { index, sentence in
            let words = tokenize(sentence)
            let rawScore = words.reduce(0.0) { $0 + Double(wordFrequency[$1] ?? 0) }
            // Нормируем на длину, чтобы не выигрывали только длинные предложения
            let normalized = words.isEmpty ? 0 : rawScore / Double(words.count)
            // Небольшой бонус первому предложению — обычно оно самое информативное в новости
            let positionBonus = index == 0 ? 1.5 : 1.0
            return ScoredSentence(sentence: sentence, score: normalized * positionBonus,
                                   index: index, words: Set(words))
        }
    }

    /// Жадный отбор по принципу MMR (Maximal Marginal Relevance): на каждом шаге
    /// берём предложение с лучшим балансом "важно" и "не похоже на уже выбранное".
    /// Без этого TF-скоринг тянул в сводку несколько предложений про одно и то же —
    /// они не были дословными дублями, но пересказывали один факт разными словами,
    /// из-за чего одни и те же ключевые слова всё равно повторялись в сводке.
    private static func selectDiverseSentences(from scored: [ScoredSentence], limit: Int) -> [ScoredSentence] {
        var remaining = scored
        var picked: [ScoredSentence] = []
        let lambda = 0.55 // вес важности против веса новизны — понижен, чтобы сильнее
                           // штрафовать предложения, пересказывающие уже выбранное теми же словами

        while picked.count < limit && !remaining.isEmpty {
            var bestIndex = 0
            var bestValue = -Double.infinity
            for (i, candidate) in remaining.enumerated() {
                let maxOverlap = picked.map { jaccard(candidate.words, $0.words) }.max() ?? 0
                let value = lambda * candidate.score - (1 - lambda) * maxOverlap * candidate.score
                if value > bestValue {
                    bestValue = value
                    bestIndex = i
                }
            }
            picked.append(remaining.remove(at: bestIndex))
        }
        return picked
    }

    private static func jaccard(_ a: Set<String>, _ b: Set<String>) -> Double {
        guard !a.isEmpty, !b.isEmpty else { return 0 }
        let intersection = a.intersection(b).count
        let union = a.union(b).count
        return union == 0 ? 0 : Double(intersection) / Double(union)
    }

    private static func tokenize(_ text: String) -> [String] {
        text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count > 2 && !stopWords.contains($0) }
    }
}
