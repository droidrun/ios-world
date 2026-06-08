import SwiftUI

struct ToastView: View {
    let toast: Toast

    var body: some View {
        Text(toast.message)
            .font(.subheadline.weight(.semibold))
            .foregroundColor(.white)
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(radius: 6)
            .accessibilityIdentifier("toast_message")
    }

    private var backgroundColor: Color {
        switch toast.style {
        case .success: return Color.green.opacity(0.9)
        case .error: return Color.red.opacity(0.9)
        case .info: return Color.blue.opacity(0.85)
        }
    }
}
