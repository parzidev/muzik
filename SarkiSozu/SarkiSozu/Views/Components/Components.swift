import SwiftUI

// MARK: - Song Card (For Horizontal Scroll)
struct SongCardView: View {
    let title: String
    let artist: String
    let footnote: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            // Icon / Art Placeholder
            ZStack {
                RoundedRectangle(cornerRadius: DS.CornerRadius.medium)
                    .fill(DS.Color.accentGradient)
                    .aspectRatio(1, contentMode: .fit)
                
                Image(systemName: "music.note")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
                    .symbolEffect(.bounce, value: true)
            }
            .frame(width: 140)
            
            VStack(alignment: .leading, spacing: 2) {
                DS.Typography.headline(title)
                    .lineLimit(1)
                    .foregroundColor(DS.Color.textPrimary)
                
                DS.Typography.subheadline(artist)
                    .lineLimit(1)
                    .foregroundColor(DS.Color.textSecondary)
                
                if let footnote = footnote {
                    DS.Typography.caption(footnote)
                        .lineLimit(1)
                        .foregroundColor(DS.Color.textTertiary)
                        .padding(.top, 2)
                }
            }
            .frame(maxWidth: 140, alignment: .leading)
        }
        .padding(DS.Spacing.xs)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(DS.CornerRadius.large)
        .shadow(color: DS.Shadow.light.color, radius: DS.Shadow.light.radius, x: 0, y: 2)
    }
}


// MARK: - Filter Chip
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, DS.Spacing.m)
                .padding(.vertical, DS.Spacing.xs)
                .background(
                    isSelected ? DS.Color.accent : Color(uiColor: .secondarySystemBackground)
                )
                .foregroundColor(isSelected ? .white : DS.Color.textPrimary)
                .cornerRadius(20)
        }
    }
}

// MARK: - Empty State
struct EmptyStateView: View {
    let icon: String // SF Symbol
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    var body: some View {
        VStack(spacing: DS.Spacing.m) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundColor(DS.Color.textTertiary)
                .padding(.bottom, DS.Spacing.xs)
            
            DS.Typography.title3(title)
                .foregroundColor(DS.Color.textPrimary)
            
            DS.Typography.subheadline(message)
                .multilineTextAlignment(.center)
                .foregroundColor(DS.Color.textSecondary)
                .padding(.horizontal, DS.Spacing.xl)
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .fontWeight(.semibold)
                        .padding(.horizontal, DS.Spacing.l)
                        .padding(.vertical, DS.Spacing.s)
                        .background(DS.Color.accent)
                        .foregroundColor(.white)
                        .cornerRadius(DS.CornerRadius.medium)
                }
                .padding(.top, DS.Spacing.m)
            }
        }
        .padding(DS.Spacing.xl)
    }
}

// MARK: - Skeleton Loading
struct SkeletonView: View {
    var body: some View {
        HStack(spacing: DS.Spacing.m) {
            RoundedRectangle(cornerRadius: DS.CornerRadius.small)
                .fill(Color(uiColor: .secondarySystemBackground))
                .frame(width: 44, height: 44)
            
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(uiColor: .secondarySystemBackground))
                    .frame(height: 16)
                    .frame(maxWidth: 150)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(uiColor: .secondarySystemBackground))
                    .frame(height: 12)
                    .frame(maxWidth: 100)
            }
            Spacer()
        }
        .padding(.vertical, DS.Spacing.xs)
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    var body: some View {
        HStack {
            DS.Typography.title2(title)
                .foregroundColor(DS.Color.textPrimary)
            
            Spacer()
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.subheadline)
                        .foregroundColor(DS.Color.accent)
                }
            }
        }
        .padding(.horizontal, DS.Spacing.m)
        .padding(.top, DS.Spacing.m)
        .padding(.bottom, DS.Spacing.xs)
    }
}

struct Components_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 20) {
                ScrollView(.horizontal) {
                    HStack {
                        SongCardView(title: "Ay Yüzlüm", artist: "Murat Göğebakan", footnote: "Popüler")
                        SongCardView(title: "Akdeniz Akşamları", artist: "Haluk Levent", footnote: nil)
                    }
                    .padding()
                }
                
                VStack {
                    SongRowView(song: Song(id: 1, sanatci: "Nilüfer", sarkiadi: "Caddelerde Rüzgar", orjinal_ton: "Am", kayitli_ton: nil, kolay_akor_ton: nil, kapo: nil, ritimler: nil, scrape_status: nil, lyrics_data: nil))
                    Divider()
                    SongRowView(song: Song(id: 2, sanatci: "Haluk Levent", sarkiadi: "Elfida", orjinal_ton: nil, kayitli_ton: nil, kolay_akor_ton: nil, kapo: nil, ritimler: nil, scrape_status: nil, lyrics_data: nil))
                }
                .padding()
                
                HStack {
                    FilterChip(title: "Tümü", isSelected: true, action: {})
                    FilterChip(title: "Favoriler", isSelected: false, action: {})
                    FilterChip(title: "90'lar", isSelected: false, action: {})
                }
                
                EmptyStateView(
                    icon: "magnifyingglass",
                    title: "Sonuç Bulunamadı",
                    message: "Aradığınız kriterlere uygun şarkı bulunamadı. Lütfen farklı anahtar kelimeler deneyin.",
                    actionTitle: "Filtreleri Temizle",
                    action: {}
                )
                
                VStack {
                    SkeletonView()
                    SkeletonView()
                    SkeletonView()
                }
                .padding()
            }
        }
    }
}
