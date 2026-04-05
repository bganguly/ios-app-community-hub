import Foundation

protocol CommunityContentProviding {
    func fetchCommunityContentPage(query: PaginatedContentQuery) async throws -> ContentResponse
}

final class CommunityAPIClient: CommunityContentProviding {
    private let session: URLSession
    private let jsonAPIBase = "https://bigfuture.collegeboard.org/jsonapi/"
    private let limitedPreviewAccessLevel = "546c2dcd-379c-4cb6-8259-8b640b5f3fe0"

    private var audienceLookupTask: Task<[String: String], Error>?
    private var topicLookupTask: Task<[String: String], Error>?

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchCommunityContentPage(query: PaginatedContentQuery) async throws -> ContentResponse {
        let livePage: ContentResponse

        switch query.contentType {
        case .video:
            livePage = await fetchVideosPage(offset: query.offset, limit: query.limit)
        case .article:
            livePage = await fetchArticlesPage(offset: query.offset, limit: query.limit)
        }

        let filtered = filter(items: livePage.items, search: query.search, audience: query.audience)
        return ContentResponse(total: livePage.total, items: filtered)
    }

    private func fetchVideosPage(offset: Int, limit: Int) async -> ContentResponse {
        do {
            let videoPayload: JsonApiCollection<JsonApiVideo> = try await fetchJSONWithRetry(
                from: "\(jsonAPIBase)resource/video?page[limit]=\(limit)&page[offset]=\(offset)&jsonapi_include=1&filter[status]=1&sort=-created"
            )
            let audienceMap = (try? await getAudienceLookup()) ?? [:]
            let topicMap = (try? await getTopicLookup()) ?? [:]
            let items = videoPayload.data.map {
                mapVideo(item: $0, audienceMap: audienceMap, topicMap: topicMap)
            }

            if items.isEmpty {
                return fallbackPage(for: .video, offset: offset, limit: limit)
            }

            return ContentResponse(
                total: resolvedTotalCount(
                    apiCount: videoPayload.meta?.count,
                    offset: offset,
                    pageItemCount: items.count,
                    pageLimit: limit
                ),
                items: items
            )
        } catch {
            return fallbackPage(for: .video, offset: offset, limit: limit)
        }
    }

    private func fetchArticlesPage(offset: Int, limit: Int) async -> ContentResponse {
        do {
            let articlePayload: JsonApiCollection<JsonApiArticle> = try await fetchJSONWithRetry(
                from: "\(jsonAPIBase)node/info_article?page[limit]=\(limit)&page[offset]=\(offset)&jsonapi_include=1&filter[status]=1&sort=-created"
            )
            let audienceMap = (try? await getAudienceLookup()) ?? [:]
            let topicMap = (try? await getTopicLookup()) ?? [:]
            let items = articlePayload.data.map {
                mapArticle(item: $0, audienceMap: audienceMap, topicMap: topicMap)
            }

            if items.isEmpty {
                return fallbackPage(for: .article, offset: offset, limit: limit)
            }

            return ContentResponse(
                total: resolvedTotalCount(
                    apiCount: articlePayload.meta?.count,
                    offset: offset,
                    pageItemCount: items.count,
                    pageLimit: limit
                ),
                items: items
            )
        } catch {
            return fallbackPage(for: .article, offset: offset, limit: limit)
        }
    }

    private func resolvedTotalCount(apiCount: Int?, offset: Int, pageItemCount: Int, pageLimit: Int) -> Int {
        if let apiCount {
            return apiCount
        }

        // If the API omits total count and we received a full page, keep pagination open.
        if pageItemCount == pageLimit {
            return offset + pageItemCount + 1
        }

        return offset + pageItemCount
    }

    private func fallbackPage(for type: ContentType, offset: Int, limit: Int) -> ContentResponse {
        let source = type == .video ? CommunityFallbackData.videos : CommunityFallbackData.articles
        let start = min(offset, source.count)
        let end = min(offset + limit, source.count)
        let items = Array(source[start..<end]).map { item in
            ContentItem(
                id: item.id,
                title: item.title,
                description: formatDescriptionForDisplay(item.description),
                audience: item.audience,
                category: item.category,
                requiresLogin: item.requiresLogin,
                language: item.language,
                kind: item.kind
            )
        }

        return ContentResponse(total: source.count, items: items)
    }

    private func filter(items: [ContentItem], search: String, audience: AudienceFilter) -> [ContentItem] {
        let normalized = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return items.filter { item in
            let matchesSearch = normalized.isEmpty ||
                item.title.lowercased().contains(normalized) ||
                item.description.lowercased().contains(normalized)

            let matchesAudience = audience == .all || item.audience.rawValue == audience.rawValue
            return matchesSearch && matchesAudience
        }
    }

