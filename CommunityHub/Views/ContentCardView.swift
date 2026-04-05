import SwiftUI

struct ContentCardView: View {
    let contentType: ContentType
    let item: ContentItem

    @State private var useFallbackThumbnail = false
    @State private var thumbnailFailed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let thumbnailURL = selectedThumbnailURL, !thumbnailFailed {
                AsyncImage(url: thumbnailURL) { phase in
                    switch phase {
                    case .empty:
                        placeholder(height: 180)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    case .failure:
                        if item.thumbnailFallbackURL != nil, !useFallbackThumbnail {
                            Color.clear
                                .frame(height: 0)
                                .onAppear {
                                    useFallbackThumbnail = true
                                }
                        } else {
                            placeholder(height: 180, title: "Thumbnail unavailable")
                                .onAppear {
                                    thumbnailFailed = true
                                }
                        }
                    @unknown default:
                        placeholder(height: 180)
                    }
                }
            } else if contentType == .video {
                placeholder(height: 180, title: "Thumbnail unavailable")
            }

            HStack {
                Text(contentType.rawValue.uppercased())
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(.blue)

                Spacer()

                Text(item.metric)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Text(item.title)
                .font(.title3.weight(.heavy))
                .foregroundStyle(.primary)

            Text(item.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineSpacing(3)

            tags
        }
        .padding(14)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var tags: some View {
        let allTags = baseTags + loginTag
        let columns = [GridItem(.adaptive(minimum: 88), alignment: .leading)]

        return LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(allTags) { tag in
                Text(tag.text)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(tag.style == .emphasis ? Color.white : Color.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(tag.style == .emphasis ? Color.black : Color(.systemGray6))
                    .clipShape(Capsule())
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var baseTags: [TagItem] {
        var tags: [TagItem] = [
            TagItem(text: item.audience.rawValue, style: .normal),
            TagItem(text: item.category.rawValue, style: .normal)
        ]

        if let language = item.language {
            tags.append(TagItem(text: language.rawValue, style: .normal))
        }

        return tags
    }

    private var loginTag: [TagItem] {
        if item.requiresLogin {
            return [TagItem(text: "LOG IN TO VIEW", style: .emphasis)]
        }
        return []
    }

    private var selectedThumbnailURL: URL? {
        if useFallbackThumbnail {
            return item.thumbnailFallbackURL ?? item.thumbnailURL
        }

        return item.thumbnailURL
    }

    private func placeholder(height: CGFloat, title: String = "") -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
                .frame(height: height)

            if !title.isEmpty {
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct TagItem: Identifiable {
    enum Style {
        case normal
        case emphasis
    }

    let id = UUID()
    let text: String
    let style: Style
}
