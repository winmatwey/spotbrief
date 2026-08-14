import Foundation

/// Простой потоковый парсер RSS 2.0 без внешних зависимостей.
final class RSSFeedParser: NSObject, XMLParserDelegate {

    private var items: [NewsItem] = []
    private var parseError: Error?
    private let sourceName: String

    enum FeedError: LocalizedError {
        case httpStatus(Int)
        case malformedXML(underlying: Error?)

        var errorDescription: String? {
            switch self {
            case .httpStatus(let code):
                return "сервер ответил кодом \(code)"
            case .malformedXML(let underlying):
                return "не удалось разобрать XML" + (underlying.map { " (\($0.localizedDescription))" } ?? "")
            }
        }
    }

    private var currentElement = ""
    private var currentTitle = ""
    private var currentDescription = ""
    private var currentContentEncoded = ""
    private var currentLink = ""
    private var currentPubDate = ""
    private var insideItem = false

    private static let dateFormatters: [DateFormatter] = {
        let formats = [
            "EEE, dd MMM yyyy HH:mm:ss Z",
            "EEE, dd MMM yyyy HH:mm:ss zzz",
            "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        ]
        return formats.map { fmt in
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US_POSIX")
            df.dateFormat = fmt
            return df
        }
    }()

    init(sourceName: String) {
        self.sourceName = sourceName
    }

    /// Загружает и парсит RSS-ленту по указанному URL.
    func parse(url: URL) async throws -> [NewsItem] {
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (compatible; SpotBriefApp/1.0)", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 15

        let (data, response) = try await URLSession.shared.data(for: request)

        // Раньше HTTP-статус не проверялся: страница ошибки (404/500, часто
        // это HTML, а не RSS) просто "не парсилась" молча, и источник тихо
        // отдавал 0 новостей вместо понятной ошибки в списке источников.
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw FeedError.httpStatus(http.statusCode)
        }

        items = []
        parseError = nil

        let parser = XMLParser(data: data)
        parser.delegate = self
        let success = parser.parse()

        // Аналогично: результат parser.parse() раньше игнорировался — битый
        // XML тоже молча давал пустой список вместо ошибки.
        guard success else {
            throw FeedError.malformedXML(underlying: parseError)
        }

        return items
    }

    // MARK: XMLParserDelegate

    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?,
                attributes attributeDict: [String: String] = [:]) {
        currentElement = elementName
        if elementName == "item" {
            insideItem = true
            currentTitle = ""
            currentDescription = ""
            currentContentEncoded = ""
            currentLink = ""
            currentPubDate = ""
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard insideItem else { return }
        switch currentElement {
        case "title": currentTitle += string
        case "description": currentDescription += string
        case "content:encoded": currentContentEncoded += string
        case "link": currentLink += string
        case "pubDate": currentPubDate += string
        default: break
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item" {
            let title = clean(currentTitle)
            // Многие ленты (РБК, Коммерсантъ и др.) дублируют текст анонса
            // и в <description>, и в <content:encoded>. Раньше оба текста
            // склеивались в одну строку, из-за чего в кратком содержании
            // повторялись одни и те же слова/предложения. Теперь выбираем
            // один источник — предпочитаем более полный content:encoded,
            // а <description> используем только как запасной вариант.
            let plainDescription = clean(currentDescription)
            let encodedDescription = clean(currentContentEncoded)
            let description = encodedDescription.count > plainDescription.count
                ? encodedDescription
                : plainDescription
            if !title.isEmpty {
                let item = NewsItem(
                    title: title,
                    rawDescription: description,
                    link: URL(string: currentLink.trimmingCharacters(in: .whitespacesAndNewlines)),
                    pubDate: parseDate(currentPubDate),
                    sourceName: sourceName
                )
                items.append(item)
            }
            insideItem = false
        }
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        self.parseError = parseError
    }

    // MARK: Вспомогательные функции

    private func clean(_ raw: String) -> String {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        // Убираем CDATA-обёртку, если парсер не снял её сам
        if text.hasPrefix("<![CDATA[") {
            text = text.replacingOccurrences(of: "<![CDATA[", with: "")
            text = text.replacingOccurrences(of: "]]>", with: "")
        }
        // Убираем HTML-теги (включая перенос строки на месте <br>/<p> и т.п.,
        // чтобы слова из соседних тегов не склеивались друг с другом без пробела)
        if text.contains("<") {
            text = text.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
        }
        text = decodeHTMLEntities(text)
        text = text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Полноценно декодирует HTML-сущности (именованные и числовые/шестнадцатеричные),
    /// иначе в тексте остаются "битые" фрагменты вроде "&mdash;", "&hellip;", "&#8217;".
    private func decodeHTMLEntities(_ input: String) -> String {
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

    private func parseDate(_ raw: String) -> Date? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        for formatter in Self.dateFormatters {
            if let date = formatter.date(from: trimmed) {
                return date
            }
        }
        return nil
    }
}
