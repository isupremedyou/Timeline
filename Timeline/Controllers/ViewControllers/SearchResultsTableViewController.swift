//
//  SearchResultsTableViewController.swift
//  Timeline
//
//  Created by Travis Chapman on 11/6/18.
//  Copyright © 2018 Travis Chapman. All rights reserved.
//

import UIKit

class SearchResultsTableViewController: UITableViewController {
    
    // MARK: - Constants & Variables
    
    var resultsArray = [SearchableRecord]() {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    // MARK: - Outlets
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UINib(nibName: "PostCell", bundle: nil), forCellReuseIdentifier: "postCell")
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return resultsArray.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "postCell", for: indexPath) as! PostTableViewCell

        guard let post = resultsArray[indexPath.row] as? Post else { return UITableViewCell() }
        
        cell.post = post
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard let selectedCell = tableView.cellForRow(at: indexPath) as? PostTableViewCell
            else { return }
        
        self.presentingViewController?.performSegue(withIdentifier: "toPostDetailVC", sender: selectedCell)
    }
}
