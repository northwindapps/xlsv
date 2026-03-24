class BackupTableViewController: UITableViewController {
    
    var backupFiles: [URL] = []
    let cellId = "cell"

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellId)
        
        loadData()
    }
    
    func loadData() {
        self.backupFiles = ExcelHelper().getBackupFiles()
        tableView.reloadData()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return backupFiles.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
        let fileURL = backupFiles[indexPath.row]
        
        var content = cell.defaultContentConfiguration()
        content.text = fileURL.lastPathComponent 
        cell.contentConfiguration = content
        
        return cell
    }
}

