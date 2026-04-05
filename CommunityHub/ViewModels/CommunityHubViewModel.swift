import Foundation

@MainActor
final class CommunityHubViewModel: ObservableObject {
    @Published private(set) var items: [ContentItem] = []
    @Published var contentType: ContentType = .video
    @Published var audience: AudienceFilter = .all
    @Published var search: String = ""
    @Published private(set) var isLoadingInitial = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var loadError: String?

    private let pageSize = 9
    private let provider: CommunityContentProviding
    private var offset = 0
    private var totalCount = 0
    private var loadTask: Task<Void, Never>?

    init(provider: CommunityContentProviding = CommunityAPIClient()) {
        self.provider = provider
    }

    var hasMore: Bool {
        offset < totalCount
    }

    deinit {
        loadTask?.cancel()
    }

    func loadInitial() {
        loadTask?.cancel()
        loadTask = Task {
            await performInitialLoad()
        }
    }

    func loadMoreIfNeeded(currentItem item: ContentItem?) {
        guard let item else { return }
        guard hasMore, !isLoadingInitial, !isLoadingMore else { return }
        guard item.id == items.last?.id else { return }

        loadTask = Task {
            await performLoadMore()
        }
    }

    func loadMore() {
        guard hasMore, !isLoadingInitial, !isLoadingMore else { return }

        loadTask = Task {
            await performLoadMore()
        }
    }

    func refreshForChangedFilters() {
        loadInitial()
    }

    private func performInitialLoad() async {
        isLoadingInitial = true
        isLoadingMore = false
        loadError = nil
        offset = 0
        totalCount = 0

        do {
            let response = try await provider.fetchCommunityContentPage(
                query: PaginatedContentQuery(
                    contentType: contentType,
                    search: search,
                    audience: audience,
                    offset: 0,
                    limit: pageSize
                )
            )
            items = response.items
            totalCount = response.total
            offset = pageSize
        } catch {
            items = []
            loadError = "Failed to load content."
        }

        isLoadingInitial = false
    }

    private func performLoadMore() async {
        guard hasMore else { return }

        isLoadingMore = true
        loadError = nil

        do {
            let response = try await provider.fetchCommunityContentPage(
                query: PaginatedContentQuery(
                    contentType: contentType,
                    search: search,
                    audience: audience,
                    offset: offset,
                    limit: pageSize
                )
            )

            // Ignore empty fallback pages that can occur after one successful live page.
            if response.items.isEmpty && response.total <= items.count {
                loadError = "Could not load next page. Tap Load More to retry."
                isLoadingMore = false
                return
            }

            items.append(contentsOf: response.items)
            totalCount = response.total
            offset += pageSize
        } catch {
            loadError = "Failed to load more content."
        }

        isLoadingMore = false
    }
}
