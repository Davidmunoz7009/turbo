import SpriteKit
import UIKit

final class GameScene: SKScene {
    private var player = SKShapeNode()
    private var dashes: [SKShapeNode] = []
    private var enemies: [SKShapeNode] = []
    private let scoreLabel = SKLabelNode(fontNamed: "Menlo-Bold")
    private let infoLabel = SKLabelNode(fontNamed: "Menlo-Bold")
    private let subLabel = SKLabelNode(fontNamed: "Menlo")

    private var gameSpeed: CGFloat = 450
    private var score: CGFloat = 0
    private var lastTime: TimeInterval = 0
    private var spawnTimer: CGFloat = 0.5
    private var alive = true
    private var targetX: CGFloat = 0

    private var roadWidth: CGFloat { size.width * 0.8 }
    private var laneWidth: CGFloat { roadWidth / 3 }
    private let dashCount = 8
    private var dashGap: CGFloat { size.height / CGFloat(dashCount) }

    private var highScore: Int {
        get { UserDefaults.standard.integer(forKey: "turbo.high") }
        set { UserDefaults.standard.set(newValue, forKey: "turbo.high") }
    }

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.10, green: 0.50, blue: 0.15, alpha: 1)
        buildRoad()

        player = makeCar(SKColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 1))
        player.position = CGPoint(x: size.width / 2, y: size.height * 0.2)
        player.zPosition = 5
        addChild(player)
        targetX = player.position.x

        scoreLabel.fontSize = 28
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: size.width / 2, y: size.height - 90)
        scoreLabel.zPosition = 10
        addChild(scoreLabel)

        infoLabel.fontSize = 34
        infoLabel.fontColor = .yellow
        infoLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.58)
        infoLabel.zPosition = 10
        addChild(infoLabel)

        subLabel.fontSize = 18
        subLabel.fontColor = .white
        subLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.58 - 36)
        subLabel.zPosition = 10
        addChild(subLabel)

        infoLabel.text = "TURBO"
        subLabel.text = "Desliza para mover el coche"
        scoreLabel.text = "0"
        run(.sequence([.wait(forDuration: 1.8), .run { [weak self] in
            self?.infoLabel.text = ""
            self?.subLabel.text = ""
        }]))
    }

    private func buildRoad() {
        let road = SKShapeNode(rectOf: CGSize(width: roadWidth, height: size.height))
        road.fillColor = SKColor(white: 0.20, alpha: 1)
        road.strokeColor = .clear
        road.position = CGPoint(x: size.width / 2, y: size.height / 2)
        road.zPosition = 0
        addChild(road)

        for sign in [-1.0, 1.0] {
            let edge = SKShapeNode(rectOf: CGSize(width: 6, height: size.height))
            edge.fillColor = .white
            edge.strokeColor = .clear
            edge.position = CGPoint(x: size.width / 2 + CGFloat(sign) * (roadWidth / 2 - 4), y: size.height / 2)
            edge.zPosition = 1
            addChild(edge)
        }

        for sign in [-1.0, 1.0] {
            for i in 0...dashCount {
                let d = SKShapeNode(rectOf: CGSize(width: 6, height: dashGap * 0.5))
                d.fillColor = .white
                d.strokeColor = .clear
                d.position = CGPoint(x: size.width / 2 + CGFloat(sign) * laneWidth / 2,
                                     y: CGFloat(i) * dashGap)
                d.zPosition = 1
                addChild(d)
                dashes.append(d)
            }
        }
    }

    private func makeCar(_ color: SKColor) -> SKShapeNode {
        let w = laneWidth * 0.55
        let h = w * 1.9
        let body = SKShapeNode(rectOf: CGSize(width: w, height: h), cornerRadius: w * 0.25)
        body.fillColor = color
        body.strokeColor = .black
        body.lineWidth = 2

        let glass = SKShapeNode(rectOf: CGSize(width: w * 0.7, height: h * 0.25), cornerRadius: 4)
        glass.fillColor = SKColor(white: 0.85, alpha: 1)
        glass.strokeColor = .clear
        glass.position = CGPoint(x: 0, y: h * 0.12)
        body.addChild(glass)

        let stripe = SKShapeNode(rectOf: CGSize(width: w * 0.18, height: h * 0.9))
        stripe.fillColor = SKColor(white: 1, alpha: 0.25)
        stripe.strokeColor = .clear
        stripe.zPosition = -0.1
        body.addChild(stripe)
        return body
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !alive { restart(); return }
        if let t = touches.first { setTarget(t.location(in: self).x) }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if alive, let t = touches.first { setTarget(t.location(in: self).x) }
    }

    private func setTarget(_ x: CGFloat) {
        let margin = roadWidth / 2 - player.frame.width / 2 - 10
        let minX = size.width / 2 - margin
        let maxX = size.width / 2 + margin
        targetX = min(max(x, minX), maxX)
    }

    override func update(_ currentTime: TimeInterval) {
        let dt: CGFloat = lastTime == 0 ? 0 : CGFloat(min(currentTime - lastTime, 0.05))
        lastTime = currentTime
        guard alive else { return }

        gameSpeed = min(450 + score * 0.9, 1150)
        score += dt * gameSpeed * 0.04
        scoreLabel.text = "\(Int(score))   MEJOR \(max(highScore, Int(score)))"

        let totalHeight = dashGap * CGFloat(dashCount + 1)
        for d in dashes {
            d.position.y -= gameSpeed * dt
            if d.position.y < -dashGap { d.position.y += totalHeight }
        }

        player.position.x += (targetX - player.position.x) * min(1, 12 * dt)
        let tilt = (targetX - player.position.x) / 120
        player.zRotation = -max(-0.25, min(0.25, tilt))

        spawnTimer -= dt
        if spawnTimer <= 0 {
            spawnEnemy()
            spawnTimer = CGFloat.random(in: 280...440) / gameSpeed
        }

        for e in enemies {
            e.position.y -= gameSpeed * 0.9 * dt
        }
        enemies.removeAll { e in
            if e.position.y < -150 { e.removeFromParent(); return true }
            return false
        }

        let hit = player.frame.insetBy(dx: 7, dy: 10)
        for e in enemies where hit.intersects(e.frame.insetBy(dx: 7, dy: 10)) {
            crash()
            break
        }
    }

    private func spawnEnemy() {
        let colors: [SKColor] = [.blue, .orange, .purple, .cyan, .yellow, .magenta]
        let e = makeCar(colors.randomElement() ?? .blue)
        let lane = Int.random(in: 0..<3)
        let laneX = size.width / 2 + CGFloat(lane - 1) * laneWidth
        e.position = CGPoint(x: laneX, y: size.height + 120)
        e.zPosition = 4
        addChild(e)
        enemies.append(e)
    }

    private func crash() {
        alive = false
        let final = Int(score)
        if final > highScore { highScore = final }
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        infoLabel.text = "¡CHOQUE!"
        subLabel.text = "Puntos: \(final)  ·  Toca para reiniciar"
        player.run(.sequence([
            .repeat(.sequence([.fadeAlpha(to: 0.2, duration: 0.08), .fadeAlpha(to: 1, duration: 0.08)]), count: 4)
        ]))
    }

    private func restart() {
        enemies.forEach { $0.removeFromParent() }
        enemies.removeAll()
        score = 0
        gameSpeed = 450
        spawnTimer = 0.5
        alive = true
        infoLabel.text = ""
        subLabel.text = ""
        player.removeAllActions()
        player.alpha = 1
        player.position = CGPoint(x: size.width / 2, y: size.height * 0.2)
        player.zRotation = 0
        targetX = player.position.x
    }
}
