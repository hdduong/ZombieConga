//
//  MyScene.m
//  ZombieConga
//
//  Created by Duong Duc Hien on 2/23/14.
//  Copyright (c) 2014 m3hcoril. All rights reserved.
//

#import "MyScene.h"

static const float ZOMBIE_MOVE_POINTS_PER_SEC = 120.0;

static const float ZOMBIE_ROTATE_RADIANS_PER_SEC = 4 * M_PI;

static inline CGPoint CGPointAdd(const CGPoint a, const CGPoint b)
{
    return CGPointMake(a.x + b.x, a.y + b.y);
}

static inline CGPoint CGPointSubtract(const CGPoint a, const CGPoint b)
{
    return CGPointMake(a.x - b.x, a.y - b.y);
}

static inline CGPoint CGPointMultiplyScalar(const CGPoint a, const CGFloat b)
{
    return CGPointMake(a.x * b, a.y * b);
}

static inline CGFloat CGPointLength(const CGPoint a) {
    return sqrtf(a.x * a.x + a.y * a.y);
}

static inline CGPoint CGPointNormalize(const CGPoint a) {
    CGFloat length = CGPointLength(a);
    return CGPointMake(a.x / length, a.y / length);
}

static inline CGFloat CGPointToAngle(const CGPoint a) {
    return atan2f(a.y, a.x);
}

static inline CGFloat CGPointDistance(const CGPoint a, const CGPoint b) {
    return (sqrt( (a.x - b.x)*(a.x - b.x) + (a.y - b.y)*(a.y - b.y) ));
}

static inline CGFloat ScalarSign(CGFloat a) {
    return a >= 0 ? 1 : -1;
}


// Returns shortest angle between two angles,
// between -M_PI and M_PI
static inline CGFloat ScalarShortestAngleBetween(const CGFloat a, const CGFloat b) {
    CGFloat difference = b - a;
    CGFloat angle = fmodf(difference, M_PI * 2);
    
    if (angle >= M_PI) {
        angle -= M_PI * 2;
    }
    else if (angle <= -M_PI) {
        angle += M_PI * 2;
    }
    return angle;
}

#define ARC4RANDOM_MAX 0x100000000
static inline CGFloat ScalarRandomRange(CGFloat min,
                                        CGFloat max) {
    return floorf(((double)arc4random() / ARC4RANDOM_MAX) * (max - min) + min);
}
                  
@implementation MyScene {
    SKSpriteNode *_zombie;
    CGPoint _velocity;
    CGPoint _lastTouchLocation;
    
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
        
        //[self spawnEnemy];
        [self runAction:[SKAction repeatActionForever:
                         [SKAction sequence:@[
                                              [SKAction performSelector:@selector(spawnEnemy)
                                                                           onTarget:self], [SKAction waitForDuration: 2.0]]]]];
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
    //NSLog(@"%0.2f miliseconds from last update",_dt*1000);
    
    if (CGPointDistance(_zombie.position, _lastTouchLocation) <= ZOMBIE_MOVE_POINTS_PER_SEC * _dt) {
        _zombie.position = CGPointMake(_lastTouchLocation.x, _lastTouchLocation.y);
        _velocity = CGPointZero;
    }
    [self moveSprite:_zombie velocity:_velocity];
    [self rotateSprite:_zombie toFace:_velocity rotateRadiansPerSec:ZOMBIE_ROTATE_RADIANS_PER_SEC ];
    [self boundsCheckPlayer];
}

-(void) moveSprite:(SKSpriteNode*) sprite velocity:(CGPoint)velocity {
    
    CGPoint ammountToMove = CGPointMultiplyScalar(velocity, _dt);
    
    //NSLog(@"Amount to move %@", NSStringFromCGPoint(ammountToMove));
    
    sprite.position = CGPointAdd(sprite.position, ammountToMove);

}

- (void)moveZombieToward:(CGPoint)location {
    CGPoint offset = CGPointSubtract(location, _zombie.position);

    CGFloat length = CGPointLength(offset);

    CGPoint direction = CGPointMultiplyScalar(offset, 1.0/length);
    

    _velocity = CGPointMultiplyScalar(direction, ZOMBIE_MOVE_POINTS_PER_SEC);
    
    
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInNode:self];
    [self moveZombieToward:touchLocation];
    
    _lastTouchLocation = touchLocation;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInNode:self];
    [self moveZombieToward:touchLocation];
    
    _lastTouchLocation = touchLocation;
    
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInNode:self];
    [self moveZombieToward:touchLocation];
    
    _lastTouchLocation = touchLocation;

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


- (void)rotateSprite:(SKSpriteNode *)sprite toFace:(CGPoint)velocity rotateRadiansPerSec:(CGFloat)rotateRadiansPerSec {
    //REMEMBER to compare zRotation (current) with velocity (already contains direction)
    
    float targetAngle = CGPointToAngle(velocity);
    
    float shortest = ScalarShortestAngleBetween(sprite.zRotation, targetAngle);
    
    float  amtToRotate = ZOMBIE_ROTATE_RADIANS_PER_SEC * _dt;
    
    if (ABS(shortest) < amtToRotate) {
        amtToRotate = ABS(shortest);
    }
    sprite.zRotation += ScalarSign(shortest) * amtToRotate;
}

-(void)spawnEnemy {
    /*
    SKSpriteNode *enemy = [SKSpriteNode spriteNodeWithImageNamed:@"enemy"];
    enemy.position = CGPointMake(self.size.width + enemy.size.width/2, self.size.height);
    
    [self addChild:enemy];
    
    SKAction *actionMidMove = [SKAction moveByX:-self.size.width/2-enemy.size.width/2
                                              y:-self.size.height + enemy.size.height/2 duration:1.0];
    
    SKAction *actionMove = [SKAction moveByX:-self.size.width/2-enemy.size.width/2
                                           y:self.size.height/2+enemy.size.height/2 duration:1.0];
    
    SKAction *wait = [SKAction waitForDuration:1.0];
    SKAction *logMessage = [SKAction runBlock:^{
        NSLog(@"Reached bottom!");
    }];
    
    SKAction *reverseMid = [actionMidMove reversedAction];
    
    SKAction *reverseMove = [actionMove reversedAction];
    
    SKAction *sequence =[SKAction sequence:@[actionMidMove, logMessage, wait, actionMove,
                                             reverseMove, logMessage, wait, reverseMid]];
    
    SKAction *repeat = [SKAction repeatActionForever:sequence];
    [enemy runAction:repeat];
    */
    
    SKSpriteNode *enemy = [SKSpriteNode spriteNodeWithImageNamed:@"enemy"];
    enemy.position = CGPointMake( self.size.width + enemy.size.width/2,
    ScalarRandomRange(enemy.size.height/2, self.size.height - enemy.size.height/2));
    
    [self addChild:enemy];
    
    SKAction *actionMove = [SKAction moveToX:-enemy.size.width/2 duration:2.0];
    SKAction *actionRemove = [SKAction removeFromParent];
    
    [enemy runAction: [SKAction sequence:@[actionMove, actionRemove]]];
}


@end
