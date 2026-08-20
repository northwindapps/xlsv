//
//  SettingsViewController.swift
//  MultiDirectionCollectionView
//
//  Created by yujinyano on 2018/09/07.
//  Copyright © 2018年 Credera. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController,UITextFieldDelegate {

     @IBOutlet weak var cellWidthlabel: UILabel!
    var idx:Int?

    @IBOutlet weak var `return`: UIButton!

    // Added purely in code (not the storyboard) so it appears consistently on
    // both storyboard scenes that reuse this class ("Settings" and
    // "SettingsViewController" identifiers) without depending on either
    // scene's own layout. Controls AppDelegate.fullFormulaRecalcEnabled, read
    // by ViewController/FileFillViewController's recalculateAfterEdit.
    private let fullFormulaRecalcLabel = UILabel()
    private let fullFormulaRecalcSwitch = UISwitch()

    private func setUpFullFormulaRecalcToggle() {
        let appd = UIApplication.shared.delegate as! AppDelegate

        fullFormulaRecalcLabel.text = "Full Formula Recalc"
        fullFormulaRecalcLabel.font = UIFont.systemFont(ofSize: 15)
        fullFormulaRecalcLabel.translatesAutoresizingMaskIntoConstraints = false

        fullFormulaRecalcSwitch.isOn = appd.fullFormulaRecalcEnabled
        fullFormulaRecalcSwitch.translatesAutoresizingMaskIntoConstraints = false
        fullFormulaRecalcSwitch.addTarget(self, action: #selector(fullFormulaRecalcToggled(_:)), for: .valueChanged)

        view.addSubview(fullFormulaRecalcLabel)
        view.addSubview(fullFormulaRecalcSwitch)

        NSLayoutConstraint.activate([
            fullFormulaRecalcSwitch.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            fullFormulaRecalcSwitch.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            fullFormulaRecalcLabel.centerYAnchor.constraint(equalTo: fullFormulaRecalcSwitch.centerYAnchor),
            fullFormulaRecalcLabel.trailingAnchor.constraint(equalTo: fullFormulaRecalcSwitch.leadingAnchor, constant: -8),
            fullFormulaRecalcLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 16)
        ])
    }

    @objc private func fullFormulaRecalcToggled(_ sender: UISwitch) {
        let appd = UIApplication.shared.delegate as! AppDelegate
        appd.fullFormulaRecalcEnabled = sender.isOn
    }

       @IBAction func exsmallCell(_ sender: Any) {
           let location1 = UserDefaults.standard
           location1.set(0, forKey: "cellSize")
           location1.synchronize()
           showAnimate()
       }
       @IBAction func smallCell(_ sender: Any) {
           let location1 = UserDefaults.standard
           location1.set(1, forKey: "cellSize")
           location1.synchronize()
           showAnimate()
       }
       
       @IBAction func middiumCell(_ sender: Any) {
           let location1 = UserDefaults.standard
           location1.set(2, forKey: "cellSize")
           location1.synchronize()
           showAnimate()
       }
       
       
       @IBAction func largeCell(_ sender: Any) {
           let location1 = UserDefaults.standard
           location1.set(3, forKey: "cellSize")
           location1.synchronize()
           showAnimate()
       }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setUpFullFormulaRecalcToggle()

        // Shared between v2 and v3 (this screen isn't duplicated) -- only shown to users who
        // actually have recovered legacy sheets waiting in Documents/RecoveredFiles/. See
        // V2LegacyMigration.swift for how they get there.
        if V2LegacyMigration.hasRecoveredFiles() {
            addRecoveredFilesButton()
        }

        // Do any additional setup after loading the view.
    }

    private func addRecoveredFilesButton() {
        let recoveredButton = UIButton(type: .system)
        recoveredButton.setTitle("Recovered Files", for: .normal)
        recoveredButton.backgroundColor = UIColor.white
        recoveredButton.layer.borderWidth = 1.0
        recoveredButton.layer.borderColor = UIColor.gray.cgColor
        recoveredButton.layer.cornerRadius = 6
        recoveredButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        recoveredButton.contentEdgeInsets = UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)
        recoveredButton.translatesAutoresizingMaskIntoConstraints = false
        recoveredButton.addTarget(self, action: #selector(showRecoveredFiles), for: .touchUpInside)
        view.addSubview(recoveredButton)
        NSLayoutConstraint.activate([
            recoveredButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 4),
            recoveredButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 8)
        ])
    }

    @objc private func showRecoveredFiles() {
        let listViewController = V2RecoveredFilesViewController()
        let nav = UINavigationController(rootViewController: listViewController)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
      
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func showAnimate() -> Bool
    {
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        if appd.imported_xlsx_file_path == "" {
            let next = UIStoryboard(name: "Manager", bundle: nil).instantiateViewController(withIdentifier: "Home") as! HomeController
            next.modalPresentationStyle = .fullScreen
            self.present(next,animated: true, completion: nil)
            return true
        }
        
        print("go to file view")
        let targetViewController = self.storyboard!.instantiateViewController( withIdentifier: "LoadingFileController" ) as! LoadingFileController //Landscape
        targetViewController.idx = idx
        targetViewController.modalPresentationStyle = .fullScreen
        // Present the target view controller after LoadingFileController's view has appeared
        DispatchQueue.main.async {
            self.present(targetViewController, animated: true, completion: nil)
        }
        
        return true
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
 

}
