//
//  OptionsViewController.swift
//
//  Copyright (C) 2019 Kenneth H. Cox
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

import UIKit

class OptionsViewController: UIViewController {
    
    //MARK: - Properties
    
    @IBOutlet weak var table: UITableView!
    
    var options: [String] = []
    var selectedOption: String?
    var selectedPath: IndexPath?
    var selectionChangedHandler:  ((String) -> Void)?

    //MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    //MARK: - Functions
    
    func setupViews() {
        table.delegate = self
        table.dataSource = self
        table.tableFooterView = UIView() // prevent ghost rows at end of table
        self.updateCheckmarks()
    }
    
    func updateCheckmarks() {
        guard let paths = table?.indexPathsForVisibleRows else { return }
        
        for indexPath in paths {
            guard let cell = table.cellForRow(at: indexPath) else { continue }
            updateCheckmark(forCell: cell, indexPath: indexPath)
        }
    }
    
    func updateCheckmark(forCell cell: UITableViewCell, indexPath: IndexPath) {
        if indexPath == selectedPath {
            cell.accessoryType = .checkmark
        } else if cell.textLabel?.text?.trim() == selectedOption {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
    }
}

extension OptionsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }
    
//    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//        return ""
//    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "optionsCell", for: indexPath)
        
        cell.textLabel?.text = options[indexPath.row]
        updateCheckmark(forCell: cell, indexPath: indexPath)
        
        return cell
    }
}

extension OptionsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedPath = indexPath
        let selection = options[indexPath.row].trim()
        selectedOption = selection
        updateCheckmarks()
        tableView.deselectRow(at: indexPath, animated: true)
        selectionChangedHandler?(selection)
    }
}