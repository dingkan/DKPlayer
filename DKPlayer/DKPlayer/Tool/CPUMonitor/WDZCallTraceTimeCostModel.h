//
//  WDZCallTraceTimeModel.h
//  WDZForAppStore
//
//  Created by 丁侃 on 2020/9/9.
//  Copyright © 2020 Wandianzhang. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WDZCallTraceTimeCostModel : NSObject
@property (nonatomic, strong) NSString *className;
@property (nonatomic, strong) NSString *methodName;
@property (nonatomic, assign) BOOL isClassMethod;
@property (nonatomic, assign) NSTimeInterval timeCost;
@property (nonatomic, assign) NSUInteger callDepth;
@property (nonatomic, copy) NSString *path;
@property (nonatomic, assign) BOOL lastCell;
@property (nonatomic, assign) NSUInteger frequency;

@property (nonatomic, strong) NSArray <WDZCallTraceTimeCostModel *>*subCosts;

-(NSString *)des;

@end

NS_ASSUME_NONNULL_END
