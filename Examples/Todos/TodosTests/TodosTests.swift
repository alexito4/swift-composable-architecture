import ComposableArchitecture
import XCTest

@testable import Todos

class TodosTests: XCTestCase {
  let scheduler = DispatchQueue.testScheduler

  func testAddTodo() {
    let store = TestStore(
      initialState: AppState(),
      reducer: appReducer,
      environment: AppEnvironment(
        mainQueue: self.scheduler.eraseToAnyScheduler(),
        uuid: UUID.incrementing,
        updateQuickActions: { _ in }
      )
    )

    store.assert(
      .send(.addTodoButtonTapped) {
        $0.todos.insert(
          Todo(
            description: "",
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
            isComplete: false
          ),
          at: 0
        )
      }
    )
  }

  func testEditTodo() {
    let state = AppState(
      todos: [
        Todo(
          description: "",
          id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
          isComplete: false
        )
      ]
    )
    let store = TestStore(
      initialState: state,
      reducer: appReducer,
      environment: AppEnvironment(
        mainQueue: self.scheduler.eraseToAnyScheduler(),
        uuid: UUID.incrementing,
        updateQuickActions: { _ in }
      )
    )

    store.assert(
      .send(
        .todo(id: state.todos[0].id, action: .textFieldChanged("Learn Composable Architecture"))
      ) {
        $0.todos[0].description = "Learn Composable Architecture"
      }
    )
  }

  func testCompleteTodo() {
    let state = AppState(
      todos: [
        Todo(
          description: "",
          id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
          isComplete: false
        ),
        Todo(
          description: "",
          id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
          isComplete: false
        ),
      ]
    )
    let store = TestStore(
      initialState: state,
      reducer: appReducer,
      environment: AppEnvironment(
        mainQueue: self.scheduler.eraseToAnyScheduler(),
        uuid: UUID.incrementing,
        updateQuickActions: { _ in }
      )
    )

    store.assert(
      .send(.todo(id: state.todos[0].id, action: .checkBoxToggled)) {
        $0.todos[0].isComplete = true
      },
      .do { self.scheduler.advance(by: 1) },
      .receive(.sortCompletedTodos) {
        $0.todos = [
          $0.todos[1],
          $0.todos[0],
        ]
      }
    )
  }

  func testCompleteTodoDebounces() {
    let state = AppState(
      todos: [
        Todo(
          description: "",
          id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
          isComplete: false
        ),
        Todo(
          description: "",
          id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
          isComplete: false
        ),
      ]
    )
    let store = TestStore(
      initialState: state,
      reducer: appReducer,
      environment: AppEnvironment(
        mainQueue: self.scheduler.eraseToAnyScheduler(),
        uuid: UUID.incrementing,
        updateQuickActions: { _ in }
      )
    )

    store.assert(
      .send(.todo(id: state.todos[0].id, action: .checkBoxToggled)) {
        $0.todos[0].isComplete = true
      },
      .do { self.scheduler.advance(by: 0.5) },
      .send(.todo(id: state.todos[0].id, action: .checkBoxToggled)) {
        $0.todos[0].isComplete = false
      },
      .do { self.scheduler.advance(by: 1) },
      .receive(.sortCompletedTodos)
    )
  }

  func testClearCompleted() {
    let state = AppState(
      todos: [
        Todo(
          description: "",
          id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
          isComplete: false
        ),
        Todo(
          description: "",
          id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
          isComplete: true
        ),
      ]
    )
    let store = TestStore(
      initialState: state,
      reducer: appReducer,
      environment: AppEnvironment(
        mainQueue: self.scheduler.eraseToAnyScheduler(),
        uuid: UUID.incrementing,
        updateQuickActions: { _ in }
      )
    )

    store.assert(
      .send(.clearCompletedButtonTapped) {
        $0.todos = [
          $0.todos[0]
        ]
      }
    )
  }

