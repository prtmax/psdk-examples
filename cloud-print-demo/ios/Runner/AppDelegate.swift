import Flutter
import PhotosUI
import UIKit
import UniformTypeIdentifiers

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, PHPickerViewControllerDelegate, UIAdaptivePresentationControllerDelegate {
  private var pendingImagePickResult: FlutterResult?
  private let maxLocalImageBytes = 25 * 1024 * 1024

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let messenger = engineBridge.applicationRegistrar.messenger()

    let imageChannel = FlutterMethodChannel(
      name: "com.psdk.examples.cloud_print_demo/local_image",
      binaryMessenger: messenger
    )
    imageChannel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(FlutterError(code: "disposed", message: "AppDelegate released", details: nil))
        return
      }
      switch call.method {
      case "pickImage":
        self.presentLocalImagePicker(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func presentLocalImagePicker(result: @escaping FlutterResult) {
    if pendingImagePickResult != nil {
      result(FlutterError(code: "pick_in_progress", message: "已有图片选择窗口正在打开", details: nil))
      return
    }
    guard let presenter = topViewController() else {
      result(FlutterError(code: "no_presenter", message: "无法打开图片选择器", details: nil))
      return
    }
    pendingImagePickResult = result
    var config = PHPickerConfiguration(photoLibrary: .shared())
    config.selectionLimit = 1
    config.filter = .images
    let picker = PHPickerViewController(configuration: config)
    picker.delegate = self
    picker.presentationController?.delegate = self
    presenter.present(picker, animated: true)
  }

  private func activeRootViewController() -> UIViewController? {
    if let root = window?.rootViewController {
      return root
    }
    let windowScenes = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
    if let activeRoot = windowScenes
      .first(where: { $0.activationState == .foregroundActive })?
      .windows.first(where: { $0.isKeyWindow })?
      .rootViewController {
      return activeRoot
    }
    return windowScenes
      .flatMap { $0.windows }
      .first(where: { $0.isKeyWindow || $0.rootViewController != nil })?
      .rootViewController
  }

  private func topViewController() -> UIViewController? {
    var current = activeRootViewController()
    while let presented = current?.presentedViewController {
      current = presented
    }
    return current
  }

  func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
    guard let pending = pendingImagePickResult else {
      return
    }
    pendingImagePickResult = nil
    pending(nil)
  }

  func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
    picker.dismiss(animated: true)
    guard let pending = pendingImagePickResult else {
      return
    }
    pendingImagePickResult = nil
    guard let first = results.first else {
      pending(nil)
      return
    }
    let provider = first.itemProvider
    let fileName = provider.suggestedName ?? "local_image"
    guard provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) else {
      pending(FlutterError(code: "unsupported_type", message: "所选项目不是受支持的图片格式", details: nil))
      return
    }
    let limitBytes = maxLocalImageBytes
    provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, error in
      DispatchQueue.main.async {
        if let error = error {
          pending(FlutterError(code: "read_failed", message: error.localizedDescription, details: nil))
          return
        }
        guard let data = data, !data.isEmpty else {
          pending(FlutterError(code: "empty_image", message: "读取本地图片内容为空", details: nil))
          return
        }
        if data.count > limitBytes {
          pending(FlutterError(code: "image_too_large", message: "所选图片超过 25 MB 大小限制", details: nil))
          return
        }
        pending([
          "name": fileName,
          "bytes": FlutterStandardTypedData(bytes: data),
        ])
      }
    }
  }
}
