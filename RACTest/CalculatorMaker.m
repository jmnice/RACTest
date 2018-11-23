//
//  CalculatorMaker.m
//  RACTest
//
//  Created by jimi on 2018/11/20.
//  Copyright © 2018 szy. All rights reserved.
//

#import "CalculatorMaker.h"

@implementation CalculatorMaker
- (CalculatorMaker *(^)(int value))add {
    return ^CalculatorMaker *(int a) {
        self.result += a;
        return self;
    };
}

- (CalculatorMaker *(^)(int value))sub {
    return ^CalculatorMaker *(int a) {
        self.result -= a;
        return self;
    };
}

- (CalculatorMaker *(^)(void))clean {
    return ^CalculatorMaker *(void) {
        self.result = 0;
        return self;
    };
}

- (void)makeCalculator:(void(^)(CalculatorMaker *mark))markBlock {
    markBlock(self);
}
@end

@implementation CalculatorFP
- (CalculatorFP *)add:(int(^)(void))block {
    int value = block();
    self.result += value;
    return self;
}

- (CalculatorFP *)sub:(int(^)(void))block {
    int value = block();
    self.result -= value;
    return self;
}

- (CalculatorFP *)clean {
    self.result = 0;
    return self;
}
@end


@interface CalculatorReactive ()
@property (nonatomic, strong) NSMutableArray<void (^)(int)> *recordObserverUpdateBlockArray;
@end

@implementation CalculatorReactive
- (id)init {
    if (self = [super init]) {
        self.recordObserverUpdateBlockArray = [NSMutableArray array];
    }
    return self;
}

- (void)addObserverValueUpdate:(void(^)(int))block {
    [_recordObserverUpdateBlockArray addObject:block];
}

- (void(^)(void))addWithRemoveControllerObserverValueUpdate:(void(^)(int))block {
    void(^removeBlock)(void) = ^{
        [_recordObserverUpdateBlockArray removeObject:block];
    };
    
    [_recordObserverUpdateBlockArray addObject:block];
    return removeBlock;
}

- (void)setValue:(int)value {
    if (_value != value) {
        _value = value;
        [_recordObserverUpdateBlockArray enumerateObjectsUsingBlock:^(void (^ _Nonnull obj)(int), NSUInteger idx, BOOL * _Nonnull stop) {
            obj(value);
        }];
    }
}
@end

@implementation CalculatorReactiveFP
- (void)commondDoBlock:(void(^)(void))block other:(CalculatorReactiveFP *)other {
    void(^tmpObserverValueUpdateBlock)(int) = ^(int a) {
        block();
    };
    
    [self.recordObserverUpdateBlockArray addObject:tmpObserverValueUpdateBlock];
    [other.recordObserverUpdateBlockArray addObject:tmpObserverValueUpdateBlock];
}

- (CalculatorReactiveFP *)addByOther:(CalculatorReactiveFP *)other {
    CalculatorReactiveFP *result = [[CalculatorReactiveFP alloc] init];
    
    [self commondDoBlock:^void{
        int newValue = self.value + other.value;
        result.value = newValue;
    } other:other];
    
    return result;
}

- (CalculatorReactiveFP *)subByOther:(CalculatorReactiveFP *)other {
    CalculatorReactiveFP *result = [[CalculatorReactiveFP alloc] init];
    
    [self commondDoBlock:^void{
        int newValue = self.value - other.value;
        result.value = newValue;
    } other:other];
    
    return result;
}
@end

@interface CocoaReactive ()
@property (nonatomic, strong) NSMutableArray<CCSubscribeBlock> *recordObserverUpdateBlockArray;
@end

@implementation CocoaReactive
- (id)init {
    if (self = [super init]) {
        self.recordObserverUpdateBlockArray = [NSMutableArray array];
    }
    return self;
}

- (void)sendValue:(id)value {
    [_recordObserverUpdateBlockArray enumerateObjectsUsingBlock:^(void (^ _Nonnull obj)(id), NSUInteger idx, BOOL * _Nonnull stop) {
        obj(value);
    }];
}

- (CCBlankBlock)subscribeValue:(CCSubscribeBlock)block {
    CCBlankBlock removeBlock = ^{
        [_recordObserverUpdateBlockArray removeObject:block];
    };
    
    [_recordObserverUpdateBlockArray addObject:block];
    return removeBlock;
}
@end

@interface CocoaReactiveFP ()
@property (nonatomic, copy) void (^createBlock)(CCSubscribeBlock o);
@end

@implementation CocoaReactiveFP
- (CocoaReactiveFP *)processValue:(id(^)(id))block {
    CocoaReactiveFP *result = [[CocoaReactiveFP alloc] init];
    void(^tmpSubscribeBlock)(id) = ^(id a) {
        id newValue = block(a);
        [result sendValue:newValue];
    };
    [self subscribeValue:tmpSubscribeBlock];
    return result;
}
@end

