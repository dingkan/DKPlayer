//
//  SMClsCallViewController.m
//  DecoupleDemo
//
//  Created by DaiMing on 2017/8/10.
//  Copyright © 2017年 Starming. All rights reserved.
//

#import "WDZClsCallViewController.h"
#import "MJRefresh.h"
#import "WDZClsCallCell.h"
#import "Masonry.h"
#import "WDZCallDB.h"
#import "WDZCallTraceTimeCostModel.h"
#import "WDZCallTrace.h"

static NSString *wdzClsCallCellIdentifier = @"wdzClsCallCell";

@interface WDZClsCallViewController ()<UITableViewDataSource,UITableViewDelegate>

@property (nonatomic, strong) NSMutableArray *listData;
@property (nonatomic, strong) UITableView *tbView;
@property (nonatomic) NSUInteger page;
@property (nonatomic, strong) UIButton *closeView;
@property (nonatomic, strong) UIButton *clearAndCloseView;

@end

@implementation WDZClsCallViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.page = 0;
    [self selectItems];
    [self.tbView registerClass:[UITableViewCell class] forCellReuseIdentifier:wdzClsCallCellIdentifier];
    [self.view addSubview:self.tbView];
    [self.tbView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.left.right.equalTo(self.view);
        make.top.equalTo(self.view).offset(20);
    }];
    [self.view addSubview:self.closeView];
    [self.closeView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.view).offset(-10);
        make.top.equalTo(self.view).offset(20);
        make.size.mas_equalTo(CGSizeMake(40, 40));
    }];
    [self.view addSubview:self.clearAndCloseView];
    [self.clearAndCloseView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.closeView.mas_left).offset(-10);
        make.top.equalTo(self.closeView);
        make.size.mas_equalTo(CGSizeMake(40, 40));
    }];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}

- (void)selectItems {
    RACScheduler *scheduler = [RACScheduler schedulerWithPriority:RACSchedulerPriorityHigh];
    @weakify(self);
    [[[[[WDZCallDB shareInstance] selectClsCallStackWithPage:self.page]
    subscribeOn:scheduler]
    deliverOn:[RACScheduler mainThreadScheduler]]
    subscribeNext:^(id x) {
        @strongify(self);
        self.tbView.mj_footer.hidden = NO;
        if (self.listData.count > 0) {
            //加载更多
            [self.listData addObjectsFromArray:x];
        } else {
            //进入时加载
            self.listData = x;
            if (self.listData.count < 50) {
                self.tbView.mj_footer.hidden = YES;
            }
        }
        //刷新
        [self.tbView reloadData];
    } error:^(NSError *error) {
        //处理无数据显示
        [self.tbView.mj_footer endRefreshingWithNoMoreData];
    } completed:^{
        //加载完成后的处理
        [self.tbView.mj_footer endRefreshing];
    }];
    self.page += 1;
}

#pragma mark - UITableView Delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.listData.count;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    WDZCallTraceTimeCostModel *model = self.listData[indexPath.row];
    CGRect frame = [model.path boundingRectWithSize:CGSizeMake([UIScreen mainScreen].bounds.size.width - 20*2, 999) options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingTruncatesLastVisibleLine attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:12]} context:nil];
    return 80 + frame.size.height;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:wdzClsCallCellIdentifier];
    cell.backgroundColor = [UIColor clearColor];
    cell.selected = UITableViewCellSelectionStyleNone;
    cell.contentView.backgroundColor = [UIColor clearColor];
    
    WDZClsCallCell *v = (WDZClsCallCell *)[cell viewWithTag:123422];
    if (!v) {
        v = [[WDZClsCallCell alloc] init];
        v.tag = 123422;
        if (cell) {
            [cell.contentView addSubview:v];
            [v mas_makeConstraints:^(MASConstraintMaker *make) {
                make.right.left.top.bottom.equalTo(cell.contentView);
            }];
        }
    }
    
    WDZCallTraceTimeCostModel *model = self.listData[indexPath.row];
    [v updateWithModel:model];
    
    return cell;
}
- (void)close {
    [self.navigationController popViewControllerAnimated:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Getter
- (NSMutableArray *)listData {
    if (!_listData) {
        _listData = [NSMutableArray array];
    }
    return _listData;
}
- (UITableView *)tbView {
    if (!_tbView) {
        _tbView = [[UITableView alloc] initWithFrame:CGRectZero];
        _tbView.dataSource = self;
        _tbView.delegate = self;
        _tbView.backgroundColor = [UIColor clearColor];
        _tbView.separatorStyle = UITableViewCellSeparatorStyleNone;
        //mj
        _tbView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(selectItems)];
        MJRefreshAutoNormalFooter *footer = (MJRefreshAutoNormalFooter *)_tbView.mj_footer;
        footer.stateLabel.font = [UIFont systemFontOfSize:12];
        footer.stateLabel.textColor = [UIColor lightGrayColor];
        [footer setTitle:@"上拉读取更多" forState:MJRefreshStateIdle];
        [footer setTitle:@"正在读取..." forState:MJRefreshStateRefreshing];
        [footer setTitle:@"已读取完毕" forState:MJRefreshStateNoMoreData];
        
    }
    return _tbView;
}
- (UIButton *)closeView {
    if (!_closeView) {

        _closeView = [UIButton buttonWithType:UIButtonTypeCustom];
        [_closeView setTitle:@"退出" forState:UIControlStateNormal];
        _closeView.titleLabel.font = [UIFont systemFontOfSize:16];
        [_closeView setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
        @weakify(self);
        [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            [[self.closeView rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
                [subscriber sendNext:@"click"];
            }];
            return nil;
        }] subscribeNext:^(id x) {
            @strongify(self);
            [self close];
        }];
    }
    return _closeView;
}
- (UIButton *)clearAndCloseView {
    if (!_clearAndCloseView) {
        _clearAndCloseView = [UIButton buttonWithType:UIButtonTypeCustom];
        [_clearAndCloseView setTitle:@"清理" forState:UIControlStateNormal];
        _clearAndCloseView.titleLabel.font = [UIFont systemFontOfSize:16];
        [_clearAndCloseView setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
        @weakify(self);
        
        [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            [[self.clearAndCloseView rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
                [subscriber sendNext:@"click"];
            }];
            return nil;
        }] subscribeNext:^(id x) {
            @strongify(self);
            [[WDZCallDB shareInstance] clearStackData];
            [self close];
        }];
    }
    return _clearAndCloseView;
}

@end