    private func mapVideo(item: JsonApiVideo, audienceMap: [String: String], topicMap: [String: String]) -> ContentItem {
        let audienceName = audienceMap[item.fieldAudience?.first?.id ?? ""] ?? "Educators"
        let topicName = topicMap[item.fieldCommunityTopics?.first?.id ?? ""] ?? ""
        let description = formatDescriptionForDisplay(item.fieldExternalDescription)
        let duration = item.fieldVideoDuration?.trimmingCharacters(in: .whitespacesAndNewlines)

        return ContentItem(
            id: item.id,
            title: item.title,
            description: description,
            audience: normalizeAudience(audienceName),
            category: inferCategory(from: topicName, title: item.title),
            requiresLogin: item.fieldAccessLevel?.id == limitedPreviewAccessLevel,
            language: normalizeLanguage(item.langcode),
            kind: .video(
                duration: duration.flatMap { $0.isEmpty ? nil : $0 } ?? "0:00",
                thumbnailURL: getVideoThumbnailURL(item),
                thumbnailFallbackURL: getYoutubeThumbnailFallback(item.fieldVideoLink)
            )
        )
    }

    private func mapArticle(item: JsonApiArticle, audienceMap: [String: String], topicMap: [String: String]) -> ContentItem {
        let audienceName = audienceMap[item.fieldAudience?.first?.id ?? ""] ?? "Educators"
        let topicName = topicMap[item.fieldCommunityTopics?.first?.id ?? ""] ?? ""
        let description = formatDescriptionForDisplay(
            item.fieldExternalDescription ?? item.fieldPreviewSummary ?? item.body?.summary ?? item.body?.value
        )

        return ContentItem(
            id: item.id,
            title: item.title,
            description: description,
            audience: normalizeAudience(audienceName),
            category: inferCategory(from: topicName, title: item.title),
            requiresLogin: item.fieldAccessLevel?.id == limitedPreviewAccessLevel,
            language: normalizeLanguage(item.langcode),
            kind: .article(readTime: "5 min read")
        )
    }

    private func normalizeAudience(_ value: String) -> Audience {
        let normalized = value.lowercased()
        if normalized.contains("parent") { return .parent }
        if normalized.contains("student") { return .student }
        return .educator
    }

    private func normalizeLanguage(_ langCode: String?) -> ContentLanguage {
        guard let langCode else { return .english }
        return langCode.lowercased().hasPrefix("es") ? .spanish : .english
    }

    private func inferCategory(from topicName: String, title: String) -> ContentCategory {
        let source = "\(topicName) \(title)".lowercased()
        if source.contains("sat") || source.contains("psat") {
            return .sat
        }

        if source.contains("ap ") || source.contains("advanced placement") {
            return .ap
        }

        if source.contains("aid") || source.contains("scholarship") || source.contains("cost") {
            return .financialAid
        }

        return .collegePlanning
    }

    private func formatDescriptionForDisplay(_ raw: String?) -> String {
        shorten(stripHTML(raw), max: 220)
    }

