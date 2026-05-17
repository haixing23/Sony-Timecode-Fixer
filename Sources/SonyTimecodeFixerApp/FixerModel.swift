import AppKit
import Foundation
import UniformTypeIdentifiers

final class FixerModel: ObservableObject {
    @Published var items: [ProcessItem] = []
    @Published var isDropTargeted = false
    @Published var isRunning = false
    @Published var outputMode = "source"
    @Published var customOutputURL: URL?

    var hasSuccessfulOutput: Bool {
        items.contains { $0.isSuccess == true }
    }

    var totalAdjustedAssets: Int {
        items.filter { $0.isSuccess == true }.reduce(0) { $0 + max($1.adjustedAssets, 0) }
    }

    private var scriptURL: URL {
        Bundle.main.url(forResource: "sony_timecode_fixer", withExtension: "py")!
    }

    func chooseInputs() {
        let panel = NSOpenPanel()
        panel.title = "选择 FCPXML 或 FCPXMLD"
        panel.message = "选择一个或多个需要修复 Sony 时间码的项目"
        panel.allowsMultipleSelection = true
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.treatsFilePackagesAsDirectories = false
        panel.allowedContentTypes = [
            UTType(filenameExtension: "fcpxml") ?? .xml,
            UTType(filenameExtension: "fcpxmld") ?? .package,
            .xml,
            .package,
            .folder
        ]
        if panel.runModal() == .OK {
            process(panel.urls)
        }
    }

    func chooseOutputFolder() {
        let panel = NSOpenPanel()
        panel.title = "选择输出文件夹"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK {
            customOutputURL = panel.url
            outputMode = "custom"
        }
    }

    func handleDrop(providers: [NSItemProvider]) -> Bool {
        var accepted = false
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                accepted = true
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                    let url: URL?
                    if let data = item as? Data {
                        url = URL(dataRepresentation: data, relativeTo: nil)
                    } else if let itemURL = item as? URL {
                        url = itemURL
                    } else {
                        url = nil
                    }
                    if let url {
                        DispatchQueue.main.async { self.process([url]) }
                    }
                }
            } else if let xmlType = Self.xmlDropType(for: provider) {
                accepted = true
                provider.loadItem(forTypeIdentifier: xmlType, options: nil) { item, _ in
                    guard let text = Self.text(from: item), text.contains("<fcpxml") else { return }
                    DispatchQueue.main.async { self.processDroppedXML(text) }
                }
            }
        }
        return accepted
    }

    func process(_ urls: [URL], forcedOutputURL: URL? = nil) {
        let filtered = urls.filter { Self.isSupported($0) }
        guard !filtered.isEmpty else {
            NSSound.beep()
            return
        }

        for url in filtered {
            items.insert(ProcessItem(url: url, state: "等待处理", detail: url.path, isSuccess: nil), at: 0)
        }

        isRunning = true
        DispatchQueue.global(qos: .userInitiated).async {
            for url in filtered {
                self.runOne(url, forcedOutputURL: forcedOutputURL)
            }
            DispatchQueue.main.async {
                self.isRunning = false
            }
        }
    }

    func processDroppedXML(_ text: String) {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Sony Timecode Fixer", isDirectory: true)
        try? FileManager.default.createDirectory(at: support, withIntermediateDirectories: true)

        let inputURL = support.appendingPathComponent("Dropped Project.fcpxml")
        do {
            try text.write(to: inputURL, atomically: true, encoding: .utf8)
        } catch {
            items.insert(ProcessItem(url: inputURL, state: "保存失败", detail: error.localizedDescription, isSuccess: false), at: 0)
            return
        }

        let outputURL = outputMode == "custom" ? customOutputURL : FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first
        process([inputURL], forcedOutputURL: outputURL)
    }

    func revealLastOutput() {
        guard let outputURL = items.first(where: { $0.isSuccess == true })?.outputURL else { return }
        NSWorkspace.shared.activateFileViewerSelecting([outputURL])
    }

    func resetResults() {
        items.removeAll()
    }

    private func runOne(_ url: URL, forcedOutputURL: URL? = nil) {
        update(url, state: "正在修复", detail: url.path, isSuccess: nil)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        var arguments = [scriptURL.path]
        if let forcedOutputURL {
            arguments += ["--output-dir", forcedOutputURL.path]
        } else if outputMode == "custom", let customOutputURL {
            arguments += ["--output-dir", customOutputURL.path]
        }
        arguments.append(url.path)
        process.arguments = arguments

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            update(url, state: "启动失败", detail: error.localizedDescription, isSuccess: false)
            return
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if process.terminationStatus == 0 {
            let parsed = Self.parseProcessOutput(output)
            update(
                url,
                state: "已完成",
                detail: output.isEmpty ? "修复完成" : output,
                isSuccess: true,
                outputURL: parsed.outputURL,
                adjustedAssets: parsed.adjustedAssets
            )
        } else {
            update(url, state: "处理失败", detail: output.isEmpty ? "请检查文件格式与 Sony 元数据" : output, isSuccess: false)
        }
    }

    private func update(
        _ url: URL,
        state: String,
        detail: String,
        isSuccess: Bool?,
        outputURL: URL? = nil,
        adjustedAssets: Int = 0
    ) {
        DispatchQueue.main.async {
            if let index = self.items.firstIndex(where: { $0.url == url && $0.isSuccess == nil }) ?? self.items.firstIndex(where: { $0.url == url }) {
                self.items[index].state = state
                self.items[index].detail = detail
                self.items[index].isSuccess = isSuccess
                self.items[index].outputURL = outputURL
                self.items[index].adjustedAssets = adjustedAssets
            }
        }
    }

    private static func isSupported(_ url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        return ext == "fcpxml" || ext == "fcpxmld" || ext == "xml" || url.hasDirectoryPath
    }

    private static func xmlDropType(for provider: NSItemProvider) -> String? {
        let preferred = [
            UTType.xml.identifier,
            UTType.plainText.identifier,
            UTType.text.identifier,
            "com.apple.finalcutpro.fcpxml",
            "com.apple.finalcutpro.xml"
        ]
        for type in preferred where provider.hasItemConformingToTypeIdentifier(type) {
            return type
        }
        return provider.registeredTypeIdentifiers.first { $0.localizedCaseInsensitiveContains("xml") }
    }

    private static func text(from item: NSSecureCoding?) -> String? {
        if let text = item as? String {
            return text
        }
        if let data = item as? Data {
            return String(data: data, encoding: .utf8)
        }
        if let url = item as? URL {
            return try? String(contentsOf: url, encoding: .utf8)
        }
        return nil
    }

    private static func parseProcessOutput(_ output: String) -> (outputURL: URL?, adjustedAssets: Int) {
        let firstLine = output.components(separatedBy: .newlines).first ?? ""
        let pathText = firstLine.components(separatedBy: " (").first ?? ""
        let outputURL = pathText.isEmpty ? nil : URL(fileURLWithPath: pathText)

        let pattern = #"(\d+)\s+Sony asset"#
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(firstLine.startIndex..<firstLine.endIndex, in: firstLine)
        let match = regex?.firstMatch(in: firstLine, range: range)
        let adjustedAssets: Int
        if let match, let assetRange = Range(match.range(at: 1), in: firstLine) {
            adjustedAssets = Int(firstLine[assetRange]) ?? 0
        } else {
            adjustedAssets = 0
        }

        return (outputURL, adjustedAssets)
    }
}
