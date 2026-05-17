import SwiftUI
import UniformTypeIdentifiers

struct DropZone: View {
    @ObservedObject var model: FixerModel
    @State private var isHovering = false

    private var showResultView: Bool {
        !model.items.isEmpty && (!model.isRunning || model.hasSuccessfulOutput)
    }

    var body: some View {
        ZStack {
            dropZoneBackground

            Group {
                if showResultView {
                    DropZoneResultView(model: model)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                } else {
                    DropZoneEmptyState(model: model)
                        .transition(.opacity)
                }
            }
            .padding(Space.x8)
        }
        .frame(minHeight: 480)
        .onHover { isHovering = $0 }
        .onDrop(
            of: [
                UTType.fileURL.identifier,
                UTType.xml.identifier,
                UTType.plainText.identifier,
                UTType.text.identifier,
                "com.apple.finalcutpro.fcpxml",
                "com.apple.finalcutpro.xml"
            ],
            isTargeted: $model.isDropTargeted
        ) { providers in
            model.handleDrop(providers: providers)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: model.isDropTargeted)
        .animation(.easeOut(duration: 0.2), value: isHovering)
        .animation(.easeOut(duration: 0.25), value: showResultView)
    }

    private var dropZoneBackground: some View {
        let shape = RoundedRectangle(cornerRadius: Radius.xl, style: .continuous)
        return shape
            .fill(Color.Theme.bgSurface)
            .overlay {
                shape.fill(isHovering ? Color.white.opacity(0.02) : Color.clear)
            }
            .overlay {
                shape.fill(model.isDropTargeted ? Color.Theme.accentBlue.opacity(0.06) : Color.clear)
            }
            .overlay {
                if model.isDropTargeted {
                    shape.strokeBorder(Color.Theme.accentBlue.opacity(0.5), lineWidth: 1.5)
                }
            }
            .cardShadow()
    }
}

private struct DropZoneEmptyState: View {
    @ObservedObject var model: FixerModel
    @State private var spin = false

    var body: some View {
        VStack(spacing: Space.x5) {
            Spacer(minLength: 0)

            ZStack {
                Circle()
                    .fill(Color.Theme.bgElevated)
                    .overlay {
                        Circle().fill(Color.Theme.accentBlue.opacity(0.12))
                    }
                    .frame(width: 60, height: 60)
                Image(systemName: model.isRunning ? "arrow.triangle.2.circlepath" : "arrow.down.to.line")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(model.isDropTargeted ? Color.Theme.accentLavender : Color.Theme.accentBlue)
                    .rotationEffect(.degrees(model.isRunning && spin ? 360 : 0))
            }
            .scaleEffect(model.isDropTargeted ? 1.05 : 1)

            VStack(spacing: Space.x2) {
                Text(model.isRunning ? "正在修复..." : (model.isDropTargeted ? "松手开始修复" : "拖入 FCPXML / FCPXMLD"))
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color.Theme.textPrimary)
                Text("支持 .fcpxml / .xml / .fcpxmld")
                    .font(Font.Theme.body)
                    .foregroundStyle(Color.Theme.textSecondary)
            }

            PrimaryActionButton(title: "从电脑选择", systemImage: "folder") {
                model.chooseInputs()
            }
            .disabled(model.isRunning)
            .opacity(model.isRunning ? 0.55 : 1)

            Spacer(minLength: 0)

            Text("结果会显示在这里")
                .font(Font.Theme.caption)
                .foregroundStyle(Color.Theme.textTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.linear(duration: 1.1).repeatForever(autoreverses: false)) {
                spin = true
            }
        }
    }
}

private struct DropZoneResultView: View {
    @ObservedObject var model: FixerModel

    private var successfulItems: [ProcessItem] {
        model.items.filter { $0.isSuccess == true }
    }

    private var visibleItems: [ProcessItem] {
        Array(model.items.prefix(12))
    }

    var body: some View {
        VStack(spacing: Space.x5) {
            Spacer(minLength: 0)

            HStack(spacing: Space.x2) {
                Circle()
                    .fill(Color.Theme.accentGreen)
                    .frame(width: 8, height: 8)
                Text("已修复 \(max(model.totalAdjustedAssets, successfulItems.count)) 个 clip")
                    .font(Font.Theme.bodyMedium)
                    .foregroundStyle(Color.Theme.textPrimary)
            }

            Rectangle()
                .fill(Color.Theme.borderSubtle)
                .frame(height: 1)

            ScrollView {
                VStack(spacing: 6) {
                    ForEach(visibleItems) { item in
                        HStack(spacing: Space.x3) {
                            statusDot(for: item)
                            Text(item.displayName)
                                .font(Font.Theme.code)
                                .foregroundStyle(Color.Theme.textPrimary)
                                .lineLimit(1)
                            Spacer()
                            Text(resultLabel(for: item))
                                .font(Font.Theme.code)
                                .foregroundStyle(Color.Theme.textSecondary)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, Space.x2)
                        .frame(height: 24)
                    }
                }
            }
            .frame(maxHeight: 220)

            Rectangle()
                .fill(Color.Theme.borderSubtle)
                .frame(height: 1)

            HStack(spacing: Space.x2) {
                SecondaryActionButton(title: "在 Finder 中显示", systemImage: "arrow.up.right.square", isDisabled: !model.hasSuccessfulOutput) {
                    model.revealLastOutput()
                }
                SecondaryActionButton(title: "再处理一批", systemImage: "plus") {
                    model.resetResults()
                    model.chooseInputs()
                }
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: 520, maxHeight: .infinity)
    }

    private func statusDot(for item: ProcessItem) -> some View {
        Circle()
            .fill(statusColor(for: item))
            .frame(width: 8, height: 8)
    }

    private func statusColor(for item: ProcessItem) -> Color {
        if item.isSuccess == true { return Color.Theme.accentGreen }
        if item.isSuccess == false { return Color.Theme.accentRed }
        return Color.Theme.accentPeach
    }

    private func resultLabel(for item: ProcessItem) -> String {
        if item.isSuccess == true {
            return item.adjustedAssets > 0 ? "\(item.adjustedAssets) assets" : "fixed"
        }
        if item.isSuccess == false {
            return "failed"
        }
        return "running"
    }
}
