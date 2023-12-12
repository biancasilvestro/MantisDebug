import SpriteKit
import GameplayKit

// Definizione della classe GameScene che eredita da SKScene
class GameScene: SKScene {
    
    //MARK: - Properties
    var gameOverOverlay : GameOverOverlay!
    
    
    var popupTime: Double = 0.9 // Tempo di intervallo per la comparsa degli oggetti
    var isNextSequenceQueued = true // per controllare la sequenza degli oggetti
    var sequenceType: [SequenceType] = [] // Tipo di sequenza di oggetti
    var sequencePos = 0 // Posizione nella sequenza
    var delay = 3.0 // Ritardo per la generazione degli oggetti successivi
    var activeSprites: [SKNode] = [] // Array contenente gli oggetti attivi nella scena
    var activeSliceBG: SKShapeNode!
    var activeSliceFG: SKShapeNode!
    var activeSlicePoints: [CGPoint] = []
    
    var scoreLbl: SKLabelNode!
    var score: Int = 0{
        willSet{
            scoreLbl.text = "\(newValue)"
            scoreLbl.run(.sequence([
                .scale(to: 1.5, duration: 0.1),
                .scale(to:1.0, duration: 0.1)
            
            ]))
        }
    }
    
    var livesNodes :[SKSpriteNode] = []
    var lives = 3
    var isGameEnded = true
    var isReload = true
    
    //MARK: - Lifecycle (Ciclo di vita)
    override func didMove(to view: SKView) { //SKview è la view che presenta i nodi, è inizializzazione di tutti gli elementi
        setupNodes() // Metodo per configurare i nodi nella scena
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        activeSlicePoints.removeAll(keepingCapacity: true)
        
        for _ in touches{
            guard let touch = touches.first else { return }
            let location = touch.location(in: self)
            
            
            activeSlicePoints.append(location)
            redrawActiveSlice()
            
            activeSliceFG.removeAllActions()
            activeSliceBG.removeAllActions()
            activeSliceFG.alpha = 1.0
            activeSliceBG.alpha = 1.0
            
        }
        
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        activeSliceBG.run(.fadeAlpha(to: 0.0, duration: 0.25))
        activeSliceFG.run(.fadeAlpha(to: 0.0, duration: 0.25))
        
        
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        if isGameEnded {return}
        
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        activeSlicePoints.append(location)
        redrawActiveSlice()
        
        let nodesAtLocation = nodes(at: location)
        
        for node in nodesAtLocation {
            if node.name == "Fruit" {
                handleFruitTouched(node)
            } else if node.name == "Bomb" {
                handleBombTouched(node)
            }
        }
    }

    func handleFruitTouched(_ node: SKNode) {
        createEmitter("SliceHitFruit", pos: node.position, node: self)
        node.name = nil
        node.parent!.physicsBody?.isDynamic = false
        
        let scaleOut = SKAction.scale(to: 0.001, duration: 0.2)
        let fadeOut = SKAction.fadeOut(withDuration: 0.2)
        let groupAct = SKAction.group([scaleOut, fadeOut])
        let sequence = SKAction.sequence([groupAct, .removeFromParent()])
        node.run(sequence)
        
        score += 1
        removeSprite(node, nodes: &activeSprites)
    }

    func handleBombTouched(_ node: SKNode) {
        createEmitter("SliceHitBomb", pos: node.parent!.position, node: self)
        node.name = nil
        node.physicsBody?.isDynamic = false
        
        let scaleOut = SKAction.scale(to: 0.001, duration: 0.2)
        let fadeOut = SKAction.fadeOut(withDuration: 0.2)
        let groupAct = SKAction.group([scaleOut, fadeOut])
        let sequence = SKAction.sequence([groupAct, .removeFromParent()])
        node.parent!.run(sequence)
        
        removeSprite(node.parent!, nodes: &activeSprites)
        setUpGameOver(true)
    }

    
    
