import Foundation

/// Язык интерфейса приложения. Не путать с языком самих новостей —
/// тексты статей приходят из RSS-лент как есть (мы не переводим контент,
/// только элементы интерфейса), а этот выбор влияет на кнопки, заголовки,
/// названия категорий и на голос озвучки.
enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case russian = "ru"
    case english = "en"
    case kazakh = "kk"
    case german = "de"

    var id: String { rawValue }

    var flag: String {
        switch self {
        case .russian: return "🇷🇺"
        case .english: return "🇬🇧"
        case .kazakh: return "🇰🇿"
        case .german: return "🇩🇪"
        }
    }

    /// Название языка на нём самом — так его узнают даже те, кто ещё
    /// не понимает нынешний язык интерфейса (важно на экране первого выбора).
    var nativeName: String {
        switch self {
        case .russian: return "Русский"
        case .english: return "English"
        case .kazakh: return "Қазақша"
        case .german: return "Deutsch"
        }
    }

    /// Код локали для системного синтеза речи (AVSpeechSynthesisVoice).
    /// На устройствах Apple нет системного голоса для казахского — в этом
    /// случае SpeechReader сам подбирает ближайший доступный голос.
    var speechLanguageCode: String {
        switch self {
        case .russian: return "ru-RU"
        case .english: return "en-US"
        case .kazakh: return "kk-KZ"
        case .german: return "de-DE"
        }
    }
}

/// Простая офлайн-локализация: таблица строк "ключ → перевод на 4 языка".
/// Сделана вручную (не через .xcstrings/Localizable.strings), чтобы язык
/// интерфейса можно было переключать мгновенно, из настроек, без перезапуска
/// приложения и без зависимости от системной локали устройства.
enum L10n {
    static func t(_ key: String, _ language: AppLanguage) -> String {
        table[key]?[language] ?? table[key]?[.russian] ?? key
    }

    /// Версия с подстановкой значений вместо %@ / %d (см. String(format:)).
    /// Отдельное имя от `t(_:_:)` — чтобы не зависеть от разрешения
    /// перегрузок Swift между обычным и variadic-параметром при вызове
    /// без дополнительных аргументов.
    static func tf(_ key: String, _ language: AppLanguage, _ args: CVarArg...) -> String {
        String(format: t(key, language), arguments: args)
    }

