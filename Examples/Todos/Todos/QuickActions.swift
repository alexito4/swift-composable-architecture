
import UIKit
import ComposableArchitecture


extension Reducer where State == AppState, Action == AppAction, Environment == AppEnvironment {
    func quickActionable() -> Reducer {
        Reducer { state, action, environment in
            let effect = self(&state, action, environment)
            
            if case let AppAction.handleQuickAction(todoId: id) = action {
                return .init(value: .todo(id: id, action: .checkBoxToggled))
            }
            
            let quickActions = state.todos.elements
                .filter { $0.isComplete == false }
                .map { todo in
                    UIApplicationShortcutItem(
                        type: "MarkTodoAsDone",
                        localizedTitle: todo.description,
                        localizedSubtitle: nil,
                        icon: nil,
                        userInfo: [
                            UIApplicationShortcutItem.todoIdKey: todo.id.uuidString as NSSecureCoding
                        ]
                    )
                }
            environment.updateQuickActions(quickActions)
            
            return effect
        }
    }
}

extension UIApplicationShortcutItem {
    static let todoIdKey = "todoId"
    
    var todoId: UUID? {
        (userInfo?[Self.todoIdKey] as? String).flatMap(UUID.init(uuidString:))
    }
}
