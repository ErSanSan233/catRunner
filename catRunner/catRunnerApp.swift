//
//  catRunnerApp.swift
//  catRunner
//
//  Created on 2024/12/21.
//

import SwiftUI
import os.log

// 添加日志过滤
extension OSLog {
    private static var subsystem = Bundle.main.bundleIdentifier!
    static let ui = OSLog(subsystem: subsystem, category: "UI")
    static let metal = OSLog(subsystem: subsystem, category: "Metal")
}

// 添加方向控制类
class OrientationController: ObservableObject {
    static let shared = OrientationController()
    
    func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            delegate.orientationLock = orientation
        }
    }
}

// 添加 AppDelegate 来控制方向
class AppDelegate: NSObject, UIApplicationDelegate {
    var orientationLock = UIInterfaceOrientationMask.all {
        didSet {
            if #available(iOS 16.0, *) {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    let geometryPreferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: orientationLock)
                    windowScene.requestGeometryUpdate(geometryPreferences)
                }
            }
        }
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return [.portrait, .landscapeRight]
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // 设置日志过滤
        if #available(iOS 15.0, *) {
            // 过滤 Metal 相关警告
            os_log("Configuring Metal logging", log: .metal, type: .debug)
            UserDefaults.standard.set(false, forKey: "MTL_DEBUG_LAYER")
            UserDefaults.standard.set(false, forKey: "METAL_DEVICE_WRAPPER_TYPE")
        }
        return true
    }
}

@main
struct catRunnerApp: App {
    // 注册 AppDelegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        // 设置日志过滤
        if #available(iOS 15.0, *) {
            // 过滤掉一些系统警告
            NSSetUncaughtExceptionHandler { exception in
                os_log("Uncaught exception: %{public}@", log: .ui, type: .error, exception.description)
            }
        }
        
        // 设置支持的方向
        OrientationController.shared.lockOrientation([.portrait, .landscapeRight])
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// 添加方向控制扩展
extension UIWindowScene.GeometryPreferences.iOS {
    static var portrait: Self {
        .init(interfaceOrientations: .portrait)
    }
    
    static var landscapeRight: Self {
        .init(interfaceOrientations: .landscapeRight)
    }
}
