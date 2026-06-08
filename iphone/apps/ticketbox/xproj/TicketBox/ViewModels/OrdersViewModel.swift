import Foundation
import Observation

@Observable final class OrdersViewModel {
    var now: Date = Date()
    private var timer: Timer?

    func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.now = Date()
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    func status(for order: Order) -> OrderStatus {
        if now >= order.estimatedDelivery {
            return .delivered
        }
        let total = order.estimatedDelivery.timeIntervalSince(order.createdAt)
        let elapsed = now.timeIntervalSince(order.createdAt)
        if elapsed < total * 0.45 {
            return .processing
        }
        return .confirmed
    }

    func countdown(for order: Order) -> String {
        let remaining = max(0, Int(order.estimatedDelivery.timeIntervalSince(now)))
        let minutes = remaining / 60
        let seconds = remaining % 60
        return String(format: "%02dm %02ds", minutes, seconds)
    }

    func etaText(for order: Order) -> String {
        let remaining = max(0, Int(order.estimatedDelivery.timeIntervalSince(now)))
        if remaining == 0 {
            return "Delivered"
        }
        let minutes = max(1, remaining / 60)
        return "ETA \(minutes) min"
    }
}
