import SwiftUI

// 摄像头位置枚举
enum CameraPosition: Int {
    case shortEdge  // 短边中间（默认）
    case longEdge   // 长边中间
    
    var label: String {
        switch self {
        case .shortEdge: return NSLocalizedString("Top", comment: "Camera on top")
        case .longEdge: return NSLocalizedString("Side", comment: "Camera on side")
        }
    }
}

struct CameraIndicator: View {
    let position: CGPoint
    
    var body: some View {
        Circle()
            .stroke(Color.white.opacity(0.3), lineWidth: 2)
            .frame(width: 12, height: 12)
            .overlay(
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 8, height: 8)
            )
            .position(position)
    }
    
    // 简化后的位置计算函数
    static func calculatePosition(in geometry: GeometryProxy, cameraEdgePosition: CameraPosition) -> CGPoint {
        // 使用界面方向而不是设备方向
        let isPortrait: Bool = {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                return windowScene.interfaceOrientation.isPortrait
            }
            return true // 默认竖屏
        }()
        
        let padding: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 12 : 44
        
        switch cameraEdgePosition {
        case .shortEdge:
            // 短边中间：竖屏时在上边，横屏时在左边
            return isPortrait ?
                CGPoint(x: geometry.size.width / 2, y: padding) :
                CGPoint(x: padding, y: geometry.size.height / 2)
            
        case .longEdge:
            // 长边中间：竖屏时在右边，横屏时在上边
            return isPortrait ?
                CGPoint(x: geometry.size.width - padding, y: geometry.size.height / 2) :
                CGPoint(x: geometry.size.width / 2, y: padding)
        }
    }
} 