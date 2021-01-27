//
//  ff_player_Frame.c
//  DKPlayer
//
//  Created by 丁侃 on 2021/1/27.
//  Copyright © 2021 丁侃. All rights reserved.
//

#include "ff_player_Frame.h"
/**
 初始化解码数据队列
 指定最大存储大小，是否要保留最后一个读节点
 开辟内存空间，初始化锁、条件变量, 以及队列中的每一个Frame
 */
static int frame_queue_init(FrameQueue *f, PacketQueue *pktq, int max_size, int keep_last)
{
    int i;
    memset(f, 0, sizeof(FrameQueue));
    
    if (!(f->mutex = SDL_CreateMutex())) {
        av_log(NULL, AV_LOG_FATAL, "SDL_CreateMutex() \n");
        return AVERROR(ENOMEM);
    }
    
    if (!(f->cond = SDL_CreateCond())) {
        av_log(NULL, AV_LOG_FATAL, "SDL_CreateCond() \n");
        return AVERROR(ENOMEM);
    }
    
    f->pktq = pktq;
    f->max_size = max_size;
    f->keep_last = keep_last;
    
    for (i = 0; i < f->max_size; i ++) {
        if (!(f->queue[i].frame = av_frame_alloc())) {
            return AVERROR(ENOMEM);
        }
    }
    return 0;
}

//销毁函数
static void frame_queue_destory(FrameQueue *f)
{
    int i;
    for (i = 0; i < f->max_size; i ++) {
        Frame *vp = &f->queue[i];
        frame_queue_unref_item(vp);
        //此函数与初始化中的av_frame_alloc对应，用于释放AVFrame
        av_frame_free(&vp->frame);
//        free_picture(&vp->frame);
    }
    SDL_DestoryMutex(f->mutex);
    SDL_DestoryCond(f->cond);
}

//释放关联内存，而为结构体自身的内存
/**
 AVFrame内存有许多的AVBufferRef类型字段，而AVBufferRef只是AVBuffer的引用，AVBuffer通过引用计数自动管理内存（垃圾回收机制）。因此AVFrame在不需要时，通过av_frame_unref()减少引用计数
 */
static void frame_queue_unref_item(Frame *vp)
{
    av_frame_unref(vp->frame);//frame引用计数-1
//    SDL_VoutUnrefYUVOverlay(vp->bmp);// sub关联的内存释放
    avsubtitle_free(&vp->sub);
}

static void frame_queue_signle(FrameQueue *f)
{
    SDL_LockMutex(f->mutex);
    SDL_CondSignle(f->cond);
    SDL_UnlockMutex(f->mutex);
}


#pragma 写操作
/**
写操作分2步骤
    1.frame_queue_peek_writable获取一个可写节点
    2.frame_queue_push 告知FrameQueue存入该节点
 */


/**
 1.在加锁的情况下，等待直到队列有空余空间可写（f->size >= f->max_size）
 2.如果有退出请求（f->pktq->abort_request）则返回NULL
 3.返回 windex位置的元素（当前写位置）
 
 注意：
    1.加锁并不是整个函数，是为了减小锁范围，提高效率
    2.之所以可以在无锁的情况下安全访问quque字段，是因为单独单写场景，queue是一个预先分配好的数组，queue本身不发生变化可以安全访问，queue内的元素，读和写不存在重叠，即windex和rindex不会重叠
 
读和写不存在重叠
    queue数组被当做一个环形缓冲区使用，那么的确存在underrun和overrun的情况，读过快，或写过快的情况，如果不加以控制，就会呈现缓冲区覆盖
    FrameQueue精明之处在于，先通过size判断当前缓冲区内空间是否够写，或者够读，（f->size >= f->max_size）说明队列中的节点以及写满了（overrun），此时如果再写肯定会覆写末读数据，那么就需要等待了。当无需等待时，windex指向的内存一定是以及读过的
 
 */
static Frame *frame_queue_peek_writable(FrameQueue *f)
{
    SDL_LockMutex(f->mutex);
    
    while (f->size >= f->max_size && !f->pktq->abort_request) {
        SDL_CondWait(f->cond, f->mutex);
    }
    
    SDL_UnlockMutex(f->mutex);
    
    if (f->pktq->abort_request) {
        return NULL;
    }
    
    return &f->queue[f->windex];
}