    private static let table: [String: [AppLanguage: String]] = [
        // MARK: Вкладки
        "tab.feed": [.russian: "Лента", .english: "Feed", .kazakh: "Таспа", .german: "Feed"],
        "tab.search": [.russian: "Поиск", .english: "Search", .kazakh: "Іздеу", .german: "Suche"],
        "tab.bookmarks": [.russian: "Избранное", .english: "Bookmarks", .kazakh: "Таңдаулылар", .german: "Lesezeichen"],
        "tab.stats": [.russian: "Статистика", .english: "Stats", .kazakh: "Статистика", .german: "Statistik"],
        "tab.settings": [.russian: "Настройки", .english: "Settings", .kazakh: "Баптаулар", .german: "Einstellungen"],

        // MARK: Главная лента
        "content.mainNow": [.russian: "Главное сейчас", .english: "Top story now", .kazakh: "Қазіргі басты жаңалық", .german: "Aktuell wichtig"],
        "content.sourcesUnavailable": [.russian: "Некоторые источники недоступны", .english: "Some sources are unavailable", .kazakh: "Кейбір көздер қолжетімсіз", .german: "Einige Quellen sind nicht verfügbar"],
        "content.categories": [.russian: "Категории", .english: "Categories", .kazakh: "Санаттар", .german: "Kategorien"],
        "content.updatedAt": [.russian: "Обновлено: %@", .english: "Updated: %@", .kazakh: "Жаңартылды: %@", .german: "Aktualisiert: %@"],
        "content.loading": [.russian: "Собираем новости…", .english: "Gathering news…", .kazakh: "Жаңалықтар жиналуда…", .german: "Nachrichten werden geladen…"],
        "content.noData.title": [.russian: "Нет данных", .english: "No data", .kazakh: "Деректер жоқ", .german: "Keine Daten"],
        "content.noData.description": [.russian: "Потяните вниз, чтобы загрузить новости из %d источников", .english: "Pull down to load news from %d sources", .kazakh: "%d көзден жаңалық жүктеу үшін төмен тартыңыз", .german: "Nach unten ziehen, um Nachrichten aus %d Quellen zu laden"],
        "content.readingTime": [.russian: "%d мин чтения", .english: "%d min read", .kazakh: "%d мин оқу", .german: "%d Min. Lesezeit"],
        "content.newsCount": [.russian: "%d новостей", .english: "%d news", .kazakh: "%d жаңалық", .german: "%d Nachrichten"],

        // MARK: Категория / детали новости
        "category.digest": [.russian: "Краткая сводка", .english: "Summary", .kazakh: "Қысқаша шолу", .german: "Kurzübersicht"],
        "category.sortPicker": [.russian: "Сортировка", .english: "Sort by", .kazakh: "Сұрыптау", .german: "Sortierung"],
        "category.allNews": [.russian: "Все новости (%d)", .english: "All news (%d)", .kazakh: "Барлық жаңалықтар (%d)", .german: "Alle Nachrichten (%d)"],
        "swipe.addBookmark": [.russian: "В избранное", .english: "Add bookmark", .kazakh: "Таңдаулыларға", .german: "Merken"],
        "swipe.removeBookmark": [.russian: "Убрать", .english: "Remove", .kazakh: "Алып тастау", .german: "Entfernen"],
        "newsRow.readingTimeShort": [.russian: "%d мин", .english: "%d min", .kazakh: "%d мин", .german: "%d Min."],
        "detail.summary": [.russian: "Краткое содержание", .english: "Summary", .kazakh: "Қысқаша мазмұны", .german: "Zusammenfassung"],
        "detail.listen": [.russian: "Прослушать", .english: "Listen", .kazakh: "Тыңдау", .german: "Anhören"],
        "detail.stop": [.russian: "Стоп", .english: "Stop", .kazakh: "Тоқтату", .german: "Stopp"],
        "detail.fullDescription": [.russian: "Полное описание из источника", .english: "Full description from source", .kazakh: "Көздегі толық сипаттама", .german: "Vollständige Beschreibung der Quelle"],
        "detail.bookmarked": [.russian: "В избранном", .english: "Bookmarked", .kazakh: "Таңдаулыда", .german: "Gemerkt"],
        "detail.bookmark": [.russian: "В избранное", .english: "Bookmark", .kazakh: "Таңдаулыларға", .german: "Merken"],
        "detail.share": [.russian: "Поделиться", .english: "Share", .kazakh: "Бөлісу", .german: "Teilen"],
        "detail.openSource": [.russian: "Открыть источник", .english: "Open source", .kazakh: "Көзді ашу", .german: "Quelle öffnen"],
        "detail.loadingFull": [.russian: "Загружаем полный текст статьи…", .english: "Loading the full article…", .kazakh: "Мақаланың толық мәтіні жүктелуде…", .german: "Vollständiger Artikel wird geladen…"],
        "detail.expandedFromArticle": [.russian: "Расширено из полного текста статьи", .english: "Expanded from the full article", .kazakh: "Мақаланың толық мәтінінен кеңейтілді", .german: "Aus dem vollständigen Artikel erweitert"],
        "summary.unavailable": [.russian: "Краткое содержание недоступно", .english: "Summary unavailable", .kazakh: "Қысқаша мазмұны қолжетімсіз", .german: "Zusammenfassung nicht verfügbar"],

        // MARK: Сортировка
        "sort.newest": [.russian: "Сначала новые", .english: "Newest first", .kazakh: "Алдымен жаңалары", .german: "Neueste zuerst"],
        "sort.source": [.russian: "По источнику", .english: "By source", .kazakh: "Көзі бойынша", .german: "Nach Quelle"],
        "sort.readingTime": [.russian: "По времени чтения", .english: "By reading time", .kazakh: "Оқу уақыты бойынша", .german: "Nach Lesezeit"],

        // MARK: Категории новостей
        "category.politics": [.russian: "Политика", .english: "Politics", .kazakh: "Саясат", .german: "Politik"],
        "category.sports": [.russian: "Спорт", .english: "Sports", .kazakh: "Спорт", .german: "Sport"],
        "category.economy": [.russian: "Экономика", .english: "Economy", .kazakh: "Экономика", .german: "Wirtschaft"],
        "category.technology": [.russian: "Технологии", .english: "Technology", .kazakh: "Технологиялар", .german: "Technologie"],
        "category.science": [.russian: "Наука", .english: "Science", .kazakh: "Ғылым", .german: "Wissenschaft"],
        "category.culture": [.russian: "Культура", .english: "Culture", .kazakh: "Мәдениет", .german: "Kultur"],
        "category.incidents": [.russian: "Происшествия", .english: "Incidents", .kazakh: "Оқиғалар", .german: "Vorfälle"],
        "category.society": [.russian: "Общество", .english: "Society", .kazakh: "Қоғам", .german: "Gesellschaft"],

        // MARK: Поиск
        "search.emptyTitle": [.russian: "Поиск по новостям", .english: "Search the news", .kazakh: "Жаңалықтардан іздеу", .german: "Nachrichten durchsuchen"],
        "search.emptyDescription": [.russian: "Введите слово из заголовка или описания", .english: "Type a word from a headline or description", .kazakh: "Тақырып немесе сипаттамадан сөз енгізіңіз", .german: "Geben Sie ein Wort aus Titel oder Beschreibung ein"],
        "search.prompt": [.russian: "Например: футбол, санкции, ИИ", .english: "E.g. football, sanctions, AI", .kazakh: "Мысалы: футбол, санкциялар, ЖИ", .german: "Z. B. Fußball, Sanktionen, KI"],

        // MARK: Избранное
        "bookmarks.emptyTitle": [.russian: "Пока пусто", .english: "Nothing yet", .kazakh: "Әзірге бос", .german: "Noch leer"],
        "bookmarks.emptyDescription": [.russian: "Смахните новость влево или откройте её, чтобы добавить в избранное", .english: "Swipe a news item left or open it to add a bookmark", .kazakh: "Жаңалықты солға сырғытыңыз немесе таңдаулыға қосу үшін ашыңыз", .german: "Nachricht nach links wischen oder öffnen, um sie zu merken"],

        // MARK: Статистика
        "stats.overview": [.russian: "Обзор", .english: "Overview", .kazakh: "Шолу", .german: "Übersicht"],
        "stats.totalNews": [.russian: "Всего новостей", .english: "Total news", .kazakh: "Барлық жаңалықтар", .german: "Nachrichten gesamt"],
        "stats.read": [.russian: "Прочитано", .english: "Read", .kazakh: "Оқылды", .german: "Gelesen"],
        "stats.sourcesCount": [.russian: "Источников", .english: "Sources", .kazakh: "Көздер", .german: "Quellen"],
        "stats.byCategory": [.russian: "По категориям", .english: "By category", .kazakh: "Санаттар бойынша", .german: "Nach Kategorie"],
        "stats.bySource": [.russian: "По источникам", .english: "By source", .kazakh: "Көздер бойынша", .german: "Nach Quelle"],
        "stats.chartCount": [.russian: "Количество", .english: "Count", .kazakh: "Саны", .german: "Anzahl"],
        "stats.chartCategory": [.russian: "Категория", .english: "Category", .kazakh: "Санат", .german: "Kategorie"],

        // MARK: Настройки
        "settings.region": [.russian: "Регион", .english: "Region", .kazakh: "Аймақ", .german: "Region"],
        "settings.regionFooter": [.russian: "Набор доступных новостных агентств зависит от выбранного региона", .english: "The set of available news agencies depends on the selected region", .kazakh: "Қолжетімді жаңалық агенттіктерінің тізімі таңдалған аймаққа байланысты", .german: "Die verfügbaren Nachrichtenagenturen hängen von der gewählten Region ab"],
        "settings.regionNotSelected": [.russian: "Не выбран", .english: "Not selected", .kazakh: "Таңдалмаған", .german: "Nicht ausgewählt"],
        "settings.autoRefresh": [.russian: "Автообновление", .english: "Auto-refresh", .kazakh: "Автожаңарту", .german: "Automatische Aktualisierung"],
        "settings.interval": [.russian: "Интервал", .english: "Interval", .kazakh: "Аралық", .german: "Intervall"],
        "settings.off": [.russian: "Выключено", .english: "Off", .kazakh: "Өшірулі", .german: "Aus"],
        "settings.minutes5": [.russian: "5 минут", .english: "5 minutes", .kazakh: "5 минут", .german: "5 Minuten"],
        "settings.minutes15": [.russian: "15 минут", .english: "15 minutes", .kazakh: "15 минут", .german: "15 Minuten"],
        "settings.minutes30": [.russian: "30 минут", .english: "30 minutes", .kazakh: "30 минут", .german: "30 Minuten"],
        "settings.hour1": [.russian: "1 час", .english: "1 hour", .kazakh: "1 сағат", .german: "1 Stunde"],
        "settings.fontSize": [.russian: "Размер текста", .english: "Text size", .kazakh: "Мәтін өлшемі", .german: "Textgröße"],
        "settings.scale": [.russian: "Масштаб", .english: "Scale", .kazakh: "Масштаб", .german: "Skalierung"],
        "settings.sampleTitle": [.russian: "Пример заголовка новости", .english: "Sample news headline", .kazakh: "Жаңалық тақырыбының үлгісі", .german: "Beispiel-Schlagzeile"],
        "settings.sourcesHeader": [.russian: "Источники (%d)", .english: "Sources (%d)", .kazakh: "Көздер (%d)", .german: "Quellen (%d)"],
        "settings.sourcesFooter": [.russian: "Отключённые источники не будут опрашиваться при обновлении ленты. Значок показывает, отвечает ли лента источника прямо сейчас с вашего устройства — так и проверяется доступность в регионе.", .english: "Disabled sources won't be queried when the feed refreshes. The icon shows whether the source responds right now from your device — that's how availability in your region is checked.", .kazakh: "Өшірілген көздер жаңарту кезінде сұралмайды. Белгіше көздің қазір құрылғыдан жауап беретінін көрсетеді — аймақтағы қолжетімділік дәл осылай тексеріледі.", .german: "Deaktivierte Quellen werden beim Aktualisieren nicht abgefragt. Das Symbol zeigt, ob die Quelle gerade von Ihrem Gerät aus antwortet — so wird die Verfügbarkeit in Ihrer Region geprüft."],
        "settings.about": [.russian: "О приложении", .english: "About", .kazakh: "Қолданба туралы", .german: "Über die App"],
        "settings.appName": [.russian: "Название", .english: "Name", .kazakh: "Атауы", .german: "Name"],
        "app.name": [.russian: "ТочкаСводки", .english: "SpotBrief", .kazakh: "ЖеделДерек", .german: "PunktBericht"],
        "settings.newsSourcesCount": [.russian: "Источников новостей", .english: "News sources", .kazakh: "Жаңалық көздері", .german: "Nachrichtenquellen"],
        "settings.aboutFooter": [.russian: "Категории и краткие содержания формируются на устройстве без обращения к внешним ИИ-сервисам.", .english: "Categories and summaries are generated on-device without calling external AI services.", .kazakh: "Санаттар мен қысқаша мазмұндар сыртқы ЖИ қызметтеріне жүгінбей, құрылғының өзінде жасалады.", .german: "Kategorien und Zusammenfassungen werden auf dem Gerät erstellt, ohne externe KI-Dienste zu nutzen."],
        "settings.language": [.russian: "Язык", .english: "Language", .kazakh: "Тіл", .german: "Sprache"],
        "settings.languageFooter": [.russian: "Меняет язык интерфейса приложения", .english: "Changes the app's interface language", .kazakh: "Қолданба интерфейсінің тілін өзгертеді", .german: "Ändert die Sprache der App-Oberfläche"],

        // MARK: Выбор региона / языка (онбординг)
        "region.title": [.russian: "Выберите ваш регион", .english: "Choose your region", .kazakh: "Аймағыңызды таңдаңыз", .german: "Wählen Sie Ihre Region"],
        "region.subtitle": [.russian: "От этого зависит, какие новостные агентства будут предложены в приложении", .english: "This determines which news agencies will be offered in the app", .kazakh: "Бұл қолданбада қандай жаңалық агенттіктері ұсынылатынын анықтайды", .german: "Dies bestimmt, welche Nachrichtenagenturen in der App angeboten werden"],
        "region.sourcesCount": [.russian: "%d источников", .english: "%d sources", .kazakh: "%d көз", .german: "%d Quellen"],
        "common.continue": [.russian: "Продолжить", .english: "Continue", .kazakh: "Жалғастыру", .german: "Weiter"],

        "region.russia": [.russian: "Россия", .english: "Russia", .kazakh: "Ресей", .german: "Russland"],
        "region.kazakhstan": [.russian: "Казахстан", .english: "Kazakhstan", .kazakh: "Қазақстан", .german: "Kasachstan"],
        "region.usa": [.russian: "США", .english: "USA", .kazakh: "АҚШ", .german: "USA"],
        "region.uk": [.russian: "Великобритания", .english: "United Kingdom", .kazakh: "Ұлыбритания", .german: "Vereinigtes Königreich"],
        "region.germany": [.russian: "Германия", .english: "Germany", .kazakh: "Германия", .german: "Deutschland"],

        "language.title": [.russian: "Выберите язык приложения", .english: "Choose app language", .kazakh: "Қолданба тілін таңдаңыз", .german: "Wählen Sie die App-Sprache"],
        "language.subtitle": [.russian: "Можно изменить позже в настройках", .english: "You can change it later in Settings", .kazakh: "Кейін баптауларда өзгертуге болады", .german: "Sie können sie später in den Einstellungen ändern"],

        // MARK: Дайджест категории и ошибки источников
        "digest.empty": [.russian: "Новостей в категории «%@» пока нет.", .english: "No news in the “%@” category yet.", .kazakh: "«%@» санатында әзірге жаңалық жоқ.", .german: "In der Kategorie „%@“ gibt es noch keine Neuigkeiten."],
        "error.sourceFailed": [.russian: "%@: не удалось загрузить (%@)", .english: "%@: failed to load (%@)", .kazakh: "%@: жүктелмеді (%@)", .german: "%@: Laden fehlgeschlagen (%@)"],

        // MARK: Свои источники
        "settings.customSources": [.russian: "Свои источники", .english: "Custom sources", .kazakh: "Жеке дереккөздер", .german: "Eigene Quellen"],
        "settings.customSourcesFooter": [.russian: "Добавленные вами RSS-ленты доступны независимо от выбранного региона.", .english: "RSS feeds you add are available regardless of the selected region.", .kazakh: "Сіз қосқан RSS-таспалар таңдалған аймаққа қарамастан қолжетімді.", .german: "Von dir hinzugefügte RSS-Feeds sind unabhängig von der gewählten Region verfügbar."],
        "settings.addSource": [.russian: "Добавить источник", .english: "Add source", .kazakh: "Дереккөз қосу", .german: "Quelle hinzufügen"],
        "settings.noCustomSources": [.russian: "Пока нет ни одного своего источника", .english: "No custom sources yet", .kazakh: "Әзірге жеке дереккөз жоқ", .german: "Noch keine eigenen Quellen"],
        "addSource.title": [.russian: "Новый источник", .english: "New source", .kazakh: "Жаңа дереккөз", .german: "Neue Quelle"],
        "addSource.nameLabel": [.russian: "Название", .english: "Name", .kazakh: "Атауы", .german: "Name"],
        "addSource.namePlaceholder": [.russian: "Например: Мой любимый блог", .english: "E.g. My favorite blog", .kazakh: "Мысалы: Сүйікті блогым", .german: "Z. B. Mein Lieblingsblog"],
        "addSource.urlLabel": [.russian: "Адрес RSS-ленты", .english: "RSS feed address", .kazakh: "RSS-таспа мекенжайы", .german: "RSS-Feed-Adresse"],
        "addSource.urlPlaceholder": [.russian: "example.com/rss.xml", .english: "example.com/rss.xml", .kazakh: "example.com/rss.xml", .german: "example.com/rss.xml"],
        "addSource.add": [.russian: "Добавить", .english: "Add", .kazakh: "Қосу", .german: "Hinzufügen"],
        "addSource.cancel": [.russian: "Отмена", .english: "Cancel", .kazakh: "Бас тарту", .german: "Abbrechen"],
        "addSource.errorEmptyName": [.russian: "Введите название источника", .english: "Enter a name for the source", .kazakh: "Дереккөз атауын енгізіңіз", .german: "Gib einen Namen für die Quelle ein"],
        "addSource.errorInvalidURL": [.russian: "Похоже, это не корректный адрес", .english: "That doesn't look like a valid address", .kazakh: "Бұл дұрыс мекенжай сияқты көрінбейді", .german: "Das sieht nicht nach einer gültigen Adresse aus"],
        "addSource.errorDuplicate": [.russian: "Такой источник уже добавлен", .english: "This source is already added", .kazakh: "Мұндай дереккөз бұрыннан қосылған", .german: "Diese Quelle wurde bereits hinzugefügt"]
    ]
}
