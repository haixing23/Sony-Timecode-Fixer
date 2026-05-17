import SwiftUI

struct Sidebar: View {
    @ObservedObject var model: FixerModel

    var body: some View {
        VStack(alignment: .leading, spacing: Space.x8) {
            outputSection
            workflowSection
            Spacer()
            footer
        }
    }

    private var outputSection: some View {
        VStack(alignment: .leading, spacing: Space.x3) {
            SectionHeader(title: "Output")
            OutputPicker(selection: $model.outputMode)

            if model.outputMode == "custom" {
                SecondaryActionButton(title: model.customOutputURL?.lastPathComponent ?? "选择输出文件夹", systemImage: "folder.badge.gearshape") {
                    model.chooseOutputFolder()
                }
            }

            HStack(alignment: .top, spacing: Space.x3) {
                Rectangle()
                    .fill(Color.Theme.accentBlue)
                    .frame(width: 2)
                Text(outputHint)
                    .font(Font.Theme.body)
                    .foregroundStyle(Color.Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var workflowSection: some View {
        VStack(alignment: .leading, spacing: Space.x3) {
            SectionHeader(title: "Workflow")
            WorkflowCodeBlock()
        }
    }

    private var footer: some View {
        Text("从 Final Cut Pro 拖出时，如果系统提供的是实际 .fcpxml/.fcpxmld 文件路径，这里可以直接处理。")
            .font(Font.Theme.caption)
            .foregroundStyle(Color.Theme.textTertiary)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var outputHint: String {
        if model.outputMode == "source" {
            return "拖入文件会自动在同目录生成 Fixed 结果"
        }
        return model.customOutputURL?.path ?? "选择一个文件夹后，所有结果都会写入那里"
    }
}
