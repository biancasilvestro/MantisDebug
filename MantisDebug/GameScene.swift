import SpriteKit
import GameplayKit

// Definizione della classe GameScene che eredita da SKScene
class GameScene: SKScene {
    
    //MARK: - Properties
    var popupTime: Double = 0.9 // Tempo di intervallo per la comparsa degli oggetti
    var isNextSequenceQueued = true // per controllare la sequenza degli oggetti
    var sequenceType: [SequenceType] = [] // Tipo di sequenza di oggetti
    var sequencePos = 0 // Posizione nella sequenza
    var delay = 3.0 // Ritardo per la generazione degli oggetti successivi
    var activeSprites: [SKNode] = [] // Array contenente gli oggetti attivi nella scena
    
    
    //MARK: - Lifecycle (Ciclo di vita)
    override func didMove(to view: SKView) { //SKview è la view che presenta i nodi, è inizializzazione di tutti gli elementi
        setupNodes() // Metodo per configurare i nodi nella scena
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
        
        
        tossHandler() // Metodo per gestire la generazione degli oggetti
    }
    
    // Metodo per configurare la fisica della scena
    func setupPhysics() {
        physicsWorld.gravity = CGVector(dx: 0.0, dy: -6.0)
        physicsWorld.speed = 0.85
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

