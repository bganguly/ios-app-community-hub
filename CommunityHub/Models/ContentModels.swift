import Foundation

enum ContentType: String, CaseIterable, Identifiable {
    case video = "Video"
    case article = "Article"

    var id: String { rawValue }

    var titlePlural: String {
        switch self {
        case .video:
            return "Videos"
        case .article:
            return "Articles"
        }
    }
}

enum AudienceFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case student = "Student"
    case parent = "Parent"
    case educator = "Educator"

    var id: String { rawValue }
}

enum Audience: String, Codable {
    case student = "Student"
    case parent = "Parent"
    case educator = "Educator"
}

enum ContentCategory: String, Codable {
    case sat = "SAT"
    case ap = "AP"
    case collegePlanning = "College Planning"
    case financialAid = "Financial Aid"
}

enum ContentLanguage: String, Codable {
    case english = "English"
    case spanish = "Spanish"
}

struct ContentItem: Identifiable, Equatable {
    let id: String
    let title: String
    let description: String
    let audience: Audience
    let category: ContentCategory
    let requiresLogin: Bool
    let language: ContentLanguage?
    let kind: Kind

    enum Kind: Equatable {
        case video(duration: String, thumbnailURL: URL?, thumbnailFallbackURL: URL?)
        case article(readTime: String)
    }

    var metric: String {
        switch kind {
        case .video(let duration, _, _):
            return duration
        case .article(let readTime):
            return readTime
        }
    }

    var thumbnailURL: URL? {
        switch kind {
        case .video(_, let thumbnailURL, _):
            return thumbnailURL
        case .article:
            return nil
        }
    }

    var thumbnailFallbackURL: URL? {
        switch kind {
        case .video(_, _, let thumbnailFallbackURL):
            return thumbnailFallbackURL
        case .article:
            return nil
        }
    }
}

struct ContentResponse {
    let total: Int
    let items: [ContentItem]
}

struct PaginatedContentQuery {
    let contentType: ContentType
    let search: String
    let audience: AudienceFilter
    let offset: Int
    let limit: Int
}
