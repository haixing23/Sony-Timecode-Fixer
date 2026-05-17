import Foundation

struct ProcessItem: Identifiable {
    let id = UUID()
    let url: URL
    var state: String
    var detail: String
    var isSuccess: Bool?
    var outputURL: URL?
    var adjustedAssets: Int = 0

    var displayName: String {
        url.lastPathComponent
    }
}
