import SwiftUI

struct WorkflowCodeBlock: View {
    private let rows: [(String, String, Color)] = [
        ("read", "FCPXML / Info.fcpxml", Color.Theme.accentBlue),
        ("match", "Sony M01.XML | MP4 meta", Color.Theme.accentMauve),
        ("write", "Fixed FCPXML(D)", Color.Theme.accentPeach),
        ("done", "ready for Final Cut Pro", Color.Theme.accentGreen)
    ]

    var body: some View {
        VStack(spacing: 0) {
            FakeTitleBar(fileName: "pipeline.swift")
            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                    HStack(spacing: Space.x4) {
                        Text("\(index + 1)")
                            .font(Font.Theme.code)
                            .foregroundStyle(Color.Theme.textTertiary)
                            .frame(width: 24, alignment: .trailing)
                        Text(row.0)
                            .font(Font.Theme.code)
                            .foregroundStyle(row.2)
                            .frame(width: 42, alignment: .leading)
                        Text(row.1)
                            .font(Font.Theme.code)
                            .foregroundStyle(Color.Theme.textPrimary)
                            .lineLimit(1)
                        Spacer(minLength: 0)
                    }
                    .frame(height: 24)
                    .padding(.horizontal, Space.x4)
                }
            }
            .padding(.vertical, Space.x3)
        }
        .background(Color.Theme.bgCode)
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
    }
}

struct FakeTitleBar: View {
    let fileName: String

    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(Color.Theme.trafficRed).frame(width: 8, height: 8)
            Circle().fill(Color.Theme.trafficYellow).frame(width: 8, height: 8)
            Circle().fill(Color.Theme.trafficGreen).frame(width: 8, height: 8)
            Spacer()
            Text(fileName)
                .font(Font.Theme.codeLabel)
                .foregroundStyle(Color.Theme.textTertiary)
        }
        .frame(height: 28)
        .padding(.horizontal, Space.x3)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.Theme.borderSubtle)
                .frame(height: 1)
        }
    }
}
