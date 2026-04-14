import SwiftUI

struct OnboardingView: View {
    @Binding var hasSeenOnboarding: Bool
    @State private var currentPage = 0

    private let pages: [(icon: String, title: String, subtitle: String, color: Color)] = [
        ("music.note.list", "4000+ Türkçe Şarkı", "Akorları ve sözleriyle birlikte binlerce şarkıya anında eriş.", Color(hex: "5B5FC7")),
        ("guitars", "Akor Diyagramları", "Her akoru görsel olarak öğren. Tıkla, diyagramı gör.", Color(hex: "E67E22")),
        ("arrow.up.arrow.down", "Transpose & Kapo", "Sesine uygun tonu bul. Kapo hesaplayıcı ile en kolay pozisyonu keşfet.", Color(hex: "2ECC71")),
        ("heart.fill", "Pratik Yap", "Favorilerini kaydet, setlist oluştur, pratik süresini takip et.", Color(hex: "E74C3C")),
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    VStack(spacing: 32) {
                        Spacer()

                        ZStack {
                            Circle()
                                .fill(page.color.opacity(0.15))
                                .frame(width: 160, height: 160)
                            Circle()
                                .fill(page.color.opacity(0.1))
                                .frame(width: 120, height: 120)
                            Image(systemName: page.icon)
                                .font(.system(size: 48))
                                .foregroundColor(page.color)
                        }

                        VStack(spacing: 12) {
                            Text(page.title)
                                .font(.title)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)

                            Text(page.subtitle)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }

                        Spacer()
                        Spacer()
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            // Bottom button
            VStack(spacing: 16) {
                Button {
                    if currentPage < pages.count - 1 {
                        withAnimation { currentPage += 1 }
                    } else {
                        hasSeenOnboarding = true
                    }
                } label: {
                    Text(currentPage == pages.count - 1 ? "Başla" : "Devam")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(pages[currentPage].color)
                        .cornerRadius(16)
                }

                if currentPage < pages.count - 1 {
                    Button("Atla") {
                        hasSeenOnboarding = true
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Color(uiColor: .systemBackground))
    }
}
