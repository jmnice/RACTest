//
//  ViewController.m
//  RACTest
//
//  Created by jimi on 2018/11/20.
//  Copyright © 2018 szy. All rights reserved.
//

#import "ViewController.h"
#import "CalculatorMaker.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self testCalculatorReactiveFP];
    [self testCocoaReactiveFP];
    [self testReactiveFP];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)testCalculatorReactiveFP {
    {
        CalculatorMaker *calculator = [[CalculatorMaker alloc] init];
        [calculator makeCalculator:^(CalculatorMaker *mark) {
            mark.add(2).sub(1).clean().add(3);
        }];
        NSLog(@"~~~~ value %d",calculator.result);
    }
    {
        CalculatorMaker *calculator = [[CalculatorMaker alloc] init];
        [calculator makeCalculator:^(CalculatorMaker *mark) {
            CalculatorMaker *(^tmpAddBlock)(int) = [mark add];
            CalculatorMaker *tmpAddReturn = tmpAddBlock(2);
            
            CalculatorMaker *(^tmpSubBlock)(int) = [tmpAddReturn sub];
            CalculatorMaker *tmpSubReturn = tmpSubBlock(1);
            
            CalculatorMaker *(^tmpCleanBlock)(void) = [tmpSubReturn clean];
            CalculatorMaker *tmpCleanReturn = tmpCleanBlock();
            
            CalculatorMaker *(^tmpAdd2Block)(int) = [tmpCleanReturn add];
            CalculatorMaker *tmpAdd2Return = tmpAdd2Block(3);
        }];
        NSLog(@"~~~~ value %d",calculator.result);
    }
    {
        CalculatorFP *fp = [[CalculatorFP alloc] init];
        [[[[fp add:^int{
            return 2;
        }] sub:^int{
            return 1;
        }] clean] add:^int{
            return 3;
        }];
        
        NSLog(@"~~~~ fp value %d",fp.result);
    }
    {
        CalculatorReactive *a = [[CalculatorReactive alloc] init];
        [a addObserverValueUpdate:^(int v) {
            NSLog(@"a new value is %d",v);
        }];

        void(^removeBlock)(void) = [a addWithRemoveControllerObserverValueUpdate:^(int v) {
            NSLog(@"a with remove new value %d",v);
        }];

        a.value = 10;
        a.value = 5;
        removeBlock();
        a.value = 11;
    }
    {
        CalculatorReactiveFP *a = [[CalculatorReactiveFP alloc] init];
        [a addObserverValueUpdate:^(int v) {
            NSLog(@"a new value is %d",v);
        }];
        CalculatorReactiveFP *b = [[CalculatorReactiveFP alloc] init];
        [b addObserverValueUpdate:^(int v) {
            NSLog(@"b new value is %d",v);
        }];
        CalculatorReactiveFP *c = [a addByOther:b];
        [c addObserverValueUpdate:^(int v) {
            NSLog(@"c new value is %d",v);
        }];
        
        CalculatorReactiveFP *e = [[c addByOther:a] subByOther:b];
        [e addObserverValueUpdate:^(int v) {
            NSLog(@"e new value is %d",v);
        }];
        
        a.value = 1;
        b.value = 3;
        a.value = 5;
        c.value = 11;
        b.value = 2;
    }
}

- (void)testCocoaReactiveFP {
    {
        CocoaReactive *reactive = [[CocoaReactive alloc] init];
        [reactive subscribeValue:^(id v) {
            NSLog(@"reactive new value %@",v);
        }];
        
        [reactive sendValue:@(2)];
    }
    
    {
        CocoaReactiveFP *a = [[CocoaReactiveFP alloc] init];
        
        CocoaReactiveFP *b = [[a processValue:^id(id v) {
            int tmpV = [v intValue];
            return @(tmpV + 3);
        }] processValue:^id(id v) {
            int tmpV = [v intValue];
            return @(tmpV + 5);
        }];
        
        [b subscribeValue:^(id v) {
            NSLog(@"b new value %@",v);
        }];
        
        [a sendValue:@(2)];
    }
    
    {
        CocoaReactiveFP *a = [[CocoaReactiveFP alloc] init];
        CocoaReactiveFP *b = [[CocoaReactiveFP alloc] init];
        
        CocoaReactiveFP *c = [a processValue2:^CocoaReactiveFP *(id v) {
            return b;
        }];
        
        [c subscribeValue:^(id v) {
            NSLog(@"c new value %@",v);
        }];
        
        [a sendValue:@(2)];
        [b sendValue:@(20)];
        
    }
    {
        CocoaReactiveFP *aLazy = [[CocoaReactiveFP alloc] init];
        
        CocoaReactiveFP *cLazy = [aLazy processValueLazy:^CCBindBlock{
            return ^CocoaReactiveFP *(id v){
                CocoaReactiveFP *bLazy = [[CocoaReactiveFP alloc]init];
                //尴尬的我们发现bLazy,无处sendValue.在这sendValue的话,cLazy还未subscribe bLazy.
                return bLazy;
            };
        }];
        
        [cLazy subscribeValue:^(id value) {
            NSLog(@"cLazy new value %@",value);
        }];
        
        [aLazy sendValue:@(2)];
        [aLazy sendValue:@(5)];
    }
    {
        CocoaReactiveFP *aLazy = [[CocoaReactiveFP alloc] init];
        
        CocoaReactiveFP *cLazy = [aLazy processValueLazy:^CCBindBlock{
            return ^CocoaReactiveFP *(id v){
                CocoaReactiveFP *bLazy = [CocoaReactiveFP createReactiveFPLazy:^(CCSubscribeBlock o) {
                    o(@([v intValue] + 5));
                }];
                return bLazy;
            };
        }];
        
        [cLazy subscribeValue:^(id value) {
            NSLog(@"cLazy new value %@",value);
        }];
        
        [aLazy sendValue:@(2)];
        [aLazy sendValue:@(5)];
    }
}

- (void)testReactiveFP {
    CocoaSignal *aSignal = [CocoaSignal createSignal:^(CocoaSubscriber *subscriber) {
        [subscriber sendValue:@(2)];
        [subscriber sendValue:@(5)];
    }];
    
    CocoaSignal *cSignal = [aSignal bind:^CCStreamBindBlock{
        return ^CocoaSignal *(id v){
            CocoaSignal *bSignal = [CocoaSignal createSignal:^(CocoaSubscriber *subscriber) {
                int newValue =  [v intValue] + 5;
                [subscriber sendValue:@(newValue)];
            }];
            return bSignal;
        };
    }];
    
    [cSignal subscribeValue:^(id value) {
        NSLog(@"cSignal new value %@",value);
    }];

}

@end
