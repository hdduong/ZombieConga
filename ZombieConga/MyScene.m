//
//  MyScene.m
//  ZombieConga
//
//  Created by Duong Duc Hien on 2/23/14.
//  Copyright (c) 2014 m3hcoril. All rights reserved.
//

#import "MyScene.h"

static const float ZOMBIE_MOVE_POINTS_PER_SEC = 120.0;
static const float TRAIN_MOVE_POINTS_PER_SEC = 120.0;

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
    
    SKAction *_zombieAnaimation;
    SKAction *_catCollisionSound;
    SKAction *_enemyCollisionSound;
    
    BOOL _zombieBlinking;
    
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
        
        NSMutableArray *textures = [NSMutableArray arrayWithCapacity:10];
        
        for (int i =1;i < 4;i ++) {
            NSString *textureName = [NSString stringWithFormat:@"zombie%d",i];
            SKTexture *texture = [SKTexture textureWithImageNamed:textureName];
            [textures addObject:texture];
        }
        
        _zombieAnaimation = [SKAction animateWithTextures:textures timePerFrame:0.1];
        
        //[_zombie runAction:[SKAction repeatActionForever:_zombieAnaimation]];
        
        
        [self runAction:[SKAction repeatActionForever: [SKAction sequence:@[ [SKAction performSelector:@selector(spawnCat) onTarget:self], [SKAction waitForDuration:1.0]]]]];
        
        _catCollisionSound = [SKAction playSoundFileNamed:@"hitCat.wav" waitForCompletion:NO];
        _enemyCollisionSound = [SKAction playSoundFileNamed:@"hitCatLady.wav" waitForCompletion:NO];
        
        _zombieBlinking = FALSE;
        _zombie.zPosition = 100;
        

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
        
        [self stopZombieAnimation];
    }
    [self moveSprite:_zombie velocity:_velocity];
    [self rotateSprite:_zombie toFace:_velocity rotateRadiansPerSec:ZOMBIE_ROTATE_RADIANS_PER_SEC ];
    [self boundsCheckPlayer];
    [self moveTrain];
}

-(void) didEvaluateActions {
    [self checkCollisions];
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
    [self startZombieAnimation];

    
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
    enemy.name = @"enemy";
    
    enemy.position = CGPointMake( self.size.width + enemy.size.width/2,
    ScalarRandomRange(enemy.size.height/2, self.size.height - enemy.size.height/2));
    
    [self addChild:enemy];
    
    SKAction *actionMove = [SKAction moveToX:-enemy.size.width/2 duration:2.0];
    SKAction *actionRemove = [SKAction removeFromParent];
    
    [enemy runAction: [SKAction sequence:@[actionMove, actionRemove]]];
}

- (void)startZombieAnimation {
    if (![_zombie actionForKey:@"animation"]) {
        [_zombie runAction: [SKAction repeatActionForever:_zombieAnaimation] withKey:@"animation"];
    }
}

- (void)stopZombieAnimation {
    [_zombie removeActionForKey:@"animation"];
}


- (void)spawnCat {
    // 1
    SKSpriteNode *cat = [SKSpriteNode spriteNodeWithImageNamed:@"cat"];
    cat.name = @"cat";
    
    cat.position = CGPointMake( ScalarRandomRange(0, self.size.width), ScalarRandomRange(0, self.size.height));
    
    cat.xScale = 0;
    cat.yScale = 0;
    
    [self addChild:cat];
    
    
    /*
    SKAction *appear = [SKAction scaleTo:1.0 duration:0.5];
    SKAction *wait = [SKAction waitForDuration:3.0];
    SKAction *disappear = [SKAction scaleTo:0.0 duration:0.5];
    SKAction *removeFromParent = [SKAction removeFromParent];
    [cat runAction: [SKAction sequence:@[appear, wait, disappear, removeFromParent]]];
     */
    
    cat.zRotation = -M_PI / 16;
    SKAction *appear = [SKAction scaleTo:1.0 duration:0.5];
    SKAction *leftWiggle = [SKAction rotateByAngle:M_PI / 8
                                          duration:0.5];
    SKAction *rightWiggle = [leftWiggle reversedAction];
    SKAction *fullWiggle =[SKAction sequence:@[leftWiggle, rightWiggle]];
    
    //SKAction *wiggleWait = [SKAction repeatAction:fullWiggle count:10];
    
    SKAction *scaleUp = [SKAction scaleBy:1.2 duration:0.25];
    SKAction *scaleDown = [scaleUp reversedAction];
    SKAction *fullScale = [SKAction sequence: @[scaleUp, scaleDown, scaleUp, scaleDown]];
    SKAction *group = [SKAction group:@[fullScale, fullWiggle]];
    SKAction *groupWait = [SKAction repeatAction:group count:1000];
    
    SKAction *disappear = [SKAction scaleTo:0.0 duration:0.5];
    SKAction *removeFromParent = [SKAction removeFromParent];
    [cat runAction: [SKAction sequence: @[appear,groupWait , disappear, removeFromParent]]];
}

