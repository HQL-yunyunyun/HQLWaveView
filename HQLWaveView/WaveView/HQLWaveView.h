//
//  HQLWaveView.h
//  HQLWaveView
//
//  Created by 何启亮 on 2018/5/17.
//  Copyright © 2018年 hql_personal_team. All rights reserved.
//

#import <UIKit/UIKit.h>

/*
 波纹的View :
 利用 正弦曲线公式 来画出波浪
 公式:y=Asin(ωx+φ)+k
 A :振幅,曲线最高位和最低位的距离
 ω :角速度,用于控制周期大小，单位x中起伏的个数
 K :偏距,曲线上下偏移量
 φ :初相,曲线左右偏移量
 */

/*
 默认的振幅为 View 的 height
 线的长度默认为 View 的 width
 */

@interface HQLWaveView : UIView

/**
 波浪线的数量 --- 只有一条主波浪线，其他都为次波浪线
 default : 5
 */
@property (nonatomic, assign) NSUInteger numberOfWaves;

/**
 波浪线的颜色 --- 次波浪线的颜色将是waveColor0.6的透明度的颜色
 */
@property (nonatomic, strong) UIColor *waveColor;

/**
 主波浪线的宽度
 default : 2
 */
@property (nonatomic, assign) CGFloat primaryWaveWidth;

/**
 次波浪线的宽度
 default : 1
 */
@property (nonatomic, assign) CGFloat secondaryWaveWidth;

/**
 最小的振幅强度 --- 即当幅度接近0时的幅度，如果值大于0将会有更加生动的动画
 default : 0.1
 */
@property (nonatomic, assign) CGFloat idleAmplitude;

/**
 当前振幅强度
 */
@property (nonatomic, assign, readonly) CGFloat amplitude;

/**
 波的频率，值越高，将有越多的波峰(值越高，正弦的周期越短)
 default : 1.5
 */
@property (nonatomic, assign) CGFloat frequency;

/**
 绘制点的密度(这个属性表现为两个点的 x 值的距离，即self.density越高则绘制的点的密度越低)，如果绘制的点的密度越高那么需要消耗的性能越高。
 default : 5
 */
@property (nonatomic, assign) CGFloat density;

/**
 相移 :  在这里表现为动画移动的方向和速度
 default : -0.15
 */
@property (nonatomic, assign) CGFloat phaseShift;

/**
 振幅的强度 --- 1倍为当前设定最大的振幅，2为两倍，以此类推
 default : 0.5
 */
@property (nonatomic, assign) CGFloat waveLevel;

/**
 获取振幅强度 --- 如果不赋值，将使用 waveLevel
 */
@property (nonatomic, copy) CGFloat(^waveLevelCallback)(HQLWaveView *waveView);

/**
 是否在动画中
 */
@property (nonatomic, assign, readonly, getter=isAnimating) BOOL animating;

/**
 开始动画 --- 将使用 CADisplayLink 来刷新动画
 */
- (void)startAnimate;

/**
 结束动画 --- wave都将移除
 */
- (void)stopAnimate;

@end