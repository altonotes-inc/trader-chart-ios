//
//  Scroller.swift
//  TraderChart
//
//  Created by Keita Yamamoto on 2019/04/19.
//  Copyright © 2019 altonotes Inc. All rights reserved.
//

import Foundation

/// 1方向慣性スクロールの制御。両端はiOSのスクロールのようにバウンスする。
/// 慣性移動は端にぶつかって少し戻るまではサインカーブ、そこから戻り切るまではω(180° → 270°)のサインカーブでイースアウト
///
/// OS標準のScrollViewを使わない理由は、OS標準のScrollViewに以下のようなデメリットがあるため。
///    - ScrollViewが入れ子になった場合の制御が複雑になる
///    - Androidはマイナスのスクロールオフセットを指定できない
///    - iOSはマイナスのスクロールオフセットを指定した際に、scrollViewDidScrollが不正に呼ばれるバグらしき挙動がある
///    - Androidはスクロールコンテンツのサイズを数値で指定できずサイズ制御が煩雑
///
open class Scroller: @unchecked Sendable {
    private let halfPI: Double = Double.pi / 2
    private let pi: Double = Double.pi

    /// 最小スクロール位置
    public var minPosition: Double = 0
    /// 最大スクロール位置
    public var maxPosition: Double = 1000 // 1000は適当。特に意味はない

    /// 最大慣性スクロール速度
    public var maxVelocity: Double = 3000

    /// FPS（1秒間の処理回数）
    public var fps: Double {
        didSet { loopIntervalMicroSec = fpsToInterval(fps: fps) }
    }
    /// ループ間隔
    public var loopIntervalMicroSec: UInt32 = 0
    /// 摩擦力（point/sec^2）
    public var frictionalForce: Double = 1000
    /// 反発バネ定数
    public var bounceFactor: Double = 30
    /// 速度計測の最小時間（秒）
    public var minMeasurementTime: Double = 0.030
    /// スクロールコールバック
    public var onScrollChanged: ((Double) -> Void)?
    /// スクロール中か
    public var isScrolling: Bool { return isThreadRunning }
    /// 現在ポジション
    public var scrollPosition: Double = 0

    private var moveMode: MoveMode?

    private var timePoints = [TimePosition]()
    private var isThreadRunning = false
    private var firstVelocity: Double?
    private var isWaitingUIThread = false

    private var preTouchPosition: Double?

    /// 慣性スライドやバウンスの起点となるポイント
    private var basePoint: BasePoint?

    /// ドラッグに対してスクロールする向き
    public let direction: Direction

    /// 端にめり込んでいるときのドラッグに対する移動割合
    var moveRateOnSink: Double = 0.33

    /// 慣性移動による端へのめり込み速度
    var sinkVelocity: Double = 20

    /// 跳ね返り速度
    var reboundVelocity: Double = 5

    init(fps: Double = 60, direction: Direction = .positive) {
        self.fps = fps
        self.direction = direction
        self.loopIntervalMicroSec = fpsToInterval(fps: fps)
    }

    /// スクロール位置などを初期状態に戻す
    public func clear(position: Double = 0) {
        scrollPosition = position
        moveMode = nil
        timePoints.removeAll()
        isThreadRunning = false
        firstVelocity = nil
        isWaitingUIThread = false
        preTouchPosition = nil
        basePoint = nil
    }

    /// 引数に指定したScrollerの状態を引き継ぐ
    public func importState(from: Scroller) {
        minPosition = from.minPosition
        maxPosition = from.maxPosition
        clear(position: from.scrollPosition)
    }

    /// タッチが移動したとき呼び出す
    /// iOSの時間分解能の実測は以下のとおりで、たまにとても短いスパンがある
    /// iPhoneX: 0.2ms〜25ms、iPhone5: 6ms〜18ms
    public func touch(position: CGFloat) { touch(position: Double(position)) }
    public func touch(position: Double) {
        print("touch")
        moveMode = nil
        isThreadRunning = false

        recordTimePoint(position: position)

        if let prePosition = preTouchPosition {
            var move = moveVector(position, prePosition)
            
            if scrollPosition < minPosition || maxPosition < scrollPosition {
                // NOTE: 反発する向きの移動は軽くする方が自然に思えるが、iOSのUIScrollViewもそうなっていないのでいったん現状で良しとする
                move *= moveRateOnSink
            }
            
            scrollPosition -= move
            indicateScrollPosition()
        }

        preTouchPosition = position
    }
    
    /// タッチが離れたとき呼び出す
    public func touchEnd(position: CGFloat) { touchEnd(position: Double(position)) }
    public func touchEnd(position: Double) {
        recordTimePoint(position: position)

        guard let first = timePoints.first, let last = timePoints.last else {
            return
        }
        
        let time = last.sec - first.sec
        if time == 0 {
            return
        }

        var move = -moveVector(last.position, first.position)
        if scrollPosition < minPosition || maxPosition < scrollPosition {
            move *= moveRateOnSink
        }

        var velocity = move / time
        velocity = min(velocity, maxVelocity)
        velocity = max(velocity, -maxVelocity)

        // 速度計算
        basePoint = BasePoint(time: currentSec(),
                              position: scrollPosition,
                              velocity: velocity)

        if scrollPosition < minPosition {
            moveMode = MoveMode.sinkLower
        } else if maxPosition < scrollPosition {
            moveMode = MoveMode.sinkUpper
        } else {
            moveMode = MoveMode.slide
        }

        startThread()
        timePoints.removeAll()
        preTouchPosition = nil
    }
    