@implementation CocoaReactiveFP (optimize)
- (CocoaReactiveFP *)processValue2:(CocoaReactiveFP *(^)(id v))block {
    CocoaReactiveFP *result = [[CocoaReactiveFP alloc] init];
    void(^tmpSubscribeBlock)(id) = ^(id a) {
        //这里返回了一个管道,我们订阅这个管道,当它有值过来,我们就传给result
        CocoaReactiveFP *reactive = block(a);
        void(^tmpSubscribeReactiveBlock)(id) = ^(id a) {
            [result sendValue:a];
        };
        [reactive subscribeValue:tmpSubscribeReactiveBlock];
    };
    [self subscribeValue:tmpSubscribeBlock];
    return result;
}
@end

@implementation CocoaReactiveFP (Lazy)
- (CocoaReactiveFP *)processValueLazy:(CCBindBlock(^)(void))block {
    CocoaReactiveFP *result = [[CocoaReactiveFP alloc] init];
    void(^tmpSubscribeBlock)(id) = ^(id a) {
        //block将在有subscribe的时候才调用
        CCBindBlock bindBlock = block();
        CocoaReactiveFP *bindReactive = bindBlock(a);
        void(^tmpBindReactiveSubscribeBlock)(id) = ^(id a) {
            [result sendValue:a];
        };
        [bindReactive subscribeValue:tmpBindReactiveSubscribeBlock];
    };
    [self subscribeValue:tmpSubscribeBlock];
    return result;
}
@end



@implementation CocoaReactiveFP (Lazy2)
+ (CocoaReactiveFP *)createReactiveFPLazy:(void(^)(CCSubscribeBlock o))block {
    CocoaReactiveFP *lazy = [[CocoaReactiveFP alloc] init];
    lazy.createBlock = block;
    return lazy;
}

- (CCBlankBlock)subscribeValue:(CCSubscribeBlock)block {
    CCBlankBlock result = [super subscribeValue:block];
    //当有人subscribe的时候我们就调用_createBlock通知外界
    if (_createBlock) {
        _createBlock(block);
    }
    return result;
}
@end


////////////////以下是最终模拟类//////////////////////
@interface CocoaSubscriber ()
@property (nonatomic, copy) CCSubscribeBlock valueBlock;
@property (nonatomic, readonly) CCBlankBlock dispose;
@end

@implementation CocoaSubscriber
+ (instancetype)subscriberWithValueBlock:(CCSubscribeBlock)block {
    CocoaSubscriber *result  = [[CocoaSubscriber alloc] init];
    result.valueBlock = block;
    return result;
}

- (id)init {
    if (self = [super init]) {
        __weak CocoaSubscriber *wself = self;
        _dispose = ^{
            __weak CCSubscribeBlock wblock = wself.valueBlock;
            if (wblock) {
                wblock = NULL;
            }
        };
    }
    return self;
}

- (void)sendValue:(id)value {
    if (_valueBlock) {
        _valueBlock(value);
    }
}
@end

@implementation CocoaStream
- (__kindof CocoaStream *)bind:(CCStreamBindBlock(^)(void))block {
    NSString *reason = [NSString stringWithFormat:@"%@ must be overridden by subclasses", NSStringFromSelector(_cmd)];
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:reason userInfo:nil];
}
@end

@interface CocoaSignal ()
@property (nonatomic, copy) void(^createBlock)(CocoaSubscriber *o);
@end

@implementation CocoaSignal
+ (CocoaSignal *)createSignal:(void(^)(CocoaSubscriber *subscriber))createBlock; {
    CocoaSignal *signal = [[CocoaSignal alloc] init];
    signal.createBlock = createBlock;
    return signal;
}

- (CCBlankBlock)subscribeValue:(CCSubscribeBlock)block {
    CocoaSubscriber *subscriber = [CocoaSubscriber subscriberWithValueBlock:block];
    if (_createBlock) {
        _createBlock(subscriber);
    }
    return subscriber.dispose;
}

- (CocoaSignal *)bind:(CCStreamBindBlock(^)(void))block {
    return [CocoaSignal createSignal:^(CocoaSubscriber *subscriber) {
        CCStreamBindBlock bindBlock = block();
        void(^tmpSubscribeBlock)(id) = ^(id a) {
            CocoaSignal *bindReactive = (CocoaSignal *)bindBlock(a);
            void(^tmpBindReactiveSubscribeBlock)(id) = ^(id a) {
                [subscriber sendValue:a];
            };
            [bindReactive subscribeValue:tmpBindReactiveSubscribeBlock];
        };
        [self subscribeValue:tmpSubscribeBlock];
    }];
}
@end
