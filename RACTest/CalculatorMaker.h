//
//  CalculatorMaker.h
//  RACTest
//
//  Created by jimi on 2018/11/20.
//  Copyright © 2018 szy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CalculatorMaker : NSObject
@property (nonatomic, assign) int result;
//加法
- (CalculatorMaker *(^)(int value))add;
//减法
- (CalculatorMaker *(^)(int value))sub;
//归0
- (CalculatorMaker *(^)(void))clean;

- (void)makeCalculator:(void(^)(CalculatorMaker *mark))markBlock;
@end

@interface CalculatorFP : NSObject
@property (nonatomic, assign) int result;
- (CalculatorFP *)add:(int(^)(void))block;
- (CalculatorFP *)sub:(int(^)(void))block;
- (CalculatorFP *)clean;
@end

@interface CalculatorReactive : NSObject
@property (nonatomic, assign) int value;
- (void)addObserverValueUpdate:(void(^)(int a))block;
//这个方法返回一个block,调用该block,就能移除block的监听
- (void(^)(void))addWithRemoveControllerObserverValueUpdate:(void(^)(int))block;
@end

@interface CalculatorReactiveFP : CalculatorReactive
- (CalculatorReactiveFP *)addByOther:(CalculatorReactiveFP *)other;
- (CalculatorReactiveFP *)subByOther:(CalculatorReactiveFP *)other;
@end


///////////////////////进入抽象/////////////////
//为了方便阅读,把一些常的block加上别名
typedef void(^CCSubscribeBlock)(id value);
typedef void(^CCBlankBlock)(void);


@interface CocoaReactive : NSObject
//把方法名,由set/observer->send/subscribe
- (void)sendValue:(id)value;
- (CCBlankBlock)subscribeValue:(CCSubscribeBlock)block;
@end

@interface CocoaReactiveFP : CocoaReactive
- (CocoaReactiveFP *)processValue:(id(^)(id v))block;
@end

@interface CocoaReactiveFP (optimize)
- (CocoaReactiveFP *)processValue2:(CocoaReactiveFP *(^)(id v))block;
@end

@class CocoaReactiveFP;
//方便阅读我们将方法processValue2 的参数block加别名
typedef CocoaReactiveFP *(^CCBindBlock)(id value);
@interface CocoaReactiveFP (Lazy)
- (CocoaReactiveFP *)processValueLazy:(CCBindBlock(^)(void))block;
@end

@interface CocoaReactiveFP (Lazy2)
+ (CocoaReactiveFP *)createReactiveFPLazy:(void(^)(CCSubscribeBlock o))block;
@end



/////////////////以下是最终模拟类//////////////////////
@interface CocoaSubscriber : NSObject
+ (instancetype)subscriberWithValueBlock:(CCSubscribeBlock)block;
- (void)sendValue:(id)value;
@end

@class CocoaStream;
typedef CocoaStream *(^CCStreamBindBlock)(id value);
@interface CocoaStream : NSObject
- (__kindof CocoaStream *)bind:(CCStreamBindBlock(^)(void))block;
@end

@interface CocoaSignal : CocoaStream
+ (CocoaSignal *)createSignal:(void(^)(CocoaSubscriber *subscriber))createBlock;
- (CCBlankBlock)subscribeValue:(CCSubscribeBlock)block;
@end
