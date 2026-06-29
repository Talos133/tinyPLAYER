enum WindowMode: Equatable {
    case normal
    case mini
    case tucked(ScreenEdge)
}

enum ScreenEdge: String, Codable {
    case top, bottom, leading, trailing
}
