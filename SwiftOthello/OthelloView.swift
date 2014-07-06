//
//  OthelloView.swift
//  SwiftOthello
//
//  Created by muratamuu on 2014/07/06.
//  Copyright (c) 2014年 muratamuu. All rights reserved.
//

import UIKit

class OthelloView: UIView {
    let initboard = [
        [0,0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0,0],
        [0,0,0,0,2,1,0,0,0,0],
        [0,0,0,0,1,2,0,0,0,0],
        [0,0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0,0],
    ];
    let FREE = 0, BLACK_STONE = 1, WHITE_STONE = 2
    var board = Int[][]()
    var boardSide: CGFloat = 0
    let origX: CGFloat = 0
    var origY: CGFloat = 0
    var lbl: String = ""
    var isGameOver = false
    var onceToken: dispatch_once_t = 0
    let green = CGColorCreateGenericRGB(0.6, 1.0, 0.2, 1.0)
    let white = CGColorCreateGenericRGB(1.0, 1.0, 1.0, 1.0)
    let black = CGColorCreateGenericRGB(0.0, 0.0, 0.0, 1.0)
    let blue  = CGColorCreateGenericRGB(0.6, 0.5, 1.0, 1.0)
    
    func initialize () {
        board = initboard.copy()
        boardSide = self.frame.size.width / 8.0
        origY = self.frame.size.height / 2.0 - (4 * boardSide)
        lbl = ""
        isGameOver = false
    }
    
    override func drawRect(rect: CGRect) {
        dispatch_once(&onceToken, { self.initialize() })
        
        let context = UIGraphicsGetCurrentContext()
        CGContextSetStrokeColorWithColor(context, white)
        CGContextSetLineWidth(context, 1.5)
        
        for x in 1..9 {
            for y in 1..9 {
                // draw board
                let xpos = origX + CGFloat(x-1) * boardSide
                let ypos = origY + CGFloat(y-1) * boardSide
                let r = CGRectMake(xpos, ypos, boardSide, boardSide)
                CGContextSetFillColorWithColor(context, green)
                CGContextFillRect(context, r)
                CGContextStrokeRect(context, r)
                
                if board[x][y] == BLACK_STONE {
                    CGContextSetFillColorWithColor(context, black)
                    CGContextFillEllipseInRect(context, r) // draw black stone
                } else if board[x][y] == WHITE_STONE {
                    CGContextSetFillColorWithColor(context, white)
                    CGContextFillEllipseInRect(context, r) // draw white stone
                }
            }
        }
        
        // draw label
        let cstr = lbl.bridgeToObjectiveC().UTF8String
        CGContextSetTextDrawingMode(context, kCGTextFill)
        CGContextSetFillColorWithColor(context, blue)
        CGContextSelectFont(context, "Helvetica", 20 , kCGEncodingMacRoman)
        CGContextSetTextMatrix(context, CGAffineTransformMake(1.0, 0.0, 0.0, -1.0, 0.0, 0.0));
        CGContextShowTextAtPoint(context, 0, origY, cstr, strlen(cstr));
    }
    
    override func touchesBegan(touches: NSSet!, withEvent event: UIEvent!) {
        if isGameOver { // restart
            initialize()
            setNeedsDisplay()
            return
        }
        
        if canPlaced(BLACK_STONE).count > 0 { // player can put black stone.
            if let (x, y) = getPos(touches) {
                if putStone(&board, x, y, BLACK_STONE) {
                    cpuPut()
                }
            }
        } else {
            cpuPut()
        }
        
        updateGame()
        setNeedsDisplay()
    }
    
    func getPos(touches: NSSet!) -> (x: Int, y: Int)? {
        let touch: UITouch = touches.anyObject() as UITouch
        let point = touch.locationInView(self)
        for x in 1..9 {
            let xpos = origX + boardSide * CGFloat(x)
            for y in 1..9 {
                let ypos = origY + boardSide * CGFloat(y)
                if point.x <= xpos && point.y <= ypos {
                    return (x, y)
                }
            }
        }
        return nil
    }
    
    func cpuPut() {
        var places = canPlaced(WHITE_STONE) // cpu puts white stone.
        if places.count > 0 {
            let (x, y) = places[ Int(arc4random()) % places.count ]
            putStone(&board, x, y, WHITE_STONE)
        }
    }
    
    func updateGame() {
        let (free, black, white) = calcStones()
        let canBlack = canPlaced(BLACK_STONE)
        let canWhite = canPlaced(WHITE_STONE)
        if free == 0 || (canBlack.isEmpty && canWhite.isEmpty) {
            isGameOver = true
            lbl = "Game Over (black:\(black) white:\(white))"
        } else if canBlack.isEmpty {
            lbl = "Click to Skip Black"
        } else if canWhite.isEmpty {
            lbl = "Skipped White"
        } else {
            lbl = ""
        }
    }
    
    func putStone (inout board: Int[][], _ x: Int, _ y: Int, _ stone: Int) -> Bool {
        let b1 = flip(&board, x, y, stone, dx: 1, dy: 0)
        let b2 = flip(&board, x, y, stone, dx:-1, dy: 0)
        let b3 = flip(&board, x, y, stone, dx: 0, dy: 1)
        let b4 = flip(&board, x, y, stone, dx: 0, dy:-1)
        let b5 = flip(&board, x, y, stone, dx: 1, dy: 1)
        let b6 = flip(&board, x, y, stone, dx:-1, dy:-1)
        let b7 = flip(&board, x, y, stone, dx: 1, dy:-1)
        let b8 = flip(&board, x, y, stone, dx:-1, dy: 1)
        
        let canPut = b1 || b2 || b3 || b4 || b5 || b6 || b7 || b8;
        if canPut {
            board[x][y] = stone
        }
        return canPut
    }
    
    func flip (inout board: Int[][], _ x: Int, _ y: Int, _ stone: Int, dx: Int, dy: Int) -> Bool {
        
        var fliploop: (Int, Int) -> Bool = { _ in false }
        fliploop = { (x: Int, y: Int) -> Bool in
            if board[x][y] == self.FREE {
                return false
            } else if board[x][y] == stone {
                return true
            } else if fliploop (x+dx, y+dy) {
                board[x][y] = stone // flip!
                return true
            } else {
                return false
            }
        }
        func reverse(stone: Int) -> Int {
            return stone == BLACK_STONE ? WHITE_STONE : BLACK_STONE
        }
        
        if board[x][y] == FREE && board[x+dx][y+dy] == reverse(stone) {
            return fliploop(x+dx, y+dy)
        } else {
            return false
        }
    }
    
    func canPlaced(stone: Int) -> Array<(Int, Int)> {
        var result = Array<(Int, Int)>()
        for x in 1..9 {
            for y in 1..9 {
                if board[x][y] == 0 {
                    var dummy = board.copy()
                    if putStone(&dummy, x, y, stone) {
                        result += (x, y)
                    }
                }
            }
        }
        return result
    }
    
    func calcStones () -> (free: Int, black: Int, white: Int) {
        var free = 0, white = 0, black = 0
        for i in 1..9 {
            for j in 1..9 {
                switch board[i][j] {
                case BLACK_STONE: black++
                case WHITE_STONE: white++
                default: free++
                }
            }
        }
        return (free, black, white)
    }
}


