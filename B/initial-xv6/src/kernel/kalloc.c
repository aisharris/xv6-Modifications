// Physical memory allocator, for user processes,
// kernel stacks, page-table pages,
// and pipe buffers. Allocates whole 4096-byte pages.

#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "riscv.h"
#include "defs.h"

//reference to physical pages

struct PA_ref 
{
  struct spinlock lock;
  int ref_arr[PHYSTOP >> PGSHIFT];
};

void freerange(void *pa_start, void *pa_end);

extern char end[]; // first address after kernel.
                   // defined by kernel.ld.

struct run {
  struct run *next;
};

struct {
  struct spinlock lock;
  struct run *freelist;
} kmem;

struct PA_ref stPageRefs;

void
kinit()
{
  initlock(&stPageRefs.lock, "page_refs"); 

  initlock(&kmem.lock, "kmem");
  freerange(end, (void*)PHYSTOP);
}

void
freerange(void *pa_start, void *pa_end)
{
  char *p;
  p = (char*)PGROUNDUP((uint64)pa_start);
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
  {
    stPageRefs.ref_arr[(uint64)p >> PGSHIFT] = 1;
    kfree(p);
  }
}

// Free the page of physical memory pointed at by pa,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    panic("kfree");


  //acquire(&stPageRefs.lock);
  if(stPageRefs.ref_arr[(uint64)pa >> PGSHIFT] == 0)
  {
    //release(&stPageRefs.lock);
    panic("kfree: ref count is 0 oh no");
  }

  stPageRefs.ref_arr[(uint64)pa >> PGSHIFT]--;

  if(stPageRefs.ref_arr[(uint64)pa >> PGSHIFT] != 0)
  {
    //release(&stPageRefs.lock);
    return;
  }
  else
  {
    // Fill with junk to catch dangling refs. ???anyways
    memset(pa, 1, PGSIZE);

    r = (struct run*)pa;
    acquire(&kmem.lock);
    r->next = kmem.freelist;
    kmem.freelist = r;
    release(&kmem.lock);
    //release(&stPageRefs.lock);
  }
}

// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
  struct run *r;

  acquire(&kmem.lock);
  r = kmem.freelist;

  if(r)
  {
    //increment references
    //acquire(&stPageRefs.lock);
    stPageRefs.ref_arr[(uint64)r >> PGSHIFT] = 1;
    //release(&stPageRefs.lock);

    kmem.freelist = r->next;  

  }
  release(&kmem.lock);

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
  return (void*)r;
}

void
increase_ref(void *pa)
{
  //acquire(&stPageRefs.lock);

  stPageRefs.ref_arr[(uint64)pa >> PGSHIFT]++;
  
  //release(&stPageRefs.lock);
}

void
decrease_ref(void *pa)
{
  //acquire(&stPageRefs.lock);

  stPageRefs.ref_arr[(uint64)pa >> PGSHIFT]--;
  
  //release(&stPageRefs.lock);
}

int
get_refcount(void *pa)
{
  //acquire(&stPageRefs.lock);
  int ret = stPageRefs.ref_arr[(uint64)pa >> PGSHIFT];
  //release(&stPageRefs.lock);

  return ret;
}