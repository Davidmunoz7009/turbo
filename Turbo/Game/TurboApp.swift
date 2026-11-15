import SwiftUI
import SpriteKit

@main
struct TurboApp: App {
    var body: some Scene {
        WindowGroup { GameView() }
    }
}

struct GameView: View {
    @State private var scene: GameScene = {
        let s = GameScene()
        s.size = UIScreen.main.bounds.size
        s.scaleMode = .aspectFill
        return s
    }()

    var body: some View {
        SpriteView(scene: scene)
            .ignoresSafeArea()
            .statusBarHidden(true)
    }
}
