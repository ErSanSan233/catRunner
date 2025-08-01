import AVFoundation
import Photos
import UIKit
import SwiftUI
import AudioToolbox  // 添加音频工具箱

class CameraManager: NSObject, ObservableObject {
    private var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    
    @Published var recentPhotos: [UIImage] = []
    @Published private(set) var isCameraReady = false
    private let maxPhotos = 3
    
    // 添加快门声音ID
    private let shutterSoundID: SystemSoundID = 1108 // iOS 相机快门声音ID
    
    override init() {
        super.init()
        loadRecentPhotos()
        // 注册相册变化监听
        PHPhotoLibrary.shared().register(self)
        // 检查相机权限
        checkPermissions()
    }
    
    deinit {
        // 取消注册
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
        // 停止相机会话
        captureSession?.stopRunning()
    }
    
    private func loadRecentPhotos() {
        // 先检查权限状态
        let status = PHPhotoLibrary.authorizationStatus()
        if status == .notDetermined {
            PHPhotoLibrary.requestAuthorization { [weak self] newStatus in
                if newStatus == .authorized {
                    self?.fetchPhotos()
                }
            }
        } else if status == .authorized {
            fetchPhotos()
        }
    }
    
    private func fetchPhotos() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = maxPhotos
        
        let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        self.updateRecentPhotos(from: assets)
    }
    
    private func updateRecentPhotos(from assets: PHFetchResult<PHAsset>) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            var newPhotos: [UIImage] = []
            
            let options = PHImageRequestOptions()
            options.isSynchronous = false
            options.deliveryMode = .fastFormat
            
            assets.enumerateObjects { asset, _, _ in
                PHImageManager.default().requestImage(
                    for: asset,
                    targetSize: CGSize(width: 100, height: 100),
                    contentMode: .aspectFill,
                    options: options
                ) { image, _ in
                    if let image = image {
                        newPhotos.append(image)
                        if newPhotos.count == self?.maxPhotos {
                            DispatchQueue.main.async {
                                self?.recentPhotos = newPhotos
                            }
                        }
                    }
                }
            }
            
            // 如果照片少于maxRecentPhotos，也要更新
            if newPhotos.count < self?.maxPhotos ?? 3 {
                DispatchQueue.main.async {
                    self?.recentPhotos = newPhotos
                }
            }
        }
    }
    
    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    DispatchQueue.main.async {
                        self?.setupCamera()
                    }
                }
            }
        case .restricted, .denied:
            return
        case .authorized:
            setupCamera()
        @unknown default:
            return
        }
    }
    
    func setupCamera() {
        // 在后台队列中设置相机
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let session = AVCaptureSession()
            session.sessionPreset = .photo
            
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
                  let input = try? AVCaptureDeviceInput(device: device) else {
                return
            }
            
            let output = AVCapturePhotoOutput()
            
            if session.canAddInput(input) && session.canAddOutput(output) {
                session.beginConfiguration()
                session.addInput(input)
                session.addOutput(output)
                session.commitConfiguration()
                
                self.captureSession = session
                self.photoOutput = output
                
                // 启动相机会话
                session.startRunning()
                
                // 更新状态
                DispatchQueue.main.async {
                    self.isCameraReady = true
                }
            }
        }
    }
    
    func capturePhoto() {
        guard isCameraReady,
              let photoOutput = photoOutput,
              captureSession?.isRunning == true else {
            print("Camera is not ready")
            return
        }
        
        // 播放快门声
        AudioServicesPlaySystemSound(shutterSoundID)
        
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    // 修改添加照片的方法
    private func addPhotoToRecent(_ image: UIImage) {
        DispatchQueue.main.async {
            // 在数组开头插入新照片
            self.recentPhotos.insert(image, at: 0)
            // 如果超过最大数量，移除最后一张
            if self.recentPhotos.count > self.maxPhotos {
                self.recentPhotos.removeLast()
            }
        }
    }
    
    // 获取当前界面方向
    private func getCurrentImageOrientation() -> UIImage.Orientation {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            // 前置摄像头需要先左旋转，然后根据界面方向再调整
            if windowScene.interfaceOrientation == .landscapeRight {
                return .down  // 前置摄像头在横屏时需要旋转180度
            }
            return .leftMirrored  // 前置摄像头在竖屏时需要左旋转并镜像
        }
        return .leftMirrored  // 默认竖屏处理
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil else {
            print("Error capturing photo: \(error!.localizedDescription)")
            return
        }
        
        guard let imageData = photo.fileDataRepresentation() else {
            print("Error while generating image from photo capture data.")
            return
        }
        
        guard let uiImage = UIImage(data: imageData) else {
            print("Could not create UIImage from image data.")
            return
        }
        
        // 根据当前界面方向调整照片方向
        let orientation = getCurrentImageOrientation()
        let correctedImage: UIImage
        if let cgImage = uiImage.cgImage {
            correctedImage = UIImage(cgImage: cgImage, scale: uiImage.scale, orientation: orientation)
        } else {
            correctedImage = uiImage
        }
        
        // 保存照片到相册
        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetChangeRequest.creationRequestForAsset(from: correctedImage)
            request.creationDate = Date()
        }) { [weak self] success, error in
            if success {
                self?.addPhotoToRecent(correctedImage)
            } else if let error = error {
                print("Error saving photo to library: \(error.localizedDescription)")
            }
        }
    }
}

// 添加相册变化监听
extension CameraManager: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = maxPhotos
        
        let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        DispatchQueue.main.async { [weak self] in
            self?.updateRecentPhotos(from: assets)
        }
    }
} 