import SwiftUI

struct PreviewDock: View {
    let latestPhoto: UIImage?
    
    var body: some View {
        if let photo = latestPhoto {
            Image(uiImage: photo)
                .resizable()
                .scaledToFill()
                .frame(width: 50, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(15)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                )
                .onTapGesture {
                    if let photosURL = URL(string: "photos-redirect://") {
                        UIApplication.shared.open(photosURL, options: [:], completionHandler: nil)
                    }
                }
                .transition(.opacity)
        }
    }
} 