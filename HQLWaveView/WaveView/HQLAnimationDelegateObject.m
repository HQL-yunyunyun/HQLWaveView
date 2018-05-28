//
//  HQLAnimationDelegate.m
//  HQLWaveView
//
//  Created by 何启亮 on 2018/5/28.
//  Copyright © 2018年 hql_personal_team. All rights reserved.
//

#import "HQLAnimationDelegateObject.h"

@implementation HQLAnimationDelegateObject

#pragma mark - CAAnimationDelegate

- (void)animationDidStart:(CAAnimation *)anim {
    if (self.delegate && [self.delegate respondsToSelector:@selector(hql_animationDidStart:)]) {
        [self.delegate hql_animationDidStart:anim];
    }
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    if (self.delegate && [self.delegate respondsToSelector:@selector(hql_animationDidStop:finished:)]) {
        [self.delegate hql_animationDidStop:anim finished:flag];
    }
}

@end
