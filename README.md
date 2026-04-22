# SarkiSozU — Turkce Gitar Akor & Sarki Sozu Uygulamasi

Turkce sarkilarin akorlarini ve sozlerini goruntuleyen, muzisyenler icin gelistirilmis kapsamli bir iOS uygulamasi. SwiftUI ile yazildi, iPhone ve iPad icin adaptif layout destegi.

**4067 sarki** | **968 sanatci** | **Akor diyagramlari** | **Transpoz** | **Metronom** | **Akort aleti** | **Canli akor tespiti** | **Ozel akor kutuphanesi** | **iCloud senkronizasyon** | **Ses kaydi + A/B loop**

---

## Ana Ozellikler

### Sarki Goruntuleme
- **4067 sarki** veritabani (repertuarim.com'dan scrape edilmis, JSONL, ~32MB bundle)
- Akor ve soz goruntuleyici — satirlar uzerinde akor pozisyonlari
- Transpoz — yari ton yukari/asagi, anlik hesaplama
- Kapo destegi — orijinal kapo + kullanici kapo, efektif transpoz
- Akor diyagramlari — dokunulabilir, Canvas tabanli
- Turkce arama — karakter normalizasyonu (u/o/s/c/g/i destegi)
- Otomatik kaydirma — ayarlanabilir hiz, calarken sozu takip
- Yazi boyutu ayari (10–28pt)

### Organizasyon
- **Favori sarkilar** — kalp ile isaretleme, ayri sekme
- **Playlistler** — ozel listeler, sarki ekle/cikar, rename, delete
- **Sarki notlari** — her sarkiya kisisel not
- **Son goruntulenenler** — ana sayfada hizli erisim
- **Sanatci sayfasi** — sanatci bazli sarki listesi
- **Zorluk derecesi** — otomatik hesaplama (Kolay/Orta/Zor/Uzman)

### Muzisyen Araclari
- **Metronom** — 40–220 BPM, 4/4/3/4/6/8/2/4 olcu, tap tempo, hazir tempo secenekleri
- **Akort Aleti** — YIN pitch detection, standart/Drop D/Open G/Open D akort, cent sapma gostergesi
- **Canli Akor Tespiti** — FFT + chroma analizi, gercek zamanli akor tanima, guven yuzdesi
  - Mikrofon seviye metre (20 bar, yesil/sari/kirmizi)
  - 12-bar chroma enerji gorselleme (nota etiketli)
  - Hassasiyet slider (@AppStorage persistence)
  - Tespit edilen akorun canli diyagrami
- **Kapo Hesaplayici** — hedef akor secimi, 0–12 perdede kapo onerileri, kolay/zor degerlendirmesi
- **Pratik Zamanlayicisi** — sure secimi (10–60dk), geri sayim, halka ilerleme, 7 gunluk seri takibi
- **Ozel Akor Kutuphanesi** — kendi akorlarinizi olusturun (ChordEditorView)
  - 5×6 dokunulabilir fretboard grid
  - Base fret stepper
  - Barre toggle + string range picker
  - Canli onizleme
  - CloudKit ile cihazlar arasi senkron

### Kesif & Oyun
- **"Bunu Calabilir misin?" Modu** — bildigi akorlari sec, calabilecegi sarkilari bul
- **Rastgele Sarki** — tek tikla
- **Akor Kutuphanesi** — 28 temel akor + sinirsiz ozel akor

### Performans Modlari
- **Konser (Setlist) Modu** — tam ekran, siyah arka plan, swipe gecis, ekran acik tutma
- **Ses Kaydi & A/B Loop** — pratik icin dahili kaydedici
  - Kayit / oynatma / duraklat
  - A–B loop (sec ve dongude oynat)
  - Oynatma hizi ayari
  - Kayit kutuphanesi (sarki bazli)
- **Streaming Entegrasyonu** — "Dinle" menusu:
  - Spotify (uygulama varsa deep link, yoksa web)
  - Apple Music (music.apple.com/tr/search)
  - YouTube (youtube:// ya da web)

### iCloud Senkronizasyon
NSUbiquitousKeyValueStore uzerinden otomatik senkron (CloudKit container gerektirmez):
- Favoriler
- Playlistler
- Sarki notlari
- Ozel akorlar
- Son goruntulenenler
- Ayarlar: toggle + manuel sync + son sync zamani

### Pro Abonelik
- StoreKit 2 tabanli abonelik sistemi (ProManager)
- Ucretsiz limitler: 5 favori, 3 playlist
- Pro avantajlari: sinirsiz favori, sinirsiz playlist, PDF export, kayit, ozel akor
- `Products.storekit` config dosyasi dahil
- PaywallView

### iPad Destegi
- NavigationSplitView (sidebar + detay)
- `@Environment(\.horizontalSizeClass)` ile iPhone/iPad otomatik secim
- iPhone'da TabView, iPad'de sidebar (home/songs/search/favorites/settings)

### Diger
- **Haptic Feedback** — HapticManager (metronom tick, buton tiklama, basari/hata)
- **PDF Export** — ExportService ile sarki PDF ciktisi
- **Onboarding** — 4 sayfalik tanitim
- **Karanlik Mod** — tam karanlik tema
- **Ekran Acik Tutma** — performans modlarinda

---

## Mimari

```
SarkiSozu/
├── SarkiSozuApp.swift              # Entry point + @StateObject shared managers
├── ContentView.swift               # iPhone TabView / iPad NavigationSplitView
├── DesignSystem.swift              # DS namespace (renkler, spacing, tipografi)
├── Theme.swift                     # Tema sabitleri
├── Models/
│   └── Song.swift                  # Song, Playlist, RenderBlock, SongDifficulty
├── Services/
│   ├── SongDataService.swift       # Veri, favoriler, playlistler, notlar
│   ├── ProManager.swift            # StoreKit 2 abonelik
│   ├── RecordingManager.swift      # AVAudioRecorder + A/B loop
│   ├── StreamingService.swift      # Spotify/Apple Music/YouTube deep link
│   ├── CustomChordStore.swift      # Kullanici akorlari
│   ├── SyncManager.swift           # iCloud KV senkron
│   └── ExportService.swift         # PDF export
├── Utils/
│   ├── MusicTheory.swift           # Transpoz, nota
│   └── HapticManager.swift         # UIImpactFeedback wrapper
├── ViewModels/
│   └── ViewModels.swift
├── Views/
│   ├── HomeView.swift
│   ├── SongsView.swift
│   ├── SearchView.swift
│   ├── FavoritesView.swift
│   ├── SettingsView.swift          # + iCloud toggle
│   ├── SongDetailView.swift        # + kayit/streaming butonlari
│   ├── SongRecordingSheet.swift    # Kayit UI + A/B loop
│   ├── PaywallView.swift           # Pro abonelik UI
│   ├── ArtistView.swift
│   ├── SetlistView.swift           # Konser modu
│   ├── CanIPlayView.swift
│   ├── CapoCalculatorView.swift
│   ├── PracticeView.swift
│   ├── MetronomeView.swift
│   ├── TunerView.swift
│   ├── ChordDetectorView.swift     # + mic meter + chroma viz + sensitivity
│   ├── ChordLibraryView.swift      # + ozel akor bolumu
│   ├── ChordEditorView.swift       # Fretboard editor
│   ├── OnboardingView.swift
│   ├── PlaylistDetailView.swift
│   └── Components/
│       ├── Components.swift
│       ├── SongRowView.swift
│       └── ChordDiagramView.swift
└── Resources/
    ├── cleaned_songs.json          # 4067 sarki (JSONL, ~32MB)
    ├── Products.storekit           # StoreKit config
    └── ChordSVGs/                  # Akor SVG dosyalari
```

### Kullanilan Teknolojiler
- **SwiftUI** — Tum UI
- **AVFoundation** — AVAudioRecorder, AVAudioPlayer, AVAudioEngine, AVAudioSession
- **Accelerate (vDSP)** — FFT, chroma cikarimi, YIN pitch detection
- **StoreKit 2** — Abonelik yonetimi
- **NSUbiquitousKeyValueStore** — iCloud KV senkron (1MB limit)
- **UIKit** — UIImpactFeedbackGenerator, UIGraphicsPDFRenderer
- **UserDefaults + JSON** — Lokal persistence
- **Canvas API** — Akor diyagramlari

### Concurrency
- `@MainActor` isolation shared stores icin (SyncManager, CustomChordStore, ProManager)
- `nonisolated static var` gerekli computed property'lerde
- `Task { @MainActor in }` cross-isolation senkron tetikleme
- `MainActor.assumeIsolated` sync context'ten main-isolated erisim

### Gereksinimler
- iOS 17.0+
- Xcode 16+
- Swift 5.0+
- Mikrofon izni (akort aleti, akor tespiti, ses kaydi)
- iCloud "Key-value storage" capability (sync icin, Xcode'dan manuel aktif et)

---

## Kurulum

```bash
git clone https://github.com/parzidev/muzik.git
cd muzik/SarkiSozu
open SarkiSozu.xcodeproj
```

Xcode'da hedef cihaz secip **Cmd+R** ile calistirin.

### iCloud Sync Kurulumu
1. Xcode → Target → Signing & Capabilities
2. **+ Capability** → **iCloud**
3. **Key-value storage** kutusunu isaretle
4. Ayni Apple ID ile giris yapmis cihazlarda otomatik sync

### StoreKit Test
- Scheme → Run → Options → StoreKit Configuration → `Products.storekit` sec
- Sanal satin alimla Pro ozellikleri test edilebilir

> **Not:** Akort aleti, akor tespiti ve ses kaydi gercek cihaz gerektirir. Simulatorde bu ozellikler uyarı gosterir. iCloud KV simulatorde silent no-op davranır.

---

## Veri Kaynagi

Sarki verileri [repertuarim.com](https://www.repertuarim.com) adresinden scrape edilmistir. Her sarki icin:
- Sanatci adi, sarki adi
- Orijinal ton, kayitli ton, kolay akor tonu
- Kapo bilgisi
- Ritim kaliplari
- Soz satirlari ile akor pozisyonlari

---

## Yol Haritasi

### Tamamlanan Kilometre Taslari
- [x] 4067 sarki JSONL parser
- [x] Transpoz + kapo hesabi
- [x] Canvas akor diyagramlari
- [x] Metronom (AVAudioEngine)
- [x] Akort aleti (YIN)
- [x] Canli akor tespiti (FFT + chroma)
- [x] Pratik zamanlayici
- [x] Konser modu
- [x] Haptic feedback
- [x] PDF export
- [x] Ses kaydi + A/B loop
- [x] Streaming entegrasyon (Spotify/Apple Music/YouTube)
- [x] Ozel akor kutuphanesi (ChordEditorView)
- [x] iCloud senkron (NSUbiquitousKeyValueStore)
- [x] StoreKit 2 abonelik (Pro)
- [x] iPad split view layout

### v1.6 — Sirada
- [ ] App Icon tasarimi (1024×1024)
- [ ] Launch Screen animasyonu
- [ ] Landscape destegi
- [ ] Arama gecmisi ve oneriler
- [ ] Share sheet (sarki paylasma)
- [ ] Akor kutuphanesini genisletme (sus4, add9, dim, aug)
- [ ] Alternatif akor pozisyonlari
- [ ] Strum pattern gosterimi

### v2.0 — Platform Genislemesi
- [ ] watchOS (metronom + akort aleti)
- [ ] macOS Catalyst / native Mac
- [ ] Widgets (rastgele sarki, pratik hatirlatici)
- [ ] Siri Shortcuts
- [ ] CarPlay (soz goruntuleyici)
- [ ] Apple Music tam entegrasyon (MusicKit)

### Teknik Borc
- [ ] Unit testler (XCTest)
- [ ] UI testleri (XCUITest)
- [ ] CI/CD (GitHub Actions)
- [ ] Accessibility (VoiceOver)
- [ ] Lokalizasyon (EN/DE/FR)
- [ ] CoreData'ya gecis

---

## Ekran Goruntuleri

> Yakinda eklenecek

---

## Lisans

Kisisel kullanim icin gelistirilmistir. Sarki verileri repertuarim.com'a aittir.
