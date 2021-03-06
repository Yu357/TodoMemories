//
//  Todo.swift
//  TodoDiary
//
//  Created by Yu on 2021/09/16.
//

import Foundation
import RealmSwift
import WidgetKit

class Todo: Object, Identifiable {
    //Todoの列定義
    @Persisted(primaryKey: true) var id = 0
    @Persisted var order = -1
    @Persisted var content = ""
    @Persisted var isPinned = false
    @Persisted var isAchieved = false
    @Persisted var achievedDate = Date()
    @Persisted var achievedYmd = 0
    
    //realmインスタンス
    static func customRealm() -> Realm {
        var realm: Realm {
            let config = customRealmConfig()
            let realm = try! Realm(configuration: config)
            return realm
        }
        return realm
    }
    
    static func customRealmConfig() -> Realm.Configuration {
        var config = Realm.Configuration(
            // Realmのスキーマのバージョンを管理
            schemaVersion: 6,
            migrationBlock: { migration, oldSchemaVersion in
                if (oldSchemaVersion < 6) {
                    //Do nothing
                }
            }
        )
        let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.example.y.TodoDiary")!
        config.fileURL = url.appendingPathComponent("db.realm")
        return config
    }
    
    //全てのレコード
    static func all() -> Results<Todo> {
        let realm = Todo.customRealm()
        return realm.objects(Todo.self)
    }
    
    //未達成Todo
    static func unachievedTodos() -> Results<Todo> {
        let realm = Todo.customRealm()
        return realm.objects(Todo.self).filter("isAchieved == false").sorted(byKeyPath: "order", ascending: true)
    }
    
    //固定済み未達成Todo
    static func pinnedTodos() -> Results<Todo> {
        let realm = Todo.customRealm()
        return realm.objects(Todo.self).filter("isPinned == true && isAchieved == false").sorted(byKeyPath: "order", ascending: true)
    }
    
    //未固定未達成Todo
    static func unpinnedTodos() -> Results<Todo> {
        let realm = Todo.customRealm()
        return realm.objects(Todo.self).filter("isPinned == false && isAchieved == false").sorted(byKeyPath: "order", ascending: true)
    }
    
    //達成済みTodo
    static func achievedTodos() -> Results<Todo> {
        let realm = Todo.customRealm()
        return realm.objects(Todo.self).filter("isAchieved == true").sorted(byKeyPath: "achievedDate", ascending: false)
    }
    
    //0件の結果
    static func noRecord() -> Results<Todo> {
        let realm = Todo.customRealm()
        return realm.objects(Todo.self).filter("id == -1")
    }
    
    //指定されたidのTodo
    static func oneTodoById(id: Int) -> Todo {
        let realm = Todo.customRealm()
        return realm.object(ofType: Todo.self, forPrimaryKey: id)!
    }
    
    //指定された年月日に達成されたTodo
    static func todosOfTheDay(achievedYmd: Int, isAscending: Bool) -> Results<Todo> {
        let realm = Todo.customRealm()
        return realm.objects(Todo.self).filter("isAchieved == true && achievedYmd == \(achievedYmd)").sorted(byKeyPath: "achievedDate", ascending: isAscending)
    }
    
    //指定された年月内の各日に達成されたTodoの数の配列
    static func countsOfTodoInMonth(year: Int, month: Int) -> [Int] {
        // Realmオブジェクト生成
        let realm = Todo.customRealm()
        
        // その月の日数を取得
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month + 1
        dateComponents.day = 0
        let date = Calendar.current.date(from: dateComponents)!
        let dayCountInMonth = Calendar.current.component(.day, from: date)
        
        // counts配列生成開始
        var counts: [Int] = []
        for index in 1...dayCountInMonth {
            // YMDを生成
            let achievedYmd = year * 10000 + month * 100 + index
            
            // 指定の年月日に達成したtodosを読み取り
            let count = realm.objects(Todo.self).filter("isAchieved == true && achievedYmd == \(achievedYmd)").sorted(byKeyPath: "achievedDate").count
            counts.append(count)
        }

        return counts
    }
    
