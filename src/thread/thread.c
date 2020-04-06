#include "thread.h"
#include "stdint.h"
#include "string.h"
#include "global.h"
#include "memory.h"
#include "list.h"
#include "interrupt.h"

#define PG_SIZE 4096

struct task_struct* main_thread; // 主线程 PCB
struct list thread_ready_list; // 就绪队列
struct list thread_all_list; // 所有任务队列
static struct list_elem* thread_tag; // 用于保存队列中的线程结点

extern void switch_to(struct task_struct* cur, struct task_struct* next);

struct task_struct* running_thread() {
	uint32_t esp;
	asm ("mov %%esp, %0" : "=g" (esp));
	// 返回esp整数部分，即pcb起始地址
	return (struct task_struct*)(esp & 0xfffff000);
}

// 由 kernel_thread 去执行 function(func_arg)
static void kernel_thread(thread_func* function, void* func_arg) {
	intr_enable();
	function(func_arg);
}

// 初始化线程栈 thread_stack
void thread_create(struct task_struct* pthread, thread_func function, void* func_arg) {
	// 先预留中断使用栈的空间
	pthread->self_kstack -= sizeof(struct intr_stack);
	
	// 再留出线程栈空间
	pthread->self_kstack -= sizeof(struct thread_stack);
	struct thread_stack* kthread_stack = (struct thread_stack*)pthread->self_kstack;
	kthread_stack->eip = kernel_thread;
	kthread_stack->function = function;
	kthread_stack->func_arg = func_arg;
	kthread_stack->ebp = kthread_stack->ebx = kthread_stack->esi = kthread_stack->edi = 0;
}

// 初始化线程基本信息
void init_thread(struct task_struct* pthread, char* name, int prio) {
	memset(pthread, 0, sizeof(*pthread));
	strcpy(pthread->name, name);
	
	if (pthread == main_thread) {
		pthread->status = TASK_RUNNING;
	} else {
		pthread->status = TASK_READY;
	}
	pthread->priority = prio;
	// 线程自己在内核态下使用的栈顶地址
	pthread->self_kstack = (uint32_t*)((uint32_t)pthread + PG_SIZE);
	pthread->ticks = prio;
	pthread->elapsed_ticks = 0;
	pthread->pgdir = NULL;
	pthread->stack_magic = 0x19870916; // 自定义魔数
}

// 创建一优先级为 prio 的线程，线程名为 name，线程所执行的函数为 function_start
struct task_struct* thread_start(char* name, int prio, thread_func function, void* func_arg) {
	put_str("one thread start:");
	put_str(name);
	put_str("\n");
	// pcb 都位于内核空间，包括用户进程的 pcb 也是在内核空间
	struct task_struct* thread = get_kernel_pages(1);
	
	init_thread(thread, name, prio);
	thread_create(thread, function, func_arg);
	
	list_append(&thread_ready_list, &thread->general_tag);
	list_append(&thread_all_list, &thread->all_list_tag);
	
	return thread;
}

static void make_main_thread(void) {
	main_thread = running_thread();
	init_thread(main_thread, "main", 31);
	list_append(&thread_all_list, &main_thread->all_list_tag);
}

// 实现任务调度
void schedule() {
	struct task_struct* cur = running_thread();
	if (cur->status == TASK_RUNNING) {
		// 只是时间片到了，加入就绪队列队尾
		list_append(&thread_ready_list, &cur->general_tag);
		cur->ticks = cur->priority;
		cur->status = TASK_READY;
	} else {
		// 需要等某事件发生后才能继续上 cpu，不加入就绪队列
	}
	
	thread_tag = NULL;
	// 就绪队列取第一个，准备上cpu
	thread_tag = list_pop(&thread_ready_list);
	struct task_struct* next = elem2entry(struct task_struct, general_tag, thread_tag);
	next->status = TASK_RUNNING;
	process_activate(next);
	switch_to(cur, next);
}

// 初始化线程环境
void thread_init(void) {
	put_str("thread_init_start\n");
	list_init(&thread_ready_list);
	list_init(&thread_all_list);
	make_main_thread();
	put_str("thread_init done\n");
}



// 当前线程将自己阻塞，标志其状态为 stat(取值必须为 BLOCKED WAITING HANGING 之一)
void thread_block(enum task_status stat) {
	enum intr_status old_status = intr_disable();
	struct task_struct* cur_thread = running_thread();
	cur_thread->status = stat;
	schedule();
	intr_set_status(old_status);
}

// 解除阻塞
void thread_unblock(struct task_struct* pthread) {
	enum intr_status old_status = intr_disable();
	if (pthread->status != TASK_READY) {
		if (elem_find(&thread_ready_list, &pthread->general_tag)) {
			// 错误！blocked thread in ready_list
		}
		// 放到队列的最前面，使其尽快得到调度
		list_push(&thread_ready_list, &pthread->general_tag);
		pthread->status = TASK_READY;
	}
	intr_set_status(old_status);
}






















