import Foundation

/// Загружает полный текст статьи по ссылке из RSS и извлекает из HTML читаемый
/// текст простым эвристическим разбором — без внешних библиотек и без ИИ.
///
/// Зачем это нужно: RSS `<description>` у подавляющего большинства лент — это
/// короткий тизер на 1–2 предложения (так живёт RSS-формат), и суммаризатору
/// просто не из чего сделать содержательную выжимку — сколько текста дали,
/// столько он и пересказывает. Полный текст статьи даёт на порядок больше
/// материала, поэтому и краткое содержание выходит куда более содержательным
/// и с меньшим повтором одних и тех же фраз.
enum ArticleContentFetcher {

    enum FetchError: Error {
        case badResponse
        case notEnoughText
    }

    /// Заголовочные слова, по которым статья почти наверняка представляет
    /// собой не один связный текст, а набор независимых мини-материалов —
    /// гороскопы (по знаку зодиака) или колонки читательских писем (каждое
    /// письмо — отдельная, не связанная с другими тема). Экстрактивному
    /// суммаризатору, рассчитанному на один связный текст, такое скармливать
    /// нельзя: он выхватывает "важные" предложения из разных писем/тем
    /// и склеивает их в бессвязную кашу.
    private static let multiTopicTitleKeywords: Set<String> = [
        "гороскоп", "horoscope", "horoskop", "zodiac", "sternzeichen",
        "dear abby", "ask amy", "dear prudence", "dear prudie", "miss manners", "dear annie"
    ]

    private static let zodiacSigns: [String] = [
        "овен", "телец", "близнецы", "рак", "лев", "дева",
        "весы", "скорпион", "стрелец", "козерог", "водолей", "рыбы"
    ]

    /// Проверка ДО загрузки — по заголовку и тизеру. Дешёвая и достаточная
    /// для явных случаев (гороскопы, известные колонки советов).
    static func isLikelyMultiTopicContent(title: String, description: String) -> Bool {
        let haystack = (title + " " + description).lowercased()
        if multiTopicTitleKeywords.contains(where: { haystack.contains($0) }) { return true }
        let signHits = zodiacSigns.filter { haystack.contains($0) }.count
        return signHits >= 4
    }

