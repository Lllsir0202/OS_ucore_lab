#include "memlayout.h"
#include <pmm.h>
#include <list.h>
#include <string.h>
#include <buddy_system_pmm.h>
#include <stdio.h>

struct buddy2_t{
    unsigned size;  //记录内存总共的大小
    unsigned longest[35000];   //表明所对应的内存块的空闲单位
};

//定义一个指针
struct buddy2_t *buddy;

//记录页面，便于使用
struct Page *bases;


#define LEFT_LEAF(index) ((index) * 2 + 1)
#define RIGHT_LEAF(index) ((index) * 2 + 2)
#define PARENT(index) ( ((index) + 1) / 2 - 1)

#define IS_POWER_OF_2(x) (!((x)&((x)-1)))
#define MAX(a, b) ((a) > (b) ? (a) : (b))

#define ptr2buddy(buddy,member) \
    to_struct((buddy),struct buddy2_t, member)

static unsigned fixsize(unsigned size) {
  size |= size >> 1;
  size |= size >> 2;
  size |= size >> 4;
  size |= size >> 8;
  size |= size >> 16;
  return size+1;
}


static void
buddy_system_init(void){

}

static void
buddy_system_init_memmap(struct Page *base, size_t n){
    assert(n > 0);
    unsigned node_size;
    bases = base;   //记录下页，即记录下开始的连续页表块即可
    // 先将所有的page的proprty都设为1，表示这个还没有被使用
    struct Page *p = base;
    for(;p != base + n; p ++){
        p->flags = p->property = 1; //表示当前所有页都没有使用
        set_page_ref(p, 0); //表示当前所有页都没有被引用
    }
    
    buddy->size = n;
    node_size = n * 2;
    for (unsigned i = 0; i < 2 * n - 1; ++i) {
        if (IS_POWER_OF_2(i+1)){
            node_size /= 2;
        }
        buddy->longest[i] = node_size;
    }
}

static struct Page *
buddy_system_alloc_pages(size_t n) {
    assert(n > 0);
    unsigned index = 0;
    unsigned node_size;
    unsigned offset = 0;
    if (n > buddy->size) {
        return NULL;
    }
    if(!IS_POWER_OF_2(n)) {
        n = fixsize(n);
    }
    for(node_size = buddy->size; node_size != n; node_size /= 2 ) {
        if (buddy->longest[LEFT_LEAF(index)] >= n)
        index = LEFT_LEAF(index);
        else
        index = RIGHT_LEAF(index);
    }

    buddy->longest[index] = 0;
    offset = (index + 1) * node_size - buddy->size;

    while (index) {
        index = PARENT(index);
        buddy->longest[index] = 
        MAX(buddy->longest[LEFT_LEAF(index)], buddy->longest[RIGHT_LEAF(index)]);
    }
    struct Page* page = bases + offset;
    struct Page* p = bases + offset;
    for(;p != page + n; p ++){
        p->flags = 0;
        p->property = 0;
    }
    return page;
}

static void
buddy_system_free_pages(struct Page *base, size_t n) {
    assert(n > 0 && n <= buddy->size);
    unsigned long long node_size, index = 0;
    unsigned long long left_longest, right_longest;
    node_size = 1;
    index = n + buddy->size - 1;
    for (; buddy->longest[index] ; index = PARENT(index)) {
        node_size *= 2;
        if (index == 0)
        return;
    }
    buddy->longest[index] = node_size;
    while (index) {
        index = PARENT(index);
        node_size *= 2;
        left_longest = buddy->longest[LEFT_LEAF(index)];
        right_longest = buddy->longest[RIGHT_LEAF(index)];
        if (left_longest + right_longest == node_size)
        buddy->longest[index] = node_size;
        else
        buddy->longest[index] = MAX(left_longest, right_longest);
    }
} 

static size_t
buddy_system_nr_free_pages(void) {
    return buddy->size;
}

static void
buddy_system_check(void) {

}

//这个结构体在
const struct pmm_manager buddy_system_pmm_manager = {
    .name = "buddy_system_pmm_manager",
    .init = buddy_system_init,
    .init_memmap = buddy_system_init_memmap,
    .alloc_pages = buddy_system_alloc_pages,
    .free_pages = buddy_system_free_pages,
    .nr_free_pages = buddy_system_nr_free_pages,
    .check = buddy_system_check,
};
