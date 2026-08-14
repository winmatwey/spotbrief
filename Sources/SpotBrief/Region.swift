import Foundation

/// Регион пользователя. Определяет, какие новостные агентства предлагаются
/// в приложении. Выбирается один раз при первом запуске и может быть
/// изменён позже в настройках.
enum Region: String, CaseIterable, Identifiable, Codable {
    case russia
    case kazakhstan
    case usa
    case uk
    case germany

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .russia: return "Россия"
        case .kazakhstan: return "Казахстан"
        case .usa: return "США"
        case .uk: return "Великобритания"
        case .germany: return "Германия"
        }
    }

    /// Локализованное название региона для интерфейса.
    func localizedName(_ language: AppLanguage) -> String {
        switch self {
        case .russia: return L10n.t("region.russia", language)
        case .kazakhstan: return L10n.t("region.kazakhstan", language)
        case .usa: return L10n.t("region.usa", language)
        case .uk: return L10n.t("region.uk", language)
        case .germany: return L10n.t("region.germany", language)
        }
    }

    var flag: String {
        switch self {
        case .russia: return "🇷🇺"
        case .kazakhstan: return "🇰🇿"
        case .usa: return "🇺🇸"
        case .uk: return "🇬🇧"
        case .germany: return "🇩🇪"
        }
    }
}

extension NewsSource {
    /// Список источников для конкретного региона. Адреса собраны по крупным
    /// и общеизвестным агентствам страны; фактическую доступность каждого
    /// конкретного источника с устройства пользователя проверяет
    /// SourceAvailabilityChecker при выборе региона и в настройках —
    /// это и требуемая "проверка доступности в регионе" (если лента
    /// не отвечает с устройства пользователя, значит она недоступна
    /// именно там, где он находится).
    static func sources(for region: Region) -> [NewsSource] {
        switch region {
        case .russia: return russiaSources
        case .kazakhstan: return kazakhstanSources
        case .usa: return usaSources
        case .uk: return ukSources
        case .germany: return germanySources
        }
    }

    private static let russiaSources: [NewsSource] = [
        NewsSource(name: "РИА Новости", feedURL: URL(string: "https://ria.ru/export/rss2/index.xml")!),
        NewsSource(name: "ТАСС", feedURL: URL(string: "https://tass.ru/rss/v2.xml")!),
        NewsSource(name: "Lenta.ru", feedURL: URL(string: "https://lenta.ru/rss/news")!),
        NewsSource(name: "РБК", feedURL: URL(string: "https://rssexport.rbc.ru/rbcnews/news/30/full.rss")!),
        NewsSource(name: "Коммерсантъ", feedURL: URL(string: "https://www.kommersant.ru/RSS/news.xml")!),
        NewsSource(name: "Чемпионат", feedURL: URL(string: "https://www.championat.com/rss/news.xml")!),
        NewsSource(name: "Habr", feedURL: URL(string: "https://habr.com/ru/rss/all/all/")!),
        NewsSource(name: "N+1", feedURL: URL(string: "https://nplus1.ru/rss")!),
        NewsSource(name: "Meduza", feedURL: URL(string: "https://meduza.io/rss2/all")!),
        NewsSource(name: "Вести.ру", feedURL: URL(string: "https://www.vesti.ru/vesti.rss")!),
        NewsSource(name: "Новые Известия", feedURL: URL(string: "https://newizv.ru/rss")!),
        NewsSource(name: "Вечерняя Москва", feedURL: URL(string: "https://vm.ru/rss")!),
        NewsSource(name: "Экономика и жизнь", feedURL: URL(string: "https://www.eg-online.ru/news/news_rss.php?SID=605")!),
        NewsSource(name: "НВО (Независимое военное обозрение)", feedURL: URL(string: "https://nvo.ng.ru/rss/")!),
        NewsSource(name: "Chita.ru", feedURL: URL(string: "https://www.chita.ru/rss-feeds/rss.xml")!),
        NewsSource(name: "Tverlife.ru", feedURL: URL(string: "https://tverlife.ru/feed/")!),
        NewsSource(name: "Province.ru", feedURL: URL(string: "https://www.province.ru/rss/")!),
        NewsSource(name: "АиФ Адыгея", feedURL: URL(string: "https://adigea.aif.ru/rss/googlearticles")!),
        NewsSource(name: "Amic.ru", feedURL: URL(string: "https://feeds.feedburner.com/amic/news")!),
        NewsSource(name: "Nnews.nnov.ru", feedURL: URL(string: "https://nnews.nnov.ru/rss")!)
    ]

