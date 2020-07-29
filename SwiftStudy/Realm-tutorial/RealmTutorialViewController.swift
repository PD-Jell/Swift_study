//
//  RealmTutorialViewController.swift
//  SwiftStudy
//
//  Created by YooHG on 7/23/20.
//  Copyright © 2020 Jell PD. All rights reserved.
//

import UIKit
import Foundation
import RealmSwift
import RxRealm
import RxSwift
import RxCocoa

class Dog: Object {
    @objc dynamic var name = ""
    @objc dynamic var age = 0
    @objc dynamic var time: TimeInterval = Date().timeIntervalSinceReferenceDate
    
    init(name: String?, age: Int?) {
        super.init()
        self.name = name ?? ""
        self.age = age ?? 0
    }
    
    required init() {
        super.init()
        self.name = ""
        self.age = 0
    }
    
        override static func indexedProperties() -> [String] {
            return ["name"]
        }
}

class Person: Object {
    @objc dynamic var name = ""
    @objc dynamic var picture: Data? = nil
    let dogs = List<Dog>()
    
    override class func indexedProperties() -> [String] {
        return ["name"]
    }
}

class RealmTutorialViewController: UIViewController {
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var addBtn: UIButton!
    @IBOutlet var tickBtn: UIButton!
    
    var dogs: Results<Dog>!
    
    let bag = DisposeBag()
    
    lazy var dog: Dog = {
        let realm = try! Realm()
        let dog = Dog()
//        try! realm.write {
//            realm.add(dog)
//        }
        return dog
    }()
    
    let config = Realm.Configuration(
        schemaVersion: 2,
        migrationBlock:  { migration, oldSchemaVersion in
            // 아무것도 안써도 대부분 알아서 마이그레이션 해줌.
    }
    )
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        Realm.Configuration.defaultConfiguration = config
        let realm = try! Realm()
        dogs = realm.objects(Dog.self)
            .sorted(byKeyPath: "time", ascending: false)
        
        Observable.collection(from: dogs)
            .map ({"dogs: \($0.count)"})
            .subscribe { event in
                self.title = event.element
        }
        .disposed(by: bag)
        
        
        addBtn.rx.tap
            .map{ [Dog(name: "dogname1", age: 4), Dog(name: "dogname2", age: 5)] }
            .bind(to: Realm.rx.add(onError: {
                if $0 != nil {
                    print("Error \($1.localizedDescription) while saving objects \(String(describing: $0))")
                } else {
                    print("Error \($1.localizedDescription) while opening realm.")
                }
            }))
            .disposed(by: bag)
        
//        tickBtn.rx.tap
//            .subscribe(onNext: { [unowned self] _ in
//                try! realm.write {
//                    self.ticker.ticks += 1
//                }
//            })
        
        
        
        let myDog = Dog()
        myDog.name = "Rex"
        myDog.age = 1
        print("name of dog: \(myDog.name)")
        
        
        let puppies = realm.objects(Dog.self)
        //            .filter("age < 2")
        print(puppies.elements)
        print(puppies.count)
        
        try! realm.write {
            realm.add(myDog)
        }
        
        print(puppies.count)
        
        DispatchQueue(label: "background").async {
            autoreleasepool {
                let realm = try! Realm()
                let theDog = realm.objects(Dog.self).filter("age == 1").first
                try! realm.write {
                    theDog!.age = 3
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        Observable.changeset(from: dogs)
            .subscribe(onNext: { [unowned self] _, changes in
                if let changes = changes {
                    self.tableView.applyChangeset(changes)
                } else {
                    self.tableView.reloadData()
                }
                
            }).disposed(by: bag)
    }
}

extension RealmTutorialViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dogs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let dog = self.dogs[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
//        cell.textLabel?.text = formatter.string(from: Date(timeIntervalSinceReferenceDate: dog.time))
        cell.textLabel?.text = Formatter().string(for: Date(timeIntervalSinceReferenceDate: dog.time))
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Delete objects by tapping them, add ticks to trigger a footer update"
    }
}

extension RealmTutorialViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        Observable.from([self.dogs[indexPath.row]])
            .subscribe(Realm.rx.delete())
//            .disposed(by: bag)
            .disposed(by: self.bag)
    }
    
//    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
//        return footer
//    }
}

extension UITableView {
    func applyChangeset(_ changes: RealmChangeset) {
        beginUpdates()
        deleteRows(at: changes.deleted.map { IndexPath(row: $0, section: 0) }, with: .automatic)
        insertRows(at: changes.inserted.map { IndexPath(row: $0, section: 0) }, with: .automatic)
        reloadRows(at: changes.updated.map { IndexPath(row: $0, section: 0) }, with: .automatic)
        endUpdates()
    }
}
