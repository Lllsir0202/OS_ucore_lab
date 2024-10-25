#include <pmm.h>
#include <list.h>
#include <string.h>
#include <buddy_system_pmm.h>
#include <stdio.h>
free_buddy_t free_buddy;

#define max_order (free_buddy.max_order)
#define free_list (free_buddy.free_list)
#define nr_free (free_buddy.nr_free)

size_t RoundDownOfPower2(size_t x)
{
    size_t i;
    for(i = 0; i < sizeof(size_t) * 8 - 1; i++)
        if((1 << (i + 1)) > x)
            break;
    return i;
}

size_t RoundUpOfPower2(size_t x)
{
    size_t i;
    for(i = 0; i < sizeof(size_t) * 8 - 1; i++)
        if((1 << (i + 1)) >= x)
            break;
    return (i + 1);
}

void buddy_merge(struct Page *base) {
    list_entry_t* le = list_prev(&(base->page_link));
    if (le != &free_list[base->property]) {
        struct Page *p = le2page(le, page_link);
        if (p + (1 << p->property) == base) {
            list_del(&(base->page_link));
            list_del(&(p->page_link));
            ClearPageProperty(base);
            p->property *= 2;
            size_t buddy_size = p->property;
            if (list_empty(&free_list[buddy_size])) 
                list_add(&free_list[buddy_size], &(p->page_link));
            else 
            {
                list_entry_t* le = &free_list[buddy_size];
                while ((le = list_next(le)) != &free_list[buddy_size]) 
                {
                    struct Page* page = le2page(le, page_link);
                    if (p < page) 
                    {
                        list_add_before(le, &(p->page_link));
                        break;
                    } else if (list_next(le) == &free_list[buddy_size]) 
                    {
                        list_add(le, &(p->page_link));
                    }
                }
            }
            buddy_merge(p);
        }
    }

    le = list_next(&(base->page_link));
    if (le != &free_list[base->property]) {
        struct Page *p = le2page(le, page_link);
        if (base + (1 << base->property) == p) {
            list_del(&(base->page_link));
            list_del(&(p->page_link));
            ClearPageProperty(p);
            base->property *= 2;
            size_t buddy_size = base->property;
            if (list_empty(&free_list[buddy_size])) 
                list_add(&free_list[buddy_size], &(base->page_link));
            else {
                list_entry_t* le = &free_list[buddy_size];
                while ((le = list_next(le)) != &free_list[buddy_size]) 
                {
                    struct Page* page = le2page(le, page_link);
                    if (base < page) 
                    {
                        list_add_before(le, &(base->page_link));
                        break;
                    } else if (list_next(le) == &free_list[buddy_size]) 
                    {
                        list_add(le, &(base->page_link));
                    }
                }
            }
            buddy_merge(base);
        }
    }
}

static void
buddy_init(void) {
    for(size_t i = 0;i <= MAX_ORDER;i++)
        list_init(&free_list[i]);
    nr_free = 0;
    max_order = 0;
}

static void
buddy_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);
    cprintf("%d\n", n);
    while(n != 0)
    {
        size_t buddy_size = (size_t)(RoundDownOfPower2(n));
        if(buddy_size > MAX_ORDER)
            buddy_size = MAX_ORDER;
        size_t page_count = 1 << buddy_size;
        struct Page *p = base;
        for (; p != base + page_count; p++) 
        {
            assert(PageReserved(p));
            p->flags = p->property = 0;
            set_page_ref(p, 0);
        }
        base->property = buddy_size;
        SetPageProperty(base);
        nr_free += page_count;
        if (list_empty(&free_list[buddy_size]))     
            list_add(&free_list[buddy_size], &(base->page_link)); 
        else 
        {
            list_entry_t* le = &free_list[buddy_size];
            while ((le = list_next(le)) != &free_list[buddy_size]) {
                struct Page* page = le2page(le, page_link);
                if (base < page) {
                    list_add_before(le, &(base->page_link));
                    break;
                } else if (list_next(le) == &free_list[buddy_size]) {
                    list_add(le, &(base->page_link));
                }
            }
        }
        base = base + page_count;
        n = n - page_count;
        if(buddy_size > max_order)
            max_order = buddy_size;
    }
}

