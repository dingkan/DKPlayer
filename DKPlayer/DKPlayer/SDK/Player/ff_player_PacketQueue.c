//
//  ff_player_PacketQueue.c
//  DKPlayer
//
//  Created by 丁侃 on 2021/1/27.
//  Copyright © 2021 丁侃. All rights reserved.
//

#include "ff_player_PacketQueue.h"
#define MIN_PKT_DURATION 15

static AVPacket flush_pkt;

static int packet_queue_init(PacketQueue *q)
{
    /**
     void *memset(void *s,int c,size_t n)
     将s所指向的某一块内存中的每个字节的内容全部设置为ch指定的ASCII值， 块的大小由第三个参数指定，这个函数通常为新申请的内存做初始化工作， 其返回值为指向S的指针
     将已开辟内存空间 s 的首 n 个字节的值设为值 c。
     */
    memset(q, 0, sizeof(PacketQueue));
    q->mutex = SDL_CreateMutex();
    if (!q->mutex) {
        av_log(NULL, AV_LOG_FATAL, "SDL_CreateMutex():\n");
        return AVERROR(ENOMEM);
    }
    
    q->cond = SDL_CreateCond();
    if (!q->cond) {
        av_log(NULL, AV_LOG_FATAL, "SDL_CreateCond():\n");
        return AVERROR(ENOMEM);
    }
    
    q->abort_request = 1;
    return 0;
}

//将队列中所有节点清除，比如用于销毁队列，seek操作等
static void packet_queue_flush(PacketQueue *q)
{
    MyAVPacketList *pkt, *pkt1;
    SDL_LockMutex(q->mutex);
    
    for (pkt = q->first_pkt; pkt; pkt = pkt1) {
        pkt1 = pkt->next;
        //对AVPacket缓冲区的引用计数-1,释放内存空间
        av_packet_unref(&pkt->pkt);
        av_free(&pkt);
    }
    
    q->last_kpt = NULL;
    q->first_pkt = NULL;
    q->nb_packets = 0;
    q->size = 0;
    q->duration = 0;
    SDL_UnlockMutex(q->mutex);
}

/**
 packet_queue_flush
 释放复用节点链表中的数据、销毁mutex和cond
 */
static void packet_queue_destory(PacketQueue *q)
{
    packet_queue_flush(q);
    
    SDL_LockMutex(q->mutex);
    
    while (q->recycle_pkt) {
        MyAVPacketList *pkt = q->recycle_pkt;
        if (pkt) {
            q->recycle_pkt = pkt->next;
            av_free(&pkt);
        }
    }
    
    SDL_UnlockMutex(q->mutex);
    
    SDL_DestoryMutex(q->mutex);
    SDL_DestoryCond(q->cond);
}


//启用队列
static void packet_queue_start(PacketQueue *q)
{
    SDL_LockMutex(q->mutex);
    
    q->abort_request = 0;
    //特殊AVPacket,用来分界标记非连续的2段数据
    packet_queue_put_private(q, &flush_pkt);
    
    SDL_UnlockMutex(q->mutex);
}

//中止队列
static void packet_queue_abort(PacketQueue *q)
{
    SDL_LockMutex(q->mutex);
    
    q->abort_request = 1;
    //确保当前等待该条件的线程能被激活并继续执行退出流程
    SDL_CondSignle(q->cond);
    SDL_UnlockMutex(q->mutex);
}

#pragma 写操作
static int packet_queue_put(PacketQueue *q, AVPacket *pkt)
{
    int ret;
    SDL_LockMutex(q->mutex);
    
    ret = packet_queue_put_private(q, pkt);
    
    SDL_UnlockMutex(q->mutex);
    
    if (pkt != &flush_pkt && ret < 0) {
        //放入失败
        av_packet_unref(pkt);
    }
    return  ret;
}

//放入空包，意味着流的结束，一般在视频读取完成的时候放入空包
static int packet_queue_put_nullpakcet(PacketQueue *q, int stream_index)
{
    //构建一个AVPacket
    AVPacket pkt1, *pkt = &pkt1;
    av_init_packet(pkt);
    pkt->data = NULL;
    pkt->size = 0;
    pkt->stream_index = stream_index;
    return packet_queue_put(q, pkt);
}