    private static let kazakhstanSources: [NewsSource] = [
        NewsSource(name: "Tengrinews (English)", feedURL: URL(string: "http://en.tengrinews.kz/news.rss")!),
        NewsSource(name: "The Astana Times", feedURL: URL(string: "https://astanatimes.com/feed/atom/")!),
        NewsSource(name: "Time.kz", feedURL: URL(string: "https://time.kz/rss")!),
        NewsSource(name: "Lada.kz", feedURL: URL(string: "https://www.lada.kz/rss.xml")!),
        NewsSource(name: "eKaraganda.kz", feedURL: URL(string: "https://ekaraganda.kz/rss.php")!),
        NewsSource(name: "Ng.kz", feedURL: URL(string: "https://www.ng.kz/modules/newspaper/cache/newspaper.xml")!),
        NewsSource(name: "Liter.kz", feedURL: URL(string: "https://liter.kz/feed/")!),
        NewsSource(name: "Zakon.kz", feedURL: URL(string: "https://www.zakon.kz/rss/")!),
        NewsSource(name: "Caravan.kz", feedURL: URL(string: "https://www.caravan.kz/rss/")!),
        NewsSource(name: "Kursiv Media", feedURL: URL(string: "https://kz.kursiv.media/feed/")!),
        NewsSource(name: "Informburo.kz", feedURL: URL(string: "https://informburo.kz/rss.xml")!),
        NewsSource(name: "Kazpravda.kz", feedURL: URL(string: "https://kazpravda.kz/rss")!)
    ]

    private static let usaSources: [NewsSource] = [
        NewsSource(name: "NBC News", feedURL: URL(string: "https://feeds.nbcnews.com/nbcnews/public/news")!),
        NewsSource(name: "CBS News", feedURL: URL(string: "https://www.cbsnews.com/feeds/rss/main.rss")!),
        NewsSource(name: "PBS NewsHour", feedURL: URL(string: "https://www.pbs.org/newshour/feeds/rss/headlines")!),
        NewsSource(name: "UPI — U.S. News", feedURL: URL(string: "https://rss.upi.com/news/tn_us.rss")!),
        NewsSource(name: "The New York Times", feedURL: URL(string: "https://rss.nytimes.com/services/xml/rss/nyt/HomePage.xml")!),
        NewsSource(name: "WSJ — U.S. News", feedURL: URL(string: "https://feeds.content.dowjones.io/public/rss/RSSUSnews")!),
        NewsSource(name: "Los Angeles Times", feedURL: URL(string: "https://www.latimes.com/local/rss2.0.xml")!),
        NewsSource(name: "New York Post", feedURL: URL(string: "https://nypost.com/feed/")!),
        NewsSource(name: "The Washington Times", feedURL: URL(string: "https://www.washingtontimes.com/rss/headlines/news")!),
        NewsSource(name: "Vox", feedURL: URL(string: "https://www.vox.com/rss/index.xml")!),
        NewsSource(name: "Business Insider", feedURL: URL(string: "https://feeds.businessinsider.com/custom/all")!),
        NewsSource(name: "POLITICO", feedURL: URL(string: "https://www.politico.com/rss/politicopicks.xml")!),
        NewsSource(name: "Fox Business", feedURL: URL(string: "https://moxie.foxbusiness.com/google-publisher/latest.xml")!),
        NewsSource(name: "Newsweek", feedURL: URL(string: "https://www.newsweek.com/rss")!),
        NewsSource(name: "The Atlantic", feedURL: URL(string: "https://www.theatlantic.com/feed/all/")!),
        NewsSource(name: "The New Yorker", feedURL: URL(string: "https://www.newyorker.com/feed/rss")!),
        NewsSource(name: "NPR", feedURL: URL(string: "https://www.npr.org/rss/rss.php?id=1001")!),
        NewsSource(name: "ProPublica", feedURL: URL(string: "https://www.propublica.org/feeds/propublica/main")!),
        NewsSource(name: "Mother Jones", feedURL: URL(string: "https://www.motherjones.com/feed/")!),
        NewsSource(name: "The Hill", feedURL: URL(string: "https://thehill.com/feed/")!),
        NewsSource(name: "Salon", feedURL: URL(string: "https://www.salon.com/feed")!),
        NewsSource(name: "RealClearPolitics", feedURL: URL(string: "https://www.realclearpolitics.com/index.xml")!),
        NewsSource(name: "The Daily Wire", feedURL: URL(string: "https://www.dailywire.com/feeds/rss.xml")!),
        NewsSource(name: "Breitbart", feedURL: URL(string: "https://feeds.feedburner.com/breitbart")!),
        NewsSource(name: "Observer", feedURL: URL(string: "https://observer.com/feed/")!)
    ]