    //funzione per verificare se gli oggetti sono fuori visuale cosi li rimuoviamo
    override func update(_ currentTime: TimeInterval) {
        // Controlla se ci sono nodi nell'array
        if activeSprites.count > 0 {
            // per iterare su ogni nodo
            activeSprites.forEach({
                let height = $0.frame.height   //$0 = singolo nodo, frame= frame della scena. ottengo l'altezza del frame che ingloba il nodo
                let value = frame.minY - height   //value= fuoriscena frame.minY= bordo inferiore della scena
                
                // Controllo se l'oggetto è fuori dalla visuale e lo rimuovo dalla scena
                if $0.position.y < value {
                    $0.removeAllActions()
                    if $0.name == "BombContainer" {
                        $0.name = nil
                        $0.removeFromParent() //rimuove il nodo dalla scena
                        removeSprite($0, nodes: &activeSprites) //rimuove il nodo dall'array
                    } else if $0.name == "Fruit" {
                        subtracklife()
                        $0.name = nil
                        $0.removeFromParent()
                        removeSprite($0, nodes: &activeSprites)
                    }
                }
            })
        } else {
            // Se non ci sono oggetti attivi quindi array vuoto, avvia la generazione della sequenza
            if !isNextSequenceQueued {
                run(.wait(forDuration: popupTime)) {
                    self.tossHandler() //dopo il popuptime si genera la sequenza
                }
                isNextSequenceQueued = true
            }
        }
    }
}

//MARK: -Configures (Configurazioni)
extension GameScene {
    // Metodo per configurare i nodi nella scena
    func setupNodes() {
        createBG() // Creazione dello sfondo
        setupPhysics() // Configurazione della fisica della scena
        setupSequenceType() // Configurazione dei tipi di sequenza di oggetti
        createLives()
        createSlice()
        createScore()
        setupOverlays()
        
        guard !isGameEnded else {return}
        run(.wait(forDuration: 1.5)) {
            self.tossHandler()// Metodo per gestire la generazione degli oggetti
        }
    
    }
    
    // Metodo per configurare la fisica della scena
    func setupPhysics() {
        physicsWorld.gravity = CGVector(dx: 0.0, dy: -6.0)
        physicsWorld.speed = 0.85
    }
    
    
    
    func setupOverlays(){
        gameOverOverlay = GameOverOverlay(gameScene: self, size:size)
        gameOverOverlay.zPosition = 999999
        addChild(gameOverOverlay)
        
        
        guard isReload else{
            return
        }
        gameOverOverlay.setups(true)
        gameOverOverlay.showPlay()
    }
    
    
}

//MARK: -Background (Sfondo)
extension GameScene {
    // Metodo per creare lo sfondo della scena
    func createBG() {
        let bg = SKSpriteNode(imageNamed: "background")
        bg.position = CGPoint(x: frame.width/2, y: frame.height/2)
        bg.zPosition = -1.0
        addChild(bg)
    }
}


//MARK: -mantis/fruit
extension GameScene{
    func tossHandler(){
        if isGameEnded {return}
        
        // Metodo per gestire la generazione degli oggetti
        popupTime *= 0.991
        delay *= 0.99 // cosi ogni volta che avvia la funzione, diventa sempre piu veloce il gioco
        // Riduce il tempo di intervallo per la comparsa degli oggetti
       
        
        // Seleziona il tipo di sequenza di oggetti in base alla posizione nella sequenza
        let sequence = sequenceType[sequencePos]
        switch sequence{
        case .OneNoBomb:
            createSprite(.Never)// Crea un oggetto senza bomba
        case .One:
            createSprite()
        case .TwoWithOneBomb:
            createSprite(.Never)
            createSprite(.Always)// Crea un oggetto con bomba
        case .Two:
            createSprite()
            createSprite()// Crea un oggetto random
        case .Three:
            createSprite()
            createSprite()
            createSprite()
        case .Four:
            createSprite()
            createSprite()
        case .Five:
            createSprite()
            run(.wait(forDuration: delay/5)){self.createSprite()}
            run(.wait(forDuration: delay/5*2)){self.createSprite()}
            run(.wait(forDuration: delay/5*3)){self.createSprite()}
        case .Six:
            createSprite()
            run(.wait(forDuration: delay/10)){self.createSprite()}
            run(.wait(forDuration: delay/10)){self.createSprite()}
            run(.wait(forDuration: delay/10*2)){self.createSprite()}
        }
        
        
        sequencePos += 1
        isNextSequenceQueued = false
    }
    
    
    
