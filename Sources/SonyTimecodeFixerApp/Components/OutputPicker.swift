import SwiftUI

struct OutputPicker: View {
    @Binding var selection: String
    @Namespace private var namespace

    var body: some View {
        HStack(spacing: 0) {
            segment(title: "原文件旁边", value: "source")
            segment(title: "指定文件夹", value: "custom")
        }
        .padding(Space.x1)
        .background(Color.Theme.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
    }

    private func segment(title: String, value: String) -> some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                selection = value
            }
        } label: {
            Text(title)
                .font(Font.Theme.bodyMedium)
                .foregroundStyle(selection == value ? Color.Theme.textPrimary : Color.Theme.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background {
                    if selection == value {
                        RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                            .fill(Color.Theme.bgElevated)
                            .overlay {
                                RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                                    .fill(Color.Theme.accentBlue.opacity(0.10))
                            }
                            .matchedGeometryEffect(id: "segment", in: namespace)
                    }
                }
        }
        .buttonStyle(.plain)
    }
}