    private static let ukSources: [NewsSource] = [
        NewsSource(name: "BBC News", feedURL: URL(string: "https://feeds.bbci.co.uk/news/rss.xml")!),
        NewsSource(name: "BBC — UK", feedURL: URL(string: "https://feeds.bbci.co.uk/news/uk/rss.xml")!),
        NewsSource(name: "BBC — World", feedURL: URL(string: "https://feeds.bbci.co.uk/news/world/rss.xml")!),
        NewsSource(name: "BBC — Business", feedURL: URL(string: "https://feeds.bbci.co.uk/news/business/rss.xml")!),
        NewsSource(name: "BBC — Technology", feedURL: URL(string: "https://feeds.bbci.co.uk/news/technology/rss.xml")!),
        NewsSource(name: "Sky News", feedURL: URL(string: "https://feeds.skynews.com/feeds/rss/home.xml")!),
        NewsSource(name: "The Guardian — UK", feedURL: URL(string: "https://www.theguardian.com/uk/rss")!),
        NewsSource(name: "The Guardian — World", feedURL: URL(string: "https://www.theguardian.com/world/rss")!),
        NewsSource(name: "The Telegraph", feedURL: URL(string: "https://www.telegraph.co.uk/rss.xml")!),
        NewsSource(name: "The Independent", feedURL: URL(string: "https://www.independent.co.uk/news/uk/rss")!),
        NewsSource(name: "Evening Standard", feedURL: URL(string: "https://www.standard.co.uk/news/rss")!),
        NewsSource(name: "HuffPost UK", feedURL: URL(string: "https://www.huffingtonpost.co.uk/feeds/index.xml")!)
    ]

    private static let germanySources: [NewsSource] = [
        NewsSource(name: "Der Spiegel — Politik", feedURL: URL(string: "https://www.spiegel.de/politik/index.rss")!),
        NewsSource(name: "Die Zeit", feedURL: URL(string: "https://newsfeed.zeit.de/index")!),
        NewsSource(name: "Die Zeit — Politik", feedURL: URL(string: "https://newsfeed.zeit.de/politik/index")!),
        NewsSource(name: "tagesschau", feedURL: URL(string: "https://www.tagesschau.de/index~rss2.xml")!),
        NewsSource(name: "Bundesregierung (офиц.)", feedURL: URL(string: "https://www.bundesregierung.de/SiteGlobals/Functions/RSSFeed/DE/RSSNewsfeed/RSS_Breg_aktuell/RSSNewsfeed.xml")!),
        NewsSource(name: "FAZ", feedURL: URL(string: "https://www.faz.net/rss/aktuell/")!),
        NewsSource(name: "Handelsblatt", feedURL: URL(string: "https://www.handelsblatt.com/contentexport/feed/schlagzeilen")!),
        NewsSource(name: "Süddeutsche Zeitung", feedURL: URL(string: "https://rss.sueddeutsche.de/rss/Topthemen")!),
        NewsSource(name: "Focus Online", feedURL: URL(string: "https://rss.focus.de/fol/XML/rss_folnews.xml")!),
        NewsSource(name: "WELT", feedURL: URL(string: "https://www.welt.de/feeds/latest.rss")!),
        NewsSource(name: "Heise Online", feedURL: URL(string: "https://www.heise.de/rss/heise-atom.xml")!),
        NewsSource(name: "Netzpolitik.org", feedURL: URL(string: "https://netzpolitik.org/feed/")!)
    ]
}
