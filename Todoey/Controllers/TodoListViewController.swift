//
//  TodoListViewController.swift
//  Todoey
//
//  Created by Jason Becker on 5/6/19.
//  Copyright © 2019 Jason Becker. All rights reserved.
//

import UIKit
import RealmSwift
import ChameleonFramework

class TodoListViewController: SwipeTableViewController {
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    var toDoItems: Results<Item>?
    
    let realm = try! Realm()
    
    var selectedCategory : Category? {
        didSet{
            loadItems()
        }
    }
    

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        //print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        title = selectedCategory?.name
        
        guard let colorHex = selectedCategory?.backgroundColor else { fatalError() }
        
        updateNavBar(withHexCode: colorHex)

    }
    
    override func viewWillDisappear(_ animated: Bool) {
    
        updateNavBar(withHexCode: "#1D9BF6")
        
    }
    
    //MARK: - Nav Bar Setup Methods
    func updateNavBar(withHexCode colorHexCode: String) {
        
        guard let navBar = navigationController?.navigationBar else { fatalError("Navigation Controller does not exist") }
        
        guard let navBarColor = UIColor(hexString: colorHexCode) else { fatalError() }
        
        navBar.barTintColor = navBarColor
        
        searchBar.barTintColor = navBarColor
        
        navBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor : ContrastColorOf(navBarColor, returnFlat: true)]
        
        navBar.tintColor = ContrastColorOf(navBarColor, returnFlat: true)
        
    }
    
    
    //MARK: - Tableview Datasource Methods
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return toDoItems?.count ?? 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        
        if let item = toDoItems?[indexPath.row] {
           
            cell.textLabel?.text = item.title
            
            if let color = UIColor(hexString: selectedCategory!.backgroundColor)?.darken(byPercentage: CGFloat(indexPath.row) / CGFloat(toDoItems!.count)) {
                
                let prevColor = UIColor(hexString: selectedCategory!.backgroundColor)?.darken(byPercentage: CGFloat(indexPath.row - 1 ) / CGFloat(toDoItems!.count))
                let rectOfCell = tableView.rectForRow(at: indexPath)
                //let rectOfCellInSuperview = tableView.convert(rectOfCell, to: tableView.superview)
                
                cell.backgroundColor = UIColor(gradientStyle: .topToBottom, withFrame: rectOfCell, andColors: [prevColor!, color])
                
                cell.layer.borderWidth = 0.25
                cell.layer.borderColor = UIColor.gray.cgColor
                
                //cell.backgroundColor = color
                cell.textLabel?.textColor = ContrastColorOf(color, returnFlat: true)
                cell.tintColor = ContrastColorOf(color, returnFlat: true)
            }
            
//            cell.backgroundColor = FlatSkyBlue().darken(byPercentage: CGFloat(indexPath.row / toDoItems.count))
            
            cell.accessoryType = item.done ? .checkmark : .none
            
        }
        else {
            
            cell.textLabel?.text = "No Items Added"
        }
        
        return cell
    }
    
    
    //MARK: - TableView Delegate Methods
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        
        if let item = toDoItems?[indexPath.row] {
            do {
                try realm.write {
                    item.done = !item.done
                    //realm.delete(item)
                }
            }
            catch{
                print("Error saving done status \(error)")
            }
        }
        
        
        tableView.reloadData()
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
    //MARK: - Add New Items
    
    
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        
        var textField = UITextField()
        
        let alert = UIAlertController(title: "Add New Todoey Item", message: "", preferredStyle: .alert)
        
        let action = UIAlertAction(title: "Add Item", style: .default) { (action) in
            // what will happen on click Add item button on UI Alert
            
            if let currentCategory = self.selectedCategory {
                do {
                    try self.realm.write {
                        let newItem = Item()
                        newItem.title = textField.text!
                        newItem.dateCreated = Date()
                        currentCategory.items.append(newItem)
                    }
                }
                catch {
                    print("Error saving new Items \(error)")
                }
               
            }
            
            
            self.tableView.reloadData()
            
            
        }
        
        alert.addTextField { (alertTextField) in
            alertTextField.placeholder = "Create New Item"
            textField = alertTextField
        }
        
        alert.addAction(action)
        
        present(alert, animated: true)
        
    }
    
    //MARK: - Model Manipulation Methods
    
    override func updateModel(at indexPath: IndexPath) {
        if let item = self.toDoItems?[indexPath.row] {
            do {
                try self.realm.write {
                    self.realm.delete(item)
                }
            }
            catch {
                print("Error deleting item, \(error)")
            }
        }
    }
    
    func loadItems() {
        
        toDoItems = selectedCategory?.items.sorted(byKeyPath: "title", ascending: true)


        tableView.reloadData()
    }
    
    
    
    
}

//MARK: - Search Bar Methods

extension TodoListViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {

      toDoItems = toDoItems?.filter("title CONTAINS[cd] %@", searchBar.text!).sorted(byKeyPath: "dateCreated", ascending: true)
        tableView.reloadData()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text?.count == 0 {
            loadItems()
            
            DispatchQueue.main.async {
                
                searchBar.resignFirstResponder()
                
            }
            
        }
    }
    
}
