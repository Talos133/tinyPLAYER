enum GreekGrade: Int, CaseIterable, Comparable {
    case kappa   = 1
    case iota    = 2
    case theta   = 3
    case eta     = 4
    case zeta    = 5
    case epsilon = 6
    case delta   = 7
    case gamma   = 8
    case beta    = 9
    case alpha   = 10

    var symbol: String {
        switch self {
        case .alpha:   "Α"
        case .beta:    "Β"
        case .gamma:   "Γ"
        case .delta:   "Δ"
        case .epsilon: "Ε"
        case .zeta:    "Ζ"
        case .eta:     "Η"
        case .theta:   "Θ"
        case .iota:    "Ι"
        case .kappa:   "Κ"
        }
    }

    var displayName: String {
        switch self {
        case .alpha:   "Alpha"
        case .beta:    "Beta"
        case .gamma:   "Gamma"
        case .delta:   "Delta"
        case .epsilon: "Epsilon"
        case .zeta:    "Zeta"
        case .eta:     "Eta"
        case .theta:   "Theta"
        case .iota:    "Iota"
        case .kappa:   "Kappa"
        }
    }

    init?(score: Int) {
        self.init(rawValue: score)
    }

    static func < (lhs: GreekGrade, rhs: GreekGrade) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
