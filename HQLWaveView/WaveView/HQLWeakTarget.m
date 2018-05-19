//
//  HQLWeakProxy.m
//  HQLWaveView
//
//  Created by 何启亮 on 2018/5/17.
//  Copyright © 2018年 hql_personal_team. All rights reserved.
//

#import "HQLWeakTarget.h"

@implementation HQLWeakTarget

+ (instancetype)weakTargetWithTarget:(id)target {
    return [[self alloc] initWithTarget:target];
}

- (instancetype)initWithTarget:(id)target {
    _target = target;
    return self;
}

/*
 重写下面两个方法 : 消息转发方法
 这两个方法的触发机制：
 这个触发机制涉及到了runtime的方法调用流程:
 1.在相应操作的对象中的缓存方法列表中找调用的方法，如果找到则转向相应实现并执行;
 2.在1没找到的情况下，在相应操作的对象中的方法列表找调用的方法，如果找到则转向相应实现并执行;
 3.在1/2都失败的情况下去父类指针指向的对象中执行1/2；
 4.以此类推，如果一直到根类都没有找到相应的方法，则转向拦截调用，走转发机制;
 5.若类没有重写拦截的方法，则程序报错。
 
 而拦截调用的几个方法就是:
 + (BOOL)resolveClassMethod:(SEL)sel;
 + (BOOL)resolveInstanceMethod:(SEL)sel;
 - (id)forwardingTargetForSelector:(SEL)aSelector;
 - (void)forwardInvocation:(NSInvocation *)anInvocation;

 调用顺序为:
 1.动态方法解析 : 检查当前类是否动态向该类添加了方法 --- 可以在这个方法中动态添加实现的方法。
     + (BOOL)resolveInstanceMethod:(SEL)sel;
 2.快速消息转发 : 检查类是否重写了 [class forwardingTargetForSelector:] 方法，如果返回了非nil/非self的实例，就会向该实例重新发送消息(再走一次方法调用的流程 --- 可以理解为通过重写这个方法，可以返回一个实现了 sel(方法) 的实例，调用该实例的方法)。
 3.标准消息转发 : runtime发送methodSignatureForSelector:消息获取Selector对应的方法签名，返回值非空则通过forwardInvocation:转发消息，返回值为空则向当前对象发送doesNotRecognizeSelector:消息，程序崩溃退出。(标准消息转发可以转发给多个对象，但开销比较大)
 
 参考博客:
 https://neyoufan.github.io/2017/01/13/ios/BayMax_HTSafetyGuard/
 https://nianxi.net/ios/objc-multi-inheritance.html
 */

/*
 标准消息转发
 */

/**
 获取方法签名
 */
- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    return [_target methodSignatureForSelector:sel];
}

/**
 转发消息
 */
- (void)forwardInvocation:(NSInvocation *)invocation {
    if ([_target respondsToSelector:[invocation selector]]) {
        [invocation invokeWithTarget:_target];
    }
}

@end
