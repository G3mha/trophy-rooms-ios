import SwiftUI

struct PlatformReleaseRegionSection: View {
    @Binding var region: String

    private let regions = ["NA", "EU", "JP", "AU", "OTHER"]

    var body: some View {
        Section("Region") {
            Picker("Region", selection: $region) {
                ForEach(regions, id: \.self) { value in
                    Text(AdminPlatformReleaseFormatting.regionDisplayName(value)).tag(value)
                }
            }
        }
    }
}

struct PlatformReleaseDateSection: View {
    @Binding var releaseDate: Date

    var body: some View {
        Section("Release Date") {
            DatePicker("Date", selection: $releaseDate, displayedComponents: .date)
        }
    }
}