static struct Page *
buddy_alloc_pages(size_t n) {
    assert(n > 0);
    if (n > nr_free)
        return NULL;
    size_t buddy_size = (size_t)(RoundUpOfPower2(n));
    size_t page_count = 1 << buddy_size;
    if(buddy_size > max_order)
        return NULL;
    struct Page *page = NULL;
    list_entry_t *le = &free_list[buddy_size];
    while ((le = list_next(le)) != &free_list[buddy_size]) {
        struct Page *p = le2page(le, page_link);
        page = p;
        break;
    }
    if (page != NULL) {
        list_del(&(page->page_link));
        nr_free -= page_count;
        ClearPageProperty(page);
    }
    else
    {
        size_t ready_buddy_size = buddy_size;
        size_t ready_page_count = page_count;
        while ((le = list_next(le)) == &free_list[ready_buddy_size]) {
            ready_buddy_size = ready_buddy_size + 1;
            ready_page_count = ready_page_count * 2;
            le = &free_list[ready_buddy_size];
        }
        struct Page *base1 = le2page(le, page_link);
        while(ready_buddy_size != buddy_size){
            list_del(&(base1->page_link));
            ready_buddy_size = ready_buddy_size - 1;
            ready_page_count = ready_page_count / 2;
            base1->property = ready_buddy_size;
            struct Page *base2 = base1 + ready_page_count;
            base2->property = ready_buddy_size;
            SetPageProperty(base2);

            if (list_empty(&free_list[ready_buddy_size]))     
                list_add(&free_list[ready_buddy_size], &(base1->page_link)); 
            else 
            {
                list_entry_t* le1 = &free_list[ready_buddy_size];
                while ((le1 = list_next(le1)) != &free_list[ready_buddy_size]) {
                    struct Page* page = le2page(le1, page_link);
                    if (base1 < page) {
                        list_add_before(le1, &(base1->page_link));
                        break;
                    } else if (list_next(le1) == &free_list[ready_buddy_size]) {
                        list_add(le1, &(base1->page_link));
                    }
                }
            }
            list_entry_t* le1 = &free_list[ready_buddy_size];
            while ((le1 = list_next(le1)) != &free_list[ready_buddy_size]) {
                struct Page* page = le2page(le1, page_link);
                if (base2 < page) {
                    list_add_before(le1, &(base2->page_link));
                    break;
                } else if (list_next(le1) == &free_list[ready_buddy_size]) {
                    list_add(le1, &(base2->page_link));
                }
            }
        }
        page = base1;
        list_del(&(page->page_link));
        nr_free -= page_count;
        ClearPageProperty(page);
    }
    return page;
}

static void
buddy_free_pages(struct Page *base, size_t n) {
    assert(n > 0);
    size_t buddy_size = (size_t)(RoundUpOfPower2(n));
    size_t page_count = 1 << buddy_size;
    struct Page *p = base;
    for (; p != base + page_count; p++) {
        assert(!PageReserved(p) && !PageProperty(p));
        p->flags = 0;
        set_page_ref(p, 0);
    }
    base->property = buddy_size;
    SetPageProperty(base);
    nr_free += page_count;
    if (list_empty(&free_list[buddy_size])) {
        list_add(&free_list[buddy_size], &(base->page_link));
    } else {
        list_entry_t* le = &free_list[buddy_size];
        while ((le = list_next(le)) != &free_list[buddy_size]) {
            struct Page* page = le2page(le, page_link);
            if (base < page) {
                list_add_before(le, &(base->page_link));
                break;
            } else if (list_next(le) == &free_list[buddy_size]) {
                list_add(le, &(base->page_link));
            }
        }
    }
    buddy_merge(base);
}


static size_t
buddy_nr_free_pages(void) {
    return nr_free;
}

static void
buddy_check(void) {
    int count = 0, total = 0;
    list_entry_t *le;
    for(size_t i = 0;i <= MAX_ORDER;i++)
    {
        le = &free_list[i];
        while ((le = list_next(le)) != &free_list[i]) {
            struct Page *p = le2page(le, page_link);
            assert(PageProperty(p));
            count ++, total += (1 << p->property);
        }
    }
    assert(total == nr_free_pages());
    assert(!list_empty(&free_list[10]));
    assert(!list_empty(&free_list[7]));
    assert(!list_empty(&free_list[5]));
    assert(!list_empty(&free_list[4]));
    assert(!list_empty(&free_list[3]));
    assert(!list_empty(&free_list[0]));
    cprintf("%d\n", total);
    cprintf("%d\n", count);
    
    list_entry_t free_list_store[MAX_ORDER + 1];
    for(size_t i = 0;i <= MAX_ORDER;i++)
    {
        free_list_store[i] = free_list[i];
        list_init(&free_list[i]);
        assert(list_empty(&free_list[i]));
    }
    
    struct Page *p0 = alloc_pages(5), *p1, *p2;
    assert(list_empty(&free_list[3]));
    p1= alloc_pages(5);
    assert(list_empty(&free_list[4]));
    assert(!list_empty(&free_list[3]));
    assert(p0 != NULL);
    assert(!PageProperty(p0));
    
    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    assert(alloc_pages(4) == NULL);
    free_pages(p0, 5);
    assert(!list_empty(&free_list[3]));
    free_pages(p1, 5);
    assert((p2 = alloc_pages(3)) != NULL);
    assert(!list_empty(&free_list[2]));
    free_pages(p2, 3);
    assert(list_empty(&free_list[2]));
    assert(!list_empty(&free_list[3]));
    nr_free = nr_free_store;

    for(size_t i = 0;i <= MAX_ORDER;i++)
    {
        free_list[i] = free_list_store[i];
        le = &free_list[i];
        while ((le = list_next(le)) != &free_list[i]) {
        struct Page *p = le2page(le, page_link);
        count --, total -= (1 << p->property);
        }
    }
    assert(count == 0);
    assert(total == 0);
}
//这个结构体在
const struct pmm_manager buddy_pmm_manager = {
    .name = "buddy_pmm_manager",
    .init = buddy_init,
    .init_memmap = buddy_init_memmap,
    .alloc_pages = buddy_alloc_pages,
    .free_pages = buddy_free_pages,
    .nr_free_pages = buddy_nr_free_pages,
    .check = buddy_check,
};