  func testDelete() {
    let state = AppState(
      todos: [
        Todo(
          description: "",
          id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
          isComplete: false
        ),
        Todo(
          description: "",
          id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
          isComplete: false
        ),
        Todo(
          description: "",
          id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
          isComplete: false
        ),
      ]
    )
    let store = TestStore(
      initialState: state,
      reducer: appReducer,
      environment: AppEnvironment(
        mainQueue: self.scheduler.eraseToAnyScheduler(),
        uuid: UUID.incrementing,
        updateQuickActions: { _ in }
      )
    )

    store.assert(
      .send(.delete([1])) {
        $0.todos = [
          $0.todos[0],
          $0.todos[2],
        ]
      }
    )
  }

  func testEditModeMoving() {
    let state = AppState(
      todos: [
        Todo(
          description: "",
          id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
          isComplete: false
        ),
        Todo(
          description: "",
          id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
          isComplete: false
        ),
        Todo(
          description: "",
          id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
          isComplete: false
        ),
      ]
    )
    let store = TestStore(
      initialState: state,
      reducer: appReducer,
      environment: AppEnvironment(
        mainQueue: self.scheduler.eraseToAnyScheduler(),
        uuid: UUID.incrementing,
        updateQuickActions: { _ in }
      )
    )

    store.assert(
      .send(.editModeChanged(.active)) {
        $0.editMode = .active
      },
      .send(.move([0], 2)) {
        $0.todos = [
          $0.todos[1],
          $0.todos[0],
          $0.todos[2],
        ]
      },
      .do { self.scheduler.advance(by: .milliseconds(100)) },
      .receive(.sortCompletedTodos)
    )
  }

  func testFilteredEdit() {
    let state = AppState(
      todos: [
        Todo(
          description: "",
          id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
          isComplete: false
        ),
        Todo(
          description: "",
          id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
          isComplete: true
        ),
      ]
    )
    let store = TestStore(
      initialState: state,
      reducer: appReducer,
      environment: AppEnvironment(
        mainQueue: self.scheduler.eraseToAnyScheduler(),
        uuid: UUID.incrementing,
        updateQuickActions: { _ in }
      )
    )

    store.assert(
      .send(.filterPicked(.completed)) {
        $0.filter = .completed
      },
      .send(.todo(id: state.todos[1].id, action: .textFieldChanged("Did this already"))) {
        $0.todos[1].description = "Did this already"
      }
    )
  }
    
    func testQuickActions() {
        var quickActionsHistory: [[UIApplicationShortcutItem]?] = []
        
        let store = TestStore(
          initialState: AppState(),
          reducer: appReducer,
          environment: AppEnvironment(
            mainQueue: self.scheduler.eraseToAnyScheduler(),
            uuid: UUID.incrementing,
            updateQuickActions: { quickActionsHistory.append($0) }
          )
        )
        let id = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!

        store.assert(
            .send(.addTodoButtonTapped) {
                $0.todos.insert(
                    Todo(
                        description: "",
                        id:  id,
                        isComplete: false
                    ),
                    at: 0
                )
            },
            .do {
                XCTAssertEqual(quickActionsHistory.count, 1)
            },
            .send(.todo(id: id, action: .textFieldChanged("Cookies"))) {
                $0.todos[0].description = "Cookies"
            },
            .do {
                XCTAssertEqual(quickActionsHistory.count, 2)
                XCTAssertEqual(quickActionsHistory[1]?[0].localizedTitle, "Cookies")
            },
            .send(.handleQuickAction(todoId: id)) { _ in
                XCTAssertEqual(quickActionsHistory.count, 2)
            },
            .receive(.todo(id: id, action: .checkBoxToggled)) {
                $0.todos[0].isComplete = true
            },
            .do {
                XCTAssertEqual(quickActionsHistory.count, 3)
                XCTAssertTrue(quickActionsHistory[2]!.isEmpty)
            },
            .do { self.scheduler.advance(by: 1) },
            .receive(.sortCompletedTodos)
        )
    }
}

extension UUID {
  // A deterministic, auto-incrementing "UUID" generator for testing.
  static var incrementing: () -> UUID {
    var uuid = 0
    return {
      defer { uuid += 1 }
      return UUID(uuidString: "00000000-0000-0000-0000-\(String(format: "%012x", uuid))")!
    }
  }
}
