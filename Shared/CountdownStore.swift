import Foundation

struct CountdownStore {
    private let defaults: UserDefaults
    private static let deadlineKey = "countdown.deadline"

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    init() {
        guard let group = Bundle.main.object(forInfoDictionaryKey: "CountdownAppGroup") as? String,
              !group.isEmpty,
              let defaults = UserDefaults(suiteName: group) else {
            preconditionFailure("Configure CountdownAppGroup and matching App Group entitlements.")
        }
        self.defaults = defaults
    }

    var deadline: Date {
        guard let stored = defaults.object(forKey: Self.deadlineKey) as? Date else {
            return Countdown.defaultDeadline
        }
        return stored
    }

    func save(_ deadline: Date) {
        defaults.set(deadline, forKey: Self.deadlineKey)
    }
}