/**
 push当前windex节点
 1.windex+1；如果超出max_size,则回环为0
 2.加锁的情况下更新size大小
 
 因为FrameQueue是基于固定长度的数组实现的队列，与链表不同，其节点在初始化的时候已经在队列中了，push所要做的只是通过某个标记记录该节点是否是写入未读的。这里的做法是对windex + 1; 将写指针移动到下一个元素，凡是windex之前的节点，都代表写过的
 */
static void frame_queue_push(FrameQueue *f)
{
    if (++f->windex == f->max_size) {
        f->windex = 0;
    }
    
    SDL_LockMutex(f->mutex);
    
    f->size ++;
    SDL_CondSignle(f->cond);
    
    SDL_UnlockMutex(f->mutex);
}

#pragma 读操作
/**
 读操作分2步
 1.frame_queue_peek_readable 获取可读的节点
 2.frame_queue_next 标记节点已读
 */


/**
 1.加锁情况下，判断是否有可读节点 （f->size - f->rindex_shown > 0）
 2.如果有退出请求，则返回NULL （f->pktq->abort_request）
 3.读取当前可读节点 （(f->rindex + f->rindex_shown) & f->max_size）
 
 如果是读过快情况，则回等待
 rindex_shown: rindex指向的节点是否被读过，如果被读过，为1。 反之，为0
 */
static Frame *frame_queue_peek_readable(FrameQueue *f)
{
    SDL_LockMutex(f->mutex);
    
    while (f->size - f->rindex_shown <= 0 && !f->pktq->abort_request) {
        SDL_CondWait(f->cond, f->mutex);
    }

    SDL_UnlockMutex(f->mutex);
    
    if (f->pktq->abort_request) {
        return NULL;
    }
    
    return  &f->queue[(f->rindex + f->rindex_shown) & f->max_size];
}


//用于在读完一个节点后调用，来标记一个节点已经被读过
/**
 标记已读
 1.rindex+1 ,如果超出max_size, 则回环为0
 2.加锁情况下 更新size
 
 对于已读的节点需要通过frame_queue_unref_item来释放关联内存。
 在执行rindex操作前，需要先判断rindex_shown的值
 
 初始化状态，还没开始读，rindex 、rindex_shown 均为0
 第一次读， 调用next, 满足条件(f->keep_last && !f->rindex_shown)。所以rindex 仍为 0; 而rindex_shown为1  ----->  此时节点0时已读节点，也是要peek的last节点，将要读的节点是节点1（rindex+rindex_shown）
 
 第二次读，peek了节点后，调用next, 不满足条件(f->keep_last && !f->rindex_shown)。 此时rindex = 1。 而rindex_shown=2。 此时节点1是last节点。节点2是将要读点的节点（rindex+rindex_shown）
 
 继续往后分析，会一直重复第二次读的情况，始终是rindex指向了last, 而rindex_shown一直为1。rindex+rindex_shown刚好是将要读的节点
 */
static void frame_queue_next(FrameQueue *f)
{
    if (f->keep_last && !f->rindex_shown) {//如果支持keep_last,并且rindex_shown为0， 则rindex_shown = 1
        f->rindex_shown = 1;
        return;
    }
    
    //否则，移动rindex, 并减小size
    frame_queue_unref_item(&f->queue[f->rindex]);//释放内存
    if (++f->rindex == f->max_size) {
        f->rindex = 0;//回环
    }
    
    //更新size
    SDL_LockMutex(f->mutex);
    f->size --;
    SDL_CondSignle(f->cond);
    SDL_UnlockMutex(f->mutex);
}


#pragma 辅助函数
//读当前节点。 与frame_queue_peek_readable等效，但是没有检查是否有可读节点
static Frame *frame_queue_peek(FrameQueue *f)
{
    return &f->queue[(f->rindex + f->rindex_shown) % f->max_size];
}


//读取下一个节点
static Frame *frame_queue_peek_next(FrameQueue *f)
{
    return &f->queue[(f->rindex + f->rindex_shown + 1) % f->max_size];
}

//读取上一个节点
static Frame *frame_queue_peek_last(FrameQueue *f)
{
    return &f->queue[f->rindex];
}

//返回队列中未显示的帧数
static int frame_queue_nb_remaining(FrameQueue *f)
{
    return f->size - f->rindex_shown;
}