    /// 現在の時刻と位置を記録する
    private func recordTimePoint(position: Double) {
        let currentSecond = currentSec()
        let point = TimePosition(microSec: currentSecond, position: position)
        
        // 速度計算可能な直近のポイントを探す
        let reversedIndices = (0..<timePoints.count).reversed()
        var firstMeasurableIndex: Int?
        for i in reversedIndices {
            if minMeasurementTime < currentSecond - timePoints[i].sec {
                firstMeasurableIndex = i
                break
            }
        }
        
        // 速度計算可能な直近ポイントより古いポイントは削除
        if let firstIndex = firstMeasurableIndex, 0 < firstIndex {
            timePoints.removeFirst(firstIndex)
        }

        timePoints.append(point)
    }
    
    private func startThread() {
        isThreadRunning = true
        DispatchQueue.global(qos: .userInteractive).async {
            self.scrollingLoop()
        }
    }
    
    private func scrollingLoop() {
        while isThreadRunning {

            if !updatePosition() { break }

            if !isWaitingUIThread { // UIスレッドの処理が終わっていない場合はスキップして処理を間引く
                isWaitingUIThread = true
                DispatchQueue.main.async {
                    self.indicateScrollPosition()
                    self.isWaitingUIThread = false
                }
            }

            usleep(loopIntervalMicroSec)
        }
        isThreadRunning = false
    }

    private func updatePosition() -> Bool {
        guard let basePoint = basePoint, let moveMode = moveMode else {
            return false
        }

        let currentTime = currentSec()
        let time = currentTime - basePoint.time

        switch moveMode {
        case .slide:
            let absV = abs(basePoint.velocity) - frictionalForce * time
            if absV < 0 {
                // 慣性終了
                self.moveMode = nil
                return false
            }
            scrollPosition = calcSlidePosition(basePoint: basePoint, time: time)
            
            if scrollPosition < minPosition {
                self.moveMode = MoveMode.sinkLower
            } else if maxPosition < scrollPosition {
                self.moveMode = MoveMode.sinkUpper
            }

            if self.moveMode == MoveMode.sinkLower || self.moveMode == MoveMode.sinkUpper {
                let v = (0 < basePoint.velocity) ? absV : -absV
                self.basePoint = BasePoint(time: currentTime, position: scrollPosition, velocity: v)
            }
        case .sinkLower, .sinkUpper:
            let amplitude = basePoint.velocity / bounceFactor
            let radian = time * sinkVelocity
            scrollPosition = basePoint.position + amplitude * sin(radian)

            if pi * 0.75 <= radian {
                if moveMode == MoveMode.sinkLower {
                    self.moveMode = MoveMode.reboundLower
                } else if moveMode == MoveMode.sinkUpper {
                    self.moveMode = MoveMode.reboundUpper
                }
                self.basePoint = BasePoint(time: currentTime, position: scrollPosition, velocity: 0)
            }
            
            if pi <= radian {
                // 初期位置に戻す
                if moveMode == MoveMode.sinkLower {
                    scrollPosition = minPosition
                } else if moveMode == MoveMode.sinkUpper {
                    scrollPosition = maxPosition
                }
                self.moveMode = nil
                self.basePoint = nil
            }
        case .reboundLower, .reboundUpper:
            let width = (moveMode == .reboundLower) ? minPosition - basePoint.position : maxPosition - basePoint.position
            let amplitude = width
            let radian: Double = time * reboundVelocity
            let move = -amplitude * sin(pi + radian)
            scrollPosition = basePoint.position + move
            
            if halfPI <= radian {
                if moveMode == MoveMode.reboundLower {
                    scrollPosition = minPosition
                } else if moveMode == MoveMode.reboundUpper {
                    scrollPosition = maxPosition
                }
                self.moveMode = nil
                self.basePoint = nil
            }
        }

        return true
    }

    private func moveVector(_ newPosition: Double, _ oldPosition: Double) -> Double {
        if direction == .positive {
            return oldPosition - newPosition
        } else {
            return newPosition - oldPosition
        }
    }

    private func indicateScrollPosition() {
        onScrollChanged?(scrollPosition)
    }
    
    private func endScrolling() {
        isThreadRunning = false
        timePoints.removeAll()
    }
    
    /// 現在の期待位置を計算する
    /// v = v0 + a t
    /// x = v0 t + 1/2 a t^2
    private func calcSlidePosition(basePoint: BasePoint, time: Double) -> Double {
        let v0 = basePoint.velocity
        let a = (0 < v0) ? -frictionalForce : frictionalForce
        let move = (v0 * time) + (0.5 * a * time * time)

        return basePoint.position + move
    }
    
    /// FPSからフレーム時間を算出する
    func fpsToInterval(fps: Double) -> UInt32 {
        return UInt32(1000000 / fps)
    }
    
    /// 現在の秒
    func currentSec() -> Double {
        var tv = timeval()
        gettimeofday(&tv, nil)
        return Double(tv.tv_sec) + Double(tv.tv_usec) / 1000000.0
    }
    
    /// アニメーションの基準の点
    struct BasePoint {
        let time: Double
        let position: Double
        let velocity: Double // point/μsec
    }
    
    private class TimePosition {
        let sec: Double
        let position: Double
        init(microSec: Double, position: Double) {
            self.sec = microSec
            self.position = position
        }
    }

    /// タッチを離した後の自動移動モード
    enum MoveMode {
        /// 慣性スクロール
        case slide
        /// 下限に到達して沈み込む
        case sinkLower
        /// 上限に到達して沈み込む
        case sinkUpper
        /// 下限に到達して沈み込んだ後の跳ね返り
        case reboundLower
        /// 上限に到達して沈み込んだ後の跳ね返り
        case reboundUpper
    }

    /// ドラッグに対してどちら向きにスクロールするか
    public enum Direction {
        /// プラス方向への移動でスクロール位置がプラスに動く
        case positive
        /// マイナス方向への移動でスクロール位置がプラスに動く
        case negative
    }
}
