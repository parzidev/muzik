import SwiftUI
import StoreKit

// MARK: - Paywall Sheet

struct PaywallView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var pro = ProManager.shared

    /// Which feature triggered this paywall — shown at the top for context.
    let triggerFeature: ProGate.Feature?

    @State private var selectedProduct: ProManager.ProductID = .yearly

    init(feature: ProGate.Feature? = nil) {
        self.triggerFeature = feature
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DS.Spacing.l) {
                    header
                    featureHighlight
                    proFeaturesList
                    productPicker
                    ctaButton
                    legalRow
                    restoreButton

                    if let err = pro.lastError {
                        Text(err)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical, DS.Spacing.l)
                .padding(.horizontal, DS.Spacing.m)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        HapticManager.tap()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .task { await pro.refresh() }
            .onChange(of: pro.isPro) { _, newValue in
                if newValue {
                    HapticManager.success()
                    dismiss()
                }
            }
        }
    }

    // MARK: - Subviews

    private var header: some View {
        VStack(spacing: DS.Spacing.s) {
            ZStack {
                RoundedRectangle(cornerRadius: DS.CornerRadius.xlarge)
                    .fill(DS.Color.accentGradient)
                    .frame(width: 96, height: 96)
                Image(systemName: "crown.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.white)
            }
            .shadow(color: DS.Shadow.float.color, radius: 16, x: 0, y: 8)

            Text("SarkıSözÜ Pro")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Müzisyenler için tam deneyim")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top, DS.Spacing.m)
    }

    @ViewBuilder
    private var featureHighlight: some View {
        if let feature = triggerFeature {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "lock.open.fill")
                        .foregroundColor(DS.Color.accent)
                    Text(feature.title)
                        .font(.headline)
                }
                Text(feature.message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(DS.Spacing.m)
            .background(DS.Color.accent.opacity(0.08))
            .cornerRadius(DS.CornerRadius.medium)
        }
    }

    private var proFeaturesList: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s) {
            Text("Pro ile neler gelir:")
                .font(.headline)
                .padding(.bottom, 4)
            featureRow("infinity", "Sınırsız favori ve çalma listesi")
            featureRow("square.and.arrow.up", "PDF, ChordPro ve metin olarak dışa aktar")
            featureRow("icloud", "iCloud ile tüm cihazlarda senkron")
            featureRow("guitars", "Alternatif akor pozisyonları")
            featureRow("waveform.path", "Polyphonic tuner ve alternatif akortlar")
            featureRow("mic.fill", "Pratik sırasında ses kaydı")
            featureRow("sparkles", "AI şarkı önerisi ve akor çıkarma")
            featureRow("nosign", "Reklam yok, ilk sıra destek")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DS.Spacing.m)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(DS.CornerRadius.medium)
    }

    private func featureRow(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(DS.Color.accent)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
            Spacer()
        }
    }

    private var productPicker: some View {
        VStack(spacing: DS.Spacing.s) {
            ForEach(sortedProducts, id: \.id) { product in
                productRow(product)
            }

            if pro.products.isEmpty {
                HStack {
                    ProgressView().scaleEffect(0.8)
                    Text("Fiyatlar yükleniyor…")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
        }
    }

    private var sortedProducts: [Product] {
        pro.products
    }

    private func productRow(_ product: Product) -> some View {
        let productID = ProManager.ProductID(rawValue: product.id)
        let isSelected = selectedProduct.rawValue == product.id
        let isYearly = productID == .yearly
        let isLifetime = productID == .lifetime

        return Button {
            HapticManager.tap()
            if let pid = productID { selectedProduct = pid }
        } label: {
            HStack(spacing: DS.Spacing.m) {
                ZStack {
                    Circle()
                        .stroke(isSelected ? DS.Color.accent : Color(uiColor: .tertiaryLabel), lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle()
                            .fill(DS.Color.accent)
                            .frame(width: 12, height: 12)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(productID?.displayName ?? product.displayName)
                            .font(.headline)
                        if isYearly {
                            Text("EN POPÜLER")
                                .font(.caption2).fontWeight(.bold)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(DS.Color.accent)
                                .foregroundColor(.white)
                                .cornerRadius(4)
                        }
                        if isLifetime {
                            Text("TEK SEFERLİK")
                                .font(.caption2).fontWeight(.bold)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(4)
                        }
                    }
                    Text(productSubtitle(product, id: productID))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(product.displayPrice)
                    .font(.headline)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: DS.CornerRadius.medium)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: DS.CornerRadius.medium)
                    .stroke(isSelected ? DS.Color.accent : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private func productSubtitle(_ product: Product, id: ProManager.ProductID?) -> String {
        guard let id else { return "" }
        switch id {
        case .monthly: return "Her ay yenilenir"
        case .yearly:  return "Yıllık · ayda daha uygun"
        case .lifetime: return "Tek ödeme, ömür boyu erişim"
        }
    }

    private var ctaButton: some View {
        Button {
            HapticManager.impact(.medium)
            Task { await pro.purchase(selectedProduct) }
        } label: {
            HStack {
                if pro.purchaseInFlight {
                    ProgressView().tint(.white)
                } else {
                    Text(ctaText)
                        .font(.headline)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(DS.Color.accentGradient)
            .foregroundColor(.white)
            .cornerRadius(DS.CornerRadius.medium)
        }
        .disabled(pro.purchaseInFlight || pro.products.isEmpty)
    }

    private var ctaText: String {
        if selectedProduct == .lifetime {
            return "Ömür Boyu Satın Al"
        }
        return "Pro'ya Geç"
    }

    private var restoreButton: some View {
        Button {
            HapticManager.tap()
            Task { await pro.restore() }
        } label: {
            Text("Satın Alımları Geri Yükle")
                .font(.footnote)
                .foregroundColor(DS.Color.accent)
        }
    }

    private var legalRow: some View {
        VStack(spacing: 4) {
            Text("Abonelik otomatik yenilenir. İstediğin zaman Ayarlar > Apple ID > Abonelikler'den iptal edebilirsin.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            HStack(spacing: 8) {
                Link("Gizlilik", destination: URL(string: "https://example.com/privacy")!)
                Text("·")
                Link("Kullanım Şartları", destination: URL(string: "https://example.com/terms")!)
            }
            .font(.caption2)
        }
        .padding(.horizontal)
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Paywall Trigger Modifier

extension View {
    /// Presents the paywall sheet bound to a trigger feature.
    func paywallSheet(isPresented: Binding<Bool>, feature: ProGate.Feature? = nil) -> some View {
        self.sheet(isPresented: isPresented) {
            PaywallView(feature: feature)
        }
    }
}

// MARK: - Pro Badge

struct ProBadge: View {
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "crown.fill")
            Text("PRO")
        }
        .font(.caption2).fontWeight(.bold)
        .padding(.horizontal, 6).padding(.vertical, 2)
        .background(DS.Color.accentGradient)
        .foregroundColor(.white)
        .cornerRadius(6)
    }
}
