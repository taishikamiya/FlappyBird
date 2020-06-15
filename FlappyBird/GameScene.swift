//
//  GameScene.swift
//  FlappyBird
//
//  Created by Taishi Kamiya on 2020/06/14.
//  Copyright © 2020 taishi.kamiya. All rights reserved.
//

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var scrollNode:SKNode!
    var wallNode:SKNode!
    var bird:SKSpriteNode!
    var item:SKSpriteNode!
    
    //衝突判定カテゴリー
    let birdCategory: UInt32 = 1 << 0     // 0..0001
    let groundCategory: UInt32 = 1 << 1     // 0..0010
    let wallCategory: UInt32 = 1 << 2     // 0..0100
    let scoreCategory: UInt32 = 1 << 3     // 0..1000
    let itemCategory: UInt32 = 1 << 4   // 0..10000
    

    //スコア用
    var score = 0
    var scoreLabelNode:SKLabelNode!
    var bestScoreLabelNode:SKLabelNode!
    let userDefaults:UserDefaults = UserDefaults.standard
    
    // SKView上にシーンが表示されたときに呼ばれるメソッド
    override func didMove(to view: SKView) {
        
        //重力を設定
        physicsWorld.gravity = CGVector(dx: 0, dy: -4)
        physicsWorld.contactDelegate = self
        
        //背景色を設定
        backgroundColor = UIColor(red: 0.15, green: 0.75, blue: 0.90, alpha: 1)
        
        //スクロールするSpriteの親ノード
        scrollNode =  SKNode()
        addChild(scrollNode)

        //壁用ノード
        wallNode = SKNode()
        scrollNode.addChild(wallNode)
        
        // 各種Spriteを生成する処理をメソッドに分割
        setupGround()
        setupCloud()
        setupWall()
        setupBird()
        setupItem()
        
        setupScoreLabel()
    }
    
    func setupGround(){
        
        //地面の画像を読み込む
        let groundTexture = SKTexture(imageNamed: "ground")
        groundTexture.filteringMode = .nearest
        
        //必要な枚数を計算
        let needNumber =  Int(self.frame.size.width / groundTexture.size().width) + 2
        
        //スクロールするアクションを作成
        //左方向に画像一枚分スクロールさせるアクション
        let moveGround = SKAction.moveBy(x: -groundTexture.size().width, y: 0, duration: 5)
        
        //元の位置に戻すアクション
        let resetGround = SKAction.moveBy(x: groundTexture.size().width, y: 0, duration: 0)
        
        //左にスクロール→もとの位置→左にスクロールと無限に繰り返すアクション
        let repeatScrollGround  = SKAction.repeatForever(SKAction.sequence([moveGround, resetGround]))
        
        //groundのSpriteを配置
        for i in 0..<needNumber {
            let sprite  = SKSpriteNode(texture: groundTexture)
            
        //Spriteの表示する位置を指定
            sprite.position = CGPoint(x: groundTexture.size().width / 2 + groundTexture.size().width * CGFloat(i), y: groundTexture.size().height / 2)

            sprite.run(repeatScrollGround)
            
            //Spriteに物理演算を設定する
            sprite.physicsBody = SKPhysicsBody(rectangleOf: groundTexture.size())
            
            //衝突のカテゴリー設定
            sprite.physicsBody?.categoryBitMask = groundCategory
            
            //衝突のときに動かないように設定する
            sprite.physicsBody?.isDynamic = false
            
            //シーンにSpriteを追加
            scrollNode.addChild(sprite)
//            addChild(sprite)
        }
    }
    
    
    func setupCloud(){
        
        //雲の画像を読み込む
        let cloudTexture = SKTexture(imageNamed: "cloud")
        cloudTexture.filteringMode = .nearest
        
        //必要な枚数を計算
        let needCloudNumber = Int(self.frame.size.width / cloudTexture.size().width) + 2
        
        //スクロールするアクションを作成
        //左方向に画像一枚分スクロールするアクション
        let moveCloud = SKAction.moveBy(x: -cloudTexture.size().width, y: 0, duration: 20)
        
        //元の位置にお戻すアクション
        let resetCloud = SKAction.moveBy(x: cloudTexture.size().width, y: 0, duration: 0)
        
        //左にスクロールー＞元の位置→左にスクロールを繰り返す
        let repeatScrollCloud = SKAction.repeatForever(SKAction.sequence([moveCloud,resetCloud]))
        
        //spriteを配置
        for i in 0..<needCloudNumber {
            let sprite = SKSpriteNode(texture: cloudTexture)
            sprite.zPosition = -100 //一番うしろになるようにする
            
            //Spriteの表示する位置を指定
            sprite.position = CGPoint(x: cloudTexture.size().width / 2 + cloudTexture.size().width * CGFloat(i), y: self.size.height - cloudTexture.size().height / 2)
        
        //spriteにアニメーション設定
        sprite.run(repeatScrollCloud)
        
        //Sprite追加
        scrollNode.addChild(sprite)
        
        }
        
    }
    
    func setupWall(){
        //壁の画像読み込む
        let wallTexture = SKTexture(imageNamed: "wall")
        wallTexture.filteringMode = .linear
        
        //移動するキョリを計算
        let movingDistance = CGFloat(self.frame.size.width + wallTexture.size().width)
        
        //画面外まで移動するアクション作成
        let moveWall = SKAction.moveBy(x: -movingDistance, y: 0, duration: 4)
        
        //自身をとりのぞくアクションを作成
        let removeWall = SKAction.removeFromParent()
        
        //２つのアニメーションを順に実行するアクション
        let wallAnimation = SKAction.sequence([moveWall,removeWall])
        
        //鳥の画像サイズをStockk
        let birdSize = SKTexture(imageNamed: "bird_a").size()
        
        //鳥が通り抜ける隙間のサイズを取りのサイズの３倍とする
        let slit_length = birdSize.height * 3
        
        //隙間位置の上下の揺れ幅を鳥サイズの３倍とする
        let random_y_range = birdSize.height * 3
        
        //下の壁のy軸下限位置
        let groundSize = SKTexture(imageNamed: "ground").size()
        let center_y = groundSize.height + (self.frame.size.height - groundSize.height) / 2
        let under_wall_lowest_y = center_y - slit_length / 2 - wallTexture.size().height / 2 - random_y_range / 2
        
        //壁を生成するアクション
        let createWallAnimation = SKAction.run({
            //壁関連のノードを乗せるノードを作成
            let wall = SKNode()
            wall.position = CGPoint(x:self.frame.size.width + wallTexture.size().width/2, y:0)
            wall.zPosition = -50 // 雲より手前、地面より奥
            
            //０〜random_y_rangeまでのランダム値を生成
            let random_y = CGFloat.random(in: 0..<random_y_range)
            //y軸の下限にランダムな値を足して下の壁のy座標を決定
            let under_wall_y = under_wall_lowest_y + random_y
            
            //下側の壁作成
            let under = SKSpriteNode(texture: wallTexture)
            under.position = CGPoint(x:0, y:under_wall_y)
            
            //Spriteに物理演算する
            under.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            under.physicsBody?.categoryBitMask = self.wallCategory
            
            //衝突のときに動かないようにする
            under.physicsBody?.isDynamic = false
            
            wall.addChild(under)
            
            //上側の壁作成
            let upper = SKSpriteNode(texture: wallTexture)
            upper.position = CGPoint(x:0, y:under_wall_y + wallTexture.size().height + slit_length)
            
            //Spriteに物理演算を設定する
            upper.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            upper.physicsBody?.categoryBitMask = self.wallCategory
            
            //衝突のときに動かないようにする
            upper.physicsBody?.isDynamic = false
            
            wall.addChild(upper)
            
            //スコアアップ用のノード
            let scoreNode = SKNode()
            scoreNode.position = CGPoint(x: upper.size.width + birdSize.width / 2, y: self.frame.height / 2)
            scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: upper.size.width, height: self.frame.size.height))
            scoreNode.physicsBody?.isDynamic = false
            scoreNode.physicsBody?.categoryBitMask = self.scoreCategory
            scoreNode.physicsBody?.contactTestBitMask = self.birdCategory
            
            wall.addChild(scoreNode)
            
            
            wall.run(wallAnimation)
            
            self.wallNode.addChild(wall)
        })
 
        //次の壁作成までの時間待ちのアクション
        let  waitAnimation  = SKAction.wait(forDuration: 2)
        
        //カベを作成→時間まち→カベ作成を繰り返す
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createWallAnimation, waitAnimation]))
        
        wallNode.run(repeatForeverAnimation)
        
    }
    
    func setupBird() {
        // 鳥の画像を２種類読み込む
        let birdTextureA = SKTexture(imageNamed: "bird_a")
        birdTextureA.filteringMode = .linear
        let birdTextureB = SKTexture(imageNamed: "bird_b")
        birdTextureB.filteringMode = .linear
        
        //2種類のテクスチャを交互に変更するアニメーション作成
        let textureAnimation = SKAction.animate(with: [birdTextureA, birdTextureB], timePerFrame: 0.2)
        let flap =  SKAction.repeatForever(textureAnimation)
        
        //Sprite作成
        bird = SKSpriteNode(texture: birdTextureA)
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y: self.frame.size.height * 0.7)
        
        //物理演算を設定
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2)
        
        //衝突したときに回転させない
        bird.physicsBody?.allowsRotation = false
        
        //衝突のカテゴリ設定
        bird.physicsBody?.categoryBitMask = birdCategory
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.physicsBody?.contactTestBitMask =  groundCategory | wallCategory
        
        //アニメーション設定
        bird.run(flap)
        
        //Spriteを追加
        addChild(bird)
    }
    
    func setupItem() {
        //read Item Img
        let itemTexture = SKTexture(imageNamed: "seed")
        itemTexture.filteringMode = .linear
        
        //移動するキョリを計算
        let movingDistance = CGFloat(self.frame.size.width + itemTexture.size().width)
          //カベと同じそくどで動かす
        let moveItem = SKAction.moveBy(x: -movingDistance, y: 0, duration: 4)
                   
        //自身をとりのぞくアクションを作成　//画面外に移動したら
        let removeItem = SKAction.removeFromParent()
    
        //２つのアニメーションを順に実行するアクション
        let itemAnimation = SKAction.sequence([moveItem,removeItem])

        item = SKSpriteNode(texture: itemTexture)
        item.position = CGPoint(x: self.frame.size.width * 0.5, y: self.frame.size.height * 0.5)

        item.run(itemAnimation)
        addChild(item)

/*        //itemを生成するアクション
        let createItemAnimation = SKAction.run({

            //item作成
            self.item = SKSpriteNode(texture: itemTexture)
            self.item.position = CGPoint(x: self.frame.size.width * 0.5, y: self.frame.size.height * 0.5)

        })
 */


    }
    
    
    //画面をタップしたときに呼ばれる
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if scrollNode.speed > 0 {
        //鳥の速度をゼロにする
        bird.physicsBody?.velocity = CGVector.zero
        //鳥に縦方向のちからを与える
        bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 15))
        } else if bird.speed == 0 {
            restart()
        }
    }

    // SKPhysicsContactDelegateのMethod　衝突した時に呼ばれる
    func didBegin(_ contact: SKPhysicsContact) {
        //game overのときはなにもしない
        if scrollNode.speed <= 0 {
            return
        }
        
        if (contact.bodyA.categoryBitMask & scoreCategory) == scoreCategory || (contact.bodyB.categoryBitMask & scoreCategory) == scoreCategory {
            //score用の物体と衝突
            print("ScoreUp")
            score += 1
            scoreLabelNode.text = "Score:\(score)"
            
            //ベストスコア更新か確認する
            var bestScore = userDefaults.integer(forKey: "BEST")
            if score > bestScore {
                bestScore = score
                bestScoreLabelNode.text = "Best Score:\(bestScore)"
                userDefaults.set(bestScore, forKey: "BEST")
                userDefaults.synchronize()
            }
        } else {
            //カベか地面と衝突
            print("GameOver")
            
            //stop scroll
            scrollNode.speed = 0
            
            bird.physicsBody?.collisionBitMask = groundCategory
            
            let roll = SKAction.rotate(byAngle: CGFloat(Double.pi)*CGFloat(bird.position.y)*0.01, duration: 1)
            bird.run(roll, completion:{
                self.bird.speed = 0
            })
        }
    }
    
    func restart(){
        score = 0
        scoreLabelNode.text = "Score:\(score)"
        
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y:self.frame.size.height * 0.7)
        bird.physicsBody?.velocity = CGVector.zero
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.zRotation = 0
        
        wallNode.removeAllChildren()
        
        bird.speed = 1
        scrollNode.speed = 1
    }

    
    func setupScoreLabel(){
        score = 0
        scoreLabelNode = SKLabelNode()
        scoreLabelNode.fontColor = UIColor.black
        scoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 60)
        scoreLabelNode.zPosition = 100 // 手前
        scoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        scoreLabelNode.text = "Score:\(score)"
        self.addChild(scoreLabelNode)
        
        bestScoreLabelNode = SKLabelNode()
        bestScoreLabelNode.fontColor = UIColor.black
        bestScoreLabelNode.position = CGPoint(x: 10, y: self.frame.height - 90)
        bestScoreLabelNode.zPosition = 100
        bestScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        
        let bestScore = userDefaults.integer(forKey: "BEST")
        bestScoreLabelNode.text = "Best Score:\(bestScore)"
        self.addChild(bestScoreLabelNode)
        
        
    }
}



