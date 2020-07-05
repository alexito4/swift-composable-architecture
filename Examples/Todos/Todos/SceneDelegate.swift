import ComposableArchitecture
import SwiftUI
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?
 
    let store = Store(
      initialState: AppState(),
      reducer: appReducer,
      environment: AppEnvironment(
        mainQueue: DispatchQueue.main.eraseToAnyScheduler(),
        uuid: UUID.init,
        updateQuickActions: { UIApplication.shared.shortcutItems = $0 }
      )
    )
    
  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    self.window = (scene as? UIWindowScene).map(UIWindow.init(windowScene:))

    let rootView = AppView(
      store: store
    )

    self.window?.rootViewController = UIHostingController(rootView: rootView)
    self.window?.makeKeyAndVisible()
    
    if let shortcutItem = connectionOptions.shortcutItem {
        print(">> willConnectTo with shortcutItem: \(shortcutItem)")
        _ = handleQuickAction(shortcutItem)
    }
  }
    
    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        
        print(">> performActionFor: \(shortcutItem)")
        completionHandler(handleQuickAction(shortcutItem))
    }
    
    private func handleQuickAction(_ shortcutItem: UIApplicationShortcutItem) -> Bool {
        if let todoId = shortcutItem.todoId {
            ViewStore(store).send(.handleQuickAction(todoId: todoId))
            return true
        } else {
            return false
        }
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    true
  }
}
