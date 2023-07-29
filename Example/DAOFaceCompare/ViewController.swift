//
//  ViewController.swift
//  DAOFaceCompare
//
//  Created by DAO on 07/29/2023.
//  Copyright (c) 2023 DAO. All rights reserved.
//

import UIKit
import DAOFaceCompare

class ViewController: UIViewController {
    @IBOutlet weak var sameLabel: UILabel!
    @IBOutlet weak var diffLabel: UILabel!
    
    let image1 = UIImage(named: "weeknd1")!
    let image2 = UIImage(named: "weeknd2")!
    let image3 = UIImage(named: "Ariana")!
    let image4 = UIImage(named: "Taylor")!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            // Compare faces
            let faceCompare = try DAOFaceCompare()
            faceCompare.compare(image1, with: image2, completion: { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let score):
                    self.sameLabel.text = "similar: \(score)"
                case .failure(let error):
                    print(error.localizedDescription)
                }
            })
            
            faceCompare.compare(image3, with: image4, completion: { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let score):
                    self.diffLabel.text = "similar: \(score)"
                case .failure(let error):
                    print(error.localizedDescription)
                }
            })
            
        } catch {
            print(error.localizedDescription)
        }
    }

}

