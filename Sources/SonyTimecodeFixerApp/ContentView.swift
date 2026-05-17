import AppKit
import SwiftUI

struct ContentView: View {
    @ObservedObject var model: FixerModel

    var body: some View {
        VStack(spacing: 0) {
            titleBarSpace
            header
            mainArea
            footer
        }
        .frame(minWidth: 1080, idealWidth: 1180, minHeight: 720)
        .background(Color.Theme.bgBase)
        .preferredColorScheme(.dark)
        .onAppear {
            configureWindow()
        }
    }

    private var titleBarSpace: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(height: 28)
    }

    private var header: some View {
        HStack(spacing: Space.x3) {
            AppIconBadge()

            VStack(alignment: .leading, spacing: 2) {
                Text("Sony Timecode Fixer")
                    .font(Font.Theme.title)
                    .foregroundStyle(Color.Theme.textPrimary)
                Text("修复 Final Cut Pro 中 Sony MP4 的起始时间码")
                    .font(Font.Theme.subtitle)
                    .foregroundStyle(Color.Theme.textSecondary)
            }

            Spacer()

            HStack(spacing: Space.x2) {
                SecondaryActionButton(title: "选择文件", systemImage: "doc.badge.plus") {
                    model.chooseInputs()
                }
                SecondaryActionButton(title: "显示结果", systemImage: "arrow.up.right.square", isDisabled: !model.hasSuccessfulOutput) {
                    model.revealLastOutput()
                }
            }
        }
        .padding(.horizontal, Space.x8)
        .padding(.vertical, Space.x6)
    }

    private var mainArea: some View {
        HStack(alignment: .top, spacing: Space.x5) {
            DropZone(model: model)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Sidebar(model: model)
                .frame(width: 380)
        }
        .padding(.horizontal, Space.x8)
        .padding(.top, Space.x2)
        .padding(.bottom, Space.x6)
    }

    private var footer: some View {
        HStack {
            Spacer()
            Text("FCPXML and FCPXMLD stay local. No network, no upload.")
                .font(Font.Theme.caption)
                .foregroundStyle(Color.Theme.textTertiary)
        }
        .padding(.horizontal, Space.x8)
        .padding(.bottom, Space.x6)
    }

    private func configureWindow() {
        DispatchQueue.main.async {
            guard let window = NSApp.windows.first else { return }
            window.isMovableByWindowBackground = true
            window.titlebarAppearsTransparent = true
            window.backgroundColor = NSColor(Color.Theme.bgBase)
        }
    }
}
