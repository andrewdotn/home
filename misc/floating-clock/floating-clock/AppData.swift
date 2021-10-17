import Combine
import SwiftUI

final class AppData: ObservableObject {
    @Published var text: String = ""
}
