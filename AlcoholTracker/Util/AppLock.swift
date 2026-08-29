import Combine
import Foundation
import LocalAuthentication

/// Face ID / Touch ID gate — "Face ID before anything is shown."
/// Discretion is a first-class setting for a stigmatised habit (brief P8).
@MainActor
final class AppLock: ObservableObject {
    @Published var locked = false
    private var authenticating = false

    func lockIfEnabled(_ enabled: Bool) {
        guard enabled else { return }
        locked = true
    }

    func unlock() async {
        guard locked, !authenticating else { return }
        authenticating = true
        defer { authenticating = false }

        let context = LAContext()
        context.localizedFallbackTitle = L.s("applock_fallback_passcode")
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            // No biometrics/passcode enrolled — do not brick the user's data.
            locked = false
            return
        }

        do {
            let ok = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: L.s("applock_prompt_reason")
            )
            if ok { locked = false }
        } catch {
            // Stay locked; user can retry from the lock screen.
        }
    }
}
