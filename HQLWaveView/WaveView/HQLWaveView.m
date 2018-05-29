//
//  HQLWaveView.m
//  HQLWaveView
//
//  Created by 何启亮 on 2018/5/17.
//  Copyright © 2018年 hql_personal_team. All rights reserved.
//

#import "HQLWaveView.h"
#import "HQLWeakTarget.h"
#import "HQLAnimationDelegateObject.h"

#define kAnimationDefaultTime 2

@interface HQLWaveView () <HQLAnimationDelegate>

/**
 当前振幅强度
 */
@property (nonatomic, assign) CGFloat amplitude;

/**
 当前相移
 */
@property (nonatomic, assign) CGFloat phase;

/**
 保存波浪线
 */
@property (nonatomic, strong) NSMutableArray <CAShapeLayer *>*wavesArray;

/**
 控制 刷新
 */
@property (nonatomic, strong) CADisplayLink *displayLink;

/**
 弱引用target
 */
@property (nonatomic, strong) HQLWeakTarget *weakTarget;

/**
 是否在动画中
 */
@property (nonatomic, assign, getter=isAnimating) BOOL animating;

/**
 首尾两端的圆点layer
 */
@property (nonatomic, strong) NSMutableArray <CAShapeLayer *>*roundLayerArray;

/**
 开始动画和结束动画的两条线
 */
@property (nonatomic, strong) NSMutableArray <CAShapeLayer *>*lineLayerArray;

/**
 是否在开场动画 或 结束动画中
 */
@property (nonatomic, assign) BOOL durationAnimation;

/**
 记录完成的动画数
 */
@property (nonatomic, assign) NSInteger animationEndCount;

@end

@implementation HQLWaveView {
    BOOL _isBeginWithAnimation;
    BOOL _isEndWithAnimation;
    // 记录圆点的创建是否是在 开场动画中创建
    BOOL _roundPointCreateWithoutAnimation;
}

#pragma mark - initialize method

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self prepareView];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self prepareView];
    }
    return self;
}

- (void)dealloc {
    [self.displayLink invalidate];
    NSLog(@"deaolloc ---> %@", NSStringFromClass([self class]));
}

#pragma mark - prepare View

- (void)prepareView {
    
    self.animating = NO;
    
    // 创建一个弱引用target
    self.weakTarget = [HQLWeakTarget weakTargetWithTarget:self];
    
    self.numberOfWaves = 5;
    self.waveColor = [UIColor whiteColor];
    
    self.primaryWaveWidth = 2;
    self.secondaryWaveWidth = 1;
    
    self.idleAmplitude = 0.1;
    self.frequency = 1.5;
    self.density = 5;
    self.phaseShift = -0.15;
    self.waveLevel = 0.5;
    
    self.wavesArray = [NSMutableArray array];
    self.roundLayerArray = [NSMutableArray array];
    self.lineLayerArray = [NSMutableArray array];
}

#pragma mark - animate method

/**
 开始动画 --- 同时有一个开场的动画
 */
- (void)startAnimateWithOpeningAnimation {
    if (self.animating || self.durationAnimation) {
        return;
    }
    _roundPointCreateWithoutAnimation = NO;
    _isBeginWithAnimation = YES;
    self.durationAnimation = YES;
    self.animationEndCount = 2;
    
    CGFloat centerX = self.frame.size.width * 0.5;
    CGFloat centerY = self.frame.size.height * 0.5;
    
    // 创建两个圆点
    [self createRoundPoint];
    // 给两个点的圆点来个originPath
    NSInteger index = 0;
    for (CAShapeLayer *roundPoint in self.roundLayerArray) {
        UIBezierPath *path = [[UIBezierPath alloc] init];
        [path addArcWithCenter:CGPointMake(centerX, centerY) radius:(self.primaryWaveWidth * 2) startAngle:0 endAngle:(2 * M_PI) clockwise:YES];
        roundPoint.path = path.CGPath;
        // 添加动画
        [roundPoint addAnimation:[self createRoundPointAnimateWithIsLeft:(index == 0) isBegin:YES animationDuration:kAnimationDefaultTime originPosition:roundPoint.position] forKey:[NSString stringWithFormat:@"Begin_RoundPointAnimation_%ld", index]];
        
        index++;
    }
    
    // 创建两条线
    [self createLine];
    index = 0;
    for (CAShapeLayer *line in self.lineLayerArray) {
        UIBezierPath *path = [[UIBezierPath alloc] init];
        [path moveToPoint:CGPointMake(centerX, centerY)];
        [path addLineToPoint:CGPointMake(centerX + (index == 0 ? -1 : 1), centerY)];
        line.path = path.CGPath;
        // 添加动画
        [line addAnimation:[self createLineAnimateWithIsLeft:(index == 0) isBegin:YES animationDuration:kAnimationDefaultTime] forKey:[NSString stringWithFormat:@"Begin_LineAnimation_%ld", index]];
        
        index++;
    }
}

