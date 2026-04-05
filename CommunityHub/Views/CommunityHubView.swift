import SwiftUI

struct CommunityHubView: View {
    @StateObject private var viewModel = CommunityHubViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    header

                    if viewModel.isLoadingInitial {
                        loadingState(text: "Loading content...")
                    } else if let error = viewModel.loadError, viewModel.items.isEmpty {
                        errorState(message: error)
                    } else if viewModel.items.isEmpty {
                        emptyState
                    } else {
                        ForEach(viewModel.items) { item in
                            ContentCardView(contentType: viewModel.contentType, item: item)
                                .onAppear {
                                    viewModel.loadMoreIfNeeded(currentItem: item)
                                }
                        }

                        if viewModel.hasMore {
                            Color.clear
                                .frame(height: 1)
                                .onAppear {
                                    viewModel.loadMore()
                                }
                        }

                        footer
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            if viewModel.items.isEmpty {
                viewModel.loadInitial()
            }
        }
        .onChange(of: viewModel.contentType) { _ in
            viewModel.refreshForChangedFilters()
        }
        .onChange(of: viewModel.audience) { _ in
            viewModel.refreshForChangedFilters()
        }
        .task(id: viewModel.search) {
            try? await Task.sleep(nanoseconds: 350_000_000)
            await MainActor.run {
                viewModel.refreshForChangedFilters()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("BigFuture Community Library")
                .font(.footnote.weight(.bold))
                .foregroundStyle(.primary)

            Text(viewModel.contentType.titlePlural)
                .font(.system(size: 30, weight: .heavy))
                .foregroundStyle(.primary)

            Text("Starter mobile experience with live Community Hub API data.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Picker("Content Type", selection: $viewModel.contentType) {
                ForEach(ContentType.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)

            TextField(
                "Search \(viewModel.contentType.titlePlural.lowercased())",
                text: $viewModel.search
            )
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(.separator), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))

            audienceChips

            Text("\(viewModel.items.count) Results")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
        }
    }

    private var audienceChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(AudienceFilter.allCases) { option in
                    Button {
                        viewModel.audience = option
                    } label: {
                        Text(option.rawValue)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(viewModel.audience == option ? Color.white : Color.blue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(viewModel.audience == option ? Color.blue : Color.blue.opacity(0.15))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var footer: some View {
        VStack(spacing: 6) {
            Group {
                if viewModel.isLoadingMore {
                    loadingState(text: "Loading more...")
                } else if !viewModel.hasMore {
                    Text("No more results.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                } else if let error = viewModel.loadError {
                    VStack(spacing: 10) {
                        Text(error)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)

                        Button("Retry Load More") {
                            viewModel.loadMore()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                    .padding(.vertical, 24)
                } else {
                    Button("Load More") {
                        viewModel.loadMore()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .padding(.top, 8)
                }
            }
        }
    }

    private var emptyState: some View {
        Text("No results for your current filters.")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
    }

    private func loadingState(text: String) -> some View {
        VStack(spacing: 8) {
            ProgressView()
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private func errorState(message: String) -> some View {
        VStack(spacing: 8) {
            Text("Unable to load content.")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}

struct CommunityHubView_Previews: PreviewProvider {
    static var previews: some View {
        CommunityHubView()
    }
}
