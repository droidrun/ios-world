import SwiftUI

struct RecordView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = RecordViewModel()
    @State private var showHeatmap = false
    @State private var showThreeDimensionalMap = false
    @State private var showingRoutePicker = false
    @State private var showingSensorPicker = false
    @State private var showingCameraSheet = false
    @State private var isLiveLocationEnabled = false
    @State private var connectedSensorName: String?
    @State private var selectedPhotoStyle: String?
    @State private var mapResetTrigger = 0
    @State private var sheetRestingOffset: CGFloat = 0
    @GestureState private var sheetDragOffset: CGFloat = 0

    private let maxSheetLift: CGFloat = 168

    private var availableRoutes: [Route] {
        appState.currentData.routes
    }

    var body: some View {
        GeometryReader { proxy in
            let bottomSheetPadding = proxy.safeAreaInsets.bottom + 10
            let sheetOffset = max(-maxSheetLift, min(0, sheetRestingOffset + sheetDragOffset))

            ZStack {
                MapPlaceholderView(
                    points: viewModel.selectedRoute?.points ?? [],
                    routes: availableRoutes,
                    highlightedRouteId: viewModel.selectedRoute?.id,
                    height: proxy.size.height + proxy.safeAreaInsets.top + 120,
                    style: .fullScreen,
                    showCurrentLocation: true,
                    showLabels: false,
                    showHeatmap: showHeatmap,
                    isThreeDimensional: showThreeDimensionalMap,
                    allowsInteraction: true,
                    recenterTrigger: mapResetTrigger
                )
                .ignoresSafeArea()

                VStack(spacing: 18) {
                    topOverlay(proxy)
                    Spacer()
                }

                trailingControls
                    .padding(.trailing, 18)
                    .padding(.bottom, bottomSheetPadding + 248)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)

                bottomSheet
                    .offset(y: sheetOffset)
                    .padding(.horizontal, 12)
                    .padding(.bottom, bottomSheetPadding)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
        }
        .background(AppTheme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .animation(.spring(response: 0.28, dampingFraction: 0.86), value: sheetRestingOffset)
        .onAppear {
            loadPendingRouteIfNeeded()
            loadPendingWorkoutIfNeeded()
            syncSheetLiftToPhase(viewModel.phase)
        }
        .onChange(of: viewModel.phase) { _, newPhase in
            // The recording / paused / review sheets are taller than the idle
            // sheet; at the resting (0) offset their Pause/Stop/Resume/Save
            // buttons render below the bottom safe area and become un-tappable.
            // Lift the sheet for those phases so the action buttons stay
            // on-screen and hit-testable.
            syncSheetLiftToPhase(newPhase)
        }
        .onChange(of: appState.pendingRouteId) { _, _ in
            loadPendingRouteIfNeeded()
        }
        .onChange(of: appState.pendingWorkoutPreset) { _, _ in
            loadPendingWorkoutIfNeeded()
        }
        .sheet(isPresented: $showingRoutePicker) {
            NavigationStack {
                List(availableRoutes) { route in
                    Button {
                        viewModel.applyRoute(route)
                        showingRoutePicker = false
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(route.name)
                                .foregroundStyle(.primary)
                            Text("\(route.startLocation) • \(AppFormatters.distance(route.distanceKilometers))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .background(AppTheme.background.ignoresSafeArea())
                .navigationTitle("Select Route")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") {
                            showingRoutePicker = false
                        }
                    }
                }
            }
            .preferredColorScheme(.dark)
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showingSensorPicker) {
            NavigationStack {
                List(["Apple Watch", "Heart Rate Strap", "Power Meter", "Cadence Sensor"], id: \.self) { sensor in
                    Button(sensor) {
                        connectedSensorName = sensor
                        showingSensorPicker = false
                    }
                }
                .scrollContentBackground(.hidden)
                .background(AppTheme.background.ignoresSafeArea())
                .navigationTitle("Add a Sensor")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") {
                            showingSensorPicker = false
                        }
                    }
                }
            }
            .preferredColorScheme(.dark)
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showingCameraSheet) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeaderView("Workout Photo", subtitle: "Attach a stylized preview image to this simulated recording session")
                        ForEach(["Blue Hour", "Track Glow", "Forest Fade"], id: \.self) { style in
                            Button {
                                selectedPhotoStyle = style
                                showingCameraSheet = false
                            } label: {
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: style == "Blue Hour"
                                                ? [Color.blue, Color.indigo]
                                                : style == "Track Glow"
                                                    ? [AppTheme.accent, Color.yellow]
                                                    : [Color.green, Color.black],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .overlay(alignment: .bottomLeading) {
                                        Text(style)
                                            .font(.system(size: 22, weight: .bold))
                                            .foregroundStyle(.white)
                                            .padding(20)
                                    }
                                    .frame(height: 180)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(20)
                }
                .background(AppTheme.background.ignoresSafeArea())
                .navigationTitle("Camera")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") {
                            showingCameraSheet = false
                        }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }

    private func topOverlay(_ proxy: GeometryProxy) -> some View {
        VStack(spacing: 16) {
            HStack {
                Button {
                    appState.selectedTab = .routes
                } label: {
                    TrailBlazeIconButton(systemImage: "chevron.down", filled: true, background: .black.opacity(0.86), size: 44)
                }
                .buttonStyle(.plain)

                Spacer()
            }

            Button {
                showHeatmap.toggle()
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(
                                AngularGradient(
                                    colors: [.blue, .green, .yellow, .red, .purple, .blue],
                                    center: .center
                                )
                            )
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.white)
                            .font(.system(size: 13, weight: .bold))
                    }
                    .frame(width: 40, height: 40)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(showHeatmap ? "Weekly heatmap on" : "See what's popular")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                        Text(showHeatmap ? "Popular roads are highlighted on the map." : "Tap to add weekly Heatmap")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(.black.opacity(0.88))
                )
                .overlay(
                    Capsule()
                        .stroke(
                            LinearGradient(
                                colors: [.yellow, .red.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 1.4
                        )
                )
            }
            .buttonStyle(.plain)

            if let route = viewModel.selectedRoute {
                HStack(spacing: 10) {
                    Image(systemName: route.recommendedActivityType.systemImage)
                        .foregroundStyle(AppTheme.accent)
                    Text(route.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Spacer()
                    Text(route.startLocation)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(.black.opacity(0.82))
                )
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, proxy.safeAreaInsets.top + 8)
    }

    private var trailingControls: some View {
        VStack(spacing: 10) {
            Button {
                showingCameraSheet = true
            } label: {
                TrailBlazeIconButton(
                    systemImage: selectedPhotoStyle == nil ? "camera.fill" : "photo.fill",
                    filled: true,
                    background: selectedPhotoStyle == nil ? .black.opacity(0.86) : AppTheme.accent.opacity(0.92),
                    foreground: selectedPhotoStyle == nil ? .white : .black,
                    size: 44
                )
            }
            .buttonStyle(.plain)

            Button {
                showThreeDimensionalMap.toggle()
            } label: {
                Text("3D")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(showThreeDimensionalMap ? .black : .white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(showThreeDimensionalMap ? AppTheme.accent : .black.opacity(0.86)))
            }
            .buttonStyle(.plain)

            Button {
                mapResetTrigger += 1
                appState.transientMessage = "Centered on San Francisco."
            } label: {
                TrailBlazeIconButton(systemImage: "location", filled: true, background: .black.opacity(0.86), size: 44)
            }
            .buttonStyle(.plain)
        }
    }

    private var bottomSheet: some View {
        VStack(spacing: 16) {
            Capsule()
                .fill(.white.opacity(0.28))
                .frame(width: 36, height: 5)
                .padding(.top, 10)
                // Drag-to-lift is scoped to the grabber handle only. Attaching
                // it to the whole sheet (via .simultaneousGesture) swallowed
                // taps on the .borderedProminent Pause/Stop/Resume/Save buttons.
                .padding(.horizontal, 60)
                .contentShape(Rectangle())
                .gesture(sheetDragGesture)

            switch viewModel.phase {
            case .idle:
                idleSheet
            case .recording:
                recordingSheet
            case .paused:
                pausedSheet
            case .review:
                reviewSheet
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(red: 0.08, green: 0.08, blue: 0.09).opacity(0.98))
        )
    }

    private var idleSheet: some View {
        VStack(spacing: 20) {
            HStack(alignment: .top, spacing: 24) {
                Button {
                    viewModel.selectedActivityType = nextActivityType(after: viewModel.selectedActivityType)
                } label: {
                    RecordCircleButton(
                        title: viewModel.selectedActivityType.title,
                        systemImage: viewModel.selectedActivityType.systemImage,
                        fillColor: Color(red: 0.22, green: 0.18, blue: 0.14),
                        foregroundColor: .white,
                        showsCheck: true
                    )
                }
                .buttonStyle(.plain)

                Button {
                    viewModel.start()
                } label: {
                    RecordCircleButton(
                        title: "Start",
                        systemImage: "play.fill",
                        fillColor: AppTheme.accent,
                        foregroundColor: .white,
                        isPrimary: true
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(AccessibilityID.recordStartButton)

                Button {
                    showingRoutePicker = true
                } label: {
                    RecordCircleButton(
                        title: viewModel.selectedRoute == nil ? "Add Route" : "Route Ready",
                        systemImage: "point.topleft.down.curvedto.point.bottomright.up",
                        fillColor: Color.white.opacity(0.12),
                        foregroundColor: .white.opacity(0.8)
                    )
                }
                .buttonStyle(.plain)
            }

            if let selectedPhotoStyle {
                photoStylePreviewCard(style: selectedPhotoStyle)
            }

            VStack(spacing: 0) {
                recordSettingsRow(icon: "sharedwithyou", title: "Share live location", detail: isLiveLocationEnabled ? "On" : "Off") {
                    isLiveLocationEnabled.toggle()
                }

                Divider()
                    .background(AppTheme.divider)

                recordSettingsRow(icon: "heart.text.square", title: connectedSensorName == nil ? "Add a sensor" : "Sensor", detail: connectedSensorName ?? "") {
                    showingSensorPicker = true
                }

                Divider()
                    .background(AppTheme.divider)

                NavigationLink(destination: MoreView()) {
                    HStack(spacing: 12) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(width: 28)

                        Text("Settings")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.plain)
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppTheme.cardBackground)
            )
        }
    }

    private var recordingSheet: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Recording \(viewModel.selectedActivityType.title)")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(AppTheme.accent)
                .textCase(.uppercase)

            Text(AppFormatters.duration(viewModel.elapsedSeconds))
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)

            MetricGridView(
                items: [
                    MetricItem(label: "Distance", value: AppFormatters.distance(viewModel.distanceKilometers)),
                    MetricItem(label: "Pace / Speed", value: viewModel.selectedActivityType == .ride || viewModel.selectedActivityType == .indoorRide ? AppFormatters.speed(distanceKilometers: viewModel.distanceKilometers, durationSeconds: max(viewModel.elapsedSeconds, 1)) : AppFormatters.pace(secondsPerKilometer: max(viewModel.averagePaceSecondsPerKilometer, 1))),
                    MetricItem(label: "Elev Gain", value: AppFormatters.elevation(viewModel.elevationGainMeters)),
                    MetricItem(label: "Calories", value: AppFormatters.integer(viewModel.calories))
                ]
            )

            HStack(spacing: 12) {
                Button("Pause") {
                    viewModel.pause()
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .contentShape(Rectangle())
                .accessibilityIdentifier(AccessibilityID.recordPauseButton)

                Button("Stop") {
                    viewModel.stop()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .contentShape(Rectangle())
                .accessibilityIdentifier(AccessibilityID.recordStopButton)
            }
        }
    }

    private var pausedSheet: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Paused")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.yellow)
                .textCase(.uppercase)

            Text(AppFormatters.duration(viewModel.elapsedSeconds))
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)

            MetricGridView(
                items: [
                    MetricItem(label: "Distance", value: AppFormatters.distance(viewModel.distanceKilometers)),
                    MetricItem(label: "Pace / Speed", value: viewModel.selectedActivityType == .ride || viewModel.selectedActivityType == .indoorRide ? AppFormatters.speed(distanceKilometers: viewModel.distanceKilometers, durationSeconds: max(viewModel.elapsedSeconds, 1)) : AppFormatters.pace(secondsPerKilometer: max(viewModel.averagePaceSecondsPerKilometer, 1))),
                    MetricItem(label: "Elev Gain", value: AppFormatters.elevation(viewModel.elevationGainMeters)),
                    MetricItem(label: "Calories", value: AppFormatters.integer(viewModel.calories))
                ]
            )

            HStack(spacing: 12) {
                Button("Resume") {
                    viewModel.resume()
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.accent)
                .contentShape(Rectangle())
                .accessibilityIdentifier(AccessibilityID.recordResumeButton)

                Button("Stop") {
                    viewModel.stop()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .contentShape(Rectangle())
                .accessibilityIdentifier(AccessibilityID.recordStopButton)
            }
        }
    }

    private var reviewSheet: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeaderView("Review Activity", subtitle: "Save the simulated workout back into the feed")

            TrailBlazeInsetTextField(title: "Activity Title", text: $viewModel.reviewTitle)

            MetricGridView(
                items: [
                    MetricItem(label: "Distance", value: AppFormatters.distance(viewModel.distanceKilometers)),
                    MetricItem(label: "Duration", value: AppFormatters.duration(viewModel.elapsedSeconds)),
                    MetricItem(label: "Avg Pace", value: viewModel.selectedActivityType == .ride || viewModel.selectedActivityType == .indoorRide ? AppFormatters.speed(distanceKilometers: viewModel.distanceKilometers, durationSeconds: max(viewModel.elapsedSeconds, 1)) : AppFormatters.pace(secondsPerKilometer: max(viewModel.averagePaceSecondsPerKilometer, 1))),
                    MetricItem(label: "Calories", value: AppFormatters.integer(viewModel.calories))
                ]
            )

            VStack(alignment: .leading, spacing: 10) {
                Text("Splits")
                    .font(.headline)
                    .foregroundStyle(.white)
                ForEach(viewModel.splits) { split in
                    HStack {
                        Text("Split \(split.index)")
                            .foregroundStyle(.white)
                        Spacer()
                        Text(AppFormatters.distance(split.distanceKilometers))
                            .foregroundStyle(AppTheme.textSecondary)
                        Text(AppFormatters.duration(split.durationSeconds))
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                    }
                    .font(.subheadline)
                }
            }

            if let selectedPhotoStyle {
                photoStylePreviewCard(style: selectedPhotoStyle)
            }

            HStack(spacing: 12) {
                Button("Save Activity") {
                    let activity = viewModel.makeActivity(currentUserAthleteId: appState.currentData.currentUserAthleteId)
                    appState.saveRecordedActivity(activity)
                    viewModel.reset()
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.accent)
                .accessibilityIdentifier(AccessibilityID.recordSaveButton)

                Button("Discard") {
                    viewModel.discard()
                }
                .buttonStyle(.bordered)
                .tint(.white)
                .accessibilityIdentifier(AccessibilityID.recordDiscardButton)
            }
        }
    }

    private func recordSettingsRow(icon: String, title: String, detail: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 28)

                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)

                Spacer()

                if !detail.isEmpty {
                    Text(detail)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }

    private func photoStylePreviewCard(style: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Attached Photo")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)

            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(photoStyleGradient(for: style))
                .overlay(alignment: .bottomLeading) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(style)
                            .font(.system(size: 20, weight: .bold))
                        Text("Saved with this activity preview")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundStyle(.white)
                    .padding(16)
                }
                .frame(height: 132)
        }
    }

    private func photoStyleGradient(for style: String) -> LinearGradient {
        let colors: [Color]

        switch style {
        case "Blue Hour":
            colors = [Color.blue, Color.indigo]
        case "Track Glow":
            colors = [AppTheme.accent, Color.yellow]
        default:
            colors = [Color.green, Color.black]
        }

        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private func nextActivityType(after type: ActivityType) -> ActivityType {
        let supportedTypes: [ActivityType] = [.ride, .run, .walk, .hike, .indoorRide]
        guard let index = supportedTypes.firstIndex(of: type) else { return .ride }
        return supportedTypes[(index + 1) % supportedTypes.count]
    }

    private var sheetDragGesture: some Gesture {
        DragGesture(minimumDistance: 6)
            .updating($sheetDragOffset) { value, state, _ in
                state = value.translation.height
            }
            .onEnded { value in
                let proposedOffset = max(-maxSheetLift, min(0, sheetRestingOffset + value.translation.height))
                sheetRestingOffset = proposedOffset < (-maxSheetLift * 0.45) ? -maxSheetLift : 0
            }
    }

    private func syncSheetLiftToPhase(_ phase: RecordViewModel.RecordingPhase) {
        switch phase {
        case .recording, .paused, .review:
            sheetRestingOffset = -maxSheetLift
        case .idle:
            sheetRestingOffset = 0
        }
    }

    private func loadPendingRouteIfNeeded() {
        if let route = appState.consumePendingRoute() {
            viewModel.applyRoute(route)
        }
    }

    private func loadPendingWorkoutIfNeeded() {
        if let preset = appState.consumePendingWorkoutPreset() {
            viewModel.applyWorkoutPreset(preset)
        }
    }
}

private struct RecordCircleButton: View {
    let title: String
    let systemImage: String
    let fillColor: Color
    let foregroundColor: Color
    var showsCheck = false
    var isPrimary = false

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(fillColor)
                    .frame(width: isPrimary ? 76 : 60, height: isPrimary ? 76 : 60)

                Image(systemName: systemImage)
                    .font(.system(size: isPrimary ? 26 : 22, weight: .semibold))
                    .foregroundStyle(foregroundColor)
                    .frame(width: isPrimary ? 76 : 60, height: isPrimary ? 76 : 60)

                if showsCheck {
                    Circle()
                        .fill(AppTheme.accent)
                        .frame(width: 20, height: 20)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.black)
                        )
                        .offset(x: 22, y: -22)
                }
            }

            Text(title)
                .font(.system(size: isPrimary ? 14 : 12, weight: .semibold))
                .foregroundStyle(isPrimary ? AppTheme.accent : .white.opacity(0.7))
                .minimumScaleFactor(0.82)
        }
    }
}
