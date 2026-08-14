import Foundation

// MARK: - Категории новостей

enum NewsCategory: String, CaseIterable, Identifiable, Codable, Hashable {
    case politics = "Политика"
    case sports = "Спорт"
    case economy = "Экономика"
    case technology = "Технологии"
    case science = "Наука"
    case culture = "Культура"
    case incidents = "Происшествия"
    case society = "Общество"

    var id: String { rawValue }

    /// Локализованное имя категории для интерфейса. `rawValue` при этом
    /// остаётся стабильным (на русском) — он используется как ключ
    /// в JSON-кэше и при персистентности, поэтому не завязан на язык.
    func localizedName(_ language: AppLanguage) -> String {
        switch self {
        case .politics: return L10n.t("category.politics", language)
        case .sports: return L10n.t("category.sports", language)
        case .economy: return L10n.t("category.economy", language)
        case .technology: return L10n.t("category.technology", language)
        case .science: return L10n.t("category.science", language)
        case .culture: return L10n.t("category.culture", language)
        case .incidents: return L10n.t("category.incidents", language)
        case .society: return L10n.t("category.society", language)
        }
    }

    var symbolName: String {
        switch self {
        case .politics: return "building.columns.fill"
        case .sports: return "sportscourt.fill"
        case .economy: return "chart.line.uptrend.xyaxis"
        case .technology: return "cpu.fill"
        case .science: return "atom"
        case .culture: return "theatermasks.fill"
        case .incidents: return "exclamationmark.triangle.fill"
        case .society: return "person.3.fill"
        }
    }

    /// Ключевые слова для эвристической классификации новости по её заголовку и описанию.
    /// Однословные ключи проверяются как ЦЕЛОЕ слово (см. NewsCategorizer), а не как
    /// подстрока — иначе, например, "банк" ложно срабатывал внутри "банкет".
    /// Фразы из нескольких слов (например, "лига чемпионов") — более редкий и надёжный
    /// сигнал темы, чем одно общее слово, поэтому такие совпадения весят больше
    /// (см. вес в NewsCategorizer.categorize). Списки включают русские, английские
    /// и немецкие термины, так как источники в приложении на трёх языках.
    var keywords: [String] {
        switch self {
        case .politics:
            return [
                "президент", "путин", "госдума", "министр", "выборы", "закон",
                "кремль", "правительство", "сенат", "парламент", "оон", "нато",
                "санкции", "дипломат", "переговоры", "губернатор", "депутат", "указ",
                "referendum", "референдум", "чиновник", "кабмин", "мид", "минобороны",
                "государственная дума", "совет безопасности", "совет федерации",
                "лига наций", "лига арабских государств", "белый дом", "евросоюз",
                "president", "kremlin", "parliament", "sanctions", "diplomat", "nato",
                "election", "elections", "congress", "senate", "governor", "white house",
                "foreign ministry", "state department", "european union", "prime minister",
                "bundestag", "bundeskanzler", "kanzler", "bundesregierung", "wahl", "minister"
            ]
        case .sports:
            return [
                "футбол", "хоккей", "баскетбол", "теннис", "волейбол", "матч",
                "чемпионат", "олимпиада", "сборная", "спортсмен", "гол", "тренер",
                "турнир", "медаль", "фифа", "уефа", "чемпионат мира по футболу",
                "олимпийские игры", "кубок мира", "лига чемпионов", "футбольная лига",
                "чемпионат россии по футболу", "football", "soccer", "hockey",
                "basketball", "tennis", "goal", "referee", "athlete", "olympics",
                "world cup", "champions league", "premier league", "medal", "coach",
                "fußball", "bundesliga", "olympiade", "meisterschaft", "turnier"
            ]
        case .economy:
            return [
                "рубль", "доллар", "евро", "инфляция", "банк", "ввп", "нефть",
                "биржа", "акции", "экономика", "бюджет", "налог", "цена", "рынок",
                "инвестиции", "курс валют", "центральный банк", "мировая экономика",
                "цена на нефть", "федеральная резервная система", "economy", "inflation",
                "stock market", "gdp", "dollar", "euro", "central bank", "stock exchange",
                "oil price", "investment", "recession", "wirtschaft", "inflation",
                "aktien", "zentralbank", "rezession", "bruttoinlandsprodukt"
            ]
        case .technology:
            return [
                "технологии", "смартфон", "нейросеть", "стартап", "гаджет", "робот",
                "процессор", "мобильное приложение", "искусственный интеллект",
                "software", "hardware", "apple", "google", "microsoft", "tesla",
                "spacex", "стартапы", "спутник", "ракета", "technology", "startup",
                "gadget", "processor", "chip", "artificial intelligence", "app store",
                "technologie", "digitalisierung", "künstliche intelligenz", "raumfahrt"
            ]
        case .science:
            return [
                "учёный", "исследование", "открытие", "университет", "медицина",
                "вакцина", "генетика", "археолог", "nasa", "роскосмос", "scientist",
                "research", "study", "university", "vaccine", "genetics", "archaeology",
                "discovery", "wissenschaft", "forschung", "studie", "universität",
                "impfstoff", "genetik"
            ]
        case .culture:
            return [
                "фильм", "кино", "музыка", "театр", "выставка", "концерт", "актёр",
                "режиссёр", "книга", "фестиваль", "музей", "премьера", "film",
                "cinema", "music", "concert", "actor", "director", "museum",
                "festival", "premiere", "kultur", "musik", "theater", "ausstellung"
            ]
        case .incidents:
            return [
                "пожар", "авария", "дтп", "взрыв", "погиб", "убийство", "происшествие",
                "чп", "эвакуация", "разыскивают", "задержан", "уголовное дело", "суд",
                "землетрясение", "наводнение", "fire", "explosion", "earthquake",
                "flood", "crash", "killed", "arrested", "accident", "unfall", "brand",
                "erdbeben", "explosion"
            ]
        case .society:
            return []
        }
    }
}

// MARK: - Источник новостей (RSS)

struct NewsSource: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let feedURL: URL
}

// Полные списки источников по регионам определены в Region.swift
// (NewsSource.sources(for:)) — набор зависит от того, какой регион
// выбрал пользователь при первом запуске.

// MARK: - Новость

struct NewsItem: Identifiable, Hashable, Codable {
    let id: UUID
    let title: String
    let rawDescription: String
    let link: URL?
    let pubDate: Date?
    let sourceName: String
    var category: NewsCategory = .society
    var summary: String = ""

    init(id: UUID = UUID(), title: String, rawDescription: String, link: URL?,
         pubDate: Date?, sourceName: String, category: NewsCategory = .society, summary: String = "") {
        self.id = id
        self.title = title
        self.rawDescription = rawDescription
        self.link = link
        self.pubDate = pubDate
        self.sourceName = sourceName
        self.category = category
        self.summary = summary
    }

    /// Стабильный идентификатор, не меняющийся между обновлениями ленты —
    /// используется для избранного и отметок "прочитано".
    var stableID: String {
        "\(sourceName)|\(title)".data(using: .utf8)?.base64EncodedString() ?? "\(sourceName)|\(title)"
    }

    /// Примерное время чтения полного описания (по 200 слов/мин).
    var readingTimeMinutes: Int {
        let words = rawDescription.split(separator: " ").count
        return max(1, Int((Double(words) / 200.0).rounded(.up)))
    }

    static func == (lhs: NewsItem, rhs: NewsItem) -> Bool {
        lhs.title == rhs.title && lhs.sourceName == rhs.sourceName
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(sourceName)
    }
}
