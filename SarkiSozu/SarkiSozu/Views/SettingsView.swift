import SwiftUI

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject var dataService: SongDataService
    @StateObject private var viewModel = SettingsViewModel()
    
    // Sheet states
    @State private var showAbout = false
    @State private var showFeedback = false
    
    var body: some View {
        Form {
            Section("Görünüm") {
                // Dark Mode Toggle
                Toggle(isOn: $viewModel.darkMode) {
                    Label {
                        Text("Karanlık Mod").foregroundColor(DS.Color.textPrimary)
                    } icon: {
                        Image(systemName: "moon.fill").foregroundColor(DS.Color.accent)
                    }
                }
                .tint(DS.Color.accent)
                .onChange(of: viewModel.darkMode) { _, isDark in
                    // Sync with DataService if needed locally, though AppStorage handles persistence
                    dataService.darkMode = isDark
                }
                
                // Font Size
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label {
                            Text("Yazı Boyutu").foregroundColor(DS.Color.textPrimary)
                        } icon: {
                            Image(systemName: "textformat.size").foregroundColor(DS.Color.accent)
                        }
                        Spacer()
                        Text("\(Int(viewModel.fontSize)) pt")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("A").font(.caption)
                        Slider(value: $viewModel.fontSize, in: 10...28, step: 1)
                            .tint(DS.Color.accent)
                            .onChange(of: viewModel.fontSize) { _, newVal in
                                dataService.fontSize = Int(newVal)
                            }
                        Text("A").font(.title3)
                    }
                }
                .padding(.vertical, 4)
                
                // Preview Text
                Text("Örnek Şarkı Sözü\nSample Lyrics Text")
                    .font(DS.Typography.lyrics(size: viewModel.fontSize))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(8)
                    .listRowBackground(Color.clear)
            }
            
            Section("Otomatik Kaydırma") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label {
                            Text("Hız").foregroundColor(DS.Color.textPrimary)
                        } icon: {
                            Image(systemName: "speedometer").foregroundColor(DS.Color.accent)
                        }
                        Spacer()
                        Text("\(Int(viewModel.scrollSpeed))x")
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $viewModel.scrollSpeed, in: 1...10, step: 0.5)
                        .tint(DS.Color.accent)
                        .onChange(of: viewModel.scrollSpeed) { _, newVal in
                             dataService.scrollSpeed = Int(newVal)
                        }
                }
                .padding(.vertical, 4)
            }
            
            Section("Araçlar") {
                NavigationLink(destination: ChordLibraryView()) {
                    Label {
                        Text("Akor Kütüphanesi").foregroundColor(DS.Color.textPrimary)
                    } icon: {
                        Image(systemName: "music.note.list").foregroundColor(DS.Color.accent)
                    }
                }
                NavigationLink(destination: CapoCalculatorView()) {
                    Label {
                        Text("Kapo Hesaplayıcı").foregroundColor(DS.Color.textPrimary)
                    } icon: {
                        Image(systemName: "guitars").foregroundColor(.orange)
                    }
                }
                NavigationLink(destination: PracticeView()) {
                    Label {
                        Text("Pratik & İstatistik").foregroundColor(DS.Color.textPrimary)
                    } icon: {
                        Image(systemName: "timer").foregroundColor(.green)
                    }
                }
                NavigationLink(destination: MetronomeView()) {
                    Label {
                        Text("Metronom").foregroundColor(DS.Color.textPrimary)
                    } icon: {
                        Image(systemName: "metronome").foregroundColor(.red)
                    }
                }
                NavigationLink(destination: TunerView()) {
                    Label {
                        Text("Akort Aleti").foregroundColor(DS.Color.textPrimary)
                    } icon: {
                        Image(systemName: "tuningfork").foregroundColor(.purple)
                    }
                }
                NavigationLink(destination: ChordDetectorView()) {
                    Label {
                        Text("Akor Tespiti").foregroundColor(DS.Color.textPrimary)
                    } icon: {
                        Image(systemName: "waveform").foregroundColor(.cyan)
                    }
                }
            }
            
            Section("Uygulama") {
                Button {
                    showAbout = true
                } label: {
                    Label {
                        Text("Hakkında").foregroundColor(DS.Color.textPrimary)
                    } icon: {
                        Image(systemName: "info.circle").foregroundColor(DS.Color.accent)
                    }
                }
                
                Button {
                    showFeedback = true
                } label: {
                    Label {
                        Text("Geri Bildirim").foregroundColor(DS.Color.textPrimary)
                    } icon: {
                        Image(systemName: "envelope").foregroundColor(DS.Color.accent)
                    }
                }
                
                // Version
                HStack {
                    Label {
                        Text("Versiyon").foregroundColor(DS.Color.textPrimary)
                    } icon: {
                        Image(systemName: "hammer").foregroundColor(DS.Color.accent)
                    }
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Ayarlar")
        .sheet(isPresented: $showAbout) {
            AboutView()
        }
        .sheet(isPresented: $showFeedback) {
            FeedbackView()
        }
        .onAppear {
            // Sync initial state if needed
            viewModel.fontSize = Double(dataService.fontSize)
            viewModel.darkMode = dataService.darkMode
            viewModel.scrollSpeed = Double(dataService.scrollSpeed)
        }
    }
}

