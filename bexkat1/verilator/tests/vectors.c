#include "vectors.h"

static void dummy(void) {
  asm("halt");
}

isr _vectors_start[32] = {
  (void *)0xc0000001,
  (void *)0x00000000, /* reset */
  (void *)0xc0000001,
  dummy, /* mmu fault */
  (void *)0xc0000001,
  dummy, /* timer0 */
  (void *)0xc0000001,
  dummy, /* timer1 */
  (void *)0xc0000001,
  dummy, /* timer2 */
  (void *)0xc0000001,
  dummy, /* timer3 */
  (void *)0xc0000001,
  dummy, /* uart0 rx */
  (void *)0xc0000001,
  dummy, /* uart0 tx */
  (void *)0xc0000001,
  dummy, /* illegal instruction */
  (void *)0xc0000001,
  dummy, /* cpu1 */
  (void *)0xc0000001,
  dummy, /* cpu2 */
  (void *)0xc0000001,
  dummy, /* cpu3 */
  (void *)0xc0000001,
  dummy, /* trap 0 */
  (void *)0xc0000001,
  dummy, /* trap 1 */
  (void *)0xc0000001,
  dummy, /* trap 2 */
  (void *)0xc0000001,
  dummy /* trap 3 */
};

void set_interrupt_handler(interrupt_slot s, isr f) {
  _vectors_start[s] = f;
}

void set_exception_handler(interrupt_slot s, esr f) {
  _vectors_start[s] = (isr)f;
}
