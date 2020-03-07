#include "sync.h"
#include "list.h"
#include "global.h"
#include "interrupt.h"

// 初始化信号量
void sema_init(struct semaphore* psema, uint8_t value) {
	psema->value = value; // 为信号量赋初值
	list_init(&psema->waiters); // 初始化信号量的等待队列
}

// 初始化锁 plock
void lock_init(struct lock* plock) {
	plock->holder = NULL;
	plock->holder_repeat_nr = 0;
	sema_init(&plock->semaphore, 1); // 信号量初值为1
}

// 信号量 down 操作
void sema_down(struct semaphore* psema) {
	// 关闭中断保证原子操作
	enum intr_status old_status = intr_disable();
	while(psema->value == 0) {
		// 表示已经被别人持有，当前线程把自己加入该锁的等待队列，然后阻塞自己
		list_append(&psema->waiters, &running_thread()->general_tag);
		thread_block(TASK_BLOCKED);
	}
	// value不为0，则可以获得锁
	psema->value--;
	intr_set_status(old_status);
}
	
// 信号量的 up 操作
void sema_up(struct semaphore* psema) {
	// 关闭中断保证原子操作
	enum intr_status old_status = intr_disable();
	
	if (!list_empty(&psema->waiters)) {
		struct task_struct* thread_blocked = elem2entry(struct task_struct, general_tag, list_pop(&psema->waiters));
		thread_unblock(thread_blocked);
	}
	
	psema->value++;
	intr_set_status(old_status);
}

// 获取锁 plock
void lock_acquire(struct lock* plock) {
	if (plock->holder != running_thread()) {
		sema_down(&plock->semaphore);
		plock->holder = running_thread();
		plock->holder_repeat_nr = 1;
	} else {
		plock->holder_repeat_nr++;
	}
}

// 释放锁 plock
void lock_release(struct lock* plock) {
	if (plock->holder_repeat_nr > 1) {
		plock->holder_repeat_nr--;
		return;
	}
	plock->holder = NULL;
	plock->holder_repeat_nr = 0;
	sema_up(&plock->semaphore);
}





















		