    func createSprite(_ forceBomb: ForceBomb = .Defaults) {
        var sprite = SKSpriteNode() // A SpriteNode is a node that displays a Sprite.As it is a Node it can be transformed, be included as a child in another node and have child nodes of its own. A Sprite is a textured 2D node
        
        // Randomly determine if the object is a bomb or a fruit based on forceBomb parameter
        var bombType = Int.random(min: 1, max: 6)
        if forceBomb == .Never {
            bombType = 1 // Force to create a fruit
        } else if forceBomb == .Always {
            bombType = 0 // Force to create a bomb
        }
        
        // Check the determined bombType to decide whether to create a bomb or a fruit
        if bombType == 0 {
            // Create a bomb
            sprite = SKSpriteNode()
            sprite.zPosition = 1.0
            sprite.setScale(1.0)
            sprite.name = "BombContainer"
            
            let bomb = SKSpriteNode(imageNamed: "bomb_1")
            bomb.name = "Bomb"
            sprite.addChild(bomb)
        } else {
            // Create a fruit
            sprite = SKSpriteNode(imageNamed: "fruit_2")
            sprite.setScale(1)
            sprite.name = "Fruit"
        }
        
        // Calculate minimum and maximum X positions to place the object within the scene bounds
        let spriteW = sprite.frame.width
        let minXPosition = frame.minX + spriteW // Minimum X position, increased to move objects more to the left
        let maxXPosition = frame.maxX - spriteW * 2 // Right limit to position the objects
        
        // Generate a random X position within the calculated range
        let posX = CGFloat.random(in: minXPosition...maxXPosition)
        
        // Calculate the Y position placing the object just off the bottom of the screen
        let posY = -sprite.frame.height / 2
        let pos = CGPoint(x: posX, y: posY)
        
        // Generate random velocity and angular velocity values
        let angularVelocity = CGFloat.random(min: -6.0, max: 6.0) / 2
        let yVelocity = Int.random(min: 24, max: 32)
        let xVelocity: Int
        let value = frame.minX + 256
        
        // Adjust X velocity based on the X position to control the object's movement direction
        if pos.x < value {
            xVelocity = Int.random(min: 8, max: 40)
        } else if pos.x < value * 2 {
            xVelocity = Int.random(min: 3, max: 5)
        } else if pos.x < frame.maxX {
            xVelocity = Int.random(min: 3, max: 5)
        } else {
            xVelocity = Int.random(min: 8, max: 15)
        }
        
        // Set the position, physics body, and initial velocity of the object
        sprite.position = pos
        sprite.physicsBody = SKPhysicsBody(circleOfRadius: 60.0)
        sprite.physicsBody?.collisionBitMask = 0
        sprite.physicsBody?.angularVelocity = angularVelocity
        sprite.physicsBody?.velocity = CGVector(dx: CGFloat(xVelocity * 30), dy: CGFloat(yVelocity * 27))
        
        // Add the object to the scene and the activeSprites array
        addChild(sprite)
        activeSprites.append(sprite)
    }

    
    // Metodo per rimuovere un nodo dalla scena e dall'array activeSprites

    func removeSprite(_ node: SKNode, nodes: inout [SKNode]){
        if let index = nodes.firstIndex(of: node){ // se l'indice del primo elemento dell'array è uguale al nodo passato come parametro allora rimuovilo
            nodes.remove(at: index)
        }
    }
}



//MARK: -Sequence Type
extension GameScene{
    // Metodo per configurare i tipi di sequenza di oggetti

    func setupSequenceType(){
        sequenceType =  [.OneNoBomb, .One, .TwoWithOneBomb, .Two, .Three, .Four, .Five,  .Six]
        for _ in 0...1000{
            let sequence = SequenceType(rawValue: Int.random(min: 2, max: 7))!
            sequenceType.append(sequence)   // creiamo casi random di sequenze
        }

    }

    
}

//MARK: -Sequence Type
extension GameScene{
    func createSlice() {
        
        activeSliceBG = SKShapeNode()
        activeSliceBG.zPosition = 2.0
        activeSliceBG.lineWidth = 9.0
        activeSliceBG.strokeColor = UIColor (red: 1.0, green: 0.9, blue: 0.0, alpha: 1.0)
        
        activeSliceFG = SKShapeNode()
        activeSliceFG.zPosition = 2.0
        activeSliceFG.lineWidth = 5.0
        activeSliceFG.strokeColor = .white
        
        addChild(activeSliceBG)
        addChild(activeSliceFG)
        }
    
    
    func redrawActiveSlice() {
        if activeSlicePoints.count < 2 {
            activeSliceBG.path = nil
            activeSliceFG.path = nil
            return
        }
        while activeSlicePoints.count > 12 {
            activeSlicePoints.remove (at: 0)
        }
        let bezierPath = UIBezierPath()
        bezierPath.move(to: activeSlicePoints[0])
        
        
        for i in 0..<activeSlicePoints.count {
            bezierPath.addLine(to: activeSlicePoints[i])
        }
        activeSliceBG.path = bezierPath.cgPath
        activeSliceFG.path = bezierPath.cgPath
        
    }

    
}


