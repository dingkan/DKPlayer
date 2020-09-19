//
//  WDZCallDB.m
//  WDZForAppStore
//
//  Created by 丁侃 on 2020/9/9.
//  Copyright © 2020 Wandianzhang. All rights reserved.
//

#import "WDZCallDB.h"

@interface WDZCallDB ()

@property (nonatomic, copy) NSString *clsCallDBPath;
@property (nonatomic, strong) FMDatabaseQueue *dbQueue;

@end

@implementation WDZCallDB

+(instancetype)shareInstance{
    static WDZCallDB *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[WDZCallDB alloc]init];
    });
    return manager;
}

-(instancetype)init{
    if (self = [super init]) {
        _clsCallDBPath = [PATH_OF_DOCUMENT stringByAppendingPathComponent:@"cls.sqlite"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:_clsCallDBPath] == NO) {
            FMDatabase *db = [FMDatabase databaseWithPath:_clsCallDBPath];
            if ([db open]) {
                //方法读取频次表
                /**
                 cid 主键id
                 fid 父ID 暂时不用
                 cls 类名
                 mtd 方法名
                 path 完整路径
                 timecost 方法消耗时长
                 calldepth 层级
                 frequency 调用次数
                 lastcell 是否是最后一个call
                    
                 */
                NSString *createSql = @"create table clscall (cid INTEGER PRIMARY KEY AUTOINCREMENT  NOT NULL, fid integer, cls text, mtd text, path text, timecost double, calldepth integer, frequency integer, lastcall integer)";
                [db executeUpdate:createSql];
                
                //表记录
                /**
                 sid 主键id
                 stackContent 堆栈内容
                 insertDate: 日期
                 */
                NSString *createStackSql = @"create table stack (sid INTEGER PRIMARY KEY AUTOINCREMENT  NOT NULL, stackcontent text,isstuck integer, insertdate double)";
                [db executeUpdate:createStackSql];
            }
        }
        _dbQueue = [FMDatabaseQueue databaseQueueWithPath:_clsCallDBPath];
    }
    return self;
}

#pragma mark  - 卡顿和CPU超标堆栈
-(RACSignal *)increaseWithStackModel:(WDZCallStackModel *)model{
    @weakify(self);
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        if ([model.stackStr containsString:@"+[WDZCallStack callStackWithType:]"] || [model.stackStr containsString:@"-[WDZLagMonitor updateCPUInfo]"]) {
            return nil;
        }
        @strongify(self);
        [self.dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
           
            if ([db open]) {
                [db executeQuery:@"insert into stack (stackcontent, isstuck, insertdate) values (?, ?, ?)",model.stackStr, model.isStuck, [NSDate date]];
                [db close];
                [subscriber sendCompleted];
            }
            
        }];
        
    }];
}

-(RACSignal *)selectStackWithPage:(NSUInteger)page{
    @weakify(self);
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        @strongify(self);
        FMDatabase *db = [FMDatabase databaseWithPath:self.clsCallDBPath];
        if ([db open]) {
            FMResultSet *set = [db executeQuery:@"select * from stack order by sid desc limit ?, 50",@(page * 50)];
            NSUInteger count = 0;
            NSMutableArray *array = [NSMutableArray array];
            while ([set next]) {
                WDZCallStackModel *model = [[WDZCallStackModel alloc]init];
                model.stackStr = [set stringForColumn:@"stackcontent"];
                model.isStuck = [set boolForColumn:@"isstuck"];
                model.dateString = [set doubleForColumn:@"insertdate"];
                [array addObject:model];
                count ++;
            }
            
            if (count > 0) {
                [subscriber sendNext:array];
                [subscriber sendCompleted];
            }else{
                [subscriber sendError:nil];
            }
            [db close];
        }
       
        return nil;
    }];
}

-(void)clearStackData{
    FMDatabase *db = [FMDatabase databaseWithPath:self.clsCallDBPath];
    if ([db open]) {
        [db executeQuery:@"delete from stack"];
        [db close];
    }
}

#pragma mark -clsCall方法调用频次
-(void)addClsCallStackModel:(WDZCallTraceTimeCostModel *)model{
    
    if ([model.methodName isEqualToString:@"clsCallInsertToViewWillAppear"] || [model.methodName isEqualToString:@"clsCallInsertToViewWillDisappear"]) {
        return;
    }
    
    [self.dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
       
        if ([db open]) {
            //添加白名单
            FMResultSet *set = [db executeQuery:@"select cid,frequency from clscall where path = ?", model.path];
            if ([set next]) {
                int frequency = [set intForColumn:@"frequency"] + 1;
                int cid = [set intForColumn:@"cid"];
                [db executeUpdate:@"update clscall set frequency = ? where cid = ?",@(frequency),@(cid)];
            }else{
                [db executeUpdate:@"insert into clscall (cls, mtd, path, timecost, calldepth, frequency, lastcall) values (?, ?, ?, ?, ?, ?, ?)", model.className, model.methodName, model.path, @(model.timeCost), @(model.callDepth), @1, @(model.lastCell)];
            }
            [db close];
        }
        
    }];
}

//分页查询
-(RACSignal *)selectClsCallStackWithPage:(NSUInteger)page{
    @weakify(self);
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        @strongify(self);
        
        FMDatabase *db = [FMDatabase databaseWithPath:self.clsCallDBPath];
        if ([db open]) {
            FMResultSet *set = [db executeQuery:@"select * from clscall where lastcall=? order by frequency desc limit ?, 50", @1, @(page * 50)];
            NSUInteger count = 0;
            NSMutableArray *array = [NSMutableArray array];
            if ([set next]) {
                WDZCallTraceTimeCostModel *model = [self createCallTraceTimeCostModelWithSet:set];
                [array addObject:model];
                count ++;
            }
            
            if (count > 0) {
                [subscriber sendNext:array];
            }else{
                [subscriber sendError:nil];
            }
            
            [db close];
        }
        return nil;
    }];
}

-(void)clearClsCallStackData{
    FMDatabase *db = [FMDatabase databaseWithPath:self.clsCallDBPath];
    if ([db open]) {
        [db executeUpdate:@"delete form clscall"];
        [db close];
    }
}

-(WDZCallTraceTimeCostModel *)createCallTraceTimeCostModelWithSet:(FMResultSet *)set{
    WDZCallTraceTimeCostModel *model = [[WDZCallTraceTimeCostModel alloc]init];

    model.className = [set stringForColumn:@"cls"];
    model.methodName = [set stringForColumn:@"mtd"];
    model.timeCost = [set doubleForColumn:@"timecost"];
    model.callDepth = [set intForColumn:@"calldepth"];
    model.path = [set stringForColumn:@"path"];
    model.lastCell = [set boolForColumn:@"lastcall"];
    model.frequency = [set intForColumn:@"frequency"];
    
    return model;
}

@end