/**
 结束动画 --- 同时有一个散场动画
 */
- (void)stopAnimateWithEndingAnimation {
    
    if (!self.isAnimating || self.durationAnimation) {
        return;
    }
    _isEndWithAnimation = YES;
    
    CGFloat centerX = self.frame.size.width * 0.5;
    CGFloat centerY = self.frame.size.height * 0.5;
    CGFloat viewWidth = self.frame.size.width;
    
    // 创建两条线
    [self createLine];
    NSInteger index = 0;
    for (CAShapeLayer *line in self.lineLayerArray) {
        UIBezierPath *path = [[UIBezierPath alloc] init];
        [path moveToPoint:CGPointMake(centerX, centerY)];
        CGFloat x = 0;
        if (index == 0) {
            x = [self roundPointWidth] - self.primaryWaveWidth * 0.5;
        } else {
            x = viewWidth - [self roundPointWidth] + self.primaryWaveWidth * 0.5;
        }
        [path addLineToPoint:CGPointMake(x, centerY)];
        line.path = path.CGPath;
        index++;
    }
    
    // 移除waves
    [self removeWavesLayerAndDisplay];
    self.animating = NO;
    self.durationAnimation = YES;
    self.animationEndCount = 1;
    
    // 添加动画
    index = 0;
    for (CAShapeLayer *line in self.lineLayerArray) {
        // 添加动画
        [line addAnimation:[self createLineAnimateWithIsLeft:(index == 0) isBegin:NO animationDuration:kAnimationDefaultTime] forKey:[NSString stringWithFormat:@"End_LineAnimation_%ld", index]];
        index++;
    }
    
    index = 0;
    for (CAShapeLayer *roundPoint in self.roundLayerArray) {
        // 添加动画
        if (!_roundPointCreateWithoutAnimation) {
            [roundPoint addAnimation:[self createRoundPointAnimateWithIsLeft:(index == 0) isBegin:NO animationDuration:kAnimationDefaultTime originPosition:roundPoint.position] forKey:[NSString stringWithFormat:@"End_RoundPointAnimation_%ld", index]];
        } else {
            [roundPoint addAnimation:[self createNoAnimateRoundPointEndAnimateWIthIsLeft:(index == 0) animationDuration:kAnimationDefaultTime originPosition:roundPoint.position] forKey:[NSString stringWithFormat:@"End_RoundPointAnimation_%ld", index]];
        }
        
        index++;
    }
}

/**
 开始动画
 */
- (void)startAnimate {
    
    if (self.animating || self.durationAnimation) {
        return;
    }
    self.animating = YES;
    
    // 创建waves
    [self createWaves];
    // 判断displayLink
    if (self.displayLink) {
        [self.displayLink invalidate];
        self.displayLink = nil;
    }
    // 创建displayLink
    self.displayLink = [CADisplayLink displayLinkWithTarget:self.weakTarget selector:@selector(drawWave)];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    
    // 需要将 开场动画的两条线隐藏
    [self removeArrayLayer:self.lineLayerArray];
    
    // 判断是否有两个圆
    if (self.roundLayerArray.count <= 0) {
        _roundPointCreateWithoutAnimation = YES;
        // 没有开场动画 --- 需要画两个圆
        [self createRoundPoint];
        // 给两个点的圆点来个originPath
        NSInteger index = 0;
        for (CAShapeLayer *roundPoint in self.roundLayerArray) {
            UIBezierPath *path = [[UIBezierPath alloc] init];
            
            CGFloat x = 0;
            if (index == 0) {
                x = [self roundPointWidth] * 0.5;
            } else {
                x = self.frame.size.width - ([self roundPointWidth] * 0.5);
            }
            
            [path addArcWithCenter:CGPointMake(x, self.frame.size.height * 0.5) radius:(self.primaryWaveWidth * 2) startAngle:0 endAngle:(2 * M_PI) clockwise:YES];
            roundPoint.path = path.CGPath;
            
            index++;
        }
    }
    
    
    // 回调 ---
    if (self.waveDidStartAnimateCallback) {
        self.waveDidStartAnimateCallback(self);
    }
}

