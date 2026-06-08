import SwiftUI

struct ProfileSummaryView: View {
    let profile: UserProfile
    let account: SkyMilesAccount

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(profile.fullName)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .accessibilityIdentifier("profile_name_label")

            HStack(spacing: 6) {
                Text(account.medallionLevel)
                    .font(.system(size: 14, weight: .semibold))
                Text("·")
                Text("#\(account.memberNumber)")
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(Color.white.opacity(0.85))
            .accessibilityIdentifier("profile_skymiles_summary")

            HStack(spacing: 18) {
                metric(label: "Miles", value: "\(account.redeemableMiles)", id: "profile_skymiles_number")
                metric(label: "MQDs", value: "$\(account.mqds.formatted())", id: "profile_mqds_value")
                metric(label: "Home", value: profile.homeAirportCode, id: "profile_home_airport_label")
            }
            .accessibilityIdentifier("profile_metrics_row")

            Text(profile.email)
                .font(.system(size: 12))
                .foregroundStyle(Color.white.opacity(0.75))
                .accessibilityIdentifier("profile_email_label")
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [SkyTripTheme.navyLight, SkyTripTheme.navy],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(alignment: .topTrailing) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 28))
                .foregroundStyle(Color.white.opacity(0.15))
                .padding(12)
        }
        .accessibilityIdentifier("profile_summary_card")
    }

    private func metric(label: String, value: String, id: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .accessibilityIdentifier(id)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Color.white.opacity(0.7))
        }
    }
}
