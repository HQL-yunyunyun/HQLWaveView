//
//  HQLAnimationDelegate.h
//  HQLWaveView
//
//  Created by 何启亮 on 2018/5/28.
//  Copyright © 2018年 hql_personal_team. All rights reserved.
//

#import <UIKit/UIKit.h>

/*
 说明：
 因为 CAAnimation 的 delegate 是 strong 引用的(为了避免在动画中，对象被释放掉)，所以就会造成内存泄漏。
 内存引用关系： View (强引用)-> layer(CAAnimation 是针对于 CALayer 的) / layer (强引用)-> CAAnimation / CAAnimation.delegate (强引用)-> View
 要打破这个循环引用的关系可以在 CAAnimation.delegate (强引用)-> View  这里入手，只要View是弱引用就OK了(参考 HQLWeakTarget) / 或者在动画完成的时候移除动画(但移除动画那么动画效果就会没了)。
 但这里使用 HQLWeakTarget 也会出现一个问题： 当动画还没完成，而View要释放(具体的表现就是：在进行动画的时候，Controller pop 回上一个Controller)，因为View释放了，那么 HQLWeakTarget.target 就为 nil ，而 HQLWeakTarget 转发消息是利用 "forwardInvocation:(NSInvocation *)invocation" "methodSignatureForSelector:(SEL)sel" 这两个方法，而消息转发出去必须是 HQLWeakTarget.target 不能为 nil ，这样就出现了一个bug了，所以最后表现为 doesNotRecognizeSelector 的错误。
 那么 HQLWeakTarget 走不通，可以通过创建一个新的 object 来弱引用 target，然后再实现 CAAnimationDelegate。
 ps: 这样的实现方法太粗暴了...
 */

@protocol HQLAnimationDelegate <NSObject>

@optional

/* Called when the animation begins its active duration. */

- (void)hql_animationDidStart:(CAAnimation *)anim;

/* Called when the animation either completes its active duration or
 * is removed from the object it is attached to (i.e. the layer). 'flag'
 * is true if the animation reached the end of its active duration
 * without being removed. */

- (void)hql_animationDidStop:(CAAnimation *)anim finished:(BOOL)flag;

@end

@interface HQLAnimationDelegateObject : NSObject <CAAnimationDelegate>

@property (nonatomic, weak) id <HQLAnimationDelegate>delegate;

@end
