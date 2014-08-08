//
//  OthelloView.swift
//  SwiftOthello
//
//  Created by muratamuu on 2014/07/06.
//  Copyright (c) 2014年 muratamuu. All rights reserved.
//

import UIKit

let EMPTY = 0, BLACK_STONE = 1, WHITE_STONE = 2

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
    var board:[[Int]]
    let white = UIColor.whiteColor().CGColor
    let black = UIColor.blackColor().CGColor
    let green = UIColor(red:0.6, green:1.0, blue:0.2, alpha:1.0).CGColor
    var side:CGFloat
    var top:CGFloat
    let left:CGFloat = 0
    let lbl:UILabel = UILabel()
    var isGameOver = false
    
    init(coder aDecoder: NSCoder!) {
        let appFrame = UIScreen.mainScreen().applicationFrame
        side = appFrame.size.width / 8
        top = (appFrame.size.height - (side * 8)) / 2
        board = initboard
        
        super.init(coder:aDecoder)
        
        lbl.text = ""
        lbl.frame = CGRectMake(10, top / 2, appFrame.size.width, top / 2)
        addSubview(lbl)
    }
    
    override func drawRect(rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        CGContextSetStrokeColorWithColor(context, white)
        CGContextSetLineWidth(context, 1.5)
        
        for y in 1...8 {
            for x in 1...8 {
                let rx = left + side * CGFloat(x-1)
                let ry = top + side * CGFloat(y-1)
                let rect = CGRectMake(rx, ry, side, side)
                CGContextSetFillColorWithColor(context, green)
                CGContextFillRect(context, rect)
                CGContextStrokeRect(context, rect)
                
                if board[y][x] == BLACK_STONE {
                    CGContextSetFillColorWithColor(context, black)
                    CGContextFillEllipseInRect(context, rect) // draw black stone
                } else if board[y][x] == WHITE_STONE {
                    CGContextSetFillColorWithColor(context, white)
                    CGContextFillEllipseInRect(context, rect) // draw white stone
                }
            }
        }
    }
    
    override func touchesBegan(touches: NSSet!, withEvent event: UIEvent!) {
        if isGameOver {
            board = initboard
            updateGame()
            setNeedsDisplay()
            return
        }
        if let canBlack = canPlaced(board, BLACK_STONE) { // player can put black stone.
            if let (x, y) = getPos(touches) {
                if let blackPlaces = flip(board, x, y, BLACK_STONE) {
                    putStones(blackPlaces, stone: BLACK_STONE)
                    if let whitePlaces = cpuFlip(board, WHITE_STONE) {
                        putStones(whitePlaces, stone: WHITE_STONE)
                    }
                }
            }
        } else {
            if let whitePlaces = cpuFlip(board, WHITE_STONE) {
                putStones(whitePlaces, stone: WHITE_STONE)
            }
        }
        updateGame()
        setNeedsDisplay()
    }
    
    func getPos(touches: NSSet!) -> (x: Int, y: Int)? {
        let touch:UITouch = touches.anyObject() as UITouch
        let point = touch.locationInView(self)
        for y in 1...8 {
            for x in 1...8 {
                let rx = left + side * CGFloat(x-1)
                let ry = top + side * CGFloat(y-1)
                let rect = CGRectMake(rx, ry, side, side)
                if CGRectContainsPoint(rect, point) {
                    return (x, y)
                }
            }
        }
        return nil
    }
    
    func putStones(places:[(Int, Int)], stone: Int) {
        for (x, y) in places {
            board[y][x] = stone
        }
    }
    
    func updateGame() {
        let (free, black, white) = calcStones(board)
        let canBlack = canPlaced(board, BLACK_STONE)
        let canWhite = canPlaced(board, WHITE_STONE)
        if free == 0 || (!canBlack && !canWhite) {
            lbl.text = "Game Over (Black:\(black) White:\(white))"
            isGameOver = true
        } else {
            lbl.text = ""
            isGameOver = false
        }
    }
}

func flip(board:[[Int]], x:Int, y:Int, stone:Int) -> [(Int, Int)]? {
    if board[y][x] != EMPTY { return nil }
    var result:[(Int, Int)] = []
    result += flipLine(board, x, y, stone, 1, 0)
    result += flipLine(board, x, y, stone,-1, 0)
    result += flipLine(board, x, y, stone, 0, 1)
    result += flipLine(board, x, y, stone, 0,-1)
    result += flipLine(board, x, y, stone, 1, 1)
    result += flipLine(board, x, y, stone,-1,-1)
    result += flipLine(board, x, y, stone, 1,-1)
    result += flipLine(board, x, y, stone,-1, 1)
    if result.count > 0 {
        result += (x, y)
        return result
    } else {
        return nil
    }
}

func flipLine(board:[[Int]], x:Int, y:Int, stone:Int, dx:Int, dy:Int) -> [(Int, Int)] {
    var flipLoop: (Int, Int) -> [(Int, Int)]? = { _ in nil }
    flipLoop = { (x: Int, y: Int) -> [(Int, Int)]? in
        if board[y][x] == EMPTY {
            return nil
        } else if board[y][x] == stone {
            return []
        } else if var result = flipLoop(x+dx, y+dy) {
            result += (x, y)
            return result
        } else {
            return nil
        }
    }
    if let result = flipLoop(x+dx, y+dy) {
        return result
    }
    return []
}

func canPlaced(board:[[Int]], stone: Int) -> [(Int, Int)]? {
    var result:[(Int, Int)] = []
    for y in 1...8 {
        for x in 1...8 {
            if let res = flip(board, x, y, stone) {
                result += (x, y)
            }
        }
    }
    if result.isEmpty {
        return nil
    } else {
        return result
    }
}

func cpuFlip(board:[[Int]], stone: Int) -> [(Int, Int)]? {
    if let places = canPlaced(board, stone) {
        let (x, y) = places[ Int(arc4random()) % places.count ]
        return flip(board, x, y, stone)
    }
    return nil
}

func calcStones(board:[[Int]]) -> (free:Int, black:Int, white:Int) {
    var free = 0, white = 0, black = 0
    for y in 1...8 {
        for x in 1...8 {
            switch board[y][x] {
            case BLACK_STONE: black++
            case WHITE_STONE: white++
            default: free++
            }
        }
    }
    return (free, black, white)
}