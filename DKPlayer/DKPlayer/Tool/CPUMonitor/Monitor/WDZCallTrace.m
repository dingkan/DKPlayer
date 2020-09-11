//
//  WDZCallTrace.m
//  WDZForAppStore
//
//  Created by 丁侃 on 2020/9/10.
//  Copyright © 2020 Wandianzhang. All rights reserved.
//

#import "WDZCallTrace.h"
#import "WDZCallTraceCore.h"
#import "WDZCallLib.h"
#import "WDZCallTraceTimeCostModel.h"
#import "WDZCallDB.h"

@implementation WDZCallTrace

+(void)start{
    wdzCallTraceStart();
}

+(void)startWithMaxDepth:(int)depth{
    wdzCallConfigMaxDepth(depth);
    [WDZCallTrace start];
}

+(void)startWithMinCost:(double)ms{
    wdzCallConfigMinTime(ms * 1000);
    [WDZCallTrace start];
}

+(void)startWithMaxDepth:(int)depth minCost:(double)ms{
    wdzCallConfigMinTime(ms * 1000);
    wdzCallConfigMaxDepth(depth);
    [WDZCallTrace start];
}

+(void)stop{
    wdzCallTraceStop();
}

+(void)save{
    NSMutableString *mStr = [NSMutableString string];
    NSArray <WDZCallTraceTimeCostModel *>*records = [self loadRecords];
    for (WDZCallTraceTimeCostModel *model in records) {
        model.path = [NSString stringWithFormat:@"[%@ %@]",model.className, model.methodName];
        [self appendRecord:model mstr:mStr];
    }
}

+(void)stopSaveAndClean{
    [WDZCallTrace stop];
    [WDZCallTrace save];
    wdzClearCallRecords();
}

+(void)appendRecord:(WDZCallTraceTimeCostModel *)record mstr:(NSMutableString *)mstr{
    if (record.subCosts.count < 1) {
        record.lastCell = YES;
        [[WDZCallDB shareInstance] addClsCallStackModel:record];
    }else{
        for (WDZCallTraceTimeCostModel *model in record.subCosts) {
            if ([model.className isEqualToString:@"WDZCallTrace"]) {
                break;
            }
            model.path = [NSString stringWithFormat:@"%@ -[%@ %@]",model.path, model.className, model.methodName];
            [self appendRecord:model mstr:mstr];
        }
    }
}

+(NSArray *)loadRecords{
    NSMutableArray <WDZCallTraceTimeCostModel *>*array = [NSMutableArray array];
    int num = 0;
    wdzCallRecord *records = wdzGetCallRecords(&num);
    for (int i = 0; i < num; i ++) {
        wdzCallRecord *re = &records[i];
        WDZCallTraceTimeCostModel *model = [[WDZCallTraceTimeCostModel alloc]init];
        model.className = NSStringFromClass(re->cls);
        model.methodName = NSStringFromSelector(re->sel);
        model.isClassMethod = class_isMetaClass(re->cls);
        model.timeCost = (double)re->time / 1000000.0;
        model.callDepth = re->depth;
        [array addObject:model];
    }
    NSUInteger count = array.count;
    for (int i = 0; i < count; i ++) {
        WDZCallTraceTimeCostModel *model = array[i];
        if (model.callDepth > 0) {
            [array removeObject:model];
            //下一个
            for (int j = i; j < count - 1; j ++) {
                //网子节点添加
                if (array[j].callDepth + 1 == model.callDepth) {
                    NSMutableArray *subArray = array[j].subCosts;
                    if (!subArray) {
                        subArray = [NSMutableArray array];
                        array[j].subCosts = subArray;
                    }
                    [subArray insertObject:model atIndex:0];
                }
            }
            i --;
            count --;
        }
    }
    
    return array;
}

@end
