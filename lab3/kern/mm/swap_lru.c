#include "memlayout.h"
#include "pmm.h"
#include "vmm.h"
#include <defs.h>
#include <riscv.h>
#include <stdio.h>
#include <string.h>
#include <swap.h>
#include <swap_lru.h>
#include <list.h>

/* [wikipedia]The simplest Page Replacement Algorithm(PRA) is a fifo algorithm. The first-in, first-out
 * page replacement algorithm is a low-overhead algorithm that requires little book-keeping on
 * the part of the operating system. The idea is obvious from the name - the operating system
 * keeps track of all the pages in memory in a queue, with the most recent arrival at the back,
 * and the earliest arrival in front. When a page needs to be replaced, the page at the front
 * of the queue (the oldest page) is selected. While FIFO is cheap and intuitive, it performs
 * poorly in practical application. Thus, it is rarely used in its unmodified form. This
 * algorithm experiences Belady's anomaly.
 *
 * Details of FIFO PRA
 * (1) Prepare: In order to implement FIFO PRA, we should manage all swappable pages, so we can
 *              link these pages into pra_list_head according the time order. At first you should
 *              be familiar to the struct list in list.h. struct list is a simple doubly linked list
 *              implementation. You should know howto USE: list_init, list_add(list_add_after),
 *              list_add_before, list_del, list_next, list_prev. Another tricky method is to transform
 *              a general list struct to a special struct (such as struct page). You can find some MACRO:
 *              le2page (in memlayout.h), (in future labs: le2vma (in vmm.h), le2proc (in proc.h),etc.
 */

static list_entry_t pra_list_head;
/*
 * (2) _fifo_init_mm: init pra_list_head and let  mm->sm_priv point to the addr of pra_list_head.
 *              Now, From the memory control struct mm_struct, we can access FIFO PRA
 */
static int
_lru_init_mm(struct mm_struct *mm)
{     
     list_init(&pra_list_head);
     mm->sm_priv = &pra_list_head;
     //cprintf(" mm->sm_priv %x in fifo_init_mm\n",mm->sm_priv);
     return 0;
}
/*
 * (3)_fifo_map_swappable: According FIFO PRA, we should link the most recent arrival page at the back of pra_list_head qeueue
 */

static int
_lru_access(uintptr_t addr)
{
    list_entry_t *head= &pra_list_head;
    
 
    // assert(entry != NULL && head != NULL);

    // 对这个地址在当前的链表中进行一个遍历，如果存在，则将其加到最前
    list_entry_t *p = head;
    struct Page *page;
    while(1)
    {
        p = list_next(p);
        if(p == head)
        {
            break;
        }
        page = le2page(p, pra_page_link);
        // 说明有相同的
        if(page->pra_vaddr == addr)
        {
            break;
        }
    }
    list_entry_t *entry = &(page->pra_page_link);
    list_del(p);
    list_add(head, entry);
    //list_del(p);
    cprintf("page addr 0x%x\n", entry);
    return 0;
}

static int
_lru_map_swappable(struct mm_struct *mm, uintptr_t addr, struct Page *page, int swap_in)
{
     list_entry_t *head=(list_entry_t*) mm->sm_priv;
     list_entry_t *entry=&(page->pra_page_link);
 
     assert(entry != NULL && head != NULL);
    // //record the page access situlation

    // //(1)link the most recent arrival page at the back of the pra_list_head qeueue.
    // // 进行一个遍历，如果找到相同的，就将它串到head后，也就是最前面，然后每次剔除最后一个
    // list_entry_t *p = list_next(head);
    // struct Page *pa;
    // int flag = 0;
    // while(1)
    // {
    //     // 当没有遍历一圈时，继续遍历
    //     if(p != head)
    //     {
    //         p = list_next(p);
    //     }else {
    //         break;
    //     }
    //     pa = le2page(p, pra_page_link);
    //     if(pa == page)
    //     {
    //         flag = 1;
    //         break;
    //     }
    // }
    // // 找到相同时，先串到头节点后一位置，然后将那个位置的剔除，
     list_add(head, entry);
    // if(flag==1)
    // {
    //     list_del(p);
    // }
    cprintf("page addr 0x%x\n", entry);
    return 0;
}
/*
 *  (4)_fifo_swap_out_victim: According FIFO PRA, we should unlink the  earliest arrival page in front of pra_list_head qeueue,
 *                            then set the addr of addr of this page to ptr_page.
 */