    // 指定された年月日に達成されたTodoの数
    static func countOfTodoAtDay(year: Int, month: Int, day: Int) -> Int {
        
        let achievedYmd = year * 10000 + month * 100 + day
        
        let realm = Todo.customRealm()
        let count = realm.objects(Todo.self).filter("isAchieved == true && achievedYmd == \(achievedYmd)").sorted(byKeyPath: "achievedDate").count
        return count
    }
    
    //新規Todo追加
    static func insertTodo(content: String, isPinned: Bool, isAchieved: Bool, achievedDate: Date) {
        let realm = Todo.customRealm()
        //新規レコード用のidを生成
        let maxId = realm.objects(Todo.self).sorted(byKeyPath: "id").last?.id ?? 0
        let newId = maxId + 1
        //新規レコード用のorderを生成
        var newOrder = 0
        if !isAchieved {
            var maxOrder = 0
            if !isPinned {
                maxOrder = Todo.unpinnedTodos().sorted(byKeyPath: "order").last?.order ?? -1
            } else {
                maxOrder = Todo.pinnedTodos().sorted(byKeyPath: "order").last?.order ?? -1
            }
            newOrder = maxOrder + 1
        } else {
            newOrder = -1
        }
        //新規レコード生成
        let todo = Todo()
        todo.id = newId
        todo.order = newOrder
        todo.content = content
        todo.isPinned = isPinned
        todo.isAchieved = isAchieved
        if isAchieved {
            todo.achievedDate = achievedDate
            let calendar = Calendar(identifier: .gregorian)
            let year = calendar.component(.year, from: achievedDate)
            let month = calendar.component(.month, from: achievedDate)
            let day = calendar.component(.day, from: achievedDate)
            todo.achievedYmd = year * 10000 + month * 100 + day
        }
        //新規レコード追加
        try! realm.write {
            realm.add(todo)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    //Todo更新
    static func updateTodo(id: Int, content: String, isPinned: Bool, isAchieved: Bool, achievedDate: Date) {
        let realm = Todo.customRealm()
        let todo = oneTodoById(id: id)
        try! realm.write {
            todo.content = content
            todo.isPinned = isPinned
            todo.isAchieved = isAchieved
            if isAchieved {
                todo.achievedDate = achievedDate
                let calendar = Calendar(identifier: .gregorian)
                let year = calendar.component(.year, from: achievedDate)
                let month = calendar.component(.month, from: achievedDate)
                let day = calendar.component(.day, from: achievedDate)
                todo.achievedYmd = year * 10000 + month * 100 + day
            }
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    //Todoのcontentを更新
    static func updateTodoContentAndDate(id: Int, newContent: String, newAchievedDate: Date) {
        let realm = Todo.customRealm()
        let todo = oneTodoById(id: id)
        try! realm.write {
            todo.content = newContent
            todo.achievedDate = newAchievedDate
            let calendar = Calendar(identifier: .gregorian)
            let year = calendar.component(.year, from: newAchievedDate)
            let month = calendar.component(.month, from: newAchievedDate)
            let day = calendar.component(.day, from: newAchievedDate)
            todo.achievedYmd = year * 10000 + month * 100 + day
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    //Todo削除
    static func deleteTodo(id: Int) {
        let realm = Todo.customRealm()
        //もし未達成Todoを削除するなら、選択されたTodo以降のTodoのorderをデクリメントする
        let todo = oneTodoById(id: id)
        if !todo.isAchieved {
            decrementTodos(isPinnedTodos: todo.isPinned, id: id)
        }
        //選択されたTodoを削除
        try! realm.write {
            realm.delete(todo)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    //Todoを固定する
    static func pinTodo(id: Int) {
        let realm = Todo.customRealm()
        //選択されたTodo以降のunpinnedTodosのTodoのorderをデクリメント
        decrementTodos(isPinnedTodos: false, id: id)
        //選択されたTodoを固定し、pinnedTodosの後尾に追加
        let todo = oneTodoById(id: id)
        let maxOrder = Todo.pinnedTodos().sorted(byKeyPath: "order").last?.order ?? -1
        let newOrder = maxOrder + 1
        try! realm.write {
            todo.isPinned = true
            todo.order = newOrder
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    //Todoの固定を解除する
    static func unpinTodo(id: Int) {
        let realm = Todo.customRealm()
        //選択されたTodo以降のpinnedTodosのTodoのorderをデクリメント
        decrementTodos(isPinnedTodos: true, id: id)
        //unpinnedTodosの全Todoのorderをインクリメント
        // Realmコレクションは通常ライブ。今回は凍結して扱う
        let unpinnedTodos = Todo.unpinnedTodos().freeze()
        try! realm.write {
            for index in 0..<unpinnedTodos.count {
                // Realmオブジェクトのプロパティを更新するときだけ、Realmオブジェクトを解凍する
                unpinnedTodos[index].thaw()!.order = unpinnedTodos[index].order + 1
            }
        }
        //選択されたTodoの固定を解除し、unPinnedTodosの先頭に追加
        let todo = oneTodoById(id: id)
        try! realm.write {
            todo.isPinned = false
            todo.order = 0
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    //Todoを達成済みに変更する
    static func achieveTodo(id: Int, achievedDate: Date) {
        let realm = Todo.customRealm()
        //選択されたTodo以降のTodoのorderをデクリメント
        let todo = oneTodoById(id: id)
        decrementTodos(isPinnedTodos: todo.isPinned, id: id)
        //選択されたTodoを達成済みにする
        try! realm.write {
            todo.order = -1
            todo.isPinned = false
            todo.isAchieved = true
            todo.achievedDate = achievedDate
            let calendar = Calendar(identifier: .gregorian)
            let year = calendar.component(.year, from: achievedDate)
            let month = calendar.component(.month, from: achievedDate)
            let day = calendar.component(.day, from: achievedDate)
            todo.achievedYmd = year * 10000 + month * 100 + day
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    //Todoを未達成に戻す
    static func unachieveTodo(id: Int) {
        let realm = Todo.customRealm()
        let todo = oneTodoById(id: id)
        let maxOrder = Todo.unpinnedTodos().sorted(byKeyPath: "order").last?.order ?? -1
        let newOrder = maxOrder + 1
        try! realm.write {
            todo.order = newOrder
            todo.isAchieved = false
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    //Todoのorderを変更する
    static func changeOrder(id: Int, newOrder: Int) {
        let realm = Todo.customRealm()
        let todo = oneTodoById(id: id)
        try! realm.write {
            todo.order = newOrder
        }
    }
    
    //Todoを並べ替え
    static func sortTodos(todos: Results<Todo>, sourceIndexSet: IndexSet, destination: Int) {
        guard let source = sourceIndexSet.first else {
            return
        }
        let moveId = todos[source].id
        if source < destination {
            print("HELLO \(todos[source].content) down")
            for i in (source + 1)...(destination - 1) {
                Todo.changeOrder(id: todos[i].id, newOrder: todos[i].order - 1)
            }
            Todo.changeOrder(id: moveId, newOrder: destination - 1)
        }
        if destination < source {
            print("HELLO \(todos[source].content) up")
            for i in (destination...(source - 1)).reversed() {
                Todo.changeOrder(id: todos[i].id, newOrder: todos[i].order + 1)
            }
            Todo.changeOrder(id: moveId, newOrder: destination)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    //指定したTodos配列の特定のTodo以降のTodoをデクリメント
    static func decrementTodos(isPinnedTodos: Bool, id: Int) {
        let todos = isPinnedTodos ? Todo.pinnedTodos() : Todo.unpinnedTodos()
        let todo = oneTodoById(id: id)
        let selectedOrder = todo.order
        let todosMaxOrder = todos.sorted(byKeyPath: "order").last?.order ?? -1
        if selectedOrder != todosMaxOrder {
            for index in selectedOrder + 1 ... todosMaxOrder {
                Todo.changeOrder(id: todos[index].id, newOrder: todos[index].order - 1)
            }
        }
    }
}
