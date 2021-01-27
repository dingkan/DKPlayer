//
//  ff_player_Frame.h
//  DKPlayer
//
//  Created by 丁侃 on 2021/1/27.
//  Copyright © 2021 丁侃. All rights reserved.
//  解码后数据存储

#ifndef ff_player_Frame_h
#define ff_player_Frame_h

#include <stdio.h>
#include "avformat.h"
#include "ff_mutex.h"
#include "ff_player_PacketQueue.h"

#define VIDEO_PICTURE_QUEUE_SIZE_MIN        (3)
#define VIDEO_PICTURE_QUEUE_SIZE_MAX        (16)
#define VIDEO_PICTURE_QUEUE_SIZE_DEFAULT    (VIDEO_PICTURE_QUEUE_SIZE_MIN)
#define SUBPICTURE_QUEUE_SIZE 16
#define SAMPLE_QUEUE_SIZE 9
#define FRAME_QUEUE_SIZE FFMAX(SAMPLE_QUEUE_SIZE, FFMAX(VIDEO_PICTURE_QUEUE_SIZE_MAX, SUBPICTURE_QUEUE_SIZE))

//Frame的设计试图用一个结构体融合3种数据:视频、音频、字幕
typedef struct Frame{
    AVFrame         *frame;//音视频解码数据
    AVSubtitle      sub;//解码的字幕数据
    int             serial;//序列号
    double          pts;//presentation
    double          duration;
    int64_t         pos;
    
    //SDL_VoutOverlay  *bmp;
    
    int             allocated;
    int             width;//width & height 对AVSubtitle的补充
    int             height;
    int             format;
    AVRational      sar;
    int             uploaded;
} Frame;

/**
 帧队列
 
 数据结构设计
 1.高效率的读写模型(不同于PacketQueue，每次访问都需要对整个队列加锁，锁范围很大)
 2.高效的内存模型（节点内存以数组形式预分配，无需动态分配）
 3.环形缓冲区设计，可以同时访问上一读节点
 
 */
typedef struct FrameQueue{
    Frame           queue[FRAME_QUEUE_SIZE];//队列元素，用顺序队列
    int             rindex;//读指针
    int             windex;//写指针
    int             size;//当前存储的节点个数（当前已写入的节点个数）
    int             max_size;//最大允许存储的节点个数
    int             keep_last;//是否在环形缓冲区的读写过程中保留最后一个读节点不被覆盖
    int             rindex_shown;//当前节点是否已显示
    SDL_mutex       *mutex;
    SDL_cond        *cond;
    PacketQueue     *pktq;//关联的PacketQueue;
}FrameQueue;


#pragma 队列操作相关
static int frame_queue_init(FrameQueue *f, PacketQueue *pktq, int max_size, int keep_last);
static void frame_queue_signle(FrameQueue *f);
static void frame_queue_destory(FrameQueue *f);
static void frame_queue_unref_item(Frame *vp);

static Frame *frame_queue_peek_writable(FrameQueue *f);
static void frame_queue_push(FrameQueue *f);

static Frame *frame_queue_peek_readable(FrameQueue *f);
static void frame_queue_next(FrameQueue *f);

static Frame *frame_queue_peek(FrameQueue *f);
static Frame *frame_queue_peek_next(FrameQueue *f);
static Frame *frame_queue_peek_last(FrameQueue *f);
static int frame_queue_nb_remaining(FrameQueue *f);
#endif /* ff_player_Frame_h */