    private func stripHTML(_ raw: String?) -> String {
        guard let raw, !raw.isEmpty else {
            return ""
        }

        let withoutTags = raw.replacingOccurrences(
            of: "<[^>]*>",
            with: " ",
            options: .regularExpression
        )

        let withoutNbsp = withoutTags.replacingOccurrences(of: "&nbsp;", with: " ")
        return withoutNbsp.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func shorten(_ text: String, max: Int) -> String {
        guard text.count > max else {
            return text
        }

        let index = text.index(text.startIndex, offsetBy: max - 1)
        return text[text.startIndex..<index].trimmingCharacters(in: .whitespacesAndNewlines) + "..."
    }

    private func toAbsoluteMediaURL(_ path: String?) -> URL? {
        guard let path, !path.isEmpty else {
            return nil
        }

        if path.hasPrefix("http://") || path.hasPrefix("https://") {
            return URL(string: path)
        }

        if path.hasPrefix("/") {
            return URL(string: "https://bigfuture.collegeboard.org\(path)")
        }

        return nil
    }

    private func getYoutubeVideoID(_ link: String?) -> String? {
        guard let normalizedLink = link?.trimmingCharacters(in: .whitespacesAndNewlines), !normalizedLink.isEmpty else {
            return nil
        }

        let pattern = #"(?:youtu\.be/|youtube\.com/(?:watch\?v=|embed/|shorts/))([A-Za-z0-9_-]{6,})"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }

        let range = NSRange(normalizedLink.startIndex..<normalizedLink.endIndex, in: normalizedLink)
        guard let match = regex.firstMatch(in: normalizedLink, options: [], range: range),
              let idRange = Range(match.range(at: 1), in: normalizedLink) else {
            return nil
        }

        return String(normalizedLink[idRange])
    }

    private func getYoutubeThumbnail(_ link: String?) -> URL? {
        guard let videoID = getYoutubeVideoID(link) else {
            return nil
        }

        return URL(string: "https://img.youtube.com/vi/\(videoID)/hqdefault.jpg")
    }

    private func getYoutubeThumbnailFallback(_ link: String?) -> URL? {
        guard let videoID = getYoutubeVideoID(link) else {
            return nil
        }

        return URL(string: "https://i.ytimg.com/vi/\(videoID)/hqdefault.jpg")
    }

    private func getVideoThumbnailURL(_ item: JsonApiVideo) -> URL? {
        let mediaImage = toAbsoluteMediaURL(item.fieldThumbnailMedia?.fieldMediaImage?.uri?.url)
        return mediaImage ?? getYoutubeThumbnail(item.fieldVideoLink)
    }

    private func getAudienceLookup() async throws -> [String: String] {
        if let task = audienceLookupTask {
            return try await task.value
        }

        let task = Task<[String: String], Error> {
            let payload: JsonApiCollection<JsonApiTaxonomyItem> = try await fetchJSON(
                from: "\(jsonAPIBase)taxonomy_term/audience?fields[taxonomy_term--audience]=name&jsonapi_include=1"
            )
            return Dictionary(uniqueKeysWithValues: payload.data.map { ($0.id, $0.name ?? "") })
        }

        audienceLookupTask = task

        do {
            return try await task.value
        } catch {
            audienceLookupTask = nil
            throw error
        }
    }

    private func getTopicLookup() async throws -> [String: String] {
        if let task = topicLookupTask {
            return try await task.value
        }

        let task = Task<[String: String], Error> {
            let payload: JsonApiCollection<JsonApiTaxonomyItem> = try await fetchJSON(
                from: "\(jsonAPIBase)taxonomy_term/bigfuture_community_topics?fields[taxonomy_term--bigfuture_community_topics]=name,parent&jsonapi_include=1&page[limit]=200"
            )
            return Dictionary(uniqueKeysWithValues: payload.data.map { ($0.id, $0.name ?? "") })
        }

        topicLookupTask = task

        do {
            return try await task.value
        } catch {
            topicLookupTask = nil
            throw error
        }
    }

    private func fetchJSON<T: Decodable>(from urlString: String) async throws -> T {
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpStatus(httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(T.self, from: data)
    }

    private func fetchJSONWithRetry<T: Decodable>(from urlString: String) async throws -> T {
        do {
            return try await fetchJSON(from: urlString)
        } catch {
            // A short retry smooths over occasional transient API/network failures.
            try? await Task.sleep(nanoseconds: 250_000_000)
            return try await fetchJSON(from: urlString)
        }
    }
}

private extension CommunityAPIClient {
    enum APIError: Error {
        case invalidURL
        case invalidResponse
        case httpStatus(Int)
    }

    struct JsonApiCollection<T: Decodable>: Decodable {
        let data: [T]
        let meta: Meta?

        private enum CodingKeys: String, CodingKey {
            case data
            case meta
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            meta = try container.decodeIfPresent(Meta.self, forKey: .meta)
            let lossyData = try container.decode([LossyDecodable<T>].self, forKey: .data)
            data = lossyData.compactMap { $0.value }
        }

        struct Meta: Decodable {
            let count: Int?
        }
    }

    struct JsonApiRef: Decodable {
        let id: String
        let type: String
    }

    struct LossyDecodable<Value: Decodable>: Decodable {
        let value: Value?

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            value = try? container.decode(Value.self)
        }
    }

    struct JsonApiTaxonomyItem: Decodable {
        let id: String
        let name: String?
    }

    struct JsonApiBody: Decodable {
        let value: String?
        let summary: String?
    }

    struct JsonApiVideo: Decodable {
        let id: String
        let title: String
        let langcode: String?
        let fieldExternalDescription: String?
        let fieldVideoDuration: String?
        let fieldVideoLink: String?
        let fieldAudience: [JsonApiRef]?
        let fieldCommunityTopics: [JsonApiRef]?
        let fieldAccessLevel: JsonApiRef?
        let fieldThumbnailMedia: JsonApiThumbnailMedia?
    }

    struct JsonApiThumbnailMedia: Decodable {
        let data: JsonApiRef?
        let fieldMediaImage: JsonApiMediaImage?
    }

    struct JsonApiMediaImage: Decodable {
        let data: JsonApiRef?
        let uri: JsonApiURI?
    }

    struct JsonApiURI: Decodable {
        let url: String?
    }

    struct JsonApiArticle: Decodable {
        let id: String
        let title: String
        let langcode: String?
        let fieldExternalDescription: String?
        let fieldPreviewSummary: String?
        let body: JsonApiBody?
        let fieldAudience: [JsonApiRef]?
        let fieldCommunityTopics: [JsonApiRef]?
        let fieldAccessLevel: JsonApiRef?
    }
}
