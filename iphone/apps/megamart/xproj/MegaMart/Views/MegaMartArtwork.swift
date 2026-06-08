import SwiftUI

enum MegaMartArtwork {
    static func productAssetName(for productID: String) -> String? {
        switch productID {
        case "noise_canceling_headphones_001":
            return "art_headphones"
        case "mechanical_keyboard_003":
            return "art_keyboard"
        case "monitor_27inch_004":
            return "art_monitor"
        case "air_fryer_009":
            return "art_air_fryer"
        case "face_moisturizer_033":
            return "art_moisturizer"
        case "running_shoes_025":
            return "art_running_shoes"
        case "sunscreen_lotion_036":
            return "art_sunscreen"
        case "protein_powder_041":
            return "art_protein_powder"
        case "paper_towels_046":
            return "art_paper_towels"
        case "led_desk_lamp_049":
            return "art_desk_lamp"
        case "dog_treats_065":
            return "art_dog_treats"
        case "water_bottle_074":
            return "art_water_bottle"
        case "yoga_mat_073":
            return "art_yoga_mat"
        case "trail_backpack_077":
            return "art_backpack"
        case "ps5_digital_bundle_081":
            return "art_ps5_bundle"
        case "ps5_slim_disc_bundle_082":
            return "art_ps5_slim_bundle"
        case "ps5_charging_station_083":
            return "art_ps5_dock"
        case "ps5_controller_084":
            return "art_ps5_controller"
        case "ps5_headset_085":
            return "art_ps5_headset"
        case "ps5_external_storage_086":
            return "art_ps5_storage"
        case "ps5_cooling_stand_087":
            return "art_ps5_cooling"
        default:
            return nil
        }
    }

    static func categoryAssetName(for query: String) -> String? {
        let normalized = query.lowercased()
        if normalized.contains("prime") {
            return "cat_prime"
        }
        if normalized.contains("medical") || normalized.contains("pharmacy") {
            return "cat_medical"
        }
        if normalized.contains("gift") || normalized.contains("registry") {
            return "cat_gifting"
        }
        if normalized.contains("deal") || normalized.contains("saving") {
            return "cat_deals"
        }
        if normalized.contains("grocery") || normalized.contains("store") {
            return "cat_groceries"
        }
        if normalized.contains("pet") {
            return "cat_pets"
        }
        if normalized.contains("beauty") || normalized.contains("fashion") {
            return "cat_beauty"
        }
        if normalized.contains("home") || normalized.contains("garden") || normalized.contains("tool") {
            return "cat_home"
        }
        if normalized.contains("device") || normalized.contains("electronic") {
            return "cat_devices"
        }
        if normalized.contains("gaming") || normalized.contains("video") || normalized.contains("ps5") {
            return "cat_gaming"
        }
        if normalized.contains("book") || normalized.contains("reading") {
            return "cat_books"
        }
        if normalized.contains("toy") || normalized.contains("baby") || normalized.contains("kid") {
            return "cat_toys"
        }
        return nil
    }
}

struct MegaMartProductArtwork: View {
    let product: Product

    var body: some View {
        if let assetName = MegaMartArtwork.productAssetName(for: product.id) {
            Image(assetName)
                .resizable()
                .scaledToFit()
        } else if let imageURL = product.imageURL, let url = URL(string: imageURL) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(1, contentMode: .fit)
                case .failure:
                    sfSymbolFallback
                default:
                    Color(.systemGray6)
                        .aspectRatio(1, contentMode: .fit)
                        .overlay {
                            ProgressView()
                        }
                }
            }
        } else {
            sfSymbolFallback
        }
    }

    private var sfSymbolFallback: some View {
        Image(systemName: product.imageSystemName)
            .resizable()
            .scaledToFit()
            .foregroundStyle(MegaMartTheme.linkBlue)
            .padding(10)
    }
}

struct MegaMartCategoryArtwork: View {
    let query: String
    let fallbackSystemImage: String

    var body: some View {
        if let assetName = MegaMartArtwork.categoryAssetName(for: query) {
            Image(assetName)
                .resizable()
                .scaledToFit()
        } else {
            Image(systemName: fallbackSystemImage)
                .resizable()
                .scaledToFit()
                .foregroundStyle(MegaMartTheme.linkBlue)
                .padding(12)
        }
    }
}
