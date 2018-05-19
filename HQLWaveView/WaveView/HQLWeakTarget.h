//
//  HQLWeakProxy.h
//  HQLWaveView
//
//  Created by 何启亮 on 2018/5/17.
//  Copyright © 2018年 hql_personal_team. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 通过这个类来持有一个弱引用的 target，并重写方法转发，以此来打破循环引用
 例如: CADisplayLink 和 NSTimer 的情况
 参考博客:
 https://www.jianshu.com/p/8adb7f8dec82
 
 还有一种方法可以来打破NSTimer或CADisplayLink的循环引用:
      创建一个NSObjet 并通过 Method Swizzling 实现 Timer/DisplayLink 强引用的方法.
 
 其实这上面两种方法都是通过一个 弱引用target 来打破循环引用，但重写NSProxy这个方法实现更加好一点，适用的范围更加大.
 */

@interface HQLWeakTarget : NSProxy

@property (nonatomic, weak, readonly) id target;

+ (instancetype)weakTargetWithTarget:(id)target;

@end