- (void)stopAnimate {
    
    if (!self.animating || self.durationAnimation) {
        return;
    }
    self.animating = NO;
    
    [self removeWavesLayerAndDisplay];
    // 移除两个圆
    [self removeArrayLayer:self.roundLayerArray];
}

- (CGFloat)roundPointWidth {
    // 圆点的大小 --- 线宽 --- 原的半径
    CGFloat roundWidth = self.primaryWaveWidth * 2 + self.primaryWaveWidth * 4;
    return roundWidth;
}

#pragma mark - tool

/**
 移除layer
 */
- (void)removeArrayLayer:(NSMutableArray *)layerArray {
    [layerArray makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
    [layerArray removeAllObjects];
    
    if (self.waveDidEndAnimateCallback) {
        self.waveDidEndAnimateCallback(self);
    }
}

- (void)removeWavesLayerAndDisplay {
    [self removeArrayLayer:self.wavesArray];
    
    [self.displayLink invalidate];
    self.displayLink = nil;
}

#pragma mark - draw wave method

/**
 画波浪线的方法
 */
- (void)drawWave {
    
    /*
     2018.5.29 : 因为在两边添加了两个圆点，目前计算波浪线的算法是截取两端，即没有做出调整算出来的曲线是以0到View.width为标准，那么就会表现为圆点那不是起点，所以这样显示就会有问题。
     */
    
    // 波浪线 --- 中间高两边低
    
    CGFloat viewHeight = CGRectGetHeight(self.frame);
    CGFloat viewWidth = CGRectGetWidth(self.frame);
    CGFloat waveMid = viewWidth * 0.5;
    CGFloat maxAmplitude = viewHeight - (self.primaryWaveWidth * 2); // 最大的振幅
    
    // 设置振幅强度
    self.waveLevel = self.waveLevelCallback ? self.waveLevelCallback(self) : self.waveLevel;
    self.phase += self.phaseShift;
    
    self.amplitude = fmax(self.waveLevel, self.idleAmplitude);
    
    for (int i = 0; i < self.wavesArray.count; i++) {
        // 画波浪线的路径
        // 使用CGPath
        CGMutablePathRef wavePath = CGPathCreateMutable();
        // Progress is a value between 1.0 and -0.5, determined by the current wave idx, which is used to alter the wave's amplitude.
        // 计算波浪线的一个振幅的强度
        CGFloat progress = 1.0f - (CGFloat)i / self.numberOfWaves;
        CGFloat normedAmplitude = (1.5f * progress - 0.5f) * self.amplitude;
        
        CGFloat beginX = [self roundPointWidth] - self.primaryWaveWidth * 0.5;
        CGFloat maxX = viewWidth - [self roundPointWidth] + self.primaryWaveWidth * 0.5;
        
        for (CGFloat x = beginX; x < (maxX + self.density); x += self.density) {
            
            // 将超出 maxX 的x 都设置成 maxX
            if (x >= maxX) {
                x = maxX;
            }
            // We use a parable to scale the sinus wave, that has its peak in the middle of the view.
            // 这个比例会使波浪线的振幅中间高 --- 两边小
            CGFloat scaling = -pow(x / waveMid - 1, 2) + 1;
            // 显示在中间
            CGFloat y = (scaling * maxAmplitude * normedAmplitude) * sin((2 * M_PI * (x / viewWidth) * self.frequency) + self.phase) + (viewHeight * 0.5);
            
            if (x == beginX) { // 表示刚开始画波浪线
                CGPathMoveToPoint(wavePath, nil, x, y);
            } else {
                CGPathAddLineToPoint(wavePath, nil, x, y);
            }
            
        }
        
        CAShapeLayer *waveLine = [self.wavesArray objectAtIndex:i];
        waveLine.path = wavePath;
        CGPathRelease(wavePath);
    }
    
}

#pragma mark - calayer animation method

/**
 创建 圆点 的动画

 @param isLeft 是否是向左的圆点
 @param isBegin 是否是开始的动画
 @param animationDuration 动画持续时间
 @return animation
 */
- (CAAnimation *)createRoundPointAnimateWithIsLeft:(BOOL)isLeft isBegin:(BOOL)isBegin animationDuration:(NSTimeInterval)animationDuration originPosition:(CGPoint)originPosition {
    // 这是位置移动的动画
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position"];
    animation.removedOnCompletion = NO;
    animation.duration = animationDuration;
    animation.fillMode = kCAFillModeForwards;
    // delegate
    HQLAnimationDelegateObject *obj = [[HQLAnimationDelegateObject alloc] init];
    obj.delegate = self;
    animation.delegate = obj;
    
    CGPoint toValue = CGPointZero;
    CGFloat distance = 0;
    
    // 判断位置 :
    // 在左边且开始动画 -> 向左移动
    // 在左边且结束动画 -> 向右移动
    // 在右边且开始动画 -> 向右移动
    // 在右边且结束动画 -> 向左移动
    if (!isBegin) {
        toValue = originPosition;
    } else {
        // 开始动画
        if (isLeft) {
            distance = (-self.frame.size.width * 0.5) + [self roundPointWidth] * 0.5;
        } else {
            distance = self.frame.size.width * 0.5 - [self roundPointWidth] * 0.5;
        }
        toValue = CGPointMake(originPosition.x + distance, originPosition.y);
    }
    
    animation.toValue = [NSValue valueWithCGPoint:toValue];
    return animation;
}

/**
 两个圆点创建时是直接创建在两端 --- 那么结束动画跟创建圆点时在中间是不一样的(position 不一样)
 因为 CABasicAnimation 是不会改变 CALayer 的值的，所以如果根据 CALayer 的position 来计算移动的position是不对的
 */
- (CAAnimation *)createNoAnimateRoundPointEndAnimateWIthIsLeft:(BOOL)isLeft animationDuration:(NSTimeInterval)animationDuration originPosition:(CGPoint)originPosition {
    // 这是位置移动的动画
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position"];
    animation.removedOnCompletion = NO;
    animation.duration = animationDuration;
    animation.fillMode = kCAFillModeForwards;
    // delegate
    HQLAnimationDelegateObject *obj = [[HQLAnimationDelegateObject alloc] init];
    obj.delegate = self;
    animation.delegate = obj;
    
    CGPoint toValue = CGPointZero;
    CGFloat distance = 0;
    
    // 判断位置 :
    if (isLeft) {
        distance = self.frame.size.width * 0.5 - [self roundPointWidth] * 0.5;
    } else {
        distance = (-self.frame.size.width * 0.5) + [self roundPointWidth] * 0.5;
    }
    toValue = CGPointMake(originPosition.x + distance, originPosition.y);
    
    animation.toValue = [NSValue valueWithCGPoint:toValue];
    return animation;
}

/**
 创建 line 的动画

 @param isLeft 是否是左边的线
 @param isBegin 是否是开始的动画
 @param animationDuration 动画持续时间
 @return 动画
 */
- (CAAnimation *)createLineAnimateWithIsLeft:(BOOL)isLeft isBegin:(BOOL)isBegin animationDuration:(NSTimeInterval)animationDuration {
    // 这是Path改变的动画
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"path"];
    animation.removedOnCompletion = NO;
    animation.duration = animationDuration;
    animation.fillMode = kCAFillModeForwards;
    // delegate
    HQLAnimationDelegateObject *obj = [[HQLAnimationDelegateObject alloc] init];
    obj.delegate = self;
    animation.delegate = obj;
    
    UIBezierPath *toValue = [[UIBezierPath alloc] init];
    
    CGFloat centerY = self.frame.size.height * 0.5;
    CGFloat centerX = self.frame.size.width * 0.5;
    [toValue moveToPoint:CGPointMake(centerX, centerY)];
    // 是否是开始的动画
    if (isBegin) {
        
        CGFloat x = 0;
        if (isLeft) {
            // 向左 --- 那么圆点是去到中点的左边
            x = [self roundPointWidth] - self.primaryWaveWidth * 0.5;
        } else {
            // 向右 --- 那么圆点是去到中点的右边
            x = self.frame.size.width - [self roundPointWidth] + self.primaryWaveWidth * 0.5;
        }
        [toValue addLineToPoint:CGPointMake(x, centerY)];
        
    } else {
        // 结束的动画 --- 线都是回到中点
        [toValue addLineToPoint:CGPointMake(centerX + (isLeft ? -1 : 1), centerY)];
    }
    
    animation.toValue = (__bridge id _Nullable)(toValue.CGPath);
    
    return animation;
}