/**
 主要做了3件事
 1.计算serial, serial标记了这个节点内的数据是何时的，一般情况下新增节点与上一个节点的serial是一样的，但当队列中加入了一个flush_pkt后，后续节点的serial会比之前的大1
 2.队列操作，经典的队列实现方式，
 3.队列属性操作
 */
static int packet_queue_put_private(PacketQueue *q, AVPacket *pkt)
{
    MyAVPacketList *pkt1;
    
    if (q->abort_request) {//如果终止，
        return -1;
    }
    
#ifdef FFP_MERGE
    pkt1 = av_malloc(sizeof(MyAVPacketList));
#else
    pkt1 = q->recycle_pkt;
    if (pkt1) {
        q->recycle_pkt = pkt1->next;
        q->recycle_count ++;
    }else{
        q->alloc_count ++;
        pkt1 = av_malloc(sizeof(MyAVPacketList));
    }
#ifdef FFP_SHOW_PKT_RECYCLE
    int total_count = q->recycle_count + q->alloc_count
    if (!(total_count % 50)) {
        av_log(ffp, AV_LOG_DEBUG, "pkt-recycle \t%d + \t%d = \t%d\n", q->recycle_count, q->alloc_count, total_count);
    }
#endif
#endif
    
    if (!pkt1) {//内存不足，则失败
        return -1;
    }
    
    pkt1->pkt = *pkt;//拷贝AVPakcet(浅拷贝， AVPakcet.data等内存并没有拷贝)
    pkt1->next = NULL;
    if (pkt == &flush_pkt) {//如果放入的是flush_pkt,则需要增加队列的序列号，以表示不连续的两段数据
        q->serial ++;
    }
    
    pkt1->serial = q->serial;//用队列的序列号标记节点
    
    //队列操作
    if (!q->last_kpt) {//空队列
        q->first_pkt = pkt1;
    }else{
        q->last_kpt->next = pkt1;
    }
    q->last_kpt = pkt1;
    
    //队列属性操作，
    q->nb_packets ++;
    q->size += pkt1->pkt.size + sizeof(*pkt1);
    q->duration += FFMAX(pkt1->pkt.duration, MIN_PKT_DURATION);
    
    SDL_CondSignle(q->cond);
    return 0;
}


#pragma 读操作
/**
 读取队列中的一个节点
 block: 调用者是否需要在没节点可取的情况下阻塞等待
 pkt: 输出参数
 serial:输出参数
 */
static int packet_queue_get(PacketQueue *q, AVPacket *pkt, int block, int *serial)
{
    MyAVPacketList *pkt1;
    int ret;
    
    SDL_LockMutex(q->mutex);
    
    for (; ; ) {
        if (q->abort_request) {//终止
            ret = -1;
            break;
        }
        
        pkt1 = q->first_pkt;//从队列头部开始取数据
        if (pkt1) {//有数据
            q->first_pkt = pkt1->next;//获取第二个节点
            if (!q->first_pkt) {
                q->last_kpt = NULL;
            }
            q->nb_packets--;//更新队列节点数
            q->size -= pkt1->pkt.size + sizeof(*pkt1);//更新cache大小
            q->duration -= FFMAX(pkt1->pkt.duration, MIN_PKT_DURATION);//更新总时长
            *pkt = pkt1->pkt;//返回AVpacket, 这里发生一次AVpacket结构体拷贝，AVPacket的data只拷贝了指针
            if (serial) {
                *serial = pkt1->serial;
            }
#ifdef FFP_MERGE
            av_free(pkt1);//释放节点
#else
            //更新复用节点
            pkt1->next = q->recycle_pkt;
            q->recycle_pkt = pkt1;
#endif
            ret = 1;
            break;
        }else if (!block){//没有数据，并且非阻塞调用
            ret = 0;
            break;
        }else{//没有数据，且阻塞调用
            SDL_CondWait(q->cond, q->mutex);
        }
    }
    
    SDL_UnlockMutex(q->mutex);
    return  ret;
}

