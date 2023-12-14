//
//  GameOverOverlay.swift
//  MantisDebug
//
//  Created by Bianca Silvestro  on 12/12/23.
//

import SpriteKit

struct GOOverlaySettings {
    static let ContinueNode = "ContinueNode"
    static let ContinueLbl = "ContinueLbl"
    static let PlayNode = "PlayNode"
    static let PlayLbl = "PlayLbl"
}


class GameOverOverlay: BaseOverlay {
    //MARK: - Properties
    private var titleLbl: SKLabelNode!
    private var continueLbl: SKLabelNode!
    private var continueNode: SKShapeNode!
    
    private var playLbl: SKLabelNode!
    private var playNode: SKShapeNode!
    
    
    var isContinue = false {
        didSet{
            updateBtn(true, event: isContinue, node: continueNode)
            updateBtn(true, event: isContinue, node: continueLbl)
        }
    }
    
    var isPlay = false{
        didSet{
            updateBtn(true, event: isContinue, node: playNode)
            updateBtn(true, event: isContinue, node: playLbl)
        }
        
    }
    
    
    
    
    
    
    override init(gameScene: GameScene, size: CGSize) {
        super.init(gameScene: gameScene, size: size)
    }
    required init? (coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        
        guard let touch = touches.first else { return}
        let node = atPoint(touch.location(in: self))
        
        if node.name == GOOverlaySettings.ContinueNode || node.name == GOOverlaySettings.ContinueLbl{
            if !isContinue {isContinue = true }
        } else if node.name == GOOverlaySettings.PlayNode || node.name ==  GOOverlaySettings.PlayLbl{
            if !isPlay {isPlay = true}
        }
        
    }
    override func touchesEnded (_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded (touches, with: event)
        if isContinue{
            gameScene.presentScene()
            isContinue = false
        }
        if isPlay{
            
            let fade = SKAction.fadeAlpha(to: 0.0, duration: 0.5)
            bgNode.run(fade) { self.bgNode.isHidden = true }
            playNode.run(.sequence([fade, .removeFromParent ()]))
            playLbl.run(.sequence([fade, .removeFromParent ()]))
            gameScene.isGameEnded = false
            run(.wait(forDuration: 1.5)) {
                self.gameScene.tossHandler()
            }
        }
        
    }
    override func touchesMoved (_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved (touches, with: event)
        
        guard let touch = touches.first else { return }
        if isContinue {
            
            if let parent = continueNode.parent {
                let location = touch.location(in: parent)
                isContinue = continueNode.contains (location)
            }
        }
        
        if isPlay {
            if let parent = playNode.parent {
                let location = touch.location(in: parent)
                isPlay = playNode.contains(location)
            }
        }
    }
}
extension GameOverOverlay {
    func setups(_ isPlay: Bool = false, highScore: Int = 0, actualScore: Int = 0) {
        isUserInteractionEnabled = true
        guard let viewBounds = gameScene.view?.bounds else { return }
        let viewWidth = viewBounds.width
        let viewHeight = viewBounds.height
       

        if isPlay { //schermata di gioco
            let playWidth = viewWidth * 0.6
            let playHeight = viewHeight * 0.15
            let playX = viewBounds.midX - playWidth / 2
            let playY = viewBounds.midY - playHeight / 2
            let playRect = CGRect(x: playX, y: playY, width: playWidth, height: playHeight)
            
            playNode = createBGNode(playRect, corner: 10.0)
            playNode.name = GOOverlaySettings.PlayNode
            
            let playLabelPos = CGPoint(x: playNode.frame.midX, y: playNode.frame.midY)
            playLbl = createLbl(playLabelPos, hori: .center, verti: .center, txt: "Play", fontS: 40.0)
            playLbl.name = GOOverlaySettings.PlayLbl
        } else { // schermata gameover
            let continueWidth = viewWidth * 0.6
            let continueHeight = viewHeight * 0.15
            let continueX = viewBounds.midX - continueWidth / 2
            let continueY = viewBounds.midY - continueHeight / 2
            let continueRect = CGRect(x: continueX, y: continueY, width: continueWidth, height: continueHeight)
            
            let titleHeight: CGFloat = 60.0
            let titleY = continueRect.minY + titleHeight * 2.5
            
            titleLbl = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
            titleLbl.text = "GAME OVER"
            titleLbl.fontSize = 60.0
            titleLbl.numberOfLines = 0
            titleLbl.preferredMaxLayoutWidth = viewWidth * 0.8
            titleLbl.isHidden = true
            titleLbl.position = CGPoint(x: viewBounds.midX, y: titleY)
            addChild(titleLbl)
            
            continueNode = createBGNode(continueRect, corner: 10.0)
            continueNode.name = GOOverlaySettings.ContinueNode
            
            let continueLabelPos = CGPoint(x: continueNode.frame.midX, y: continueNode.frame.midY)
            continueLbl = createLbl(continueLabelPos, hori: .center, verti: .center, txt: "Continue", fontS: 40.0)
            continueLbl.name = GOOverlaySettings.ContinueLbl
            let highScoreLab = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
               highScoreLab.text = "HIGHEST SCORE: \(highScore)"
               highScoreLab.fontSize = 30.0
               highScoreLab.position = CGPoint(x: viewWidth - 200, y: continueNode.frame.minY - 90) // Imposta la posizione verticale sotto il pulsante "Continue"
               highScoreLab.zPosition = 5 // Imposta la Z-position per assicurarti che sia visualizzato sopra altri nodi
               addChild(highScoreLab)
            
            let actualScoreLab = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
                actualScoreLab.text = "YOUR SCORE: \(actualScore)"
                actualScoreLab.fontSize = 30.0
                actualScoreLab.position = CGPoint(x: 200, y: continueNode.frame.minY - 90)
                actualScoreLab.zPosition = 5
                addChild(actualScoreLab)
        }
    }
    
    
    