#pragma mark - HQLAnimationDelegate

/*
 判断是否是动画中的逻辑 --- 设置self.animationEndCount 的个数为当前的动画数
 没调用一次 "animationDidStop:(CAAnimation *)anim finished:(BOOL)flag" self.animationEndCount 减一
 当 self.animationEndCount 等于0，则表明当前的动画已完成
 */

- (void)hql_animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    self.animationEndCount--;
    if (self.animationEndCount == 0) {
        
        // 结束了所有的动画
        self.durationAnimation = NO;
        // 开场动画完成
        if (_isBeginWithAnimation) {
            _isBeginWithAnimation = NO;
            
            // 回调
            if (self.waveViewBeginAnimationDidEndAnimateCallback) {
                self.waveViewBeginAnimationDidEndAnimateCallback(self);
            }
            
            [self startAnimate];
        }
        if (_isEndWithAnimation) {
            _isEndWithAnimation = NO;
            
            // 回调
            if (self.waveViewEndAnimationDidEndAnimateCallback) {
                self.waveViewEndAnimationDidEndAnimateCallback(self);
            }
            // 移除圆点和线
            [self removeArrayLayer:self.roundLayerArray];
            [self removeArrayLayer:self.lineLayerArray];
        }
    }
}

#pragma mark - create layer method

