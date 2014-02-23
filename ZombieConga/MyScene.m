//
//  MyScene.m
//  ZombieConga
//
//  Created by Duong Duc Hien on 2/23/14.
//  Copyright (c) 2014 m3hcoril. All rights reserved.
//

#import "MyScene.h"

static const float ZOMBIE_MOVE_POINTS_PER_SEC = 120.0;

@implementation MyScene {
    SKSpriteNode *_zombie;
    CGPoint _velocity;
    
    NSTimeInterval _lastUpdateTime;
    NSTimeInterval _dt;
    
}

-(id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        self.backgroundColor = [SKColor whiteColor];
        
        SKSpriteNode *bg = [SKSpriteNode spriteNodeWithImageNamed:@"background"];
        bg.position = CGPointMake(self.size.width/2, self.size.height/2);
        
        _zombie = [SKSpriteNode spriteNodeWithImageNamed:@"zombie1"];
        _zombie.position = CGPointMake(100, 100);
        //[_zombie setScale:2.0];
        
        [self addChild:bg];
        [self addChild:_zombie];
    }
    return self;
}

- (void)update:(CFTimeInterval)currentTime {
    
    if(_lastUpdateTime) {
        _dt = currentTime - _lastUpdateTime;
    } else {
        _dt = 0;
    }
    _lastUpdateTime = currentTime;
    NSLog(@"%0.2f miliseconds from last update",_dt*1000);
    
    //_zombie.position = CGPointMake(_zombie.position.x + 2, _zombie.position.y);
    [self moveSprite:_zombie velocity:_velocity];
    [self rotateSprite:_zombie toFace:_velocity];
    [self boundsCheckPlayer];
}

-(void) moveSprite:(SKSpriteNode*) sprite velocity:(CGPoint)velocity {
    
    CGPoint ammountToMove = CGPointMake(velocity.x * _dt, velocity.y * _dt);
    
    NSLog(@"Amount to move %@", NSStringFromCGPoint(ammountToMove));
    
    sprite.position = CGPointMake(sprite.position.x + ammountToMove.x, sprite.position.y + ammountToMove.y);
}

- (void)moveZombieToward:(CGPoint)location {
    CGPoint offset = CGPointMake(location.x - _zombie.position.x, location.y - _zombie.position.y);
    
    CGFloat length = sqrtf(offset.x * offset.x + offset.y * offset.y);
    
    CGPoint direction = CGPointMake(offset.x / length, offset.y / length);
    
    _velocity = CGPointMake(direction.x * ZOMBIE_MOVE_POINTS_PER_SEC,
                direction.y * ZOMBIE_MOVE_POINTS_PER_SEC);
    // lenght of _velocity = ZOMBIE_MOVE_POINTS_PER_SEC but we have direction there
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInNode:self];
    [self moveZombieToward:touchLocation];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInNode:self];
    [self moveZombieToward:touchLocation];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInNode:self];
    [self moveZombieToward:touchLocation];
}


- (void)boundsCheckPlayer {
    // 1
    CGPoint newPosition = _zombie.position;
    CGPoint newVelocity = _velocity;
    
    // 2
    CGPoint bottomLeft = CGPointZero;
    
    CGPoint topRight = CGPointMake(self.size.width,
                                   self.size.height);
    // 3
    if (newPosition.x <= bottomLeft.x) {
        newPosition.x = bottomLeft.x;
        newVelocity.x = -newVelocity.x;
    }
    if (newPosition.x >= topRight.x) {
        newPosition.x = topRight.x;
        newVelocity.x = -newVelocity.x;
    }
    
    if (newPosition.y <= bottomLeft.y) {
        newPosition.y = bottomLeft.y;
        newVelocity.y = -newVelocity.y;
    }
    
    if (newPosition.y >= topRight.y) {
        newPosition.y = topRight.y;
        newVelocity.y = -newVelocity.y;
    }
    
    // 4
    _zombie.position = newPosition;
    _velocity = newVelocity;
}

- (void)rotateSprite:(SKSpriteNode *)sprite toFace:(CGPoint)direction
{
    sprite.zRotation = atan2f(direction.y, direction.x);
}


@end
