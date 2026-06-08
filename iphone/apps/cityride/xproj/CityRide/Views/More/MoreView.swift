import SwiftUI

struct MoreView: View {
    @ObservedObject var viewModel: MoreViewModel

    @State private var showTerms = false
    @State private var showPrivacy = false
    @State private var showLicenses = false
    @State private var showBusiness = false
    @State private var showFamily = false
    @State private var showUberOne = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    servicesGrid
                    uberOnePromo
                    businessSection
                    legalSection
                    appInfoSection
                }
                .padding(16)
            }
            .background(CityRideTheme.background)
            .navigationTitle("Services")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showTerms) {
                ServicesLegalSheet(title: "Terms of Service", content: termsText)
            }
            .sheet(isPresented: $showPrivacy) {
                ServicesLegalSheet(title: "Privacy Policy", content: privacyText)
            }
            .sheet(isPresented: $showLicenses) {
                ServicesLegalSheet(title: "Open Source Licenses", content: licensesText)
            }
            .sheet(isPresented: $showBusiness) {
                ServicesInfoSheet(
                    icon: "building.2.fill",
                    title: "CityRide for Business",
                    detail: "Manage work travel, meal programs, and expense reporting for your entire team. Set spending limits, view reports, and centralize billing — all in one place.",
                    accessID: "services_business_sheet"
                )
            }
            .sheet(isPresented: $showFamily) {
                ServicesInfoSheet(
                    icon: "person.2.fill",
                    title: "Family Profiles",
                    detail: "Set up rides and deliveries for family members. Monitor trips, set safety preferences, and pay from a shared wallet — keeping everyone moving safely.",
                    accessID: "services_family_sheet"
                )
            }
            .sheet(isPresented: $showUberOne) {
                ServicesInfoSheet(
                    icon: "crown.fill",
                    title: "CityRide One",
                    detail: "Save on every ride and delivery with a CityRide One membership. Enjoy priority support, exclusive deals, and automatic savings on every trip.",
                    accessID: "services_uber_one_sheet"
                )
            }
        }
    }

    private var servicesGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10)
        ], spacing: 10) {
            serviceTile(icon: "car.fill", title: "Ride", subtitle: "Go anywhere", id: "services_ride_tile") {
                viewModel.store.postStatusMessage("Opening Ride…")
            }
            serviceTile(icon: "calendar.badge.clock", title: "Reserve", subtitle: "Plan ahead", id: "services_reserve_tile") {
                viewModel.store.postStatusMessage("Opening Reserve…")
            }
            serviceTile(icon: "fork.knife", title: "Eats", subtitle: "Order food", id: "services_eats_tile") {
                viewModel.store.postStatusMessage("Opening Eats…")
            }
            serviceTile(icon: "cart.fill", title: "Grocery", subtitle: "Fresh delivery", id: "services_grocery_tile") {
                viewModel.store.postStatusMessage("Opening Grocery…")
            }
            serviceTile(icon: "shippingbox.fill", title: "Package", subtitle: "Send anything", id: "services_package_tile") {
                viewModel.store.postStatusMessage("Opening Package…")
            }
            serviceTile(icon: "key.fill", title: "Rent", subtitle: "Rent a car", id: "services_rent_tile") {
                viewModel.store.postStatusMessage("Opening Rent…")
            }
        }
    }

    private func serviceTile(icon: String, title: String, subtitle: String, id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .frame(width: 48, height: 48)
                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                VStack(spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(CityRideTheme.muted)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .uberCard(radius: 14)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(id)
    }

    private var uberOnePromo: some View {
        Button {
            showUberOne = true
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CityRide One")
                        .font(.headline)
                    Text("Save on rides and delivery with a monthly membership")
                        .font(.caption)
                        .foregroundStyle(CityRideTheme.muted)
                }
                Spacer()
                Image(systemName: "crown.fill")
                    .font(.title2)
                    .foregroundStyle(.yellow)
            }
            .padding(14)
            .uberCard(radius: 18)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("services_uber_one_promo")
    }

    private var businessSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Business")
                .font(.title3.weight(.bold))

            Button {
                showBusiness = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "building.2.fill")
                        .font(.title3)
                        .foregroundStyle(CityRideTheme.muted)
                        .frame(width: 34)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("CityRide for Business")
                            .font(.subheadline.weight(.semibold))
                        Text("Manage work travel and meal programs")
                            .font(.caption)
                            .foregroundStyle(CityRideTheme.muted)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(CityRideTheme.muted)
                }
                .padding(12)
                .uberCard(radius: 14)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("services_uber_business_card")

            Button {
                showFamily = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "person.2.fill")
                        .font(.title3)
                        .foregroundStyle(CityRideTheme.muted)
                        .frame(width: 34)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Family profiles")
                            .font(.subheadline.weight(.semibold))
                        Text("Set up rides and deliveries for family members")
                            .font(.caption)
                            .foregroundStyle(CityRideTheme.muted)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(CityRideTheme.muted)
                }
                .padding(12)
                .uberCard(radius: 14)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("services_family_profiles_card")
        }
    }

    private var legalSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Legal")
                .font(.title3.weight(.bold))

            VStack(spacing: 0) {
                legalRow(title: "Terms of Service", id: "services_terms_button") {
                    showTerms = true
                }
                Divider().overlay(CityRideTheme.cardBorder)
                legalRow(title: "Privacy Policy", id: "services_privacy_button") {
                    showPrivacy = true
                }
                Divider().overlay(CityRideTheme.cardBorder)
                legalRow(title: "Open source licenses", id: "services_licenses_button") {
                    showLicenses = true
                }
            }
            .uberCard(radius: 14)
        }
    }

    private func legalRow(title: String, id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.subheadline)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(CityRideTheme.muted)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(id)
    }

    private var appInfoSection: some View {
        VStack(spacing: 4) {
            Text("CityRide")
                .font(.subheadline.weight(.medium))
            Text("Version 25.12.1 (4829)")
                .font(.caption)
                .foregroundStyle(CityRideTheme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
        .padding(.bottom, 24)
        .accessibilityIdentifier("services_app_version_label")
    }

    // MARK: - Legal text content

    private var termsText: String {
        """
        Terms of Service

        Last updated: January 1, 2025

        By using CityRide, you agree to these Terms of Service. CityRide provides a platform connecting riders with independent driver-partners.

        1. Eligibility. You must be at least 18 years old to use CityRide.

        2. Account. You are responsible for keeping your account credentials secure.

        3. Rides. Prices are shown before you book. Cancellation fees may apply.

        4. Payments. By providing a payment method, you authorize CityRide to charge for completed rides.

        5. Conduct. You agree to treat drivers respectfully and comply with all applicable laws.

        6. Changes. We may update these terms at any time. Continued use constitutes acceptance.

        Contact: legal@cityride.example
        """
    }

    private var privacyText: String {
        """
        Privacy Policy

        Last updated: January 1, 2025

        CityRide collects information necessary to provide the ride-hailing service.

        1. Data we collect. Location data, trip history, payment information, and device identifiers.

        2. How we use it. To match you with drivers, process payments, and improve the service.

        3. Sharing. We share data with your driver during a trip and with payment processors.

        4. Retention. Trip data is retained for 7 years for regulatory compliance.

        5. Your rights. You can request a copy of your data or ask for deletion from Account > Privacy.

        6. Cookies. The app uses analytics cookies to improve performance.

        Contact: privacy@cityride.example
        """
    }

    private var licensesText: String {
        """
        Open Source Licenses

        CityRide is built with the following open-source components:

        Swift (Apache License 2.0)
        Copyright © Apple Inc.

        MapKit (Apple Developer License)
        Copyright © Apple Inc.

        Combine (Apple Developer License)
        Copyright © Apple Inc.

        Full license texts are available at:
        https://cityride.example/licenses
        """
    }
}

// MARK: - Supporting sheets

private struct ServicesLegalSheet: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let content: String

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(content)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier("services_legal_body")
            }
            .background(CityRideTheme.background)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .accessibilityIdentifier("services_legal_done_button")
                }
            }
        }
    }
}

private struct ServicesInfoSheet: View {
    @Environment(\.dismiss) private var dismiss
    let icon: String
    let title: String
    let detail: String
    let accessID: String

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 56))
                    .foregroundStyle(CityRideTheme.accent)
                    .accessibilityIdentifier("\(accessID)_icon")
                Text(title)
                    .font(.title2.weight(.bold))
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("\(accessID)_title")
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(CityRideTheme.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .accessibilityIdentifier("\(accessID)_detail")
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Text("Got it")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 50)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .accessibilityIdentifier("\(accessID)_done_button")
            }
            .padding(.bottom, 32)
            .background(CityRideTheme.background)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .accessibilityIdentifier("\(accessID)_toolbar_done")
                }
            }
        }
    }
}