/**
 创建waves
 */
- (void)createWaves {
    if (self.numberOfWaves <= 0) {
        return;
    }
    
    [self removeArrayLayer:self.wavesArray];
    
    for (int i = 0; i < self.numberOfWaves; i++) {
        CAShapeLayer *waveLine = [CAShapeLayer layer];
        waveLine.lineCap = kCALineCapRound;
        waveLine.lineJoin = kCALineJoinRound;
        
        CGFloat progress = 1.0f - (CGFloat)i / self.numberOfWaves;
        CGFloat multiplier = MIN(1.0, (progress / 3.0f * 2.0f) + (1.0f / 3.0f));
        UIColor *color = [self.waveColor colorWithAlphaComponent:(i == 0 ? 1 : 1 * multiplier * 0.6)];
        waveLine.strokeColor = color.CGColor;
        
        waveLine.fillColor = [UIColor clearColor].CGColor;
        waveLine.lineWidth = (i == 0 ? self.primaryWaveWidth : self.secondaryWaveWidth);
        
        [self.layer addSublayer:waveLine];
        [self.wavesArray addObject:waveLine];
    }
    
}

- (void)createRoundPoint {
    
    // 创建首尾两端的圆点
    [self removeArrayLayer:self.roundLayerArray];
    
    for (int i = 0; i < 2; i++) {
        CAShapeLayer *roundPoint = [CAShapeLayer layer];

        roundPoint.strokeColor = self.waveColor.CGColor;
        roundPoint.fillColor = [UIColor clearColor].CGColor;
        roundPoint.lineWidth = self.primaryWaveWidth;

        [self.layer addSublayer:roundPoint];
        [self.roundLayerArray addObject:roundPoint];
    }
    
}

- (void)createLine {
    // 创建开始动画和结束动画的两条线
    [self removeArrayLayer:self.lineLayerArray];
    
    for (int i = 0; i < 2; i++) {
        CAShapeLayer *roundPoint = [CAShapeLayer layer];
        
        roundPoint.strokeColor = self.waveColor.CGColor;
        roundPoint.fillColor = [UIColor clearColor].CGColor;
        roundPoint.lineWidth = self.primaryWaveWidth;
        
        [self.layer addSublayer:roundPoint];
        [self.lineLayerArray addObject:roundPoint];
    }
}

@end