    /// Проверка ПОСЛЕ загрузки — по структуре самого текста. Ловит колонки
    /// советов и без характерного заголовка: в них почти всегда несколько
    /// раз подряд встречается обращение вида "DEAR ABBY:" / "DEAR ТАКОЙ-ТО:" —
    /// по одному на каждое отдельное, не связанное с другими письмо.
    /// Одно такое обращение — это нормально (например, вступление письма),
    /// а вот два и больше — явный признак, что в тексте склеено несколько
    /// разных материалов.
    private static func looksLikeConcatenatedLetters(_ text: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: "(?i)\\bDEAR [A-ZÀ-Ö][^:.!?]{1,40}:") else { return false }
        let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.numberOfMatches(in: text, range: nsRange) >= 2
    }

    /// Пытается получить читаемый текст статьи. Делает до двух попыток:
    /// некоторые сайты на ПЕРВЫЙ запрос в сессии отдают страницу с баннером
    /// согласия на cookies, антибот-проверку или иную заглушку вместо статьи,
    /// а на повторный запрос (когда сессия/cookie уже "запомнены") —
    /// уже настоящую страницу. Раньше это выглядело как "иногда открывается
    /// битое краткое содержание, а если выйти из статьи и зайти снова — всё
    /// в порядке": пользователь вручную делал то, что теперь делает эта
    /// функция сама, за один визит.
    static func fetchArticleText(from url: URL, relatedTo title: String) async throws -> String {
        if let text = try? await singleAttempt(url), isRelevant(text, to: title), !looksLikeConcatenatedLetters(text) {
            return text
        }
        if let text = try? await singleAttempt(url), isRelevant(text, to: title), !looksLikeConcatenatedLetters(text) {
            return text
        }
        throw FetchError.notEnoughText
    }

    private static func singleAttempt(_ url: URL) async throws -> String {
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (compatible; SpotBriefApp/1.0)", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 12

        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw FetchError.badResponse
        }

        guard let html = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) else {
            throw FetchError.notEnoughText
        }

        let text = extractReadableText(from: html)
        guard text.count > 200 else { throw FetchError.notEnoughText }
        return text
    }

    /// Проверяет, что извлечённый текст действительно похож на статью С ЭТИМ
    /// заголовком, а не на баннер согласия/заглушку/страницу с другим
    /// материалом — то есть на общий, но полезный признак "это не та
    /// страница" вне зависимости от его конкретной причины.
    private static func isRelevant(_ text: String, to title: String) -> Bool {
        let titleWords = significantWords(in: title)
        guard !titleWords.isEmpty else { return true } // нечем судить — не блокируем
        let lowered = text.lowercased()
        let matches = titleWords.filter { lowered.contains($0) }.count
        // Мягкий порог: словоформы (падежи/склонения) собьют точное совпадение
        // части слов заголовка, но не всех сразу — достаточно трети.
        return matches >= max(1, titleWords.count / 3)
    }

    private static func significantWords(in text: String) -> [String] {
        text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count > 3 }
    }

    /// Очень простой аналог "режима чтения". Работает в несколько этапов, потому
    /// что раньше он собирал текст из ВСЕХ `<p>` на странице — а это захватывало
    /// не только тело статьи, но и сайдбары "Все новости", виджеты "Загрузить ещё",
    /// списки похожих материалов и т.п. Из-за этого в краткое содержание попадала
    /// каша из чужих заголовков вместо текста самой новости.
    private static func extractReadableText(from html: String) -> String {
        var cleaned = html
        cleaned = cleaned.replacingOccurrences(of: "(?is)<script.*?</script>", with: " ", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: "(?is)<style.*?</style>", with: " ", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: "(?is)<!--.*?-->", with: " ", options: .regularExpression)

        // Код (блоки <pre> и инлайновый <code>) — не текст статьи, а листинги,
        // конфиги, регулярки и т.п. Раньше это не вырезалось, и на сайтах вроде
        // Habr, где код лежит прямо внутри тех же <p>, что и окружающий текст,
        // строки конфигурации и кода попадали в текст статьи наравне с прозой.
        // Экстрактивный суммаризатор такие "предложения" не отличал от обычных —
        // они содержали часто повторяющиеся технические термины и получали
        // высокий score, из-за чего в краткое содержание просачивалась
        // нечитаемая мешанина из кода вперемешку с настоящими предложениями.
        cleaned = cleaned.replacingOccurrences(of: "(?is)<pre[^>]*>.*?</pre>", with: " ", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: "(?is)<code[^>]*>.*?</code>", with: " ", options: .regularExpression)

        // Шаг 1: вырезаем целиком навигацию, сайдбары, подвал и другие сквозные
        // блоки — на большинстве новостных сайтов "похожие материалы" и списки
        // последних новостей размечены именно этими семантическими тегами.
        for tag in ["nav", "header", "footer", "aside"] {
            cleaned = cleaned.replacingOccurrences(of: "(?is)<\(tag)[^>]*>.*?</\(tag)>", with: " ", options: .regularExpression)
        }

        // Шаг 2: если на странице есть тег <article>, тело статьи почти всегда
        // именно там — сужаем поиск параграфов только до него, полностью
        // игнорируя всё остальное содержимое страницы.
        if let articleRange = firstTagRange(tag: "article", in: cleaned) {
            cleaned = String(cleaned[articleRange])
        }

        let paragraphs = extractParagraphs(from: cleaned)
        return dedupParagraphs(paragraphs).joined(separator: " ")
    }

    /// Находит диапазон содержимого первого тега `<article>...</article>`.
    /// Простой, не вложенный поиск открывающего/закрывающего тега — этого
    /// достаточно для подавляющего большинства новостных вёрсток, где
    /// `<article>` на странице ровно один и не пересекается сам с собой.
    private static func firstTagRange(tag: String, in html: String) -> Range<String.Index>? {
        guard let openRange = html.range(of: "(?is)<\(tag)[^>]*>", options: .regularExpression),
              let closeRange = html.range(of: "</\(tag)>", options: [.caseInsensitive, .backwards]),
              openRange.upperBound < closeRange.lowerBound else {
            return nil
        }
        return openRange.upperBound..<closeRange.lowerBound
    }

    private static func extractParagraphs(from html: String) -> [String] {
        var paragraphs: [String] = []
        guard let regex = try? NSRegularExpression(pattern: "(?is)<p[^>]*>(.*?)</p>") else { return paragraphs }
        let nsRange = NSRange(html.startIndex..<html.endIndex, in: html)
        regex.enumerateMatches(in: html, range: nsRange) { match, _, _ in
            guard let match, let range = Range(match.range(at: 1), in: html) else { return }
            let text = stripTags(String(html[range]))
            guard isLikelyArticleText(text) else { return }
            paragraphs.append(text)
        }
        return paragraphs
    }

    /// Отсеивает то, что похоже не на текст статьи, а на элемент виджета со
    /// списком других новостей: короткие обрывки, строки, заканчивающиеся
    /// временем публикации ("... Политика 08:35"), и типовые ярлыки-рубрики.
    private static func isLikelyArticleText(_ text: String) -> Bool {
        guard text.count > 60 else { return false }
        if text.range(of: "\\d{1,2}:\\d{2}\\s*$", options: .regularExpression) != nil { return false }

        let navLabels: Set<String> = [
            "политика", "общество", "экономика", "спорт", "технологии", "наука",
            "культура", "происшествия", "подписка на рбк", "загрузить еще",
            "загрузить ещё", "читайте также", "все новости", "входит в сюжеты"
        ]
        let normalized = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if navLabels.contains(normalized) { return false }

        if looksLikeCode(text) { return false }

        return true
    }

    /// Подстраховка на случай, если код на странице не обёрнут в `<pre>`/`<code>`
    /// (например, вставлен как обычный текст с переносами строк внутри `<p>`).
    /// Считает долю символов, типичных для кода/конфигов (`{ } ; < > = | \ _`)
    /// среди непробельных символов параграфа — у обычной прозы она пренебрежимо
    /// мала, у конфигов и команд шелла — заметно выше.
    private static func looksLikeCode(_ text: String) -> Bool {
        let codeCharacters = CharacterSet(charactersIn: "{}[]<>;=|\\_`")
        let nonWhitespace = text.unicodeScalars.filter { !CharacterSet.whitespacesAndNewlines.contains($0) }
        guard nonWhitespace.count > 20 else { return false }
        let codeCount = nonWhitespace.filter { codeCharacters.contains($0) }.count
        return Double(codeCount) / Double(nonWhitespace.count) > 0.04
    }

    /// Убирает повторяющиеся параграфы (например, дублирующийся текст в мобильной
    /// и десктопной версии разметки одной и той же страницы).
    private static func dedupParagraphs(_ paragraphs: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for paragraph in paragraphs {
            let key = paragraph.lowercased()
            guard !seen.contains(key) else { continue }
            seen.insert(key)
            result.append(paragraph)
        }
        return result
    }

    private static func stripTags(_ raw: String) -> String {
        var text = raw.replacingOccurrences(of: "(?is)<[^>]+>", with: " ", options: .regularExpression)
        text = decodeHTMLEntities(text)
        text = text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Полноценно декодирует HTML-сущности (именованные и числовые/шестнадцатеричные) —
    /// без этого в тексте статьи оставались "битые" фрагменты вроде "&#8217;"
    /// вместо апострофа. Та же логика, что и в RSSFeedParser.decodeHTMLEntities,
    /// но здесь работаем с полным текстом статьи, а не с тизером из RSS.
    private static func decodeHTMLEntities(_ input: String) -> String {
        var text = input

        let namedEntities: [String: String] = [
            "&nbsp;": " ", "&amp;": "&", "&quot;": "\"", "&apos;": "'",
            "&laquo;": "«", "&raquo;": "»",
            "&ndash;": "–", "&mdash;": "—", "&hellip;": "…",
            "&lsquo;": "‘", "&rsquo;": "’", "&ldquo;": "“", "&rdquo;": "”",
            "&lt;": "<", "&gt;": ">"
        ]
        for (entity, replacement) in namedEntities {
            text = text.replacingOccurrences(of: entity, with: replacement)
        }

        // Числовые сущности вида &#8212; и &#x2014;
        if let regex = try? NSRegularExpression(pattern: "&#(x[0-9A-Fa-f]+|[0-9]+);") {
            let nsText = text as NSString
            let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))
            for match in matches.reversed() {
                let codeString = nsText.substring(with: match.range(at: 1))
                let scalarValue: UInt32?
                if codeString.hasPrefix("x") || codeString.hasPrefix("X") {
                    scalarValue = UInt32(codeString.dropFirst(), radix: 16)
                } else {
                    scalarValue = UInt32(codeString)
                }
                if let value = scalarValue, let scalar = Unicode.Scalar(value) {
                    text = (text as NSString).replacingCharacters(in: match.range, with: String(scalar))
                }
            }
        }
        return text
    }
}
