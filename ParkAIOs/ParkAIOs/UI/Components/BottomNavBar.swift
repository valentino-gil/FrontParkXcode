import SwiftUI

enum BottomNavItem {
    case mapa
    case favoritos
    case reportar
    case historial
    case perfil

    var label: String {
        switch self {
        case .mapa: return "Mapa"
        case .favoritos: return "Favoritos"
        case .reportar: return "Reportar"
        case .historial: return "Historial"
        case .perfil: return "Perfil"
        }
    }

    func iconName(selected: Bool) -> String {
        switch self {
        case .mapa: return selected ? "map.fill" : "map"
        case .favoritos: return selected ? "heart.fill" : "heart"
        case .reportar: return "plus" // se usa aparte, en el botón central
        case .historial: return selected ? "clock.fill" : "clock"
        case .perfil: return selected ? "person.fill" : "person"
        }
    }
}

struct BottomNavBar: View {
    let selectedItem: BottomNavItem
    let onItemSelected: (BottomNavItem) -> Void

    private let inactiveColor = Color(red: 0.612, green: 0.639, blue: 0.686) // #9CA3AF

    var body: some View {
        HStack(alignment: .center) {
            NavBarItem(item: .mapa, selected: selectedItem == .mapa, onClick: onItemSelected, inactiveColor: inactiveColor)

            Spacer()

            NavBarItem(item: .favoritos, selected: selectedItem == .favoritos, onClick: onItemSelected, inactiveColor: inactiveColor)

            Spacer()

            // Botón central destacado
            Button(action: { onItemSelected(.reportar) }) {
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .fill(Color.parkaiBlue)
                            .frame(width: 52, height: 52)
                        Image(systemName: "plus")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    Text("Reportar")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.parkaiBlue)
                }
            }

            Spacer()

            NavBarItem(item: .historial, selected: selectedItem == .historial, onClick: onItemSelected, inactiveColor: inactiveColor)

            Spacer()

            NavBarItem(item: .perfil, selected: selectedItem == .perfil, onClick: onItemSelected, inactiveColor: inactiveColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .background(
            Color.white
                .shadow(color: .black.opacity(0.08), radius: 4, y: -2) // aprox. tonalElevation de Material3
        )
    }
}

private struct NavBarItem: View {
    let item: BottomNavItem
    let selected: Bool
    let onClick: (BottomNavItem) -> Void
    let inactiveColor: Color

    var body: some View {
        Button(action: { onClick(item) }) {
            VStack(spacing: 4) {
                Image(systemName: item.iconName(selected: selected))
                    .font(.system(size: 24))
                Text(item.label)
                    .font(.system(size: 11, weight: selected ? .semibold : .regular))
            }
            .foregroundColor(selected ? .parkaiBlue : inactiveColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
    }
}

#Preview {
    BottomNavBar(selectedItem: .mapa, onItemSelected: { _ in })
}