-(void) checkCollisions {
   

    [self enumerateChildNodesWithName:@"cat" usingBlock:^(SKNode *node, BOOL *stop) {
        SKSpriteNode *cat = (SKSpriteNode *) node;
        if (CGRectIntersectsRect(cat.frame, _zombie.frame)) {
            //[cat removeFromParent];
            [self runAction:_catCollisionSound];
            cat.name = @"train";
            [cat removeAllActions];
            
            [cat setScale:1.0];
            cat.zRotation = 0.0;
            /*
            [cat runAction:[SKAction repeatActionForever:
                            [SKAction sequence:@[
                                                 [SKAction colorizeWithColor:[SKColor greenColor] colorBlendFactor:1.0 duration:0.2],
                                                 [SKAction colorizeWithColorBlendFactor: 0.0 duration:0.2],
                                                 ]]
            ]];
            */
            cat.color = [SKColor greenColor];
            cat.colorBlendFactor = 1.0;
        }
    }];
    
   
    [self enumerateChildNodesWithName:@"enemy" usingBlock:^(SKNode *node, BOOL *stop) {
        SKSpriteNode *enemy = (SKSpriteNode *) node;
        CGRect smallerFrame = CGRectInset(enemy.frame, 20, 20);
        
        if (CGRectIntersectsRect(smallerFrame, _zombie.frame)) {
            if (!_zombieBlinking) {
            //[enemy removeFromParent];
                _zombieBlinking = TRUE;
                [self runAction:_enemyCollisionSound];
                [self zombieBlink];
            }
        }
    }];
   
}

-(void) zombieBlink {
    
    float blinkTimes = 10;
    float blinkDuration = 5.0;
    
    SKAction *blinkAction = [SKAction customActionWithDuration:blinkDuration actionBlock:^(SKNode *node, CGFloat elapsedTime) {
        float slice = blinkDuration/ blinkTimes;
        float remainder = fmodf(elapsedTime,slice);
        node.hidden = remainder > (slice/2);
    }];
    
    [_zombie runAction:blinkAction completion:^{
        _zombie.hidden = FALSE;
        _zombieBlinking = FALSE;
    }];
}

-(void) moveTrain {
    __block CGPoint targetPosition = _zombie.position;
    
    [self enumerateChildNodesWithName:@"train" usingBlock:^(SKNode *node, BOOL *stop) {
        if (!node.hasActions) {
            float actionDuration = 0.3;
            CGPoint offset = CGPointSubtract(targetPosition, node.position);
            
            float offsetLength = CGPointLength(offset);
            CGPoint direction = CGPointMultiplyScalar(offset, 1.0/offsetLength);
            
            CGPoint ammountToMovePerSec = CGPointMultiplyScalar(direction, TRAIN_MOVE_POINTS_PER_SEC);
            CGPoint amountToMove = CGPointMultiplyScalar(ammountToMovePerSec, actionDuration);
            
            [node runAction:[SKAction moveBy:CGVectorMake(amountToMove.x, amountToMove.y) duration:actionDuration]];
            
        }
        targetPosition = node.position;
    }];
}
@end
