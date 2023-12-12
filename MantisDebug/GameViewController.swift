//
//  GameViewController.swift
//  MantisDebug
//
//  Created by Bianca Silvestro  on 11/12/23.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let scene = GameScene(size: CGSize(width: screenWidth, height: screenHeigth))
        scene.scaleMode = .aspectFill
        
        let skView = view as! SKView
        skView.showsNodeCount = true
        skView.showsFPS = true
        skView.showsPhysics = true
        skView.ignoresSiblingOrder = false
        skView.presentScene (scene)
    }

    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
