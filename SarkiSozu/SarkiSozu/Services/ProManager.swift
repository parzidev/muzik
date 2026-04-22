import Foundation
import StoreKit
import SwiftUI

/// Manages Pro subscription state and StoreKit 2 transactions.
@MainActor
final class ProManager: ObservableObject {
    static let shared = ProManager()

    // Product identifiers — bunları App Store Connect'te de aynen oluştur.
    enum ProductID: String, CaseIterable {
        case monthly = "com.sarkisozu.pro.monthly"
        case yearly = "com.sarkisozu.pro.yearly"
        case lifetime = "com.sarkisozu.pro.lifetime"

        var displayName: String {
            switch self {
            case .monthly: return "Aylık"
            case .yearly: return "Yıllık"
            case .lifetime: return "Ömür Boyu"
            }
        }

        var isSubscription: Bool {
            self != .lifetime
        }
    }

    @Published private(set) var products: [Product] = []
    @Published private(set) var isPro: Bool = false
    @Published private(set) var purchaseInFlight: Bool = false
    @Published var lastError: String?

    /// Debug override — Xcode preview veya test için local Pro açma.
    @AppStorage("debug_force_pro") var debugForcePro: Bool = false

    private var updatesTask: Task<Void, Never>?

    private init() {
        updatesTask = listenForTransactionUpdates()
        Task { await refresh() }
    }

    deinit {
        updatesTask?.cancel()
    }

    // MARK: - Public API

    /// Check if user has Pro access (subscription active OR lifetime purchased OR debug flag).
    var hasProAccess: Bool {
        debugForcePro || isPro
    }

    func refresh() async {
        await loadProducts()
        await updateEntitlement()
    }

    func purchase(_ productID: ProductID) async {
        guard let product = products.first(where: { $0.id == productID.rawValue }) else {
            lastError = "Ürün bulunamadı. Tekrar deneyin."
            return
        }
        purchaseInFlight = true
        defer { purchaseInFlight = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await updateEntitlement()
                await transaction.finish()
            case .userCancelled:
                break
            case .pending:
                lastError = "Satın alma onay bekliyor."
            @unknown default:
                break
            }
        } catch {
            lastError = error.localizedDescription
        }
    }

    func restore() async {
        purchaseInFlight = true
        defer { purchaseInFlight = false }
        do {
            try await AppStore.sync()
            await updateEntitlement()
        } catch {
            lastError = error.localizedDescription
        }
    }

    // MARK: - Internal

    private func loadProducts() async {
        do {
            let ids = ProductID.allCases.map { $0.rawValue }
            let fetched = try await Product.products(for: ids)
            self.products = fetched.sorted { a, b in
                ProductID(rawValue: a.id).map(sortIndex) ?? 99 <
                ProductID(rawValue: b.id).map(sortIndex) ?? 99
            }
        } catch {
            lastError = "Ürünler yüklenemedi: \(error.localizedDescription)"
        }
    }

    private func sortIndex(_ p: ProductID) -> Int {
        switch p {
        case .yearly: return 0
        case .lifetime: return 1
        case .monthly: return 2
        }
    }

    private func updateEntitlement() async {
        var active = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let tx) = result else { continue }
            if ProductID(rawValue: tx.productID) != nil {
                if tx.revocationDate == nil {
                    active = true
                }
            }
        }
        self.isPro = active
    }

    private func listenForTransactionUpdates() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                if case .verified(let tx) = result {
                    await tx.finish()
                    await self.updateEntitlement()
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let value):
            return value
        }
    }
}

// MARK: - Feature Gate

/// Central source of truth for free-tier limits.
enum ProGate {
    static let freeFavoritesLimit = 10
    static let freePlaylistsLimit = 1

    /// Which feature triggered the paywall — used for analytics + paywall copy.
    enum Feature: String {
        case favoritesLimit
        case playlistsLimit
        case exportPDF
        case exportChordPro
        case shareSong
        case cloudSync
        case altChordShapes

        var title: String {
            switch self {
            case .favoritesLimit: return "Sınırsız Favori"
            case .playlistsLimit: return "Sınırsız Liste"
            case .exportPDF: return "PDF Olarak Kaydet"
            case .exportChordPro: return "Akor Dosyası Dışa Aktar"
            case .shareSong: return "Şarkı Paylaş"
            case .cloudSync: return "iCloud Senkronizasyon"
            case .altChordShapes: return "Alternatif Akor Pozisyonları"
            }
        }

        var message: String {
            switch self {
            case .favoritesLimit:
                return "Ücretsiz sürümde en fazla \(ProGate.freeFavoritesLimit) favori ekleyebilirsin. Pro ile sınırsız favori + çalma listesi."
            case .playlistsLimit:
                return "Ücretsiz sürümde \(ProGate.freePlaylistsLimit) liste oluşturabilirsin. Pro ile sınırsız liste + iCloud senkronizasyon."
            case .exportPDF:
                return "Şarkıları transpoz edilmiş haliyle PDF olarak kaydet. Setlist'ini tek PDF'te topla."
            case .exportChordPro:
                return "ChordPro veya düz metin olarak şarkılarını dışa aktar, başka uygulamalarda aç."
            case .shareSong:
                return "Şarkıyı arkadaşlarınla paylaş. Pro ile tam sözler ve akorlar dahil."
            case .cloudSync:
                return "Favorilerini, listelerini ve notlarını tüm cihazlarında senkron et."
            case .altChordShapes:
                return "Her akor için 3-4 farklı tutuş pozisyonu gör."
            }
        }
    }
}
