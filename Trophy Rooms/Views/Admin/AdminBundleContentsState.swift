import Foundation
import Combine

final class AdminBundleContentsState: ObservableObject {
    @Published var showGamePicker = false
    @Published var showDLCPicker = false
}