    private func createBGNode(_ rect: CGRect, corner: CGFloat = 0.0) -> SKShapeNode {
        let bgColor = UIColor(red: 206/255, green: 142/255, blue: 96/255, alpha: 0.5)
        let shapeNode = SKShapeNode(rect: rect, cornerRadius: corner)
        shapeNode.strokeColor = bgColor
        shapeNode.fillColor = bgColor
        shapeNode.isHidden = true
        addChild(shapeNode)
        return shapeNode
    }
    
    
    private func createLbl(_ pos: CGPoint, hori: SKLabelHorizontalAlignmentMode, verti:
                           SKLabelVerticalAlignmentMode, txt: String, fontC: UIColor = .white, fontS: CGFloat = 45.0) -> SKLabelNode {
        let lbl = SKLabelNode(fontNamed: "San Francisco")
        lbl.fontColor = fontC
        lbl.fontSize = fontS
        lbl.text = txt
        lbl.horizontalAlignmentMode = hori
        lbl.verticalAlignmentMode = verti
        lbl.position = pos
        lbl.isHidden = true
        addChild(lbl)
        return lbl
    }
    
    private func updateBtn(_ anim: Bool, event: Bool, node: SKNode) {
        var alpha: CGFloat = 1.0
        if event { alpha = 0.5 }
        
        if anim {
            node.run(.fadeAlpha(to: alpha, duration: 0.1))
        }else{
            node.alpha = alpha
        }
        
    }
    
    func showPlay() {
        playNode.isHidden = false
        playLbl.isHidden = false
        
        fadeInBG()
        fadeIn(playNode, delay: 0.5)
        fadeIn(playLbl, delay: 0.5)
    }
    func showGameOver(_ txt: String) {
        continueNode.isHidden = false
        continueLbl.isHidden = false
        
        titleLbl.isHidden = false
        titleLbl.text = txt
        
        fadeInBG()
        fadeIn(continueNode, delay: 0.5)
        fadeIn(continueLbl, delay: 0.5)
    }
    
    
    
    
}
