import SwiftUI
import PhotosUI
import UIKit
struct ProfileView: View {
    var onFavoritesClick: () -> Void = {}
    var onHistoryClick: () -> Void = {}
    var onLogoutClick: () -> Void = {}
    // MARK: - Estados
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profileImage: UIImage?
    @State private var userProfile: UserResponse?
    @State private var selectedAvatar = "default"
    @State private var showAvatarPicker = false
    @State private var showSettings = false
    @State private var selectedSection: ProfileSection?
    @State private var isUploading = false
    @State private var isLoading = true
    @State private var profileError: String?
    @State private var favoritesCount: Int?
    @State private var reportsCount: Int?
    @State private var searchesCount: Int?
    // MARK: - Colores
    private let navy = Color(
        red: 0.07, green: 0.10, blue: 0.20
    )
    private let muted = Color(
        red: 0.38, green: 0.43, blue: 0.54
    )
    private let blue = Color(
        red: 0.02, green: 0.43, blue: 1.0
    )
    // MARK: - Avatares
    private let avatarOptions = [
        "default",
        "avatar_1",
        "avatar_2",
        "avatar_3",
        "avatar_4",
        "avatar_5",
        "avatar_6"
    ]
    private let avatarSymbols: [String: String] = [
        "default": "person.crop.circle.fill",
        "avatar_1": "person.fill",
        "avatar_2": "face.smiling.fill",
        "avatar_3": "figure.walk",
        "avatar_4": "car.side.fill",
        "avatar_5": "steeringwheel",
        "avatar_6": "bolt.circle.fill"
    ]
    // MARK: - Datos del usuario
    private var userName: String {
        userProfile?.name
            ?? UserSession.getName()
            ?? "Usuario"
    }
    private var userEmail: String {
        userProfile?.email
            ?? UserSession.getEmail()
            ?? "Correo no disponible"
    }
    // MARK: - Vista principal
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                header
                accountCard
                statisticsCard
                menuCard
                logoutButton
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 30)
        }
        .background(
            Color(red: 0.985, green: 0.989, blue: 1)
        )
        .navigationBarBackButtonHidden(true)
        // Selector de avatares
        .sheet(isPresented: $showAvatarPicker) {
            avatarPicker
        }
        // Configuración
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                placeholder("Configuración")
            }
        }
        // Otras secciones
        .sheet(item: $selectedSection) { section in
            NavigationStack {
                placeholder(section.title)
            }
        }
        // Descargar perfil al abrir la pantalla
        .task {
            await loadProfile()
            await loadProfileStats()
        }
        // Detectar fotografía seleccionada
        .onChange(of: selectedPhoto) { _, newValue in
            guard let newValue else { return }
            Task {
                await processSelectedPhoto(newValue)
            }
        }
        // Mostrar errores
        .alert(
            "Error de perfil",
            isPresented: Binding(
                get: { profileError != nil },
                set: {
                    if !$0 {
                        profileError = nil
                    }
                }
            )
        ) {
            Button("Aceptar", role: .cancel) {
                profileError = nil
            }
        } message: {
            Text(profileError ?? "")
        }
        // Indicador de carga
        .overlay {
            if isUploading {
                ZStack {
                    Color.black.opacity(0.25)
                        .ignoresSafeArea()
                    VStack(spacing: 14) {
                        ProgressView()
                            .tint(blue)
                        Text("Guardando imagen...")
                            .font(.system(size: 14))
                    }
                    .padding(28)
                    .background(
                        .white,
                        in: RoundedRectangle(cornerRadius: 18)
                    )
                }
            }
        }
    }
    // MARK: - Encabezado
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Mi perfil")
                    .font(.system(size: 25, weight: .bold))
                    .foregroundStyle(navy)
                Text("Gestioná tu cuenta y preferencias.")
                    .font(.system(size: 14))
                    .foregroundStyle(muted)
            }
            Spacer()
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 23))
                    .foregroundStyle(muted)
                    .frame(width: 40, height: 40)
            }
        }
    }
    // MARK: - Tarjeta del usuario
    private var accountCard: some View {
        HStack(spacing: 16) {
            Button {
                showAvatarPicker = true
            } label: {
                ZStack(alignment: .bottomTrailing) {
                    avatarImage
                        .frame(width: 94, height: 94)
                        .clipShape(Circle())
                    Image(systemName: "pencil")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(blue, in: Circle())
                        .overlay(
                            Circle()
                                .stroke(.white, lineWidth: 2)
                        )
                }
            }
            .buttonStyle(.plain)
            .disabled(isUploading)
            VStack(alignment: .leading, spacing: 8) {
                Text(userName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(navy)
                    .lineLimit(1)
                Text(userEmail)
                    .font(.system(size: 12))
                    .foregroundStyle(muted)
                    .lineLimit(2)
                if !isLoading && userProfile != nil {
                    Label(
                        "Cuenta ParkAI",
                        systemImage: "checkmark.seal.fill"
                    )
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.green)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Color.green.opacity(0.09),
                        in: Capsule()
                    )
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .foregroundStyle(muted)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .profileCard()
    }
    // MARK: - Imagen de perfil
    @ViewBuilder
    private var avatarImage: some View {
        if let profileImage {
            Image(uiImage: profileImage)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                Circle()
                    .fill(blue.opacity(0.09))
                Image(
                    systemName: avatarSymbols[selectedAvatar]
                        ?? "person.crop.circle.fill"
                )
                .resizable()
                .scaledToFit()
                .foregroundStyle(blue)
                .padding(20)
            }
        }
    }
    // MARK: - Estadísticas
    private var statisticsCard: some View {
        HStack(spacing: 0) {
            statistic(
                favoritesCount.map(String.init) ?? "—",
                "Favoritos",
                "bookmark.fill",
                blue
            )
            Rectangle()
                .fill(Color.gray.opacity(0.15))
                .frame(width: 1, height: 70)
            statistic(
                reportsCount.map(String.init) ?? "—",
                "Reportes",
                "chart.bar.fill",
                .green
            )
            Rectangle()
                .fill(Color.gray.opacity(0.15))
                .frame(width: 1, height: 70)
            statistic(
                searchesCount.map(String.init) ?? "—",
                "Búsquedas",
                "clock",
                .purple
            )
        }
        .padding(.vertical, 20)
        .profileCard()
    }
    private func statistic(
        _ value: String,
        _ title: String,
        _ symbol: String,
        _ color: Color
    ) -> some View {
        VStack(spacing: 7) {
            Image(systemName: symbol)
                .font(.system(size: 19))
                .foregroundStyle(color)
                .frame(width: 40, height: 40)
                .background(
                    color.opacity(0.10),
                    in: Circle()
                )
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(navy)
            Text(title)
                .font(.system(size: 12))
                .foregroundStyle(muted)
        }
        .frame(maxWidth: .infinity)
    }
    // MARK: - Menú de perfil
    private var menuCard: some View {
        VStack(spacing: 0) {
            menuRow(
                "Mis favoritos",
                "Lugares guardados",
                "heart",
                blue
            ) {
                onFavoritesClick()
            }
            Divider().padding(.leading, 60)
            menuRow(
                "Historial de búsquedas",
                "Tus búsquedas recientes",
                "clock",
                .purple
            ) {
                onHistoryClick()
            }
            Divider().padding(.leading, 60)
            menuRow(
                "Mis reportes",
                "Reportes enviados por vos",
                "chart.bar",
                .green
            ) {
                selectedSection = .reports
            }
            Divider().padding(.leading, 60)
            menuRow(
                "Notificaciones",
                "Preferencias y configuración",
                "bell",
                .orange
            ) {
                selectedSection = .notifications
            }
            Divider().padding(.leading, 60)
            menuRow(
                "Privacidad",
                "Seguridad y datos personales",
                "shield",
                blue
            ) {
                selectedSection = .privacy
            }
            Divider().padding(.leading, 60)
            menuRow(
                "Ayuda y soporte",
                "Preguntas frecuentes",
                "questionmark.circle",
                muted
            ) {
                selectedSection = .help
            }
            Divider().padding(.leading, 60)
            menuRow(
                "Acerca de ParkAI",
                "Versión 1.0.0",
                "info.circle",
                muted
            ) {
                selectedSection = .about
            }
        }
        .profileCard()
    }
    private func menuRow(
        _ title: String,
        _ subtitle: String,
        _ symbol: String,
        _ color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 18) {
                Image(systemName: symbol)
                    .font(.system(size: 20))
                    .foregroundStyle(color)
                    .frame(width: 30)
                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(navy)
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(muted)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundStyle(muted)
            }
            .padding(.horizontal, 18)
            .frame(height: 65)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    // MARK: - Cerrar sesión
    private var logoutButton: some View {
        Button(action: onLogoutClick) {
            Label(
                "Cerrar sesión",
                systemImage: "rectangle.portrait.and.arrow.right"
            )
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
        }
        .background(
            .white,
            in: RoundedRectangle(cornerRadius: 18)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.gray.opacity(0.10))
        )
    }
    // MARK: - Selector de avatar y fotografía
    private var avatarPicker: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Text("Elegí tu imagen de perfil")
                        .font(.title3.bold())
                    Text(
                        "Seleccioná un avatar de ParkAI o utilizá una fotografía de tu galería."
                    )
                    .font(.system(size: 14))
                    .foregroundStyle(muted)
                    .multilineTextAlignment(.center)
                    LazyVGrid(
                        columns: Array(
                            repeating: GridItem(.flexible()),
                            count: 3
                        ),
                        spacing: 24
                    ) {
                        ForEach(avatarOptions, id: \.self) { option in
                            Button {
                                Task {
                                    await selectAvatar(option)
                                }
                            } label: {
                                Image(
                                    systemName: avatarSymbols[option]
                                        ?? "person.fill"
                                )
                                .font(.system(size: 36))
                                .foregroundStyle(blue)
                                .frame(width: 85, height: 85)
                                .background(
                                    blue.opacity(0.08),
                                    in: Circle()
                                )
                                .overlay(
                                    Circle()
                                        .stroke(
                                            selectedAvatar == option
                                            && profileImage == nil
                                            ? blue : .clear,
                                            lineWidth: 2
                                        )
                                )
                            }
                            .disabled(isUploading)
                        }
                    }
                    Divider()
                    PhotosPicker(
                        selection: $selectedPhoto,
                        matching: .images
                    ) {
                        Label(
                            "Elegir foto de mi galería",
                            systemImage: "photo"
                        )
                        .font(
                            .system(size: 15, weight: .semibold)
                        )
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundStyle(.white)
                        .background(
                            blue,
                            in: RoundedRectangle(cornerRadius: 14)
                        )
                    }
                    .disabled(isUploading)
                }
                .padding(24)
            }
            .navigationTitle("Foto de perfil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") {
                        showAvatarPicker = false
                    }
                }
            }
        }
    }
    // MARK: - Obtener usuario actual
    private func fetchCurrentProfile() async throws -> UserResponse {
        guard let token = TokenManager.getToken(),
              !token.isEmpty else {
            throw ProfileAPIError.noToken
        }
        let result = try await AuthAPIClient.getCurrentUser(
            token: token
        )
        guard result.statusCode == 200,
              let user = result.user else {
            throw ProfileAPIError.serverError(
                result.statusCode
            )
        }
        return user
    }
    // MARK: - Cargar perfil del backend
    @MainActor
    private func loadProfile() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let user = try await fetchCurrentProfile()
            userProfile = user
            UserSession.saveUser(user)
            if user.hasProfileImage == true {
                profileImage = try await ProfileAPIClient.getPhoto()
            } else {
                profileImage = nil
                selectedAvatar = user.avatarKey ?? "default"
            }
        } catch {
            profileError = error.localizedDescription
        }
    }
    // MARK: - Procesar foto elegida
    @MainActor
    private func processSelectedPhoto(
        _ selectedItem: PhotosPickerItem
    ) async {
        do {
            guard let data = try await selectedItem.loadTransferable(
                type: Data.self
            ), let image = UIImage(data: data) else {
                throw ProfileAPIError.invalidImage
            }
            await saveProfileImage(image)
        } catch {
            profileError = error.localizedDescription
        }
        selectedPhoto = nil
    }
    // MARK: - Subir foto al backend
    @MainActor
    private func saveProfileImage(
        _ image: UIImage
    ) async {
        isUploading = true
        defer { isUploading = false }
        do {
            try await ProfileAPIClient.uploadPhoto(image)
            profileImage = image
            showAvatarPicker = false
            let user = try await fetchCurrentProfile()
            userProfile = user
            UserSession.saveUser(user)
        } catch {
            profileError = error.localizedDescription
        }
    }
    // MARK: - Cambiar avatar en el backend
    @MainActor
    private func selectAvatar(
        _ option: String
    ) async {
        isUploading = true
        defer { isUploading = false }
        do {
            try await ProfileAPIClient.selectAvatar(option)
            selectedAvatar = option
            profileImage = nil
            showAvatarPicker = false
            let user = try await fetchCurrentProfile()
            userProfile = user
            UserSession.saveUser(user)
        } catch {
            profileError = error.localizedDescription
        }
    }
    // MARK: - Pantallas pendientes
    private func placeholder(
        _ title: String
    ) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "wrench.and.screwdriver")
                .font(.system(size: 40))
                .foregroundStyle(blue)
            Text("Próximamente")
                .font(.title2.bold())
            Text(
                "Estamos preparando esta sección de ParkAI."
            )
            .foregroundStyle(muted)
            .multilineTextAlignment(.center)
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
        .padding()
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Cerrar") {
                    selectedSection = nil
                    showSettings = false
                }
            }
        }
    }
    @MainActor
    private func loadProfileStats() async {
        do {
            let stats = try await ProfileStatsAPIClient.getStats()
            favoritesCount = stats.favoritesCount
            reportsCount = stats.reportsCount
            searchesCount = stats.searchesCount
        } catch {
            print("Error cargando estadísticas: \(error)")
        }
    }

}
// MARK: - Secciones del perfil
private enum ProfileSection: String, Identifiable {
    case reports
    case notifications
    case privacy
    case help
    case about
    var id: String { rawValue }
    var title: String {
        switch self {
        case .reports:
            return "Mis reportes"
        case .notifications:
            return "Notificaciones"
        case .privacy:
            return "Privacidad"
        case .help:
            return "Ayuda y soporte"
        case .about:
            return "Acerca de ParkAI"
        }
    }
}
// MARK: - Estilo de tarjetas
private extension View {
    func profileCard() -> some View {
        self
            .background(
                .white,
                in: RoundedRectangle(cornerRadius: 19)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 19)
                    .stroke(Color.gray.opacity(0.07))
            )
            .shadow(
                color: .black.opacity(0.035),
                radius: 12,
                y: 4
            )
    }
}
// MARK: - Preview
#Preview {
    NavigationStack {
        ProfileView()
    }
}
