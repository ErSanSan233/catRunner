import SwiftUI

struct ControlDock: View {
    @Binding var isDockExpanded: Bool
    @Binding var photoMode: PhotoMode
    @Binding var previousPhotoMode: PhotoMode
    @Binding var moveSpeed: Double
    @Binding var isPreparingPhoto: Bool
    @Binding var cameraEdgePosition: CameraPosition
    
    let onShutterPress: () -> Void
    
    // 添加设备方向判断
    private var isPortrait: Bool {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            return windowScene.interfaceOrientation.isPortrait
        }
        return true
    }
    
    var body: some View {
        Group {
            if isPortrait {
                // 竖屏布局
                VStack(alignment: .trailing, spacing: 20) {
                    if isDockExpanded {
                        expandedControlPanel
                            .transition(
                                .asymmetric(
                                    insertion: .scale(scale: 0.8).combined(with: .opacity).combined(with: .move(edge: .bottom)),
                                    removal: .scale(scale: 0.8).combined(with: .opacity).combined(with: .move(edge: .bottom))
                                )
                            )
                    }
                    compactControlBar
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 10)
            } else {
                // 横屏布局
                HStack(alignment: .bottom, spacing: 20) {
                    if isDockExpanded {
                        expandedControlPanel
                            .transition(
                                .asymmetric(
                                    insertion: .scale(scale: 0.8).combined(with: .opacity).combined(with: .move(edge: .trailing)),
                                    removal: .scale(scale: 0.8).combined(with: .opacity).combined(with: .move(edge: .trailing))
                                )
                            )
                    }
                    compactControlBar
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 10)
            }
        }
    }
    
    // 展开的控制面板
    private var expandedControlPanel: some View {
        VStack(spacing: 20) {
            // 速度控制
            VStack(alignment: .leading, spacing: 8) {
                Text(NSLocalizedString("Move Speed", comment: "Speed control title"))
                    .foregroundColor(.white)
                    .font(.system(size: 14))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack {
                    Image(systemName: "tortoise")
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "hare")
                        .foregroundColor(.white)
                }
                
                Slider(value: $moveSpeed, in: 0.1...1.0)
                    .tint(.white)
            }
            .padding(.horizontal, 15)
            
            // 摄像头位置选择
            VStack(alignment: .leading, spacing: 8) {
                Text(NSLocalizedString("Camera Position", comment: "Camera position title"))
                    .foregroundColor(.white)
                    .font(.system(size: 14))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Picker(NSLocalizedString("Camera Position", comment: "Camera position picker"), selection: $cameraEdgePosition) {
                    Text(NSLocalizedString("Top", comment: "Top camera position"))
                        .tag(CameraPosition.shortEdge)
                    Text(NSLocalizedString("Side", comment: "Side camera position"))
                        .tag(CameraPosition.longEdge)
                }
                .pickerStyle(.segmented)
            }
            .padding(.horizontal, 15)
            
            // 相机模式选择
            VStack(alignment: .leading, spacing: 8) {
                Text(NSLocalizedString("Photo Mode", comment: "Photo mode title"))
                    .foregroundColor(.white)
                    .font(.system(size: 14))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                CustomSegmentedControl(selection: Binding(
                    get: { photoMode },
                    set: { newMode in
                        if newMode == .auto {
                            previousPhotoMode = photoMode
                        }
                        photoMode = newMode
                    }
                ))
            }
            .padding(.horizontal, 15)
        }
        .frame(width: 180)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
    }
    
    // 紧凑的控制栏
    private var compactControlBar: some View {
        HStack(spacing: 15) {
            // 折叠按钮
            Button(action: {
                withAnimation(.spring(duration: 0.3)) {
                    isDockExpanded.toggle()
                }
            }) {
                Image(systemName: isDockExpanded ? 
                      (isPortrait ? "chevron.down.circle.fill" : "chevron.right.circle.fill") :
                      (isPortrait ? "chevron.up.circle.fill" : "chevron.left.circle.fill"))
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }
            
            // 快门按钮
            Button(action: onShutterPress) {
                if photoMode == .auto {
                    Circle()
                        .stroke(Color.red, lineWidth: 3)
                        .frame(width: 60, height: 60)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.red)
                                .frame(width: 20, height: 20)
                        )
                } else {
                    Circle()
                        .stroke(Color.white, lineWidth: 3)
                        .frame(width: 60, height: 60)
                        .overlay(
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Image(systemName: photoMode.icon)
                                        .font(.system(size: 20))
                                        .foregroundColor(.white)
                                )
                        )
                }
            }
            .disabled(isPreparingPhoto)
        }
        .padding(15)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
    }
} 