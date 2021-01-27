//
//  ff_player_PacketQueue.h
//  DKPlayer
//
//  Created by 丁侃 on 2021/1/27.
//  Copyright © 2021 丁侃. All rights reserved.
//  解封装后数据存储

#ifndef ff_player_PacketQueue_h
#define ff_player_PacketQueue_h

#include <stdio.h>
#include "avformat.h"
#include "ff_mutex.h"

/**
 
 节点的内存是完全由队列维护，put的时候malloc, get的时候free
 AVPacket分两块
    一部分是AVPakcet结构体的内存，和节点共存亡
    一部分是AVPacket指向的内存，这部分通过av_packet_unref函数释放
 
 缓冲区的设计
 PacketQueue
 
 1.数据结构
    PacketQueue采用两条链表
        一个是保存数据链表，从first_pkt到last_pkt,插入数据到last_pkt后面，取数据从first_pkt拿
        一个是复用节点链表，保存没有数据的节点，复用链表头部是recycle_pkt,取完数据后的空节点，放到recycle_pkt的头部，然后这个空节点成为新的recycle_pkt。存数据时也从recycle_pkt复用一个节点
 2.引入serial概念，区分前后数据是否连续
 3.设计了2个特殊的packet ---- flush_pkt和nullpkt,用于更细致的控制（类似于多线程编程中的事件模型，往队列中放入flush事件，放入null事件）
 */

typedef struct MyAVPacketList{
    AVPacket                    pkt;//解封装后数据
    struct MyAVPacketList       *next;//下一个节点
    int                         serial;//序列号
}MyAVPacketList;

/**
 
 */
typedef struct PacketQueue{
    MyAVPacketList              *first_pkt, *last_kpt;//保存数据链表
    int                         nb_packets;//队列中共有多少个节点
    int                         size;//队列所有节点字节总数，用于计算cache大小
    int64_t                     duration;//队列所有节点的合计时长
    int                         abort_request;//是否要终止队列操作，用于安全快速退出播放
    int                         serial;//序列号
    SDL_mutex                   *mutex;//互斥锁
    SDL_cond                    *cond;//条件变量，用于读写线程相互通知
    MyAVPacketList              *recycle_pkt;//复用节点链表
    int                         recycle_count;
    int                         alloc_count;
}PacketQueue;

#pragma 队列操作相关
/**
 初始化操作
 */
static int packet_queue_init(PacketQueue *q);
static void packet_queue_flush(PacketQueue *q);
static void packet_queue_destory(PacketQueue *q);
static void packet_queue_start(PacketQueue *q);
static void packet_queue_abort(PacketQueue *q);

#pragma 写操作
static int packet_queue_put(PacketQueue *q, AVPacket *pkt);
static int packet_queue_put_nullpakcet(PacketQueue *q, int stream_index);
static int packet_queue_put_private(PacketQueue *q, AVPacket *pkt);

#pragma 读操作
static int packet_queue_get(PacketQueue *q, AVPacket *pkt, int block, int *serial);
#endif /* ff_player_PacketQueue_h */
