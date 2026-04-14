# SarkiSozU - Turkce Gitar Akor & Sarki Sozu Uygulamasi

Turkce sarkilarin akorlarini ve sozlerini goruntuleyen, muzisyenler icin gelistirilmis kapsamli bir iOS uygulamasi.

**4000+ sarki** | **968 sanatci** | **Akor diyagramlari** | **Transpoz** | **Metronom** | **Akort aleti**

---

## Ozellikler

### Temel Ozellikler
- **4067 sarki** veritabani (repertuarim.com'dan scrape edilmis)
- **Akor ve soz goruntuleyici** — satirlar uzerinde akor pozisyonlari
- **Transpoz (ton degistirme)** — yari ton yukari/asagi, anlik hesaplama
- **Kapo destegi** — orijinal kapo + kullanici kapo ayari, efektif transpoz
- **Akor diyagramlari** — dokunulabilir akorlar, Canvas tabanli perde gorunumu
- **Turkce arama** — karakter normalizasyonu (u/o/s/c/g/i destegi)
- **Favori sarkilar** — kalp ile isaretleme, ayri sekmede listeleme
- **Playlist sistemi** — ozel listeler olusturma, sarki ekleme/cikarma
- **Sarki notlari** — her sarkiya kisisel not ekleme

### Muzisyen Araclari
- **Metronom** — BPM ayarli (40-220), 4/4-3/4-6/8-2/4 olcu, tap tempo, hazir tempo secenekleri (Largo, Adagio, Allegro vb.)
- **Akort Aleti (Tuner)** — YIN pitch detection algoritması, standart/Drop D/Open G/Open D akort destegi, cent sapma gostergesi
- **Canli Akor Tespiti** — FFT + chroma analizi ile gercek zamanli akor tanima, guven yuzdesi, son tespit edilen akorlar
- **Kapo Hesaplayici** — hedef akor secimi, 0-12 perdede kapo onerileri, kolay/zor degerlendirmesi
- **Pratik Zamanlayicisi** — sure secimi (10-60dk), geri sayim, ilerleme halkasi, seri takibi (7 gunluk), oturum istatistikleri

### Kesif & Oyun
- **"Bunu Calabilir misin?" Modu** — bildigi akorlari sec, calabilecegi sarkilari bul (%50+ eslesen)
- **Rastgele Sarki** — tek tikla rastgele sarki ac
- **Zorluk Derecesi** — otomatik hesaplama (Kolay/Orta/Zor/Uzman), barre akor sayisina gore
- **Sanatci Sayfasi** — sanatci detay sayfasi, sarki listesi

### Performans
- **Konser (Setlist) Modu** — tam ekran, siyah arka plan, swipe ile sarki gecisi, otomatik ekran acik tutma
- **Otomatik Kaydirma** — ayarlanabilir hiz, sarki calarken sozu takip etme
- **Karanlik Mod** — tam karanlik tema destegi
- **Yazi Boyutu** — 10pt - 28pt arasi ayarlanabilir

### Diger
- **Onboarding** — ilk acilista 4 sayfalik tanitim
- **Akor Kutuphanesi** — 28 temel akorun diyagramlari
- **Son Acilanlar** — ana sayfada son goruntulenen sarkilar

---

## Teknik Detaylar

### Mimari
```
SarkiSozu/
├── SarkiSozuApp.swift          # App entry point
├── ContentView.swift           # TabView (5 sekme) + onboarding
├── DesignSystem.swift          # DS namespace (renkler, spacing, tipografi)
├── Theme.swift                 # Tema sabitleri
├── Models/
│   └── Song.swift              # Song, Playlist, RenderBlock, SongDifficulty
├── Services/
│   └── SongDataService.swift   # Veri yukleyici, favoriler, playlistler, arama
├── ViewModels/
│   └── ViewModels.swift        # HomeViewModel, SongDetailViewModel, SettingsViewModel
├── Views/
│   ├── HomeView.swift          # Kesfet sekmesi, quick actions, populer
│   ├── SongsView.swift         # Tum sarkilar, siralama
│   ├── SearchView.swift        # Arama
│   ├── FavoritesView.swift     # Favoriler + playlistler
│   ├── SettingsView.swift      # Ayarlar, hakkinda, geri bildirim
│   ├── SongDetailView.swift    # Sarki detay, akorlar, transpoz
│   ├── ArtistView.swift        # Sanatci sayfasi
│   ├── SetlistView.swift       # Konser modu (fullscreen)
│   ├── CanIPlayView.swift      # Calabilir misin? modu
│   ├── CapoCalculatorView.swift # Kapo hesaplayici
│   ├── PracticeView.swift      # Pratik zamanlayici + istatistik
│   ├── MetronomeView.swift     # Metronom (AVAudioEngine)
│   ├── TunerView.swift         # Akort aleti (YIN pitch detection)
│   ├── ChordDetectorView.swift # Canli akor tespiti (FFT + chroma)
│   ├── OnboardingView.swift    # Ilk acilis tanitim
│   ├── ChordLibraryView.swift  # Akor kutuphanesi
│   ├── PlaylistDetailView.swift # Playlist detay
│   └── Components/
│       ├── Components.swift     # SectionHeader, SongCardView, EmptyState vb.
│       ├── SongRowView.swift    # Sarki satir komponenti
│       └── ChordDiagramView.swift # Canvas akor diyagrami
├── Utils/
│   └── MusicTheory.swift       # Transpoz, nota islemleri
└── Resources/
    ├── cleaned_songs.json      # 4067 sarki veritabani (JSONL, ~32MB)
    └── ChordSVGs/              # Akor SVG dosyalari
```

### Kullanilan Teknolojiler
- **SwiftUI** — Tum UI
- **AVFoundation / AVAudioEngine** — Metronom sesi, mikrofon girisi, pitch detection
- **Accelerate (vDSP)** — FFT, sinyal isleme
- **UserDefaults** — Favori, playlist, pratik oturumu, notlar
- **JSONL parsing** — Satir satir JSON decode (bellek verimli)
- **Canvas API** — Akor diyagramlari cizimi

### Gereksinimler
- iOS 17.0+
- Xcode 16+
- Swift 5.0+
- Mikrofon izni (akort aleti ve akor tespiti icin)

---

## Kurulum

```bash
git clone https://github.com/parzidev/muzik.git
cd muzik/SarkiSozu
open SarkiSozu.xcodeproj
```

Xcode'da hedef cihaz secip **Cmd+R** ile calistirin.

> **Not:** Akort aleti ve akor tespiti ozellikleri gercek cihaz gerektirir. Simulatorde bu ozellikler "Gercek cihazda deneyin" mesaji gosterir.

---

## Veri Kaynagi

Sarki verileri [repertuarim.com](https://www.repertuarim.com) adresinden scrape edilmistir. Her sarki icin:
- Sanatci adi
- Sarki adi
- Orijinal ton, kayitli ton, kolay akor tonu
- Kapo bilgisi
- Ritim kaliplari
- Soz satirlari ile akor pozisyonlari

---

## Yol Haritasi

### v1.1 — Kullanici Deneyimi Iyilestirmeleri
- [ ] App Icon tasarimi (1024x1024)
- [ ] Launch Screen animasyonu
- [ ] Haptic feedback (metronom tick, buton tiklamalari)
- [ ] iPad layout destegi (split view, sidebar)
- [ ] Landscape mod destegi (sarki goruntulerken)
- [ ] Arama gecmisi ve oneriler
- [ ] Sarki paylasma (share sheet)

### v1.2 — Gelismis Muzik Ozellikleri
- [ ] Akor gecis animasyonlari (sarki calarken siradaki akor vurgulama)
- [ ] Strum pattern gosterimi (ritim kaliplari gorsel)
- [ ] Akor kutuphanesini genisletme (sus4, add9, dim, aug vb.)
- [ ] Alternatif pozisyonlar (ayni akorun farkli perdelerdeki tutuslari)
- [ ] Barre akor gostergesi (diyagramda barre cizgisi)
- [ ] Metronom + sarki senkronizasyonu (BPM eslestirme)

### v1.3 — Sosyal & Bulut
- [ ] CloudKit senkronizasyonu (favoriler, playlistler, notlar)
- [ ] iCloud yedekleme
- [ ] Kullanici hesaplari (opsiyonel)
- [ ] Topluluk playlists (paylasilan listeler)
- [ ] Sarki isteme / ekleme onerisi

### v1.4 — Yapay Zeka & Gelismis Analiz
- [ ] Akilli sarki onerisi (calan sarkilara gore)
- [ ] Zorluk bazli ogrenme yolu (basitten zora sarki siralama)
- [ ] Parmak pozisyonu tanima (kamera ile)
- [ ] Ses kaydi + geri dinleme (pratik sirasinda)
- [ ] Akor ilerleme analizi (sarki harmoni yapisi)

### v1.5 — Icerik & Genisleme
- [ ] Offline mod (tum veritabanini indirme)
- [ ] Yeni sarki ekleme arayuzu (kullanici katilimli)
- [ ] Ukulele / bass akor destegi
- [ ] Piyano akor gosterimi
- [ ] Sarki videolari entegrasyonu (YouTube link)
- [ ] Tab (tablature) gorunumu

### v2.0 — Platform Genislemesi
- [ ] watchOS companion app (metronom + akort aleti)
- [ ] macOS Catalyst / native Mac app
- [ ] Widgets (rastgele sarki, pratik hatirlatici)
- [ ] Siri Shortcuts ("Hey Siri, pratik baslat")
- [ ] CarPlay destegi (soz goruntuleyici)
- [ ] Apple Music entegrasyonu

### Teknik Borc & Iyilestirmeler
- [ ] Unit test altyapisi (XCTest)
- [ ] UI testleri (XCUITest)
- [ ] CI/CD pipeline (GitHub Actions)
- [ ] Performans optimizasyonu (lazy loading, pagination)
- [ ] Accessibility (VoiceOver tam destegi)
- [ ] Lokalizasyon altyapisi (Ingilizce, Almanca vb.)
- [ ] Analytics entegrasyonu
- [ ] Crash reporting (Firebase Crashlytics veya benzeri)
- [ ] CoreData'ya gecis (UserDefaults yerine)

---

## Ekran Goruntuleri

> Yakinda eklenecek

---

## Lisans

Bu proje kisisel kullanim icin gelistirilmistir. Sarki verileri repertuarim.com'a aittir.
