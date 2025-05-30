import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  func scene(_ scene: UIScene,
             willConnectTo session: UISceneSession,
             options connectionOptions: UIScene.ConnectionOptions) {
    guard let ws = (scene as? UIWindowScene) else { return }
    let window = UIWindow(windowScene: ws)
    let rootVC = CountriesViewController()
    window.rootViewController = UINavigationController(rootViewController: rootVC)
    window.makeKeyAndVisible()
    self.window = window
  }
}
