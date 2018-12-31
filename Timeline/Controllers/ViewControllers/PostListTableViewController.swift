//
//  PostListTableViewController.swift
//  Timeline
//
//  Created by Travis Chapman on 11/6/18.
//  Copyright © 2018 Travis Chapman. All rights reserved.
//

import UIKit

class PostListTableViewController: UITableViewController {

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpSearchController()
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadTableView), name: PostController.PostsChangedNotification, object: nil)
        
        tableView.register(UINib(nibName: "PostCell", bundle: nil), forCellReuseIdentifier: "postCell")
    }
    
    // MARK: - Actions
    
    @IBAction func refreshControlPulled(_ sender: UIRefreshControl) {
        
        refreshPosts()
    }
    
    
    // MARK: - Functions
    
    @objc func refreshPosts() {
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        PostController.shared.fetchPosts { (success) in
            if success {
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    self.tableView.refreshControl?.endRefreshing()
                }
            }
        }
    }
    
    @objc func reloadTableView() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func setUpSearchController() {
        
        let searchResultsVC = SearchResultsTableViewController()
        let searchController = UISearchController(searchResultsController: searchResultsVC as SearchResultsTableViewController)
        searchController.searchResultsUpdater = self
        
        self.definesPresentationContext = true
        self.navigationItem.searchController = searchController
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return PostController.shared.posts.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "postCell", for: indexPath) as! PostTableViewCell

        let post = PostController.shared.posts[indexPath.row]
        
        cell.post = post

        return cell
    }

    // MARK: - Navigation
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard let selectedCell = tableView.cellForRow(at: indexPath) as? PostTableViewCell
            else { return }
        
        self.performSegue(withIdentifier: "toPostDetailVC", sender: selectedCell)
    }
    
    override func performSegue(withIdentifier identifier: String, sender: Any?) {
        
        guard let sender = sender as? PostTableViewCell else { return }
        
        let storyboard = UIStoryboard(name: "ViewPosts", bundle: nil)
        
        if let index = tableView.indexPath(for: sender)?.row {
        
            guard let postDetailVC = storyboard.instantiateViewController(withIdentifier: "postDetailVC") as? PostDetailTableViewController else { return }
            
            let post = PostController.shared.posts[index]
            
            postDetailVC.post = post
            navigationController?.pushViewController(postDetailVC, animated: true)
            
            
        } else {

            guard let searchResultsVC = navigationItem.searchController?.searchResultsController as? SearchResultsTableViewController,
                let index = searchResultsVC.tableView.indexPath(for: sender)?.row
                else { return }

            let post = searchResultsVC.resultsArray[index] as? Post

            guard let postDetailVC = storyboard.instantiateViewController(withIdentifier: "postDetailVC") as? PostDetailTableViewController else { return }
            
            postDetailVC.post = post
            navigationController?.pushViewController(postDetailVC, animated: true)
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toPostDetailVC" {
            guard let destinationVC = segue.destination as? PostDetailTableViewController else { return }
            
            guard let index = tableView.indexPathForSelectedRow?.row else { return }
            
            let post = PostController.shared.posts[index]
            
            destinationVC.post = post
        }
    }
}

// MARK: - Class Extensions

extension PostListTableViewController: UISearchResultsUpdating, UISearchControllerDelegate {
    
    func updateSearchResults(for searchController: UISearchController) {
        
        guard let resultsViewController = searchController.searchResultsController as? SearchResultsTableViewController else { return }
        
        guard let searchTerm = searchController.searchBar.text else { return }
        
        var resultsArray = [SearchableRecord]()
        
        for post in PostController.shared.posts {
            if post.matches(searchTerm: searchTerm) {
                
                resultsArray.append(post)
            }
        }
        resultsViewController.resultsArray = resultsArray
    }
    
    
}
