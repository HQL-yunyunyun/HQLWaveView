//
//  HQLWaveView.m
//  HQLWaveView
//
//  Created by 何启亮 on 2018/5/17.
//  Copyright © 2018年 hql_personal_team. All rights reserved.
//

#import "HQLWaveView.h"
#import "HQLWeakTarget.h"

@interface HQLWaveView ()

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

@end

@implementation HQLWaveView

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
}

#pragma mark - event

/**
 开始动画
 */
- (void)startAnimate {
    
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
}

- (void)stopAnimate {
    self.animating = NO;
    
    [self.wavesArray enumerateObjectsUsingBlock:^(CAShapeLayer * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperlayer];
    }];
    [self.wavesArray removeAllObjects];
    
    [self.displayLink invalidate];
    self.displayLink = nil;
}

/**
 画波浪线的方法
 */
- (void)drawWave {
    
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
        UIBezierPath *wavePath = [UIBezierPath bezierPath];
        // Progress is a value between 1.0 and -0.5, determined by the current wave idx, which is used to alter the wave's amplitude.
        // 计算波浪线的一个振幅的强度
        CGFloat progress = 1.0f - (CGFloat)i / self.numberOfWaves;
        CGFloat normedAmplitude = (1.5f * progress - 0.5f) * self.amplitude;
        
        for (CGFloat x = 0; x < (viewWidth + self.density); x += self.density) {
            
            // We use a parable to scale the sinus wave, that has its peak in the middle of the view.
            // 这个比例会使波浪线的振幅中间高 --- 两边小
            CGFloat scaling = -pow(x / waveMid - 1, 2) + 1;
            // 显示在中间
            CGFloat y = (scaling * maxAmplitude * normedAmplitude) * sin((2 * M_PI * (x / viewWidth) * self.frequency) + self.phase) + (viewHeight * 0.5);
            
            if (x == 0) { // 表示刚开始画波浪线
                [wavePath moveToPoint:CGPointMake(x, y)];
            } else {
                [wavePath addLineToPoint:CGPointMake(x, y)];
            }
            
        }
        
        CAShapeLayer *waveLine = [self.wavesArray objectAtIndex:i];
        waveLine.path = [wavePath CGPath];
    }
    
}

/**
 创建waves
 */
- (void)createWaves {
    if (self.numberOfWaves <= 0) {
        return;
    }
    
    [self.wavesArray enumerateObjectsUsingBlock:^(CAShapeLayer * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperlayer];
    }];
    [self.wavesArray removeAllObjects];
    
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

@end