//MARK: -Score
extension GameScene {
    func createScore() {
        let width: CGFloat = 150.0
        let height: CGFloat = 50.0
        
        let shapeRect = CGRect(x: frame.midX - width / 2, y: frame.maxY - height - 20.0, width: width, height: height)
        let shape = SKShapeNode(rect: shapeRect, cornerRadius: 8.0)
        shape.strokeColor = .clear
        shape.fillColor = UIColor.black.withAlphaComponent(0.5)
        shape.zPosition = 5.0
        addChild(shape)
        
        scoreLbl = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
        scoreLbl.text = "0"
        scoreLbl.zPosition = 5.0
        scoreLbl.fontSize = 40.0
        scoreLbl.verticalAlignmentMode = .center
        scoreLbl.horizontalAlignmentMode = .center
        scoreLbl.position = CGPoint(x: frame.midX, y: frame.maxY - height  + scoreLbl.fontSize * 0.2)
        addChild(scoreLbl)
    }
}




extension GameScene {
    func createLives() {
        let containerNode = SKNode()
        
        var totalWidth: CGFloat = 0.0
        
        for _ in 0..<3 {
            let sprite = SKSpriteNode(imageNamed: "sliceLife")
            sprite.setScale(0.9)
            let spriteW = sprite.frame.width * sprite.xScale // Larghezza effettiva dell'immagine
            let spriteH = sprite.frame.height * sprite.yScale // Altezza effettiva dell'immagine
            
            sprite.position = CGPoint(x: totalWidth, y: 0)
            totalWidth += spriteW
            
            containerNode.addChild(sprite)
            livesNodes.append(sprite)
        }
        
        containerNode.position = CGPoint(x: 40, y: frame.maxY - 50) // Posizione del contenitore
        addChild(containerNode)
    }
    
    

    func subtracklife() {
            lives -= 1
            
            if lives >= 0 && lives < livesNodes.count {
                let sprite = livesNodes[lives]
                sprite.texture = SKTexture(imageNamed: "sliceLifeGone")
                sprite.xScale = 1.3 * 1.0
                sprite.yScale = 1.3 * 1.0
                sprite.run(.scale(to: 1.0, duration: 0.1))
                
                if lives == 0 {
                    setUpGameOver(true) // Imposta il Game Over se il numero di vite è zero
                } else {
                    checkLivesState() // Altrimenti, controlla lo stato delle vite
                }
            }
        }
}

// MARK game over
extension GameScene{
    func setUpGameOver(_ isGameOver: Bool){
        gameOverOverlay.setups(score:score)
        gameOverOverlay.showGameOver("GAME OVER")
        
        if isGameEnded {return}
        isGameEnded = true
        physicsWorld.speed = 0.0
        isUserInteractionEnabled = false
        
        if isGameOver{
            let texture = SKTexture(imageNamed: "sliceLifeGone")
            livesNodes[0].texture = texture
            livesNodes[1].texture = texture
            livesNodes[2].texture = texture
        }
        
    }

    
    
    func presentScene(){
        
        let scene = GameScene(size: size)
        scene.scaleMode = scaleMode
        scene.isReload = false
        scene.isGameEnded = false
        view!.presentScene(scene, transition: .fade(withDuration: 1.0))
        
        
        
        
        
    }
    
    
    
func checkLivesState() {
        var allLivesGone = true
        
        for node in livesNodes {
            if node.texture != SKTexture(imageNamed: "sliceLifeGone") {
                allLivesGone = false
                break
            }
        }
        
        if allLivesGone {
            setUpGameOver(true) // Se tutte le vite sono gone, imposta il Game Over a true
        }
    }
}




// MARK emitter
extension GameScene{
    func createEmitter (_ fn: String, pos: CGPoint, node : SKNode){
        let emitter = SKEmitterNode(fileNamed: fn)!
        emitter.position = pos
        node.addChild(emitter)
        
    }
    
    
}