static int
_lru_swap_out_victim(struct mm_struct *mm, struct Page ** ptr_page, int in_tick)
{
     list_entry_t *head=(list_entry_t*) mm->sm_priv;
         assert(head != NULL);
     assert(in_tick==0);
     /* Select the victim */
     //(1)  unlink the  earliest arrival page in front of pra_list_head qeueue
     //(2)  set the addr of addr of this page to ptr_page
     // 这里得到的入口应该是最后一个位置，这里可以不动，在前面进行修改
    list_entry_t* entry = list_prev(head);
    if (entry != head) {
        list_del(entry);
        *ptr_page = le2page(entry, pra_page_link);
    } else {
        *ptr_page = NULL;
    }
    cprintf("page addr 0x%x\n", entry);
    return 0;
}

static int
_lru_check_swap(void) {
    cprintf("write Virt Page c in lru_check_swap\n");
    *(unsigned char *)0x3000 = 0x0c;
    _lru_access((unsigned char *)0x3000)  ;
    assert(pgfault_num==4);
    cprintf("write Virt Page a in lru_check_swap\n");
    *(unsigned char *)0x1000= 0x0a;
    _lru_access((unsigned char *)0x1000) ;
    assert(pgfault_num==4);
    cprintf("write Virt Page d in lru_check_swap\n");
    *(unsigned char *)0x4000 = 0x0d;
    _lru_access((unsigned char *)0x4000) ;
    assert(pgfault_num==4);
    cprintf("write Virt Page b in lru_check_swap\n");
    *(unsigned char *)0x2000 = 0x0b;
    _lru_access((unsigned char *)0x2000) ;
    assert(pgfault_num==4);
    // 2 -> 4 -> 1 -> 3
    cprintf("write Virt Page e in lru_check_swap\n");
    *(unsigned char *)0x5000 = 0x0e;
    _lru_access((unsigned char *)0x5000);
    assert(pgfault_num==5);
    // 5 -> 2 -> 4 -> 1
    cprintf("write Virt Page b in lru_check_swap\n");
    *(unsigned char *)0x2000 = 0x0b;
    _lru_access((unsigned char *)0x2000);
    assert(pgfault_num==5);
    // 2 -> 5 -> 4 -> 1
    cprintf("write Virt Page a in lru_check_swap\n");

    *(unsigned char *)0x1000 = 0x0a;
    _lru_access((unsigned char *)0x1000);
    // 1 -> 2 -> 5 -> 4
    assert(pgfault_num==5);
    //assert(pgfault_num==6);
    cprintf("write Virt Page b in lru_check_swap\n");
    *(unsigned char *)0x2000 = 0x0b;
    _lru_access((unsigned char *)0x2000);
    // 2 -> 1 -> 5 -> 4
    assert(pgfault_num==5);
    // assert(pgfault_num==7);
    cprintf("write Virt Page c in lru_check_swap\n");
    
    *(unsigned char *)0x3000 = 0x0c;
    _lru_access((unsigned char *)0x3000);
    // 3 -> 2 -> 1 -> 5
    assert(pgfault_num==6);
    //assert(pgfault_num==8);
    cprintf("write Virt Page d in lru_check_swap\n");
    
    *(unsigned char *)0x4000 = 0x0d;
    _lru_access((unsigned char *)0x4000);
    // 4 -> 3 -> 2 -> 1
    assert(pgfault_num==7);
    //assert(pgfault_num==9);
    cprintf("write Virt Page e in lru_check_swap\n");
    
    *(unsigned char *)0x5000 = 0x0e;
    _lru_access((unsigned char *)0x5000);
    // 5 -> 4 -> 3 -> 2
    assert(pgfault_num==8);
    //assert(pgfault_num==10);
    cprintf("write Virt Page a in lru_check_swap\n");
    //assert(*(unsigned char *)0x1000 == 0x0a);
    assert(*(unsigned char *)0x2000 == 0x0b);
    // 2 -> 5 -> 4 -> 3
    
    *(unsigned char *)0x1000 = 0x0a;
    _lru_access((unsigned char *)0x1000);
    // 1 -> 2 -> 5 -> 4
    assert(pgfault_num==9);
    // assert(pgfault_num==11);
    return 0;
}


static int
_lru_init(void)
{
    return 0;
}

static int
_lru_set_unswappable(struct mm_struct *mm, uintptr_t addr)
{
    return 0;
}

static int
_lru_tick_event(struct mm_struct *mm)
{ return 0; }


struct swap_manager swap_manager_lru =
{
     .name            = "lru swap manager",
     .init            = &_lru_init,
     .init_mm         = &_lru_init_mm,
     .tick_event      = &_lru_tick_event,
     .map_swappable   = &_lru_map_swappable,
     .set_unswappable = &_lru_set_unswappable,
     .swap_out_victim = &_lru_swap_out_victim,
     .check_swap      = &_lru_check_swap,
};
