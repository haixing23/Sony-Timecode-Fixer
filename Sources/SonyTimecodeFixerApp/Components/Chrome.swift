import SwiftUI

struct AppIconBadge: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.Theme.accentRed, Color.Theme.accentPeach],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white)
        }
        .frame(width: 44, height: 44)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: Color.Theme.accentRed.opacity(0.18), radius: 16, x: 0, y: 6)
    }
}

struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title.uppercased())
            .font(Font.Theme.section)
            .tracking(1.0)
            .foregroundStyle(Color.Theme.textTertiary)
    }
}

struct PrimaryActionButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void
    @State private var isHovering = false
    @State private var isPressing = false

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .labelStyle(.titleAndIcon)
                .padding(.horizontal, Space.x5)
                .padding(.vertical, Space.x3)
                .background(
                    LinearGradient(
                        colors: [Color.Theme.accentBlue, Color.Theme.accentLavender],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .brightness(isHovering ? 0.05 : 0)
                )
                .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
                .shadow(color: Color.Theme.accentBlue.opacity(isPressing ? 0.18 : 0.30), radius: isPressing ? 8 : 16, x: 0, y: 4)
                .scaleEffect(isPressing ? 0.98 : 1)
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressing = true }
                .onEnded { _ in isPressing = false }
        )
        .animation(.easeOut(duration: 0.15), value: isHovering)
        .animation(.easeOut(duration: 0.1), value: isPressing)
    }
}

struct SecondaryActionButton: View {
    let title: String
    let systemImage: String
    var isDisabled = false
    let action: () -> Void
    @State private var isHovering = false
    @State private var isPressing = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .medium))
                Text(title)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundStyle(isDisabled ? Color.Theme.textDisabled : Color.Theme.textPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, Space.x2)
            .background(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .fill(Color.Theme.bgElevated)
                    .overlay {
                        RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                            .fill(isHovering && !isDisabled ? Color.white.opacity(0.04) : Color.clear)
                    }
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .stroke(isHovering && !isDisabled ? Color.Theme.borderDefault : Color.Theme.borderSubtle, lineWidth: 1)
            )
            .scaleEffect(isPressing ? 0.98 : 1)
            .opacity(isDisabled ? 0.4 : 1)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .onHover { isHovering = $0 }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in if !isDisabled { isPressing = true } }
                .onEnded { _ in isPressing = false }
        )
        .animation(.easeOut(duration: 0.15), value: isHovering)
        .animation(.easeOut(duration: 0.1), value: isPressing)
    }
}
