//
//  ContentView.swift
//  catRunner
//
//  Created on 2024/12/21.
//

import SwiftUI
import AVFoundation
import Photos

// 添加拍照模式枚举
enum PhotoMode: Int, CaseIterable {
    case instant    // 立即拍照
    case delayed    // 延迟拍照
    case auto      // 自动拍照
    
    var icon: String {
        switch self {
        case .instant: return "bolt"
        case .delayed: return "timer"
        case .auto: return "camera.aperture"
        }
    }
    
    var label: String {
        switch self {
        case .instant: return NSLocalizedString("Instant", comment: "Instant photo mode")
        case .delayed: return NSLocalizedString("Delayed", comment: "Delayed photo mode")
        case .auto: return NSLocalizedString("Auto", comment: "Auto photo mode")
        }
    }
}

// 自定义分段控制器
struct CustomSegmentedControl: View {
    @Binding var selection: PhotoMode
    let animation: Animation = .easeInOut(duration: 0.2)
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(PhotoMode.allCases, id: \.self) { mode in
                Button(action: {
                    withAnimation(animation) {
                        selection = mode
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: mode.icon)
                            .font(.system(size: 16))
                        Text(mode.label)
                            .font(.system(size: 12))
                    }
                    .frame(width: 50)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                }
                .foregroundColor(selection == mode ? .black : .white)
            }
        }
        .background(
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
                    .frame(width: 50)
                    .offset(x: CGFloat(selection.rawValue) * 50)
            }
        )
        .background(Color.white.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct ContentView: View {
    // 状态变量
    @State private var animalPosition: CGPoint = .zero  // 动物的位置
    @State private var currentAnimal: String = "🐁"     // 当前显示的动物
    @State private var moveSpeed: Double = 0.5         // 移动速度（0.1-1.0）
    @State private var deviceOrientation = UIDevice.current.orientation
    @State private var isPreparingPhoto = false  // 添加状态来控制拍照流程
    @State private var photoMode: PhotoMode = .delayed  // 改为默认延迟模式
    @State private var moveCount: Int = 0  // 添加移动次数计数器
    @State private var isDockExpanded = false
    @State private var previousPhotoMode: PhotoMode = .delayed
    @State private var cameraEdgePosition: CameraPosition = .shortEdge
    @State private var showingHelp = false
    
    // 可选的动物数组 - 使用鲜艳的动物和物品emoji
    let animals = ["🦩", "🦜", "🦚", "🦋", "🐠", "🌺", "🌸", "🌈", "⭐️", "🌟", "🦄", "🐳", "🦕", "🦖", "🦒", "🦁", "🐯", "🦊", "🐸", "🦎"]
    
    // 移动定时器
    @State private var moveTimer: Timer? = nil
    
    @StateObject private var cameraManager = CameraManager()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景
                Color.black
                    .edgesIgnoringSafeArea(.all)
                
                // 修改摄像头指示圈
                CameraIndicator(position: CameraIndicator.calculatePosition(in: geometry, cameraEdgePosition: cameraEdgePosition))
                
                // 动物emoji
                Text(currentAnimal)
                    .font(.system(size: 80))
                    .position(animalPosition)
                    .onAppear {
                        animalPosition = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                        scheduleNextMove(in: geometry.size)
                    }
                
                VStack {
                    Spacer()
                    
                    HStack(alignment: .bottom) {
                        // 左侧区域
                        VStack(alignment: .leading, spacing: 15) {
                            // 帮助按钮
                            Button(action: {
                                showingHelp = true
                            }) {
                                Image(systemName: "questionmark.circle")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                                    .opacity(0.6)
                                    .padding(12)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                            }
                            .sheet(isPresented: $showingHelp) {
                                HelpView()
                            }
                            
                            // 预览窗口
                            PreviewDock(latestPhoto: cameraManager.recentPhotos.first)
                        }
                        .padding(.leading, 10)
                        
                        Spacer()
                        
                        // 右侧控制区域
                        ControlDock(
                            isDockExpanded: $isDockExpanded,
                            photoMode: $photoMode,
                            previousPhotoMode: $previousPhotoMode,
                            moveSpeed: $moveSpeed,
                            isPreparingPhoto: $isPreparingPhoto,
                            cameraEdgePosition: $cameraEdgePosition,
                            onShutterPress: {
                                switch photoMode {
                                case .instant:
                                    cameraManager.capturePhoto()
                                case .delayed:
                                    prepareAndTakePhoto(in: geometry)
                                case .auto:
                                    photoMode = previousPhotoMode
                                }
                            }
                        )
                    }
                    .padding(.bottom, 30)
                }
            }
            .onChange(of: geometry.size) { oldSize, newSize in
                // 尺寸变化时立即更新移动范围
                ensureAnimalInSafeBounds(in: newSize)
                moveTimer?.invalidate() // 停止当前的移动计时器
                moveAnimal(in: newSize) // 立即移动到新的有效位置
                scheduleNextMove(in: newSize) // 重新安排下一次移动
            }
            .onTapGesture { location in
                changeAnimal()
                moveAnimal(in: geometry.size)
                scheduleNextMove(in: geometry.size)
            }
            .onAppear {
                cameraManager.checkPermissions()
                // 添加设备方向变化通知监听
                NotificationCenter.default.addObserver(
                    forName: UIDevice.orientationDidChangeNotification,
                    object: nil,
                    queue: .main
                ) { _ in
                    deviceOrientation = UIDevice.current.orientation
                    // 方向改变时，确保动物在安全区域内
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       windowScene.interfaceOrientation.isPortrait != deviceOrientation.isPortrait {
                        // 界面方向确实发生了改变，等待布局更新完成
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { // 增加延迟时间
                            // 先确保当前位置在安全区域内
                            ensureAnimalInSafeBounds(in: geometry.size)
                            // 然后再进行随机移动
                            moveAnimal(in: geometry.size)
                            scheduleNextMove(in: geometry.size)
                        }
                    }
                }
                // 开启设备方向监测
                UIDevice.current.beginGeneratingDeviceOrientationNotifications()
                
                // 初始化动物位置
                animalPosition = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                scheduleNextMove(in: geometry.size)
            }
            .onDisappear {
                // 清理
                UIDevice.current.endGeneratingDeviceOrientationNotifications()
            }
            .onChange(of: moveCount) { oldValue, newValue in
                if photoMode == .auto && newValue >= Int.random(in: 1...2) {
                    moveCount = 0
                    let cameraPosition = CameraIndicator.calculatePosition(in: geometry, cameraEdgePosition: cameraEdgePosition)
                    autoTakePhoto(in: geometry.size, cameraPosition: cameraPosition)
                }
            }
        }
    }
    
    // 修改 scheduleNextMove 函数
    private func scheduleNextMove(in size: CGSize) {
        moveTimer?.invalidate()
        
        let baseInterval = 3.0
        let minInterval = 0.5
        // 修改计算方式，确保区间有效
        let maxInterval = max(minInterval + 0.1, baseInterval * (1.1 - moveSpeed))
        let randomInterval = Double.random(in: minInterval...maxInterval)
        
        moveTimer = Timer.scheduledTimer(withTimeInterval: randomInterval, repeats: false) { _ in
            if photoMode == .auto {
                moveCount += 1
                moveAnimal(in: size)  // 无论如何都要移动
                scheduleNextMove(in: size)  // 继续安排下一次移动
            } else {
                moveAnimal(in: size)
                scheduleNextMove(in: size)
            }
        }
    }
    
    // 随机改变显示的动物
    private func changeAnimal() {
        currentAnimal = animals.randomElement() ?? "🐁"
    }
    
    // 添加确保动物在安全区域内的函数
    private func ensureAnimalInSafeBounds(in size: CGSize) {
        let padding: CGFloat = 50 // 边缘安全距离
        let safeX = min(max(animalPosition.x, padding), size.width - padding)
        let safeY = min(max(animalPosition.y, padding), size.height - padding)
        
        // 如果位置需要调整，使用动画平滑过渡
        if safeX != animalPosition.x || safeY != animalPosition.y {
            withAnimation(.easeInOut(duration: 0.3)) {
                animalPosition = CGPoint(x: safeX, y: safeY)
            }
        }
    }
    
    // 随机移动动物到新位置
    private func moveAnimal(in size: CGSize) {
        let duration = 0.5 * (1.1 - moveSpeed)
        let padding: CGFloat = 50 // 边缘安全距离
        
        // 确保移动范围在安全区域内
        let safeWidth = size.width - (padding * 2)
        let safeHeight = size.height - (padding * 2)
        
        withAnimation(.easeInOut(duration: duration)) {
            // 生成新位置时考虑padding
            let newX = padding + CGFloat.random(in: 0...safeWidth)
            let newY = padding + CGFloat.random(in: 0...safeHeight)
            animalPosition = CGPoint(x: newX, y: newY)
        }
    }
    
    // 添加新的拍照准备函数
    private func prepareAndTakePhoto(in geometry: GeometryProxy) {
        isPreparingPhoto = true
        moveTimer?.invalidate() // 暂停随机移动
        
        let cameraPosition = CameraIndicator.calculatePosition(in: geometry, cameraEdgePosition: cameraEdgePosition)
        
        // 移动动物到摄像头位置
        withAnimation(.easeInOut(duration: 0.5)) {
            animalPosition = cameraPosition
        }
        
        // 等待动物移动完成后拍照
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            cameraManager.capturePhoto()
            
            // 拍照后恢复随机移动
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isPreparingPhoto = false
                scheduleNextMove(in: geometry.size)
            }
        }
    }
    
    // 修改自动拍照函数，使动物拍完照后立即移动
    private func autoTakePhoto(in size: CGSize, cameraPosition: CGPoint) {
        isPreparingPhoto = true
        
        // 移动动物到摄像头位置
        withAnimation(.easeInOut(duration: 0.5)) {
            animalPosition = cameraPosition
        }
        
        // 等待动物移动完成后拍照
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            cameraManager.capturePhoto()
            
            // 拍照后立即移动到新位置
            isPreparingPhoto = false
            moveAnimal(in: size)  // 立即移动到新位置
            scheduleNextMove(in: size)  // 安排下一次移动
        }
    }
}

#Preview {
    ContentView()
}