// MARK: - About View
struct AboutView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DS.Spacing.l) {
                    // App icon placeholder
                    ZStack {
                        RoundedRectangle(cornerRadius: DS.CornerRadius.xlarge)
                            .fill(DS.Color.accentGradient)
                            .frame(width: 100, height: 100)
                        Image(systemName: "music.note.list")
                            .font(.system(size: 48))
                            .foregroundColor(.white)
                    }
                    .padding(.top, DS.Spacing.xl)
                    .shadow(color: DS.Shadow.medium.color, radius: DS.Shadow.medium.radius, x: 0, y: 4)

                    VStack(spacing: 4) {
                        DS.Typography.title1("ŞarkıSözÜ")
                            .foregroundColor(DS.Color.textPrimary)
                        Text("Sürüm 1.0")
                            .font(.subheadline)
                            .foregroundColor(DS.Color.textSecondary)
                    }

                    VStack(alignment: .leading, spacing: DS.Spacing.m) {
                        Text("ŞarkıSözÜ, Türkçe şarkı sözlerini ve gitar akorlarını görüntüleyebileceğiniz ücretsiz bir uygulamadır.")
                            .font(.body)
                            .foregroundColor(DS.Color.textPrimary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, DS.Spacing.l)

                        Text("Özellikler:")
                            .font(.headline)
                            .padding(.top, DS.Spacing.s)
                            .padding(.horizontal, DS.Spacing.m)

                        VStack(alignment: .leading, spacing: DS.Spacing.s) {
                            featureRow(icon: "music.note", text: "Binlerce şarkı sözü ve akor")
                            featureRow(icon: "arrow.up.arrow.down", text: "Ton değiştirme (transpoz)")
                            featureRow(icon: "hand.draw", text: "Akor diyagramları")
                            featureRow(icon: "star.fill", text: "Favori şarkılar")
                            featureRow(icon: "magnifyingglass", text: "Hızlı arama")
                            featureRow(icon: "moon.fill", text: "Karanlık mod desteği")
                        }
                        .padding(.horizontal, DS.Spacing.m)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(DS.CornerRadius.medium)
                        .padding(.horizontal, DS.Spacing.m)
                    }

                    Spacer()
                }
                .padding(.bottom, DS.Spacing.xl)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Hakkında")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") { dismiss() }
                        .foregroundColor(DS.Color.accent)
                }
            }
        }
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: DS.Spacing.m) {
            Image(systemName: icon)
                .foregroundColor(DS.Color.accent)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .foregroundColor(DS.Color.textPrimary)
            Spacer()
        }
        .padding(DS.Spacing.s)
    }
}

// MARK: - Feedback View
struct FeedbackView: View {
    @Environment(\.dismiss) var dismiss
    @State private var feedbackText = ""
    @State private var feedbackType = 0
    @State private var showThankYou = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    Text("Geri bildiriminiz bizim için değerli!")
                        .font(.subheadline)
                        .foregroundColor(DS.Color.textSecondary)
                        .padding(.top, DS.Spacing.s)

                    Picker("Tür", selection: $feedbackType) {
                        Text("Öneri").tag(0)
                        Text("Hata Bildirimi").tag(1)
                        Text("Diğer").tag(2)
                    }
                    .pickerStyle(.segmented)

                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $feedbackText)
                            .frame(minHeight: 150)
                            .padding(8)
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .cornerRadius(DS.CornerRadius.medium)
                        
                        if feedbackText.isEmpty {
                            Text("Mesajınızı buraya yazın...")
                                .foregroundColor(Color(uiColor: .tertiaryLabel))
                                .padding(.horizontal, 12)
                                .padding(.top, 16)
                                .allowsHitTesting(false)
                        }
                    }

                    if showThankYou {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(DS.Color.success)
                            Text("Teşekkürler! Geri bildiriminiz kaydedildi.")
                                .font(.subheadline)
                                .foregroundColor(DS.Color.textSecondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(DS.CornerRadius.medium)
                        .transition(.scale.combined(with: .opacity))
                    }

                    Button(action: {
                        withAnimation {
                            showThankYou = true
                            feedbackText = ""
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            dismiss()
                        }
                    }) {
                        Text("Gönder")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(feedbackText.isEmpty ? Color.gray : DS.Color.accent)
                            .cornerRadius(DS.CornerRadius.medium)
                            .shadow(color: feedbackText.isEmpty ? .clear : DS.Shadow.light.color, radius: 4, y: 2)
                    }
                    .disabled(feedbackText.isEmpty)
                }
                .padding(.horizontal, DS.Spacing.m)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Geri Bildirim")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") { dismiss() }
                        .foregroundColor(DS.Color.accent)
                }
            }
        }
    }
}
