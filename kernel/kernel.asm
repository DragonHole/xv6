
kernel/kernel：     文件格式 elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	18010113          	addi	sp,sp,384 # 80009180 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	b7c78793          	addi	a5,a5,-1156 # 80005be0 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	dbe78793          	addi	a5,a5,-578 # 80000e6c <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  timerinit();
    800000d8:	00000097          	auipc	ra,0x0
    800000dc:	f44080e7          	jalr	-188(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000e0:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000e4:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000e6:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e8:	30200073          	mret
}
    800000ec:	60a2                	ld	ra,8(sp)
    800000ee:	6402                	ld	s0,0(sp)
    800000f0:	0141                	addi	sp,sp,16
    800000f2:	8082                	ret

00000000800000f4 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000f4:	715d                	addi	sp,sp,-80
    800000f6:	e486                	sd	ra,72(sp)
    800000f8:	e0a2                	sd	s0,64(sp)
    800000fa:	fc26                	sd	s1,56(sp)
    800000fc:	f84a                	sd	s2,48(sp)
    800000fe:	f44e                	sd	s3,40(sp)
    80000100:	f052                	sd	s4,32(sp)
    80000102:	ec56                	sd	s5,24(sp)
    80000104:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000106:	04c05663          	blez	a2,80000152 <consolewrite+0x5e>
    8000010a:	8a2a                	mv	s4,a0
    8000010c:	84ae                	mv	s1,a1
    8000010e:	89b2                	mv	s3,a2
    80000110:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000112:	5afd                	li	s5,-1
    80000114:	4685                	li	a3,1
    80000116:	8626                	mv	a2,s1
    80000118:	85d2                	mv	a1,s4
    8000011a:	fbf40513          	addi	a0,s0,-65
    8000011e:	00002097          	auipc	ra,0x2
    80000122:	36e080e7          	jalr	878(ra) # 8000248c <either_copyin>
    80000126:	01550c63          	beq	a0,s5,8000013e <consolewrite+0x4a>
      break;
    uartputc(c);
    8000012a:	fbf44503          	lbu	a0,-65(s0)
    8000012e:	00000097          	auipc	ra,0x0
    80000132:	77a080e7          	jalr	1914(ra) # 800008a8 <uartputc>
  for(i = 0; i < n; i++){
    80000136:	2905                	addiw	s2,s2,1
    80000138:	0485                	addi	s1,s1,1
    8000013a:	fd299de3          	bne	s3,s2,80000114 <consolewrite+0x20>
  }

  return i;
}
    8000013e:	854a                	mv	a0,s2
    80000140:	60a6                	ld	ra,72(sp)
    80000142:	6406                	ld	s0,64(sp)
    80000144:	74e2                	ld	s1,56(sp)
    80000146:	7942                	ld	s2,48(sp)
    80000148:	79a2                	ld	s3,40(sp)
    8000014a:	7a02                	ld	s4,32(sp)
    8000014c:	6ae2                	ld	s5,24(sp)
    8000014e:	6161                	addi	sp,sp,80
    80000150:	8082                	ret
  for(i = 0; i < n; i++){
    80000152:	4901                	li	s2,0
    80000154:	b7ed                	j	8000013e <consolewrite+0x4a>

0000000080000156 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000156:	7159                	addi	sp,sp,-112
    80000158:	f486                	sd	ra,104(sp)
    8000015a:	f0a2                	sd	s0,96(sp)
    8000015c:	eca6                	sd	s1,88(sp)
    8000015e:	e8ca                	sd	s2,80(sp)
    80000160:	e4ce                	sd	s3,72(sp)
    80000162:	e0d2                	sd	s4,64(sp)
    80000164:	fc56                	sd	s5,56(sp)
    80000166:	f85a                	sd	s6,48(sp)
    80000168:	f45e                	sd	s7,40(sp)
    8000016a:	f062                	sd	s8,32(sp)
    8000016c:	ec66                	sd	s9,24(sp)
    8000016e:	e86a                	sd	s10,16(sp)
    80000170:	1880                	addi	s0,sp,112
    80000172:	8aaa                	mv	s5,a0
    80000174:	8a2e                	mv	s4,a1
    80000176:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000178:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000017c:	00011517          	auipc	a0,0x11
    80000180:	00450513          	addi	a0,a0,4 # 80011180 <cons>
    80000184:	00001097          	auipc	ra,0x1
    80000188:	a3e080e7          	jalr	-1474(ra) # 80000bc2 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000018c:	00011497          	auipc	s1,0x11
    80000190:	ff448493          	addi	s1,s1,-12 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    80000194:	00011917          	auipc	s2,0x11
    80000198:	08490913          	addi	s2,s2,132 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    8000019c:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000019e:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001a0:	4ca9                	li	s9,10
  while(n > 0){
    800001a2:	07305863          	blez	s3,80000212 <consoleread+0xbc>
    while(cons.r == cons.w){
    800001a6:	0984a783          	lw	a5,152(s1)
    800001aa:	09c4a703          	lw	a4,156(s1)
    800001ae:	02f71463          	bne	a4,a5,800001d6 <consoleread+0x80>
      if(myproc()->killed){
    800001b2:	00002097          	auipc	ra,0x2
    800001b6:	820080e7          	jalr	-2016(ra) # 800019d2 <myproc>
    800001ba:	551c                	lw	a5,40(a0)
    800001bc:	e7b5                	bnez	a5,80000228 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001be:	85a6                	mv	a1,s1
    800001c0:	854a                	mv	a0,s2
    800001c2:	00002097          	auipc	ra,0x2
    800001c6:	ed0080e7          	jalr	-304(ra) # 80002092 <sleep>
    while(cons.r == cons.w){
    800001ca:	0984a783          	lw	a5,152(s1)
    800001ce:	09c4a703          	lw	a4,156(s1)
    800001d2:	fef700e3          	beq	a4,a5,800001b2 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001d6:	0017871b          	addiw	a4,a5,1
    800001da:	08e4ac23          	sw	a4,152(s1)
    800001de:	07f7f713          	andi	a4,a5,127
    800001e2:	9726                	add	a4,a4,s1
    800001e4:	01874703          	lbu	a4,24(a4)
    800001e8:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    800001ec:	077d0563          	beq	s10,s7,80000256 <consoleread+0x100>
    cbuf = c;
    800001f0:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001f4:	4685                	li	a3,1
    800001f6:	f9f40613          	addi	a2,s0,-97
    800001fa:	85d2                	mv	a1,s4
    800001fc:	8556                	mv	a0,s5
    800001fe:	00002097          	auipc	ra,0x2
    80000202:	238080e7          	jalr	568(ra) # 80002436 <either_copyout>
    80000206:	01850663          	beq	a0,s8,80000212 <consoleread+0xbc>
    dst++;
    8000020a:	0a05                	addi	s4,s4,1
    --n;
    8000020c:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    8000020e:	f99d1ae3          	bne	s10,s9,800001a2 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000212:	00011517          	auipc	a0,0x11
    80000216:	f6e50513          	addi	a0,a0,-146 # 80011180 <cons>
    8000021a:	00001097          	auipc	ra,0x1
    8000021e:	a5c080e7          	jalr	-1444(ra) # 80000c76 <release>

  return target - n;
    80000222:	413b053b          	subw	a0,s6,s3
    80000226:	a811                	j	8000023a <consoleread+0xe4>
        release(&cons.lock);
    80000228:	00011517          	auipc	a0,0x11
    8000022c:	f5850513          	addi	a0,a0,-168 # 80011180 <cons>
    80000230:	00001097          	auipc	ra,0x1
    80000234:	a46080e7          	jalr	-1466(ra) # 80000c76 <release>
        return -1;
    80000238:	557d                	li	a0,-1
}
    8000023a:	70a6                	ld	ra,104(sp)
    8000023c:	7406                	ld	s0,96(sp)
    8000023e:	64e6                	ld	s1,88(sp)
    80000240:	6946                	ld	s2,80(sp)
    80000242:	69a6                	ld	s3,72(sp)
    80000244:	6a06                	ld	s4,64(sp)
    80000246:	7ae2                	ld	s5,56(sp)
    80000248:	7b42                	ld	s6,48(sp)
    8000024a:	7ba2                	ld	s7,40(sp)
    8000024c:	7c02                	ld	s8,32(sp)
    8000024e:	6ce2                	ld	s9,24(sp)
    80000250:	6d42                	ld	s10,16(sp)
    80000252:	6165                	addi	sp,sp,112
    80000254:	8082                	ret
      if(n < target){
    80000256:	0009871b          	sext.w	a4,s3
    8000025a:	fb677ce3          	bgeu	a4,s6,80000212 <consoleread+0xbc>
        cons.r--;
    8000025e:	00011717          	auipc	a4,0x11
    80000262:	faf72d23          	sw	a5,-70(a4) # 80011218 <cons+0x98>
    80000266:	b775                	j	80000212 <consoleread+0xbc>

0000000080000268 <consputc>:
{
    80000268:	1141                	addi	sp,sp,-16
    8000026a:	e406                	sd	ra,8(sp)
    8000026c:	e022                	sd	s0,0(sp)
    8000026e:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000270:	10000793          	li	a5,256
    80000274:	00f50a63          	beq	a0,a5,80000288 <consputc+0x20>
    uartputc_sync(c);
    80000278:	00000097          	auipc	ra,0x0
    8000027c:	55e080e7          	jalr	1374(ra) # 800007d6 <uartputc_sync>
}
    80000280:	60a2                	ld	ra,8(sp)
    80000282:	6402                	ld	s0,0(sp)
    80000284:	0141                	addi	sp,sp,16
    80000286:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000288:	4521                	li	a0,8
    8000028a:	00000097          	auipc	ra,0x0
    8000028e:	54c080e7          	jalr	1356(ra) # 800007d6 <uartputc_sync>
    80000292:	02000513          	li	a0,32
    80000296:	00000097          	auipc	ra,0x0
    8000029a:	540080e7          	jalr	1344(ra) # 800007d6 <uartputc_sync>
    8000029e:	4521                	li	a0,8
    800002a0:	00000097          	auipc	ra,0x0
    800002a4:	536080e7          	jalr	1334(ra) # 800007d6 <uartputc_sync>
    800002a8:	bfe1                	j	80000280 <consputc+0x18>

00000000800002aa <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002aa:	1101                	addi	sp,sp,-32
    800002ac:	ec06                	sd	ra,24(sp)
    800002ae:	e822                	sd	s0,16(sp)
    800002b0:	e426                	sd	s1,8(sp)
    800002b2:	e04a                	sd	s2,0(sp)
    800002b4:	1000                	addi	s0,sp,32
    800002b6:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002b8:	00011517          	auipc	a0,0x11
    800002bc:	ec850513          	addi	a0,a0,-312 # 80011180 <cons>
    800002c0:	00001097          	auipc	ra,0x1
    800002c4:	902080e7          	jalr	-1790(ra) # 80000bc2 <acquire>

  switch(c){
    800002c8:	47d5                	li	a5,21
    800002ca:	0af48663          	beq	s1,a5,80000376 <consoleintr+0xcc>
    800002ce:	0297ca63          	blt	a5,s1,80000302 <consoleintr+0x58>
    800002d2:	47a1                	li	a5,8
    800002d4:	0ef48763          	beq	s1,a5,800003c2 <consoleintr+0x118>
    800002d8:	47c1                	li	a5,16
    800002da:	10f49a63          	bne	s1,a5,800003ee <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002de:	00002097          	auipc	ra,0x2
    800002e2:	204080e7          	jalr	516(ra) # 800024e2 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002e6:	00011517          	auipc	a0,0x11
    800002ea:	e9a50513          	addi	a0,a0,-358 # 80011180 <cons>
    800002ee:	00001097          	auipc	ra,0x1
    800002f2:	988080e7          	jalr	-1656(ra) # 80000c76 <release>
}
    800002f6:	60e2                	ld	ra,24(sp)
    800002f8:	6442                	ld	s0,16(sp)
    800002fa:	64a2                	ld	s1,8(sp)
    800002fc:	6902                	ld	s2,0(sp)
    800002fe:	6105                	addi	sp,sp,32
    80000300:	8082                	ret
  switch(c){
    80000302:	07f00793          	li	a5,127
    80000306:	0af48e63          	beq	s1,a5,800003c2 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000030a:	00011717          	auipc	a4,0x11
    8000030e:	e7670713          	addi	a4,a4,-394 # 80011180 <cons>
    80000312:	0a072783          	lw	a5,160(a4)
    80000316:	09872703          	lw	a4,152(a4)
    8000031a:	9f99                	subw	a5,a5,a4
    8000031c:	07f00713          	li	a4,127
    80000320:	fcf763e3          	bltu	a4,a5,800002e6 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000324:	47b5                	li	a5,13
    80000326:	0cf48763          	beq	s1,a5,800003f4 <consoleintr+0x14a>
      consputc(c);
    8000032a:	8526                	mv	a0,s1
    8000032c:	00000097          	auipc	ra,0x0
    80000330:	f3c080e7          	jalr	-196(ra) # 80000268 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000334:	00011797          	auipc	a5,0x11
    80000338:	e4c78793          	addi	a5,a5,-436 # 80011180 <cons>
    8000033c:	0a07a703          	lw	a4,160(a5)
    80000340:	0017069b          	addiw	a3,a4,1
    80000344:	0006861b          	sext.w	a2,a3
    80000348:	0ad7a023          	sw	a3,160(a5)
    8000034c:	07f77713          	andi	a4,a4,127
    80000350:	97ba                	add	a5,a5,a4
    80000352:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    80000356:	47a9                	li	a5,10
    80000358:	0cf48563          	beq	s1,a5,80000422 <consoleintr+0x178>
    8000035c:	4791                	li	a5,4
    8000035e:	0cf48263          	beq	s1,a5,80000422 <consoleintr+0x178>
    80000362:	00011797          	auipc	a5,0x11
    80000366:	eb67a783          	lw	a5,-330(a5) # 80011218 <cons+0x98>
    8000036a:	0807879b          	addiw	a5,a5,128
    8000036e:	f6f61ce3          	bne	a2,a5,800002e6 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000372:	863e                	mv	a2,a5
    80000374:	a07d                	j	80000422 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000376:	00011717          	auipc	a4,0x11
    8000037a:	e0a70713          	addi	a4,a4,-502 # 80011180 <cons>
    8000037e:	0a072783          	lw	a5,160(a4)
    80000382:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    80000386:	00011497          	auipc	s1,0x11
    8000038a:	dfa48493          	addi	s1,s1,-518 # 80011180 <cons>
    while(cons.e != cons.w &&
    8000038e:	4929                	li	s2,10
    80000390:	f4f70be3          	beq	a4,a5,800002e6 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    80000394:	37fd                	addiw	a5,a5,-1
    80000396:	07f7f713          	andi	a4,a5,127
    8000039a:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    8000039c:	01874703          	lbu	a4,24(a4)
    800003a0:	f52703e3          	beq	a4,s2,800002e6 <consoleintr+0x3c>
      cons.e--;
    800003a4:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003a8:	10000513          	li	a0,256
    800003ac:	00000097          	auipc	ra,0x0
    800003b0:	ebc080e7          	jalr	-324(ra) # 80000268 <consputc>
    while(cons.e != cons.w &&
    800003b4:	0a04a783          	lw	a5,160(s1)
    800003b8:	09c4a703          	lw	a4,156(s1)
    800003bc:	fcf71ce3          	bne	a4,a5,80000394 <consoleintr+0xea>
    800003c0:	b71d                	j	800002e6 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003c2:	00011717          	auipc	a4,0x11
    800003c6:	dbe70713          	addi	a4,a4,-578 # 80011180 <cons>
    800003ca:	0a072783          	lw	a5,160(a4)
    800003ce:	09c72703          	lw	a4,156(a4)
    800003d2:	f0f70ae3          	beq	a4,a5,800002e6 <consoleintr+0x3c>
      cons.e--;
    800003d6:	37fd                	addiw	a5,a5,-1
    800003d8:	00011717          	auipc	a4,0x11
    800003dc:	e4f72423          	sw	a5,-440(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003e0:	10000513          	li	a0,256
    800003e4:	00000097          	auipc	ra,0x0
    800003e8:	e84080e7          	jalr	-380(ra) # 80000268 <consputc>
    800003ec:	bded                	j	800002e6 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    800003ee:	ee048ce3          	beqz	s1,800002e6 <consoleintr+0x3c>
    800003f2:	bf21                	j	8000030a <consoleintr+0x60>
      consputc(c);
    800003f4:	4529                	li	a0,10
    800003f6:	00000097          	auipc	ra,0x0
    800003fa:	e72080e7          	jalr	-398(ra) # 80000268 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    800003fe:	00011797          	auipc	a5,0x11
    80000402:	d8278793          	addi	a5,a5,-638 # 80011180 <cons>
    80000406:	0a07a703          	lw	a4,160(a5)
    8000040a:	0017069b          	addiw	a3,a4,1
    8000040e:	0006861b          	sext.w	a2,a3
    80000412:	0ad7a023          	sw	a3,160(a5)
    80000416:	07f77713          	andi	a4,a4,127
    8000041a:	97ba                	add	a5,a5,a4
    8000041c:	4729                	li	a4,10
    8000041e:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000422:	00011797          	auipc	a5,0x11
    80000426:	dec7ad23          	sw	a2,-518(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    8000042a:	00011517          	auipc	a0,0x11
    8000042e:	dee50513          	addi	a0,a0,-530 # 80011218 <cons+0x98>
    80000432:	00002097          	auipc	ra,0x2
    80000436:	dec080e7          	jalr	-532(ra) # 8000221e <wakeup>
    8000043a:	b575                	j	800002e6 <consoleintr+0x3c>

000000008000043c <consoleinit>:

void
consoleinit(void)
{
    8000043c:	1141                	addi	sp,sp,-16
    8000043e:	e406                	sd	ra,8(sp)
    80000440:	e022                	sd	s0,0(sp)
    80000442:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000444:	00008597          	auipc	a1,0x8
    80000448:	bcc58593          	addi	a1,a1,-1076 # 80008010 <etext+0x10>
    8000044c:	00011517          	auipc	a0,0x11
    80000450:	d3450513          	addi	a0,a0,-716 # 80011180 <cons>
    80000454:	00000097          	auipc	ra,0x0
    80000458:	6de080e7          	jalr	1758(ra) # 80000b32 <initlock>

  uartinit();
    8000045c:	00000097          	auipc	ra,0x0
    80000460:	32a080e7          	jalr	810(ra) # 80000786 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000464:	00021797          	auipc	a5,0x21
    80000468:	eb478793          	addi	a5,a5,-332 # 80021318 <devsw>
    8000046c:	00000717          	auipc	a4,0x0
    80000470:	cea70713          	addi	a4,a4,-790 # 80000156 <consoleread>
    80000474:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000476:	00000717          	auipc	a4,0x0
    8000047a:	c7e70713          	addi	a4,a4,-898 # 800000f4 <consolewrite>
    8000047e:	ef98                	sd	a4,24(a5)
}
    80000480:	60a2                	ld	ra,8(sp)
    80000482:	6402                	ld	s0,0(sp)
    80000484:	0141                	addi	sp,sp,16
    80000486:	8082                	ret

0000000080000488 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    80000488:	7179                	addi	sp,sp,-48
    8000048a:	f406                	sd	ra,40(sp)
    8000048c:	f022                	sd	s0,32(sp)
    8000048e:	ec26                	sd	s1,24(sp)
    80000490:	e84a                	sd	s2,16(sp)
    80000492:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    80000494:	c219                	beqz	a2,8000049a <printint+0x12>
    80000496:	08054663          	bltz	a0,80000522 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    8000049a:	2501                	sext.w	a0,a0
    8000049c:	4881                	li	a7,0
    8000049e:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004a2:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004a4:	2581                	sext.w	a1,a1
    800004a6:	00008617          	auipc	a2,0x8
    800004aa:	b9a60613          	addi	a2,a2,-1126 # 80008040 <digits>
    800004ae:	883a                	mv	a6,a4
    800004b0:	2705                	addiw	a4,a4,1
    800004b2:	02b577bb          	remuw	a5,a0,a1
    800004b6:	1782                	slli	a5,a5,0x20
    800004b8:	9381                	srli	a5,a5,0x20
    800004ba:	97b2                	add	a5,a5,a2
    800004bc:	0007c783          	lbu	a5,0(a5)
    800004c0:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004c4:	0005079b          	sext.w	a5,a0
    800004c8:	02b5553b          	divuw	a0,a0,a1
    800004cc:	0685                	addi	a3,a3,1
    800004ce:	feb7f0e3          	bgeu	a5,a1,800004ae <printint+0x26>

  if(sign)
    800004d2:	00088b63          	beqz	a7,800004e8 <printint+0x60>
    buf[i++] = '-';
    800004d6:	fe040793          	addi	a5,s0,-32
    800004da:	973e                	add	a4,a4,a5
    800004dc:	02d00793          	li	a5,45
    800004e0:	fef70823          	sb	a5,-16(a4)
    800004e4:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004e8:	02e05763          	blez	a4,80000516 <printint+0x8e>
    800004ec:	fd040793          	addi	a5,s0,-48
    800004f0:	00e784b3          	add	s1,a5,a4
    800004f4:	fff78913          	addi	s2,a5,-1
    800004f8:	993a                	add	s2,s2,a4
    800004fa:	377d                	addiw	a4,a4,-1
    800004fc:	1702                	slli	a4,a4,0x20
    800004fe:	9301                	srli	a4,a4,0x20
    80000500:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000504:	fff4c503          	lbu	a0,-1(s1)
    80000508:	00000097          	auipc	ra,0x0
    8000050c:	d60080e7          	jalr	-672(ra) # 80000268 <consputc>
  while(--i >= 0)
    80000510:	14fd                	addi	s1,s1,-1
    80000512:	ff2499e3          	bne	s1,s2,80000504 <printint+0x7c>
}
    80000516:	70a2                	ld	ra,40(sp)
    80000518:	7402                	ld	s0,32(sp)
    8000051a:	64e2                	ld	s1,24(sp)
    8000051c:	6942                	ld	s2,16(sp)
    8000051e:	6145                	addi	sp,sp,48
    80000520:	8082                	ret
    x = -xx;
    80000522:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000526:	4885                	li	a7,1
    x = -xx;
    80000528:	bf9d                	j	8000049e <printint+0x16>

000000008000052a <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000052a:	1101                	addi	sp,sp,-32
    8000052c:	ec06                	sd	ra,24(sp)
    8000052e:	e822                	sd	s0,16(sp)
    80000530:	e426                	sd	s1,8(sp)
    80000532:	1000                	addi	s0,sp,32
    80000534:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000536:	00011797          	auipc	a5,0x11
    8000053a:	d007a523          	sw	zero,-758(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    8000053e:	00008517          	auipc	a0,0x8
    80000542:	ada50513          	addi	a0,a0,-1318 # 80008018 <etext+0x18>
    80000546:	00000097          	auipc	ra,0x0
    8000054a:	02e080e7          	jalr	46(ra) # 80000574 <printf>
  printf(s);
    8000054e:	8526                	mv	a0,s1
    80000550:	00000097          	auipc	ra,0x0
    80000554:	024080e7          	jalr	36(ra) # 80000574 <printf>
  printf("\n");
    80000558:	00008517          	auipc	a0,0x8
    8000055c:	b7050513          	addi	a0,a0,-1168 # 800080c8 <digits+0x88>
    80000560:	00000097          	auipc	ra,0x0
    80000564:	014080e7          	jalr	20(ra) # 80000574 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000568:	4785                	li	a5,1
    8000056a:	00009717          	auipc	a4,0x9
    8000056e:	a8f72b23          	sw	a5,-1386(a4) # 80009000 <panicked>
  for(;;)
    80000572:	a001                	j	80000572 <panic+0x48>

0000000080000574 <printf>:
{
    80000574:	7131                	addi	sp,sp,-192
    80000576:	fc86                	sd	ra,120(sp)
    80000578:	f8a2                	sd	s0,112(sp)
    8000057a:	f4a6                	sd	s1,104(sp)
    8000057c:	f0ca                	sd	s2,96(sp)
    8000057e:	ecce                	sd	s3,88(sp)
    80000580:	e8d2                	sd	s4,80(sp)
    80000582:	e4d6                	sd	s5,72(sp)
    80000584:	e0da                	sd	s6,64(sp)
    80000586:	fc5e                	sd	s7,56(sp)
    80000588:	f862                	sd	s8,48(sp)
    8000058a:	f466                	sd	s9,40(sp)
    8000058c:	f06a                	sd	s10,32(sp)
    8000058e:	ec6e                	sd	s11,24(sp)
    80000590:	0100                	addi	s0,sp,128
    80000592:	8a2a                	mv	s4,a0
    80000594:	e40c                	sd	a1,8(s0)
    80000596:	e810                	sd	a2,16(s0)
    80000598:	ec14                	sd	a3,24(s0)
    8000059a:	f018                	sd	a4,32(s0)
    8000059c:	f41c                	sd	a5,40(s0)
    8000059e:	03043823          	sd	a6,48(s0)
    800005a2:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005a6:	00011d97          	auipc	s11,0x11
    800005aa:	c9adad83          	lw	s11,-870(s11) # 80011240 <pr+0x18>
  if(locking)
    800005ae:	020d9b63          	bnez	s11,800005e4 <printf+0x70>
  if (fmt == 0)
    800005b2:	040a0263          	beqz	s4,800005f6 <printf+0x82>
  va_start(ap, fmt);
    800005b6:	00840793          	addi	a5,s0,8
    800005ba:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005be:	000a4503          	lbu	a0,0(s4)
    800005c2:	14050f63          	beqz	a0,80000720 <printf+0x1ac>
    800005c6:	4981                	li	s3,0
    if(c != '%'){
    800005c8:	02500a93          	li	s5,37
    switch(c){
    800005cc:	07000b93          	li	s7,112
  consputc('x');
    800005d0:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005d2:	00008b17          	auipc	s6,0x8
    800005d6:	a6eb0b13          	addi	s6,s6,-1426 # 80008040 <digits>
    switch(c){
    800005da:	07300c93          	li	s9,115
    800005de:	06400c13          	li	s8,100
    800005e2:	a82d                	j	8000061c <printf+0xa8>
    acquire(&pr.lock);
    800005e4:	00011517          	auipc	a0,0x11
    800005e8:	c4450513          	addi	a0,a0,-956 # 80011228 <pr>
    800005ec:	00000097          	auipc	ra,0x0
    800005f0:	5d6080e7          	jalr	1494(ra) # 80000bc2 <acquire>
    800005f4:	bf7d                	j	800005b2 <printf+0x3e>
    panic("null fmt");
    800005f6:	00008517          	auipc	a0,0x8
    800005fa:	a3250513          	addi	a0,a0,-1486 # 80008028 <etext+0x28>
    800005fe:	00000097          	auipc	ra,0x0
    80000602:	f2c080e7          	jalr	-212(ra) # 8000052a <panic>
      consputc(c);
    80000606:	00000097          	auipc	ra,0x0
    8000060a:	c62080e7          	jalr	-926(ra) # 80000268 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000060e:	2985                	addiw	s3,s3,1
    80000610:	013a07b3          	add	a5,s4,s3
    80000614:	0007c503          	lbu	a0,0(a5)
    80000618:	10050463          	beqz	a0,80000720 <printf+0x1ac>
    if(c != '%'){
    8000061c:	ff5515e3          	bne	a0,s5,80000606 <printf+0x92>
    c = fmt[++i] & 0xff;
    80000620:	2985                	addiw	s3,s3,1
    80000622:	013a07b3          	add	a5,s4,s3
    80000626:	0007c783          	lbu	a5,0(a5)
    8000062a:	0007849b          	sext.w	s1,a5
    if(c == 0)
    8000062e:	cbed                	beqz	a5,80000720 <printf+0x1ac>
    switch(c){
    80000630:	05778a63          	beq	a5,s7,80000684 <printf+0x110>
    80000634:	02fbf663          	bgeu	s7,a5,80000660 <printf+0xec>
    80000638:	09978863          	beq	a5,s9,800006c8 <printf+0x154>
    8000063c:	07800713          	li	a4,120
    80000640:	0ce79563          	bne	a5,a4,8000070a <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000644:	f8843783          	ld	a5,-120(s0)
    80000648:	00878713          	addi	a4,a5,8
    8000064c:	f8e43423          	sd	a4,-120(s0)
    80000650:	4605                	li	a2,1
    80000652:	85ea                	mv	a1,s10
    80000654:	4388                	lw	a0,0(a5)
    80000656:	00000097          	auipc	ra,0x0
    8000065a:	e32080e7          	jalr	-462(ra) # 80000488 <printint>
      break;
    8000065e:	bf45                	j	8000060e <printf+0x9a>
    switch(c){
    80000660:	09578f63          	beq	a5,s5,800006fe <printf+0x18a>
    80000664:	0b879363          	bne	a5,s8,8000070a <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    80000668:	f8843783          	ld	a5,-120(s0)
    8000066c:	00878713          	addi	a4,a5,8
    80000670:	f8e43423          	sd	a4,-120(s0)
    80000674:	4605                	li	a2,1
    80000676:	45a9                	li	a1,10
    80000678:	4388                	lw	a0,0(a5)
    8000067a:	00000097          	auipc	ra,0x0
    8000067e:	e0e080e7          	jalr	-498(ra) # 80000488 <printint>
      break;
    80000682:	b771                	j	8000060e <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000684:	f8843783          	ld	a5,-120(s0)
    80000688:	00878713          	addi	a4,a5,8
    8000068c:	f8e43423          	sd	a4,-120(s0)
    80000690:	0007b903          	ld	s2,0(a5)
  consputc('0');
    80000694:	03000513          	li	a0,48
    80000698:	00000097          	auipc	ra,0x0
    8000069c:	bd0080e7          	jalr	-1072(ra) # 80000268 <consputc>
  consputc('x');
    800006a0:	07800513          	li	a0,120
    800006a4:	00000097          	auipc	ra,0x0
    800006a8:	bc4080e7          	jalr	-1084(ra) # 80000268 <consputc>
    800006ac:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006ae:	03c95793          	srli	a5,s2,0x3c
    800006b2:	97da                	add	a5,a5,s6
    800006b4:	0007c503          	lbu	a0,0(a5)
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bb0080e7          	jalr	-1104(ra) # 80000268 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006c0:	0912                	slli	s2,s2,0x4
    800006c2:	34fd                	addiw	s1,s1,-1
    800006c4:	f4ed                	bnez	s1,800006ae <printf+0x13a>
    800006c6:	b7a1                	j	8000060e <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006c8:	f8843783          	ld	a5,-120(s0)
    800006cc:	00878713          	addi	a4,a5,8
    800006d0:	f8e43423          	sd	a4,-120(s0)
    800006d4:	6384                	ld	s1,0(a5)
    800006d6:	cc89                	beqz	s1,800006f0 <printf+0x17c>
      for(; *s; s++)
    800006d8:	0004c503          	lbu	a0,0(s1)
    800006dc:	d90d                	beqz	a0,8000060e <printf+0x9a>
        consputc(*s);
    800006de:	00000097          	auipc	ra,0x0
    800006e2:	b8a080e7          	jalr	-1142(ra) # 80000268 <consputc>
      for(; *s; s++)
    800006e6:	0485                	addi	s1,s1,1
    800006e8:	0004c503          	lbu	a0,0(s1)
    800006ec:	f96d                	bnez	a0,800006de <printf+0x16a>
    800006ee:	b705                	j	8000060e <printf+0x9a>
        s = "(null)";
    800006f0:	00008497          	auipc	s1,0x8
    800006f4:	93048493          	addi	s1,s1,-1744 # 80008020 <etext+0x20>
      for(; *s; s++)
    800006f8:	02800513          	li	a0,40
    800006fc:	b7cd                	j	800006de <printf+0x16a>
      consputc('%');
    800006fe:	8556                	mv	a0,s5
    80000700:	00000097          	auipc	ra,0x0
    80000704:	b68080e7          	jalr	-1176(ra) # 80000268 <consputc>
      break;
    80000708:	b719                	j	8000060e <printf+0x9a>
      consputc('%');
    8000070a:	8556                	mv	a0,s5
    8000070c:	00000097          	auipc	ra,0x0
    80000710:	b5c080e7          	jalr	-1188(ra) # 80000268 <consputc>
      consputc(c);
    80000714:	8526                	mv	a0,s1
    80000716:	00000097          	auipc	ra,0x0
    8000071a:	b52080e7          	jalr	-1198(ra) # 80000268 <consputc>
      break;
    8000071e:	bdc5                	j	8000060e <printf+0x9a>
  if(locking)
    80000720:	020d9163          	bnez	s11,80000742 <printf+0x1ce>
}
    80000724:	70e6                	ld	ra,120(sp)
    80000726:	7446                	ld	s0,112(sp)
    80000728:	74a6                	ld	s1,104(sp)
    8000072a:	7906                	ld	s2,96(sp)
    8000072c:	69e6                	ld	s3,88(sp)
    8000072e:	6a46                	ld	s4,80(sp)
    80000730:	6aa6                	ld	s5,72(sp)
    80000732:	6b06                	ld	s6,64(sp)
    80000734:	7be2                	ld	s7,56(sp)
    80000736:	7c42                	ld	s8,48(sp)
    80000738:	7ca2                	ld	s9,40(sp)
    8000073a:	7d02                	ld	s10,32(sp)
    8000073c:	6de2                	ld	s11,24(sp)
    8000073e:	6129                	addi	sp,sp,192
    80000740:	8082                	ret
    release(&pr.lock);
    80000742:	00011517          	auipc	a0,0x11
    80000746:	ae650513          	addi	a0,a0,-1306 # 80011228 <pr>
    8000074a:	00000097          	auipc	ra,0x0
    8000074e:	52c080e7          	jalr	1324(ra) # 80000c76 <release>
}
    80000752:	bfc9                	j	80000724 <printf+0x1b0>

0000000080000754 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000754:	1101                	addi	sp,sp,-32
    80000756:	ec06                	sd	ra,24(sp)
    80000758:	e822                	sd	s0,16(sp)
    8000075a:	e426                	sd	s1,8(sp)
    8000075c:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000075e:	00011497          	auipc	s1,0x11
    80000762:	aca48493          	addi	s1,s1,-1334 # 80011228 <pr>
    80000766:	00008597          	auipc	a1,0x8
    8000076a:	8d258593          	addi	a1,a1,-1838 # 80008038 <etext+0x38>
    8000076e:	8526                	mv	a0,s1
    80000770:	00000097          	auipc	ra,0x0
    80000774:	3c2080e7          	jalr	962(ra) # 80000b32 <initlock>
  pr.locking = 1;
    80000778:	4785                	li	a5,1
    8000077a:	cc9c                	sw	a5,24(s1)
}
    8000077c:	60e2                	ld	ra,24(sp)
    8000077e:	6442                	ld	s0,16(sp)
    80000780:	64a2                	ld	s1,8(sp)
    80000782:	6105                	addi	sp,sp,32
    80000784:	8082                	ret

0000000080000786 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000786:	1141                	addi	sp,sp,-16
    80000788:	e406                	sd	ra,8(sp)
    8000078a:	e022                	sd	s0,0(sp)
    8000078c:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    8000078e:	100007b7          	lui	a5,0x10000
    80000792:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    80000796:	f8000713          	li	a4,-128
    8000079a:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    8000079e:	470d                	li	a4,3
    800007a0:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007a4:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007a8:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007ac:	469d                	li	a3,7
    800007ae:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007b2:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007b6:	00008597          	auipc	a1,0x8
    800007ba:	8a258593          	addi	a1,a1,-1886 # 80008058 <digits+0x18>
    800007be:	00011517          	auipc	a0,0x11
    800007c2:	a8a50513          	addi	a0,a0,-1398 # 80011248 <uart_tx_lock>
    800007c6:	00000097          	auipc	ra,0x0
    800007ca:	36c080e7          	jalr	876(ra) # 80000b32 <initlock>
}
    800007ce:	60a2                	ld	ra,8(sp)
    800007d0:	6402                	ld	s0,0(sp)
    800007d2:	0141                	addi	sp,sp,16
    800007d4:	8082                	ret

00000000800007d6 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007d6:	1101                	addi	sp,sp,-32
    800007d8:	ec06                	sd	ra,24(sp)
    800007da:	e822                	sd	s0,16(sp)
    800007dc:	e426                	sd	s1,8(sp)
    800007de:	1000                	addi	s0,sp,32
    800007e0:	84aa                	mv	s1,a0
  push_off();
    800007e2:	00000097          	auipc	ra,0x0
    800007e6:	394080e7          	jalr	916(ra) # 80000b76 <push_off>

  if(panicked){
    800007ea:	00009797          	auipc	a5,0x9
    800007ee:	8167a783          	lw	a5,-2026(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    800007f2:	10000737          	lui	a4,0x10000
  if(panicked){
    800007f6:	c391                	beqz	a5,800007fa <uartputc_sync+0x24>
    for(;;)
    800007f8:	a001                	j	800007f8 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    800007fa:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    800007fe:	0207f793          	andi	a5,a5,32
    80000802:	dfe5                	beqz	a5,800007fa <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000804:	0ff4f513          	andi	a0,s1,255
    80000808:	100007b7          	lui	a5,0x10000
    8000080c:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000810:	00000097          	auipc	ra,0x0
    80000814:	406080e7          	jalr	1030(ra) # 80000c16 <pop_off>
}
    80000818:	60e2                	ld	ra,24(sp)
    8000081a:	6442                	ld	s0,16(sp)
    8000081c:	64a2                	ld	s1,8(sp)
    8000081e:	6105                	addi	sp,sp,32
    80000820:	8082                	ret

0000000080000822 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000822:	00008797          	auipc	a5,0x8
    80000826:	7e67b783          	ld	a5,2022(a5) # 80009008 <uart_tx_r>
    8000082a:	00008717          	auipc	a4,0x8
    8000082e:	7e673703          	ld	a4,2022(a4) # 80009010 <uart_tx_w>
    80000832:	06f70a63          	beq	a4,a5,800008a6 <uartstart+0x84>
{
    80000836:	7139                	addi	sp,sp,-64
    80000838:	fc06                	sd	ra,56(sp)
    8000083a:	f822                	sd	s0,48(sp)
    8000083c:	f426                	sd	s1,40(sp)
    8000083e:	f04a                	sd	s2,32(sp)
    80000840:	ec4e                	sd	s3,24(sp)
    80000842:	e852                	sd	s4,16(sp)
    80000844:	e456                	sd	s5,8(sp)
    80000846:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000848:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000084c:	00011a17          	auipc	s4,0x11
    80000850:	9fca0a13          	addi	s4,s4,-1540 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000854:	00008497          	auipc	s1,0x8
    80000858:	7b448493          	addi	s1,s1,1972 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000085c:	00008997          	auipc	s3,0x8
    80000860:	7b498993          	addi	s3,s3,1972 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000864:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000868:	02077713          	andi	a4,a4,32
    8000086c:	c705                	beqz	a4,80000894 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000086e:	01f7f713          	andi	a4,a5,31
    80000872:	9752                	add	a4,a4,s4
    80000874:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    80000878:	0785                	addi	a5,a5,1
    8000087a:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000087c:	8526                	mv	a0,s1
    8000087e:	00002097          	auipc	ra,0x2
    80000882:	9a0080e7          	jalr	-1632(ra) # 8000221e <wakeup>
    
    WriteReg(THR, c);
    80000886:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000088a:	609c                	ld	a5,0(s1)
    8000088c:	0009b703          	ld	a4,0(s3)
    80000890:	fcf71ae3          	bne	a4,a5,80000864 <uartstart+0x42>
  }
}
    80000894:	70e2                	ld	ra,56(sp)
    80000896:	7442                	ld	s0,48(sp)
    80000898:	74a2                	ld	s1,40(sp)
    8000089a:	7902                	ld	s2,32(sp)
    8000089c:	69e2                	ld	s3,24(sp)
    8000089e:	6a42                	ld	s4,16(sp)
    800008a0:	6aa2                	ld	s5,8(sp)
    800008a2:	6121                	addi	sp,sp,64
    800008a4:	8082                	ret
    800008a6:	8082                	ret

00000000800008a8 <uartputc>:
{
    800008a8:	7179                	addi	sp,sp,-48
    800008aa:	f406                	sd	ra,40(sp)
    800008ac:	f022                	sd	s0,32(sp)
    800008ae:	ec26                	sd	s1,24(sp)
    800008b0:	e84a                	sd	s2,16(sp)
    800008b2:	e44e                	sd	s3,8(sp)
    800008b4:	e052                	sd	s4,0(sp)
    800008b6:	1800                	addi	s0,sp,48
    800008b8:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008ba:	00011517          	auipc	a0,0x11
    800008be:	98e50513          	addi	a0,a0,-1650 # 80011248 <uart_tx_lock>
    800008c2:	00000097          	auipc	ra,0x0
    800008c6:	300080e7          	jalr	768(ra) # 80000bc2 <acquire>
  if(panicked){
    800008ca:	00008797          	auipc	a5,0x8
    800008ce:	7367a783          	lw	a5,1846(a5) # 80009000 <panicked>
    800008d2:	c391                	beqz	a5,800008d6 <uartputc+0x2e>
    for(;;)
    800008d4:	a001                	j	800008d4 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008d6:	00008717          	auipc	a4,0x8
    800008da:	73a73703          	ld	a4,1850(a4) # 80009010 <uart_tx_w>
    800008de:	00008797          	auipc	a5,0x8
    800008e2:	72a7b783          	ld	a5,1834(a5) # 80009008 <uart_tx_r>
    800008e6:	02078793          	addi	a5,a5,32
    800008ea:	02e79b63          	bne	a5,a4,80000920 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    800008ee:	00011997          	auipc	s3,0x11
    800008f2:	95a98993          	addi	s3,s3,-1702 # 80011248 <uart_tx_lock>
    800008f6:	00008497          	auipc	s1,0x8
    800008fa:	71248493          	addi	s1,s1,1810 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008fe:	00008917          	auipc	s2,0x8
    80000902:	71290913          	addi	s2,s2,1810 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000906:	85ce                	mv	a1,s3
    80000908:	8526                	mv	a0,s1
    8000090a:	00001097          	auipc	ra,0x1
    8000090e:	788080e7          	jalr	1928(ra) # 80002092 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000912:	00093703          	ld	a4,0(s2)
    80000916:	609c                	ld	a5,0(s1)
    80000918:	02078793          	addi	a5,a5,32
    8000091c:	fee785e3          	beq	a5,a4,80000906 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000920:	00011497          	auipc	s1,0x11
    80000924:	92848493          	addi	s1,s1,-1752 # 80011248 <uart_tx_lock>
    80000928:	01f77793          	andi	a5,a4,31
    8000092c:	97a6                	add	a5,a5,s1
    8000092e:	01478c23          	sb	s4,24(a5)
      uart_tx_w += 1;
    80000932:	0705                	addi	a4,a4,1
    80000934:	00008797          	auipc	a5,0x8
    80000938:	6ce7be23          	sd	a4,1756(a5) # 80009010 <uart_tx_w>
      uartstart();
    8000093c:	00000097          	auipc	ra,0x0
    80000940:	ee6080e7          	jalr	-282(ra) # 80000822 <uartstart>
      release(&uart_tx_lock);
    80000944:	8526                	mv	a0,s1
    80000946:	00000097          	auipc	ra,0x0
    8000094a:	330080e7          	jalr	816(ra) # 80000c76 <release>
}
    8000094e:	70a2                	ld	ra,40(sp)
    80000950:	7402                	ld	s0,32(sp)
    80000952:	64e2                	ld	s1,24(sp)
    80000954:	6942                	ld	s2,16(sp)
    80000956:	69a2                	ld	s3,8(sp)
    80000958:	6a02                	ld	s4,0(sp)
    8000095a:	6145                	addi	sp,sp,48
    8000095c:	8082                	ret

000000008000095e <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    8000095e:	1141                	addi	sp,sp,-16
    80000960:	e422                	sd	s0,8(sp)
    80000962:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000964:	100007b7          	lui	a5,0x10000
    80000968:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000096c:	8b85                	andi	a5,a5,1
    8000096e:	cb91                	beqz	a5,80000982 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000970:	100007b7          	lui	a5,0x10000
    80000974:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    80000978:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000097c:	6422                	ld	s0,8(sp)
    8000097e:	0141                	addi	sp,sp,16
    80000980:	8082                	ret
    return -1;
    80000982:	557d                	li	a0,-1
    80000984:	bfe5                	j	8000097c <uartgetc+0x1e>

0000000080000986 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    80000986:	1101                	addi	sp,sp,-32
    80000988:	ec06                	sd	ra,24(sp)
    8000098a:	e822                	sd	s0,16(sp)
    8000098c:	e426                	sd	s1,8(sp)
    8000098e:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    80000990:	54fd                	li	s1,-1
    80000992:	a029                	j	8000099c <uartintr+0x16>
      break;
    consoleintr(c);
    80000994:	00000097          	auipc	ra,0x0
    80000998:	916080e7          	jalr	-1770(ra) # 800002aa <consoleintr>
    int c = uartgetc();
    8000099c:	00000097          	auipc	ra,0x0
    800009a0:	fc2080e7          	jalr	-62(ra) # 8000095e <uartgetc>
    if(c == -1)
    800009a4:	fe9518e3          	bne	a0,s1,80000994 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009a8:	00011497          	auipc	s1,0x11
    800009ac:	8a048493          	addi	s1,s1,-1888 # 80011248 <uart_tx_lock>
    800009b0:	8526                	mv	a0,s1
    800009b2:	00000097          	auipc	ra,0x0
    800009b6:	210080e7          	jalr	528(ra) # 80000bc2 <acquire>
  uartstart();
    800009ba:	00000097          	auipc	ra,0x0
    800009be:	e68080e7          	jalr	-408(ra) # 80000822 <uartstart>
  release(&uart_tx_lock);
    800009c2:	8526                	mv	a0,s1
    800009c4:	00000097          	auipc	ra,0x0
    800009c8:	2b2080e7          	jalr	690(ra) # 80000c76 <release>
}
    800009cc:	60e2                	ld	ra,24(sp)
    800009ce:	6442                	ld	s0,16(sp)
    800009d0:	64a2                	ld	s1,8(sp)
    800009d2:	6105                	addi	sp,sp,32
    800009d4:	8082                	ret

00000000800009d6 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009d6:	1101                	addi	sp,sp,-32
    800009d8:	ec06                	sd	ra,24(sp)
    800009da:	e822                	sd	s0,16(sp)
    800009dc:	e426                	sd	s1,8(sp)
    800009de:	e04a                	sd	s2,0(sp)
    800009e0:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009e2:	03451793          	slli	a5,a0,0x34
    800009e6:	ebb9                	bnez	a5,80000a3c <kfree+0x66>
    800009e8:	84aa                	mv	s1,a0
    800009ea:	00025797          	auipc	a5,0x25
    800009ee:	61678793          	addi	a5,a5,1558 # 80026000 <end>
    800009f2:	04f56563          	bltu	a0,a5,80000a3c <kfree+0x66>
    800009f6:	47c5                	li	a5,17
    800009f8:	07ee                	slli	a5,a5,0x1b
    800009fa:	04f57163          	bgeu	a0,a5,80000a3c <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    800009fe:	6605                	lui	a2,0x1
    80000a00:	4585                	li	a1,1
    80000a02:	00000097          	auipc	ra,0x0
    80000a06:	2bc080e7          	jalr	700(ra) # 80000cbe <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a0a:	00011917          	auipc	s2,0x11
    80000a0e:	87690913          	addi	s2,s2,-1930 # 80011280 <kmem>
    80000a12:	854a                	mv	a0,s2
    80000a14:	00000097          	auipc	ra,0x0
    80000a18:	1ae080e7          	jalr	430(ra) # 80000bc2 <acquire>
  r->next = kmem.freelist;
    80000a1c:	01893783          	ld	a5,24(s2)
    80000a20:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a22:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a26:	854a                	mv	a0,s2
    80000a28:	00000097          	auipc	ra,0x0
    80000a2c:	24e080e7          	jalr	590(ra) # 80000c76 <release>
}
    80000a30:	60e2                	ld	ra,24(sp)
    80000a32:	6442                	ld	s0,16(sp)
    80000a34:	64a2                	ld	s1,8(sp)
    80000a36:	6902                	ld	s2,0(sp)
    80000a38:	6105                	addi	sp,sp,32
    80000a3a:	8082                	ret
    panic("kfree");
    80000a3c:	00007517          	auipc	a0,0x7
    80000a40:	62450513          	addi	a0,a0,1572 # 80008060 <digits+0x20>
    80000a44:	00000097          	auipc	ra,0x0
    80000a48:	ae6080e7          	jalr	-1306(ra) # 8000052a <panic>

0000000080000a4c <freerange>:
{
    80000a4c:	7179                	addi	sp,sp,-48
    80000a4e:	f406                	sd	ra,40(sp)
    80000a50:	f022                	sd	s0,32(sp)
    80000a52:	ec26                	sd	s1,24(sp)
    80000a54:	e84a                	sd	s2,16(sp)
    80000a56:	e44e                	sd	s3,8(sp)
    80000a58:	e052                	sd	s4,0(sp)
    80000a5a:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a5c:	6785                	lui	a5,0x1
    80000a5e:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a62:	94aa                	add	s1,s1,a0
    80000a64:	757d                	lui	a0,0xfffff
    80000a66:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a68:	94be                	add	s1,s1,a5
    80000a6a:	0095ee63          	bltu	a1,s1,80000a86 <freerange+0x3a>
    80000a6e:	892e                	mv	s2,a1
    kfree(p);
    80000a70:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a72:	6985                	lui	s3,0x1
    kfree(p);
    80000a74:	01448533          	add	a0,s1,s4
    80000a78:	00000097          	auipc	ra,0x0
    80000a7c:	f5e080e7          	jalr	-162(ra) # 800009d6 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a80:	94ce                	add	s1,s1,s3
    80000a82:	fe9979e3          	bgeu	s2,s1,80000a74 <freerange+0x28>
}
    80000a86:	70a2                	ld	ra,40(sp)
    80000a88:	7402                	ld	s0,32(sp)
    80000a8a:	64e2                	ld	s1,24(sp)
    80000a8c:	6942                	ld	s2,16(sp)
    80000a8e:	69a2                	ld	s3,8(sp)
    80000a90:	6a02                	ld	s4,0(sp)
    80000a92:	6145                	addi	sp,sp,48
    80000a94:	8082                	ret

0000000080000a96 <kinit>:
{
    80000a96:	1141                	addi	sp,sp,-16
    80000a98:	e406                	sd	ra,8(sp)
    80000a9a:	e022                	sd	s0,0(sp)
    80000a9c:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000a9e:	00007597          	auipc	a1,0x7
    80000aa2:	5ca58593          	addi	a1,a1,1482 # 80008068 <digits+0x28>
    80000aa6:	00010517          	auipc	a0,0x10
    80000aaa:	7da50513          	addi	a0,a0,2010 # 80011280 <kmem>
    80000aae:	00000097          	auipc	ra,0x0
    80000ab2:	084080e7          	jalr	132(ra) # 80000b32 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ab6:	45c5                	li	a1,17
    80000ab8:	05ee                	slli	a1,a1,0x1b
    80000aba:	00025517          	auipc	a0,0x25
    80000abe:	54650513          	addi	a0,a0,1350 # 80026000 <end>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	f8a080e7          	jalr	-118(ra) # 80000a4c <freerange>
}
    80000aca:	60a2                	ld	ra,8(sp)
    80000acc:	6402                	ld	s0,0(sp)
    80000ace:	0141                	addi	sp,sp,16
    80000ad0:	8082                	ret

0000000080000ad2 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ad2:	1101                	addi	sp,sp,-32
    80000ad4:	ec06                	sd	ra,24(sp)
    80000ad6:	e822                	sd	s0,16(sp)
    80000ad8:	e426                	sd	s1,8(sp)
    80000ada:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000adc:	00010497          	auipc	s1,0x10
    80000ae0:	7a448493          	addi	s1,s1,1956 # 80011280 <kmem>
    80000ae4:	8526                	mv	a0,s1
    80000ae6:	00000097          	auipc	ra,0x0
    80000aea:	0dc080e7          	jalr	220(ra) # 80000bc2 <acquire>
  r = kmem.freelist;
    80000aee:	6c84                	ld	s1,24(s1)
  if(r)
    80000af0:	c885                	beqz	s1,80000b20 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000af2:	609c                	ld	a5,0(s1)
    80000af4:	00010517          	auipc	a0,0x10
    80000af8:	78c50513          	addi	a0,a0,1932 # 80011280 <kmem>
    80000afc:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000afe:	00000097          	auipc	ra,0x0
    80000b02:	178080e7          	jalr	376(ra) # 80000c76 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b06:	6605                	lui	a2,0x1
    80000b08:	4595                	li	a1,5
    80000b0a:	8526                	mv	a0,s1
    80000b0c:	00000097          	auipc	ra,0x0
    80000b10:	1b2080e7          	jalr	434(ra) # 80000cbe <memset>
  return (void*)r;
}
    80000b14:	8526                	mv	a0,s1
    80000b16:	60e2                	ld	ra,24(sp)
    80000b18:	6442                	ld	s0,16(sp)
    80000b1a:	64a2                	ld	s1,8(sp)
    80000b1c:	6105                	addi	sp,sp,32
    80000b1e:	8082                	ret
  release(&kmem.lock);
    80000b20:	00010517          	auipc	a0,0x10
    80000b24:	76050513          	addi	a0,a0,1888 # 80011280 <kmem>
    80000b28:	00000097          	auipc	ra,0x0
    80000b2c:	14e080e7          	jalr	334(ra) # 80000c76 <release>
  if(r)
    80000b30:	b7d5                	j	80000b14 <kalloc+0x42>

0000000080000b32 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b32:	1141                	addi	sp,sp,-16
    80000b34:	e422                	sd	s0,8(sp)
    80000b36:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b38:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b3a:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b3e:	00053823          	sd	zero,16(a0)
}
    80000b42:	6422                	ld	s0,8(sp)
    80000b44:	0141                	addi	sp,sp,16
    80000b46:	8082                	ret

0000000080000b48 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b48:	411c                	lw	a5,0(a0)
    80000b4a:	e399                	bnez	a5,80000b50 <holding+0x8>
    80000b4c:	4501                	li	a0,0
  return r;
}
    80000b4e:	8082                	ret
{
    80000b50:	1101                	addi	sp,sp,-32
    80000b52:	ec06                	sd	ra,24(sp)
    80000b54:	e822                	sd	s0,16(sp)
    80000b56:	e426                	sd	s1,8(sp)
    80000b58:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b5a:	6904                	ld	s1,16(a0)
    80000b5c:	00001097          	auipc	ra,0x1
    80000b60:	e5a080e7          	jalr	-422(ra) # 800019b6 <mycpu>
    80000b64:	40a48533          	sub	a0,s1,a0
    80000b68:	00153513          	seqz	a0,a0
}
    80000b6c:	60e2                	ld	ra,24(sp)
    80000b6e:	6442                	ld	s0,16(sp)
    80000b70:	64a2                	ld	s1,8(sp)
    80000b72:	6105                	addi	sp,sp,32
    80000b74:	8082                	ret

0000000080000b76 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b76:	1101                	addi	sp,sp,-32
    80000b78:	ec06                	sd	ra,24(sp)
    80000b7a:	e822                	sd	s0,16(sp)
    80000b7c:	e426                	sd	s1,8(sp)
    80000b7e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b80:	100024f3          	csrr	s1,sstatus
    80000b84:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b88:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b8a:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000b8e:	00001097          	auipc	ra,0x1
    80000b92:	e28080e7          	jalr	-472(ra) # 800019b6 <mycpu>
    80000b96:	5d3c                	lw	a5,120(a0)
    80000b98:	cf89                	beqz	a5,80000bb2 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000b9a:	00001097          	auipc	ra,0x1
    80000b9e:	e1c080e7          	jalr	-484(ra) # 800019b6 <mycpu>
    80000ba2:	5d3c                	lw	a5,120(a0)
    80000ba4:	2785                	addiw	a5,a5,1
    80000ba6:	dd3c                	sw	a5,120(a0)
}
    80000ba8:	60e2                	ld	ra,24(sp)
    80000baa:	6442                	ld	s0,16(sp)
    80000bac:	64a2                	ld	s1,8(sp)
    80000bae:	6105                	addi	sp,sp,32
    80000bb0:	8082                	ret
    mycpu()->intena = old;
    80000bb2:	00001097          	auipc	ra,0x1
    80000bb6:	e04080e7          	jalr	-508(ra) # 800019b6 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bba:	8085                	srli	s1,s1,0x1
    80000bbc:	8885                	andi	s1,s1,1
    80000bbe:	dd64                	sw	s1,124(a0)
    80000bc0:	bfe9                	j	80000b9a <push_off+0x24>

0000000080000bc2 <acquire>:
{
    80000bc2:	1101                	addi	sp,sp,-32
    80000bc4:	ec06                	sd	ra,24(sp)
    80000bc6:	e822                	sd	s0,16(sp)
    80000bc8:	e426                	sd	s1,8(sp)
    80000bca:	1000                	addi	s0,sp,32
    80000bcc:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bce:	00000097          	auipc	ra,0x0
    80000bd2:	fa8080e7          	jalr	-88(ra) # 80000b76 <push_off>
  if(holding(lk))
    80000bd6:	8526                	mv	a0,s1
    80000bd8:	00000097          	auipc	ra,0x0
    80000bdc:	f70080e7          	jalr	-144(ra) # 80000b48 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000be0:	4705                	li	a4,1
  if(holding(lk))
    80000be2:	e115                	bnez	a0,80000c06 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000be4:	87ba                	mv	a5,a4
    80000be6:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bea:	2781                	sext.w	a5,a5
    80000bec:	ffe5                	bnez	a5,80000be4 <acquire+0x22>
  __sync_synchronize();
    80000bee:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000bf2:	00001097          	auipc	ra,0x1
    80000bf6:	dc4080e7          	jalr	-572(ra) # 800019b6 <mycpu>
    80000bfa:	e888                	sd	a0,16(s1)
}
    80000bfc:	60e2                	ld	ra,24(sp)
    80000bfe:	6442                	ld	s0,16(sp)
    80000c00:	64a2                	ld	s1,8(sp)
    80000c02:	6105                	addi	sp,sp,32
    80000c04:	8082                	ret
    panic("acquire");
    80000c06:	00007517          	auipc	a0,0x7
    80000c0a:	46a50513          	addi	a0,a0,1130 # 80008070 <digits+0x30>
    80000c0e:	00000097          	auipc	ra,0x0
    80000c12:	91c080e7          	jalr	-1764(ra) # 8000052a <panic>

0000000080000c16 <pop_off>:

void
pop_off(void)
{
    80000c16:	1141                	addi	sp,sp,-16
    80000c18:	e406                	sd	ra,8(sp)
    80000c1a:	e022                	sd	s0,0(sp)
    80000c1c:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c1e:	00001097          	auipc	ra,0x1
    80000c22:	d98080e7          	jalr	-616(ra) # 800019b6 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c26:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c2a:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c2c:	e78d                	bnez	a5,80000c56 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c2e:	5d3c                	lw	a5,120(a0)
    80000c30:	02f05b63          	blez	a5,80000c66 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c34:	37fd                	addiw	a5,a5,-1
    80000c36:	0007871b          	sext.w	a4,a5
    80000c3a:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c3c:	eb09                	bnez	a4,80000c4e <pop_off+0x38>
    80000c3e:	5d7c                	lw	a5,124(a0)
    80000c40:	c799                	beqz	a5,80000c4e <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c42:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c46:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c4a:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c4e:	60a2                	ld	ra,8(sp)
    80000c50:	6402                	ld	s0,0(sp)
    80000c52:	0141                	addi	sp,sp,16
    80000c54:	8082                	ret
    panic("pop_off - interruptible");
    80000c56:	00007517          	auipc	a0,0x7
    80000c5a:	42250513          	addi	a0,a0,1058 # 80008078 <digits+0x38>
    80000c5e:	00000097          	auipc	ra,0x0
    80000c62:	8cc080e7          	jalr	-1844(ra) # 8000052a <panic>
    panic("pop_off");
    80000c66:	00007517          	auipc	a0,0x7
    80000c6a:	42a50513          	addi	a0,a0,1066 # 80008090 <digits+0x50>
    80000c6e:	00000097          	auipc	ra,0x0
    80000c72:	8bc080e7          	jalr	-1860(ra) # 8000052a <panic>

0000000080000c76 <release>:
{
    80000c76:	1101                	addi	sp,sp,-32
    80000c78:	ec06                	sd	ra,24(sp)
    80000c7a:	e822                	sd	s0,16(sp)
    80000c7c:	e426                	sd	s1,8(sp)
    80000c7e:	1000                	addi	s0,sp,32
    80000c80:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	ec6080e7          	jalr	-314(ra) # 80000b48 <holding>
    80000c8a:	c115                	beqz	a0,80000cae <release+0x38>
  lk->cpu = 0;
    80000c8c:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000c90:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000c94:	0f50000f          	fence	iorw,ow
    80000c98:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000c9c:	00000097          	auipc	ra,0x0
    80000ca0:	f7a080e7          	jalr	-134(ra) # 80000c16 <pop_off>
}
    80000ca4:	60e2                	ld	ra,24(sp)
    80000ca6:	6442                	ld	s0,16(sp)
    80000ca8:	64a2                	ld	s1,8(sp)
    80000caa:	6105                	addi	sp,sp,32
    80000cac:	8082                	ret
    panic("release");
    80000cae:	00007517          	auipc	a0,0x7
    80000cb2:	3ea50513          	addi	a0,a0,1002 # 80008098 <digits+0x58>
    80000cb6:	00000097          	auipc	ra,0x0
    80000cba:	874080e7          	jalr	-1932(ra) # 8000052a <panic>

0000000080000cbe <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cbe:	1141                	addi	sp,sp,-16
    80000cc0:	e422                	sd	s0,8(sp)
    80000cc2:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cc4:	ca19                	beqz	a2,80000cda <memset+0x1c>
    80000cc6:	87aa                	mv	a5,a0
    80000cc8:	1602                	slli	a2,a2,0x20
    80000cca:	9201                	srli	a2,a2,0x20
    80000ccc:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000cd0:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cd4:	0785                	addi	a5,a5,1
    80000cd6:	fee79de3          	bne	a5,a4,80000cd0 <memset+0x12>
  }
  return dst;
}
    80000cda:	6422                	ld	s0,8(sp)
    80000cdc:	0141                	addi	sp,sp,16
    80000cde:	8082                	ret

0000000080000ce0 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000ce0:	1141                	addi	sp,sp,-16
    80000ce2:	e422                	sd	s0,8(sp)
    80000ce4:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000ce6:	ca05                	beqz	a2,80000d16 <memcmp+0x36>
    80000ce8:	fff6069b          	addiw	a3,a2,-1
    80000cec:	1682                	slli	a3,a3,0x20
    80000cee:	9281                	srli	a3,a3,0x20
    80000cf0:	0685                	addi	a3,a3,1
    80000cf2:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000cf4:	00054783          	lbu	a5,0(a0)
    80000cf8:	0005c703          	lbu	a4,0(a1)
    80000cfc:	00e79863          	bne	a5,a4,80000d0c <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d00:	0505                	addi	a0,a0,1
    80000d02:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d04:	fed518e3          	bne	a0,a3,80000cf4 <memcmp+0x14>
  }

  return 0;
    80000d08:	4501                	li	a0,0
    80000d0a:	a019                	j	80000d10 <memcmp+0x30>
      return *s1 - *s2;
    80000d0c:	40e7853b          	subw	a0,a5,a4
}
    80000d10:	6422                	ld	s0,8(sp)
    80000d12:	0141                	addi	sp,sp,16
    80000d14:	8082                	ret
  return 0;
    80000d16:	4501                	li	a0,0
    80000d18:	bfe5                	j	80000d10 <memcmp+0x30>

0000000080000d1a <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d1a:	1141                	addi	sp,sp,-16
    80000d1c:	e422                	sd	s0,8(sp)
    80000d1e:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d20:	02a5e563          	bltu	a1,a0,80000d4a <memmove+0x30>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d24:	fff6069b          	addiw	a3,a2,-1
    80000d28:	ce11                	beqz	a2,80000d44 <memmove+0x2a>
    80000d2a:	1682                	slli	a3,a3,0x20
    80000d2c:	9281                	srli	a3,a3,0x20
    80000d2e:	0685                	addi	a3,a3,1
    80000d30:	96ae                	add	a3,a3,a1
    80000d32:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000d34:	0585                	addi	a1,a1,1
    80000d36:	0785                	addi	a5,a5,1
    80000d38:	fff5c703          	lbu	a4,-1(a1)
    80000d3c:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000d40:	fed59ae3          	bne	a1,a3,80000d34 <memmove+0x1a>

  return dst;
}
    80000d44:	6422                	ld	s0,8(sp)
    80000d46:	0141                	addi	sp,sp,16
    80000d48:	8082                	ret
  if(s < d && s + n > d){
    80000d4a:	02061713          	slli	a4,a2,0x20
    80000d4e:	9301                	srli	a4,a4,0x20
    80000d50:	00e587b3          	add	a5,a1,a4
    80000d54:	fcf578e3          	bgeu	a0,a5,80000d24 <memmove+0xa>
    d += n;
    80000d58:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000d5a:	fff6069b          	addiw	a3,a2,-1
    80000d5e:	d27d                	beqz	a2,80000d44 <memmove+0x2a>
    80000d60:	02069613          	slli	a2,a3,0x20
    80000d64:	9201                	srli	a2,a2,0x20
    80000d66:	fff64613          	not	a2,a2
    80000d6a:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000d6c:	17fd                	addi	a5,a5,-1
    80000d6e:	177d                	addi	a4,a4,-1
    80000d70:	0007c683          	lbu	a3,0(a5)
    80000d74:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000d78:	fef61ae3          	bne	a2,a5,80000d6c <memmove+0x52>
    80000d7c:	b7e1                	j	80000d44 <memmove+0x2a>

0000000080000d7e <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d7e:	1141                	addi	sp,sp,-16
    80000d80:	e406                	sd	ra,8(sp)
    80000d82:	e022                	sd	s0,0(sp)
    80000d84:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d86:	00000097          	auipc	ra,0x0
    80000d8a:	f94080e7          	jalr	-108(ra) # 80000d1a <memmove>
}
    80000d8e:	60a2                	ld	ra,8(sp)
    80000d90:	6402                	ld	s0,0(sp)
    80000d92:	0141                	addi	sp,sp,16
    80000d94:	8082                	ret

0000000080000d96 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000d96:	1141                	addi	sp,sp,-16
    80000d98:	e422                	sd	s0,8(sp)
    80000d9a:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000d9c:	ce11                	beqz	a2,80000db8 <strncmp+0x22>
    80000d9e:	00054783          	lbu	a5,0(a0)
    80000da2:	cf89                	beqz	a5,80000dbc <strncmp+0x26>
    80000da4:	0005c703          	lbu	a4,0(a1)
    80000da8:	00f71a63          	bne	a4,a5,80000dbc <strncmp+0x26>
    n--, p++, q++;
    80000dac:	367d                	addiw	a2,a2,-1
    80000dae:	0505                	addi	a0,a0,1
    80000db0:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000db2:	f675                	bnez	a2,80000d9e <strncmp+0x8>
  if(n == 0)
    return 0;
    80000db4:	4501                	li	a0,0
    80000db6:	a809                	j	80000dc8 <strncmp+0x32>
    80000db8:	4501                	li	a0,0
    80000dba:	a039                	j	80000dc8 <strncmp+0x32>
  if(n == 0)
    80000dbc:	ca09                	beqz	a2,80000dce <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dbe:	00054503          	lbu	a0,0(a0)
    80000dc2:	0005c783          	lbu	a5,0(a1)
    80000dc6:	9d1d                	subw	a0,a0,a5
}
    80000dc8:	6422                	ld	s0,8(sp)
    80000dca:	0141                	addi	sp,sp,16
    80000dcc:	8082                	ret
    return 0;
    80000dce:	4501                	li	a0,0
    80000dd0:	bfe5                	j	80000dc8 <strncmp+0x32>

0000000080000dd2 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dd2:	1141                	addi	sp,sp,-16
    80000dd4:	e422                	sd	s0,8(sp)
    80000dd6:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dd8:	872a                	mv	a4,a0
    80000dda:	8832                	mv	a6,a2
    80000ddc:	367d                	addiw	a2,a2,-1
    80000dde:	01005963          	blez	a6,80000df0 <strncpy+0x1e>
    80000de2:	0705                	addi	a4,a4,1
    80000de4:	0005c783          	lbu	a5,0(a1)
    80000de8:	fef70fa3          	sb	a5,-1(a4)
    80000dec:	0585                	addi	a1,a1,1
    80000dee:	f7f5                	bnez	a5,80000dda <strncpy+0x8>
    ;
  while(n-- > 0)
    80000df0:	86ba                	mv	a3,a4
    80000df2:	00c05c63          	blez	a2,80000e0a <strncpy+0x38>
    *s++ = 0;
    80000df6:	0685                	addi	a3,a3,1
    80000df8:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000dfc:	fff6c793          	not	a5,a3
    80000e00:	9fb9                	addw	a5,a5,a4
    80000e02:	010787bb          	addw	a5,a5,a6
    80000e06:	fef048e3          	bgtz	a5,80000df6 <strncpy+0x24>
  return os;
}
    80000e0a:	6422                	ld	s0,8(sp)
    80000e0c:	0141                	addi	sp,sp,16
    80000e0e:	8082                	ret

0000000080000e10 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e10:	1141                	addi	sp,sp,-16
    80000e12:	e422                	sd	s0,8(sp)
    80000e14:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e16:	02c05363          	blez	a2,80000e3c <safestrcpy+0x2c>
    80000e1a:	fff6069b          	addiw	a3,a2,-1
    80000e1e:	1682                	slli	a3,a3,0x20
    80000e20:	9281                	srli	a3,a3,0x20
    80000e22:	96ae                	add	a3,a3,a1
    80000e24:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e26:	00d58963          	beq	a1,a3,80000e38 <safestrcpy+0x28>
    80000e2a:	0585                	addi	a1,a1,1
    80000e2c:	0785                	addi	a5,a5,1
    80000e2e:	fff5c703          	lbu	a4,-1(a1)
    80000e32:	fee78fa3          	sb	a4,-1(a5)
    80000e36:	fb65                	bnez	a4,80000e26 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e38:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e3c:	6422                	ld	s0,8(sp)
    80000e3e:	0141                	addi	sp,sp,16
    80000e40:	8082                	ret

0000000080000e42 <strlen>:

int
strlen(const char *s)
{
    80000e42:	1141                	addi	sp,sp,-16
    80000e44:	e422                	sd	s0,8(sp)
    80000e46:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e48:	00054783          	lbu	a5,0(a0)
    80000e4c:	cf91                	beqz	a5,80000e68 <strlen+0x26>
    80000e4e:	0505                	addi	a0,a0,1
    80000e50:	87aa                	mv	a5,a0
    80000e52:	4685                	li	a3,1
    80000e54:	9e89                	subw	a3,a3,a0
    80000e56:	00f6853b          	addw	a0,a3,a5
    80000e5a:	0785                	addi	a5,a5,1
    80000e5c:	fff7c703          	lbu	a4,-1(a5)
    80000e60:	fb7d                	bnez	a4,80000e56 <strlen+0x14>
    ;
  return n;
}
    80000e62:	6422                	ld	s0,8(sp)
    80000e64:	0141                	addi	sp,sp,16
    80000e66:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e68:	4501                	li	a0,0
    80000e6a:	bfe5                	j	80000e62 <strlen+0x20>

0000000080000e6c <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e6c:	1141                	addi	sp,sp,-16
    80000e6e:	e406                	sd	ra,8(sp)
    80000e70:	e022                	sd	s0,0(sp)
    80000e72:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e74:	00001097          	auipc	ra,0x1
    80000e78:	b32080e7          	jalr	-1230(ra) # 800019a6 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e7c:	00008717          	auipc	a4,0x8
    80000e80:	19c70713          	addi	a4,a4,412 # 80009018 <started>
  if(cpuid() == 0){
    80000e84:	c139                	beqz	a0,80000eca <main+0x5e>
    while(started == 0)
    80000e86:	431c                	lw	a5,0(a4)
    80000e88:	2781                	sext.w	a5,a5
    80000e8a:	dff5                	beqz	a5,80000e86 <main+0x1a>
      ;
    __sync_synchronize();
    80000e8c:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e90:	00001097          	auipc	ra,0x1
    80000e94:	b16080e7          	jalr	-1258(ra) # 800019a6 <cpuid>
    80000e98:	85aa                	mv	a1,a0
    80000e9a:	00007517          	auipc	a0,0x7
    80000e9e:	21e50513          	addi	a0,a0,542 # 800080b8 <digits+0x78>
    80000ea2:	fffff097          	auipc	ra,0xfffff
    80000ea6:	6d2080e7          	jalr	1746(ra) # 80000574 <printf>
    kvminithart();    // turn on paging
    80000eaa:	00000097          	auipc	ra,0x0
    80000eae:	0d8080e7          	jalr	216(ra) # 80000f82 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eb2:	00001097          	auipc	ra,0x1
    80000eb6:	772080e7          	jalr	1906(ra) # 80002624 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000eba:	00005097          	auipc	ra,0x5
    80000ebe:	d66080e7          	jalr	-666(ra) # 80005c20 <plicinithart>
  }

  scheduler();        
    80000ec2:	00001097          	auipc	ra,0x1
    80000ec6:	01e080e7          	jalr	30(ra) # 80001ee0 <scheduler>
    consoleinit();
    80000eca:	fffff097          	auipc	ra,0xfffff
    80000ece:	572080e7          	jalr	1394(ra) # 8000043c <consoleinit>
    printfinit();
    80000ed2:	00000097          	auipc	ra,0x0
    80000ed6:	882080e7          	jalr	-1918(ra) # 80000754 <printfinit>
    printf("\n");
    80000eda:	00007517          	auipc	a0,0x7
    80000ede:	1ee50513          	addi	a0,a0,494 # 800080c8 <digits+0x88>
    80000ee2:	fffff097          	auipc	ra,0xfffff
    80000ee6:	692080e7          	jalr	1682(ra) # 80000574 <printf>
    printf("xv6 kernel is booting\n");
    80000eea:	00007517          	auipc	a0,0x7
    80000eee:	1b650513          	addi	a0,a0,438 # 800080a0 <digits+0x60>
    80000ef2:	fffff097          	auipc	ra,0xfffff
    80000ef6:	682080e7          	jalr	1666(ra) # 80000574 <printf>
    printf("\n");
    80000efa:	00007517          	auipc	a0,0x7
    80000efe:	1ce50513          	addi	a0,a0,462 # 800080c8 <digits+0x88>
    80000f02:	fffff097          	auipc	ra,0xfffff
    80000f06:	672080e7          	jalr	1650(ra) # 80000574 <printf>
    kinit();         // physical page allocator
    80000f0a:	00000097          	auipc	ra,0x0
    80000f0e:	b8c080e7          	jalr	-1140(ra) # 80000a96 <kinit>
    kvminit();       // create kernel page table
    80000f12:	00000097          	auipc	ra,0x0
    80000f16:	37e080e7          	jalr	894(ra) # 80001290 <kvminit>
    kvminithart();   // turn on paging
    80000f1a:	00000097          	auipc	ra,0x0
    80000f1e:	068080e7          	jalr	104(ra) # 80000f82 <kvminithart>
    procinit();      // process table
    80000f22:	00001097          	auipc	ra,0x1
    80000f26:	9d4080e7          	jalr	-1580(ra) # 800018f6 <procinit>
    trapinit();      // trap vectors
    80000f2a:	00001097          	auipc	ra,0x1
    80000f2e:	6d2080e7          	jalr	1746(ra) # 800025fc <trapinit>
    trapinithart();  // install kernel trap vector
    80000f32:	00001097          	auipc	ra,0x1
    80000f36:	6f2080e7          	jalr	1778(ra) # 80002624 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f3a:	00005097          	auipc	ra,0x5
    80000f3e:	cd0080e7          	jalr	-816(ra) # 80005c0a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f42:	00005097          	auipc	ra,0x5
    80000f46:	cde080e7          	jalr	-802(ra) # 80005c20 <plicinithart>
    binit();         // buffer cache
    80000f4a:	00002097          	auipc	ra,0x2
    80000f4e:	ea2080e7          	jalr	-350(ra) # 80002dec <binit>
    iinit();         // inode cache
    80000f52:	00002097          	auipc	ra,0x2
    80000f56:	534080e7          	jalr	1332(ra) # 80003486 <iinit>
    fileinit();      // file table
    80000f5a:	00003097          	auipc	ra,0x3
    80000f5e:	4e2080e7          	jalr	1250(ra) # 8000443c <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f62:	00005097          	auipc	ra,0x5
    80000f66:	de0080e7          	jalr	-544(ra) # 80005d42 <virtio_disk_init>
    userinit();      // first user process
    80000f6a:	00001097          	auipc	ra,0x1
    80000f6e:	d40080e7          	jalr	-704(ra) # 80001caa <userinit>
    __sync_synchronize();
    80000f72:	0ff0000f          	fence
    started = 1;
    80000f76:	4785                	li	a5,1
    80000f78:	00008717          	auipc	a4,0x8
    80000f7c:	0af72023          	sw	a5,160(a4) # 80009018 <started>
    80000f80:	b789                	j	80000ec2 <main+0x56>

0000000080000f82 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f82:	1141                	addi	sp,sp,-16
    80000f84:	e422                	sd	s0,8(sp)
    80000f86:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000f88:	00008797          	auipc	a5,0x8
    80000f8c:	0987b783          	ld	a5,152(a5) # 80009020 <kernel_pagetable>
    80000f90:	83b1                	srli	a5,a5,0xc
    80000f92:	577d                	li	a4,-1
    80000f94:	177e                	slli	a4,a4,0x3f
    80000f96:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000f98:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f9c:	12000073          	sfence.vma
  sfence_vma();
}
    80000fa0:	6422                	ld	s0,8(sp)
    80000fa2:	0141                	addi	sp,sp,16
    80000fa4:	8082                	ret

0000000080000fa6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fa6:	7139                	addi	sp,sp,-64
    80000fa8:	fc06                	sd	ra,56(sp)
    80000faa:	f822                	sd	s0,48(sp)
    80000fac:	f426                	sd	s1,40(sp)
    80000fae:	f04a                	sd	s2,32(sp)
    80000fb0:	ec4e                	sd	s3,24(sp)
    80000fb2:	e852                	sd	s4,16(sp)
    80000fb4:	e456                	sd	s5,8(sp)
    80000fb6:	e05a                	sd	s6,0(sp)
    80000fb8:	0080                	addi	s0,sp,64
    80000fba:	84aa                	mv	s1,a0
    80000fbc:	89ae                	mv	s3,a1
    80000fbe:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fc0:	57fd                	li	a5,-1
    80000fc2:	83e9                	srli	a5,a5,0x1a
    80000fc4:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fc6:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fc8:	04b7f263          	bgeu	a5,a1,8000100c <walk+0x66>
    panic("walk");
    80000fcc:	00007517          	auipc	a0,0x7
    80000fd0:	10450513          	addi	a0,a0,260 # 800080d0 <digits+0x90>
    80000fd4:	fffff097          	auipc	ra,0xfffff
    80000fd8:	556080e7          	jalr	1366(ra) # 8000052a <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fdc:	060a8663          	beqz	s5,80001048 <walk+0xa2>
    80000fe0:	00000097          	auipc	ra,0x0
    80000fe4:	af2080e7          	jalr	-1294(ra) # 80000ad2 <kalloc>
    80000fe8:	84aa                	mv	s1,a0
    80000fea:	c529                	beqz	a0,80001034 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000fec:	6605                	lui	a2,0x1
    80000fee:	4581                	li	a1,0
    80000ff0:	00000097          	auipc	ra,0x0
    80000ff4:	cce080e7          	jalr	-818(ra) # 80000cbe <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80000ff8:	00c4d793          	srli	a5,s1,0xc
    80000ffc:	07aa                	slli	a5,a5,0xa
    80000ffe:	0017e793          	ori	a5,a5,1
    80001002:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001006:	3a5d                	addiw	s4,s4,-9
    80001008:	036a0063          	beq	s4,s6,80001028 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000100c:	0149d933          	srl	s2,s3,s4
    80001010:	1ff97913          	andi	s2,s2,511
    80001014:	090e                	slli	s2,s2,0x3
    80001016:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001018:	00093483          	ld	s1,0(s2)
    8000101c:	0014f793          	andi	a5,s1,1
    80001020:	dfd5                	beqz	a5,80000fdc <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001022:	80a9                	srli	s1,s1,0xa
    80001024:	04b2                	slli	s1,s1,0xc
    80001026:	b7c5                	j	80001006 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001028:	00c9d513          	srli	a0,s3,0xc
    8000102c:	1ff57513          	andi	a0,a0,511
    80001030:	050e                	slli	a0,a0,0x3
    80001032:	9526                	add	a0,a0,s1
}
    80001034:	70e2                	ld	ra,56(sp)
    80001036:	7442                	ld	s0,48(sp)
    80001038:	74a2                	ld	s1,40(sp)
    8000103a:	7902                	ld	s2,32(sp)
    8000103c:	69e2                	ld	s3,24(sp)
    8000103e:	6a42                	ld	s4,16(sp)
    80001040:	6aa2                	ld	s5,8(sp)
    80001042:	6b02                	ld	s6,0(sp)
    80001044:	6121                	addi	sp,sp,64
    80001046:	8082                	ret
        return 0;
    80001048:	4501                	li	a0,0
    8000104a:	b7ed                	j	80001034 <walk+0x8e>

000000008000104c <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000104c:	715d                	addi	sp,sp,-80
    8000104e:	e486                	sd	ra,72(sp)
    80001050:	e0a2                	sd	s0,64(sp)
    80001052:	fc26                	sd	s1,56(sp)
    80001054:	f84a                	sd	s2,48(sp)
    80001056:	f44e                	sd	s3,40(sp)
    80001058:	f052                	sd	s4,32(sp)
    8000105a:	ec56                	sd	s5,24(sp)
    8000105c:	e85a                	sd	s6,16(sp)
    8000105e:	e45e                	sd	s7,8(sp)
    80001060:	0880                	addi	s0,sp,80
    80001062:	8aaa                	mv	s5,a0
    80001064:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    80001066:	777d                	lui	a4,0xfffff
    80001068:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    8000106c:	167d                	addi	a2,a2,-1
    8000106e:	00b609b3          	add	s3,a2,a1
    80001072:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001076:	893e                	mv	s2,a5
    80001078:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    8000107c:	6b85                	lui	s7,0x1
    8000107e:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001082:	4605                	li	a2,1
    80001084:	85ca                	mv	a1,s2
    80001086:	8556                	mv	a0,s5
    80001088:	00000097          	auipc	ra,0x0
    8000108c:	f1e080e7          	jalr	-226(ra) # 80000fa6 <walk>
    80001090:	c51d                	beqz	a0,800010be <mappages+0x72>
    if(*pte & PTE_V)
    80001092:	611c                	ld	a5,0(a0)
    80001094:	8b85                	andi	a5,a5,1
    80001096:	ef81                	bnez	a5,800010ae <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001098:	80b1                	srli	s1,s1,0xc
    8000109a:	04aa                	slli	s1,s1,0xa
    8000109c:	0164e4b3          	or	s1,s1,s6
    800010a0:	0014e493          	ori	s1,s1,1
    800010a4:	e104                	sd	s1,0(a0)
    if(a == last)
    800010a6:	03390863          	beq	s2,s3,800010d6 <mappages+0x8a>
    a += PGSIZE;
    800010aa:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800010ac:	bfc9                	j	8000107e <mappages+0x32>
      panic("remap");
    800010ae:	00007517          	auipc	a0,0x7
    800010b2:	02a50513          	addi	a0,a0,42 # 800080d8 <digits+0x98>
    800010b6:	fffff097          	auipc	ra,0xfffff
    800010ba:	474080e7          	jalr	1140(ra) # 8000052a <panic>
      return -1;
    800010be:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800010c0:	60a6                	ld	ra,72(sp)
    800010c2:	6406                	ld	s0,64(sp)
    800010c4:	74e2                	ld	s1,56(sp)
    800010c6:	7942                	ld	s2,48(sp)
    800010c8:	79a2                	ld	s3,40(sp)
    800010ca:	7a02                	ld	s4,32(sp)
    800010cc:	6ae2                	ld	s5,24(sp)
    800010ce:	6b42                	ld	s6,16(sp)
    800010d0:	6ba2                	ld	s7,8(sp)
    800010d2:	6161                	addi	sp,sp,80
    800010d4:	8082                	ret
  return 0;
    800010d6:	4501                	li	a0,0
    800010d8:	b7e5                	j	800010c0 <mappages+0x74>

00000000800010da <walkaddr>:
  if(va >= MAXVA)
    800010da:	57fd                	li	a5,-1
    800010dc:	83e9                	srli	a5,a5,0x1a
    800010de:	00b7f463          	bgeu	a5,a1,800010e6 <walkaddr+0xc>
    return 0;
    800010e2:	4501                	li	a0,0
}
    800010e4:	8082                	ret
{
    800010e6:	7179                	addi	sp,sp,-48
    800010e8:	f406                	sd	ra,40(sp)
    800010ea:	f022                	sd	s0,32(sp)
    800010ec:	ec26                	sd	s1,24(sp)
    800010ee:	e84a                	sd	s2,16(sp)
    800010f0:	e44e                	sd	s3,8(sp)
    800010f2:	1800                	addi	s0,sp,48
    800010f4:	892a                	mv	s2,a0
    800010f6:	84ae                	mv	s1,a1
  pte = walk(pagetable, va, 0);
    800010f8:	4601                	li	a2,0
    800010fa:	00000097          	auipc	ra,0x0
    800010fe:	eac080e7          	jalr	-340(ra) # 80000fa6 <walk>
  if(pte == 0 || (*pte & PTE_V) == 0){
    80001102:	c509                	beqz	a0,8000110c <walkaddr+0x32>
    80001104:	611c                	ld	a5,0(a0)
    80001106:	0017f713          	andi	a4,a5,1
    8000110a:	e73d                	bnez	a4,80001178 <walkaddr+0x9e>
    if(va > myproc()->sz)
    8000110c:	00001097          	auipc	ra,0x1
    80001110:	8c6080e7          	jalr	-1850(ra) # 800019d2 <myproc>
    80001114:	653c                	ld	a5,72(a0)
      return 0;
    80001116:	4501                	li	a0,0
    if(va > myproc()->sz)
    80001118:	0097f963          	bgeu	a5,s1,8000112a <walkaddr+0x50>
}
    8000111c:	70a2                	ld	ra,40(sp)
    8000111e:	7402                	ld	s0,32(sp)
    80001120:	64e2                	ld	s1,24(sp)
    80001122:	6942                	ld	s2,16(sp)
    80001124:	69a2                	ld	s3,8(sp)
    80001126:	6145                	addi	sp,sp,48
    80001128:	8082                	ret
    char *mem = kalloc(); // allocate a new page lazily
    8000112a:	00000097          	auipc	ra,0x0
    8000112e:	9a8080e7          	jalr	-1624(ra) # 80000ad2 <kalloc>
    80001132:	89aa                	mv	s3,a0
    if(mem == 0)
    80001134:	c929                	beqz	a0,80001186 <walkaddr+0xac>
    memset(mem, 0, PGSIZE);
    80001136:	6605                	lui	a2,0x1
    80001138:	4581                	li	a1,0
    8000113a:	00000097          	auipc	ra,0x0
    8000113e:	b84080e7          	jalr	-1148(ra) # 80000cbe <memset>
    if(mappages(pagetable, va2, PGSIZE, (uint64)mem, PTE_U | PTE_R | PTE_W | PTE_V) != 0){
    80001142:	475d                	li	a4,23
    80001144:	86ce                	mv	a3,s3
    80001146:	6605                	lui	a2,0x1
    80001148:	75fd                	lui	a1,0xfffff
    8000114a:	8de5                	and	a1,a1,s1
    8000114c:	854a                	mv	a0,s2
    8000114e:	00000097          	auipc	ra,0x0
    80001152:	efe080e7          	jalr	-258(ra) # 8000104c <mappages>
    80001156:	e501                	bnez	a0,8000115e <walkaddr+0x84>
      return (uint64)*mem;
    80001158:	0009c503          	lbu	a0,0(s3) # 1000 <_entry-0x7ffff000>
    8000115c:	b7c1                	j	8000111c <walkaddr+0x42>
      kfree(mem);
    8000115e:	854e                	mv	a0,s3
    80001160:	00000097          	auipc	ra,0x0
    80001164:	876080e7          	jalr	-1930(ra) # 800009d6 <kfree>
      panic("walkaddr: mappages");
    80001168:	00007517          	auipc	a0,0x7
    8000116c:	f7850513          	addi	a0,a0,-136 # 800080e0 <digits+0xa0>
    80001170:	fffff097          	auipc	ra,0xfffff
    80001174:	3ba080e7          	jalr	954(ra) # 8000052a <panic>
  if((*pte & PTE_U) == 0)
    80001178:	0107f513          	andi	a0,a5,16
    8000117c:	d145                	beqz	a0,8000111c <walkaddr+0x42>
  pa = PTE2PA(*pte);
    8000117e:	00a7d513          	srli	a0,a5,0xa
    80001182:	0532                	slli	a0,a0,0xc
  return pa;
    80001184:	bf61                	j	8000111c <walkaddr+0x42>
      return 0;
    80001186:	4501                	li	a0,0
    80001188:	bf51                	j	8000111c <walkaddr+0x42>

000000008000118a <kvmmap>:
{
    8000118a:	1141                	addi	sp,sp,-16
    8000118c:	e406                	sd	ra,8(sp)
    8000118e:	e022                	sd	s0,0(sp)
    80001190:	0800                	addi	s0,sp,16
    80001192:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001194:	86b2                	mv	a3,a2
    80001196:	863e                	mv	a2,a5
    80001198:	00000097          	auipc	ra,0x0
    8000119c:	eb4080e7          	jalr	-332(ra) # 8000104c <mappages>
    800011a0:	e509                	bnez	a0,800011aa <kvmmap+0x20>
}
    800011a2:	60a2                	ld	ra,8(sp)
    800011a4:	6402                	ld	s0,0(sp)
    800011a6:	0141                	addi	sp,sp,16
    800011a8:	8082                	ret
    panic("kvmmap");
    800011aa:	00007517          	auipc	a0,0x7
    800011ae:	f4e50513          	addi	a0,a0,-178 # 800080f8 <digits+0xb8>
    800011b2:	fffff097          	auipc	ra,0xfffff
    800011b6:	378080e7          	jalr	888(ra) # 8000052a <panic>

00000000800011ba <kvmmake>:
{
    800011ba:	1101                	addi	sp,sp,-32
    800011bc:	ec06                	sd	ra,24(sp)
    800011be:	e822                	sd	s0,16(sp)
    800011c0:	e426                	sd	s1,8(sp)
    800011c2:	e04a                	sd	s2,0(sp)
    800011c4:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    800011c6:	00000097          	auipc	ra,0x0
    800011ca:	90c080e7          	jalr	-1780(ra) # 80000ad2 <kalloc>
    800011ce:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800011d0:	6605                	lui	a2,0x1
    800011d2:	4581                	li	a1,0
    800011d4:	00000097          	auipc	ra,0x0
    800011d8:	aea080e7          	jalr	-1302(ra) # 80000cbe <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011dc:	4719                	li	a4,6
    800011de:	6685                	lui	a3,0x1
    800011e0:	10000637          	lui	a2,0x10000
    800011e4:	100005b7          	lui	a1,0x10000
    800011e8:	8526                	mv	a0,s1
    800011ea:	00000097          	auipc	ra,0x0
    800011ee:	fa0080e7          	jalr	-96(ra) # 8000118a <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011f2:	4719                	li	a4,6
    800011f4:	6685                	lui	a3,0x1
    800011f6:	10001637          	lui	a2,0x10001
    800011fa:	100015b7          	lui	a1,0x10001
    800011fe:	8526                	mv	a0,s1
    80001200:	00000097          	auipc	ra,0x0
    80001204:	f8a080e7          	jalr	-118(ra) # 8000118a <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001208:	4719                	li	a4,6
    8000120a:	004006b7          	lui	a3,0x400
    8000120e:	0c000637          	lui	a2,0xc000
    80001212:	0c0005b7          	lui	a1,0xc000
    80001216:	8526                	mv	a0,s1
    80001218:	00000097          	auipc	ra,0x0
    8000121c:	f72080e7          	jalr	-142(ra) # 8000118a <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001220:	00007917          	auipc	s2,0x7
    80001224:	de090913          	addi	s2,s2,-544 # 80008000 <etext>
    80001228:	4729                	li	a4,10
    8000122a:	80007697          	auipc	a3,0x80007
    8000122e:	dd668693          	addi	a3,a3,-554 # 8000 <_entry-0x7fff8000>
    80001232:	4605                	li	a2,1
    80001234:	067e                	slli	a2,a2,0x1f
    80001236:	85b2                	mv	a1,a2
    80001238:	8526                	mv	a0,s1
    8000123a:	00000097          	auipc	ra,0x0
    8000123e:	f50080e7          	jalr	-176(ra) # 8000118a <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001242:	4719                	li	a4,6
    80001244:	46c5                	li	a3,17
    80001246:	06ee                	slli	a3,a3,0x1b
    80001248:	412686b3          	sub	a3,a3,s2
    8000124c:	864a                	mv	a2,s2
    8000124e:	85ca                	mv	a1,s2
    80001250:	8526                	mv	a0,s1
    80001252:	00000097          	auipc	ra,0x0
    80001256:	f38080e7          	jalr	-200(ra) # 8000118a <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000125a:	4729                	li	a4,10
    8000125c:	6685                	lui	a3,0x1
    8000125e:	00006617          	auipc	a2,0x6
    80001262:	da260613          	addi	a2,a2,-606 # 80007000 <_trampoline>
    80001266:	040005b7          	lui	a1,0x4000
    8000126a:	15fd                	addi	a1,a1,-1
    8000126c:	05b2                	slli	a1,a1,0xc
    8000126e:	8526                	mv	a0,s1
    80001270:	00000097          	auipc	ra,0x0
    80001274:	f1a080e7          	jalr	-230(ra) # 8000118a <kvmmap>
  proc_mapstacks(kpgtbl);
    80001278:	8526                	mv	a0,s1
    8000127a:	00000097          	auipc	ra,0x0
    8000127e:	5e6080e7          	jalr	1510(ra) # 80001860 <proc_mapstacks>
}
    80001282:	8526                	mv	a0,s1
    80001284:	60e2                	ld	ra,24(sp)
    80001286:	6442                	ld	s0,16(sp)
    80001288:	64a2                	ld	s1,8(sp)
    8000128a:	6902                	ld	s2,0(sp)
    8000128c:	6105                	addi	sp,sp,32
    8000128e:	8082                	ret

0000000080001290 <kvminit>:
{
    80001290:	1141                	addi	sp,sp,-16
    80001292:	e406                	sd	ra,8(sp)
    80001294:	e022                	sd	s0,0(sp)
    80001296:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001298:	00000097          	auipc	ra,0x0
    8000129c:	f22080e7          	jalr	-222(ra) # 800011ba <kvmmake>
    800012a0:	00008797          	auipc	a5,0x8
    800012a4:	d8a7b023          	sd	a0,-640(a5) # 80009020 <kernel_pagetable>
}
    800012a8:	60a2                	ld	ra,8(sp)
    800012aa:	6402                	ld	s0,0(sp)
    800012ac:	0141                	addi	sp,sp,16
    800012ae:	8082                	ret

00000000800012b0 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800012b0:	715d                	addi	sp,sp,-80
    800012b2:	e486                	sd	ra,72(sp)
    800012b4:	e0a2                	sd	s0,64(sp)
    800012b6:	fc26                	sd	s1,56(sp)
    800012b8:	f84a                	sd	s2,48(sp)
    800012ba:	f44e                	sd	s3,40(sp)
    800012bc:	f052                	sd	s4,32(sp)
    800012be:	ec56                	sd	s5,24(sp)
    800012c0:	e85a                	sd	s6,16(sp)
    800012c2:	e45e                	sd	s7,8(sp)
    800012c4:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800012c6:	03459793          	slli	a5,a1,0x34
    800012ca:	e795                	bnez	a5,800012f6 <uvmunmap+0x46>
    800012cc:	8a2a                	mv	s4,a0
    800012ce:	892e                	mv	s2,a1
    800012d0:	8b36                	mv	s6,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012d2:	0632                	slli	a2,a2,0xc
    800012d4:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0) continue; // lazy allocation
      //panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012d8:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012da:	6a85                	lui	s5,0x1
    800012dc:	0535ea63          	bltu	a1,s3,80001330 <uvmunmap+0x80>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012e0:	60a6                	ld	ra,72(sp)
    800012e2:	6406                	ld	s0,64(sp)
    800012e4:	74e2                	ld	s1,56(sp)
    800012e6:	7942                	ld	s2,48(sp)
    800012e8:	79a2                	ld	s3,40(sp)
    800012ea:	7a02                	ld	s4,32(sp)
    800012ec:	6ae2                	ld	s5,24(sp)
    800012ee:	6b42                	ld	s6,16(sp)
    800012f0:	6ba2                	ld	s7,8(sp)
    800012f2:	6161                	addi	sp,sp,80
    800012f4:	8082                	ret
    panic("uvmunmap: not aligned");
    800012f6:	00007517          	auipc	a0,0x7
    800012fa:	e0a50513          	addi	a0,a0,-502 # 80008100 <digits+0xc0>
    800012fe:	fffff097          	auipc	ra,0xfffff
    80001302:	22c080e7          	jalr	556(ra) # 8000052a <panic>
      panic("uvmunmap: walk");
    80001306:	00007517          	auipc	a0,0x7
    8000130a:	e1250513          	addi	a0,a0,-494 # 80008118 <digits+0xd8>
    8000130e:	fffff097          	auipc	ra,0xfffff
    80001312:	21c080e7          	jalr	540(ra) # 8000052a <panic>
      panic("uvmunmap: not a leaf");
    80001316:	00007517          	auipc	a0,0x7
    8000131a:	e1250513          	addi	a0,a0,-494 # 80008128 <digits+0xe8>
    8000131e:	fffff097          	auipc	ra,0xfffff
    80001322:	20c080e7          	jalr	524(ra) # 8000052a <panic>
    *pte = 0;
    80001326:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000132a:	9956                	add	s2,s2,s5
    8000132c:	fb397ae3          	bgeu	s2,s3,800012e0 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001330:	4601                	li	a2,0
    80001332:	85ca                	mv	a1,s2
    80001334:	8552                	mv	a0,s4
    80001336:	00000097          	auipc	ra,0x0
    8000133a:	c70080e7          	jalr	-912(ra) # 80000fa6 <walk>
    8000133e:	84aa                	mv	s1,a0
    80001340:	d179                	beqz	a0,80001306 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0) continue; // lazy allocation
    80001342:	611c                	ld	a5,0(a0)
    80001344:	0017f713          	andi	a4,a5,1
    80001348:	d36d                	beqz	a4,8000132a <uvmunmap+0x7a>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000134a:	3ff7f713          	andi	a4,a5,1023
    8000134e:	fd7704e3          	beq	a4,s7,80001316 <uvmunmap+0x66>
    if(do_free){
    80001352:	fc0b0ae3          	beqz	s6,80001326 <uvmunmap+0x76>
      uint64 pa = PTE2PA(*pte);
    80001356:	83a9                	srli	a5,a5,0xa
      kfree((void*)pa);
    80001358:	00c79513          	slli	a0,a5,0xc
    8000135c:	fffff097          	auipc	ra,0xfffff
    80001360:	67a080e7          	jalr	1658(ra) # 800009d6 <kfree>
    80001364:	b7c9                	j	80001326 <uvmunmap+0x76>

0000000080001366 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001366:	1101                	addi	sp,sp,-32
    80001368:	ec06                	sd	ra,24(sp)
    8000136a:	e822                	sd	s0,16(sp)
    8000136c:	e426                	sd	s1,8(sp)
    8000136e:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001370:	fffff097          	auipc	ra,0xfffff
    80001374:	762080e7          	jalr	1890(ra) # 80000ad2 <kalloc>
    80001378:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000137a:	c519                	beqz	a0,80001388 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000137c:	6605                	lui	a2,0x1
    8000137e:	4581                	li	a1,0
    80001380:	00000097          	auipc	ra,0x0
    80001384:	93e080e7          	jalr	-1730(ra) # 80000cbe <memset>
  return pagetable;
}
    80001388:	8526                	mv	a0,s1
    8000138a:	60e2                	ld	ra,24(sp)
    8000138c:	6442                	ld	s0,16(sp)
    8000138e:	64a2                	ld	s1,8(sp)
    80001390:	6105                	addi	sp,sp,32
    80001392:	8082                	ret

0000000080001394 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001394:	7179                	addi	sp,sp,-48
    80001396:	f406                	sd	ra,40(sp)
    80001398:	f022                	sd	s0,32(sp)
    8000139a:	ec26                	sd	s1,24(sp)
    8000139c:	e84a                	sd	s2,16(sp)
    8000139e:	e44e                	sd	s3,8(sp)
    800013a0:	e052                	sd	s4,0(sp)
    800013a2:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800013a4:	6785                	lui	a5,0x1
    800013a6:	04f67863          	bgeu	a2,a5,800013f6 <uvminit+0x62>
    800013aa:	8a2a                	mv	s4,a0
    800013ac:	89ae                	mv	s3,a1
    800013ae:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    800013b0:	fffff097          	auipc	ra,0xfffff
    800013b4:	722080e7          	jalr	1826(ra) # 80000ad2 <kalloc>
    800013b8:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800013ba:	6605                	lui	a2,0x1
    800013bc:	4581                	li	a1,0
    800013be:	00000097          	auipc	ra,0x0
    800013c2:	900080e7          	jalr	-1792(ra) # 80000cbe <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013c6:	4779                	li	a4,30
    800013c8:	86ca                	mv	a3,s2
    800013ca:	6605                	lui	a2,0x1
    800013cc:	4581                	li	a1,0
    800013ce:	8552                	mv	a0,s4
    800013d0:	00000097          	auipc	ra,0x0
    800013d4:	c7c080e7          	jalr	-900(ra) # 8000104c <mappages>
  memmove(mem, src, sz);
    800013d8:	8626                	mv	a2,s1
    800013da:	85ce                	mv	a1,s3
    800013dc:	854a                	mv	a0,s2
    800013de:	00000097          	auipc	ra,0x0
    800013e2:	93c080e7          	jalr	-1732(ra) # 80000d1a <memmove>
}
    800013e6:	70a2                	ld	ra,40(sp)
    800013e8:	7402                	ld	s0,32(sp)
    800013ea:	64e2                	ld	s1,24(sp)
    800013ec:	6942                	ld	s2,16(sp)
    800013ee:	69a2                	ld	s3,8(sp)
    800013f0:	6a02                	ld	s4,0(sp)
    800013f2:	6145                	addi	sp,sp,48
    800013f4:	8082                	ret
    panic("inituvm: more than a page");
    800013f6:	00007517          	auipc	a0,0x7
    800013fa:	d4a50513          	addi	a0,a0,-694 # 80008140 <digits+0x100>
    800013fe:	fffff097          	auipc	ra,0xfffff
    80001402:	12c080e7          	jalr	300(ra) # 8000052a <panic>

0000000080001406 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001406:	1101                	addi	sp,sp,-32
    80001408:	ec06                	sd	ra,24(sp)
    8000140a:	e822                	sd	s0,16(sp)
    8000140c:	e426                	sd	s1,8(sp)
    8000140e:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001410:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001412:	00b67d63          	bgeu	a2,a1,8000142c <uvmdealloc+0x26>
    80001416:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001418:	6785                	lui	a5,0x1
    8000141a:	17fd                	addi	a5,a5,-1
    8000141c:	00f60733          	add	a4,a2,a5
    80001420:	767d                	lui	a2,0xfffff
    80001422:	8f71                	and	a4,a4,a2
    80001424:	97ae                	add	a5,a5,a1
    80001426:	8ff1                	and	a5,a5,a2
    80001428:	00f76863          	bltu	a4,a5,80001438 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    8000142c:	8526                	mv	a0,s1
    8000142e:	60e2                	ld	ra,24(sp)
    80001430:	6442                	ld	s0,16(sp)
    80001432:	64a2                	ld	s1,8(sp)
    80001434:	6105                	addi	sp,sp,32
    80001436:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001438:	8f99                	sub	a5,a5,a4
    8000143a:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    8000143c:	4685                	li	a3,1
    8000143e:	0007861b          	sext.w	a2,a5
    80001442:	85ba                	mv	a1,a4
    80001444:	00000097          	auipc	ra,0x0
    80001448:	e6c080e7          	jalr	-404(ra) # 800012b0 <uvmunmap>
    8000144c:	b7c5                	j	8000142c <uvmdealloc+0x26>

000000008000144e <uvmalloc>:
  if(newsz < oldsz)
    8000144e:	0ab66163          	bltu	a2,a1,800014f0 <uvmalloc+0xa2>
{
    80001452:	7139                	addi	sp,sp,-64
    80001454:	fc06                	sd	ra,56(sp)
    80001456:	f822                	sd	s0,48(sp)
    80001458:	f426                	sd	s1,40(sp)
    8000145a:	f04a                	sd	s2,32(sp)
    8000145c:	ec4e                	sd	s3,24(sp)
    8000145e:	e852                	sd	s4,16(sp)
    80001460:	e456                	sd	s5,8(sp)
    80001462:	0080                	addi	s0,sp,64
    80001464:	8aaa                	mv	s5,a0
    80001466:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001468:	6985                	lui	s3,0x1
    8000146a:	19fd                	addi	s3,s3,-1
    8000146c:	95ce                	add	a1,a1,s3
    8000146e:	79fd                	lui	s3,0xfffff
    80001470:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001474:	08c9f063          	bgeu	s3,a2,800014f4 <uvmalloc+0xa6>
    80001478:	894e                	mv	s2,s3
    mem = kalloc();
    8000147a:	fffff097          	auipc	ra,0xfffff
    8000147e:	658080e7          	jalr	1624(ra) # 80000ad2 <kalloc>
    80001482:	84aa                	mv	s1,a0
    if(mem == 0){
    80001484:	c51d                	beqz	a0,800014b2 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001486:	6605                	lui	a2,0x1
    80001488:	4581                	li	a1,0
    8000148a:	00000097          	auipc	ra,0x0
    8000148e:	834080e7          	jalr	-1996(ra) # 80000cbe <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001492:	4779                	li	a4,30
    80001494:	86a6                	mv	a3,s1
    80001496:	6605                	lui	a2,0x1
    80001498:	85ca                	mv	a1,s2
    8000149a:	8556                	mv	a0,s5
    8000149c:	00000097          	auipc	ra,0x0
    800014a0:	bb0080e7          	jalr	-1104(ra) # 8000104c <mappages>
    800014a4:	e905                	bnez	a0,800014d4 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014a6:	6785                	lui	a5,0x1
    800014a8:	993e                	add	s2,s2,a5
    800014aa:	fd4968e3          	bltu	s2,s4,8000147a <uvmalloc+0x2c>
  return newsz;
    800014ae:	8552                	mv	a0,s4
    800014b0:	a809                	j	800014c2 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    800014b2:	864e                	mv	a2,s3
    800014b4:	85ca                	mv	a1,s2
    800014b6:	8556                	mv	a0,s5
    800014b8:	00000097          	auipc	ra,0x0
    800014bc:	f4e080e7          	jalr	-178(ra) # 80001406 <uvmdealloc>
      return 0;
    800014c0:	4501                	li	a0,0
}
    800014c2:	70e2                	ld	ra,56(sp)
    800014c4:	7442                	ld	s0,48(sp)
    800014c6:	74a2                	ld	s1,40(sp)
    800014c8:	7902                	ld	s2,32(sp)
    800014ca:	69e2                	ld	s3,24(sp)
    800014cc:	6a42                	ld	s4,16(sp)
    800014ce:	6aa2                	ld	s5,8(sp)
    800014d0:	6121                	addi	sp,sp,64
    800014d2:	8082                	ret
      kfree(mem);
    800014d4:	8526                	mv	a0,s1
    800014d6:	fffff097          	auipc	ra,0xfffff
    800014da:	500080e7          	jalr	1280(ra) # 800009d6 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014de:	864e                	mv	a2,s3
    800014e0:	85ca                	mv	a1,s2
    800014e2:	8556                	mv	a0,s5
    800014e4:	00000097          	auipc	ra,0x0
    800014e8:	f22080e7          	jalr	-222(ra) # 80001406 <uvmdealloc>
      return 0;
    800014ec:	4501                	li	a0,0
    800014ee:	bfd1                	j	800014c2 <uvmalloc+0x74>
    return oldsz;
    800014f0:	852e                	mv	a0,a1
}
    800014f2:	8082                	ret
  return newsz;
    800014f4:	8532                	mv	a0,a2
    800014f6:	b7f1                	j	800014c2 <uvmalloc+0x74>

00000000800014f8 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014f8:	7179                	addi	sp,sp,-48
    800014fa:	f406                	sd	ra,40(sp)
    800014fc:	f022                	sd	s0,32(sp)
    800014fe:	ec26                	sd	s1,24(sp)
    80001500:	e84a                	sd	s2,16(sp)
    80001502:	e44e                	sd	s3,8(sp)
    80001504:	e052                	sd	s4,0(sp)
    80001506:	1800                	addi	s0,sp,48
    80001508:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000150a:	84aa                	mv	s1,a0
    8000150c:	6905                	lui	s2,0x1
    8000150e:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001510:	4985                	li	s3,1
    80001512:	a821                	j	8000152a <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001514:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80001516:	0532                	slli	a0,a0,0xc
    80001518:	00000097          	auipc	ra,0x0
    8000151c:	fe0080e7          	jalr	-32(ra) # 800014f8 <freewalk>
      pagetable[i] = 0;
    80001520:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001524:	04a1                	addi	s1,s1,8
    80001526:	03248163          	beq	s1,s2,80001548 <freewalk+0x50>
    pte_t pte = pagetable[i];
    8000152a:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000152c:	00f57793          	andi	a5,a0,15
    80001530:	ff3782e3          	beq	a5,s3,80001514 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001534:	8905                	andi	a0,a0,1
    80001536:	d57d                	beqz	a0,80001524 <freewalk+0x2c>
      panic("freewalk: leaf");
    80001538:	00007517          	auipc	a0,0x7
    8000153c:	c2850513          	addi	a0,a0,-984 # 80008160 <digits+0x120>
    80001540:	fffff097          	auipc	ra,0xfffff
    80001544:	fea080e7          	jalr	-22(ra) # 8000052a <panic>
    }
  }
  kfree((void*)pagetable);
    80001548:	8552                	mv	a0,s4
    8000154a:	fffff097          	auipc	ra,0xfffff
    8000154e:	48c080e7          	jalr	1164(ra) # 800009d6 <kfree>
}
    80001552:	70a2                	ld	ra,40(sp)
    80001554:	7402                	ld	s0,32(sp)
    80001556:	64e2                	ld	s1,24(sp)
    80001558:	6942                	ld	s2,16(sp)
    8000155a:	69a2                	ld	s3,8(sp)
    8000155c:	6a02                	ld	s4,0(sp)
    8000155e:	6145                	addi	sp,sp,48
    80001560:	8082                	ret

0000000080001562 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001562:	1101                	addi	sp,sp,-32
    80001564:	ec06                	sd	ra,24(sp)
    80001566:	e822                	sd	s0,16(sp)
    80001568:	e426                	sd	s1,8(sp)
    8000156a:	1000                	addi	s0,sp,32
    8000156c:	84aa                	mv	s1,a0
  if(sz > 0)
    8000156e:	e999                	bnez	a1,80001584 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001570:	8526                	mv	a0,s1
    80001572:	00000097          	auipc	ra,0x0
    80001576:	f86080e7          	jalr	-122(ra) # 800014f8 <freewalk>
}
    8000157a:	60e2                	ld	ra,24(sp)
    8000157c:	6442                	ld	s0,16(sp)
    8000157e:	64a2                	ld	s1,8(sp)
    80001580:	6105                	addi	sp,sp,32
    80001582:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001584:	6605                	lui	a2,0x1
    80001586:	167d                	addi	a2,a2,-1
    80001588:	962e                	add	a2,a2,a1
    8000158a:	4685                	li	a3,1
    8000158c:	8231                	srli	a2,a2,0xc
    8000158e:	4581                	li	a1,0
    80001590:	00000097          	auipc	ra,0x0
    80001594:	d20080e7          	jalr	-736(ra) # 800012b0 <uvmunmap>
    80001598:	bfe1                	j	80001570 <uvmfree+0xe>

000000008000159a <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000159a:	c269                	beqz	a2,8000165c <uvmcopy+0xc2>
{
    8000159c:	715d                	addi	sp,sp,-80
    8000159e:	e486                	sd	ra,72(sp)
    800015a0:	e0a2                	sd	s0,64(sp)
    800015a2:	fc26                	sd	s1,56(sp)
    800015a4:	f84a                	sd	s2,48(sp)
    800015a6:	f44e                	sd	s3,40(sp)
    800015a8:	f052                	sd	s4,32(sp)
    800015aa:	ec56                	sd	s5,24(sp)
    800015ac:	e85a                	sd	s6,16(sp)
    800015ae:	e45e                	sd	s7,8(sp)
    800015b0:	0880                	addi	s0,sp,80
    800015b2:	8aaa                	mv	s5,a0
    800015b4:	8b2e                	mv	s6,a1
    800015b6:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800015b8:	4481                	li	s1,0
    800015ba:	a829                	j	800015d4 <uvmcopy+0x3a>
    if((pte = walk(old, i, 0)) == 0)
      panic("uvmcopy: pte should exist");
    800015bc:	00007517          	auipc	a0,0x7
    800015c0:	bb450513          	addi	a0,a0,-1100 # 80008170 <digits+0x130>
    800015c4:	fffff097          	auipc	ra,0xfffff
    800015c8:	f66080e7          	jalr	-154(ra) # 8000052a <panic>
  for(i = 0; i < sz; i += PGSIZE){
    800015cc:	6785                	lui	a5,0x1
    800015ce:	94be                	add	s1,s1,a5
    800015d0:	0944f463          	bgeu	s1,s4,80001658 <uvmcopy+0xbe>
    if((pte = walk(old, i, 0)) == 0)
    800015d4:	4601                	li	a2,0
    800015d6:	85a6                	mv	a1,s1
    800015d8:	8556                	mv	a0,s5
    800015da:	00000097          	auipc	ra,0x0
    800015de:	9cc080e7          	jalr	-1588(ra) # 80000fa6 <walk>
    800015e2:	dd69                	beqz	a0,800015bc <uvmcopy+0x22>
    if((*pte & PTE_V) == 0)
    800015e4:	6118                	ld	a4,0(a0)
    800015e6:	00177793          	andi	a5,a4,1
    800015ea:	d3ed                	beqz	a5,800015cc <uvmcopy+0x32>
      //panic("uvmcopy: page not present");
      // lazy allocation, unsure if all pte in parent pt are allocated with pa, skip
      continue;
    pa = PTE2PA(*pte);
    800015ec:	00a75593          	srli	a1,a4,0xa
    800015f0:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015f4:	3ff77913          	andi	s2,a4,1023
    if((mem = kalloc()) == 0)
    800015f8:	fffff097          	auipc	ra,0xfffff
    800015fc:	4da080e7          	jalr	1242(ra) # 80000ad2 <kalloc>
    80001600:	89aa                	mv	s3,a0
    80001602:	c515                	beqz	a0,8000162e <uvmcopy+0x94>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001604:	6605                	lui	a2,0x1
    80001606:	85de                	mv	a1,s7
    80001608:	fffff097          	auipc	ra,0xfffff
    8000160c:	712080e7          	jalr	1810(ra) # 80000d1a <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001610:	874a                	mv	a4,s2
    80001612:	86ce                	mv	a3,s3
    80001614:	6605                	lui	a2,0x1
    80001616:	85a6                	mv	a1,s1
    80001618:	855a                	mv	a0,s6
    8000161a:	00000097          	auipc	ra,0x0
    8000161e:	a32080e7          	jalr	-1486(ra) # 8000104c <mappages>
    80001622:	d54d                	beqz	a0,800015cc <uvmcopy+0x32>
      kfree(mem);
    80001624:	854e                	mv	a0,s3
    80001626:	fffff097          	auipc	ra,0xfffff
    8000162a:	3b0080e7          	jalr	944(ra) # 800009d6 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000162e:	4685                	li	a3,1
    80001630:	00c4d613          	srli	a2,s1,0xc
    80001634:	4581                	li	a1,0
    80001636:	855a                	mv	a0,s6
    80001638:	00000097          	auipc	ra,0x0
    8000163c:	c78080e7          	jalr	-904(ra) # 800012b0 <uvmunmap>
  return -1;
    80001640:	557d                	li	a0,-1
}
    80001642:	60a6                	ld	ra,72(sp)
    80001644:	6406                	ld	s0,64(sp)
    80001646:	74e2                	ld	s1,56(sp)
    80001648:	7942                	ld	s2,48(sp)
    8000164a:	79a2                	ld	s3,40(sp)
    8000164c:	7a02                	ld	s4,32(sp)
    8000164e:	6ae2                	ld	s5,24(sp)
    80001650:	6b42                	ld	s6,16(sp)
    80001652:	6ba2                	ld	s7,8(sp)
    80001654:	6161                	addi	sp,sp,80
    80001656:	8082                	ret
  return 0;
    80001658:	4501                	li	a0,0
    8000165a:	b7e5                	j	80001642 <uvmcopy+0xa8>
    8000165c:	4501                	li	a0,0
}
    8000165e:	8082                	ret

0000000080001660 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001660:	1141                	addi	sp,sp,-16
    80001662:	e406                	sd	ra,8(sp)
    80001664:	e022                	sd	s0,0(sp)
    80001666:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001668:	4601                	li	a2,0
    8000166a:	00000097          	auipc	ra,0x0
    8000166e:	93c080e7          	jalr	-1732(ra) # 80000fa6 <walk>
  if(pte == 0)
    80001672:	c901                	beqz	a0,80001682 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001674:	611c                	ld	a5,0(a0)
    80001676:	9bbd                	andi	a5,a5,-17
    80001678:	e11c                	sd	a5,0(a0)
}
    8000167a:	60a2                	ld	ra,8(sp)
    8000167c:	6402                	ld	s0,0(sp)
    8000167e:	0141                	addi	sp,sp,16
    80001680:	8082                	ret
    panic("uvmclear");
    80001682:	00007517          	auipc	a0,0x7
    80001686:	b0e50513          	addi	a0,a0,-1266 # 80008190 <digits+0x150>
    8000168a:	fffff097          	auipc	ra,0xfffff
    8000168e:	ea0080e7          	jalr	-352(ra) # 8000052a <panic>

0000000080001692 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001692:	c6bd                	beqz	a3,80001700 <copyout+0x6e>
{
    80001694:	715d                	addi	sp,sp,-80
    80001696:	e486                	sd	ra,72(sp)
    80001698:	e0a2                	sd	s0,64(sp)
    8000169a:	fc26                	sd	s1,56(sp)
    8000169c:	f84a                	sd	s2,48(sp)
    8000169e:	f44e                	sd	s3,40(sp)
    800016a0:	f052                	sd	s4,32(sp)
    800016a2:	ec56                	sd	s5,24(sp)
    800016a4:	e85a                	sd	s6,16(sp)
    800016a6:	e45e                	sd	s7,8(sp)
    800016a8:	e062                	sd	s8,0(sp)
    800016aa:	0880                	addi	s0,sp,80
    800016ac:	8b2a                	mv	s6,a0
    800016ae:	8c2e                	mv	s8,a1
    800016b0:	8a32                	mv	s4,a2
    800016b2:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800016b4:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016b6:	6a85                	lui	s5,0x1
    800016b8:	a015                	j	800016dc <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016ba:	9562                	add	a0,a0,s8
    800016bc:	0004861b          	sext.w	a2,s1
    800016c0:	85d2                	mv	a1,s4
    800016c2:	41250533          	sub	a0,a0,s2
    800016c6:	fffff097          	auipc	ra,0xfffff
    800016ca:	654080e7          	jalr	1620(ra) # 80000d1a <memmove>

    len -= n;
    800016ce:	409989b3          	sub	s3,s3,s1
    src += n;
    800016d2:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016d4:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016d8:	02098263          	beqz	s3,800016fc <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016dc:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016e0:	85ca                	mv	a1,s2
    800016e2:	855a                	mv	a0,s6
    800016e4:	00000097          	auipc	ra,0x0
    800016e8:	9f6080e7          	jalr	-1546(ra) # 800010da <walkaddr>
    if(pa0 == 0)
    800016ec:	cd01                	beqz	a0,80001704 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016ee:	418904b3          	sub	s1,s2,s8
    800016f2:	94d6                	add	s1,s1,s5
    if(n > len)
    800016f4:	fc99f3e3          	bgeu	s3,s1,800016ba <copyout+0x28>
    800016f8:	84ce                	mv	s1,s3
    800016fa:	b7c1                	j	800016ba <copyout+0x28>
  }
  return 0;
    800016fc:	4501                	li	a0,0
    800016fe:	a021                	j	80001706 <copyout+0x74>
    80001700:	4501                	li	a0,0
}
    80001702:	8082                	ret
      return -1;
    80001704:	557d                	li	a0,-1
}
    80001706:	60a6                	ld	ra,72(sp)
    80001708:	6406                	ld	s0,64(sp)
    8000170a:	74e2                	ld	s1,56(sp)
    8000170c:	7942                	ld	s2,48(sp)
    8000170e:	79a2                	ld	s3,40(sp)
    80001710:	7a02                	ld	s4,32(sp)
    80001712:	6ae2                	ld	s5,24(sp)
    80001714:	6b42                	ld	s6,16(sp)
    80001716:	6ba2                	ld	s7,8(sp)
    80001718:	6c02                	ld	s8,0(sp)
    8000171a:	6161                	addi	sp,sp,80
    8000171c:	8082                	ret

000000008000171e <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000171e:	caa5                	beqz	a3,8000178e <copyin+0x70>
{
    80001720:	715d                	addi	sp,sp,-80
    80001722:	e486                	sd	ra,72(sp)
    80001724:	e0a2                	sd	s0,64(sp)
    80001726:	fc26                	sd	s1,56(sp)
    80001728:	f84a                	sd	s2,48(sp)
    8000172a:	f44e                	sd	s3,40(sp)
    8000172c:	f052                	sd	s4,32(sp)
    8000172e:	ec56                	sd	s5,24(sp)
    80001730:	e85a                	sd	s6,16(sp)
    80001732:	e45e                	sd	s7,8(sp)
    80001734:	e062                	sd	s8,0(sp)
    80001736:	0880                	addi	s0,sp,80
    80001738:	8b2a                	mv	s6,a0
    8000173a:	8a2e                	mv	s4,a1
    8000173c:	8c32                	mv	s8,a2
    8000173e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001740:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001742:	6a85                	lui	s5,0x1
    80001744:	a01d                	j	8000176a <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001746:	018505b3          	add	a1,a0,s8
    8000174a:	0004861b          	sext.w	a2,s1
    8000174e:	412585b3          	sub	a1,a1,s2
    80001752:	8552                	mv	a0,s4
    80001754:	fffff097          	auipc	ra,0xfffff
    80001758:	5c6080e7          	jalr	1478(ra) # 80000d1a <memmove>

    len -= n;
    8000175c:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001760:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001762:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001766:	02098263          	beqz	s3,8000178a <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    8000176a:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000176e:	85ca                	mv	a1,s2
    80001770:	855a                	mv	a0,s6
    80001772:	00000097          	auipc	ra,0x0
    80001776:	968080e7          	jalr	-1688(ra) # 800010da <walkaddr>
    if(pa0 == 0)
    8000177a:	cd01                	beqz	a0,80001792 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    8000177c:	418904b3          	sub	s1,s2,s8
    80001780:	94d6                	add	s1,s1,s5
    if(n > len)
    80001782:	fc99f2e3          	bgeu	s3,s1,80001746 <copyin+0x28>
    80001786:	84ce                	mv	s1,s3
    80001788:	bf7d                	j	80001746 <copyin+0x28>
  }
  return 0;
    8000178a:	4501                	li	a0,0
    8000178c:	a021                	j	80001794 <copyin+0x76>
    8000178e:	4501                	li	a0,0
}
    80001790:	8082                	ret
      return -1;
    80001792:	557d                	li	a0,-1
}
    80001794:	60a6                	ld	ra,72(sp)
    80001796:	6406                	ld	s0,64(sp)
    80001798:	74e2                	ld	s1,56(sp)
    8000179a:	7942                	ld	s2,48(sp)
    8000179c:	79a2                	ld	s3,40(sp)
    8000179e:	7a02                	ld	s4,32(sp)
    800017a0:	6ae2                	ld	s5,24(sp)
    800017a2:	6b42                	ld	s6,16(sp)
    800017a4:	6ba2                	ld	s7,8(sp)
    800017a6:	6c02                	ld	s8,0(sp)
    800017a8:	6161                	addi	sp,sp,80
    800017aa:	8082                	ret

00000000800017ac <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800017ac:	c6c5                	beqz	a3,80001854 <copyinstr+0xa8>
{
    800017ae:	715d                	addi	sp,sp,-80
    800017b0:	e486                	sd	ra,72(sp)
    800017b2:	e0a2                	sd	s0,64(sp)
    800017b4:	fc26                	sd	s1,56(sp)
    800017b6:	f84a                	sd	s2,48(sp)
    800017b8:	f44e                	sd	s3,40(sp)
    800017ba:	f052                	sd	s4,32(sp)
    800017bc:	ec56                	sd	s5,24(sp)
    800017be:	e85a                	sd	s6,16(sp)
    800017c0:	e45e                	sd	s7,8(sp)
    800017c2:	0880                	addi	s0,sp,80
    800017c4:	8a2a                	mv	s4,a0
    800017c6:	8b2e                	mv	s6,a1
    800017c8:	8bb2                	mv	s7,a2
    800017ca:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017cc:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017ce:	6985                	lui	s3,0x1
    800017d0:	a035                	j	800017fc <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017d2:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017d6:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017d8:	0017b793          	seqz	a5,a5
    800017dc:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017e0:	60a6                	ld	ra,72(sp)
    800017e2:	6406                	ld	s0,64(sp)
    800017e4:	74e2                	ld	s1,56(sp)
    800017e6:	7942                	ld	s2,48(sp)
    800017e8:	79a2                	ld	s3,40(sp)
    800017ea:	7a02                	ld	s4,32(sp)
    800017ec:	6ae2                	ld	s5,24(sp)
    800017ee:	6b42                	ld	s6,16(sp)
    800017f0:	6ba2                	ld	s7,8(sp)
    800017f2:	6161                	addi	sp,sp,80
    800017f4:	8082                	ret
    srcva = va0 + PGSIZE;
    800017f6:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017fa:	c8a9                	beqz	s1,8000184c <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017fc:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001800:	85ca                	mv	a1,s2
    80001802:	8552                	mv	a0,s4
    80001804:	00000097          	auipc	ra,0x0
    80001808:	8d6080e7          	jalr	-1834(ra) # 800010da <walkaddr>
    if(pa0 == 0)
    8000180c:	c131                	beqz	a0,80001850 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    8000180e:	41790833          	sub	a6,s2,s7
    80001812:	984e                	add	a6,a6,s3
    if(n > max)
    80001814:	0104f363          	bgeu	s1,a6,8000181a <copyinstr+0x6e>
    80001818:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    8000181a:	955e                	add	a0,a0,s7
    8000181c:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001820:	fc080be3          	beqz	a6,800017f6 <copyinstr+0x4a>
    80001824:	985a                	add	a6,a6,s6
    80001826:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001828:	41650633          	sub	a2,a0,s6
    8000182c:	14fd                	addi	s1,s1,-1
    8000182e:	9b26                	add	s6,s6,s1
    80001830:	00f60733          	add	a4,a2,a5
    80001834:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd9000>
    80001838:	df49                	beqz	a4,800017d2 <copyinstr+0x26>
        *dst = *p;
    8000183a:	00e78023          	sb	a4,0(a5)
      --max;
    8000183e:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001842:	0785                	addi	a5,a5,1
    while(n > 0){
    80001844:	ff0796e3          	bne	a5,a6,80001830 <copyinstr+0x84>
      dst++;
    80001848:	8b42                	mv	s6,a6
    8000184a:	b775                	j	800017f6 <copyinstr+0x4a>
    8000184c:	4781                	li	a5,0
    8000184e:	b769                	j	800017d8 <copyinstr+0x2c>
      return -1;
    80001850:	557d                	li	a0,-1
    80001852:	b779                	j	800017e0 <copyinstr+0x34>
  int got_null = 0;
    80001854:	4781                	li	a5,0
  if(got_null){
    80001856:	0017b793          	seqz	a5,a5
    8000185a:	40f00533          	neg	a0,a5
}
    8000185e:	8082                	ret

0000000080001860 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001860:	7139                	addi	sp,sp,-64
    80001862:	fc06                	sd	ra,56(sp)
    80001864:	f822                	sd	s0,48(sp)
    80001866:	f426                	sd	s1,40(sp)
    80001868:	f04a                	sd	s2,32(sp)
    8000186a:	ec4e                	sd	s3,24(sp)
    8000186c:	e852                	sd	s4,16(sp)
    8000186e:	e456                	sd	s5,8(sp)
    80001870:	e05a                	sd	s6,0(sp)
    80001872:	0080                	addi	s0,sp,64
    80001874:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001876:	00010497          	auipc	s1,0x10
    8000187a:	e5a48493          	addi	s1,s1,-422 # 800116d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000187e:	8b26                	mv	s6,s1
    80001880:	00006a97          	auipc	s5,0x6
    80001884:	780a8a93          	addi	s5,s5,1920 # 80008000 <etext>
    80001888:	04000937          	lui	s2,0x4000
    8000188c:	197d                	addi	s2,s2,-1
    8000188e:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001890:	00016a17          	auipc	s4,0x16
    80001894:	840a0a13          	addi	s4,s4,-1984 # 800170d0 <tickslock>
    char *pa = kalloc();
    80001898:	fffff097          	auipc	ra,0xfffff
    8000189c:	23a080e7          	jalr	570(ra) # 80000ad2 <kalloc>
    800018a0:	862a                	mv	a2,a0
    if(pa == 0)
    800018a2:	c131                	beqz	a0,800018e6 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    800018a4:	416485b3          	sub	a1,s1,s6
    800018a8:	858d                	srai	a1,a1,0x3
    800018aa:	000ab783          	ld	a5,0(s5)
    800018ae:	02f585b3          	mul	a1,a1,a5
    800018b2:	2585                	addiw	a1,a1,1
    800018b4:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800018b8:	4719                	li	a4,6
    800018ba:	6685                	lui	a3,0x1
    800018bc:	40b905b3          	sub	a1,s2,a1
    800018c0:	854e                	mv	a0,s3
    800018c2:	00000097          	auipc	ra,0x0
    800018c6:	8c8080e7          	jalr	-1848(ra) # 8000118a <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018ca:	16848493          	addi	s1,s1,360
    800018ce:	fd4495e3          	bne	s1,s4,80001898 <proc_mapstacks+0x38>
  }
}
    800018d2:	70e2                	ld	ra,56(sp)
    800018d4:	7442                	ld	s0,48(sp)
    800018d6:	74a2                	ld	s1,40(sp)
    800018d8:	7902                	ld	s2,32(sp)
    800018da:	69e2                	ld	s3,24(sp)
    800018dc:	6a42                	ld	s4,16(sp)
    800018de:	6aa2                	ld	s5,8(sp)
    800018e0:	6b02                	ld	s6,0(sp)
    800018e2:	6121                	addi	sp,sp,64
    800018e4:	8082                	ret
      panic("kalloc");
    800018e6:	00007517          	auipc	a0,0x7
    800018ea:	8ba50513          	addi	a0,a0,-1862 # 800081a0 <digits+0x160>
    800018ee:	fffff097          	auipc	ra,0xfffff
    800018f2:	c3c080e7          	jalr	-964(ra) # 8000052a <panic>

00000000800018f6 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    800018f6:	7139                	addi	sp,sp,-64
    800018f8:	fc06                	sd	ra,56(sp)
    800018fa:	f822                	sd	s0,48(sp)
    800018fc:	f426                	sd	s1,40(sp)
    800018fe:	f04a                	sd	s2,32(sp)
    80001900:	ec4e                	sd	s3,24(sp)
    80001902:	e852                	sd	s4,16(sp)
    80001904:	e456                	sd	s5,8(sp)
    80001906:	e05a                	sd	s6,0(sp)
    80001908:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    8000190a:	00007597          	auipc	a1,0x7
    8000190e:	89e58593          	addi	a1,a1,-1890 # 800081a8 <digits+0x168>
    80001912:	00010517          	auipc	a0,0x10
    80001916:	98e50513          	addi	a0,a0,-1650 # 800112a0 <pid_lock>
    8000191a:	fffff097          	auipc	ra,0xfffff
    8000191e:	218080e7          	jalr	536(ra) # 80000b32 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001922:	00007597          	auipc	a1,0x7
    80001926:	88e58593          	addi	a1,a1,-1906 # 800081b0 <digits+0x170>
    8000192a:	00010517          	auipc	a0,0x10
    8000192e:	98e50513          	addi	a0,a0,-1650 # 800112b8 <wait_lock>
    80001932:	fffff097          	auipc	ra,0xfffff
    80001936:	200080e7          	jalr	512(ra) # 80000b32 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000193a:	00010497          	auipc	s1,0x10
    8000193e:	d9648493          	addi	s1,s1,-618 # 800116d0 <proc>
      initlock(&p->lock, "proc");
    80001942:	00007b17          	auipc	s6,0x7
    80001946:	87eb0b13          	addi	s6,s6,-1922 # 800081c0 <digits+0x180>
      p->kstack = KSTACK((int) (p - proc));
    8000194a:	8aa6                	mv	s5,s1
    8000194c:	00006a17          	auipc	s4,0x6
    80001950:	6b4a0a13          	addi	s4,s4,1716 # 80008000 <etext>
    80001954:	04000937          	lui	s2,0x4000
    80001958:	197d                	addi	s2,s2,-1
    8000195a:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000195c:	00015997          	auipc	s3,0x15
    80001960:	77498993          	addi	s3,s3,1908 # 800170d0 <tickslock>
      initlock(&p->lock, "proc");
    80001964:	85da                	mv	a1,s6
    80001966:	8526                	mv	a0,s1
    80001968:	fffff097          	auipc	ra,0xfffff
    8000196c:	1ca080e7          	jalr	458(ra) # 80000b32 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001970:	415487b3          	sub	a5,s1,s5
    80001974:	878d                	srai	a5,a5,0x3
    80001976:	000a3703          	ld	a4,0(s4)
    8000197a:	02e787b3          	mul	a5,a5,a4
    8000197e:	2785                	addiw	a5,a5,1
    80001980:	00d7979b          	slliw	a5,a5,0xd
    80001984:	40f907b3          	sub	a5,s2,a5
    80001988:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    8000198a:	16848493          	addi	s1,s1,360
    8000198e:	fd349be3          	bne	s1,s3,80001964 <procinit+0x6e>
  }
}
    80001992:	70e2                	ld	ra,56(sp)
    80001994:	7442                	ld	s0,48(sp)
    80001996:	74a2                	ld	s1,40(sp)
    80001998:	7902                	ld	s2,32(sp)
    8000199a:	69e2                	ld	s3,24(sp)
    8000199c:	6a42                	ld	s4,16(sp)
    8000199e:	6aa2                	ld	s5,8(sp)
    800019a0:	6b02                	ld	s6,0(sp)
    800019a2:	6121                	addi	sp,sp,64
    800019a4:	8082                	ret

00000000800019a6 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    800019a6:	1141                	addi	sp,sp,-16
    800019a8:	e422                	sd	s0,8(sp)
    800019aa:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019ac:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800019ae:	2501                	sext.w	a0,a0
    800019b0:	6422                	ld	s0,8(sp)
    800019b2:	0141                	addi	sp,sp,16
    800019b4:	8082                	ret

00000000800019b6 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    800019b6:	1141                	addi	sp,sp,-16
    800019b8:	e422                	sd	s0,8(sp)
    800019ba:	0800                	addi	s0,sp,16
    800019bc:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019be:	2781                	sext.w	a5,a5
    800019c0:	079e                	slli	a5,a5,0x7
  return c;
}
    800019c2:	00010517          	auipc	a0,0x10
    800019c6:	90e50513          	addi	a0,a0,-1778 # 800112d0 <cpus>
    800019ca:	953e                	add	a0,a0,a5
    800019cc:	6422                	ld	s0,8(sp)
    800019ce:	0141                	addi	sp,sp,16
    800019d0:	8082                	ret

00000000800019d2 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    800019d2:	1101                	addi	sp,sp,-32
    800019d4:	ec06                	sd	ra,24(sp)
    800019d6:	e822                	sd	s0,16(sp)
    800019d8:	e426                	sd	s1,8(sp)
    800019da:	1000                	addi	s0,sp,32
  push_off();
    800019dc:	fffff097          	auipc	ra,0xfffff
    800019e0:	19a080e7          	jalr	410(ra) # 80000b76 <push_off>
    800019e4:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019e6:	2781                	sext.w	a5,a5
    800019e8:	079e                	slli	a5,a5,0x7
    800019ea:	00010717          	auipc	a4,0x10
    800019ee:	8b670713          	addi	a4,a4,-1866 # 800112a0 <pid_lock>
    800019f2:	97ba                	add	a5,a5,a4
    800019f4:	7b84                	ld	s1,48(a5)
  pop_off();
    800019f6:	fffff097          	auipc	ra,0xfffff
    800019fa:	220080e7          	jalr	544(ra) # 80000c16 <pop_off>
  return p;
}
    800019fe:	8526                	mv	a0,s1
    80001a00:	60e2                	ld	ra,24(sp)
    80001a02:	6442                	ld	s0,16(sp)
    80001a04:	64a2                	ld	s1,8(sp)
    80001a06:	6105                	addi	sp,sp,32
    80001a08:	8082                	ret

0000000080001a0a <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001a0a:	1141                	addi	sp,sp,-16
    80001a0c:	e406                	sd	ra,8(sp)
    80001a0e:	e022                	sd	s0,0(sp)
    80001a10:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a12:	00000097          	auipc	ra,0x0
    80001a16:	fc0080e7          	jalr	-64(ra) # 800019d2 <myproc>
    80001a1a:	fffff097          	auipc	ra,0xfffff
    80001a1e:	25c080e7          	jalr	604(ra) # 80000c76 <release>

  if (first) {
    80001a22:	00007797          	auipc	a5,0x7
    80001a26:	dde7a783          	lw	a5,-546(a5) # 80008800 <first.1>
    80001a2a:	eb89                	bnez	a5,80001a3c <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a2c:	00001097          	auipc	ra,0x1
    80001a30:	c10080e7          	jalr	-1008(ra) # 8000263c <usertrapret>
}
    80001a34:	60a2                	ld	ra,8(sp)
    80001a36:	6402                	ld	s0,0(sp)
    80001a38:	0141                	addi	sp,sp,16
    80001a3a:	8082                	ret
    first = 0;
    80001a3c:	00007797          	auipc	a5,0x7
    80001a40:	dc07a223          	sw	zero,-572(a5) # 80008800 <first.1>
    fsinit(ROOTDEV);
    80001a44:	4505                	li	a0,1
    80001a46:	00002097          	auipc	ra,0x2
    80001a4a:	9c0080e7          	jalr	-1600(ra) # 80003406 <fsinit>
    80001a4e:	bff9                	j	80001a2c <forkret+0x22>

0000000080001a50 <allocpid>:
allocpid() {
    80001a50:	1101                	addi	sp,sp,-32
    80001a52:	ec06                	sd	ra,24(sp)
    80001a54:	e822                	sd	s0,16(sp)
    80001a56:	e426                	sd	s1,8(sp)
    80001a58:	e04a                	sd	s2,0(sp)
    80001a5a:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a5c:	00010917          	auipc	s2,0x10
    80001a60:	84490913          	addi	s2,s2,-1980 # 800112a0 <pid_lock>
    80001a64:	854a                	mv	a0,s2
    80001a66:	fffff097          	auipc	ra,0xfffff
    80001a6a:	15c080e7          	jalr	348(ra) # 80000bc2 <acquire>
  pid = nextpid;
    80001a6e:	00007797          	auipc	a5,0x7
    80001a72:	d9678793          	addi	a5,a5,-618 # 80008804 <nextpid>
    80001a76:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a78:	0014871b          	addiw	a4,s1,1
    80001a7c:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a7e:	854a                	mv	a0,s2
    80001a80:	fffff097          	auipc	ra,0xfffff
    80001a84:	1f6080e7          	jalr	502(ra) # 80000c76 <release>
}
    80001a88:	8526                	mv	a0,s1
    80001a8a:	60e2                	ld	ra,24(sp)
    80001a8c:	6442                	ld	s0,16(sp)
    80001a8e:	64a2                	ld	s1,8(sp)
    80001a90:	6902                	ld	s2,0(sp)
    80001a92:	6105                	addi	sp,sp,32
    80001a94:	8082                	ret

0000000080001a96 <proc_pagetable>:
{
    80001a96:	1101                	addi	sp,sp,-32
    80001a98:	ec06                	sd	ra,24(sp)
    80001a9a:	e822                	sd	s0,16(sp)
    80001a9c:	e426                	sd	s1,8(sp)
    80001a9e:	e04a                	sd	s2,0(sp)
    80001aa0:	1000                	addi	s0,sp,32
    80001aa2:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001aa4:	00000097          	auipc	ra,0x0
    80001aa8:	8c2080e7          	jalr	-1854(ra) # 80001366 <uvmcreate>
    80001aac:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001aae:	c121                	beqz	a0,80001aee <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001ab0:	4729                	li	a4,10
    80001ab2:	00005697          	auipc	a3,0x5
    80001ab6:	54e68693          	addi	a3,a3,1358 # 80007000 <_trampoline>
    80001aba:	6605                	lui	a2,0x1
    80001abc:	040005b7          	lui	a1,0x4000
    80001ac0:	15fd                	addi	a1,a1,-1
    80001ac2:	05b2                	slli	a1,a1,0xc
    80001ac4:	fffff097          	auipc	ra,0xfffff
    80001ac8:	588080e7          	jalr	1416(ra) # 8000104c <mappages>
    80001acc:	02054863          	bltz	a0,80001afc <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001ad0:	4719                	li	a4,6
    80001ad2:	05893683          	ld	a3,88(s2)
    80001ad6:	6605                	lui	a2,0x1
    80001ad8:	020005b7          	lui	a1,0x2000
    80001adc:	15fd                	addi	a1,a1,-1
    80001ade:	05b6                	slli	a1,a1,0xd
    80001ae0:	8526                	mv	a0,s1
    80001ae2:	fffff097          	auipc	ra,0xfffff
    80001ae6:	56a080e7          	jalr	1386(ra) # 8000104c <mappages>
    80001aea:	02054163          	bltz	a0,80001b0c <proc_pagetable+0x76>
}
    80001aee:	8526                	mv	a0,s1
    80001af0:	60e2                	ld	ra,24(sp)
    80001af2:	6442                	ld	s0,16(sp)
    80001af4:	64a2                	ld	s1,8(sp)
    80001af6:	6902                	ld	s2,0(sp)
    80001af8:	6105                	addi	sp,sp,32
    80001afa:	8082                	ret
    uvmfree(pagetable, 0);
    80001afc:	4581                	li	a1,0
    80001afe:	8526                	mv	a0,s1
    80001b00:	00000097          	auipc	ra,0x0
    80001b04:	a62080e7          	jalr	-1438(ra) # 80001562 <uvmfree>
    return 0;
    80001b08:	4481                	li	s1,0
    80001b0a:	b7d5                	j	80001aee <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b0c:	4681                	li	a3,0
    80001b0e:	4605                	li	a2,1
    80001b10:	040005b7          	lui	a1,0x4000
    80001b14:	15fd                	addi	a1,a1,-1
    80001b16:	05b2                	slli	a1,a1,0xc
    80001b18:	8526                	mv	a0,s1
    80001b1a:	fffff097          	auipc	ra,0xfffff
    80001b1e:	796080e7          	jalr	1942(ra) # 800012b0 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b22:	4581                	li	a1,0
    80001b24:	8526                	mv	a0,s1
    80001b26:	00000097          	auipc	ra,0x0
    80001b2a:	a3c080e7          	jalr	-1476(ra) # 80001562 <uvmfree>
    return 0;
    80001b2e:	4481                	li	s1,0
    80001b30:	bf7d                	j	80001aee <proc_pagetable+0x58>

0000000080001b32 <proc_freepagetable>:
{
    80001b32:	1101                	addi	sp,sp,-32
    80001b34:	ec06                	sd	ra,24(sp)
    80001b36:	e822                	sd	s0,16(sp)
    80001b38:	e426                	sd	s1,8(sp)
    80001b3a:	e04a                	sd	s2,0(sp)
    80001b3c:	1000                	addi	s0,sp,32
    80001b3e:	84aa                	mv	s1,a0
    80001b40:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b42:	4681                	li	a3,0
    80001b44:	4605                	li	a2,1
    80001b46:	040005b7          	lui	a1,0x4000
    80001b4a:	15fd                	addi	a1,a1,-1
    80001b4c:	05b2                	slli	a1,a1,0xc
    80001b4e:	fffff097          	auipc	ra,0xfffff
    80001b52:	762080e7          	jalr	1890(ra) # 800012b0 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b56:	4681                	li	a3,0
    80001b58:	4605                	li	a2,1
    80001b5a:	020005b7          	lui	a1,0x2000
    80001b5e:	15fd                	addi	a1,a1,-1
    80001b60:	05b6                	slli	a1,a1,0xd
    80001b62:	8526                	mv	a0,s1
    80001b64:	fffff097          	auipc	ra,0xfffff
    80001b68:	74c080e7          	jalr	1868(ra) # 800012b0 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b6c:	85ca                	mv	a1,s2
    80001b6e:	8526                	mv	a0,s1
    80001b70:	00000097          	auipc	ra,0x0
    80001b74:	9f2080e7          	jalr	-1550(ra) # 80001562 <uvmfree>
}
    80001b78:	60e2                	ld	ra,24(sp)
    80001b7a:	6442                	ld	s0,16(sp)
    80001b7c:	64a2                	ld	s1,8(sp)
    80001b7e:	6902                	ld	s2,0(sp)
    80001b80:	6105                	addi	sp,sp,32
    80001b82:	8082                	ret

0000000080001b84 <freeproc>:
{
    80001b84:	1101                	addi	sp,sp,-32
    80001b86:	ec06                	sd	ra,24(sp)
    80001b88:	e822                	sd	s0,16(sp)
    80001b8a:	e426                	sd	s1,8(sp)
    80001b8c:	1000                	addi	s0,sp,32
    80001b8e:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b90:	6d28                	ld	a0,88(a0)
    80001b92:	c509                	beqz	a0,80001b9c <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b94:	fffff097          	auipc	ra,0xfffff
    80001b98:	e42080e7          	jalr	-446(ra) # 800009d6 <kfree>
  p->trapframe = 0;
    80001b9c:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001ba0:	68a8                	ld	a0,80(s1)
    80001ba2:	c511                	beqz	a0,80001bae <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001ba4:	64ac                	ld	a1,72(s1)
    80001ba6:	00000097          	auipc	ra,0x0
    80001baa:	f8c080e7          	jalr	-116(ra) # 80001b32 <proc_freepagetable>
  p->pagetable = 0;
    80001bae:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001bb2:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001bb6:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001bba:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001bbe:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001bc2:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001bc6:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001bca:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bce:	0004ac23          	sw	zero,24(s1)
}
    80001bd2:	60e2                	ld	ra,24(sp)
    80001bd4:	6442                	ld	s0,16(sp)
    80001bd6:	64a2                	ld	s1,8(sp)
    80001bd8:	6105                	addi	sp,sp,32
    80001bda:	8082                	ret

0000000080001bdc <allocproc>:
{
    80001bdc:	1101                	addi	sp,sp,-32
    80001bde:	ec06                	sd	ra,24(sp)
    80001be0:	e822                	sd	s0,16(sp)
    80001be2:	e426                	sd	s1,8(sp)
    80001be4:	e04a                	sd	s2,0(sp)
    80001be6:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001be8:	00010497          	auipc	s1,0x10
    80001bec:	ae848493          	addi	s1,s1,-1304 # 800116d0 <proc>
    80001bf0:	00015917          	auipc	s2,0x15
    80001bf4:	4e090913          	addi	s2,s2,1248 # 800170d0 <tickslock>
    acquire(&p->lock);
    80001bf8:	8526                	mv	a0,s1
    80001bfa:	fffff097          	auipc	ra,0xfffff
    80001bfe:	fc8080e7          	jalr	-56(ra) # 80000bc2 <acquire>
    if(p->state == UNUSED) {
    80001c02:	4c9c                	lw	a5,24(s1)
    80001c04:	cf81                	beqz	a5,80001c1c <allocproc+0x40>
      release(&p->lock);
    80001c06:	8526                	mv	a0,s1
    80001c08:	fffff097          	auipc	ra,0xfffff
    80001c0c:	06e080e7          	jalr	110(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c10:	16848493          	addi	s1,s1,360
    80001c14:	ff2492e3          	bne	s1,s2,80001bf8 <allocproc+0x1c>
  return 0;
    80001c18:	4481                	li	s1,0
    80001c1a:	a889                	j	80001c6c <allocproc+0x90>
  p->pid = allocpid();
    80001c1c:	00000097          	auipc	ra,0x0
    80001c20:	e34080e7          	jalr	-460(ra) # 80001a50 <allocpid>
    80001c24:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c26:	4785                	li	a5,1
    80001c28:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c2a:	fffff097          	auipc	ra,0xfffff
    80001c2e:	ea8080e7          	jalr	-344(ra) # 80000ad2 <kalloc>
    80001c32:	892a                	mv	s2,a0
    80001c34:	eca8                	sd	a0,88(s1)
    80001c36:	c131                	beqz	a0,80001c7a <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c38:	8526                	mv	a0,s1
    80001c3a:	00000097          	auipc	ra,0x0
    80001c3e:	e5c080e7          	jalr	-420(ra) # 80001a96 <proc_pagetable>
    80001c42:	892a                	mv	s2,a0
    80001c44:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c46:	c531                	beqz	a0,80001c92 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c48:	07000613          	li	a2,112
    80001c4c:	4581                	li	a1,0
    80001c4e:	06048513          	addi	a0,s1,96
    80001c52:	fffff097          	auipc	ra,0xfffff
    80001c56:	06c080e7          	jalr	108(ra) # 80000cbe <memset>
  p->context.ra = (uint64)forkret;
    80001c5a:	00000797          	auipc	a5,0x0
    80001c5e:	db078793          	addi	a5,a5,-592 # 80001a0a <forkret>
    80001c62:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c64:	60bc                	ld	a5,64(s1)
    80001c66:	6705                	lui	a4,0x1
    80001c68:	97ba                	add	a5,a5,a4
    80001c6a:	f4bc                	sd	a5,104(s1)
}
    80001c6c:	8526                	mv	a0,s1
    80001c6e:	60e2                	ld	ra,24(sp)
    80001c70:	6442                	ld	s0,16(sp)
    80001c72:	64a2                	ld	s1,8(sp)
    80001c74:	6902                	ld	s2,0(sp)
    80001c76:	6105                	addi	sp,sp,32
    80001c78:	8082                	ret
    freeproc(p);
    80001c7a:	8526                	mv	a0,s1
    80001c7c:	00000097          	auipc	ra,0x0
    80001c80:	f08080e7          	jalr	-248(ra) # 80001b84 <freeproc>
    release(&p->lock);
    80001c84:	8526                	mv	a0,s1
    80001c86:	fffff097          	auipc	ra,0xfffff
    80001c8a:	ff0080e7          	jalr	-16(ra) # 80000c76 <release>
    return 0;
    80001c8e:	84ca                	mv	s1,s2
    80001c90:	bff1                	j	80001c6c <allocproc+0x90>
    freeproc(p);
    80001c92:	8526                	mv	a0,s1
    80001c94:	00000097          	auipc	ra,0x0
    80001c98:	ef0080e7          	jalr	-272(ra) # 80001b84 <freeproc>
    release(&p->lock);
    80001c9c:	8526                	mv	a0,s1
    80001c9e:	fffff097          	auipc	ra,0xfffff
    80001ca2:	fd8080e7          	jalr	-40(ra) # 80000c76 <release>
    return 0;
    80001ca6:	84ca                	mv	s1,s2
    80001ca8:	b7d1                	j	80001c6c <allocproc+0x90>

0000000080001caa <userinit>:
{
    80001caa:	1101                	addi	sp,sp,-32
    80001cac:	ec06                	sd	ra,24(sp)
    80001cae:	e822                	sd	s0,16(sp)
    80001cb0:	e426                	sd	s1,8(sp)
    80001cb2:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cb4:	00000097          	auipc	ra,0x0
    80001cb8:	f28080e7          	jalr	-216(ra) # 80001bdc <allocproc>
    80001cbc:	84aa                	mv	s1,a0
  initproc = p;
    80001cbe:	00007797          	auipc	a5,0x7
    80001cc2:	36a7b523          	sd	a0,874(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001cc6:	03400613          	li	a2,52
    80001cca:	00007597          	auipc	a1,0x7
    80001cce:	b4658593          	addi	a1,a1,-1210 # 80008810 <initcode>
    80001cd2:	6928                	ld	a0,80(a0)
    80001cd4:	fffff097          	auipc	ra,0xfffff
    80001cd8:	6c0080e7          	jalr	1728(ra) # 80001394 <uvminit>
  p->sz = PGSIZE;
    80001cdc:	6785                	lui	a5,0x1
    80001cde:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001ce0:	6cb8                	ld	a4,88(s1)
    80001ce2:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001ce6:	6cb8                	ld	a4,88(s1)
    80001ce8:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cea:	4641                	li	a2,16
    80001cec:	00006597          	auipc	a1,0x6
    80001cf0:	4dc58593          	addi	a1,a1,1244 # 800081c8 <digits+0x188>
    80001cf4:	15848513          	addi	a0,s1,344
    80001cf8:	fffff097          	auipc	ra,0xfffff
    80001cfc:	118080e7          	jalr	280(ra) # 80000e10 <safestrcpy>
  p->cwd = namei("/");
    80001d00:	00006517          	auipc	a0,0x6
    80001d04:	4d850513          	addi	a0,a0,1240 # 800081d8 <digits+0x198>
    80001d08:	00002097          	auipc	ra,0x2
    80001d0c:	12c080e7          	jalr	300(ra) # 80003e34 <namei>
    80001d10:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d14:	478d                	li	a5,3
    80001d16:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d18:	8526                	mv	a0,s1
    80001d1a:	fffff097          	auipc	ra,0xfffff
    80001d1e:	f5c080e7          	jalr	-164(ra) # 80000c76 <release>
}
    80001d22:	60e2                	ld	ra,24(sp)
    80001d24:	6442                	ld	s0,16(sp)
    80001d26:	64a2                	ld	s1,8(sp)
    80001d28:	6105                	addi	sp,sp,32
    80001d2a:	8082                	ret

0000000080001d2c <growproc>:
{
    80001d2c:	1101                	addi	sp,sp,-32
    80001d2e:	ec06                	sd	ra,24(sp)
    80001d30:	e822                	sd	s0,16(sp)
    80001d32:	e426                	sd	s1,8(sp)
    80001d34:	e04a                	sd	s2,0(sp)
    80001d36:	1000                	addi	s0,sp,32
    80001d38:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d3a:	00000097          	auipc	ra,0x0
    80001d3e:	c98080e7          	jalr	-872(ra) # 800019d2 <myproc>
    80001d42:	892a                	mv	s2,a0
  sz = p->sz;
    80001d44:	652c                	ld	a1,72(a0)
    80001d46:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d4a:	00904f63          	bgtz	s1,80001d68 <growproc+0x3c>
  } else if(n < 0){
    80001d4e:	0204cc63          	bltz	s1,80001d86 <growproc+0x5a>
  p->sz = sz;
    80001d52:	1602                	slli	a2,a2,0x20
    80001d54:	9201                	srli	a2,a2,0x20
    80001d56:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d5a:	4501                	li	a0,0
}
    80001d5c:	60e2                	ld	ra,24(sp)
    80001d5e:	6442                	ld	s0,16(sp)
    80001d60:	64a2                	ld	s1,8(sp)
    80001d62:	6902                	ld	s2,0(sp)
    80001d64:	6105                	addi	sp,sp,32
    80001d66:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d68:	9e25                	addw	a2,a2,s1
    80001d6a:	1602                	slli	a2,a2,0x20
    80001d6c:	9201                	srli	a2,a2,0x20
    80001d6e:	1582                	slli	a1,a1,0x20
    80001d70:	9181                	srli	a1,a1,0x20
    80001d72:	6928                	ld	a0,80(a0)
    80001d74:	fffff097          	auipc	ra,0xfffff
    80001d78:	6da080e7          	jalr	1754(ra) # 8000144e <uvmalloc>
    80001d7c:	0005061b          	sext.w	a2,a0
    80001d80:	fa69                	bnez	a2,80001d52 <growproc+0x26>
      return -1;
    80001d82:	557d                	li	a0,-1
    80001d84:	bfe1                	j	80001d5c <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d86:	9e25                	addw	a2,a2,s1
    80001d88:	1602                	slli	a2,a2,0x20
    80001d8a:	9201                	srli	a2,a2,0x20
    80001d8c:	1582                	slli	a1,a1,0x20
    80001d8e:	9181                	srli	a1,a1,0x20
    80001d90:	6928                	ld	a0,80(a0)
    80001d92:	fffff097          	auipc	ra,0xfffff
    80001d96:	674080e7          	jalr	1652(ra) # 80001406 <uvmdealloc>
    80001d9a:	0005061b          	sext.w	a2,a0
    80001d9e:	bf55                	j	80001d52 <growproc+0x26>

0000000080001da0 <fork>:
{
    80001da0:	7139                	addi	sp,sp,-64
    80001da2:	fc06                	sd	ra,56(sp)
    80001da4:	f822                	sd	s0,48(sp)
    80001da6:	f426                	sd	s1,40(sp)
    80001da8:	f04a                	sd	s2,32(sp)
    80001daa:	ec4e                	sd	s3,24(sp)
    80001dac:	e852                	sd	s4,16(sp)
    80001dae:	e456                	sd	s5,8(sp)
    80001db0:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001db2:	00000097          	auipc	ra,0x0
    80001db6:	c20080e7          	jalr	-992(ra) # 800019d2 <myproc>
    80001dba:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001dbc:	00000097          	auipc	ra,0x0
    80001dc0:	e20080e7          	jalr	-480(ra) # 80001bdc <allocproc>
    80001dc4:	10050c63          	beqz	a0,80001edc <fork+0x13c>
    80001dc8:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001dca:	048ab603          	ld	a2,72(s5)
    80001dce:	692c                	ld	a1,80(a0)
    80001dd0:	050ab503          	ld	a0,80(s5)
    80001dd4:	fffff097          	auipc	ra,0xfffff
    80001dd8:	7c6080e7          	jalr	1990(ra) # 8000159a <uvmcopy>
    80001ddc:	04054863          	bltz	a0,80001e2c <fork+0x8c>
  np->sz = p->sz;
    80001de0:	048ab783          	ld	a5,72(s5)
    80001de4:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001de8:	058ab683          	ld	a3,88(s5)
    80001dec:	87b6                	mv	a5,a3
    80001dee:	058a3703          	ld	a4,88(s4)
    80001df2:	12068693          	addi	a3,a3,288
    80001df6:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dfa:	6788                	ld	a0,8(a5)
    80001dfc:	6b8c                	ld	a1,16(a5)
    80001dfe:	6f90                	ld	a2,24(a5)
    80001e00:	01073023          	sd	a6,0(a4)
    80001e04:	e708                	sd	a0,8(a4)
    80001e06:	eb0c                	sd	a1,16(a4)
    80001e08:	ef10                	sd	a2,24(a4)
    80001e0a:	02078793          	addi	a5,a5,32
    80001e0e:	02070713          	addi	a4,a4,32
    80001e12:	fed792e3          	bne	a5,a3,80001df6 <fork+0x56>
  np->trapframe->a0 = 0;
    80001e16:	058a3783          	ld	a5,88(s4)
    80001e1a:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001e1e:	0d0a8493          	addi	s1,s5,208
    80001e22:	0d0a0913          	addi	s2,s4,208
    80001e26:	150a8993          	addi	s3,s5,336
    80001e2a:	a00d                	j	80001e4c <fork+0xac>
    freeproc(np);
    80001e2c:	8552                	mv	a0,s4
    80001e2e:	00000097          	auipc	ra,0x0
    80001e32:	d56080e7          	jalr	-682(ra) # 80001b84 <freeproc>
    release(&np->lock);
    80001e36:	8552                	mv	a0,s4
    80001e38:	fffff097          	auipc	ra,0xfffff
    80001e3c:	e3e080e7          	jalr	-450(ra) # 80000c76 <release>
    return -1;
    80001e40:	597d                	li	s2,-1
    80001e42:	a059                	j	80001ec8 <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001e44:	04a1                	addi	s1,s1,8
    80001e46:	0921                	addi	s2,s2,8
    80001e48:	01348b63          	beq	s1,s3,80001e5e <fork+0xbe>
    if(p->ofile[i])
    80001e4c:	6088                	ld	a0,0(s1)
    80001e4e:	d97d                	beqz	a0,80001e44 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e50:	00002097          	auipc	ra,0x2
    80001e54:	67e080e7          	jalr	1662(ra) # 800044ce <filedup>
    80001e58:	00a93023          	sd	a0,0(s2)
    80001e5c:	b7e5                	j	80001e44 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e5e:	150ab503          	ld	a0,336(s5)
    80001e62:	00001097          	auipc	ra,0x1
    80001e66:	7de080e7          	jalr	2014(ra) # 80003640 <idup>
    80001e6a:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e6e:	4641                	li	a2,16
    80001e70:	158a8593          	addi	a1,s5,344
    80001e74:	158a0513          	addi	a0,s4,344
    80001e78:	fffff097          	auipc	ra,0xfffff
    80001e7c:	f98080e7          	jalr	-104(ra) # 80000e10 <safestrcpy>
  pid = np->pid;
    80001e80:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e84:	8552                	mv	a0,s4
    80001e86:	fffff097          	auipc	ra,0xfffff
    80001e8a:	df0080e7          	jalr	-528(ra) # 80000c76 <release>
  acquire(&wait_lock);
    80001e8e:	0000f497          	auipc	s1,0xf
    80001e92:	42a48493          	addi	s1,s1,1066 # 800112b8 <wait_lock>
    80001e96:	8526                	mv	a0,s1
    80001e98:	fffff097          	auipc	ra,0xfffff
    80001e9c:	d2a080e7          	jalr	-726(ra) # 80000bc2 <acquire>
  np->parent = p;
    80001ea0:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001ea4:	8526                	mv	a0,s1
    80001ea6:	fffff097          	auipc	ra,0xfffff
    80001eaa:	dd0080e7          	jalr	-560(ra) # 80000c76 <release>
  acquire(&np->lock);
    80001eae:	8552                	mv	a0,s4
    80001eb0:	fffff097          	auipc	ra,0xfffff
    80001eb4:	d12080e7          	jalr	-750(ra) # 80000bc2 <acquire>
  np->state = RUNNABLE;
    80001eb8:	478d                	li	a5,3
    80001eba:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001ebe:	8552                	mv	a0,s4
    80001ec0:	fffff097          	auipc	ra,0xfffff
    80001ec4:	db6080e7          	jalr	-586(ra) # 80000c76 <release>
}
    80001ec8:	854a                	mv	a0,s2
    80001eca:	70e2                	ld	ra,56(sp)
    80001ecc:	7442                	ld	s0,48(sp)
    80001ece:	74a2                	ld	s1,40(sp)
    80001ed0:	7902                	ld	s2,32(sp)
    80001ed2:	69e2                	ld	s3,24(sp)
    80001ed4:	6a42                	ld	s4,16(sp)
    80001ed6:	6aa2                	ld	s5,8(sp)
    80001ed8:	6121                	addi	sp,sp,64
    80001eda:	8082                	ret
    return -1;
    80001edc:	597d                	li	s2,-1
    80001ede:	b7ed                	j	80001ec8 <fork+0x128>

0000000080001ee0 <scheduler>:
{
    80001ee0:	7139                	addi	sp,sp,-64
    80001ee2:	fc06                	sd	ra,56(sp)
    80001ee4:	f822                	sd	s0,48(sp)
    80001ee6:	f426                	sd	s1,40(sp)
    80001ee8:	f04a                	sd	s2,32(sp)
    80001eea:	ec4e                	sd	s3,24(sp)
    80001eec:	e852                	sd	s4,16(sp)
    80001eee:	e456                	sd	s5,8(sp)
    80001ef0:	e05a                	sd	s6,0(sp)
    80001ef2:	0080                	addi	s0,sp,64
    80001ef4:	8792                	mv	a5,tp
  int id = r_tp();
    80001ef6:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001ef8:	00779a93          	slli	s5,a5,0x7
    80001efc:	0000f717          	auipc	a4,0xf
    80001f00:	3a470713          	addi	a4,a4,932 # 800112a0 <pid_lock>
    80001f04:	9756                	add	a4,a4,s5
    80001f06:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001f0a:	0000f717          	auipc	a4,0xf
    80001f0e:	3ce70713          	addi	a4,a4,974 # 800112d8 <cpus+0x8>
    80001f12:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001f14:	498d                	li	s3,3
        p->state = RUNNING;
    80001f16:	4b11                	li	s6,4
        c->proc = p;
    80001f18:	079e                	slli	a5,a5,0x7
    80001f1a:	0000fa17          	auipc	s4,0xf
    80001f1e:	386a0a13          	addi	s4,s4,902 # 800112a0 <pid_lock>
    80001f22:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f24:	00015917          	auipc	s2,0x15
    80001f28:	1ac90913          	addi	s2,s2,428 # 800170d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f2c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f30:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f34:	10079073          	csrw	sstatus,a5
    80001f38:	0000f497          	auipc	s1,0xf
    80001f3c:	79848493          	addi	s1,s1,1944 # 800116d0 <proc>
    80001f40:	a811                	j	80001f54 <scheduler+0x74>
      release(&p->lock);
    80001f42:	8526                	mv	a0,s1
    80001f44:	fffff097          	auipc	ra,0xfffff
    80001f48:	d32080e7          	jalr	-718(ra) # 80000c76 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f4c:	16848493          	addi	s1,s1,360
    80001f50:	fd248ee3          	beq	s1,s2,80001f2c <scheduler+0x4c>
      acquire(&p->lock);
    80001f54:	8526                	mv	a0,s1
    80001f56:	fffff097          	auipc	ra,0xfffff
    80001f5a:	c6c080e7          	jalr	-916(ra) # 80000bc2 <acquire>
      if(p->state == RUNNABLE) {
    80001f5e:	4c9c                	lw	a5,24(s1)
    80001f60:	ff3791e3          	bne	a5,s3,80001f42 <scheduler+0x62>
        p->state = RUNNING;
    80001f64:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f68:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f6c:	06048593          	addi	a1,s1,96
    80001f70:	8556                	mv	a0,s5
    80001f72:	00000097          	auipc	ra,0x0
    80001f76:	620080e7          	jalr	1568(ra) # 80002592 <swtch>
        c->proc = 0;
    80001f7a:	020a3823          	sd	zero,48(s4)
    80001f7e:	b7d1                	j	80001f42 <scheduler+0x62>

0000000080001f80 <sched>:
{
    80001f80:	7179                	addi	sp,sp,-48
    80001f82:	f406                	sd	ra,40(sp)
    80001f84:	f022                	sd	s0,32(sp)
    80001f86:	ec26                	sd	s1,24(sp)
    80001f88:	e84a                	sd	s2,16(sp)
    80001f8a:	e44e                	sd	s3,8(sp)
    80001f8c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f8e:	00000097          	auipc	ra,0x0
    80001f92:	a44080e7          	jalr	-1468(ra) # 800019d2 <myproc>
    80001f96:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f98:	fffff097          	auipc	ra,0xfffff
    80001f9c:	bb0080e7          	jalr	-1104(ra) # 80000b48 <holding>
    80001fa0:	c93d                	beqz	a0,80002016 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fa2:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001fa4:	2781                	sext.w	a5,a5
    80001fa6:	079e                	slli	a5,a5,0x7
    80001fa8:	0000f717          	auipc	a4,0xf
    80001fac:	2f870713          	addi	a4,a4,760 # 800112a0 <pid_lock>
    80001fb0:	97ba                	add	a5,a5,a4
    80001fb2:	0a87a703          	lw	a4,168(a5)
    80001fb6:	4785                	li	a5,1
    80001fb8:	06f71763          	bne	a4,a5,80002026 <sched+0xa6>
  if(p->state == RUNNING)
    80001fbc:	4c98                	lw	a4,24(s1)
    80001fbe:	4791                	li	a5,4
    80001fc0:	06f70b63          	beq	a4,a5,80002036 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fc4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001fc8:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001fca:	efb5                	bnez	a5,80002046 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fcc:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001fce:	0000f917          	auipc	s2,0xf
    80001fd2:	2d290913          	addi	s2,s2,722 # 800112a0 <pid_lock>
    80001fd6:	2781                	sext.w	a5,a5
    80001fd8:	079e                	slli	a5,a5,0x7
    80001fda:	97ca                	add	a5,a5,s2
    80001fdc:	0ac7a983          	lw	s3,172(a5)
    80001fe0:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001fe2:	2781                	sext.w	a5,a5
    80001fe4:	079e                	slli	a5,a5,0x7
    80001fe6:	0000f597          	auipc	a1,0xf
    80001fea:	2f258593          	addi	a1,a1,754 # 800112d8 <cpus+0x8>
    80001fee:	95be                	add	a1,a1,a5
    80001ff0:	06048513          	addi	a0,s1,96
    80001ff4:	00000097          	auipc	ra,0x0
    80001ff8:	59e080e7          	jalr	1438(ra) # 80002592 <swtch>
    80001ffc:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001ffe:	2781                	sext.w	a5,a5
    80002000:	079e                	slli	a5,a5,0x7
    80002002:	97ca                	add	a5,a5,s2
    80002004:	0b37a623          	sw	s3,172(a5)
}
    80002008:	70a2                	ld	ra,40(sp)
    8000200a:	7402                	ld	s0,32(sp)
    8000200c:	64e2                	ld	s1,24(sp)
    8000200e:	6942                	ld	s2,16(sp)
    80002010:	69a2                	ld	s3,8(sp)
    80002012:	6145                	addi	sp,sp,48
    80002014:	8082                	ret
    panic("sched p->lock");
    80002016:	00006517          	auipc	a0,0x6
    8000201a:	1ca50513          	addi	a0,a0,458 # 800081e0 <digits+0x1a0>
    8000201e:	ffffe097          	auipc	ra,0xffffe
    80002022:	50c080e7          	jalr	1292(ra) # 8000052a <panic>
    panic("sched locks");
    80002026:	00006517          	auipc	a0,0x6
    8000202a:	1ca50513          	addi	a0,a0,458 # 800081f0 <digits+0x1b0>
    8000202e:	ffffe097          	auipc	ra,0xffffe
    80002032:	4fc080e7          	jalr	1276(ra) # 8000052a <panic>
    panic("sched running");
    80002036:	00006517          	auipc	a0,0x6
    8000203a:	1ca50513          	addi	a0,a0,458 # 80008200 <digits+0x1c0>
    8000203e:	ffffe097          	auipc	ra,0xffffe
    80002042:	4ec080e7          	jalr	1260(ra) # 8000052a <panic>
    panic("sched interruptible");
    80002046:	00006517          	auipc	a0,0x6
    8000204a:	1ca50513          	addi	a0,a0,458 # 80008210 <digits+0x1d0>
    8000204e:	ffffe097          	auipc	ra,0xffffe
    80002052:	4dc080e7          	jalr	1244(ra) # 8000052a <panic>

0000000080002056 <yield>:
{
    80002056:	1101                	addi	sp,sp,-32
    80002058:	ec06                	sd	ra,24(sp)
    8000205a:	e822                	sd	s0,16(sp)
    8000205c:	e426                	sd	s1,8(sp)
    8000205e:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002060:	00000097          	auipc	ra,0x0
    80002064:	972080e7          	jalr	-1678(ra) # 800019d2 <myproc>
    80002068:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000206a:	fffff097          	auipc	ra,0xfffff
    8000206e:	b58080e7          	jalr	-1192(ra) # 80000bc2 <acquire>
  p->state = RUNNABLE;
    80002072:	478d                	li	a5,3
    80002074:	cc9c                	sw	a5,24(s1)
  sched();
    80002076:	00000097          	auipc	ra,0x0
    8000207a:	f0a080e7          	jalr	-246(ra) # 80001f80 <sched>
  release(&p->lock);
    8000207e:	8526                	mv	a0,s1
    80002080:	fffff097          	auipc	ra,0xfffff
    80002084:	bf6080e7          	jalr	-1034(ra) # 80000c76 <release>
}
    80002088:	60e2                	ld	ra,24(sp)
    8000208a:	6442                	ld	s0,16(sp)
    8000208c:	64a2                	ld	s1,8(sp)
    8000208e:	6105                	addi	sp,sp,32
    80002090:	8082                	ret

0000000080002092 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002092:	7179                	addi	sp,sp,-48
    80002094:	f406                	sd	ra,40(sp)
    80002096:	f022                	sd	s0,32(sp)
    80002098:	ec26                	sd	s1,24(sp)
    8000209a:	e84a                	sd	s2,16(sp)
    8000209c:	e44e                	sd	s3,8(sp)
    8000209e:	1800                	addi	s0,sp,48
    800020a0:	89aa                	mv	s3,a0
    800020a2:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800020a4:	00000097          	auipc	ra,0x0
    800020a8:	92e080e7          	jalr	-1746(ra) # 800019d2 <myproc>
    800020ac:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    800020ae:	fffff097          	auipc	ra,0xfffff
    800020b2:	b14080e7          	jalr	-1260(ra) # 80000bc2 <acquire>
  release(lk);
    800020b6:	854a                	mv	a0,s2
    800020b8:	fffff097          	auipc	ra,0xfffff
    800020bc:	bbe080e7          	jalr	-1090(ra) # 80000c76 <release>

  // Go to sleep.
  p->chan = chan;
    800020c0:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800020c4:	4789                	li	a5,2
    800020c6:	cc9c                	sw	a5,24(s1)

  sched();
    800020c8:	00000097          	auipc	ra,0x0
    800020cc:	eb8080e7          	jalr	-328(ra) # 80001f80 <sched>

  // Tidy up.
  p->chan = 0;
    800020d0:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800020d4:	8526                	mv	a0,s1
    800020d6:	fffff097          	auipc	ra,0xfffff
    800020da:	ba0080e7          	jalr	-1120(ra) # 80000c76 <release>
  acquire(lk);
    800020de:	854a                	mv	a0,s2
    800020e0:	fffff097          	auipc	ra,0xfffff
    800020e4:	ae2080e7          	jalr	-1310(ra) # 80000bc2 <acquire>
}
    800020e8:	70a2                	ld	ra,40(sp)
    800020ea:	7402                	ld	s0,32(sp)
    800020ec:	64e2                	ld	s1,24(sp)
    800020ee:	6942                	ld	s2,16(sp)
    800020f0:	69a2                	ld	s3,8(sp)
    800020f2:	6145                	addi	sp,sp,48
    800020f4:	8082                	ret

00000000800020f6 <wait>:
{
    800020f6:	715d                	addi	sp,sp,-80
    800020f8:	e486                	sd	ra,72(sp)
    800020fa:	e0a2                	sd	s0,64(sp)
    800020fc:	fc26                	sd	s1,56(sp)
    800020fe:	f84a                	sd	s2,48(sp)
    80002100:	f44e                	sd	s3,40(sp)
    80002102:	f052                	sd	s4,32(sp)
    80002104:	ec56                	sd	s5,24(sp)
    80002106:	e85a                	sd	s6,16(sp)
    80002108:	e45e                	sd	s7,8(sp)
    8000210a:	e062                	sd	s8,0(sp)
    8000210c:	0880                	addi	s0,sp,80
    8000210e:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002110:	00000097          	auipc	ra,0x0
    80002114:	8c2080e7          	jalr	-1854(ra) # 800019d2 <myproc>
    80002118:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000211a:	0000f517          	auipc	a0,0xf
    8000211e:	19e50513          	addi	a0,a0,414 # 800112b8 <wait_lock>
    80002122:	fffff097          	auipc	ra,0xfffff
    80002126:	aa0080e7          	jalr	-1376(ra) # 80000bc2 <acquire>
    havekids = 0;
    8000212a:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    8000212c:	4a15                	li	s4,5
        havekids = 1;
    8000212e:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    80002130:	00015997          	auipc	s3,0x15
    80002134:	fa098993          	addi	s3,s3,-96 # 800170d0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002138:	0000fc17          	auipc	s8,0xf
    8000213c:	180c0c13          	addi	s8,s8,384 # 800112b8 <wait_lock>
    havekids = 0;
    80002140:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002142:	0000f497          	auipc	s1,0xf
    80002146:	58e48493          	addi	s1,s1,1422 # 800116d0 <proc>
    8000214a:	a0bd                	j	800021b8 <wait+0xc2>
          pid = np->pid;
    8000214c:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002150:	000b0e63          	beqz	s6,8000216c <wait+0x76>
    80002154:	4691                	li	a3,4
    80002156:	02c48613          	addi	a2,s1,44
    8000215a:	85da                	mv	a1,s6
    8000215c:	05093503          	ld	a0,80(s2)
    80002160:	fffff097          	auipc	ra,0xfffff
    80002164:	532080e7          	jalr	1330(ra) # 80001692 <copyout>
    80002168:	02054563          	bltz	a0,80002192 <wait+0x9c>
          freeproc(np);
    8000216c:	8526                	mv	a0,s1
    8000216e:	00000097          	auipc	ra,0x0
    80002172:	a16080e7          	jalr	-1514(ra) # 80001b84 <freeproc>
          release(&np->lock);
    80002176:	8526                	mv	a0,s1
    80002178:	fffff097          	auipc	ra,0xfffff
    8000217c:	afe080e7          	jalr	-1282(ra) # 80000c76 <release>
          release(&wait_lock);
    80002180:	0000f517          	auipc	a0,0xf
    80002184:	13850513          	addi	a0,a0,312 # 800112b8 <wait_lock>
    80002188:	fffff097          	auipc	ra,0xfffff
    8000218c:	aee080e7          	jalr	-1298(ra) # 80000c76 <release>
          return pid;
    80002190:	a09d                	j	800021f6 <wait+0x100>
            release(&np->lock);
    80002192:	8526                	mv	a0,s1
    80002194:	fffff097          	auipc	ra,0xfffff
    80002198:	ae2080e7          	jalr	-1310(ra) # 80000c76 <release>
            release(&wait_lock);
    8000219c:	0000f517          	auipc	a0,0xf
    800021a0:	11c50513          	addi	a0,a0,284 # 800112b8 <wait_lock>
    800021a4:	fffff097          	auipc	ra,0xfffff
    800021a8:	ad2080e7          	jalr	-1326(ra) # 80000c76 <release>
            return -1;
    800021ac:	59fd                	li	s3,-1
    800021ae:	a0a1                	j	800021f6 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    800021b0:	16848493          	addi	s1,s1,360
    800021b4:	03348463          	beq	s1,s3,800021dc <wait+0xe6>
      if(np->parent == p){
    800021b8:	7c9c                	ld	a5,56(s1)
    800021ba:	ff279be3          	bne	a5,s2,800021b0 <wait+0xba>
        acquire(&np->lock);
    800021be:	8526                	mv	a0,s1
    800021c0:	fffff097          	auipc	ra,0xfffff
    800021c4:	a02080e7          	jalr	-1534(ra) # 80000bc2 <acquire>
        if(np->state == ZOMBIE){
    800021c8:	4c9c                	lw	a5,24(s1)
    800021ca:	f94781e3          	beq	a5,s4,8000214c <wait+0x56>
        release(&np->lock);
    800021ce:	8526                	mv	a0,s1
    800021d0:	fffff097          	auipc	ra,0xfffff
    800021d4:	aa6080e7          	jalr	-1370(ra) # 80000c76 <release>
        havekids = 1;
    800021d8:	8756                	mv	a4,s5
    800021da:	bfd9                	j	800021b0 <wait+0xba>
    if(!havekids || p->killed){
    800021dc:	c701                	beqz	a4,800021e4 <wait+0xee>
    800021de:	02892783          	lw	a5,40(s2)
    800021e2:	c79d                	beqz	a5,80002210 <wait+0x11a>
      release(&wait_lock);
    800021e4:	0000f517          	auipc	a0,0xf
    800021e8:	0d450513          	addi	a0,a0,212 # 800112b8 <wait_lock>
    800021ec:	fffff097          	auipc	ra,0xfffff
    800021f0:	a8a080e7          	jalr	-1398(ra) # 80000c76 <release>
      return -1;
    800021f4:	59fd                	li	s3,-1
}
    800021f6:	854e                	mv	a0,s3
    800021f8:	60a6                	ld	ra,72(sp)
    800021fa:	6406                	ld	s0,64(sp)
    800021fc:	74e2                	ld	s1,56(sp)
    800021fe:	7942                	ld	s2,48(sp)
    80002200:	79a2                	ld	s3,40(sp)
    80002202:	7a02                	ld	s4,32(sp)
    80002204:	6ae2                	ld	s5,24(sp)
    80002206:	6b42                	ld	s6,16(sp)
    80002208:	6ba2                	ld	s7,8(sp)
    8000220a:	6c02                	ld	s8,0(sp)
    8000220c:	6161                	addi	sp,sp,80
    8000220e:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002210:	85e2                	mv	a1,s8
    80002212:	854a                	mv	a0,s2
    80002214:	00000097          	auipc	ra,0x0
    80002218:	e7e080e7          	jalr	-386(ra) # 80002092 <sleep>
    havekids = 0;
    8000221c:	b715                	j	80002140 <wait+0x4a>

000000008000221e <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    8000221e:	7139                	addi	sp,sp,-64
    80002220:	fc06                	sd	ra,56(sp)
    80002222:	f822                	sd	s0,48(sp)
    80002224:	f426                	sd	s1,40(sp)
    80002226:	f04a                	sd	s2,32(sp)
    80002228:	ec4e                	sd	s3,24(sp)
    8000222a:	e852                	sd	s4,16(sp)
    8000222c:	e456                	sd	s5,8(sp)
    8000222e:	0080                	addi	s0,sp,64
    80002230:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002232:	0000f497          	auipc	s1,0xf
    80002236:	49e48493          	addi	s1,s1,1182 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    8000223a:	4989                	li	s3,2
        p->state = RUNNABLE;
    8000223c:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    8000223e:	00015917          	auipc	s2,0x15
    80002242:	e9290913          	addi	s2,s2,-366 # 800170d0 <tickslock>
    80002246:	a811                	j	8000225a <wakeup+0x3c>
      }
      release(&p->lock);
    80002248:	8526                	mv	a0,s1
    8000224a:	fffff097          	auipc	ra,0xfffff
    8000224e:	a2c080e7          	jalr	-1492(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002252:	16848493          	addi	s1,s1,360
    80002256:	03248663          	beq	s1,s2,80002282 <wakeup+0x64>
    if(p != myproc()){
    8000225a:	fffff097          	auipc	ra,0xfffff
    8000225e:	778080e7          	jalr	1912(ra) # 800019d2 <myproc>
    80002262:	fea488e3          	beq	s1,a0,80002252 <wakeup+0x34>
      acquire(&p->lock);
    80002266:	8526                	mv	a0,s1
    80002268:	fffff097          	auipc	ra,0xfffff
    8000226c:	95a080e7          	jalr	-1702(ra) # 80000bc2 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002270:	4c9c                	lw	a5,24(s1)
    80002272:	fd379be3          	bne	a5,s3,80002248 <wakeup+0x2a>
    80002276:	709c                	ld	a5,32(s1)
    80002278:	fd4798e3          	bne	a5,s4,80002248 <wakeup+0x2a>
        p->state = RUNNABLE;
    8000227c:	0154ac23          	sw	s5,24(s1)
    80002280:	b7e1                	j	80002248 <wakeup+0x2a>
    }
  }
}
    80002282:	70e2                	ld	ra,56(sp)
    80002284:	7442                	ld	s0,48(sp)
    80002286:	74a2                	ld	s1,40(sp)
    80002288:	7902                	ld	s2,32(sp)
    8000228a:	69e2                	ld	s3,24(sp)
    8000228c:	6a42                	ld	s4,16(sp)
    8000228e:	6aa2                	ld	s5,8(sp)
    80002290:	6121                	addi	sp,sp,64
    80002292:	8082                	ret

0000000080002294 <reparent>:
{
    80002294:	7179                	addi	sp,sp,-48
    80002296:	f406                	sd	ra,40(sp)
    80002298:	f022                	sd	s0,32(sp)
    8000229a:	ec26                	sd	s1,24(sp)
    8000229c:	e84a                	sd	s2,16(sp)
    8000229e:	e44e                	sd	s3,8(sp)
    800022a0:	e052                	sd	s4,0(sp)
    800022a2:	1800                	addi	s0,sp,48
    800022a4:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800022a6:	0000f497          	auipc	s1,0xf
    800022aa:	42a48493          	addi	s1,s1,1066 # 800116d0 <proc>
      pp->parent = initproc;
    800022ae:	00007a17          	auipc	s4,0x7
    800022b2:	d7aa0a13          	addi	s4,s4,-646 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800022b6:	00015997          	auipc	s3,0x15
    800022ba:	e1a98993          	addi	s3,s3,-486 # 800170d0 <tickslock>
    800022be:	a029                	j	800022c8 <reparent+0x34>
    800022c0:	16848493          	addi	s1,s1,360
    800022c4:	01348d63          	beq	s1,s3,800022de <reparent+0x4a>
    if(pp->parent == p){
    800022c8:	7c9c                	ld	a5,56(s1)
    800022ca:	ff279be3          	bne	a5,s2,800022c0 <reparent+0x2c>
      pp->parent = initproc;
    800022ce:	000a3503          	ld	a0,0(s4)
    800022d2:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800022d4:	00000097          	auipc	ra,0x0
    800022d8:	f4a080e7          	jalr	-182(ra) # 8000221e <wakeup>
    800022dc:	b7d5                	j	800022c0 <reparent+0x2c>
}
    800022de:	70a2                	ld	ra,40(sp)
    800022e0:	7402                	ld	s0,32(sp)
    800022e2:	64e2                	ld	s1,24(sp)
    800022e4:	6942                	ld	s2,16(sp)
    800022e6:	69a2                	ld	s3,8(sp)
    800022e8:	6a02                	ld	s4,0(sp)
    800022ea:	6145                	addi	sp,sp,48
    800022ec:	8082                	ret

00000000800022ee <exit>:
{
    800022ee:	7179                	addi	sp,sp,-48
    800022f0:	f406                	sd	ra,40(sp)
    800022f2:	f022                	sd	s0,32(sp)
    800022f4:	ec26                	sd	s1,24(sp)
    800022f6:	e84a                	sd	s2,16(sp)
    800022f8:	e44e                	sd	s3,8(sp)
    800022fa:	e052                	sd	s4,0(sp)
    800022fc:	1800                	addi	s0,sp,48
    800022fe:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002300:	fffff097          	auipc	ra,0xfffff
    80002304:	6d2080e7          	jalr	1746(ra) # 800019d2 <myproc>
    80002308:	89aa                	mv	s3,a0
  if(p == initproc)
    8000230a:	00007797          	auipc	a5,0x7
    8000230e:	d1e7b783          	ld	a5,-738(a5) # 80009028 <initproc>
    80002312:	0d050493          	addi	s1,a0,208
    80002316:	15050913          	addi	s2,a0,336
    8000231a:	02a79363          	bne	a5,a0,80002340 <exit+0x52>
    panic("init exiting");
    8000231e:	00006517          	auipc	a0,0x6
    80002322:	f0a50513          	addi	a0,a0,-246 # 80008228 <digits+0x1e8>
    80002326:	ffffe097          	auipc	ra,0xffffe
    8000232a:	204080e7          	jalr	516(ra) # 8000052a <panic>
      fileclose(f);
    8000232e:	00002097          	auipc	ra,0x2
    80002332:	1f2080e7          	jalr	498(ra) # 80004520 <fileclose>
      p->ofile[fd] = 0;
    80002336:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000233a:	04a1                	addi	s1,s1,8
    8000233c:	01248563          	beq	s1,s2,80002346 <exit+0x58>
    if(p->ofile[fd]){
    80002340:	6088                	ld	a0,0(s1)
    80002342:	f575                	bnez	a0,8000232e <exit+0x40>
    80002344:	bfdd                	j	8000233a <exit+0x4c>
  begin_op();
    80002346:	00002097          	auipc	ra,0x2
    8000234a:	d0e080e7          	jalr	-754(ra) # 80004054 <begin_op>
  iput(p->cwd);
    8000234e:	1509b503          	ld	a0,336(s3)
    80002352:	00001097          	auipc	ra,0x1
    80002356:	4e6080e7          	jalr	1254(ra) # 80003838 <iput>
  end_op();
    8000235a:	00002097          	auipc	ra,0x2
    8000235e:	d7a080e7          	jalr	-646(ra) # 800040d4 <end_op>
  p->cwd = 0;
    80002362:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002366:	0000f497          	auipc	s1,0xf
    8000236a:	f5248493          	addi	s1,s1,-174 # 800112b8 <wait_lock>
    8000236e:	8526                	mv	a0,s1
    80002370:	fffff097          	auipc	ra,0xfffff
    80002374:	852080e7          	jalr	-1966(ra) # 80000bc2 <acquire>
  reparent(p);
    80002378:	854e                	mv	a0,s3
    8000237a:	00000097          	auipc	ra,0x0
    8000237e:	f1a080e7          	jalr	-230(ra) # 80002294 <reparent>
  wakeup(p->parent);
    80002382:	0389b503          	ld	a0,56(s3)
    80002386:	00000097          	auipc	ra,0x0
    8000238a:	e98080e7          	jalr	-360(ra) # 8000221e <wakeup>
  acquire(&p->lock);
    8000238e:	854e                	mv	a0,s3
    80002390:	fffff097          	auipc	ra,0xfffff
    80002394:	832080e7          	jalr	-1998(ra) # 80000bc2 <acquire>
  p->xstate = status;
    80002398:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000239c:	4795                	li	a5,5
    8000239e:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800023a2:	8526                	mv	a0,s1
    800023a4:	fffff097          	auipc	ra,0xfffff
    800023a8:	8d2080e7          	jalr	-1838(ra) # 80000c76 <release>
  sched();
    800023ac:	00000097          	auipc	ra,0x0
    800023b0:	bd4080e7          	jalr	-1068(ra) # 80001f80 <sched>
  panic("zombie exit");
    800023b4:	00006517          	auipc	a0,0x6
    800023b8:	e8450513          	addi	a0,a0,-380 # 80008238 <digits+0x1f8>
    800023bc:	ffffe097          	auipc	ra,0xffffe
    800023c0:	16e080e7          	jalr	366(ra) # 8000052a <panic>

00000000800023c4 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800023c4:	7179                	addi	sp,sp,-48
    800023c6:	f406                	sd	ra,40(sp)
    800023c8:	f022                	sd	s0,32(sp)
    800023ca:	ec26                	sd	s1,24(sp)
    800023cc:	e84a                	sd	s2,16(sp)
    800023ce:	e44e                	sd	s3,8(sp)
    800023d0:	1800                	addi	s0,sp,48
    800023d2:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800023d4:	0000f497          	auipc	s1,0xf
    800023d8:	2fc48493          	addi	s1,s1,764 # 800116d0 <proc>
    800023dc:	00015997          	auipc	s3,0x15
    800023e0:	cf498993          	addi	s3,s3,-780 # 800170d0 <tickslock>
    acquire(&p->lock);
    800023e4:	8526                	mv	a0,s1
    800023e6:	ffffe097          	auipc	ra,0xffffe
    800023ea:	7dc080e7          	jalr	2012(ra) # 80000bc2 <acquire>
    if(p->pid == pid){
    800023ee:	589c                	lw	a5,48(s1)
    800023f0:	01278d63          	beq	a5,s2,8000240a <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800023f4:	8526                	mv	a0,s1
    800023f6:	fffff097          	auipc	ra,0xfffff
    800023fa:	880080e7          	jalr	-1920(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800023fe:	16848493          	addi	s1,s1,360
    80002402:	ff3491e3          	bne	s1,s3,800023e4 <kill+0x20>
  }
  return -1;
    80002406:	557d                	li	a0,-1
    80002408:	a829                	j	80002422 <kill+0x5e>
      p->killed = 1;
    8000240a:	4785                	li	a5,1
    8000240c:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    8000240e:	4c98                	lw	a4,24(s1)
    80002410:	4789                	li	a5,2
    80002412:	00f70f63          	beq	a4,a5,80002430 <kill+0x6c>
      release(&p->lock);
    80002416:	8526                	mv	a0,s1
    80002418:	fffff097          	auipc	ra,0xfffff
    8000241c:	85e080e7          	jalr	-1954(ra) # 80000c76 <release>
      return 0;
    80002420:	4501                	li	a0,0
}
    80002422:	70a2                	ld	ra,40(sp)
    80002424:	7402                	ld	s0,32(sp)
    80002426:	64e2                	ld	s1,24(sp)
    80002428:	6942                	ld	s2,16(sp)
    8000242a:	69a2                	ld	s3,8(sp)
    8000242c:	6145                	addi	sp,sp,48
    8000242e:	8082                	ret
        p->state = RUNNABLE;
    80002430:	478d                	li	a5,3
    80002432:	cc9c                	sw	a5,24(s1)
    80002434:	b7cd                	j	80002416 <kill+0x52>

0000000080002436 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002436:	7179                	addi	sp,sp,-48
    80002438:	f406                	sd	ra,40(sp)
    8000243a:	f022                	sd	s0,32(sp)
    8000243c:	ec26                	sd	s1,24(sp)
    8000243e:	e84a                	sd	s2,16(sp)
    80002440:	e44e                	sd	s3,8(sp)
    80002442:	e052                	sd	s4,0(sp)
    80002444:	1800                	addi	s0,sp,48
    80002446:	84aa                	mv	s1,a0
    80002448:	892e                	mv	s2,a1
    8000244a:	89b2                	mv	s3,a2
    8000244c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000244e:	fffff097          	auipc	ra,0xfffff
    80002452:	584080e7          	jalr	1412(ra) # 800019d2 <myproc>
  if(user_dst){
    80002456:	c08d                	beqz	s1,80002478 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002458:	86d2                	mv	a3,s4
    8000245a:	864e                	mv	a2,s3
    8000245c:	85ca                	mv	a1,s2
    8000245e:	6928                	ld	a0,80(a0)
    80002460:	fffff097          	auipc	ra,0xfffff
    80002464:	232080e7          	jalr	562(ra) # 80001692 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002468:	70a2                	ld	ra,40(sp)
    8000246a:	7402                	ld	s0,32(sp)
    8000246c:	64e2                	ld	s1,24(sp)
    8000246e:	6942                	ld	s2,16(sp)
    80002470:	69a2                	ld	s3,8(sp)
    80002472:	6a02                	ld	s4,0(sp)
    80002474:	6145                	addi	sp,sp,48
    80002476:	8082                	ret
    memmove((char *)dst, src, len);
    80002478:	000a061b          	sext.w	a2,s4
    8000247c:	85ce                	mv	a1,s3
    8000247e:	854a                	mv	a0,s2
    80002480:	fffff097          	auipc	ra,0xfffff
    80002484:	89a080e7          	jalr	-1894(ra) # 80000d1a <memmove>
    return 0;
    80002488:	8526                	mv	a0,s1
    8000248a:	bff9                	j	80002468 <either_copyout+0x32>

000000008000248c <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000248c:	7179                	addi	sp,sp,-48
    8000248e:	f406                	sd	ra,40(sp)
    80002490:	f022                	sd	s0,32(sp)
    80002492:	ec26                	sd	s1,24(sp)
    80002494:	e84a                	sd	s2,16(sp)
    80002496:	e44e                	sd	s3,8(sp)
    80002498:	e052                	sd	s4,0(sp)
    8000249a:	1800                	addi	s0,sp,48
    8000249c:	892a                	mv	s2,a0
    8000249e:	84ae                	mv	s1,a1
    800024a0:	89b2                	mv	s3,a2
    800024a2:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024a4:	fffff097          	auipc	ra,0xfffff
    800024a8:	52e080e7          	jalr	1326(ra) # 800019d2 <myproc>
  if(user_src){
    800024ac:	c08d                	beqz	s1,800024ce <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800024ae:	86d2                	mv	a3,s4
    800024b0:	864e                	mv	a2,s3
    800024b2:	85ca                	mv	a1,s2
    800024b4:	6928                	ld	a0,80(a0)
    800024b6:	fffff097          	auipc	ra,0xfffff
    800024ba:	268080e7          	jalr	616(ra) # 8000171e <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800024be:	70a2                	ld	ra,40(sp)
    800024c0:	7402                	ld	s0,32(sp)
    800024c2:	64e2                	ld	s1,24(sp)
    800024c4:	6942                	ld	s2,16(sp)
    800024c6:	69a2                	ld	s3,8(sp)
    800024c8:	6a02                	ld	s4,0(sp)
    800024ca:	6145                	addi	sp,sp,48
    800024cc:	8082                	ret
    memmove(dst, (char*)src, len);
    800024ce:	000a061b          	sext.w	a2,s4
    800024d2:	85ce                	mv	a1,s3
    800024d4:	854a                	mv	a0,s2
    800024d6:	fffff097          	auipc	ra,0xfffff
    800024da:	844080e7          	jalr	-1980(ra) # 80000d1a <memmove>
    return 0;
    800024de:	8526                	mv	a0,s1
    800024e0:	bff9                	j	800024be <either_copyin+0x32>

00000000800024e2 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800024e2:	715d                	addi	sp,sp,-80
    800024e4:	e486                	sd	ra,72(sp)
    800024e6:	e0a2                	sd	s0,64(sp)
    800024e8:	fc26                	sd	s1,56(sp)
    800024ea:	f84a                	sd	s2,48(sp)
    800024ec:	f44e                	sd	s3,40(sp)
    800024ee:	f052                	sd	s4,32(sp)
    800024f0:	ec56                	sd	s5,24(sp)
    800024f2:	e85a                	sd	s6,16(sp)
    800024f4:	e45e                	sd	s7,8(sp)
    800024f6:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800024f8:	00006517          	auipc	a0,0x6
    800024fc:	bd050513          	addi	a0,a0,-1072 # 800080c8 <digits+0x88>
    80002500:	ffffe097          	auipc	ra,0xffffe
    80002504:	074080e7          	jalr	116(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002508:	0000f497          	auipc	s1,0xf
    8000250c:	32048493          	addi	s1,s1,800 # 80011828 <proc+0x158>
    80002510:	00015917          	auipc	s2,0x15
    80002514:	d1890913          	addi	s2,s2,-744 # 80017228 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002518:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000251a:	00006997          	auipc	s3,0x6
    8000251e:	d2e98993          	addi	s3,s3,-722 # 80008248 <digits+0x208>
    printf("%d %s %s", p->pid, state, p->name);
    80002522:	00006a97          	auipc	s5,0x6
    80002526:	d2ea8a93          	addi	s5,s5,-722 # 80008250 <digits+0x210>
    printf("\n");
    8000252a:	00006a17          	auipc	s4,0x6
    8000252e:	b9ea0a13          	addi	s4,s4,-1122 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002532:	00006b97          	auipc	s7,0x6
    80002536:	d56b8b93          	addi	s7,s7,-682 # 80008288 <states.0>
    8000253a:	a00d                	j	8000255c <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000253c:	ed86a583          	lw	a1,-296(a3)
    80002540:	8556                	mv	a0,s5
    80002542:	ffffe097          	auipc	ra,0xffffe
    80002546:	032080e7          	jalr	50(ra) # 80000574 <printf>
    printf("\n");
    8000254a:	8552                	mv	a0,s4
    8000254c:	ffffe097          	auipc	ra,0xffffe
    80002550:	028080e7          	jalr	40(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002554:	16848493          	addi	s1,s1,360
    80002558:	03248263          	beq	s1,s2,8000257c <procdump+0x9a>
    if(p->state == UNUSED)
    8000255c:	86a6                	mv	a3,s1
    8000255e:	ec04a783          	lw	a5,-320(s1)
    80002562:	dbed                	beqz	a5,80002554 <procdump+0x72>
      state = "???";
    80002564:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002566:	fcfb6be3          	bltu	s6,a5,8000253c <procdump+0x5a>
    8000256a:	02079713          	slli	a4,a5,0x20
    8000256e:	01d75793          	srli	a5,a4,0x1d
    80002572:	97de                	add	a5,a5,s7
    80002574:	6390                	ld	a2,0(a5)
    80002576:	f279                	bnez	a2,8000253c <procdump+0x5a>
      state = "???";
    80002578:	864e                	mv	a2,s3
    8000257a:	b7c9                	j	8000253c <procdump+0x5a>
  }
}
    8000257c:	60a6                	ld	ra,72(sp)
    8000257e:	6406                	ld	s0,64(sp)
    80002580:	74e2                	ld	s1,56(sp)
    80002582:	7942                	ld	s2,48(sp)
    80002584:	79a2                	ld	s3,40(sp)
    80002586:	7a02                	ld	s4,32(sp)
    80002588:	6ae2                	ld	s5,24(sp)
    8000258a:	6b42                	ld	s6,16(sp)
    8000258c:	6ba2                	ld	s7,8(sp)
    8000258e:	6161                	addi	sp,sp,80
    80002590:	8082                	ret

0000000080002592 <swtch>:
    80002592:	00153023          	sd	ra,0(a0)
    80002596:	00253423          	sd	sp,8(a0)
    8000259a:	e900                	sd	s0,16(a0)
    8000259c:	ed04                	sd	s1,24(a0)
    8000259e:	03253023          	sd	s2,32(a0)
    800025a2:	03353423          	sd	s3,40(a0)
    800025a6:	03453823          	sd	s4,48(a0)
    800025aa:	03553c23          	sd	s5,56(a0)
    800025ae:	05653023          	sd	s6,64(a0)
    800025b2:	05753423          	sd	s7,72(a0)
    800025b6:	05853823          	sd	s8,80(a0)
    800025ba:	05953c23          	sd	s9,88(a0)
    800025be:	07a53023          	sd	s10,96(a0)
    800025c2:	07b53423          	sd	s11,104(a0)
    800025c6:	0005b083          	ld	ra,0(a1)
    800025ca:	0085b103          	ld	sp,8(a1)
    800025ce:	6980                	ld	s0,16(a1)
    800025d0:	6d84                	ld	s1,24(a1)
    800025d2:	0205b903          	ld	s2,32(a1)
    800025d6:	0285b983          	ld	s3,40(a1)
    800025da:	0305ba03          	ld	s4,48(a1)
    800025de:	0385ba83          	ld	s5,56(a1)
    800025e2:	0405bb03          	ld	s6,64(a1)
    800025e6:	0485bb83          	ld	s7,72(a1)
    800025ea:	0505bc03          	ld	s8,80(a1)
    800025ee:	0585bc83          	ld	s9,88(a1)
    800025f2:	0605bd03          	ld	s10,96(a1)
    800025f6:	0685bd83          	ld	s11,104(a1)
    800025fa:	8082                	ret

00000000800025fc <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800025fc:	1141                	addi	sp,sp,-16
    800025fe:	e406                	sd	ra,8(sp)
    80002600:	e022                	sd	s0,0(sp)
    80002602:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002604:	00006597          	auipc	a1,0x6
    80002608:	cb458593          	addi	a1,a1,-844 # 800082b8 <states.0+0x30>
    8000260c:	00015517          	auipc	a0,0x15
    80002610:	ac450513          	addi	a0,a0,-1340 # 800170d0 <tickslock>
    80002614:	ffffe097          	auipc	ra,0xffffe
    80002618:	51e080e7          	jalr	1310(ra) # 80000b32 <initlock>
}
    8000261c:	60a2                	ld	ra,8(sp)
    8000261e:	6402                	ld	s0,0(sp)
    80002620:	0141                	addi	sp,sp,16
    80002622:	8082                	ret

0000000080002624 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002624:	1141                	addi	sp,sp,-16
    80002626:	e422                	sd	s0,8(sp)
    80002628:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000262a:	00003797          	auipc	a5,0x3
    8000262e:	52678793          	addi	a5,a5,1318 # 80005b50 <kernelvec>
    80002632:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002636:	6422                	ld	s0,8(sp)
    80002638:	0141                	addi	sp,sp,16
    8000263a:	8082                	ret

000000008000263c <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000263c:	1141                	addi	sp,sp,-16
    8000263e:	e406                	sd	ra,8(sp)
    80002640:	e022                	sd	s0,0(sp)
    80002642:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002644:	fffff097          	auipc	ra,0xfffff
    80002648:	38e080e7          	jalr	910(ra) # 800019d2 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000264c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002650:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002652:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002656:	00005617          	auipc	a2,0x5
    8000265a:	9aa60613          	addi	a2,a2,-1622 # 80007000 <_trampoline>
    8000265e:	00005697          	auipc	a3,0x5
    80002662:	9a268693          	addi	a3,a3,-1630 # 80007000 <_trampoline>
    80002666:	8e91                	sub	a3,a3,a2
    80002668:	040007b7          	lui	a5,0x4000
    8000266c:	17fd                	addi	a5,a5,-1
    8000266e:	07b2                	slli	a5,a5,0xc
    80002670:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002672:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002676:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002678:	180026f3          	csrr	a3,satp
    8000267c:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000267e:	6d38                	ld	a4,88(a0)
    80002680:	6134                	ld	a3,64(a0)
    80002682:	6585                	lui	a1,0x1
    80002684:	96ae                	add	a3,a3,a1
    80002686:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002688:	6d38                	ld	a4,88(a0)
    8000268a:	00000697          	auipc	a3,0x0
    8000268e:	13868693          	addi	a3,a3,312 # 800027c2 <usertrap>
    80002692:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002694:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002696:	8692                	mv	a3,tp
    80002698:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000269a:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000269e:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800026a2:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026a6:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800026aa:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800026ac:	6f18                	ld	a4,24(a4)
    800026ae:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800026b2:	692c                	ld	a1,80(a0)
    800026b4:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800026b6:	00005717          	auipc	a4,0x5
    800026ba:	9da70713          	addi	a4,a4,-1574 # 80007090 <userret>
    800026be:	8f11                	sub	a4,a4,a2
    800026c0:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800026c2:	577d                	li	a4,-1
    800026c4:	177e                	slli	a4,a4,0x3f
    800026c6:	8dd9                	or	a1,a1,a4
    800026c8:	02000537          	lui	a0,0x2000
    800026cc:	157d                	addi	a0,a0,-1
    800026ce:	0536                	slli	a0,a0,0xd
    800026d0:	9782                	jalr	a5
}
    800026d2:	60a2                	ld	ra,8(sp)
    800026d4:	6402                	ld	s0,0(sp)
    800026d6:	0141                	addi	sp,sp,16
    800026d8:	8082                	ret

00000000800026da <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800026da:	1101                	addi	sp,sp,-32
    800026dc:	ec06                	sd	ra,24(sp)
    800026de:	e822                	sd	s0,16(sp)
    800026e0:	e426                	sd	s1,8(sp)
    800026e2:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800026e4:	00015497          	auipc	s1,0x15
    800026e8:	9ec48493          	addi	s1,s1,-1556 # 800170d0 <tickslock>
    800026ec:	8526                	mv	a0,s1
    800026ee:	ffffe097          	auipc	ra,0xffffe
    800026f2:	4d4080e7          	jalr	1236(ra) # 80000bc2 <acquire>
  ticks++;
    800026f6:	00007517          	auipc	a0,0x7
    800026fa:	93a50513          	addi	a0,a0,-1734 # 80009030 <ticks>
    800026fe:	411c                	lw	a5,0(a0)
    80002700:	2785                	addiw	a5,a5,1
    80002702:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002704:	00000097          	auipc	ra,0x0
    80002708:	b1a080e7          	jalr	-1254(ra) # 8000221e <wakeup>
  release(&tickslock);
    8000270c:	8526                	mv	a0,s1
    8000270e:	ffffe097          	auipc	ra,0xffffe
    80002712:	568080e7          	jalr	1384(ra) # 80000c76 <release>
}
    80002716:	60e2                	ld	ra,24(sp)
    80002718:	6442                	ld	s0,16(sp)
    8000271a:	64a2                	ld	s1,8(sp)
    8000271c:	6105                	addi	sp,sp,32
    8000271e:	8082                	ret

0000000080002720 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002720:	1101                	addi	sp,sp,-32
    80002722:	ec06                	sd	ra,24(sp)
    80002724:	e822                	sd	s0,16(sp)
    80002726:	e426                	sd	s1,8(sp)
    80002728:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000272a:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000272e:	00074d63          	bltz	a4,80002748 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002732:	57fd                	li	a5,-1
    80002734:	17fe                	slli	a5,a5,0x3f
    80002736:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002738:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000273a:	06f70363          	beq	a4,a5,800027a0 <devintr+0x80>
  }
}
    8000273e:	60e2                	ld	ra,24(sp)
    80002740:	6442                	ld	s0,16(sp)
    80002742:	64a2                	ld	s1,8(sp)
    80002744:	6105                	addi	sp,sp,32
    80002746:	8082                	ret
     (scause & 0xff) == 9){
    80002748:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    8000274c:	46a5                	li	a3,9
    8000274e:	fed792e3          	bne	a5,a3,80002732 <devintr+0x12>
    int irq = plic_claim();
    80002752:	00003097          	auipc	ra,0x3
    80002756:	506080e7          	jalr	1286(ra) # 80005c58 <plic_claim>
    8000275a:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000275c:	47a9                	li	a5,10
    8000275e:	02f50763          	beq	a0,a5,8000278c <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002762:	4785                	li	a5,1
    80002764:	02f50963          	beq	a0,a5,80002796 <devintr+0x76>
    return 1;
    80002768:	4505                	li	a0,1
    } else if(irq){
    8000276a:	d8f1                	beqz	s1,8000273e <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    8000276c:	85a6                	mv	a1,s1
    8000276e:	00006517          	auipc	a0,0x6
    80002772:	b5250513          	addi	a0,a0,-1198 # 800082c0 <states.0+0x38>
    80002776:	ffffe097          	auipc	ra,0xffffe
    8000277a:	dfe080e7          	jalr	-514(ra) # 80000574 <printf>
      plic_complete(irq);
    8000277e:	8526                	mv	a0,s1
    80002780:	00003097          	auipc	ra,0x3
    80002784:	4fc080e7          	jalr	1276(ra) # 80005c7c <plic_complete>
    return 1;
    80002788:	4505                	li	a0,1
    8000278a:	bf55                	j	8000273e <devintr+0x1e>
      uartintr();
    8000278c:	ffffe097          	auipc	ra,0xffffe
    80002790:	1fa080e7          	jalr	506(ra) # 80000986 <uartintr>
    80002794:	b7ed                	j	8000277e <devintr+0x5e>
      virtio_disk_intr();
    80002796:	00004097          	auipc	ra,0x4
    8000279a:	978080e7          	jalr	-1672(ra) # 8000610e <virtio_disk_intr>
    8000279e:	b7c5                	j	8000277e <devintr+0x5e>
    if(cpuid() == 0){
    800027a0:	fffff097          	auipc	ra,0xfffff
    800027a4:	206080e7          	jalr	518(ra) # 800019a6 <cpuid>
    800027a8:	c901                	beqz	a0,800027b8 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800027aa:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800027ae:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800027b0:	14479073          	csrw	sip,a5
    return 2;
    800027b4:	4509                	li	a0,2
    800027b6:	b761                	j	8000273e <devintr+0x1e>
      clockintr();
    800027b8:	00000097          	auipc	ra,0x0
    800027bc:	f22080e7          	jalr	-222(ra) # 800026da <clockintr>
    800027c0:	b7ed                	j	800027aa <devintr+0x8a>

00000000800027c2 <usertrap>:
{
    800027c2:	7179                	addi	sp,sp,-48
    800027c4:	f406                	sd	ra,40(sp)
    800027c6:	f022                	sd	s0,32(sp)
    800027c8:	ec26                	sd	s1,24(sp)
    800027ca:	e84a                	sd	s2,16(sp)
    800027cc:	e44e                	sd	s3,8(sp)
    800027ce:	e052                	sd	s4,0(sp)
    800027d0:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027d2:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800027d6:	1007f793          	andi	a5,a5,256
    800027da:	e7a5                	bnez	a5,80002842 <usertrap+0x80>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027dc:	00003797          	auipc	a5,0x3
    800027e0:	37478793          	addi	a5,a5,884 # 80005b50 <kernelvec>
    800027e4:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800027e8:	fffff097          	auipc	ra,0xfffff
    800027ec:	1ea080e7          	jalr	490(ra) # 800019d2 <myproc>
    800027f0:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800027f2:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800027f4:	14102773          	csrr	a4,sepc
    800027f8:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027fa:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800027fe:	47a1                	li	a5,8
    80002800:	04f71f63          	bne	a4,a5,8000285e <usertrap+0x9c>
    if(p->killed)
    80002804:	551c                	lw	a5,40(a0)
    80002806:	e7b1                	bnez	a5,80002852 <usertrap+0x90>
    p->trapframe->epc += 4;
    80002808:	6cb8                	ld	a4,88(s1)
    8000280a:	6f1c                	ld	a5,24(a4)
    8000280c:	0791                	addi	a5,a5,4
    8000280e:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002810:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002814:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002818:	10079073          	csrw	sstatus,a5
    syscall();
    8000281c:	00000097          	auipc	ra,0x0
    80002820:	356080e7          	jalr	854(ra) # 80002b72 <syscall>
  if(p->killed)
    80002824:	549c                	lw	a5,40(s1)
    80002826:	10079363          	bnez	a5,8000292c <usertrap+0x16a>
  usertrapret();
    8000282a:	00000097          	auipc	ra,0x0
    8000282e:	e12080e7          	jalr	-494(ra) # 8000263c <usertrapret>
}
    80002832:	70a2                	ld	ra,40(sp)
    80002834:	7402                	ld	s0,32(sp)
    80002836:	64e2                	ld	s1,24(sp)
    80002838:	6942                	ld	s2,16(sp)
    8000283a:	69a2                	ld	s3,8(sp)
    8000283c:	6a02                	ld	s4,0(sp)
    8000283e:	6145                	addi	sp,sp,48
    80002840:	8082                	ret
    panic("usertrap: not from user mode");
    80002842:	00006517          	auipc	a0,0x6
    80002846:	a9e50513          	addi	a0,a0,-1378 # 800082e0 <states.0+0x58>
    8000284a:	ffffe097          	auipc	ra,0xffffe
    8000284e:	ce0080e7          	jalr	-800(ra) # 8000052a <panic>
      exit(-1);
    80002852:	557d                	li	a0,-1
    80002854:	00000097          	auipc	ra,0x0
    80002858:	a9a080e7          	jalr	-1382(ra) # 800022ee <exit>
    8000285c:	b775                	j	80002808 <usertrap+0x46>
  } else if((which_dev = devintr()) != 0){
    8000285e:	00000097          	auipc	ra,0x0
    80002862:	ec2080e7          	jalr	-318(ra) # 80002720 <devintr>
    80002866:	892a                	mv	s2,a0
    80002868:	ed5d                	bnez	a0,80002926 <usertrap+0x164>
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000286a:	14202773          	csrr	a4,scause
  } else if(r_scause() == 15){
    8000286e:	47bd                	li	a5,15
    80002870:	04f70863          	beq	a4,a5,800028c0 <usertrap+0xfe>
    80002874:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002878:	5890                	lw	a2,48(s1)
    8000287a:	00006517          	auipc	a0,0x6
    8000287e:	aae50513          	addi	a0,a0,-1362 # 80008328 <states.0+0xa0>
    80002882:	ffffe097          	auipc	ra,0xffffe
    80002886:	cf2080e7          	jalr	-782(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000288a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000288e:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002892:	00006517          	auipc	a0,0x6
    80002896:	ac650513          	addi	a0,a0,-1338 # 80008358 <states.0+0xd0>
    8000289a:	ffffe097          	auipc	ra,0xffffe
    8000289e:	cda080e7          	jalr	-806(ra) # 80000574 <printf>
    p->killed = 1;
    800028a2:	4785                	li	a5,1
    800028a4:	d49c                	sw	a5,40(s1)
    exit(-1);
    800028a6:	557d                	li	a0,-1
    800028a8:	00000097          	auipc	ra,0x0
    800028ac:	a46080e7          	jalr	-1466(ra) # 800022ee <exit>
  if(which_dev == 2)
    800028b0:	4789                	li	a5,2
    800028b2:	f6f91ce3          	bne	s2,a5,8000282a <usertrap+0x68>
    yield();
    800028b6:	fffff097          	auipc	ra,0xfffff
    800028ba:	7a0080e7          	jalr	1952(ra) # 80002056 <yield>
    800028be:	b7b5                	j	8000282a <usertrap+0x68>
    800028c0:	14302a73          	csrr	s4,stval
    if(va > myproc()->sz)
    800028c4:	fffff097          	auipc	ra,0xfffff
    800028c8:	10e080e7          	jalr	270(ra) # 800019d2 <myproc>
    800028cc:	653c                	ld	a5,72(a0)
    800028ce:	0347ec63          	bltu	a5,s4,80002906 <usertrap+0x144>
    uint64 pa = (uint64)kalloc();
    800028d2:	ffffe097          	auipc	ra,0xffffe
    800028d6:	200080e7          	jalr	512(ra) # 80000ad2 <kalloc>
    800028da:	89aa                	mv	s3,a0
    if(pa == 0){
    800028dc:	cd0d                	beqz	a0,80002916 <usertrap+0x154>
      if(mappages(p->pagetable, va, PGSIZE, pa, PTE_U|PTE_W|PTE_R) != 0){
    800028de:	4759                	li	a4,22
    800028e0:	86aa                	mv	a3,a0
    800028e2:	6605                	lui	a2,0x1
    800028e4:	75fd                	lui	a1,0xfffff
    800028e6:	00ba75b3          	and	a1,s4,a1
    800028ea:	68a8                	ld	a0,80(s1)
    800028ec:	ffffe097          	auipc	ra,0xffffe
    800028f0:	760080e7          	jalr	1888(ra) # 8000104c <mappages>
    800028f4:	d905                	beqz	a0,80002824 <usertrap+0x62>
        kfree((void *)pa);
    800028f6:	854e                	mv	a0,s3
    800028f8:	ffffe097          	auipc	ra,0xffffe
    800028fc:	0de080e7          	jalr	222(ra) # 800009d6 <kfree>
        p->killed = 1;
    80002900:	4785                	li	a5,1
    80002902:	d49c                	sw	a5,40(s1)
    80002904:	b74d                	j	800028a6 <usertrap+0xe4>
      panic("usertrap: va>sz");
    80002906:	00006517          	auipc	a0,0x6
    8000290a:	9fa50513          	addi	a0,a0,-1542 # 80008300 <states.0+0x78>
    8000290e:	ffffe097          	auipc	ra,0xffffe
    80002912:	c1c080e7          	jalr	-996(ra) # 8000052a <panic>
      panic("usertrap: kalloc");
    80002916:	00006517          	auipc	a0,0x6
    8000291a:	9fa50513          	addi	a0,a0,-1542 # 80008310 <states.0+0x88>
    8000291e:	ffffe097          	auipc	ra,0xffffe
    80002922:	c0c080e7          	jalr	-1012(ra) # 8000052a <panic>
  if(p->killed)
    80002926:	549c                	lw	a5,40(s1)
    80002928:	d7c1                	beqz	a5,800028b0 <usertrap+0xee>
    8000292a:	bfb5                	j	800028a6 <usertrap+0xe4>
    8000292c:	4901                	li	s2,0
    8000292e:	bfa5                	j	800028a6 <usertrap+0xe4>

0000000080002930 <kerneltrap>:
{
    80002930:	7179                	addi	sp,sp,-48
    80002932:	f406                	sd	ra,40(sp)
    80002934:	f022                	sd	s0,32(sp)
    80002936:	ec26                	sd	s1,24(sp)
    80002938:	e84a                	sd	s2,16(sp)
    8000293a:	e44e                	sd	s3,8(sp)
    8000293c:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000293e:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002942:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002946:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    8000294a:	1004f793          	andi	a5,s1,256
    8000294e:	cb85                	beqz	a5,8000297e <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002950:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002954:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002956:	ef85                	bnez	a5,8000298e <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002958:	00000097          	auipc	ra,0x0
    8000295c:	dc8080e7          	jalr	-568(ra) # 80002720 <devintr>
    80002960:	cd1d                	beqz	a0,8000299e <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002962:	4789                	li	a5,2
    80002964:	06f50a63          	beq	a0,a5,800029d8 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002968:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000296c:	10049073          	csrw	sstatus,s1
}
    80002970:	70a2                	ld	ra,40(sp)
    80002972:	7402                	ld	s0,32(sp)
    80002974:	64e2                	ld	s1,24(sp)
    80002976:	6942                	ld	s2,16(sp)
    80002978:	69a2                	ld	s3,8(sp)
    8000297a:	6145                	addi	sp,sp,48
    8000297c:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    8000297e:	00006517          	auipc	a0,0x6
    80002982:	9fa50513          	addi	a0,a0,-1542 # 80008378 <states.0+0xf0>
    80002986:	ffffe097          	auipc	ra,0xffffe
    8000298a:	ba4080e7          	jalr	-1116(ra) # 8000052a <panic>
    panic("kerneltrap: interrupts enabled");
    8000298e:	00006517          	auipc	a0,0x6
    80002992:	a1250513          	addi	a0,a0,-1518 # 800083a0 <states.0+0x118>
    80002996:	ffffe097          	auipc	ra,0xffffe
    8000299a:	b94080e7          	jalr	-1132(ra) # 8000052a <panic>
    printf("scause %p\n", scause);
    8000299e:	85ce                	mv	a1,s3
    800029a0:	00006517          	auipc	a0,0x6
    800029a4:	a2050513          	addi	a0,a0,-1504 # 800083c0 <states.0+0x138>
    800029a8:	ffffe097          	auipc	ra,0xffffe
    800029ac:	bcc080e7          	jalr	-1076(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029b0:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800029b4:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    800029b8:	00006517          	auipc	a0,0x6
    800029bc:	a1850513          	addi	a0,a0,-1512 # 800083d0 <states.0+0x148>
    800029c0:	ffffe097          	auipc	ra,0xffffe
    800029c4:	bb4080e7          	jalr	-1100(ra) # 80000574 <printf>
    panic("kerneltrap");
    800029c8:	00006517          	auipc	a0,0x6
    800029cc:	a2050513          	addi	a0,a0,-1504 # 800083e8 <states.0+0x160>
    800029d0:	ffffe097          	auipc	ra,0xffffe
    800029d4:	b5a080e7          	jalr	-1190(ra) # 8000052a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029d8:	fffff097          	auipc	ra,0xfffff
    800029dc:	ffa080e7          	jalr	-6(ra) # 800019d2 <myproc>
    800029e0:	d541                	beqz	a0,80002968 <kerneltrap+0x38>
    800029e2:	fffff097          	auipc	ra,0xfffff
    800029e6:	ff0080e7          	jalr	-16(ra) # 800019d2 <myproc>
    800029ea:	4d18                	lw	a4,24(a0)
    800029ec:	4791                	li	a5,4
    800029ee:	f6f71de3          	bne	a4,a5,80002968 <kerneltrap+0x38>
    yield();
    800029f2:	fffff097          	auipc	ra,0xfffff
    800029f6:	664080e7          	jalr	1636(ra) # 80002056 <yield>
    800029fa:	b7bd                	j	80002968 <kerneltrap+0x38>

00000000800029fc <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800029fc:	1101                	addi	sp,sp,-32
    800029fe:	ec06                	sd	ra,24(sp)
    80002a00:	e822                	sd	s0,16(sp)
    80002a02:	e426                	sd	s1,8(sp)
    80002a04:	1000                	addi	s0,sp,32
    80002a06:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a08:	fffff097          	auipc	ra,0xfffff
    80002a0c:	fca080e7          	jalr	-54(ra) # 800019d2 <myproc>
  switch (n) {
    80002a10:	4795                	li	a5,5
    80002a12:	0497e163          	bltu	a5,s1,80002a54 <argraw+0x58>
    80002a16:	048a                	slli	s1,s1,0x2
    80002a18:	00006717          	auipc	a4,0x6
    80002a1c:	a0870713          	addi	a4,a4,-1528 # 80008420 <states.0+0x198>
    80002a20:	94ba                	add	s1,s1,a4
    80002a22:	409c                	lw	a5,0(s1)
    80002a24:	97ba                	add	a5,a5,a4
    80002a26:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002a28:	6d3c                	ld	a5,88(a0)
    80002a2a:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002a2c:	60e2                	ld	ra,24(sp)
    80002a2e:	6442                	ld	s0,16(sp)
    80002a30:	64a2                	ld	s1,8(sp)
    80002a32:	6105                	addi	sp,sp,32
    80002a34:	8082                	ret
    return p->trapframe->a1;
    80002a36:	6d3c                	ld	a5,88(a0)
    80002a38:	7fa8                	ld	a0,120(a5)
    80002a3a:	bfcd                	j	80002a2c <argraw+0x30>
    return p->trapframe->a2;
    80002a3c:	6d3c                	ld	a5,88(a0)
    80002a3e:	63c8                	ld	a0,128(a5)
    80002a40:	b7f5                	j	80002a2c <argraw+0x30>
    return p->trapframe->a3;
    80002a42:	6d3c                	ld	a5,88(a0)
    80002a44:	67c8                	ld	a0,136(a5)
    80002a46:	b7dd                	j	80002a2c <argraw+0x30>
    return p->trapframe->a4;
    80002a48:	6d3c                	ld	a5,88(a0)
    80002a4a:	6bc8                	ld	a0,144(a5)
    80002a4c:	b7c5                	j	80002a2c <argraw+0x30>
    return p->trapframe->a5;
    80002a4e:	6d3c                	ld	a5,88(a0)
    80002a50:	6fc8                	ld	a0,152(a5)
    80002a52:	bfe9                	j	80002a2c <argraw+0x30>
  panic("argraw");
    80002a54:	00006517          	auipc	a0,0x6
    80002a58:	9a450513          	addi	a0,a0,-1628 # 800083f8 <states.0+0x170>
    80002a5c:	ffffe097          	auipc	ra,0xffffe
    80002a60:	ace080e7          	jalr	-1330(ra) # 8000052a <panic>

0000000080002a64 <fetchaddr>:
{
    80002a64:	1101                	addi	sp,sp,-32
    80002a66:	ec06                	sd	ra,24(sp)
    80002a68:	e822                	sd	s0,16(sp)
    80002a6a:	e426                	sd	s1,8(sp)
    80002a6c:	e04a                	sd	s2,0(sp)
    80002a6e:	1000                	addi	s0,sp,32
    80002a70:	84aa                	mv	s1,a0
    80002a72:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002a74:	fffff097          	auipc	ra,0xfffff
    80002a78:	f5e080e7          	jalr	-162(ra) # 800019d2 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002a7c:	653c                	ld	a5,72(a0)
    80002a7e:	02f4f863          	bgeu	s1,a5,80002aae <fetchaddr+0x4a>
    80002a82:	00848713          	addi	a4,s1,8
    80002a86:	02e7e663          	bltu	a5,a4,80002ab2 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002a8a:	46a1                	li	a3,8
    80002a8c:	8626                	mv	a2,s1
    80002a8e:	85ca                	mv	a1,s2
    80002a90:	6928                	ld	a0,80(a0)
    80002a92:	fffff097          	auipc	ra,0xfffff
    80002a96:	c8c080e7          	jalr	-884(ra) # 8000171e <copyin>
    80002a9a:	00a03533          	snez	a0,a0
    80002a9e:	40a00533          	neg	a0,a0
}
    80002aa2:	60e2                	ld	ra,24(sp)
    80002aa4:	6442                	ld	s0,16(sp)
    80002aa6:	64a2                	ld	s1,8(sp)
    80002aa8:	6902                	ld	s2,0(sp)
    80002aaa:	6105                	addi	sp,sp,32
    80002aac:	8082                	ret
    return -1;
    80002aae:	557d                	li	a0,-1
    80002ab0:	bfcd                	j	80002aa2 <fetchaddr+0x3e>
    80002ab2:	557d                	li	a0,-1
    80002ab4:	b7fd                	j	80002aa2 <fetchaddr+0x3e>

0000000080002ab6 <fetchstr>:
{
    80002ab6:	7179                	addi	sp,sp,-48
    80002ab8:	f406                	sd	ra,40(sp)
    80002aba:	f022                	sd	s0,32(sp)
    80002abc:	ec26                	sd	s1,24(sp)
    80002abe:	e84a                	sd	s2,16(sp)
    80002ac0:	e44e                	sd	s3,8(sp)
    80002ac2:	1800                	addi	s0,sp,48
    80002ac4:	892a                	mv	s2,a0
    80002ac6:	84ae                	mv	s1,a1
    80002ac8:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002aca:	fffff097          	auipc	ra,0xfffff
    80002ace:	f08080e7          	jalr	-248(ra) # 800019d2 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002ad2:	86ce                	mv	a3,s3
    80002ad4:	864a                	mv	a2,s2
    80002ad6:	85a6                	mv	a1,s1
    80002ad8:	6928                	ld	a0,80(a0)
    80002ada:	fffff097          	auipc	ra,0xfffff
    80002ade:	cd2080e7          	jalr	-814(ra) # 800017ac <copyinstr>
  if(err < 0)
    80002ae2:	00054763          	bltz	a0,80002af0 <fetchstr+0x3a>
  return strlen(buf);
    80002ae6:	8526                	mv	a0,s1
    80002ae8:	ffffe097          	auipc	ra,0xffffe
    80002aec:	35a080e7          	jalr	858(ra) # 80000e42 <strlen>
}
    80002af0:	70a2                	ld	ra,40(sp)
    80002af2:	7402                	ld	s0,32(sp)
    80002af4:	64e2                	ld	s1,24(sp)
    80002af6:	6942                	ld	s2,16(sp)
    80002af8:	69a2                	ld	s3,8(sp)
    80002afa:	6145                	addi	sp,sp,48
    80002afc:	8082                	ret

0000000080002afe <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002afe:	1101                	addi	sp,sp,-32
    80002b00:	ec06                	sd	ra,24(sp)
    80002b02:	e822                	sd	s0,16(sp)
    80002b04:	e426                	sd	s1,8(sp)
    80002b06:	1000                	addi	s0,sp,32
    80002b08:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b0a:	00000097          	auipc	ra,0x0
    80002b0e:	ef2080e7          	jalr	-270(ra) # 800029fc <argraw>
    80002b12:	c088                	sw	a0,0(s1)
  return 0;
}
    80002b14:	4501                	li	a0,0
    80002b16:	60e2                	ld	ra,24(sp)
    80002b18:	6442                	ld	s0,16(sp)
    80002b1a:	64a2                	ld	s1,8(sp)
    80002b1c:	6105                	addi	sp,sp,32
    80002b1e:	8082                	ret

0000000080002b20 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002b20:	1101                	addi	sp,sp,-32
    80002b22:	ec06                	sd	ra,24(sp)
    80002b24:	e822                	sd	s0,16(sp)
    80002b26:	e426                	sd	s1,8(sp)
    80002b28:	1000                	addi	s0,sp,32
    80002b2a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b2c:	00000097          	auipc	ra,0x0
    80002b30:	ed0080e7          	jalr	-304(ra) # 800029fc <argraw>
    80002b34:	e088                	sd	a0,0(s1)
  return 0;
}
    80002b36:	4501                	li	a0,0
    80002b38:	60e2                	ld	ra,24(sp)
    80002b3a:	6442                	ld	s0,16(sp)
    80002b3c:	64a2                	ld	s1,8(sp)
    80002b3e:	6105                	addi	sp,sp,32
    80002b40:	8082                	ret

0000000080002b42 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002b42:	1101                	addi	sp,sp,-32
    80002b44:	ec06                	sd	ra,24(sp)
    80002b46:	e822                	sd	s0,16(sp)
    80002b48:	e426                	sd	s1,8(sp)
    80002b4a:	e04a                	sd	s2,0(sp)
    80002b4c:	1000                	addi	s0,sp,32
    80002b4e:	84ae                	mv	s1,a1
    80002b50:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002b52:	00000097          	auipc	ra,0x0
    80002b56:	eaa080e7          	jalr	-342(ra) # 800029fc <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002b5a:	864a                	mv	a2,s2
    80002b5c:	85a6                	mv	a1,s1
    80002b5e:	00000097          	auipc	ra,0x0
    80002b62:	f58080e7          	jalr	-168(ra) # 80002ab6 <fetchstr>
}
    80002b66:	60e2                	ld	ra,24(sp)
    80002b68:	6442                	ld	s0,16(sp)
    80002b6a:	64a2                	ld	s1,8(sp)
    80002b6c:	6902                	ld	s2,0(sp)
    80002b6e:	6105                	addi	sp,sp,32
    80002b70:	8082                	ret

0000000080002b72 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002b72:	1101                	addi	sp,sp,-32
    80002b74:	ec06                	sd	ra,24(sp)
    80002b76:	e822                	sd	s0,16(sp)
    80002b78:	e426                	sd	s1,8(sp)
    80002b7a:	e04a                	sd	s2,0(sp)
    80002b7c:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002b7e:	fffff097          	auipc	ra,0xfffff
    80002b82:	e54080e7          	jalr	-428(ra) # 800019d2 <myproc>
    80002b86:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002b88:	05853903          	ld	s2,88(a0)
    80002b8c:	0a893783          	ld	a5,168(s2)
    80002b90:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002b94:	37fd                	addiw	a5,a5,-1
    80002b96:	4751                	li	a4,20
    80002b98:	00f76f63          	bltu	a4,a5,80002bb6 <syscall+0x44>
    80002b9c:	00369713          	slli	a4,a3,0x3
    80002ba0:	00006797          	auipc	a5,0x6
    80002ba4:	89878793          	addi	a5,a5,-1896 # 80008438 <syscalls>
    80002ba8:	97ba                	add	a5,a5,a4
    80002baa:	639c                	ld	a5,0(a5)
    80002bac:	c789                	beqz	a5,80002bb6 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002bae:	9782                	jalr	a5
    80002bb0:	06a93823          	sd	a0,112(s2)
    80002bb4:	a839                	j	80002bd2 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002bb6:	15848613          	addi	a2,s1,344
    80002bba:	588c                	lw	a1,48(s1)
    80002bbc:	00006517          	auipc	a0,0x6
    80002bc0:	84450513          	addi	a0,a0,-1980 # 80008400 <states.0+0x178>
    80002bc4:	ffffe097          	auipc	ra,0xffffe
    80002bc8:	9b0080e7          	jalr	-1616(ra) # 80000574 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002bcc:	6cbc                	ld	a5,88(s1)
    80002bce:	577d                	li	a4,-1
    80002bd0:	fbb8                	sd	a4,112(a5)
  }
}
    80002bd2:	60e2                	ld	ra,24(sp)
    80002bd4:	6442                	ld	s0,16(sp)
    80002bd6:	64a2                	ld	s1,8(sp)
    80002bd8:	6902                	ld	s2,0(sp)
    80002bda:	6105                	addi	sp,sp,32
    80002bdc:	8082                	ret

0000000080002bde <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002bde:	1101                	addi	sp,sp,-32
    80002be0:	ec06                	sd	ra,24(sp)
    80002be2:	e822                	sd	s0,16(sp)
    80002be4:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002be6:	fec40593          	addi	a1,s0,-20
    80002bea:	4501                	li	a0,0
    80002bec:	00000097          	auipc	ra,0x0
    80002bf0:	f12080e7          	jalr	-238(ra) # 80002afe <argint>
    return -1;
    80002bf4:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002bf6:	00054963          	bltz	a0,80002c08 <sys_exit+0x2a>
  exit(n);
    80002bfa:	fec42503          	lw	a0,-20(s0)
    80002bfe:	fffff097          	auipc	ra,0xfffff
    80002c02:	6f0080e7          	jalr	1776(ra) # 800022ee <exit>
  return 0;  // not reached
    80002c06:	4781                	li	a5,0
}
    80002c08:	853e                	mv	a0,a5
    80002c0a:	60e2                	ld	ra,24(sp)
    80002c0c:	6442                	ld	s0,16(sp)
    80002c0e:	6105                	addi	sp,sp,32
    80002c10:	8082                	ret

0000000080002c12 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002c12:	1141                	addi	sp,sp,-16
    80002c14:	e406                	sd	ra,8(sp)
    80002c16:	e022                	sd	s0,0(sp)
    80002c18:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002c1a:	fffff097          	auipc	ra,0xfffff
    80002c1e:	db8080e7          	jalr	-584(ra) # 800019d2 <myproc>
}
    80002c22:	5908                	lw	a0,48(a0)
    80002c24:	60a2                	ld	ra,8(sp)
    80002c26:	6402                	ld	s0,0(sp)
    80002c28:	0141                	addi	sp,sp,16
    80002c2a:	8082                	ret

0000000080002c2c <sys_fork>:

uint64
sys_fork(void)
{
    80002c2c:	1141                	addi	sp,sp,-16
    80002c2e:	e406                	sd	ra,8(sp)
    80002c30:	e022                	sd	s0,0(sp)
    80002c32:	0800                	addi	s0,sp,16
  return fork();
    80002c34:	fffff097          	auipc	ra,0xfffff
    80002c38:	16c080e7          	jalr	364(ra) # 80001da0 <fork>
}
    80002c3c:	60a2                	ld	ra,8(sp)
    80002c3e:	6402                	ld	s0,0(sp)
    80002c40:	0141                	addi	sp,sp,16
    80002c42:	8082                	ret

0000000080002c44 <sys_wait>:

uint64
sys_wait(void)
{
    80002c44:	1101                	addi	sp,sp,-32
    80002c46:	ec06                	sd	ra,24(sp)
    80002c48:	e822                	sd	s0,16(sp)
    80002c4a:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002c4c:	fe840593          	addi	a1,s0,-24
    80002c50:	4501                	li	a0,0
    80002c52:	00000097          	auipc	ra,0x0
    80002c56:	ece080e7          	jalr	-306(ra) # 80002b20 <argaddr>
    80002c5a:	87aa                	mv	a5,a0
    return -1;
    80002c5c:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002c5e:	0007c863          	bltz	a5,80002c6e <sys_wait+0x2a>
  return wait(p);
    80002c62:	fe843503          	ld	a0,-24(s0)
    80002c66:	fffff097          	auipc	ra,0xfffff
    80002c6a:	490080e7          	jalr	1168(ra) # 800020f6 <wait>
}
    80002c6e:	60e2                	ld	ra,24(sp)
    80002c70:	6442                	ld	s0,16(sp)
    80002c72:	6105                	addi	sp,sp,32
    80002c74:	8082                	ret

0000000080002c76 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002c76:	7179                	addi	sp,sp,-48
    80002c78:	f406                	sd	ra,40(sp)
    80002c7a:	f022                	sd	s0,32(sp)
    80002c7c:	ec26                	sd	s1,24(sp)
    80002c7e:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002c80:	fdc40593          	addi	a1,s0,-36
    80002c84:	4501                	li	a0,0
    80002c86:	00000097          	auipc	ra,0x0
    80002c8a:	e78080e7          	jalr	-392(ra) # 80002afe <argint>
    return -1;
    80002c8e:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    80002c90:	02054363          	bltz	a0,80002cb6 <sys_sbrk+0x40>
  addr = myproc()->sz;
    80002c94:	fffff097          	auipc	ra,0xfffff
    80002c98:	d3e080e7          	jalr	-706(ra) # 800019d2 <myproc>
    80002c9c:	4524                	lw	s1,72(a0)
  myproc()->sz += n;
    80002c9e:	fffff097          	auipc	ra,0xfffff
    80002ca2:	d34080e7          	jalr	-716(ra) # 800019d2 <myproc>
    80002ca6:	87aa                	mv	a5,a0
    80002ca8:	fdc42503          	lw	a0,-36(s0)
    80002cac:	67b8                	ld	a4,72(a5)
    80002cae:	972a                	add	a4,a4,a0
    80002cb0:	e7b8                	sd	a4,72(a5)
  //if(growproc(n) < 0)
  //  return -1;
  if(n < 0)
    80002cb2:	00054863          	bltz	a0,80002cc2 <sys_sbrk+0x4c>
    growproc(n);
  return addr;
}
    80002cb6:	8526                	mv	a0,s1
    80002cb8:	70a2                	ld	ra,40(sp)
    80002cba:	7402                	ld	s0,32(sp)
    80002cbc:	64e2                	ld	s1,24(sp)
    80002cbe:	6145                	addi	sp,sp,48
    80002cc0:	8082                	ret
    growproc(n);
    80002cc2:	fffff097          	auipc	ra,0xfffff
    80002cc6:	06a080e7          	jalr	106(ra) # 80001d2c <growproc>
  return addr;
    80002cca:	b7f5                	j	80002cb6 <sys_sbrk+0x40>

0000000080002ccc <sys_sleep>:

uint64
sys_sleep(void)
{
    80002ccc:	7139                	addi	sp,sp,-64
    80002cce:	fc06                	sd	ra,56(sp)
    80002cd0:	f822                	sd	s0,48(sp)
    80002cd2:	f426                	sd	s1,40(sp)
    80002cd4:	f04a                	sd	s2,32(sp)
    80002cd6:	ec4e                	sd	s3,24(sp)
    80002cd8:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002cda:	fcc40593          	addi	a1,s0,-52
    80002cde:	4501                	li	a0,0
    80002ce0:	00000097          	auipc	ra,0x0
    80002ce4:	e1e080e7          	jalr	-482(ra) # 80002afe <argint>
    return -1;
    80002ce8:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002cea:	06054563          	bltz	a0,80002d54 <sys_sleep+0x88>
  acquire(&tickslock);
    80002cee:	00014517          	auipc	a0,0x14
    80002cf2:	3e250513          	addi	a0,a0,994 # 800170d0 <tickslock>
    80002cf6:	ffffe097          	auipc	ra,0xffffe
    80002cfa:	ecc080e7          	jalr	-308(ra) # 80000bc2 <acquire>
  ticks0 = ticks;
    80002cfe:	00006917          	auipc	s2,0x6
    80002d02:	33292903          	lw	s2,818(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80002d06:	fcc42783          	lw	a5,-52(s0)
    80002d0a:	cf85                	beqz	a5,80002d42 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002d0c:	00014997          	auipc	s3,0x14
    80002d10:	3c498993          	addi	s3,s3,964 # 800170d0 <tickslock>
    80002d14:	00006497          	auipc	s1,0x6
    80002d18:	31c48493          	addi	s1,s1,796 # 80009030 <ticks>
    if(myproc()->killed){
    80002d1c:	fffff097          	auipc	ra,0xfffff
    80002d20:	cb6080e7          	jalr	-842(ra) # 800019d2 <myproc>
    80002d24:	551c                	lw	a5,40(a0)
    80002d26:	ef9d                	bnez	a5,80002d64 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002d28:	85ce                	mv	a1,s3
    80002d2a:	8526                	mv	a0,s1
    80002d2c:	fffff097          	auipc	ra,0xfffff
    80002d30:	366080e7          	jalr	870(ra) # 80002092 <sleep>
  while(ticks - ticks0 < n){
    80002d34:	409c                	lw	a5,0(s1)
    80002d36:	412787bb          	subw	a5,a5,s2
    80002d3a:	fcc42703          	lw	a4,-52(s0)
    80002d3e:	fce7efe3          	bltu	a5,a4,80002d1c <sys_sleep+0x50>
  }
  release(&tickslock);
    80002d42:	00014517          	auipc	a0,0x14
    80002d46:	38e50513          	addi	a0,a0,910 # 800170d0 <tickslock>
    80002d4a:	ffffe097          	auipc	ra,0xffffe
    80002d4e:	f2c080e7          	jalr	-212(ra) # 80000c76 <release>
  return 0;
    80002d52:	4781                	li	a5,0
}
    80002d54:	853e                	mv	a0,a5
    80002d56:	70e2                	ld	ra,56(sp)
    80002d58:	7442                	ld	s0,48(sp)
    80002d5a:	74a2                	ld	s1,40(sp)
    80002d5c:	7902                	ld	s2,32(sp)
    80002d5e:	69e2                	ld	s3,24(sp)
    80002d60:	6121                	addi	sp,sp,64
    80002d62:	8082                	ret
      release(&tickslock);
    80002d64:	00014517          	auipc	a0,0x14
    80002d68:	36c50513          	addi	a0,a0,876 # 800170d0 <tickslock>
    80002d6c:	ffffe097          	auipc	ra,0xffffe
    80002d70:	f0a080e7          	jalr	-246(ra) # 80000c76 <release>
      return -1;
    80002d74:	57fd                	li	a5,-1
    80002d76:	bff9                	j	80002d54 <sys_sleep+0x88>

0000000080002d78 <sys_kill>:

uint64
sys_kill(void)
{
    80002d78:	1101                	addi	sp,sp,-32
    80002d7a:	ec06                	sd	ra,24(sp)
    80002d7c:	e822                	sd	s0,16(sp)
    80002d7e:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002d80:	fec40593          	addi	a1,s0,-20
    80002d84:	4501                	li	a0,0
    80002d86:	00000097          	auipc	ra,0x0
    80002d8a:	d78080e7          	jalr	-648(ra) # 80002afe <argint>
    80002d8e:	87aa                	mv	a5,a0
    return -1;
    80002d90:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002d92:	0007c863          	bltz	a5,80002da2 <sys_kill+0x2a>
  return kill(pid);
    80002d96:	fec42503          	lw	a0,-20(s0)
    80002d9a:	fffff097          	auipc	ra,0xfffff
    80002d9e:	62a080e7          	jalr	1578(ra) # 800023c4 <kill>
}
    80002da2:	60e2                	ld	ra,24(sp)
    80002da4:	6442                	ld	s0,16(sp)
    80002da6:	6105                	addi	sp,sp,32
    80002da8:	8082                	ret

0000000080002daa <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002daa:	1101                	addi	sp,sp,-32
    80002dac:	ec06                	sd	ra,24(sp)
    80002dae:	e822                	sd	s0,16(sp)
    80002db0:	e426                	sd	s1,8(sp)
    80002db2:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002db4:	00014517          	auipc	a0,0x14
    80002db8:	31c50513          	addi	a0,a0,796 # 800170d0 <tickslock>
    80002dbc:	ffffe097          	auipc	ra,0xffffe
    80002dc0:	e06080e7          	jalr	-506(ra) # 80000bc2 <acquire>
  xticks = ticks;
    80002dc4:	00006497          	auipc	s1,0x6
    80002dc8:	26c4a483          	lw	s1,620(s1) # 80009030 <ticks>
  release(&tickslock);
    80002dcc:	00014517          	auipc	a0,0x14
    80002dd0:	30450513          	addi	a0,a0,772 # 800170d0 <tickslock>
    80002dd4:	ffffe097          	auipc	ra,0xffffe
    80002dd8:	ea2080e7          	jalr	-350(ra) # 80000c76 <release>
  return xticks;
}
    80002ddc:	02049513          	slli	a0,s1,0x20
    80002de0:	9101                	srli	a0,a0,0x20
    80002de2:	60e2                	ld	ra,24(sp)
    80002de4:	6442                	ld	s0,16(sp)
    80002de6:	64a2                	ld	s1,8(sp)
    80002de8:	6105                	addi	sp,sp,32
    80002dea:	8082                	ret

0000000080002dec <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002dec:	7179                	addi	sp,sp,-48
    80002dee:	f406                	sd	ra,40(sp)
    80002df0:	f022                	sd	s0,32(sp)
    80002df2:	ec26                	sd	s1,24(sp)
    80002df4:	e84a                	sd	s2,16(sp)
    80002df6:	e44e                	sd	s3,8(sp)
    80002df8:	e052                	sd	s4,0(sp)
    80002dfa:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002dfc:	00005597          	auipc	a1,0x5
    80002e00:	6ec58593          	addi	a1,a1,1772 # 800084e8 <syscalls+0xb0>
    80002e04:	00014517          	auipc	a0,0x14
    80002e08:	2e450513          	addi	a0,a0,740 # 800170e8 <bcache>
    80002e0c:	ffffe097          	auipc	ra,0xffffe
    80002e10:	d26080e7          	jalr	-730(ra) # 80000b32 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002e14:	0001c797          	auipc	a5,0x1c
    80002e18:	2d478793          	addi	a5,a5,724 # 8001f0e8 <bcache+0x8000>
    80002e1c:	0001c717          	auipc	a4,0x1c
    80002e20:	53470713          	addi	a4,a4,1332 # 8001f350 <bcache+0x8268>
    80002e24:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002e28:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002e2c:	00014497          	auipc	s1,0x14
    80002e30:	2d448493          	addi	s1,s1,724 # 80017100 <bcache+0x18>
    b->next = bcache.head.next;
    80002e34:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002e36:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002e38:	00005a17          	auipc	s4,0x5
    80002e3c:	6b8a0a13          	addi	s4,s4,1720 # 800084f0 <syscalls+0xb8>
    b->next = bcache.head.next;
    80002e40:	2b893783          	ld	a5,696(s2)
    80002e44:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002e46:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002e4a:	85d2                	mv	a1,s4
    80002e4c:	01048513          	addi	a0,s1,16
    80002e50:	00001097          	auipc	ra,0x1
    80002e54:	4c2080e7          	jalr	1218(ra) # 80004312 <initsleeplock>
    bcache.head.next->prev = b;
    80002e58:	2b893783          	ld	a5,696(s2)
    80002e5c:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002e5e:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002e62:	45848493          	addi	s1,s1,1112
    80002e66:	fd349de3          	bne	s1,s3,80002e40 <binit+0x54>
  }
}
    80002e6a:	70a2                	ld	ra,40(sp)
    80002e6c:	7402                	ld	s0,32(sp)
    80002e6e:	64e2                	ld	s1,24(sp)
    80002e70:	6942                	ld	s2,16(sp)
    80002e72:	69a2                	ld	s3,8(sp)
    80002e74:	6a02                	ld	s4,0(sp)
    80002e76:	6145                	addi	sp,sp,48
    80002e78:	8082                	ret

0000000080002e7a <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002e7a:	7179                	addi	sp,sp,-48
    80002e7c:	f406                	sd	ra,40(sp)
    80002e7e:	f022                	sd	s0,32(sp)
    80002e80:	ec26                	sd	s1,24(sp)
    80002e82:	e84a                	sd	s2,16(sp)
    80002e84:	e44e                	sd	s3,8(sp)
    80002e86:	1800                	addi	s0,sp,48
    80002e88:	892a                	mv	s2,a0
    80002e8a:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002e8c:	00014517          	auipc	a0,0x14
    80002e90:	25c50513          	addi	a0,a0,604 # 800170e8 <bcache>
    80002e94:	ffffe097          	auipc	ra,0xffffe
    80002e98:	d2e080e7          	jalr	-722(ra) # 80000bc2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002e9c:	0001c497          	auipc	s1,0x1c
    80002ea0:	5044b483          	ld	s1,1284(s1) # 8001f3a0 <bcache+0x82b8>
    80002ea4:	0001c797          	auipc	a5,0x1c
    80002ea8:	4ac78793          	addi	a5,a5,1196 # 8001f350 <bcache+0x8268>
    80002eac:	02f48f63          	beq	s1,a5,80002eea <bread+0x70>
    80002eb0:	873e                	mv	a4,a5
    80002eb2:	a021                	j	80002eba <bread+0x40>
    80002eb4:	68a4                	ld	s1,80(s1)
    80002eb6:	02e48a63          	beq	s1,a4,80002eea <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002eba:	449c                	lw	a5,8(s1)
    80002ebc:	ff279ce3          	bne	a5,s2,80002eb4 <bread+0x3a>
    80002ec0:	44dc                	lw	a5,12(s1)
    80002ec2:	ff3799e3          	bne	a5,s3,80002eb4 <bread+0x3a>
      b->refcnt++;
    80002ec6:	40bc                	lw	a5,64(s1)
    80002ec8:	2785                	addiw	a5,a5,1
    80002eca:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002ecc:	00014517          	auipc	a0,0x14
    80002ed0:	21c50513          	addi	a0,a0,540 # 800170e8 <bcache>
    80002ed4:	ffffe097          	auipc	ra,0xffffe
    80002ed8:	da2080e7          	jalr	-606(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    80002edc:	01048513          	addi	a0,s1,16
    80002ee0:	00001097          	auipc	ra,0x1
    80002ee4:	46c080e7          	jalr	1132(ra) # 8000434c <acquiresleep>
      return b;
    80002ee8:	a8b9                	j	80002f46 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002eea:	0001c497          	auipc	s1,0x1c
    80002eee:	4ae4b483          	ld	s1,1198(s1) # 8001f398 <bcache+0x82b0>
    80002ef2:	0001c797          	auipc	a5,0x1c
    80002ef6:	45e78793          	addi	a5,a5,1118 # 8001f350 <bcache+0x8268>
    80002efa:	00f48863          	beq	s1,a5,80002f0a <bread+0x90>
    80002efe:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002f00:	40bc                	lw	a5,64(s1)
    80002f02:	cf81                	beqz	a5,80002f1a <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f04:	64a4                	ld	s1,72(s1)
    80002f06:	fee49de3          	bne	s1,a4,80002f00 <bread+0x86>
  panic("bget: no buffers");
    80002f0a:	00005517          	auipc	a0,0x5
    80002f0e:	5ee50513          	addi	a0,a0,1518 # 800084f8 <syscalls+0xc0>
    80002f12:	ffffd097          	auipc	ra,0xffffd
    80002f16:	618080e7          	jalr	1560(ra) # 8000052a <panic>
      b->dev = dev;
    80002f1a:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002f1e:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002f22:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002f26:	4785                	li	a5,1
    80002f28:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f2a:	00014517          	auipc	a0,0x14
    80002f2e:	1be50513          	addi	a0,a0,446 # 800170e8 <bcache>
    80002f32:	ffffe097          	auipc	ra,0xffffe
    80002f36:	d44080e7          	jalr	-700(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    80002f3a:	01048513          	addi	a0,s1,16
    80002f3e:	00001097          	auipc	ra,0x1
    80002f42:	40e080e7          	jalr	1038(ra) # 8000434c <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002f46:	409c                	lw	a5,0(s1)
    80002f48:	cb89                	beqz	a5,80002f5a <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002f4a:	8526                	mv	a0,s1
    80002f4c:	70a2                	ld	ra,40(sp)
    80002f4e:	7402                	ld	s0,32(sp)
    80002f50:	64e2                	ld	s1,24(sp)
    80002f52:	6942                	ld	s2,16(sp)
    80002f54:	69a2                	ld	s3,8(sp)
    80002f56:	6145                	addi	sp,sp,48
    80002f58:	8082                	ret
    virtio_disk_rw(b, 0);
    80002f5a:	4581                	li	a1,0
    80002f5c:	8526                	mv	a0,s1
    80002f5e:	00003097          	auipc	ra,0x3
    80002f62:	f28080e7          	jalr	-216(ra) # 80005e86 <virtio_disk_rw>
    b->valid = 1;
    80002f66:	4785                	li	a5,1
    80002f68:	c09c                	sw	a5,0(s1)
  return b;
    80002f6a:	b7c5                	j	80002f4a <bread+0xd0>

0000000080002f6c <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002f6c:	1101                	addi	sp,sp,-32
    80002f6e:	ec06                	sd	ra,24(sp)
    80002f70:	e822                	sd	s0,16(sp)
    80002f72:	e426                	sd	s1,8(sp)
    80002f74:	1000                	addi	s0,sp,32
    80002f76:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f78:	0541                	addi	a0,a0,16
    80002f7a:	00001097          	auipc	ra,0x1
    80002f7e:	46c080e7          	jalr	1132(ra) # 800043e6 <holdingsleep>
    80002f82:	cd01                	beqz	a0,80002f9a <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002f84:	4585                	li	a1,1
    80002f86:	8526                	mv	a0,s1
    80002f88:	00003097          	auipc	ra,0x3
    80002f8c:	efe080e7          	jalr	-258(ra) # 80005e86 <virtio_disk_rw>
}
    80002f90:	60e2                	ld	ra,24(sp)
    80002f92:	6442                	ld	s0,16(sp)
    80002f94:	64a2                	ld	s1,8(sp)
    80002f96:	6105                	addi	sp,sp,32
    80002f98:	8082                	ret
    panic("bwrite");
    80002f9a:	00005517          	auipc	a0,0x5
    80002f9e:	57650513          	addi	a0,a0,1398 # 80008510 <syscalls+0xd8>
    80002fa2:	ffffd097          	auipc	ra,0xffffd
    80002fa6:	588080e7          	jalr	1416(ra) # 8000052a <panic>

0000000080002faa <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80002faa:	1101                	addi	sp,sp,-32
    80002fac:	ec06                	sd	ra,24(sp)
    80002fae:	e822                	sd	s0,16(sp)
    80002fb0:	e426                	sd	s1,8(sp)
    80002fb2:	e04a                	sd	s2,0(sp)
    80002fb4:	1000                	addi	s0,sp,32
    80002fb6:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002fb8:	01050913          	addi	s2,a0,16
    80002fbc:	854a                	mv	a0,s2
    80002fbe:	00001097          	auipc	ra,0x1
    80002fc2:	428080e7          	jalr	1064(ra) # 800043e6 <holdingsleep>
    80002fc6:	c92d                	beqz	a0,80003038 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80002fc8:	854a                	mv	a0,s2
    80002fca:	00001097          	auipc	ra,0x1
    80002fce:	3d8080e7          	jalr	984(ra) # 800043a2 <releasesleep>

  acquire(&bcache.lock);
    80002fd2:	00014517          	auipc	a0,0x14
    80002fd6:	11650513          	addi	a0,a0,278 # 800170e8 <bcache>
    80002fda:	ffffe097          	auipc	ra,0xffffe
    80002fde:	be8080e7          	jalr	-1048(ra) # 80000bc2 <acquire>
  b->refcnt--;
    80002fe2:	40bc                	lw	a5,64(s1)
    80002fe4:	37fd                	addiw	a5,a5,-1
    80002fe6:	0007871b          	sext.w	a4,a5
    80002fea:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80002fec:	eb05                	bnez	a4,8000301c <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80002fee:	68bc                	ld	a5,80(s1)
    80002ff0:	64b8                	ld	a4,72(s1)
    80002ff2:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80002ff4:	64bc                	ld	a5,72(s1)
    80002ff6:	68b8                	ld	a4,80(s1)
    80002ff8:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80002ffa:	0001c797          	auipc	a5,0x1c
    80002ffe:	0ee78793          	addi	a5,a5,238 # 8001f0e8 <bcache+0x8000>
    80003002:	2b87b703          	ld	a4,696(a5)
    80003006:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003008:	0001c717          	auipc	a4,0x1c
    8000300c:	34870713          	addi	a4,a4,840 # 8001f350 <bcache+0x8268>
    80003010:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003012:	2b87b703          	ld	a4,696(a5)
    80003016:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003018:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000301c:	00014517          	auipc	a0,0x14
    80003020:	0cc50513          	addi	a0,a0,204 # 800170e8 <bcache>
    80003024:	ffffe097          	auipc	ra,0xffffe
    80003028:	c52080e7          	jalr	-942(ra) # 80000c76 <release>
}
    8000302c:	60e2                	ld	ra,24(sp)
    8000302e:	6442                	ld	s0,16(sp)
    80003030:	64a2                	ld	s1,8(sp)
    80003032:	6902                	ld	s2,0(sp)
    80003034:	6105                	addi	sp,sp,32
    80003036:	8082                	ret
    panic("brelse");
    80003038:	00005517          	auipc	a0,0x5
    8000303c:	4e050513          	addi	a0,a0,1248 # 80008518 <syscalls+0xe0>
    80003040:	ffffd097          	auipc	ra,0xffffd
    80003044:	4ea080e7          	jalr	1258(ra) # 8000052a <panic>

0000000080003048 <bpin>:

void
bpin(struct buf *b) {
    80003048:	1101                	addi	sp,sp,-32
    8000304a:	ec06                	sd	ra,24(sp)
    8000304c:	e822                	sd	s0,16(sp)
    8000304e:	e426                	sd	s1,8(sp)
    80003050:	1000                	addi	s0,sp,32
    80003052:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003054:	00014517          	auipc	a0,0x14
    80003058:	09450513          	addi	a0,a0,148 # 800170e8 <bcache>
    8000305c:	ffffe097          	auipc	ra,0xffffe
    80003060:	b66080e7          	jalr	-1178(ra) # 80000bc2 <acquire>
  b->refcnt++;
    80003064:	40bc                	lw	a5,64(s1)
    80003066:	2785                	addiw	a5,a5,1
    80003068:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000306a:	00014517          	auipc	a0,0x14
    8000306e:	07e50513          	addi	a0,a0,126 # 800170e8 <bcache>
    80003072:	ffffe097          	auipc	ra,0xffffe
    80003076:	c04080e7          	jalr	-1020(ra) # 80000c76 <release>
}
    8000307a:	60e2                	ld	ra,24(sp)
    8000307c:	6442                	ld	s0,16(sp)
    8000307e:	64a2                	ld	s1,8(sp)
    80003080:	6105                	addi	sp,sp,32
    80003082:	8082                	ret

0000000080003084 <bunpin>:

void
bunpin(struct buf *b) {
    80003084:	1101                	addi	sp,sp,-32
    80003086:	ec06                	sd	ra,24(sp)
    80003088:	e822                	sd	s0,16(sp)
    8000308a:	e426                	sd	s1,8(sp)
    8000308c:	1000                	addi	s0,sp,32
    8000308e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003090:	00014517          	auipc	a0,0x14
    80003094:	05850513          	addi	a0,a0,88 # 800170e8 <bcache>
    80003098:	ffffe097          	auipc	ra,0xffffe
    8000309c:	b2a080e7          	jalr	-1238(ra) # 80000bc2 <acquire>
  b->refcnt--;
    800030a0:	40bc                	lw	a5,64(s1)
    800030a2:	37fd                	addiw	a5,a5,-1
    800030a4:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800030a6:	00014517          	auipc	a0,0x14
    800030aa:	04250513          	addi	a0,a0,66 # 800170e8 <bcache>
    800030ae:	ffffe097          	auipc	ra,0xffffe
    800030b2:	bc8080e7          	jalr	-1080(ra) # 80000c76 <release>
}
    800030b6:	60e2                	ld	ra,24(sp)
    800030b8:	6442                	ld	s0,16(sp)
    800030ba:	64a2                	ld	s1,8(sp)
    800030bc:	6105                	addi	sp,sp,32
    800030be:	8082                	ret

00000000800030c0 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800030c0:	1101                	addi	sp,sp,-32
    800030c2:	ec06                	sd	ra,24(sp)
    800030c4:	e822                	sd	s0,16(sp)
    800030c6:	e426                	sd	s1,8(sp)
    800030c8:	e04a                	sd	s2,0(sp)
    800030ca:	1000                	addi	s0,sp,32
    800030cc:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800030ce:	00d5d59b          	srliw	a1,a1,0xd
    800030d2:	0001c797          	auipc	a5,0x1c
    800030d6:	6f27a783          	lw	a5,1778(a5) # 8001f7c4 <sb+0x1c>
    800030da:	9dbd                	addw	a1,a1,a5
    800030dc:	00000097          	auipc	ra,0x0
    800030e0:	d9e080e7          	jalr	-610(ra) # 80002e7a <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800030e4:	0074f713          	andi	a4,s1,7
    800030e8:	4785                	li	a5,1
    800030ea:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800030ee:	14ce                	slli	s1,s1,0x33
    800030f0:	90d9                	srli	s1,s1,0x36
    800030f2:	00950733          	add	a4,a0,s1
    800030f6:	05874703          	lbu	a4,88(a4)
    800030fa:	00e7f6b3          	and	a3,a5,a4
    800030fe:	c69d                	beqz	a3,8000312c <bfree+0x6c>
    80003100:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003102:	94aa                	add	s1,s1,a0
    80003104:	fff7c793          	not	a5,a5
    80003108:	8ff9                	and	a5,a5,a4
    8000310a:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000310e:	00001097          	auipc	ra,0x1
    80003112:	11e080e7          	jalr	286(ra) # 8000422c <log_write>
  brelse(bp);
    80003116:	854a                	mv	a0,s2
    80003118:	00000097          	auipc	ra,0x0
    8000311c:	e92080e7          	jalr	-366(ra) # 80002faa <brelse>
}
    80003120:	60e2                	ld	ra,24(sp)
    80003122:	6442                	ld	s0,16(sp)
    80003124:	64a2                	ld	s1,8(sp)
    80003126:	6902                	ld	s2,0(sp)
    80003128:	6105                	addi	sp,sp,32
    8000312a:	8082                	ret
    panic("freeing free block");
    8000312c:	00005517          	auipc	a0,0x5
    80003130:	3f450513          	addi	a0,a0,1012 # 80008520 <syscalls+0xe8>
    80003134:	ffffd097          	auipc	ra,0xffffd
    80003138:	3f6080e7          	jalr	1014(ra) # 8000052a <panic>

000000008000313c <balloc>:
{
    8000313c:	711d                	addi	sp,sp,-96
    8000313e:	ec86                	sd	ra,88(sp)
    80003140:	e8a2                	sd	s0,80(sp)
    80003142:	e4a6                	sd	s1,72(sp)
    80003144:	e0ca                	sd	s2,64(sp)
    80003146:	fc4e                	sd	s3,56(sp)
    80003148:	f852                	sd	s4,48(sp)
    8000314a:	f456                	sd	s5,40(sp)
    8000314c:	f05a                	sd	s6,32(sp)
    8000314e:	ec5e                	sd	s7,24(sp)
    80003150:	e862                	sd	s8,16(sp)
    80003152:	e466                	sd	s9,8(sp)
    80003154:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003156:	0001c797          	auipc	a5,0x1c
    8000315a:	6567a783          	lw	a5,1622(a5) # 8001f7ac <sb+0x4>
    8000315e:	cbd1                	beqz	a5,800031f2 <balloc+0xb6>
    80003160:	8baa                	mv	s7,a0
    80003162:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003164:	0001cb17          	auipc	s6,0x1c
    80003168:	644b0b13          	addi	s6,s6,1604 # 8001f7a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000316c:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000316e:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003170:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003172:	6c89                	lui	s9,0x2
    80003174:	a831                	j	80003190 <balloc+0x54>
    brelse(bp);
    80003176:	854a                	mv	a0,s2
    80003178:	00000097          	auipc	ra,0x0
    8000317c:	e32080e7          	jalr	-462(ra) # 80002faa <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003180:	015c87bb          	addw	a5,s9,s5
    80003184:	00078a9b          	sext.w	s5,a5
    80003188:	004b2703          	lw	a4,4(s6)
    8000318c:	06eaf363          	bgeu	s5,a4,800031f2 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003190:	41fad79b          	sraiw	a5,s5,0x1f
    80003194:	0137d79b          	srliw	a5,a5,0x13
    80003198:	015787bb          	addw	a5,a5,s5
    8000319c:	40d7d79b          	sraiw	a5,a5,0xd
    800031a0:	01cb2583          	lw	a1,28(s6)
    800031a4:	9dbd                	addw	a1,a1,a5
    800031a6:	855e                	mv	a0,s7
    800031a8:	00000097          	auipc	ra,0x0
    800031ac:	cd2080e7          	jalr	-814(ra) # 80002e7a <bread>
    800031b0:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031b2:	004b2503          	lw	a0,4(s6)
    800031b6:	000a849b          	sext.w	s1,s5
    800031ba:	8662                	mv	a2,s8
    800031bc:	faa4fde3          	bgeu	s1,a0,80003176 <balloc+0x3a>
      m = 1 << (bi % 8);
    800031c0:	41f6579b          	sraiw	a5,a2,0x1f
    800031c4:	01d7d69b          	srliw	a3,a5,0x1d
    800031c8:	00c6873b          	addw	a4,a3,a2
    800031cc:	00777793          	andi	a5,a4,7
    800031d0:	9f95                	subw	a5,a5,a3
    800031d2:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800031d6:	4037571b          	sraiw	a4,a4,0x3
    800031da:	00e906b3          	add	a3,s2,a4
    800031de:	0586c683          	lbu	a3,88(a3)
    800031e2:	00d7f5b3          	and	a1,a5,a3
    800031e6:	cd91                	beqz	a1,80003202 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031e8:	2605                	addiw	a2,a2,1
    800031ea:	2485                	addiw	s1,s1,1
    800031ec:	fd4618e3          	bne	a2,s4,800031bc <balloc+0x80>
    800031f0:	b759                	j	80003176 <balloc+0x3a>
  panic("balloc: out of blocks");
    800031f2:	00005517          	auipc	a0,0x5
    800031f6:	34650513          	addi	a0,a0,838 # 80008538 <syscalls+0x100>
    800031fa:	ffffd097          	auipc	ra,0xffffd
    800031fe:	330080e7          	jalr	816(ra) # 8000052a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003202:	974a                	add	a4,a4,s2
    80003204:	8fd5                	or	a5,a5,a3
    80003206:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000320a:	854a                	mv	a0,s2
    8000320c:	00001097          	auipc	ra,0x1
    80003210:	020080e7          	jalr	32(ra) # 8000422c <log_write>
        brelse(bp);
    80003214:	854a                	mv	a0,s2
    80003216:	00000097          	auipc	ra,0x0
    8000321a:	d94080e7          	jalr	-620(ra) # 80002faa <brelse>
  bp = bread(dev, bno);
    8000321e:	85a6                	mv	a1,s1
    80003220:	855e                	mv	a0,s7
    80003222:	00000097          	auipc	ra,0x0
    80003226:	c58080e7          	jalr	-936(ra) # 80002e7a <bread>
    8000322a:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000322c:	40000613          	li	a2,1024
    80003230:	4581                	li	a1,0
    80003232:	05850513          	addi	a0,a0,88
    80003236:	ffffe097          	auipc	ra,0xffffe
    8000323a:	a88080e7          	jalr	-1400(ra) # 80000cbe <memset>
  log_write(bp);
    8000323e:	854a                	mv	a0,s2
    80003240:	00001097          	auipc	ra,0x1
    80003244:	fec080e7          	jalr	-20(ra) # 8000422c <log_write>
  brelse(bp);
    80003248:	854a                	mv	a0,s2
    8000324a:	00000097          	auipc	ra,0x0
    8000324e:	d60080e7          	jalr	-672(ra) # 80002faa <brelse>
}
    80003252:	8526                	mv	a0,s1
    80003254:	60e6                	ld	ra,88(sp)
    80003256:	6446                	ld	s0,80(sp)
    80003258:	64a6                	ld	s1,72(sp)
    8000325a:	6906                	ld	s2,64(sp)
    8000325c:	79e2                	ld	s3,56(sp)
    8000325e:	7a42                	ld	s4,48(sp)
    80003260:	7aa2                	ld	s5,40(sp)
    80003262:	7b02                	ld	s6,32(sp)
    80003264:	6be2                	ld	s7,24(sp)
    80003266:	6c42                	ld	s8,16(sp)
    80003268:	6ca2                	ld	s9,8(sp)
    8000326a:	6125                	addi	sp,sp,96
    8000326c:	8082                	ret

000000008000326e <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000326e:	7179                	addi	sp,sp,-48
    80003270:	f406                	sd	ra,40(sp)
    80003272:	f022                	sd	s0,32(sp)
    80003274:	ec26                	sd	s1,24(sp)
    80003276:	e84a                	sd	s2,16(sp)
    80003278:	e44e                	sd	s3,8(sp)
    8000327a:	e052                	sd	s4,0(sp)
    8000327c:	1800                	addi	s0,sp,48
    8000327e:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003280:	47ad                	li	a5,11
    80003282:	04b7fe63          	bgeu	a5,a1,800032de <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003286:	ff45849b          	addiw	s1,a1,-12
    8000328a:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000328e:	0ff00793          	li	a5,255
    80003292:	0ae7e463          	bltu	a5,a4,8000333a <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003296:	08052583          	lw	a1,128(a0)
    8000329a:	c5b5                	beqz	a1,80003306 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000329c:	00092503          	lw	a0,0(s2)
    800032a0:	00000097          	auipc	ra,0x0
    800032a4:	bda080e7          	jalr	-1062(ra) # 80002e7a <bread>
    800032a8:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800032aa:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800032ae:	02049713          	slli	a4,s1,0x20
    800032b2:	01e75593          	srli	a1,a4,0x1e
    800032b6:	00b784b3          	add	s1,a5,a1
    800032ba:	0004a983          	lw	s3,0(s1)
    800032be:	04098e63          	beqz	s3,8000331a <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800032c2:	8552                	mv	a0,s4
    800032c4:	00000097          	auipc	ra,0x0
    800032c8:	ce6080e7          	jalr	-794(ra) # 80002faa <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800032cc:	854e                	mv	a0,s3
    800032ce:	70a2                	ld	ra,40(sp)
    800032d0:	7402                	ld	s0,32(sp)
    800032d2:	64e2                	ld	s1,24(sp)
    800032d4:	6942                	ld	s2,16(sp)
    800032d6:	69a2                	ld	s3,8(sp)
    800032d8:	6a02                	ld	s4,0(sp)
    800032da:	6145                	addi	sp,sp,48
    800032dc:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800032de:	02059793          	slli	a5,a1,0x20
    800032e2:	01e7d593          	srli	a1,a5,0x1e
    800032e6:	00b504b3          	add	s1,a0,a1
    800032ea:	0504a983          	lw	s3,80(s1)
    800032ee:	fc099fe3          	bnez	s3,800032cc <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800032f2:	4108                	lw	a0,0(a0)
    800032f4:	00000097          	auipc	ra,0x0
    800032f8:	e48080e7          	jalr	-440(ra) # 8000313c <balloc>
    800032fc:	0005099b          	sext.w	s3,a0
    80003300:	0534a823          	sw	s3,80(s1)
    80003304:	b7e1                	j	800032cc <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003306:	4108                	lw	a0,0(a0)
    80003308:	00000097          	auipc	ra,0x0
    8000330c:	e34080e7          	jalr	-460(ra) # 8000313c <balloc>
    80003310:	0005059b          	sext.w	a1,a0
    80003314:	08b92023          	sw	a1,128(s2)
    80003318:	b751                	j	8000329c <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000331a:	00092503          	lw	a0,0(s2)
    8000331e:	00000097          	auipc	ra,0x0
    80003322:	e1e080e7          	jalr	-482(ra) # 8000313c <balloc>
    80003326:	0005099b          	sext.w	s3,a0
    8000332a:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000332e:	8552                	mv	a0,s4
    80003330:	00001097          	auipc	ra,0x1
    80003334:	efc080e7          	jalr	-260(ra) # 8000422c <log_write>
    80003338:	b769                	j	800032c2 <bmap+0x54>
  panic("bmap: out of range");
    8000333a:	00005517          	auipc	a0,0x5
    8000333e:	21650513          	addi	a0,a0,534 # 80008550 <syscalls+0x118>
    80003342:	ffffd097          	auipc	ra,0xffffd
    80003346:	1e8080e7          	jalr	488(ra) # 8000052a <panic>

000000008000334a <iget>:
{
    8000334a:	7179                	addi	sp,sp,-48
    8000334c:	f406                	sd	ra,40(sp)
    8000334e:	f022                	sd	s0,32(sp)
    80003350:	ec26                	sd	s1,24(sp)
    80003352:	e84a                	sd	s2,16(sp)
    80003354:	e44e                	sd	s3,8(sp)
    80003356:	e052                	sd	s4,0(sp)
    80003358:	1800                	addi	s0,sp,48
    8000335a:	89aa                	mv	s3,a0
    8000335c:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000335e:	0001c517          	auipc	a0,0x1c
    80003362:	46a50513          	addi	a0,a0,1130 # 8001f7c8 <itable>
    80003366:	ffffe097          	auipc	ra,0xffffe
    8000336a:	85c080e7          	jalr	-1956(ra) # 80000bc2 <acquire>
  empty = 0;
    8000336e:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003370:	0001c497          	auipc	s1,0x1c
    80003374:	47048493          	addi	s1,s1,1136 # 8001f7e0 <itable+0x18>
    80003378:	0001e697          	auipc	a3,0x1e
    8000337c:	ef868693          	addi	a3,a3,-264 # 80021270 <log>
    80003380:	a039                	j	8000338e <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003382:	02090b63          	beqz	s2,800033b8 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003386:	08848493          	addi	s1,s1,136
    8000338a:	02d48a63          	beq	s1,a3,800033be <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000338e:	449c                	lw	a5,8(s1)
    80003390:	fef059e3          	blez	a5,80003382 <iget+0x38>
    80003394:	4098                	lw	a4,0(s1)
    80003396:	ff3716e3          	bne	a4,s3,80003382 <iget+0x38>
    8000339a:	40d8                	lw	a4,4(s1)
    8000339c:	ff4713e3          	bne	a4,s4,80003382 <iget+0x38>
      ip->ref++;
    800033a0:	2785                	addiw	a5,a5,1
    800033a2:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800033a4:	0001c517          	auipc	a0,0x1c
    800033a8:	42450513          	addi	a0,a0,1060 # 8001f7c8 <itable>
    800033ac:	ffffe097          	auipc	ra,0xffffe
    800033b0:	8ca080e7          	jalr	-1846(ra) # 80000c76 <release>
      return ip;
    800033b4:	8926                	mv	s2,s1
    800033b6:	a03d                	j	800033e4 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800033b8:	f7f9                	bnez	a5,80003386 <iget+0x3c>
    800033ba:	8926                	mv	s2,s1
    800033bc:	b7e9                	j	80003386 <iget+0x3c>
  if(empty == 0)
    800033be:	02090c63          	beqz	s2,800033f6 <iget+0xac>
  ip->dev = dev;
    800033c2:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800033c6:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800033ca:	4785                	li	a5,1
    800033cc:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800033d0:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800033d4:	0001c517          	auipc	a0,0x1c
    800033d8:	3f450513          	addi	a0,a0,1012 # 8001f7c8 <itable>
    800033dc:	ffffe097          	auipc	ra,0xffffe
    800033e0:	89a080e7          	jalr	-1894(ra) # 80000c76 <release>
}
    800033e4:	854a                	mv	a0,s2
    800033e6:	70a2                	ld	ra,40(sp)
    800033e8:	7402                	ld	s0,32(sp)
    800033ea:	64e2                	ld	s1,24(sp)
    800033ec:	6942                	ld	s2,16(sp)
    800033ee:	69a2                	ld	s3,8(sp)
    800033f0:	6a02                	ld	s4,0(sp)
    800033f2:	6145                	addi	sp,sp,48
    800033f4:	8082                	ret
    panic("iget: no inodes");
    800033f6:	00005517          	auipc	a0,0x5
    800033fa:	17250513          	addi	a0,a0,370 # 80008568 <syscalls+0x130>
    800033fe:	ffffd097          	auipc	ra,0xffffd
    80003402:	12c080e7          	jalr	300(ra) # 8000052a <panic>

0000000080003406 <fsinit>:
fsinit(int dev) {
    80003406:	7179                	addi	sp,sp,-48
    80003408:	f406                	sd	ra,40(sp)
    8000340a:	f022                	sd	s0,32(sp)
    8000340c:	ec26                	sd	s1,24(sp)
    8000340e:	e84a                	sd	s2,16(sp)
    80003410:	e44e                	sd	s3,8(sp)
    80003412:	1800                	addi	s0,sp,48
    80003414:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003416:	4585                	li	a1,1
    80003418:	00000097          	auipc	ra,0x0
    8000341c:	a62080e7          	jalr	-1438(ra) # 80002e7a <bread>
    80003420:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003422:	0001c997          	auipc	s3,0x1c
    80003426:	38698993          	addi	s3,s3,902 # 8001f7a8 <sb>
    8000342a:	02000613          	li	a2,32
    8000342e:	05850593          	addi	a1,a0,88
    80003432:	854e                	mv	a0,s3
    80003434:	ffffe097          	auipc	ra,0xffffe
    80003438:	8e6080e7          	jalr	-1818(ra) # 80000d1a <memmove>
  brelse(bp);
    8000343c:	8526                	mv	a0,s1
    8000343e:	00000097          	auipc	ra,0x0
    80003442:	b6c080e7          	jalr	-1172(ra) # 80002faa <brelse>
  if(sb.magic != FSMAGIC)
    80003446:	0009a703          	lw	a4,0(s3)
    8000344a:	102037b7          	lui	a5,0x10203
    8000344e:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003452:	02f71263          	bne	a4,a5,80003476 <fsinit+0x70>
  initlog(dev, &sb);
    80003456:	0001c597          	auipc	a1,0x1c
    8000345a:	35258593          	addi	a1,a1,850 # 8001f7a8 <sb>
    8000345e:	854a                	mv	a0,s2
    80003460:	00001097          	auipc	ra,0x1
    80003464:	b4e080e7          	jalr	-1202(ra) # 80003fae <initlog>
}
    80003468:	70a2                	ld	ra,40(sp)
    8000346a:	7402                	ld	s0,32(sp)
    8000346c:	64e2                	ld	s1,24(sp)
    8000346e:	6942                	ld	s2,16(sp)
    80003470:	69a2                	ld	s3,8(sp)
    80003472:	6145                	addi	sp,sp,48
    80003474:	8082                	ret
    panic("invalid file system");
    80003476:	00005517          	auipc	a0,0x5
    8000347a:	10250513          	addi	a0,a0,258 # 80008578 <syscalls+0x140>
    8000347e:	ffffd097          	auipc	ra,0xffffd
    80003482:	0ac080e7          	jalr	172(ra) # 8000052a <panic>

0000000080003486 <iinit>:
{
    80003486:	7179                	addi	sp,sp,-48
    80003488:	f406                	sd	ra,40(sp)
    8000348a:	f022                	sd	s0,32(sp)
    8000348c:	ec26                	sd	s1,24(sp)
    8000348e:	e84a                	sd	s2,16(sp)
    80003490:	e44e                	sd	s3,8(sp)
    80003492:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003494:	00005597          	auipc	a1,0x5
    80003498:	0fc58593          	addi	a1,a1,252 # 80008590 <syscalls+0x158>
    8000349c:	0001c517          	auipc	a0,0x1c
    800034a0:	32c50513          	addi	a0,a0,812 # 8001f7c8 <itable>
    800034a4:	ffffd097          	auipc	ra,0xffffd
    800034a8:	68e080e7          	jalr	1678(ra) # 80000b32 <initlock>
  for(i = 0; i < NINODE; i++) {
    800034ac:	0001c497          	auipc	s1,0x1c
    800034b0:	34448493          	addi	s1,s1,836 # 8001f7f0 <itable+0x28>
    800034b4:	0001e997          	auipc	s3,0x1e
    800034b8:	dcc98993          	addi	s3,s3,-564 # 80021280 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800034bc:	00005917          	auipc	s2,0x5
    800034c0:	0dc90913          	addi	s2,s2,220 # 80008598 <syscalls+0x160>
    800034c4:	85ca                	mv	a1,s2
    800034c6:	8526                	mv	a0,s1
    800034c8:	00001097          	auipc	ra,0x1
    800034cc:	e4a080e7          	jalr	-438(ra) # 80004312 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800034d0:	08848493          	addi	s1,s1,136
    800034d4:	ff3498e3          	bne	s1,s3,800034c4 <iinit+0x3e>
}
    800034d8:	70a2                	ld	ra,40(sp)
    800034da:	7402                	ld	s0,32(sp)
    800034dc:	64e2                	ld	s1,24(sp)
    800034de:	6942                	ld	s2,16(sp)
    800034e0:	69a2                	ld	s3,8(sp)
    800034e2:	6145                	addi	sp,sp,48
    800034e4:	8082                	ret

00000000800034e6 <ialloc>:
{
    800034e6:	715d                	addi	sp,sp,-80
    800034e8:	e486                	sd	ra,72(sp)
    800034ea:	e0a2                	sd	s0,64(sp)
    800034ec:	fc26                	sd	s1,56(sp)
    800034ee:	f84a                	sd	s2,48(sp)
    800034f0:	f44e                	sd	s3,40(sp)
    800034f2:	f052                	sd	s4,32(sp)
    800034f4:	ec56                	sd	s5,24(sp)
    800034f6:	e85a                	sd	s6,16(sp)
    800034f8:	e45e                	sd	s7,8(sp)
    800034fa:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800034fc:	0001c717          	auipc	a4,0x1c
    80003500:	2b872703          	lw	a4,696(a4) # 8001f7b4 <sb+0xc>
    80003504:	4785                	li	a5,1
    80003506:	04e7fa63          	bgeu	a5,a4,8000355a <ialloc+0x74>
    8000350a:	8aaa                	mv	s5,a0
    8000350c:	8bae                	mv	s7,a1
    8000350e:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003510:	0001ca17          	auipc	s4,0x1c
    80003514:	298a0a13          	addi	s4,s4,664 # 8001f7a8 <sb>
    80003518:	00048b1b          	sext.w	s6,s1
    8000351c:	0044d793          	srli	a5,s1,0x4
    80003520:	018a2583          	lw	a1,24(s4)
    80003524:	9dbd                	addw	a1,a1,a5
    80003526:	8556                	mv	a0,s5
    80003528:	00000097          	auipc	ra,0x0
    8000352c:	952080e7          	jalr	-1710(ra) # 80002e7a <bread>
    80003530:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003532:	05850993          	addi	s3,a0,88
    80003536:	00f4f793          	andi	a5,s1,15
    8000353a:	079a                	slli	a5,a5,0x6
    8000353c:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000353e:	00099783          	lh	a5,0(s3)
    80003542:	c785                	beqz	a5,8000356a <ialloc+0x84>
    brelse(bp);
    80003544:	00000097          	auipc	ra,0x0
    80003548:	a66080e7          	jalr	-1434(ra) # 80002faa <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000354c:	0485                	addi	s1,s1,1
    8000354e:	00ca2703          	lw	a4,12(s4)
    80003552:	0004879b          	sext.w	a5,s1
    80003556:	fce7e1e3          	bltu	a5,a4,80003518 <ialloc+0x32>
  panic("ialloc: no inodes");
    8000355a:	00005517          	auipc	a0,0x5
    8000355e:	04650513          	addi	a0,a0,70 # 800085a0 <syscalls+0x168>
    80003562:	ffffd097          	auipc	ra,0xffffd
    80003566:	fc8080e7          	jalr	-56(ra) # 8000052a <panic>
      memset(dip, 0, sizeof(*dip));
    8000356a:	04000613          	li	a2,64
    8000356e:	4581                	li	a1,0
    80003570:	854e                	mv	a0,s3
    80003572:	ffffd097          	auipc	ra,0xffffd
    80003576:	74c080e7          	jalr	1868(ra) # 80000cbe <memset>
      dip->type = type;
    8000357a:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000357e:	854a                	mv	a0,s2
    80003580:	00001097          	auipc	ra,0x1
    80003584:	cac080e7          	jalr	-852(ra) # 8000422c <log_write>
      brelse(bp);
    80003588:	854a                	mv	a0,s2
    8000358a:	00000097          	auipc	ra,0x0
    8000358e:	a20080e7          	jalr	-1504(ra) # 80002faa <brelse>
      return iget(dev, inum);
    80003592:	85da                	mv	a1,s6
    80003594:	8556                	mv	a0,s5
    80003596:	00000097          	auipc	ra,0x0
    8000359a:	db4080e7          	jalr	-588(ra) # 8000334a <iget>
}
    8000359e:	60a6                	ld	ra,72(sp)
    800035a0:	6406                	ld	s0,64(sp)
    800035a2:	74e2                	ld	s1,56(sp)
    800035a4:	7942                	ld	s2,48(sp)
    800035a6:	79a2                	ld	s3,40(sp)
    800035a8:	7a02                	ld	s4,32(sp)
    800035aa:	6ae2                	ld	s5,24(sp)
    800035ac:	6b42                	ld	s6,16(sp)
    800035ae:	6ba2                	ld	s7,8(sp)
    800035b0:	6161                	addi	sp,sp,80
    800035b2:	8082                	ret

00000000800035b4 <iupdate>:
{
    800035b4:	1101                	addi	sp,sp,-32
    800035b6:	ec06                	sd	ra,24(sp)
    800035b8:	e822                	sd	s0,16(sp)
    800035ba:	e426                	sd	s1,8(sp)
    800035bc:	e04a                	sd	s2,0(sp)
    800035be:	1000                	addi	s0,sp,32
    800035c0:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800035c2:	415c                	lw	a5,4(a0)
    800035c4:	0047d79b          	srliw	a5,a5,0x4
    800035c8:	0001c597          	auipc	a1,0x1c
    800035cc:	1f85a583          	lw	a1,504(a1) # 8001f7c0 <sb+0x18>
    800035d0:	9dbd                	addw	a1,a1,a5
    800035d2:	4108                	lw	a0,0(a0)
    800035d4:	00000097          	auipc	ra,0x0
    800035d8:	8a6080e7          	jalr	-1882(ra) # 80002e7a <bread>
    800035dc:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800035de:	05850793          	addi	a5,a0,88
    800035e2:	40c8                	lw	a0,4(s1)
    800035e4:	893d                	andi	a0,a0,15
    800035e6:	051a                	slli	a0,a0,0x6
    800035e8:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800035ea:	04449703          	lh	a4,68(s1)
    800035ee:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800035f2:	04649703          	lh	a4,70(s1)
    800035f6:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800035fa:	04849703          	lh	a4,72(s1)
    800035fe:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003602:	04a49703          	lh	a4,74(s1)
    80003606:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    8000360a:	44f8                	lw	a4,76(s1)
    8000360c:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000360e:	03400613          	li	a2,52
    80003612:	05048593          	addi	a1,s1,80
    80003616:	0531                	addi	a0,a0,12
    80003618:	ffffd097          	auipc	ra,0xffffd
    8000361c:	702080e7          	jalr	1794(ra) # 80000d1a <memmove>
  log_write(bp);
    80003620:	854a                	mv	a0,s2
    80003622:	00001097          	auipc	ra,0x1
    80003626:	c0a080e7          	jalr	-1014(ra) # 8000422c <log_write>
  brelse(bp);
    8000362a:	854a                	mv	a0,s2
    8000362c:	00000097          	auipc	ra,0x0
    80003630:	97e080e7          	jalr	-1666(ra) # 80002faa <brelse>
}
    80003634:	60e2                	ld	ra,24(sp)
    80003636:	6442                	ld	s0,16(sp)
    80003638:	64a2                	ld	s1,8(sp)
    8000363a:	6902                	ld	s2,0(sp)
    8000363c:	6105                	addi	sp,sp,32
    8000363e:	8082                	ret

0000000080003640 <idup>:
{
    80003640:	1101                	addi	sp,sp,-32
    80003642:	ec06                	sd	ra,24(sp)
    80003644:	e822                	sd	s0,16(sp)
    80003646:	e426                	sd	s1,8(sp)
    80003648:	1000                	addi	s0,sp,32
    8000364a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000364c:	0001c517          	auipc	a0,0x1c
    80003650:	17c50513          	addi	a0,a0,380 # 8001f7c8 <itable>
    80003654:	ffffd097          	auipc	ra,0xffffd
    80003658:	56e080e7          	jalr	1390(ra) # 80000bc2 <acquire>
  ip->ref++;
    8000365c:	449c                	lw	a5,8(s1)
    8000365e:	2785                	addiw	a5,a5,1
    80003660:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003662:	0001c517          	auipc	a0,0x1c
    80003666:	16650513          	addi	a0,a0,358 # 8001f7c8 <itable>
    8000366a:	ffffd097          	auipc	ra,0xffffd
    8000366e:	60c080e7          	jalr	1548(ra) # 80000c76 <release>
}
    80003672:	8526                	mv	a0,s1
    80003674:	60e2                	ld	ra,24(sp)
    80003676:	6442                	ld	s0,16(sp)
    80003678:	64a2                	ld	s1,8(sp)
    8000367a:	6105                	addi	sp,sp,32
    8000367c:	8082                	ret

000000008000367e <ilock>:
{
    8000367e:	1101                	addi	sp,sp,-32
    80003680:	ec06                	sd	ra,24(sp)
    80003682:	e822                	sd	s0,16(sp)
    80003684:	e426                	sd	s1,8(sp)
    80003686:	e04a                	sd	s2,0(sp)
    80003688:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000368a:	c115                	beqz	a0,800036ae <ilock+0x30>
    8000368c:	84aa                	mv	s1,a0
    8000368e:	451c                	lw	a5,8(a0)
    80003690:	00f05f63          	blez	a5,800036ae <ilock+0x30>
  acquiresleep(&ip->lock);
    80003694:	0541                	addi	a0,a0,16
    80003696:	00001097          	auipc	ra,0x1
    8000369a:	cb6080e7          	jalr	-842(ra) # 8000434c <acquiresleep>
  if(ip->valid == 0){
    8000369e:	40bc                	lw	a5,64(s1)
    800036a0:	cf99                	beqz	a5,800036be <ilock+0x40>
}
    800036a2:	60e2                	ld	ra,24(sp)
    800036a4:	6442                	ld	s0,16(sp)
    800036a6:	64a2                	ld	s1,8(sp)
    800036a8:	6902                	ld	s2,0(sp)
    800036aa:	6105                	addi	sp,sp,32
    800036ac:	8082                	ret
    panic("ilock");
    800036ae:	00005517          	auipc	a0,0x5
    800036b2:	f0a50513          	addi	a0,a0,-246 # 800085b8 <syscalls+0x180>
    800036b6:	ffffd097          	auipc	ra,0xffffd
    800036ba:	e74080e7          	jalr	-396(ra) # 8000052a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800036be:	40dc                	lw	a5,4(s1)
    800036c0:	0047d79b          	srliw	a5,a5,0x4
    800036c4:	0001c597          	auipc	a1,0x1c
    800036c8:	0fc5a583          	lw	a1,252(a1) # 8001f7c0 <sb+0x18>
    800036cc:	9dbd                	addw	a1,a1,a5
    800036ce:	4088                	lw	a0,0(s1)
    800036d0:	fffff097          	auipc	ra,0xfffff
    800036d4:	7aa080e7          	jalr	1962(ra) # 80002e7a <bread>
    800036d8:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800036da:	05850593          	addi	a1,a0,88
    800036de:	40dc                	lw	a5,4(s1)
    800036e0:	8bbd                	andi	a5,a5,15
    800036e2:	079a                	slli	a5,a5,0x6
    800036e4:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800036e6:	00059783          	lh	a5,0(a1)
    800036ea:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800036ee:	00259783          	lh	a5,2(a1)
    800036f2:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800036f6:	00459783          	lh	a5,4(a1)
    800036fa:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800036fe:	00659783          	lh	a5,6(a1)
    80003702:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003706:	459c                	lw	a5,8(a1)
    80003708:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000370a:	03400613          	li	a2,52
    8000370e:	05b1                	addi	a1,a1,12
    80003710:	05048513          	addi	a0,s1,80
    80003714:	ffffd097          	auipc	ra,0xffffd
    80003718:	606080e7          	jalr	1542(ra) # 80000d1a <memmove>
    brelse(bp);
    8000371c:	854a                	mv	a0,s2
    8000371e:	00000097          	auipc	ra,0x0
    80003722:	88c080e7          	jalr	-1908(ra) # 80002faa <brelse>
    ip->valid = 1;
    80003726:	4785                	li	a5,1
    80003728:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000372a:	04449783          	lh	a5,68(s1)
    8000372e:	fbb5                	bnez	a5,800036a2 <ilock+0x24>
      panic("ilock: no type");
    80003730:	00005517          	auipc	a0,0x5
    80003734:	e9050513          	addi	a0,a0,-368 # 800085c0 <syscalls+0x188>
    80003738:	ffffd097          	auipc	ra,0xffffd
    8000373c:	df2080e7          	jalr	-526(ra) # 8000052a <panic>

0000000080003740 <iunlock>:
{
    80003740:	1101                	addi	sp,sp,-32
    80003742:	ec06                	sd	ra,24(sp)
    80003744:	e822                	sd	s0,16(sp)
    80003746:	e426                	sd	s1,8(sp)
    80003748:	e04a                	sd	s2,0(sp)
    8000374a:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000374c:	c905                	beqz	a0,8000377c <iunlock+0x3c>
    8000374e:	84aa                	mv	s1,a0
    80003750:	01050913          	addi	s2,a0,16
    80003754:	854a                	mv	a0,s2
    80003756:	00001097          	auipc	ra,0x1
    8000375a:	c90080e7          	jalr	-880(ra) # 800043e6 <holdingsleep>
    8000375e:	cd19                	beqz	a0,8000377c <iunlock+0x3c>
    80003760:	449c                	lw	a5,8(s1)
    80003762:	00f05d63          	blez	a5,8000377c <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003766:	854a                	mv	a0,s2
    80003768:	00001097          	auipc	ra,0x1
    8000376c:	c3a080e7          	jalr	-966(ra) # 800043a2 <releasesleep>
}
    80003770:	60e2                	ld	ra,24(sp)
    80003772:	6442                	ld	s0,16(sp)
    80003774:	64a2                	ld	s1,8(sp)
    80003776:	6902                	ld	s2,0(sp)
    80003778:	6105                	addi	sp,sp,32
    8000377a:	8082                	ret
    panic("iunlock");
    8000377c:	00005517          	auipc	a0,0x5
    80003780:	e5450513          	addi	a0,a0,-428 # 800085d0 <syscalls+0x198>
    80003784:	ffffd097          	auipc	ra,0xffffd
    80003788:	da6080e7          	jalr	-602(ra) # 8000052a <panic>

000000008000378c <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000378c:	7179                	addi	sp,sp,-48
    8000378e:	f406                	sd	ra,40(sp)
    80003790:	f022                	sd	s0,32(sp)
    80003792:	ec26                	sd	s1,24(sp)
    80003794:	e84a                	sd	s2,16(sp)
    80003796:	e44e                	sd	s3,8(sp)
    80003798:	e052                	sd	s4,0(sp)
    8000379a:	1800                	addi	s0,sp,48
    8000379c:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000379e:	05050493          	addi	s1,a0,80
    800037a2:	08050913          	addi	s2,a0,128
    800037a6:	a021                	j	800037ae <itrunc+0x22>
    800037a8:	0491                	addi	s1,s1,4
    800037aa:	01248d63          	beq	s1,s2,800037c4 <itrunc+0x38>
    if(ip->addrs[i]){
    800037ae:	408c                	lw	a1,0(s1)
    800037b0:	dde5                	beqz	a1,800037a8 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800037b2:	0009a503          	lw	a0,0(s3)
    800037b6:	00000097          	auipc	ra,0x0
    800037ba:	90a080e7          	jalr	-1782(ra) # 800030c0 <bfree>
      ip->addrs[i] = 0;
    800037be:	0004a023          	sw	zero,0(s1)
    800037c2:	b7dd                	j	800037a8 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800037c4:	0809a583          	lw	a1,128(s3)
    800037c8:	e185                	bnez	a1,800037e8 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800037ca:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800037ce:	854e                	mv	a0,s3
    800037d0:	00000097          	auipc	ra,0x0
    800037d4:	de4080e7          	jalr	-540(ra) # 800035b4 <iupdate>
}
    800037d8:	70a2                	ld	ra,40(sp)
    800037da:	7402                	ld	s0,32(sp)
    800037dc:	64e2                	ld	s1,24(sp)
    800037de:	6942                	ld	s2,16(sp)
    800037e0:	69a2                	ld	s3,8(sp)
    800037e2:	6a02                	ld	s4,0(sp)
    800037e4:	6145                	addi	sp,sp,48
    800037e6:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800037e8:	0009a503          	lw	a0,0(s3)
    800037ec:	fffff097          	auipc	ra,0xfffff
    800037f0:	68e080e7          	jalr	1678(ra) # 80002e7a <bread>
    800037f4:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800037f6:	05850493          	addi	s1,a0,88
    800037fa:	45850913          	addi	s2,a0,1112
    800037fe:	a021                	j	80003806 <itrunc+0x7a>
    80003800:	0491                	addi	s1,s1,4
    80003802:	01248b63          	beq	s1,s2,80003818 <itrunc+0x8c>
      if(a[j])
    80003806:	408c                	lw	a1,0(s1)
    80003808:	dde5                	beqz	a1,80003800 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    8000380a:	0009a503          	lw	a0,0(s3)
    8000380e:	00000097          	auipc	ra,0x0
    80003812:	8b2080e7          	jalr	-1870(ra) # 800030c0 <bfree>
    80003816:	b7ed                	j	80003800 <itrunc+0x74>
    brelse(bp);
    80003818:	8552                	mv	a0,s4
    8000381a:	fffff097          	auipc	ra,0xfffff
    8000381e:	790080e7          	jalr	1936(ra) # 80002faa <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003822:	0809a583          	lw	a1,128(s3)
    80003826:	0009a503          	lw	a0,0(s3)
    8000382a:	00000097          	auipc	ra,0x0
    8000382e:	896080e7          	jalr	-1898(ra) # 800030c0 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003832:	0809a023          	sw	zero,128(s3)
    80003836:	bf51                	j	800037ca <itrunc+0x3e>

0000000080003838 <iput>:
{
    80003838:	1101                	addi	sp,sp,-32
    8000383a:	ec06                	sd	ra,24(sp)
    8000383c:	e822                	sd	s0,16(sp)
    8000383e:	e426                	sd	s1,8(sp)
    80003840:	e04a                	sd	s2,0(sp)
    80003842:	1000                	addi	s0,sp,32
    80003844:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003846:	0001c517          	auipc	a0,0x1c
    8000384a:	f8250513          	addi	a0,a0,-126 # 8001f7c8 <itable>
    8000384e:	ffffd097          	auipc	ra,0xffffd
    80003852:	374080e7          	jalr	884(ra) # 80000bc2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003856:	4498                	lw	a4,8(s1)
    80003858:	4785                	li	a5,1
    8000385a:	02f70363          	beq	a4,a5,80003880 <iput+0x48>
  ip->ref--;
    8000385e:	449c                	lw	a5,8(s1)
    80003860:	37fd                	addiw	a5,a5,-1
    80003862:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003864:	0001c517          	auipc	a0,0x1c
    80003868:	f6450513          	addi	a0,a0,-156 # 8001f7c8 <itable>
    8000386c:	ffffd097          	auipc	ra,0xffffd
    80003870:	40a080e7          	jalr	1034(ra) # 80000c76 <release>
}
    80003874:	60e2                	ld	ra,24(sp)
    80003876:	6442                	ld	s0,16(sp)
    80003878:	64a2                	ld	s1,8(sp)
    8000387a:	6902                	ld	s2,0(sp)
    8000387c:	6105                	addi	sp,sp,32
    8000387e:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003880:	40bc                	lw	a5,64(s1)
    80003882:	dff1                	beqz	a5,8000385e <iput+0x26>
    80003884:	04a49783          	lh	a5,74(s1)
    80003888:	fbf9                	bnez	a5,8000385e <iput+0x26>
    acquiresleep(&ip->lock);
    8000388a:	01048913          	addi	s2,s1,16
    8000388e:	854a                	mv	a0,s2
    80003890:	00001097          	auipc	ra,0x1
    80003894:	abc080e7          	jalr	-1348(ra) # 8000434c <acquiresleep>
    release(&itable.lock);
    80003898:	0001c517          	auipc	a0,0x1c
    8000389c:	f3050513          	addi	a0,a0,-208 # 8001f7c8 <itable>
    800038a0:	ffffd097          	auipc	ra,0xffffd
    800038a4:	3d6080e7          	jalr	982(ra) # 80000c76 <release>
    itrunc(ip);
    800038a8:	8526                	mv	a0,s1
    800038aa:	00000097          	auipc	ra,0x0
    800038ae:	ee2080e7          	jalr	-286(ra) # 8000378c <itrunc>
    ip->type = 0;
    800038b2:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800038b6:	8526                	mv	a0,s1
    800038b8:	00000097          	auipc	ra,0x0
    800038bc:	cfc080e7          	jalr	-772(ra) # 800035b4 <iupdate>
    ip->valid = 0;
    800038c0:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800038c4:	854a                	mv	a0,s2
    800038c6:	00001097          	auipc	ra,0x1
    800038ca:	adc080e7          	jalr	-1316(ra) # 800043a2 <releasesleep>
    acquire(&itable.lock);
    800038ce:	0001c517          	auipc	a0,0x1c
    800038d2:	efa50513          	addi	a0,a0,-262 # 8001f7c8 <itable>
    800038d6:	ffffd097          	auipc	ra,0xffffd
    800038da:	2ec080e7          	jalr	748(ra) # 80000bc2 <acquire>
    800038de:	b741                	j	8000385e <iput+0x26>

00000000800038e0 <iunlockput>:
{
    800038e0:	1101                	addi	sp,sp,-32
    800038e2:	ec06                	sd	ra,24(sp)
    800038e4:	e822                	sd	s0,16(sp)
    800038e6:	e426                	sd	s1,8(sp)
    800038e8:	1000                	addi	s0,sp,32
    800038ea:	84aa                	mv	s1,a0
  iunlock(ip);
    800038ec:	00000097          	auipc	ra,0x0
    800038f0:	e54080e7          	jalr	-428(ra) # 80003740 <iunlock>
  iput(ip);
    800038f4:	8526                	mv	a0,s1
    800038f6:	00000097          	auipc	ra,0x0
    800038fa:	f42080e7          	jalr	-190(ra) # 80003838 <iput>
}
    800038fe:	60e2                	ld	ra,24(sp)
    80003900:	6442                	ld	s0,16(sp)
    80003902:	64a2                	ld	s1,8(sp)
    80003904:	6105                	addi	sp,sp,32
    80003906:	8082                	ret

0000000080003908 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003908:	1141                	addi	sp,sp,-16
    8000390a:	e422                	sd	s0,8(sp)
    8000390c:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    8000390e:	411c                	lw	a5,0(a0)
    80003910:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003912:	415c                	lw	a5,4(a0)
    80003914:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003916:	04451783          	lh	a5,68(a0)
    8000391a:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    8000391e:	04a51783          	lh	a5,74(a0)
    80003922:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003926:	04c56783          	lwu	a5,76(a0)
    8000392a:	e99c                	sd	a5,16(a1)
}
    8000392c:	6422                	ld	s0,8(sp)
    8000392e:	0141                	addi	sp,sp,16
    80003930:	8082                	ret

0000000080003932 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003932:	457c                	lw	a5,76(a0)
    80003934:	0ed7e963          	bltu	a5,a3,80003a26 <readi+0xf4>
{
    80003938:	7159                	addi	sp,sp,-112
    8000393a:	f486                	sd	ra,104(sp)
    8000393c:	f0a2                	sd	s0,96(sp)
    8000393e:	eca6                	sd	s1,88(sp)
    80003940:	e8ca                	sd	s2,80(sp)
    80003942:	e4ce                	sd	s3,72(sp)
    80003944:	e0d2                	sd	s4,64(sp)
    80003946:	fc56                	sd	s5,56(sp)
    80003948:	f85a                	sd	s6,48(sp)
    8000394a:	f45e                	sd	s7,40(sp)
    8000394c:	f062                	sd	s8,32(sp)
    8000394e:	ec66                	sd	s9,24(sp)
    80003950:	e86a                	sd	s10,16(sp)
    80003952:	e46e                	sd	s11,8(sp)
    80003954:	1880                	addi	s0,sp,112
    80003956:	8baa                	mv	s7,a0
    80003958:	8c2e                	mv	s8,a1
    8000395a:	8ab2                	mv	s5,a2
    8000395c:	84b6                	mv	s1,a3
    8000395e:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003960:	9f35                	addw	a4,a4,a3
    return 0;
    80003962:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003964:	0ad76063          	bltu	a4,a3,80003a04 <readi+0xd2>
  if(off + n > ip->size)
    80003968:	00e7f463          	bgeu	a5,a4,80003970 <readi+0x3e>
    n = ip->size - off;
    8000396c:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003970:	0a0b0963          	beqz	s6,80003a22 <readi+0xf0>
    80003974:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003976:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    8000397a:	5cfd                	li	s9,-1
    8000397c:	a82d                	j	800039b6 <readi+0x84>
    8000397e:	020a1d93          	slli	s11,s4,0x20
    80003982:	020ddd93          	srli	s11,s11,0x20
    80003986:	05890793          	addi	a5,s2,88
    8000398a:	86ee                	mv	a3,s11
    8000398c:	963e                	add	a2,a2,a5
    8000398e:	85d6                	mv	a1,s5
    80003990:	8562                	mv	a0,s8
    80003992:	fffff097          	auipc	ra,0xfffff
    80003996:	aa4080e7          	jalr	-1372(ra) # 80002436 <either_copyout>
    8000399a:	05950d63          	beq	a0,s9,800039f4 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    8000399e:	854a                	mv	a0,s2
    800039a0:	fffff097          	auipc	ra,0xfffff
    800039a4:	60a080e7          	jalr	1546(ra) # 80002faa <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800039a8:	013a09bb          	addw	s3,s4,s3
    800039ac:	009a04bb          	addw	s1,s4,s1
    800039b0:	9aee                	add	s5,s5,s11
    800039b2:	0569f763          	bgeu	s3,s6,80003a00 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800039b6:	000ba903          	lw	s2,0(s7)
    800039ba:	00a4d59b          	srliw	a1,s1,0xa
    800039be:	855e                	mv	a0,s7
    800039c0:	00000097          	auipc	ra,0x0
    800039c4:	8ae080e7          	jalr	-1874(ra) # 8000326e <bmap>
    800039c8:	0005059b          	sext.w	a1,a0
    800039cc:	854a                	mv	a0,s2
    800039ce:	fffff097          	auipc	ra,0xfffff
    800039d2:	4ac080e7          	jalr	1196(ra) # 80002e7a <bread>
    800039d6:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800039d8:	3ff4f613          	andi	a2,s1,1023
    800039dc:	40cd07bb          	subw	a5,s10,a2
    800039e0:	413b073b          	subw	a4,s6,s3
    800039e4:	8a3e                	mv	s4,a5
    800039e6:	2781                	sext.w	a5,a5
    800039e8:	0007069b          	sext.w	a3,a4
    800039ec:	f8f6f9e3          	bgeu	a3,a5,8000397e <readi+0x4c>
    800039f0:	8a3a                	mv	s4,a4
    800039f2:	b771                	j	8000397e <readi+0x4c>
      brelse(bp);
    800039f4:	854a                	mv	a0,s2
    800039f6:	fffff097          	auipc	ra,0xfffff
    800039fa:	5b4080e7          	jalr	1460(ra) # 80002faa <brelse>
      tot = -1;
    800039fe:	59fd                	li	s3,-1
  }
  return tot;
    80003a00:	0009851b          	sext.w	a0,s3
}
    80003a04:	70a6                	ld	ra,104(sp)
    80003a06:	7406                	ld	s0,96(sp)
    80003a08:	64e6                	ld	s1,88(sp)
    80003a0a:	6946                	ld	s2,80(sp)
    80003a0c:	69a6                	ld	s3,72(sp)
    80003a0e:	6a06                	ld	s4,64(sp)
    80003a10:	7ae2                	ld	s5,56(sp)
    80003a12:	7b42                	ld	s6,48(sp)
    80003a14:	7ba2                	ld	s7,40(sp)
    80003a16:	7c02                	ld	s8,32(sp)
    80003a18:	6ce2                	ld	s9,24(sp)
    80003a1a:	6d42                	ld	s10,16(sp)
    80003a1c:	6da2                	ld	s11,8(sp)
    80003a1e:	6165                	addi	sp,sp,112
    80003a20:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a22:	89da                	mv	s3,s6
    80003a24:	bff1                	j	80003a00 <readi+0xce>
    return 0;
    80003a26:	4501                	li	a0,0
}
    80003a28:	8082                	ret

0000000080003a2a <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a2a:	457c                	lw	a5,76(a0)
    80003a2c:	10d7e863          	bltu	a5,a3,80003b3c <writei+0x112>
{
    80003a30:	7159                	addi	sp,sp,-112
    80003a32:	f486                	sd	ra,104(sp)
    80003a34:	f0a2                	sd	s0,96(sp)
    80003a36:	eca6                	sd	s1,88(sp)
    80003a38:	e8ca                	sd	s2,80(sp)
    80003a3a:	e4ce                	sd	s3,72(sp)
    80003a3c:	e0d2                	sd	s4,64(sp)
    80003a3e:	fc56                	sd	s5,56(sp)
    80003a40:	f85a                	sd	s6,48(sp)
    80003a42:	f45e                	sd	s7,40(sp)
    80003a44:	f062                	sd	s8,32(sp)
    80003a46:	ec66                	sd	s9,24(sp)
    80003a48:	e86a                	sd	s10,16(sp)
    80003a4a:	e46e                	sd	s11,8(sp)
    80003a4c:	1880                	addi	s0,sp,112
    80003a4e:	8b2a                	mv	s6,a0
    80003a50:	8c2e                	mv	s8,a1
    80003a52:	8ab2                	mv	s5,a2
    80003a54:	8936                	mv	s2,a3
    80003a56:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003a58:	00e687bb          	addw	a5,a3,a4
    80003a5c:	0ed7e263          	bltu	a5,a3,80003b40 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003a60:	00043737          	lui	a4,0x43
    80003a64:	0ef76063          	bltu	a4,a5,80003b44 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a68:	0c0b8863          	beqz	s7,80003b38 <writei+0x10e>
    80003a6c:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a6e:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003a72:	5cfd                	li	s9,-1
    80003a74:	a091                	j	80003ab8 <writei+0x8e>
    80003a76:	02099d93          	slli	s11,s3,0x20
    80003a7a:	020ddd93          	srli	s11,s11,0x20
    80003a7e:	05848793          	addi	a5,s1,88
    80003a82:	86ee                	mv	a3,s11
    80003a84:	8656                	mv	a2,s5
    80003a86:	85e2                	mv	a1,s8
    80003a88:	953e                	add	a0,a0,a5
    80003a8a:	fffff097          	auipc	ra,0xfffff
    80003a8e:	a02080e7          	jalr	-1534(ra) # 8000248c <either_copyin>
    80003a92:	07950263          	beq	a0,s9,80003af6 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003a96:	8526                	mv	a0,s1
    80003a98:	00000097          	auipc	ra,0x0
    80003a9c:	794080e7          	jalr	1940(ra) # 8000422c <log_write>
    brelse(bp);
    80003aa0:	8526                	mv	a0,s1
    80003aa2:	fffff097          	auipc	ra,0xfffff
    80003aa6:	508080e7          	jalr	1288(ra) # 80002faa <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003aaa:	01498a3b          	addw	s4,s3,s4
    80003aae:	0129893b          	addw	s2,s3,s2
    80003ab2:	9aee                	add	s5,s5,s11
    80003ab4:	057a7663          	bgeu	s4,s7,80003b00 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003ab8:	000b2483          	lw	s1,0(s6)
    80003abc:	00a9559b          	srliw	a1,s2,0xa
    80003ac0:	855a                	mv	a0,s6
    80003ac2:	fffff097          	auipc	ra,0xfffff
    80003ac6:	7ac080e7          	jalr	1964(ra) # 8000326e <bmap>
    80003aca:	0005059b          	sext.w	a1,a0
    80003ace:	8526                	mv	a0,s1
    80003ad0:	fffff097          	auipc	ra,0xfffff
    80003ad4:	3aa080e7          	jalr	938(ra) # 80002e7a <bread>
    80003ad8:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ada:	3ff97513          	andi	a0,s2,1023
    80003ade:	40ad07bb          	subw	a5,s10,a0
    80003ae2:	414b873b          	subw	a4,s7,s4
    80003ae6:	89be                	mv	s3,a5
    80003ae8:	2781                	sext.w	a5,a5
    80003aea:	0007069b          	sext.w	a3,a4
    80003aee:	f8f6f4e3          	bgeu	a3,a5,80003a76 <writei+0x4c>
    80003af2:	89ba                	mv	s3,a4
    80003af4:	b749                	j	80003a76 <writei+0x4c>
      brelse(bp);
    80003af6:	8526                	mv	a0,s1
    80003af8:	fffff097          	auipc	ra,0xfffff
    80003afc:	4b2080e7          	jalr	1202(ra) # 80002faa <brelse>
  }

  if(off > ip->size)
    80003b00:	04cb2783          	lw	a5,76(s6)
    80003b04:	0127f463          	bgeu	a5,s2,80003b0c <writei+0xe2>
    ip->size = off;
    80003b08:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003b0c:	855a                	mv	a0,s6
    80003b0e:	00000097          	auipc	ra,0x0
    80003b12:	aa6080e7          	jalr	-1370(ra) # 800035b4 <iupdate>

  return tot;
    80003b16:	000a051b          	sext.w	a0,s4
}
    80003b1a:	70a6                	ld	ra,104(sp)
    80003b1c:	7406                	ld	s0,96(sp)
    80003b1e:	64e6                	ld	s1,88(sp)
    80003b20:	6946                	ld	s2,80(sp)
    80003b22:	69a6                	ld	s3,72(sp)
    80003b24:	6a06                	ld	s4,64(sp)
    80003b26:	7ae2                	ld	s5,56(sp)
    80003b28:	7b42                	ld	s6,48(sp)
    80003b2a:	7ba2                	ld	s7,40(sp)
    80003b2c:	7c02                	ld	s8,32(sp)
    80003b2e:	6ce2                	ld	s9,24(sp)
    80003b30:	6d42                	ld	s10,16(sp)
    80003b32:	6da2                	ld	s11,8(sp)
    80003b34:	6165                	addi	sp,sp,112
    80003b36:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b38:	8a5e                	mv	s4,s7
    80003b3a:	bfc9                	j	80003b0c <writei+0xe2>
    return -1;
    80003b3c:	557d                	li	a0,-1
}
    80003b3e:	8082                	ret
    return -1;
    80003b40:	557d                	li	a0,-1
    80003b42:	bfe1                	j	80003b1a <writei+0xf0>
    return -1;
    80003b44:	557d                	li	a0,-1
    80003b46:	bfd1                	j	80003b1a <writei+0xf0>

0000000080003b48 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003b48:	1141                	addi	sp,sp,-16
    80003b4a:	e406                	sd	ra,8(sp)
    80003b4c:	e022                	sd	s0,0(sp)
    80003b4e:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003b50:	4639                	li	a2,14
    80003b52:	ffffd097          	auipc	ra,0xffffd
    80003b56:	244080e7          	jalr	580(ra) # 80000d96 <strncmp>
}
    80003b5a:	60a2                	ld	ra,8(sp)
    80003b5c:	6402                	ld	s0,0(sp)
    80003b5e:	0141                	addi	sp,sp,16
    80003b60:	8082                	ret

0000000080003b62 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003b62:	7139                	addi	sp,sp,-64
    80003b64:	fc06                	sd	ra,56(sp)
    80003b66:	f822                	sd	s0,48(sp)
    80003b68:	f426                	sd	s1,40(sp)
    80003b6a:	f04a                	sd	s2,32(sp)
    80003b6c:	ec4e                	sd	s3,24(sp)
    80003b6e:	e852                	sd	s4,16(sp)
    80003b70:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003b72:	04451703          	lh	a4,68(a0)
    80003b76:	4785                	li	a5,1
    80003b78:	00f71a63          	bne	a4,a5,80003b8c <dirlookup+0x2a>
    80003b7c:	892a                	mv	s2,a0
    80003b7e:	89ae                	mv	s3,a1
    80003b80:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b82:	457c                	lw	a5,76(a0)
    80003b84:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003b86:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b88:	e79d                	bnez	a5,80003bb6 <dirlookup+0x54>
    80003b8a:	a8a5                	j	80003c02 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003b8c:	00005517          	auipc	a0,0x5
    80003b90:	a4c50513          	addi	a0,a0,-1460 # 800085d8 <syscalls+0x1a0>
    80003b94:	ffffd097          	auipc	ra,0xffffd
    80003b98:	996080e7          	jalr	-1642(ra) # 8000052a <panic>
      panic("dirlookup read");
    80003b9c:	00005517          	auipc	a0,0x5
    80003ba0:	a5450513          	addi	a0,a0,-1452 # 800085f0 <syscalls+0x1b8>
    80003ba4:	ffffd097          	auipc	ra,0xffffd
    80003ba8:	986080e7          	jalr	-1658(ra) # 8000052a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003bac:	24c1                	addiw	s1,s1,16
    80003bae:	04c92783          	lw	a5,76(s2)
    80003bb2:	04f4f763          	bgeu	s1,a5,80003c00 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003bb6:	4741                	li	a4,16
    80003bb8:	86a6                	mv	a3,s1
    80003bba:	fc040613          	addi	a2,s0,-64
    80003bbe:	4581                	li	a1,0
    80003bc0:	854a                	mv	a0,s2
    80003bc2:	00000097          	auipc	ra,0x0
    80003bc6:	d70080e7          	jalr	-656(ra) # 80003932 <readi>
    80003bca:	47c1                	li	a5,16
    80003bcc:	fcf518e3          	bne	a0,a5,80003b9c <dirlookup+0x3a>
    if(de.inum == 0)
    80003bd0:	fc045783          	lhu	a5,-64(s0)
    80003bd4:	dfe1                	beqz	a5,80003bac <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003bd6:	fc240593          	addi	a1,s0,-62
    80003bda:	854e                	mv	a0,s3
    80003bdc:	00000097          	auipc	ra,0x0
    80003be0:	f6c080e7          	jalr	-148(ra) # 80003b48 <namecmp>
    80003be4:	f561                	bnez	a0,80003bac <dirlookup+0x4a>
      if(poff)
    80003be6:	000a0463          	beqz	s4,80003bee <dirlookup+0x8c>
        *poff = off;
    80003bea:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003bee:	fc045583          	lhu	a1,-64(s0)
    80003bf2:	00092503          	lw	a0,0(s2)
    80003bf6:	fffff097          	auipc	ra,0xfffff
    80003bfa:	754080e7          	jalr	1876(ra) # 8000334a <iget>
    80003bfe:	a011                	j	80003c02 <dirlookup+0xa0>
  return 0;
    80003c00:	4501                	li	a0,0
}
    80003c02:	70e2                	ld	ra,56(sp)
    80003c04:	7442                	ld	s0,48(sp)
    80003c06:	74a2                	ld	s1,40(sp)
    80003c08:	7902                	ld	s2,32(sp)
    80003c0a:	69e2                	ld	s3,24(sp)
    80003c0c:	6a42                	ld	s4,16(sp)
    80003c0e:	6121                	addi	sp,sp,64
    80003c10:	8082                	ret

0000000080003c12 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003c12:	711d                	addi	sp,sp,-96
    80003c14:	ec86                	sd	ra,88(sp)
    80003c16:	e8a2                	sd	s0,80(sp)
    80003c18:	e4a6                	sd	s1,72(sp)
    80003c1a:	e0ca                	sd	s2,64(sp)
    80003c1c:	fc4e                	sd	s3,56(sp)
    80003c1e:	f852                	sd	s4,48(sp)
    80003c20:	f456                	sd	s5,40(sp)
    80003c22:	f05a                	sd	s6,32(sp)
    80003c24:	ec5e                	sd	s7,24(sp)
    80003c26:	e862                	sd	s8,16(sp)
    80003c28:	e466                	sd	s9,8(sp)
    80003c2a:	1080                	addi	s0,sp,96
    80003c2c:	84aa                	mv	s1,a0
    80003c2e:	8aae                	mv	s5,a1
    80003c30:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003c32:	00054703          	lbu	a4,0(a0)
    80003c36:	02f00793          	li	a5,47
    80003c3a:	02f70363          	beq	a4,a5,80003c60 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003c3e:	ffffe097          	auipc	ra,0xffffe
    80003c42:	d94080e7          	jalr	-620(ra) # 800019d2 <myproc>
    80003c46:	15053503          	ld	a0,336(a0)
    80003c4a:	00000097          	auipc	ra,0x0
    80003c4e:	9f6080e7          	jalr	-1546(ra) # 80003640 <idup>
    80003c52:	89aa                	mv	s3,a0
  while(*path == '/')
    80003c54:	02f00913          	li	s2,47
  len = path - s;
    80003c58:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003c5a:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003c5c:	4b85                	li	s7,1
    80003c5e:	a865                	j	80003d16 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003c60:	4585                	li	a1,1
    80003c62:	4505                	li	a0,1
    80003c64:	fffff097          	auipc	ra,0xfffff
    80003c68:	6e6080e7          	jalr	1766(ra) # 8000334a <iget>
    80003c6c:	89aa                	mv	s3,a0
    80003c6e:	b7dd                	j	80003c54 <namex+0x42>
      iunlockput(ip);
    80003c70:	854e                	mv	a0,s3
    80003c72:	00000097          	auipc	ra,0x0
    80003c76:	c6e080e7          	jalr	-914(ra) # 800038e0 <iunlockput>
      return 0;
    80003c7a:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003c7c:	854e                	mv	a0,s3
    80003c7e:	60e6                	ld	ra,88(sp)
    80003c80:	6446                	ld	s0,80(sp)
    80003c82:	64a6                	ld	s1,72(sp)
    80003c84:	6906                	ld	s2,64(sp)
    80003c86:	79e2                	ld	s3,56(sp)
    80003c88:	7a42                	ld	s4,48(sp)
    80003c8a:	7aa2                	ld	s5,40(sp)
    80003c8c:	7b02                	ld	s6,32(sp)
    80003c8e:	6be2                	ld	s7,24(sp)
    80003c90:	6c42                	ld	s8,16(sp)
    80003c92:	6ca2                	ld	s9,8(sp)
    80003c94:	6125                	addi	sp,sp,96
    80003c96:	8082                	ret
      iunlock(ip);
    80003c98:	854e                	mv	a0,s3
    80003c9a:	00000097          	auipc	ra,0x0
    80003c9e:	aa6080e7          	jalr	-1370(ra) # 80003740 <iunlock>
      return ip;
    80003ca2:	bfe9                	j	80003c7c <namex+0x6a>
      iunlockput(ip);
    80003ca4:	854e                	mv	a0,s3
    80003ca6:	00000097          	auipc	ra,0x0
    80003caa:	c3a080e7          	jalr	-966(ra) # 800038e0 <iunlockput>
      return 0;
    80003cae:	89e6                	mv	s3,s9
    80003cb0:	b7f1                	j	80003c7c <namex+0x6a>
  len = path - s;
    80003cb2:	40b48633          	sub	a2,s1,a1
    80003cb6:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003cba:	099c5463          	bge	s8,s9,80003d42 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003cbe:	4639                	li	a2,14
    80003cc0:	8552                	mv	a0,s4
    80003cc2:	ffffd097          	auipc	ra,0xffffd
    80003cc6:	058080e7          	jalr	88(ra) # 80000d1a <memmove>
  while(*path == '/')
    80003cca:	0004c783          	lbu	a5,0(s1)
    80003cce:	01279763          	bne	a5,s2,80003cdc <namex+0xca>
    path++;
    80003cd2:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003cd4:	0004c783          	lbu	a5,0(s1)
    80003cd8:	ff278de3          	beq	a5,s2,80003cd2 <namex+0xc0>
    ilock(ip);
    80003cdc:	854e                	mv	a0,s3
    80003cde:	00000097          	auipc	ra,0x0
    80003ce2:	9a0080e7          	jalr	-1632(ra) # 8000367e <ilock>
    if(ip->type != T_DIR){
    80003ce6:	04499783          	lh	a5,68(s3)
    80003cea:	f97793e3          	bne	a5,s7,80003c70 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003cee:	000a8563          	beqz	s5,80003cf8 <namex+0xe6>
    80003cf2:	0004c783          	lbu	a5,0(s1)
    80003cf6:	d3cd                	beqz	a5,80003c98 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003cf8:	865a                	mv	a2,s6
    80003cfa:	85d2                	mv	a1,s4
    80003cfc:	854e                	mv	a0,s3
    80003cfe:	00000097          	auipc	ra,0x0
    80003d02:	e64080e7          	jalr	-412(ra) # 80003b62 <dirlookup>
    80003d06:	8caa                	mv	s9,a0
    80003d08:	dd51                	beqz	a0,80003ca4 <namex+0x92>
    iunlockput(ip);
    80003d0a:	854e                	mv	a0,s3
    80003d0c:	00000097          	auipc	ra,0x0
    80003d10:	bd4080e7          	jalr	-1068(ra) # 800038e0 <iunlockput>
    ip = next;
    80003d14:	89e6                	mv	s3,s9
  while(*path == '/')
    80003d16:	0004c783          	lbu	a5,0(s1)
    80003d1a:	05279763          	bne	a5,s2,80003d68 <namex+0x156>
    path++;
    80003d1e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d20:	0004c783          	lbu	a5,0(s1)
    80003d24:	ff278de3          	beq	a5,s2,80003d1e <namex+0x10c>
  if(*path == 0)
    80003d28:	c79d                	beqz	a5,80003d56 <namex+0x144>
    path++;
    80003d2a:	85a6                	mv	a1,s1
  len = path - s;
    80003d2c:	8cda                	mv	s9,s6
    80003d2e:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80003d30:	01278963          	beq	a5,s2,80003d42 <namex+0x130>
    80003d34:	dfbd                	beqz	a5,80003cb2 <namex+0xa0>
    path++;
    80003d36:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003d38:	0004c783          	lbu	a5,0(s1)
    80003d3c:	ff279ce3          	bne	a5,s2,80003d34 <namex+0x122>
    80003d40:	bf8d                	j	80003cb2 <namex+0xa0>
    memmove(name, s, len);
    80003d42:	2601                	sext.w	a2,a2
    80003d44:	8552                	mv	a0,s4
    80003d46:	ffffd097          	auipc	ra,0xffffd
    80003d4a:	fd4080e7          	jalr	-44(ra) # 80000d1a <memmove>
    name[len] = 0;
    80003d4e:	9cd2                	add	s9,s9,s4
    80003d50:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003d54:	bf9d                	j	80003cca <namex+0xb8>
  if(nameiparent){
    80003d56:	f20a83e3          	beqz	s5,80003c7c <namex+0x6a>
    iput(ip);
    80003d5a:	854e                	mv	a0,s3
    80003d5c:	00000097          	auipc	ra,0x0
    80003d60:	adc080e7          	jalr	-1316(ra) # 80003838 <iput>
    return 0;
    80003d64:	4981                	li	s3,0
    80003d66:	bf19                	j	80003c7c <namex+0x6a>
  if(*path == 0)
    80003d68:	d7fd                	beqz	a5,80003d56 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003d6a:	0004c783          	lbu	a5,0(s1)
    80003d6e:	85a6                	mv	a1,s1
    80003d70:	b7d1                	j	80003d34 <namex+0x122>

0000000080003d72 <dirlink>:
{
    80003d72:	7139                	addi	sp,sp,-64
    80003d74:	fc06                	sd	ra,56(sp)
    80003d76:	f822                	sd	s0,48(sp)
    80003d78:	f426                	sd	s1,40(sp)
    80003d7a:	f04a                	sd	s2,32(sp)
    80003d7c:	ec4e                	sd	s3,24(sp)
    80003d7e:	e852                	sd	s4,16(sp)
    80003d80:	0080                	addi	s0,sp,64
    80003d82:	892a                	mv	s2,a0
    80003d84:	8a2e                	mv	s4,a1
    80003d86:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003d88:	4601                	li	a2,0
    80003d8a:	00000097          	auipc	ra,0x0
    80003d8e:	dd8080e7          	jalr	-552(ra) # 80003b62 <dirlookup>
    80003d92:	e93d                	bnez	a0,80003e08 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d94:	04c92483          	lw	s1,76(s2)
    80003d98:	c49d                	beqz	s1,80003dc6 <dirlink+0x54>
    80003d9a:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d9c:	4741                	li	a4,16
    80003d9e:	86a6                	mv	a3,s1
    80003da0:	fc040613          	addi	a2,s0,-64
    80003da4:	4581                	li	a1,0
    80003da6:	854a                	mv	a0,s2
    80003da8:	00000097          	auipc	ra,0x0
    80003dac:	b8a080e7          	jalr	-1142(ra) # 80003932 <readi>
    80003db0:	47c1                	li	a5,16
    80003db2:	06f51163          	bne	a0,a5,80003e14 <dirlink+0xa2>
    if(de.inum == 0)
    80003db6:	fc045783          	lhu	a5,-64(s0)
    80003dba:	c791                	beqz	a5,80003dc6 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dbc:	24c1                	addiw	s1,s1,16
    80003dbe:	04c92783          	lw	a5,76(s2)
    80003dc2:	fcf4ede3          	bltu	s1,a5,80003d9c <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003dc6:	4639                	li	a2,14
    80003dc8:	85d2                	mv	a1,s4
    80003dca:	fc240513          	addi	a0,s0,-62
    80003dce:	ffffd097          	auipc	ra,0xffffd
    80003dd2:	004080e7          	jalr	4(ra) # 80000dd2 <strncpy>
  de.inum = inum;
    80003dd6:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003dda:	4741                	li	a4,16
    80003ddc:	86a6                	mv	a3,s1
    80003dde:	fc040613          	addi	a2,s0,-64
    80003de2:	4581                	li	a1,0
    80003de4:	854a                	mv	a0,s2
    80003de6:	00000097          	auipc	ra,0x0
    80003dea:	c44080e7          	jalr	-956(ra) # 80003a2a <writei>
    80003dee:	872a                	mv	a4,a0
    80003df0:	47c1                	li	a5,16
  return 0;
    80003df2:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003df4:	02f71863          	bne	a4,a5,80003e24 <dirlink+0xb2>
}
    80003df8:	70e2                	ld	ra,56(sp)
    80003dfa:	7442                	ld	s0,48(sp)
    80003dfc:	74a2                	ld	s1,40(sp)
    80003dfe:	7902                	ld	s2,32(sp)
    80003e00:	69e2                	ld	s3,24(sp)
    80003e02:	6a42                	ld	s4,16(sp)
    80003e04:	6121                	addi	sp,sp,64
    80003e06:	8082                	ret
    iput(ip);
    80003e08:	00000097          	auipc	ra,0x0
    80003e0c:	a30080e7          	jalr	-1488(ra) # 80003838 <iput>
    return -1;
    80003e10:	557d                	li	a0,-1
    80003e12:	b7dd                	j	80003df8 <dirlink+0x86>
      panic("dirlink read");
    80003e14:	00004517          	auipc	a0,0x4
    80003e18:	7ec50513          	addi	a0,a0,2028 # 80008600 <syscalls+0x1c8>
    80003e1c:	ffffc097          	auipc	ra,0xffffc
    80003e20:	70e080e7          	jalr	1806(ra) # 8000052a <panic>
    panic("dirlink");
    80003e24:	00005517          	auipc	a0,0x5
    80003e28:	8ec50513          	addi	a0,a0,-1812 # 80008710 <syscalls+0x2d8>
    80003e2c:	ffffc097          	auipc	ra,0xffffc
    80003e30:	6fe080e7          	jalr	1790(ra) # 8000052a <panic>

0000000080003e34 <namei>:

struct inode*
namei(char *path)
{
    80003e34:	1101                	addi	sp,sp,-32
    80003e36:	ec06                	sd	ra,24(sp)
    80003e38:	e822                	sd	s0,16(sp)
    80003e3a:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003e3c:	fe040613          	addi	a2,s0,-32
    80003e40:	4581                	li	a1,0
    80003e42:	00000097          	auipc	ra,0x0
    80003e46:	dd0080e7          	jalr	-560(ra) # 80003c12 <namex>
}
    80003e4a:	60e2                	ld	ra,24(sp)
    80003e4c:	6442                	ld	s0,16(sp)
    80003e4e:	6105                	addi	sp,sp,32
    80003e50:	8082                	ret

0000000080003e52 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003e52:	1141                	addi	sp,sp,-16
    80003e54:	e406                	sd	ra,8(sp)
    80003e56:	e022                	sd	s0,0(sp)
    80003e58:	0800                	addi	s0,sp,16
    80003e5a:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003e5c:	4585                	li	a1,1
    80003e5e:	00000097          	auipc	ra,0x0
    80003e62:	db4080e7          	jalr	-588(ra) # 80003c12 <namex>
}
    80003e66:	60a2                	ld	ra,8(sp)
    80003e68:	6402                	ld	s0,0(sp)
    80003e6a:	0141                	addi	sp,sp,16
    80003e6c:	8082                	ret

0000000080003e6e <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003e6e:	1101                	addi	sp,sp,-32
    80003e70:	ec06                	sd	ra,24(sp)
    80003e72:	e822                	sd	s0,16(sp)
    80003e74:	e426                	sd	s1,8(sp)
    80003e76:	e04a                	sd	s2,0(sp)
    80003e78:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003e7a:	0001d917          	auipc	s2,0x1d
    80003e7e:	3f690913          	addi	s2,s2,1014 # 80021270 <log>
    80003e82:	01892583          	lw	a1,24(s2)
    80003e86:	02892503          	lw	a0,40(s2)
    80003e8a:	fffff097          	auipc	ra,0xfffff
    80003e8e:	ff0080e7          	jalr	-16(ra) # 80002e7a <bread>
    80003e92:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003e94:	02c92683          	lw	a3,44(s2)
    80003e98:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003e9a:	02d05863          	blez	a3,80003eca <write_head+0x5c>
    80003e9e:	0001d797          	auipc	a5,0x1d
    80003ea2:	40278793          	addi	a5,a5,1026 # 800212a0 <log+0x30>
    80003ea6:	05c50713          	addi	a4,a0,92
    80003eaa:	36fd                	addiw	a3,a3,-1
    80003eac:	02069613          	slli	a2,a3,0x20
    80003eb0:	01e65693          	srli	a3,a2,0x1e
    80003eb4:	0001d617          	auipc	a2,0x1d
    80003eb8:	3f060613          	addi	a2,a2,1008 # 800212a4 <log+0x34>
    80003ebc:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003ebe:	4390                	lw	a2,0(a5)
    80003ec0:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003ec2:	0791                	addi	a5,a5,4
    80003ec4:	0711                	addi	a4,a4,4
    80003ec6:	fed79ce3          	bne	a5,a3,80003ebe <write_head+0x50>
  }
  bwrite(buf);
    80003eca:	8526                	mv	a0,s1
    80003ecc:	fffff097          	auipc	ra,0xfffff
    80003ed0:	0a0080e7          	jalr	160(ra) # 80002f6c <bwrite>
  brelse(buf);
    80003ed4:	8526                	mv	a0,s1
    80003ed6:	fffff097          	auipc	ra,0xfffff
    80003eda:	0d4080e7          	jalr	212(ra) # 80002faa <brelse>
}
    80003ede:	60e2                	ld	ra,24(sp)
    80003ee0:	6442                	ld	s0,16(sp)
    80003ee2:	64a2                	ld	s1,8(sp)
    80003ee4:	6902                	ld	s2,0(sp)
    80003ee6:	6105                	addi	sp,sp,32
    80003ee8:	8082                	ret

0000000080003eea <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003eea:	0001d797          	auipc	a5,0x1d
    80003eee:	3b27a783          	lw	a5,946(a5) # 8002129c <log+0x2c>
    80003ef2:	0af05d63          	blez	a5,80003fac <install_trans+0xc2>
{
    80003ef6:	7139                	addi	sp,sp,-64
    80003ef8:	fc06                	sd	ra,56(sp)
    80003efa:	f822                	sd	s0,48(sp)
    80003efc:	f426                	sd	s1,40(sp)
    80003efe:	f04a                	sd	s2,32(sp)
    80003f00:	ec4e                	sd	s3,24(sp)
    80003f02:	e852                	sd	s4,16(sp)
    80003f04:	e456                	sd	s5,8(sp)
    80003f06:	e05a                	sd	s6,0(sp)
    80003f08:	0080                	addi	s0,sp,64
    80003f0a:	8b2a                	mv	s6,a0
    80003f0c:	0001da97          	auipc	s5,0x1d
    80003f10:	394a8a93          	addi	s5,s5,916 # 800212a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f14:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003f16:	0001d997          	auipc	s3,0x1d
    80003f1a:	35a98993          	addi	s3,s3,858 # 80021270 <log>
    80003f1e:	a00d                	j	80003f40 <install_trans+0x56>
    brelse(lbuf);
    80003f20:	854a                	mv	a0,s2
    80003f22:	fffff097          	auipc	ra,0xfffff
    80003f26:	088080e7          	jalr	136(ra) # 80002faa <brelse>
    brelse(dbuf);
    80003f2a:	8526                	mv	a0,s1
    80003f2c:	fffff097          	auipc	ra,0xfffff
    80003f30:	07e080e7          	jalr	126(ra) # 80002faa <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f34:	2a05                	addiw	s4,s4,1
    80003f36:	0a91                	addi	s5,s5,4
    80003f38:	02c9a783          	lw	a5,44(s3)
    80003f3c:	04fa5e63          	bge	s4,a5,80003f98 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003f40:	0189a583          	lw	a1,24(s3)
    80003f44:	014585bb          	addw	a1,a1,s4
    80003f48:	2585                	addiw	a1,a1,1
    80003f4a:	0289a503          	lw	a0,40(s3)
    80003f4e:	fffff097          	auipc	ra,0xfffff
    80003f52:	f2c080e7          	jalr	-212(ra) # 80002e7a <bread>
    80003f56:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003f58:	000aa583          	lw	a1,0(s5)
    80003f5c:	0289a503          	lw	a0,40(s3)
    80003f60:	fffff097          	auipc	ra,0xfffff
    80003f64:	f1a080e7          	jalr	-230(ra) # 80002e7a <bread>
    80003f68:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003f6a:	40000613          	li	a2,1024
    80003f6e:	05890593          	addi	a1,s2,88
    80003f72:	05850513          	addi	a0,a0,88
    80003f76:	ffffd097          	auipc	ra,0xffffd
    80003f7a:	da4080e7          	jalr	-604(ra) # 80000d1a <memmove>
    bwrite(dbuf);  // write dst to disk
    80003f7e:	8526                	mv	a0,s1
    80003f80:	fffff097          	auipc	ra,0xfffff
    80003f84:	fec080e7          	jalr	-20(ra) # 80002f6c <bwrite>
    if(recovering == 0)
    80003f88:	f80b1ce3          	bnez	s6,80003f20 <install_trans+0x36>
      bunpin(dbuf);
    80003f8c:	8526                	mv	a0,s1
    80003f8e:	fffff097          	auipc	ra,0xfffff
    80003f92:	0f6080e7          	jalr	246(ra) # 80003084 <bunpin>
    80003f96:	b769                	j	80003f20 <install_trans+0x36>
}
    80003f98:	70e2                	ld	ra,56(sp)
    80003f9a:	7442                	ld	s0,48(sp)
    80003f9c:	74a2                	ld	s1,40(sp)
    80003f9e:	7902                	ld	s2,32(sp)
    80003fa0:	69e2                	ld	s3,24(sp)
    80003fa2:	6a42                	ld	s4,16(sp)
    80003fa4:	6aa2                	ld	s5,8(sp)
    80003fa6:	6b02                	ld	s6,0(sp)
    80003fa8:	6121                	addi	sp,sp,64
    80003faa:	8082                	ret
    80003fac:	8082                	ret

0000000080003fae <initlog>:
{
    80003fae:	7179                	addi	sp,sp,-48
    80003fb0:	f406                	sd	ra,40(sp)
    80003fb2:	f022                	sd	s0,32(sp)
    80003fb4:	ec26                	sd	s1,24(sp)
    80003fb6:	e84a                	sd	s2,16(sp)
    80003fb8:	e44e                	sd	s3,8(sp)
    80003fba:	1800                	addi	s0,sp,48
    80003fbc:	892a                	mv	s2,a0
    80003fbe:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80003fc0:	0001d497          	auipc	s1,0x1d
    80003fc4:	2b048493          	addi	s1,s1,688 # 80021270 <log>
    80003fc8:	00004597          	auipc	a1,0x4
    80003fcc:	64858593          	addi	a1,a1,1608 # 80008610 <syscalls+0x1d8>
    80003fd0:	8526                	mv	a0,s1
    80003fd2:	ffffd097          	auipc	ra,0xffffd
    80003fd6:	b60080e7          	jalr	-1184(ra) # 80000b32 <initlock>
  log.start = sb->logstart;
    80003fda:	0149a583          	lw	a1,20(s3)
    80003fde:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80003fe0:	0109a783          	lw	a5,16(s3)
    80003fe4:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80003fe6:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80003fea:	854a                	mv	a0,s2
    80003fec:	fffff097          	auipc	ra,0xfffff
    80003ff0:	e8e080e7          	jalr	-370(ra) # 80002e7a <bread>
  log.lh.n = lh->n;
    80003ff4:	4d34                	lw	a3,88(a0)
    80003ff6:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80003ff8:	02d05663          	blez	a3,80004024 <initlog+0x76>
    80003ffc:	05c50793          	addi	a5,a0,92
    80004000:	0001d717          	auipc	a4,0x1d
    80004004:	2a070713          	addi	a4,a4,672 # 800212a0 <log+0x30>
    80004008:	36fd                	addiw	a3,a3,-1
    8000400a:	02069613          	slli	a2,a3,0x20
    8000400e:	01e65693          	srli	a3,a2,0x1e
    80004012:	06050613          	addi	a2,a0,96
    80004016:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004018:	4390                	lw	a2,0(a5)
    8000401a:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000401c:	0791                	addi	a5,a5,4
    8000401e:	0711                	addi	a4,a4,4
    80004020:	fed79ce3          	bne	a5,a3,80004018 <initlog+0x6a>
  brelse(buf);
    80004024:	fffff097          	auipc	ra,0xfffff
    80004028:	f86080e7          	jalr	-122(ra) # 80002faa <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000402c:	4505                	li	a0,1
    8000402e:	00000097          	auipc	ra,0x0
    80004032:	ebc080e7          	jalr	-324(ra) # 80003eea <install_trans>
  log.lh.n = 0;
    80004036:	0001d797          	auipc	a5,0x1d
    8000403a:	2607a323          	sw	zero,614(a5) # 8002129c <log+0x2c>
  write_head(); // clear the log
    8000403e:	00000097          	auipc	ra,0x0
    80004042:	e30080e7          	jalr	-464(ra) # 80003e6e <write_head>
}
    80004046:	70a2                	ld	ra,40(sp)
    80004048:	7402                	ld	s0,32(sp)
    8000404a:	64e2                	ld	s1,24(sp)
    8000404c:	6942                	ld	s2,16(sp)
    8000404e:	69a2                	ld	s3,8(sp)
    80004050:	6145                	addi	sp,sp,48
    80004052:	8082                	ret

0000000080004054 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004054:	1101                	addi	sp,sp,-32
    80004056:	ec06                	sd	ra,24(sp)
    80004058:	e822                	sd	s0,16(sp)
    8000405a:	e426                	sd	s1,8(sp)
    8000405c:	e04a                	sd	s2,0(sp)
    8000405e:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004060:	0001d517          	auipc	a0,0x1d
    80004064:	21050513          	addi	a0,a0,528 # 80021270 <log>
    80004068:	ffffd097          	auipc	ra,0xffffd
    8000406c:	b5a080e7          	jalr	-1190(ra) # 80000bc2 <acquire>
  while(1){
    if(log.committing){
    80004070:	0001d497          	auipc	s1,0x1d
    80004074:	20048493          	addi	s1,s1,512 # 80021270 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004078:	4979                	li	s2,30
    8000407a:	a039                	j	80004088 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000407c:	85a6                	mv	a1,s1
    8000407e:	8526                	mv	a0,s1
    80004080:	ffffe097          	auipc	ra,0xffffe
    80004084:	012080e7          	jalr	18(ra) # 80002092 <sleep>
    if(log.committing){
    80004088:	50dc                	lw	a5,36(s1)
    8000408a:	fbed                	bnez	a5,8000407c <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000408c:	509c                	lw	a5,32(s1)
    8000408e:	0017871b          	addiw	a4,a5,1
    80004092:	0007069b          	sext.w	a3,a4
    80004096:	0027179b          	slliw	a5,a4,0x2
    8000409a:	9fb9                	addw	a5,a5,a4
    8000409c:	0017979b          	slliw	a5,a5,0x1
    800040a0:	54d8                	lw	a4,44(s1)
    800040a2:	9fb9                	addw	a5,a5,a4
    800040a4:	00f95963          	bge	s2,a5,800040b6 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800040a8:	85a6                	mv	a1,s1
    800040aa:	8526                	mv	a0,s1
    800040ac:	ffffe097          	auipc	ra,0xffffe
    800040b0:	fe6080e7          	jalr	-26(ra) # 80002092 <sleep>
    800040b4:	bfd1                	j	80004088 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800040b6:	0001d517          	auipc	a0,0x1d
    800040ba:	1ba50513          	addi	a0,a0,442 # 80021270 <log>
    800040be:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800040c0:	ffffd097          	auipc	ra,0xffffd
    800040c4:	bb6080e7          	jalr	-1098(ra) # 80000c76 <release>
      break;
    }
  }
}
    800040c8:	60e2                	ld	ra,24(sp)
    800040ca:	6442                	ld	s0,16(sp)
    800040cc:	64a2                	ld	s1,8(sp)
    800040ce:	6902                	ld	s2,0(sp)
    800040d0:	6105                	addi	sp,sp,32
    800040d2:	8082                	ret

00000000800040d4 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800040d4:	7139                	addi	sp,sp,-64
    800040d6:	fc06                	sd	ra,56(sp)
    800040d8:	f822                	sd	s0,48(sp)
    800040da:	f426                	sd	s1,40(sp)
    800040dc:	f04a                	sd	s2,32(sp)
    800040de:	ec4e                	sd	s3,24(sp)
    800040e0:	e852                	sd	s4,16(sp)
    800040e2:	e456                	sd	s5,8(sp)
    800040e4:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800040e6:	0001d497          	auipc	s1,0x1d
    800040ea:	18a48493          	addi	s1,s1,394 # 80021270 <log>
    800040ee:	8526                	mv	a0,s1
    800040f0:	ffffd097          	auipc	ra,0xffffd
    800040f4:	ad2080e7          	jalr	-1326(ra) # 80000bc2 <acquire>
  log.outstanding -= 1;
    800040f8:	509c                	lw	a5,32(s1)
    800040fa:	37fd                	addiw	a5,a5,-1
    800040fc:	0007891b          	sext.w	s2,a5
    80004100:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004102:	50dc                	lw	a5,36(s1)
    80004104:	e7b9                	bnez	a5,80004152 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004106:	04091e63          	bnez	s2,80004162 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    8000410a:	0001d497          	auipc	s1,0x1d
    8000410e:	16648493          	addi	s1,s1,358 # 80021270 <log>
    80004112:	4785                	li	a5,1
    80004114:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004116:	8526                	mv	a0,s1
    80004118:	ffffd097          	auipc	ra,0xffffd
    8000411c:	b5e080e7          	jalr	-1186(ra) # 80000c76 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004120:	54dc                	lw	a5,44(s1)
    80004122:	06f04763          	bgtz	a5,80004190 <end_op+0xbc>
    acquire(&log.lock);
    80004126:	0001d497          	auipc	s1,0x1d
    8000412a:	14a48493          	addi	s1,s1,330 # 80021270 <log>
    8000412e:	8526                	mv	a0,s1
    80004130:	ffffd097          	auipc	ra,0xffffd
    80004134:	a92080e7          	jalr	-1390(ra) # 80000bc2 <acquire>
    log.committing = 0;
    80004138:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000413c:	8526                	mv	a0,s1
    8000413e:	ffffe097          	auipc	ra,0xffffe
    80004142:	0e0080e7          	jalr	224(ra) # 8000221e <wakeup>
    release(&log.lock);
    80004146:	8526                	mv	a0,s1
    80004148:	ffffd097          	auipc	ra,0xffffd
    8000414c:	b2e080e7          	jalr	-1234(ra) # 80000c76 <release>
}
    80004150:	a03d                	j	8000417e <end_op+0xaa>
    panic("log.committing");
    80004152:	00004517          	auipc	a0,0x4
    80004156:	4c650513          	addi	a0,a0,1222 # 80008618 <syscalls+0x1e0>
    8000415a:	ffffc097          	auipc	ra,0xffffc
    8000415e:	3d0080e7          	jalr	976(ra) # 8000052a <panic>
    wakeup(&log);
    80004162:	0001d497          	auipc	s1,0x1d
    80004166:	10e48493          	addi	s1,s1,270 # 80021270 <log>
    8000416a:	8526                	mv	a0,s1
    8000416c:	ffffe097          	auipc	ra,0xffffe
    80004170:	0b2080e7          	jalr	178(ra) # 8000221e <wakeup>
  release(&log.lock);
    80004174:	8526                	mv	a0,s1
    80004176:	ffffd097          	auipc	ra,0xffffd
    8000417a:	b00080e7          	jalr	-1280(ra) # 80000c76 <release>
}
    8000417e:	70e2                	ld	ra,56(sp)
    80004180:	7442                	ld	s0,48(sp)
    80004182:	74a2                	ld	s1,40(sp)
    80004184:	7902                	ld	s2,32(sp)
    80004186:	69e2                	ld	s3,24(sp)
    80004188:	6a42                	ld	s4,16(sp)
    8000418a:	6aa2                	ld	s5,8(sp)
    8000418c:	6121                	addi	sp,sp,64
    8000418e:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004190:	0001da97          	auipc	s5,0x1d
    80004194:	110a8a93          	addi	s5,s5,272 # 800212a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004198:	0001da17          	auipc	s4,0x1d
    8000419c:	0d8a0a13          	addi	s4,s4,216 # 80021270 <log>
    800041a0:	018a2583          	lw	a1,24(s4)
    800041a4:	012585bb          	addw	a1,a1,s2
    800041a8:	2585                	addiw	a1,a1,1
    800041aa:	028a2503          	lw	a0,40(s4)
    800041ae:	fffff097          	auipc	ra,0xfffff
    800041b2:	ccc080e7          	jalr	-820(ra) # 80002e7a <bread>
    800041b6:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800041b8:	000aa583          	lw	a1,0(s5)
    800041bc:	028a2503          	lw	a0,40(s4)
    800041c0:	fffff097          	auipc	ra,0xfffff
    800041c4:	cba080e7          	jalr	-838(ra) # 80002e7a <bread>
    800041c8:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800041ca:	40000613          	li	a2,1024
    800041ce:	05850593          	addi	a1,a0,88
    800041d2:	05848513          	addi	a0,s1,88
    800041d6:	ffffd097          	auipc	ra,0xffffd
    800041da:	b44080e7          	jalr	-1212(ra) # 80000d1a <memmove>
    bwrite(to);  // write the log
    800041de:	8526                	mv	a0,s1
    800041e0:	fffff097          	auipc	ra,0xfffff
    800041e4:	d8c080e7          	jalr	-628(ra) # 80002f6c <bwrite>
    brelse(from);
    800041e8:	854e                	mv	a0,s3
    800041ea:	fffff097          	auipc	ra,0xfffff
    800041ee:	dc0080e7          	jalr	-576(ra) # 80002faa <brelse>
    brelse(to);
    800041f2:	8526                	mv	a0,s1
    800041f4:	fffff097          	auipc	ra,0xfffff
    800041f8:	db6080e7          	jalr	-586(ra) # 80002faa <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041fc:	2905                	addiw	s2,s2,1
    800041fe:	0a91                	addi	s5,s5,4
    80004200:	02ca2783          	lw	a5,44(s4)
    80004204:	f8f94ee3          	blt	s2,a5,800041a0 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004208:	00000097          	auipc	ra,0x0
    8000420c:	c66080e7          	jalr	-922(ra) # 80003e6e <write_head>
    install_trans(0); // Now install writes to home locations
    80004210:	4501                	li	a0,0
    80004212:	00000097          	auipc	ra,0x0
    80004216:	cd8080e7          	jalr	-808(ra) # 80003eea <install_trans>
    log.lh.n = 0;
    8000421a:	0001d797          	auipc	a5,0x1d
    8000421e:	0807a123          	sw	zero,130(a5) # 8002129c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004222:	00000097          	auipc	ra,0x0
    80004226:	c4c080e7          	jalr	-948(ra) # 80003e6e <write_head>
    8000422a:	bdf5                	j	80004126 <end_op+0x52>

000000008000422c <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000422c:	1101                	addi	sp,sp,-32
    8000422e:	ec06                	sd	ra,24(sp)
    80004230:	e822                	sd	s0,16(sp)
    80004232:	e426                	sd	s1,8(sp)
    80004234:	e04a                	sd	s2,0(sp)
    80004236:	1000                	addi	s0,sp,32
    80004238:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000423a:	0001d917          	auipc	s2,0x1d
    8000423e:	03690913          	addi	s2,s2,54 # 80021270 <log>
    80004242:	854a                	mv	a0,s2
    80004244:	ffffd097          	auipc	ra,0xffffd
    80004248:	97e080e7          	jalr	-1666(ra) # 80000bc2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000424c:	02c92603          	lw	a2,44(s2)
    80004250:	47f5                	li	a5,29
    80004252:	06c7c563          	blt	a5,a2,800042bc <log_write+0x90>
    80004256:	0001d797          	auipc	a5,0x1d
    8000425a:	0367a783          	lw	a5,54(a5) # 8002128c <log+0x1c>
    8000425e:	37fd                	addiw	a5,a5,-1
    80004260:	04f65e63          	bge	a2,a5,800042bc <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004264:	0001d797          	auipc	a5,0x1d
    80004268:	02c7a783          	lw	a5,44(a5) # 80021290 <log+0x20>
    8000426c:	06f05063          	blez	a5,800042cc <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004270:	4781                	li	a5,0
    80004272:	06c05563          	blez	a2,800042dc <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004276:	44cc                	lw	a1,12(s1)
    80004278:	0001d717          	auipc	a4,0x1d
    8000427c:	02870713          	addi	a4,a4,40 # 800212a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004280:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004282:	4314                	lw	a3,0(a4)
    80004284:	04b68c63          	beq	a3,a1,800042dc <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004288:	2785                	addiw	a5,a5,1
    8000428a:	0711                	addi	a4,a4,4
    8000428c:	fef61be3          	bne	a2,a5,80004282 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004290:	0621                	addi	a2,a2,8
    80004292:	060a                	slli	a2,a2,0x2
    80004294:	0001d797          	auipc	a5,0x1d
    80004298:	fdc78793          	addi	a5,a5,-36 # 80021270 <log>
    8000429c:	963e                	add	a2,a2,a5
    8000429e:	44dc                	lw	a5,12(s1)
    800042a0:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800042a2:	8526                	mv	a0,s1
    800042a4:	fffff097          	auipc	ra,0xfffff
    800042a8:	da4080e7          	jalr	-604(ra) # 80003048 <bpin>
    log.lh.n++;
    800042ac:	0001d717          	auipc	a4,0x1d
    800042b0:	fc470713          	addi	a4,a4,-60 # 80021270 <log>
    800042b4:	575c                	lw	a5,44(a4)
    800042b6:	2785                	addiw	a5,a5,1
    800042b8:	d75c                	sw	a5,44(a4)
    800042ba:	a835                	j	800042f6 <log_write+0xca>
    panic("too big a transaction");
    800042bc:	00004517          	auipc	a0,0x4
    800042c0:	36c50513          	addi	a0,a0,876 # 80008628 <syscalls+0x1f0>
    800042c4:	ffffc097          	auipc	ra,0xffffc
    800042c8:	266080e7          	jalr	614(ra) # 8000052a <panic>
    panic("log_write outside of trans");
    800042cc:	00004517          	auipc	a0,0x4
    800042d0:	37450513          	addi	a0,a0,884 # 80008640 <syscalls+0x208>
    800042d4:	ffffc097          	auipc	ra,0xffffc
    800042d8:	256080e7          	jalr	598(ra) # 8000052a <panic>
  log.lh.block[i] = b->blockno;
    800042dc:	00878713          	addi	a4,a5,8
    800042e0:	00271693          	slli	a3,a4,0x2
    800042e4:	0001d717          	auipc	a4,0x1d
    800042e8:	f8c70713          	addi	a4,a4,-116 # 80021270 <log>
    800042ec:	9736                	add	a4,a4,a3
    800042ee:	44d4                	lw	a3,12(s1)
    800042f0:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800042f2:	faf608e3          	beq	a2,a5,800042a2 <log_write+0x76>
  }
  release(&log.lock);
    800042f6:	0001d517          	auipc	a0,0x1d
    800042fa:	f7a50513          	addi	a0,a0,-134 # 80021270 <log>
    800042fe:	ffffd097          	auipc	ra,0xffffd
    80004302:	978080e7          	jalr	-1672(ra) # 80000c76 <release>
}
    80004306:	60e2                	ld	ra,24(sp)
    80004308:	6442                	ld	s0,16(sp)
    8000430a:	64a2                	ld	s1,8(sp)
    8000430c:	6902                	ld	s2,0(sp)
    8000430e:	6105                	addi	sp,sp,32
    80004310:	8082                	ret

0000000080004312 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004312:	1101                	addi	sp,sp,-32
    80004314:	ec06                	sd	ra,24(sp)
    80004316:	e822                	sd	s0,16(sp)
    80004318:	e426                	sd	s1,8(sp)
    8000431a:	e04a                	sd	s2,0(sp)
    8000431c:	1000                	addi	s0,sp,32
    8000431e:	84aa                	mv	s1,a0
    80004320:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004322:	00004597          	auipc	a1,0x4
    80004326:	33e58593          	addi	a1,a1,830 # 80008660 <syscalls+0x228>
    8000432a:	0521                	addi	a0,a0,8
    8000432c:	ffffd097          	auipc	ra,0xffffd
    80004330:	806080e7          	jalr	-2042(ra) # 80000b32 <initlock>
  lk->name = name;
    80004334:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004338:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000433c:	0204a423          	sw	zero,40(s1)
}
    80004340:	60e2                	ld	ra,24(sp)
    80004342:	6442                	ld	s0,16(sp)
    80004344:	64a2                	ld	s1,8(sp)
    80004346:	6902                	ld	s2,0(sp)
    80004348:	6105                	addi	sp,sp,32
    8000434a:	8082                	ret

000000008000434c <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000434c:	1101                	addi	sp,sp,-32
    8000434e:	ec06                	sd	ra,24(sp)
    80004350:	e822                	sd	s0,16(sp)
    80004352:	e426                	sd	s1,8(sp)
    80004354:	e04a                	sd	s2,0(sp)
    80004356:	1000                	addi	s0,sp,32
    80004358:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000435a:	00850913          	addi	s2,a0,8
    8000435e:	854a                	mv	a0,s2
    80004360:	ffffd097          	auipc	ra,0xffffd
    80004364:	862080e7          	jalr	-1950(ra) # 80000bc2 <acquire>
  while (lk->locked) {
    80004368:	409c                	lw	a5,0(s1)
    8000436a:	cb89                	beqz	a5,8000437c <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000436c:	85ca                	mv	a1,s2
    8000436e:	8526                	mv	a0,s1
    80004370:	ffffe097          	auipc	ra,0xffffe
    80004374:	d22080e7          	jalr	-734(ra) # 80002092 <sleep>
  while (lk->locked) {
    80004378:	409c                	lw	a5,0(s1)
    8000437a:	fbed                	bnez	a5,8000436c <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000437c:	4785                	li	a5,1
    8000437e:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004380:	ffffd097          	auipc	ra,0xffffd
    80004384:	652080e7          	jalr	1618(ra) # 800019d2 <myproc>
    80004388:	591c                	lw	a5,48(a0)
    8000438a:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000438c:	854a                	mv	a0,s2
    8000438e:	ffffd097          	auipc	ra,0xffffd
    80004392:	8e8080e7          	jalr	-1816(ra) # 80000c76 <release>
}
    80004396:	60e2                	ld	ra,24(sp)
    80004398:	6442                	ld	s0,16(sp)
    8000439a:	64a2                	ld	s1,8(sp)
    8000439c:	6902                	ld	s2,0(sp)
    8000439e:	6105                	addi	sp,sp,32
    800043a0:	8082                	ret

00000000800043a2 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800043a2:	1101                	addi	sp,sp,-32
    800043a4:	ec06                	sd	ra,24(sp)
    800043a6:	e822                	sd	s0,16(sp)
    800043a8:	e426                	sd	s1,8(sp)
    800043aa:	e04a                	sd	s2,0(sp)
    800043ac:	1000                	addi	s0,sp,32
    800043ae:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800043b0:	00850913          	addi	s2,a0,8
    800043b4:	854a                	mv	a0,s2
    800043b6:	ffffd097          	auipc	ra,0xffffd
    800043ba:	80c080e7          	jalr	-2036(ra) # 80000bc2 <acquire>
  lk->locked = 0;
    800043be:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800043c2:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800043c6:	8526                	mv	a0,s1
    800043c8:	ffffe097          	auipc	ra,0xffffe
    800043cc:	e56080e7          	jalr	-426(ra) # 8000221e <wakeup>
  release(&lk->lk);
    800043d0:	854a                	mv	a0,s2
    800043d2:	ffffd097          	auipc	ra,0xffffd
    800043d6:	8a4080e7          	jalr	-1884(ra) # 80000c76 <release>
}
    800043da:	60e2                	ld	ra,24(sp)
    800043dc:	6442                	ld	s0,16(sp)
    800043de:	64a2                	ld	s1,8(sp)
    800043e0:	6902                	ld	s2,0(sp)
    800043e2:	6105                	addi	sp,sp,32
    800043e4:	8082                	ret

00000000800043e6 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800043e6:	7179                	addi	sp,sp,-48
    800043e8:	f406                	sd	ra,40(sp)
    800043ea:	f022                	sd	s0,32(sp)
    800043ec:	ec26                	sd	s1,24(sp)
    800043ee:	e84a                	sd	s2,16(sp)
    800043f0:	e44e                	sd	s3,8(sp)
    800043f2:	1800                	addi	s0,sp,48
    800043f4:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800043f6:	00850913          	addi	s2,a0,8
    800043fa:	854a                	mv	a0,s2
    800043fc:	ffffc097          	auipc	ra,0xffffc
    80004400:	7c6080e7          	jalr	1990(ra) # 80000bc2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004404:	409c                	lw	a5,0(s1)
    80004406:	ef99                	bnez	a5,80004424 <holdingsleep+0x3e>
    80004408:	4481                	li	s1,0
  release(&lk->lk);
    8000440a:	854a                	mv	a0,s2
    8000440c:	ffffd097          	auipc	ra,0xffffd
    80004410:	86a080e7          	jalr	-1942(ra) # 80000c76 <release>
  return r;
}
    80004414:	8526                	mv	a0,s1
    80004416:	70a2                	ld	ra,40(sp)
    80004418:	7402                	ld	s0,32(sp)
    8000441a:	64e2                	ld	s1,24(sp)
    8000441c:	6942                	ld	s2,16(sp)
    8000441e:	69a2                	ld	s3,8(sp)
    80004420:	6145                	addi	sp,sp,48
    80004422:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004424:	0284a983          	lw	s3,40(s1)
    80004428:	ffffd097          	auipc	ra,0xffffd
    8000442c:	5aa080e7          	jalr	1450(ra) # 800019d2 <myproc>
    80004430:	5904                	lw	s1,48(a0)
    80004432:	413484b3          	sub	s1,s1,s3
    80004436:	0014b493          	seqz	s1,s1
    8000443a:	bfc1                	j	8000440a <holdingsleep+0x24>

000000008000443c <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000443c:	1141                	addi	sp,sp,-16
    8000443e:	e406                	sd	ra,8(sp)
    80004440:	e022                	sd	s0,0(sp)
    80004442:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004444:	00004597          	auipc	a1,0x4
    80004448:	22c58593          	addi	a1,a1,556 # 80008670 <syscalls+0x238>
    8000444c:	0001d517          	auipc	a0,0x1d
    80004450:	f6c50513          	addi	a0,a0,-148 # 800213b8 <ftable>
    80004454:	ffffc097          	auipc	ra,0xffffc
    80004458:	6de080e7          	jalr	1758(ra) # 80000b32 <initlock>
}
    8000445c:	60a2                	ld	ra,8(sp)
    8000445e:	6402                	ld	s0,0(sp)
    80004460:	0141                	addi	sp,sp,16
    80004462:	8082                	ret

0000000080004464 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004464:	1101                	addi	sp,sp,-32
    80004466:	ec06                	sd	ra,24(sp)
    80004468:	e822                	sd	s0,16(sp)
    8000446a:	e426                	sd	s1,8(sp)
    8000446c:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000446e:	0001d517          	auipc	a0,0x1d
    80004472:	f4a50513          	addi	a0,a0,-182 # 800213b8 <ftable>
    80004476:	ffffc097          	auipc	ra,0xffffc
    8000447a:	74c080e7          	jalr	1868(ra) # 80000bc2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000447e:	0001d497          	auipc	s1,0x1d
    80004482:	f5248493          	addi	s1,s1,-174 # 800213d0 <ftable+0x18>
    80004486:	0001e717          	auipc	a4,0x1e
    8000448a:	eea70713          	addi	a4,a4,-278 # 80022370 <ftable+0xfb8>
    if(f->ref == 0){
    8000448e:	40dc                	lw	a5,4(s1)
    80004490:	cf99                	beqz	a5,800044ae <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004492:	02848493          	addi	s1,s1,40
    80004496:	fee49ce3          	bne	s1,a4,8000448e <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000449a:	0001d517          	auipc	a0,0x1d
    8000449e:	f1e50513          	addi	a0,a0,-226 # 800213b8 <ftable>
    800044a2:	ffffc097          	auipc	ra,0xffffc
    800044a6:	7d4080e7          	jalr	2004(ra) # 80000c76 <release>
  return 0;
    800044aa:	4481                	li	s1,0
    800044ac:	a819                	j	800044c2 <filealloc+0x5e>
      f->ref = 1;
    800044ae:	4785                	li	a5,1
    800044b0:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800044b2:	0001d517          	auipc	a0,0x1d
    800044b6:	f0650513          	addi	a0,a0,-250 # 800213b8 <ftable>
    800044ba:	ffffc097          	auipc	ra,0xffffc
    800044be:	7bc080e7          	jalr	1980(ra) # 80000c76 <release>
}
    800044c2:	8526                	mv	a0,s1
    800044c4:	60e2                	ld	ra,24(sp)
    800044c6:	6442                	ld	s0,16(sp)
    800044c8:	64a2                	ld	s1,8(sp)
    800044ca:	6105                	addi	sp,sp,32
    800044cc:	8082                	ret

00000000800044ce <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800044ce:	1101                	addi	sp,sp,-32
    800044d0:	ec06                	sd	ra,24(sp)
    800044d2:	e822                	sd	s0,16(sp)
    800044d4:	e426                	sd	s1,8(sp)
    800044d6:	1000                	addi	s0,sp,32
    800044d8:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800044da:	0001d517          	auipc	a0,0x1d
    800044de:	ede50513          	addi	a0,a0,-290 # 800213b8 <ftable>
    800044e2:	ffffc097          	auipc	ra,0xffffc
    800044e6:	6e0080e7          	jalr	1760(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    800044ea:	40dc                	lw	a5,4(s1)
    800044ec:	02f05263          	blez	a5,80004510 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800044f0:	2785                	addiw	a5,a5,1
    800044f2:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800044f4:	0001d517          	auipc	a0,0x1d
    800044f8:	ec450513          	addi	a0,a0,-316 # 800213b8 <ftable>
    800044fc:	ffffc097          	auipc	ra,0xffffc
    80004500:	77a080e7          	jalr	1914(ra) # 80000c76 <release>
  return f;
}
    80004504:	8526                	mv	a0,s1
    80004506:	60e2                	ld	ra,24(sp)
    80004508:	6442                	ld	s0,16(sp)
    8000450a:	64a2                	ld	s1,8(sp)
    8000450c:	6105                	addi	sp,sp,32
    8000450e:	8082                	ret
    panic("filedup");
    80004510:	00004517          	auipc	a0,0x4
    80004514:	16850513          	addi	a0,a0,360 # 80008678 <syscalls+0x240>
    80004518:	ffffc097          	auipc	ra,0xffffc
    8000451c:	012080e7          	jalr	18(ra) # 8000052a <panic>

0000000080004520 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004520:	7139                	addi	sp,sp,-64
    80004522:	fc06                	sd	ra,56(sp)
    80004524:	f822                	sd	s0,48(sp)
    80004526:	f426                	sd	s1,40(sp)
    80004528:	f04a                	sd	s2,32(sp)
    8000452a:	ec4e                	sd	s3,24(sp)
    8000452c:	e852                	sd	s4,16(sp)
    8000452e:	e456                	sd	s5,8(sp)
    80004530:	0080                	addi	s0,sp,64
    80004532:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004534:	0001d517          	auipc	a0,0x1d
    80004538:	e8450513          	addi	a0,a0,-380 # 800213b8 <ftable>
    8000453c:	ffffc097          	auipc	ra,0xffffc
    80004540:	686080e7          	jalr	1670(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    80004544:	40dc                	lw	a5,4(s1)
    80004546:	06f05163          	blez	a5,800045a8 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000454a:	37fd                	addiw	a5,a5,-1
    8000454c:	0007871b          	sext.w	a4,a5
    80004550:	c0dc                	sw	a5,4(s1)
    80004552:	06e04363          	bgtz	a4,800045b8 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004556:	0004a903          	lw	s2,0(s1)
    8000455a:	0094ca83          	lbu	s5,9(s1)
    8000455e:	0104ba03          	ld	s4,16(s1)
    80004562:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004566:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000456a:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000456e:	0001d517          	auipc	a0,0x1d
    80004572:	e4a50513          	addi	a0,a0,-438 # 800213b8 <ftable>
    80004576:	ffffc097          	auipc	ra,0xffffc
    8000457a:	700080e7          	jalr	1792(ra) # 80000c76 <release>

  if(ff.type == FD_PIPE){
    8000457e:	4785                	li	a5,1
    80004580:	04f90d63          	beq	s2,a5,800045da <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004584:	3979                	addiw	s2,s2,-2
    80004586:	4785                	li	a5,1
    80004588:	0527e063          	bltu	a5,s2,800045c8 <fileclose+0xa8>
    begin_op();
    8000458c:	00000097          	auipc	ra,0x0
    80004590:	ac8080e7          	jalr	-1336(ra) # 80004054 <begin_op>
    iput(ff.ip);
    80004594:	854e                	mv	a0,s3
    80004596:	fffff097          	auipc	ra,0xfffff
    8000459a:	2a2080e7          	jalr	674(ra) # 80003838 <iput>
    end_op();
    8000459e:	00000097          	auipc	ra,0x0
    800045a2:	b36080e7          	jalr	-1226(ra) # 800040d4 <end_op>
    800045a6:	a00d                	j	800045c8 <fileclose+0xa8>
    panic("fileclose");
    800045a8:	00004517          	auipc	a0,0x4
    800045ac:	0d850513          	addi	a0,a0,216 # 80008680 <syscalls+0x248>
    800045b0:	ffffc097          	auipc	ra,0xffffc
    800045b4:	f7a080e7          	jalr	-134(ra) # 8000052a <panic>
    release(&ftable.lock);
    800045b8:	0001d517          	auipc	a0,0x1d
    800045bc:	e0050513          	addi	a0,a0,-512 # 800213b8 <ftable>
    800045c0:	ffffc097          	auipc	ra,0xffffc
    800045c4:	6b6080e7          	jalr	1718(ra) # 80000c76 <release>
  }
}
    800045c8:	70e2                	ld	ra,56(sp)
    800045ca:	7442                	ld	s0,48(sp)
    800045cc:	74a2                	ld	s1,40(sp)
    800045ce:	7902                	ld	s2,32(sp)
    800045d0:	69e2                	ld	s3,24(sp)
    800045d2:	6a42                	ld	s4,16(sp)
    800045d4:	6aa2                	ld	s5,8(sp)
    800045d6:	6121                	addi	sp,sp,64
    800045d8:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800045da:	85d6                	mv	a1,s5
    800045dc:	8552                	mv	a0,s4
    800045de:	00000097          	auipc	ra,0x0
    800045e2:	34c080e7          	jalr	844(ra) # 8000492a <pipeclose>
    800045e6:	b7cd                	j	800045c8 <fileclose+0xa8>

00000000800045e8 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800045e8:	715d                	addi	sp,sp,-80
    800045ea:	e486                	sd	ra,72(sp)
    800045ec:	e0a2                	sd	s0,64(sp)
    800045ee:	fc26                	sd	s1,56(sp)
    800045f0:	f84a                	sd	s2,48(sp)
    800045f2:	f44e                	sd	s3,40(sp)
    800045f4:	0880                	addi	s0,sp,80
    800045f6:	84aa                	mv	s1,a0
    800045f8:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800045fa:	ffffd097          	auipc	ra,0xffffd
    800045fe:	3d8080e7          	jalr	984(ra) # 800019d2 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004602:	409c                	lw	a5,0(s1)
    80004604:	37f9                	addiw	a5,a5,-2
    80004606:	4705                	li	a4,1
    80004608:	04f76763          	bltu	a4,a5,80004656 <filestat+0x6e>
    8000460c:	892a                	mv	s2,a0
    ilock(f->ip);
    8000460e:	6c88                	ld	a0,24(s1)
    80004610:	fffff097          	auipc	ra,0xfffff
    80004614:	06e080e7          	jalr	110(ra) # 8000367e <ilock>
    stati(f->ip, &st);
    80004618:	fb840593          	addi	a1,s0,-72
    8000461c:	6c88                	ld	a0,24(s1)
    8000461e:	fffff097          	auipc	ra,0xfffff
    80004622:	2ea080e7          	jalr	746(ra) # 80003908 <stati>
    iunlock(f->ip);
    80004626:	6c88                	ld	a0,24(s1)
    80004628:	fffff097          	auipc	ra,0xfffff
    8000462c:	118080e7          	jalr	280(ra) # 80003740 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004630:	46e1                	li	a3,24
    80004632:	fb840613          	addi	a2,s0,-72
    80004636:	85ce                	mv	a1,s3
    80004638:	05093503          	ld	a0,80(s2)
    8000463c:	ffffd097          	auipc	ra,0xffffd
    80004640:	056080e7          	jalr	86(ra) # 80001692 <copyout>
    80004644:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004648:	60a6                	ld	ra,72(sp)
    8000464a:	6406                	ld	s0,64(sp)
    8000464c:	74e2                	ld	s1,56(sp)
    8000464e:	7942                	ld	s2,48(sp)
    80004650:	79a2                	ld	s3,40(sp)
    80004652:	6161                	addi	sp,sp,80
    80004654:	8082                	ret
  return -1;
    80004656:	557d                	li	a0,-1
    80004658:	bfc5                	j	80004648 <filestat+0x60>

000000008000465a <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000465a:	7179                	addi	sp,sp,-48
    8000465c:	f406                	sd	ra,40(sp)
    8000465e:	f022                	sd	s0,32(sp)
    80004660:	ec26                	sd	s1,24(sp)
    80004662:	e84a                	sd	s2,16(sp)
    80004664:	e44e                	sd	s3,8(sp)
    80004666:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004668:	00854783          	lbu	a5,8(a0)
    8000466c:	c3d5                	beqz	a5,80004710 <fileread+0xb6>
    8000466e:	84aa                	mv	s1,a0
    80004670:	89ae                	mv	s3,a1
    80004672:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004674:	411c                	lw	a5,0(a0)
    80004676:	4705                	li	a4,1
    80004678:	04e78963          	beq	a5,a4,800046ca <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000467c:	470d                	li	a4,3
    8000467e:	04e78d63          	beq	a5,a4,800046d8 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004682:	4709                	li	a4,2
    80004684:	06e79e63          	bne	a5,a4,80004700 <fileread+0xa6>
    ilock(f->ip);
    80004688:	6d08                	ld	a0,24(a0)
    8000468a:	fffff097          	auipc	ra,0xfffff
    8000468e:	ff4080e7          	jalr	-12(ra) # 8000367e <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004692:	874a                	mv	a4,s2
    80004694:	5094                	lw	a3,32(s1)
    80004696:	864e                	mv	a2,s3
    80004698:	4585                	li	a1,1
    8000469a:	6c88                	ld	a0,24(s1)
    8000469c:	fffff097          	auipc	ra,0xfffff
    800046a0:	296080e7          	jalr	662(ra) # 80003932 <readi>
    800046a4:	892a                	mv	s2,a0
    800046a6:	00a05563          	blez	a0,800046b0 <fileread+0x56>
      f->off += r;
    800046aa:	509c                	lw	a5,32(s1)
    800046ac:	9fa9                	addw	a5,a5,a0
    800046ae:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800046b0:	6c88                	ld	a0,24(s1)
    800046b2:	fffff097          	auipc	ra,0xfffff
    800046b6:	08e080e7          	jalr	142(ra) # 80003740 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800046ba:	854a                	mv	a0,s2
    800046bc:	70a2                	ld	ra,40(sp)
    800046be:	7402                	ld	s0,32(sp)
    800046c0:	64e2                	ld	s1,24(sp)
    800046c2:	6942                	ld	s2,16(sp)
    800046c4:	69a2                	ld	s3,8(sp)
    800046c6:	6145                	addi	sp,sp,48
    800046c8:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800046ca:	6908                	ld	a0,16(a0)
    800046cc:	00000097          	auipc	ra,0x0
    800046d0:	3c0080e7          	jalr	960(ra) # 80004a8c <piperead>
    800046d4:	892a                	mv	s2,a0
    800046d6:	b7d5                	j	800046ba <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800046d8:	02451783          	lh	a5,36(a0)
    800046dc:	03079693          	slli	a3,a5,0x30
    800046e0:	92c1                	srli	a3,a3,0x30
    800046e2:	4725                	li	a4,9
    800046e4:	02d76863          	bltu	a4,a3,80004714 <fileread+0xba>
    800046e8:	0792                	slli	a5,a5,0x4
    800046ea:	0001d717          	auipc	a4,0x1d
    800046ee:	c2e70713          	addi	a4,a4,-978 # 80021318 <devsw>
    800046f2:	97ba                	add	a5,a5,a4
    800046f4:	639c                	ld	a5,0(a5)
    800046f6:	c38d                	beqz	a5,80004718 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800046f8:	4505                	li	a0,1
    800046fa:	9782                	jalr	a5
    800046fc:	892a                	mv	s2,a0
    800046fe:	bf75                	j	800046ba <fileread+0x60>
    panic("fileread");
    80004700:	00004517          	auipc	a0,0x4
    80004704:	f9050513          	addi	a0,a0,-112 # 80008690 <syscalls+0x258>
    80004708:	ffffc097          	auipc	ra,0xffffc
    8000470c:	e22080e7          	jalr	-478(ra) # 8000052a <panic>
    return -1;
    80004710:	597d                	li	s2,-1
    80004712:	b765                	j	800046ba <fileread+0x60>
      return -1;
    80004714:	597d                	li	s2,-1
    80004716:	b755                	j	800046ba <fileread+0x60>
    80004718:	597d                	li	s2,-1
    8000471a:	b745                	j	800046ba <fileread+0x60>

000000008000471c <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    8000471c:	715d                	addi	sp,sp,-80
    8000471e:	e486                	sd	ra,72(sp)
    80004720:	e0a2                	sd	s0,64(sp)
    80004722:	fc26                	sd	s1,56(sp)
    80004724:	f84a                	sd	s2,48(sp)
    80004726:	f44e                	sd	s3,40(sp)
    80004728:	f052                	sd	s4,32(sp)
    8000472a:	ec56                	sd	s5,24(sp)
    8000472c:	e85a                	sd	s6,16(sp)
    8000472e:	e45e                	sd	s7,8(sp)
    80004730:	e062                	sd	s8,0(sp)
    80004732:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004734:	00954783          	lbu	a5,9(a0)
    80004738:	10078663          	beqz	a5,80004844 <filewrite+0x128>
    8000473c:	892a                	mv	s2,a0
    8000473e:	8aae                	mv	s5,a1
    80004740:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004742:	411c                	lw	a5,0(a0)
    80004744:	4705                	li	a4,1
    80004746:	02e78263          	beq	a5,a4,8000476a <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000474a:	470d                	li	a4,3
    8000474c:	02e78663          	beq	a5,a4,80004778 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004750:	4709                	li	a4,2
    80004752:	0ee79163          	bne	a5,a4,80004834 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004756:	0ac05d63          	blez	a2,80004810 <filewrite+0xf4>
    int i = 0;
    8000475a:	4981                	li	s3,0
    8000475c:	6b05                	lui	s6,0x1
    8000475e:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004762:	6b85                	lui	s7,0x1
    80004764:	c00b8b9b          	addiw	s7,s7,-1024
    80004768:	a861                	j	80004800 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    8000476a:	6908                	ld	a0,16(a0)
    8000476c:	00000097          	auipc	ra,0x0
    80004770:	22e080e7          	jalr	558(ra) # 8000499a <pipewrite>
    80004774:	8a2a                	mv	s4,a0
    80004776:	a045                	j	80004816 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004778:	02451783          	lh	a5,36(a0)
    8000477c:	03079693          	slli	a3,a5,0x30
    80004780:	92c1                	srli	a3,a3,0x30
    80004782:	4725                	li	a4,9
    80004784:	0cd76263          	bltu	a4,a3,80004848 <filewrite+0x12c>
    80004788:	0792                	slli	a5,a5,0x4
    8000478a:	0001d717          	auipc	a4,0x1d
    8000478e:	b8e70713          	addi	a4,a4,-1138 # 80021318 <devsw>
    80004792:	97ba                	add	a5,a5,a4
    80004794:	679c                	ld	a5,8(a5)
    80004796:	cbdd                	beqz	a5,8000484c <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004798:	4505                	li	a0,1
    8000479a:	9782                	jalr	a5
    8000479c:	8a2a                	mv	s4,a0
    8000479e:	a8a5                	j	80004816 <filewrite+0xfa>
    800047a0:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800047a4:	00000097          	auipc	ra,0x0
    800047a8:	8b0080e7          	jalr	-1872(ra) # 80004054 <begin_op>
      ilock(f->ip);
    800047ac:	01893503          	ld	a0,24(s2)
    800047b0:	fffff097          	auipc	ra,0xfffff
    800047b4:	ece080e7          	jalr	-306(ra) # 8000367e <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800047b8:	8762                	mv	a4,s8
    800047ba:	02092683          	lw	a3,32(s2)
    800047be:	01598633          	add	a2,s3,s5
    800047c2:	4585                	li	a1,1
    800047c4:	01893503          	ld	a0,24(s2)
    800047c8:	fffff097          	auipc	ra,0xfffff
    800047cc:	262080e7          	jalr	610(ra) # 80003a2a <writei>
    800047d0:	84aa                	mv	s1,a0
    800047d2:	00a05763          	blez	a0,800047e0 <filewrite+0xc4>
        f->off += r;
    800047d6:	02092783          	lw	a5,32(s2)
    800047da:	9fa9                	addw	a5,a5,a0
    800047dc:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800047e0:	01893503          	ld	a0,24(s2)
    800047e4:	fffff097          	auipc	ra,0xfffff
    800047e8:	f5c080e7          	jalr	-164(ra) # 80003740 <iunlock>
      end_op();
    800047ec:	00000097          	auipc	ra,0x0
    800047f0:	8e8080e7          	jalr	-1816(ra) # 800040d4 <end_op>

      if(r != n1){
    800047f4:	009c1f63          	bne	s8,s1,80004812 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800047f8:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800047fc:	0149db63          	bge	s3,s4,80004812 <filewrite+0xf6>
      int n1 = n - i;
    80004800:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004804:	84be                	mv	s1,a5
    80004806:	2781                	sext.w	a5,a5
    80004808:	f8fb5ce3          	bge	s6,a5,800047a0 <filewrite+0x84>
    8000480c:	84de                	mv	s1,s7
    8000480e:	bf49                	j	800047a0 <filewrite+0x84>
    int i = 0;
    80004810:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004812:	013a1f63          	bne	s4,s3,80004830 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004816:	8552                	mv	a0,s4
    80004818:	60a6                	ld	ra,72(sp)
    8000481a:	6406                	ld	s0,64(sp)
    8000481c:	74e2                	ld	s1,56(sp)
    8000481e:	7942                	ld	s2,48(sp)
    80004820:	79a2                	ld	s3,40(sp)
    80004822:	7a02                	ld	s4,32(sp)
    80004824:	6ae2                	ld	s5,24(sp)
    80004826:	6b42                	ld	s6,16(sp)
    80004828:	6ba2                	ld	s7,8(sp)
    8000482a:	6c02                	ld	s8,0(sp)
    8000482c:	6161                	addi	sp,sp,80
    8000482e:	8082                	ret
    ret = (i == n ? n : -1);
    80004830:	5a7d                	li	s4,-1
    80004832:	b7d5                	j	80004816 <filewrite+0xfa>
    panic("filewrite");
    80004834:	00004517          	auipc	a0,0x4
    80004838:	e6c50513          	addi	a0,a0,-404 # 800086a0 <syscalls+0x268>
    8000483c:	ffffc097          	auipc	ra,0xffffc
    80004840:	cee080e7          	jalr	-786(ra) # 8000052a <panic>
    return -1;
    80004844:	5a7d                	li	s4,-1
    80004846:	bfc1                	j	80004816 <filewrite+0xfa>
      return -1;
    80004848:	5a7d                	li	s4,-1
    8000484a:	b7f1                	j	80004816 <filewrite+0xfa>
    8000484c:	5a7d                	li	s4,-1
    8000484e:	b7e1                	j	80004816 <filewrite+0xfa>

0000000080004850 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004850:	7179                	addi	sp,sp,-48
    80004852:	f406                	sd	ra,40(sp)
    80004854:	f022                	sd	s0,32(sp)
    80004856:	ec26                	sd	s1,24(sp)
    80004858:	e84a                	sd	s2,16(sp)
    8000485a:	e44e                	sd	s3,8(sp)
    8000485c:	e052                	sd	s4,0(sp)
    8000485e:	1800                	addi	s0,sp,48
    80004860:	84aa                	mv	s1,a0
    80004862:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004864:	0005b023          	sd	zero,0(a1)
    80004868:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    8000486c:	00000097          	auipc	ra,0x0
    80004870:	bf8080e7          	jalr	-1032(ra) # 80004464 <filealloc>
    80004874:	e088                	sd	a0,0(s1)
    80004876:	c551                	beqz	a0,80004902 <pipealloc+0xb2>
    80004878:	00000097          	auipc	ra,0x0
    8000487c:	bec080e7          	jalr	-1044(ra) # 80004464 <filealloc>
    80004880:	00aa3023          	sd	a0,0(s4)
    80004884:	c92d                	beqz	a0,800048f6 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004886:	ffffc097          	auipc	ra,0xffffc
    8000488a:	24c080e7          	jalr	588(ra) # 80000ad2 <kalloc>
    8000488e:	892a                	mv	s2,a0
    80004890:	c125                	beqz	a0,800048f0 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004892:	4985                	li	s3,1
    80004894:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004898:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    8000489c:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800048a0:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800048a4:	00004597          	auipc	a1,0x4
    800048a8:	e0c58593          	addi	a1,a1,-500 # 800086b0 <syscalls+0x278>
    800048ac:	ffffc097          	auipc	ra,0xffffc
    800048b0:	286080e7          	jalr	646(ra) # 80000b32 <initlock>
  (*f0)->type = FD_PIPE;
    800048b4:	609c                	ld	a5,0(s1)
    800048b6:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800048ba:	609c                	ld	a5,0(s1)
    800048bc:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800048c0:	609c                	ld	a5,0(s1)
    800048c2:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800048c6:	609c                	ld	a5,0(s1)
    800048c8:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800048cc:	000a3783          	ld	a5,0(s4)
    800048d0:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800048d4:	000a3783          	ld	a5,0(s4)
    800048d8:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800048dc:	000a3783          	ld	a5,0(s4)
    800048e0:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800048e4:	000a3783          	ld	a5,0(s4)
    800048e8:	0127b823          	sd	s2,16(a5)
  return 0;
    800048ec:	4501                	li	a0,0
    800048ee:	a025                	j	80004916 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800048f0:	6088                	ld	a0,0(s1)
    800048f2:	e501                	bnez	a0,800048fa <pipealloc+0xaa>
    800048f4:	a039                	j	80004902 <pipealloc+0xb2>
    800048f6:	6088                	ld	a0,0(s1)
    800048f8:	c51d                	beqz	a0,80004926 <pipealloc+0xd6>
    fileclose(*f0);
    800048fa:	00000097          	auipc	ra,0x0
    800048fe:	c26080e7          	jalr	-986(ra) # 80004520 <fileclose>
  if(*f1)
    80004902:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004906:	557d                	li	a0,-1
  if(*f1)
    80004908:	c799                	beqz	a5,80004916 <pipealloc+0xc6>
    fileclose(*f1);
    8000490a:	853e                	mv	a0,a5
    8000490c:	00000097          	auipc	ra,0x0
    80004910:	c14080e7          	jalr	-1004(ra) # 80004520 <fileclose>
  return -1;
    80004914:	557d                	li	a0,-1
}
    80004916:	70a2                	ld	ra,40(sp)
    80004918:	7402                	ld	s0,32(sp)
    8000491a:	64e2                	ld	s1,24(sp)
    8000491c:	6942                	ld	s2,16(sp)
    8000491e:	69a2                	ld	s3,8(sp)
    80004920:	6a02                	ld	s4,0(sp)
    80004922:	6145                	addi	sp,sp,48
    80004924:	8082                	ret
  return -1;
    80004926:	557d                	li	a0,-1
    80004928:	b7fd                	j	80004916 <pipealloc+0xc6>

000000008000492a <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    8000492a:	1101                	addi	sp,sp,-32
    8000492c:	ec06                	sd	ra,24(sp)
    8000492e:	e822                	sd	s0,16(sp)
    80004930:	e426                	sd	s1,8(sp)
    80004932:	e04a                	sd	s2,0(sp)
    80004934:	1000                	addi	s0,sp,32
    80004936:	84aa                	mv	s1,a0
    80004938:	892e                	mv	s2,a1
  acquire(&pi->lock);
    8000493a:	ffffc097          	auipc	ra,0xffffc
    8000493e:	288080e7          	jalr	648(ra) # 80000bc2 <acquire>
  if(writable){
    80004942:	02090d63          	beqz	s2,8000497c <pipeclose+0x52>
    pi->writeopen = 0;
    80004946:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    8000494a:	21848513          	addi	a0,s1,536
    8000494e:	ffffe097          	auipc	ra,0xffffe
    80004952:	8d0080e7          	jalr	-1840(ra) # 8000221e <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004956:	2204b783          	ld	a5,544(s1)
    8000495a:	eb95                	bnez	a5,8000498e <pipeclose+0x64>
    release(&pi->lock);
    8000495c:	8526                	mv	a0,s1
    8000495e:	ffffc097          	auipc	ra,0xffffc
    80004962:	318080e7          	jalr	792(ra) # 80000c76 <release>
    kfree((char*)pi);
    80004966:	8526                	mv	a0,s1
    80004968:	ffffc097          	auipc	ra,0xffffc
    8000496c:	06e080e7          	jalr	110(ra) # 800009d6 <kfree>
  } else
    release(&pi->lock);
}
    80004970:	60e2                	ld	ra,24(sp)
    80004972:	6442                	ld	s0,16(sp)
    80004974:	64a2                	ld	s1,8(sp)
    80004976:	6902                	ld	s2,0(sp)
    80004978:	6105                	addi	sp,sp,32
    8000497a:	8082                	ret
    pi->readopen = 0;
    8000497c:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004980:	21c48513          	addi	a0,s1,540
    80004984:	ffffe097          	auipc	ra,0xffffe
    80004988:	89a080e7          	jalr	-1894(ra) # 8000221e <wakeup>
    8000498c:	b7e9                	j	80004956 <pipeclose+0x2c>
    release(&pi->lock);
    8000498e:	8526                	mv	a0,s1
    80004990:	ffffc097          	auipc	ra,0xffffc
    80004994:	2e6080e7          	jalr	742(ra) # 80000c76 <release>
}
    80004998:	bfe1                	j	80004970 <pipeclose+0x46>

000000008000499a <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    8000499a:	711d                	addi	sp,sp,-96
    8000499c:	ec86                	sd	ra,88(sp)
    8000499e:	e8a2                	sd	s0,80(sp)
    800049a0:	e4a6                	sd	s1,72(sp)
    800049a2:	e0ca                	sd	s2,64(sp)
    800049a4:	fc4e                	sd	s3,56(sp)
    800049a6:	f852                	sd	s4,48(sp)
    800049a8:	f456                	sd	s5,40(sp)
    800049aa:	f05a                	sd	s6,32(sp)
    800049ac:	ec5e                	sd	s7,24(sp)
    800049ae:	e862                	sd	s8,16(sp)
    800049b0:	1080                	addi	s0,sp,96
    800049b2:	84aa                	mv	s1,a0
    800049b4:	8aae                	mv	s5,a1
    800049b6:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800049b8:	ffffd097          	auipc	ra,0xffffd
    800049bc:	01a080e7          	jalr	26(ra) # 800019d2 <myproc>
    800049c0:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    800049c2:	8526                	mv	a0,s1
    800049c4:	ffffc097          	auipc	ra,0xffffc
    800049c8:	1fe080e7          	jalr	510(ra) # 80000bc2 <acquire>
  while(i < n){
    800049cc:	0b405363          	blez	s4,80004a72 <pipewrite+0xd8>
  int i = 0;
    800049d0:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800049d2:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    800049d4:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800049d8:	21c48b93          	addi	s7,s1,540
    800049dc:	a089                	j	80004a1e <pipewrite+0x84>
      release(&pi->lock);
    800049de:	8526                	mv	a0,s1
    800049e0:	ffffc097          	auipc	ra,0xffffc
    800049e4:	296080e7          	jalr	662(ra) # 80000c76 <release>
      return -1;
    800049e8:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800049ea:	854a                	mv	a0,s2
    800049ec:	60e6                	ld	ra,88(sp)
    800049ee:	6446                	ld	s0,80(sp)
    800049f0:	64a6                	ld	s1,72(sp)
    800049f2:	6906                	ld	s2,64(sp)
    800049f4:	79e2                	ld	s3,56(sp)
    800049f6:	7a42                	ld	s4,48(sp)
    800049f8:	7aa2                	ld	s5,40(sp)
    800049fa:	7b02                	ld	s6,32(sp)
    800049fc:	6be2                	ld	s7,24(sp)
    800049fe:	6c42                	ld	s8,16(sp)
    80004a00:	6125                	addi	sp,sp,96
    80004a02:	8082                	ret
      wakeup(&pi->nread);
    80004a04:	8562                	mv	a0,s8
    80004a06:	ffffe097          	auipc	ra,0xffffe
    80004a0a:	818080e7          	jalr	-2024(ra) # 8000221e <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004a0e:	85a6                	mv	a1,s1
    80004a10:	855e                	mv	a0,s7
    80004a12:	ffffd097          	auipc	ra,0xffffd
    80004a16:	680080e7          	jalr	1664(ra) # 80002092 <sleep>
  while(i < n){
    80004a1a:	05495d63          	bge	s2,s4,80004a74 <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    80004a1e:	2204a783          	lw	a5,544(s1)
    80004a22:	dfd5                	beqz	a5,800049de <pipewrite+0x44>
    80004a24:	0289a783          	lw	a5,40(s3)
    80004a28:	fbdd                	bnez	a5,800049de <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004a2a:	2184a783          	lw	a5,536(s1)
    80004a2e:	21c4a703          	lw	a4,540(s1)
    80004a32:	2007879b          	addiw	a5,a5,512
    80004a36:	fcf707e3          	beq	a4,a5,80004a04 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a3a:	4685                	li	a3,1
    80004a3c:	01590633          	add	a2,s2,s5
    80004a40:	faf40593          	addi	a1,s0,-81
    80004a44:	0509b503          	ld	a0,80(s3)
    80004a48:	ffffd097          	auipc	ra,0xffffd
    80004a4c:	cd6080e7          	jalr	-810(ra) # 8000171e <copyin>
    80004a50:	03650263          	beq	a0,s6,80004a74 <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004a54:	21c4a783          	lw	a5,540(s1)
    80004a58:	0017871b          	addiw	a4,a5,1
    80004a5c:	20e4ae23          	sw	a4,540(s1)
    80004a60:	1ff7f793          	andi	a5,a5,511
    80004a64:	97a6                	add	a5,a5,s1
    80004a66:	faf44703          	lbu	a4,-81(s0)
    80004a6a:	00e78c23          	sb	a4,24(a5)
      i++;
    80004a6e:	2905                	addiw	s2,s2,1
    80004a70:	b76d                	j	80004a1a <pipewrite+0x80>
  int i = 0;
    80004a72:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004a74:	21848513          	addi	a0,s1,536
    80004a78:	ffffd097          	auipc	ra,0xffffd
    80004a7c:	7a6080e7          	jalr	1958(ra) # 8000221e <wakeup>
  release(&pi->lock);
    80004a80:	8526                	mv	a0,s1
    80004a82:	ffffc097          	auipc	ra,0xffffc
    80004a86:	1f4080e7          	jalr	500(ra) # 80000c76 <release>
  return i;
    80004a8a:	b785                	j	800049ea <pipewrite+0x50>

0000000080004a8c <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004a8c:	715d                	addi	sp,sp,-80
    80004a8e:	e486                	sd	ra,72(sp)
    80004a90:	e0a2                	sd	s0,64(sp)
    80004a92:	fc26                	sd	s1,56(sp)
    80004a94:	f84a                	sd	s2,48(sp)
    80004a96:	f44e                	sd	s3,40(sp)
    80004a98:	f052                	sd	s4,32(sp)
    80004a9a:	ec56                	sd	s5,24(sp)
    80004a9c:	e85a                	sd	s6,16(sp)
    80004a9e:	0880                	addi	s0,sp,80
    80004aa0:	84aa                	mv	s1,a0
    80004aa2:	892e                	mv	s2,a1
    80004aa4:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004aa6:	ffffd097          	auipc	ra,0xffffd
    80004aaa:	f2c080e7          	jalr	-212(ra) # 800019d2 <myproc>
    80004aae:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004ab0:	8526                	mv	a0,s1
    80004ab2:	ffffc097          	auipc	ra,0xffffc
    80004ab6:	110080e7          	jalr	272(ra) # 80000bc2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004aba:	2184a703          	lw	a4,536(s1)
    80004abe:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004ac2:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ac6:	02f71463          	bne	a4,a5,80004aee <piperead+0x62>
    80004aca:	2244a783          	lw	a5,548(s1)
    80004ace:	c385                	beqz	a5,80004aee <piperead+0x62>
    if(pr->killed){
    80004ad0:	028a2783          	lw	a5,40(s4)
    80004ad4:	ebc1                	bnez	a5,80004b64 <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004ad6:	85a6                	mv	a1,s1
    80004ad8:	854e                	mv	a0,s3
    80004ada:	ffffd097          	auipc	ra,0xffffd
    80004ade:	5b8080e7          	jalr	1464(ra) # 80002092 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ae2:	2184a703          	lw	a4,536(s1)
    80004ae6:	21c4a783          	lw	a5,540(s1)
    80004aea:	fef700e3          	beq	a4,a5,80004aca <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004aee:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004af0:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004af2:	05505363          	blez	s5,80004b38 <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80004af6:	2184a783          	lw	a5,536(s1)
    80004afa:	21c4a703          	lw	a4,540(s1)
    80004afe:	02f70d63          	beq	a4,a5,80004b38 <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004b02:	0017871b          	addiw	a4,a5,1
    80004b06:	20e4ac23          	sw	a4,536(s1)
    80004b0a:	1ff7f793          	andi	a5,a5,511
    80004b0e:	97a6                	add	a5,a5,s1
    80004b10:	0187c783          	lbu	a5,24(a5)
    80004b14:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b18:	4685                	li	a3,1
    80004b1a:	fbf40613          	addi	a2,s0,-65
    80004b1e:	85ca                	mv	a1,s2
    80004b20:	050a3503          	ld	a0,80(s4)
    80004b24:	ffffd097          	auipc	ra,0xffffd
    80004b28:	b6e080e7          	jalr	-1170(ra) # 80001692 <copyout>
    80004b2c:	01650663          	beq	a0,s6,80004b38 <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b30:	2985                	addiw	s3,s3,1
    80004b32:	0905                	addi	s2,s2,1
    80004b34:	fd3a91e3          	bne	s5,s3,80004af6 <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004b38:	21c48513          	addi	a0,s1,540
    80004b3c:	ffffd097          	auipc	ra,0xffffd
    80004b40:	6e2080e7          	jalr	1762(ra) # 8000221e <wakeup>
  release(&pi->lock);
    80004b44:	8526                	mv	a0,s1
    80004b46:	ffffc097          	auipc	ra,0xffffc
    80004b4a:	130080e7          	jalr	304(ra) # 80000c76 <release>
  return i;
}
    80004b4e:	854e                	mv	a0,s3
    80004b50:	60a6                	ld	ra,72(sp)
    80004b52:	6406                	ld	s0,64(sp)
    80004b54:	74e2                	ld	s1,56(sp)
    80004b56:	7942                	ld	s2,48(sp)
    80004b58:	79a2                	ld	s3,40(sp)
    80004b5a:	7a02                	ld	s4,32(sp)
    80004b5c:	6ae2                	ld	s5,24(sp)
    80004b5e:	6b42                	ld	s6,16(sp)
    80004b60:	6161                	addi	sp,sp,80
    80004b62:	8082                	ret
      release(&pi->lock);
    80004b64:	8526                	mv	a0,s1
    80004b66:	ffffc097          	auipc	ra,0xffffc
    80004b6a:	110080e7          	jalr	272(ra) # 80000c76 <release>
      return -1;
    80004b6e:	59fd                	li	s3,-1
    80004b70:	bff9                	j	80004b4e <piperead+0xc2>

0000000080004b72 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004b72:	de010113          	addi	sp,sp,-544
    80004b76:	20113c23          	sd	ra,536(sp)
    80004b7a:	20813823          	sd	s0,528(sp)
    80004b7e:	20913423          	sd	s1,520(sp)
    80004b82:	21213023          	sd	s2,512(sp)
    80004b86:	ffce                	sd	s3,504(sp)
    80004b88:	fbd2                	sd	s4,496(sp)
    80004b8a:	f7d6                	sd	s5,488(sp)
    80004b8c:	f3da                	sd	s6,480(sp)
    80004b8e:	efde                	sd	s7,472(sp)
    80004b90:	ebe2                	sd	s8,464(sp)
    80004b92:	e7e6                	sd	s9,456(sp)
    80004b94:	e3ea                	sd	s10,448(sp)
    80004b96:	ff6e                	sd	s11,440(sp)
    80004b98:	1400                	addi	s0,sp,544
    80004b9a:	892a                	mv	s2,a0
    80004b9c:	dea43423          	sd	a0,-536(s0)
    80004ba0:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004ba4:	ffffd097          	auipc	ra,0xffffd
    80004ba8:	e2e080e7          	jalr	-466(ra) # 800019d2 <myproc>
    80004bac:	84aa                	mv	s1,a0

  begin_op();
    80004bae:	fffff097          	auipc	ra,0xfffff
    80004bb2:	4a6080e7          	jalr	1190(ra) # 80004054 <begin_op>

  if((ip = namei(path)) == 0){
    80004bb6:	854a                	mv	a0,s2
    80004bb8:	fffff097          	auipc	ra,0xfffff
    80004bbc:	27c080e7          	jalr	636(ra) # 80003e34 <namei>
    80004bc0:	c93d                	beqz	a0,80004c36 <exec+0xc4>
    80004bc2:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004bc4:	fffff097          	auipc	ra,0xfffff
    80004bc8:	aba080e7          	jalr	-1350(ra) # 8000367e <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004bcc:	04000713          	li	a4,64
    80004bd0:	4681                	li	a3,0
    80004bd2:	e4840613          	addi	a2,s0,-440
    80004bd6:	4581                	li	a1,0
    80004bd8:	8556                	mv	a0,s5
    80004bda:	fffff097          	auipc	ra,0xfffff
    80004bde:	d58080e7          	jalr	-680(ra) # 80003932 <readi>
    80004be2:	04000793          	li	a5,64
    80004be6:	00f51a63          	bne	a0,a5,80004bfa <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004bea:	e4842703          	lw	a4,-440(s0)
    80004bee:	464c47b7          	lui	a5,0x464c4
    80004bf2:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004bf6:	04f70663          	beq	a4,a5,80004c42 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004bfa:	8556                	mv	a0,s5
    80004bfc:	fffff097          	auipc	ra,0xfffff
    80004c00:	ce4080e7          	jalr	-796(ra) # 800038e0 <iunlockput>
    end_op();
    80004c04:	fffff097          	auipc	ra,0xfffff
    80004c08:	4d0080e7          	jalr	1232(ra) # 800040d4 <end_op>
  }
  return -1;
    80004c0c:	557d                	li	a0,-1
}
    80004c0e:	21813083          	ld	ra,536(sp)
    80004c12:	21013403          	ld	s0,528(sp)
    80004c16:	20813483          	ld	s1,520(sp)
    80004c1a:	20013903          	ld	s2,512(sp)
    80004c1e:	79fe                	ld	s3,504(sp)
    80004c20:	7a5e                	ld	s4,496(sp)
    80004c22:	7abe                	ld	s5,488(sp)
    80004c24:	7b1e                	ld	s6,480(sp)
    80004c26:	6bfe                	ld	s7,472(sp)
    80004c28:	6c5e                	ld	s8,464(sp)
    80004c2a:	6cbe                	ld	s9,456(sp)
    80004c2c:	6d1e                	ld	s10,448(sp)
    80004c2e:	7dfa                	ld	s11,440(sp)
    80004c30:	22010113          	addi	sp,sp,544
    80004c34:	8082                	ret
    end_op();
    80004c36:	fffff097          	auipc	ra,0xfffff
    80004c3a:	49e080e7          	jalr	1182(ra) # 800040d4 <end_op>
    return -1;
    80004c3e:	557d                	li	a0,-1
    80004c40:	b7f9                	j	80004c0e <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004c42:	8526                	mv	a0,s1
    80004c44:	ffffd097          	auipc	ra,0xffffd
    80004c48:	e52080e7          	jalr	-430(ra) # 80001a96 <proc_pagetable>
    80004c4c:	8b2a                	mv	s6,a0
    80004c4e:	d555                	beqz	a0,80004bfa <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004c50:	e6842783          	lw	a5,-408(s0)
    80004c54:	e8045703          	lhu	a4,-384(s0)
    80004c58:	c735                	beqz	a4,80004cc4 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004c5a:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004c5c:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004c60:	6a05                	lui	s4,0x1
    80004c62:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004c66:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80004c6a:	6d85                	lui	s11,0x1
    80004c6c:	7d7d                	lui	s10,0xfffff
    80004c6e:	ac1d                	j	80004ea4 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004c70:	00004517          	auipc	a0,0x4
    80004c74:	a4850513          	addi	a0,a0,-1464 # 800086b8 <syscalls+0x280>
    80004c78:	ffffc097          	auipc	ra,0xffffc
    80004c7c:	8b2080e7          	jalr	-1870(ra) # 8000052a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004c80:	874a                	mv	a4,s2
    80004c82:	009c86bb          	addw	a3,s9,s1
    80004c86:	4581                	li	a1,0
    80004c88:	8556                	mv	a0,s5
    80004c8a:	fffff097          	auipc	ra,0xfffff
    80004c8e:	ca8080e7          	jalr	-856(ra) # 80003932 <readi>
    80004c92:	2501                	sext.w	a0,a0
    80004c94:	1aa91863          	bne	s2,a0,80004e44 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80004c98:	009d84bb          	addw	s1,s11,s1
    80004c9c:	013d09bb          	addw	s3,s10,s3
    80004ca0:	1f74f263          	bgeu	s1,s7,80004e84 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80004ca4:	02049593          	slli	a1,s1,0x20
    80004ca8:	9181                	srli	a1,a1,0x20
    80004caa:	95e2                	add	a1,a1,s8
    80004cac:	855a                	mv	a0,s6
    80004cae:	ffffc097          	auipc	ra,0xffffc
    80004cb2:	42c080e7          	jalr	1068(ra) # 800010da <walkaddr>
    80004cb6:	862a                	mv	a2,a0
    if(pa == 0)
    80004cb8:	dd45                	beqz	a0,80004c70 <exec+0xfe>
      n = PGSIZE;
    80004cba:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004cbc:	fd49f2e3          	bgeu	s3,s4,80004c80 <exec+0x10e>
      n = sz - i;
    80004cc0:	894e                	mv	s2,s3
    80004cc2:	bf7d                	j	80004c80 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004cc4:	4481                	li	s1,0
  iunlockput(ip);
    80004cc6:	8556                	mv	a0,s5
    80004cc8:	fffff097          	auipc	ra,0xfffff
    80004ccc:	c18080e7          	jalr	-1000(ra) # 800038e0 <iunlockput>
  end_op();
    80004cd0:	fffff097          	auipc	ra,0xfffff
    80004cd4:	404080e7          	jalr	1028(ra) # 800040d4 <end_op>
  p = myproc();
    80004cd8:	ffffd097          	auipc	ra,0xffffd
    80004cdc:	cfa080e7          	jalr	-774(ra) # 800019d2 <myproc>
    80004ce0:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004ce2:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004ce6:	6785                	lui	a5,0x1
    80004ce8:	17fd                	addi	a5,a5,-1
    80004cea:	94be                	add	s1,s1,a5
    80004cec:	77fd                	lui	a5,0xfffff
    80004cee:	8fe5                	and	a5,a5,s1
    80004cf0:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004cf4:	6609                	lui	a2,0x2
    80004cf6:	963e                	add	a2,a2,a5
    80004cf8:	85be                	mv	a1,a5
    80004cfa:	855a                	mv	a0,s6
    80004cfc:	ffffc097          	auipc	ra,0xffffc
    80004d00:	752080e7          	jalr	1874(ra) # 8000144e <uvmalloc>
    80004d04:	8c2a                	mv	s8,a0
  ip = 0;
    80004d06:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004d08:	12050e63          	beqz	a0,80004e44 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004d0c:	75f9                	lui	a1,0xffffe
    80004d0e:	95aa                	add	a1,a1,a0
    80004d10:	855a                	mv	a0,s6
    80004d12:	ffffd097          	auipc	ra,0xffffd
    80004d16:	94e080e7          	jalr	-1714(ra) # 80001660 <uvmclear>
  stackbase = sp - PGSIZE;
    80004d1a:	7afd                	lui	s5,0xfffff
    80004d1c:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004d1e:	df043783          	ld	a5,-528(s0)
    80004d22:	6388                	ld	a0,0(a5)
    80004d24:	c925                	beqz	a0,80004d94 <exec+0x222>
    80004d26:	e8840993          	addi	s3,s0,-376
    80004d2a:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004d2e:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004d30:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004d32:	ffffc097          	auipc	ra,0xffffc
    80004d36:	110080e7          	jalr	272(ra) # 80000e42 <strlen>
    80004d3a:	0015079b          	addiw	a5,a0,1
    80004d3e:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004d42:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004d46:	13596363          	bltu	s2,s5,80004e6c <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004d4a:	df043d83          	ld	s11,-528(s0)
    80004d4e:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004d52:	8552                	mv	a0,s4
    80004d54:	ffffc097          	auipc	ra,0xffffc
    80004d58:	0ee080e7          	jalr	238(ra) # 80000e42 <strlen>
    80004d5c:	0015069b          	addiw	a3,a0,1
    80004d60:	8652                	mv	a2,s4
    80004d62:	85ca                	mv	a1,s2
    80004d64:	855a                	mv	a0,s6
    80004d66:	ffffd097          	auipc	ra,0xffffd
    80004d6a:	92c080e7          	jalr	-1748(ra) # 80001692 <copyout>
    80004d6e:	10054363          	bltz	a0,80004e74 <exec+0x302>
    ustack[argc] = sp;
    80004d72:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004d76:	0485                	addi	s1,s1,1
    80004d78:	008d8793          	addi	a5,s11,8
    80004d7c:	def43823          	sd	a5,-528(s0)
    80004d80:	008db503          	ld	a0,8(s11)
    80004d84:	c911                	beqz	a0,80004d98 <exec+0x226>
    if(argc >= MAXARG)
    80004d86:	09a1                	addi	s3,s3,8
    80004d88:	fb3c95e3          	bne	s9,s3,80004d32 <exec+0x1c0>
  sz = sz1;
    80004d8c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004d90:	4a81                	li	s5,0
    80004d92:	a84d                	j	80004e44 <exec+0x2d2>
  sp = sz;
    80004d94:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004d96:	4481                	li	s1,0
  ustack[argc] = 0;
    80004d98:	00349793          	slli	a5,s1,0x3
    80004d9c:	f9040713          	addi	a4,s0,-112
    80004da0:	97ba                	add	a5,a5,a4
    80004da2:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd8ef8>
  sp -= (argc+1) * sizeof(uint64);
    80004da6:	00148693          	addi	a3,s1,1
    80004daa:	068e                	slli	a3,a3,0x3
    80004dac:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004db0:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004db4:	01597663          	bgeu	s2,s5,80004dc0 <exec+0x24e>
  sz = sz1;
    80004db8:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004dbc:	4a81                	li	s5,0
    80004dbe:	a059                	j	80004e44 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004dc0:	e8840613          	addi	a2,s0,-376
    80004dc4:	85ca                	mv	a1,s2
    80004dc6:	855a                	mv	a0,s6
    80004dc8:	ffffd097          	auipc	ra,0xffffd
    80004dcc:	8ca080e7          	jalr	-1846(ra) # 80001692 <copyout>
    80004dd0:	0a054663          	bltz	a0,80004e7c <exec+0x30a>
  p->trapframe->a1 = sp;
    80004dd4:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80004dd8:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004ddc:	de843783          	ld	a5,-536(s0)
    80004de0:	0007c703          	lbu	a4,0(a5)
    80004de4:	cf11                	beqz	a4,80004e00 <exec+0x28e>
    80004de6:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004de8:	02f00693          	li	a3,47
    80004dec:	a039                	j	80004dfa <exec+0x288>
      last = s+1;
    80004dee:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004df2:	0785                	addi	a5,a5,1
    80004df4:	fff7c703          	lbu	a4,-1(a5)
    80004df8:	c701                	beqz	a4,80004e00 <exec+0x28e>
    if(*s == '/')
    80004dfa:	fed71ce3          	bne	a4,a3,80004df2 <exec+0x280>
    80004dfe:	bfc5                	j	80004dee <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80004e00:	4641                	li	a2,16
    80004e02:	de843583          	ld	a1,-536(s0)
    80004e06:	158b8513          	addi	a0,s7,344
    80004e0a:	ffffc097          	auipc	ra,0xffffc
    80004e0e:	006080e7          	jalr	6(ra) # 80000e10 <safestrcpy>
  oldpagetable = p->pagetable;
    80004e12:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004e16:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004e1a:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004e1e:	058bb783          	ld	a5,88(s7)
    80004e22:	e6043703          	ld	a4,-416(s0)
    80004e26:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004e28:	058bb783          	ld	a5,88(s7)
    80004e2c:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004e30:	85ea                	mv	a1,s10
    80004e32:	ffffd097          	auipc	ra,0xffffd
    80004e36:	d00080e7          	jalr	-768(ra) # 80001b32 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004e3a:	0004851b          	sext.w	a0,s1
    80004e3e:	bbc1                	j	80004c0e <exec+0x9c>
    80004e40:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004e44:	df843583          	ld	a1,-520(s0)
    80004e48:	855a                	mv	a0,s6
    80004e4a:	ffffd097          	auipc	ra,0xffffd
    80004e4e:	ce8080e7          	jalr	-792(ra) # 80001b32 <proc_freepagetable>
  if(ip){
    80004e52:	da0a94e3          	bnez	s5,80004bfa <exec+0x88>
  return -1;
    80004e56:	557d                	li	a0,-1
    80004e58:	bb5d                	j	80004c0e <exec+0x9c>
    80004e5a:	de943c23          	sd	s1,-520(s0)
    80004e5e:	b7dd                	j	80004e44 <exec+0x2d2>
    80004e60:	de943c23          	sd	s1,-520(s0)
    80004e64:	b7c5                	j	80004e44 <exec+0x2d2>
    80004e66:	de943c23          	sd	s1,-520(s0)
    80004e6a:	bfe9                	j	80004e44 <exec+0x2d2>
  sz = sz1;
    80004e6c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004e70:	4a81                	li	s5,0
    80004e72:	bfc9                	j	80004e44 <exec+0x2d2>
  sz = sz1;
    80004e74:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004e78:	4a81                	li	s5,0
    80004e7a:	b7e9                	j	80004e44 <exec+0x2d2>
  sz = sz1;
    80004e7c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004e80:	4a81                	li	s5,0
    80004e82:	b7c9                	j	80004e44 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004e84:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e88:	e0843783          	ld	a5,-504(s0)
    80004e8c:	0017869b          	addiw	a3,a5,1
    80004e90:	e0d43423          	sd	a3,-504(s0)
    80004e94:	e0043783          	ld	a5,-512(s0)
    80004e98:	0387879b          	addiw	a5,a5,56
    80004e9c:	e8045703          	lhu	a4,-384(s0)
    80004ea0:	e2e6d3e3          	bge	a3,a4,80004cc6 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004ea4:	2781                	sext.w	a5,a5
    80004ea6:	e0f43023          	sd	a5,-512(s0)
    80004eaa:	03800713          	li	a4,56
    80004eae:	86be                	mv	a3,a5
    80004eb0:	e1040613          	addi	a2,s0,-496
    80004eb4:	4581                	li	a1,0
    80004eb6:	8556                	mv	a0,s5
    80004eb8:	fffff097          	auipc	ra,0xfffff
    80004ebc:	a7a080e7          	jalr	-1414(ra) # 80003932 <readi>
    80004ec0:	03800793          	li	a5,56
    80004ec4:	f6f51ee3          	bne	a0,a5,80004e40 <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    80004ec8:	e1042783          	lw	a5,-496(s0)
    80004ecc:	4705                	li	a4,1
    80004ece:	fae79de3          	bne	a5,a4,80004e88 <exec+0x316>
    if(ph.memsz < ph.filesz)
    80004ed2:	e3843603          	ld	a2,-456(s0)
    80004ed6:	e3043783          	ld	a5,-464(s0)
    80004eda:	f8f660e3          	bltu	a2,a5,80004e5a <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004ede:	e2043783          	ld	a5,-480(s0)
    80004ee2:	963e                	add	a2,a2,a5
    80004ee4:	f6f66ee3          	bltu	a2,a5,80004e60 <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004ee8:	85a6                	mv	a1,s1
    80004eea:	855a                	mv	a0,s6
    80004eec:	ffffc097          	auipc	ra,0xffffc
    80004ef0:	562080e7          	jalr	1378(ra) # 8000144e <uvmalloc>
    80004ef4:	dea43c23          	sd	a0,-520(s0)
    80004ef8:	d53d                	beqz	a0,80004e66 <exec+0x2f4>
    if(ph.vaddr % PGSIZE != 0)
    80004efa:	e2043c03          	ld	s8,-480(s0)
    80004efe:	de043783          	ld	a5,-544(s0)
    80004f02:	00fc77b3          	and	a5,s8,a5
    80004f06:	ff9d                	bnez	a5,80004e44 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004f08:	e1842c83          	lw	s9,-488(s0)
    80004f0c:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004f10:	f60b8ae3          	beqz	s7,80004e84 <exec+0x312>
    80004f14:	89de                	mv	s3,s7
    80004f16:	4481                	li	s1,0
    80004f18:	b371                	j	80004ca4 <exec+0x132>

0000000080004f1a <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004f1a:	7179                	addi	sp,sp,-48
    80004f1c:	f406                	sd	ra,40(sp)
    80004f1e:	f022                	sd	s0,32(sp)
    80004f20:	ec26                	sd	s1,24(sp)
    80004f22:	e84a                	sd	s2,16(sp)
    80004f24:	1800                	addi	s0,sp,48
    80004f26:	892e                	mv	s2,a1
    80004f28:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80004f2a:	fdc40593          	addi	a1,s0,-36
    80004f2e:	ffffe097          	auipc	ra,0xffffe
    80004f32:	bd0080e7          	jalr	-1072(ra) # 80002afe <argint>
    80004f36:	04054063          	bltz	a0,80004f76 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004f3a:	fdc42703          	lw	a4,-36(s0)
    80004f3e:	47bd                	li	a5,15
    80004f40:	02e7ed63          	bltu	a5,a4,80004f7a <argfd+0x60>
    80004f44:	ffffd097          	auipc	ra,0xffffd
    80004f48:	a8e080e7          	jalr	-1394(ra) # 800019d2 <myproc>
    80004f4c:	fdc42703          	lw	a4,-36(s0)
    80004f50:	01a70793          	addi	a5,a4,26
    80004f54:	078e                	slli	a5,a5,0x3
    80004f56:	953e                	add	a0,a0,a5
    80004f58:	611c                	ld	a5,0(a0)
    80004f5a:	c395                	beqz	a5,80004f7e <argfd+0x64>
    return -1;
  if(pfd)
    80004f5c:	00090463          	beqz	s2,80004f64 <argfd+0x4a>
    *pfd = fd;
    80004f60:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004f64:	4501                	li	a0,0
  if(pf)
    80004f66:	c091                	beqz	s1,80004f6a <argfd+0x50>
    *pf = f;
    80004f68:	e09c                	sd	a5,0(s1)
}
    80004f6a:	70a2                	ld	ra,40(sp)
    80004f6c:	7402                	ld	s0,32(sp)
    80004f6e:	64e2                	ld	s1,24(sp)
    80004f70:	6942                	ld	s2,16(sp)
    80004f72:	6145                	addi	sp,sp,48
    80004f74:	8082                	ret
    return -1;
    80004f76:	557d                	li	a0,-1
    80004f78:	bfcd                	j	80004f6a <argfd+0x50>
    return -1;
    80004f7a:	557d                	li	a0,-1
    80004f7c:	b7fd                	j	80004f6a <argfd+0x50>
    80004f7e:	557d                	li	a0,-1
    80004f80:	b7ed                	j	80004f6a <argfd+0x50>

0000000080004f82 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004f82:	1101                	addi	sp,sp,-32
    80004f84:	ec06                	sd	ra,24(sp)
    80004f86:	e822                	sd	s0,16(sp)
    80004f88:	e426                	sd	s1,8(sp)
    80004f8a:	1000                	addi	s0,sp,32
    80004f8c:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80004f8e:	ffffd097          	auipc	ra,0xffffd
    80004f92:	a44080e7          	jalr	-1468(ra) # 800019d2 <myproc>
    80004f96:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80004f98:	0d050793          	addi	a5,a0,208
    80004f9c:	4501                	li	a0,0
    80004f9e:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80004fa0:	6398                	ld	a4,0(a5)
    80004fa2:	cb19                	beqz	a4,80004fb8 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80004fa4:	2505                	addiw	a0,a0,1
    80004fa6:	07a1                	addi	a5,a5,8
    80004fa8:	fed51ce3          	bne	a0,a3,80004fa0 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80004fac:	557d                	li	a0,-1
}
    80004fae:	60e2                	ld	ra,24(sp)
    80004fb0:	6442                	ld	s0,16(sp)
    80004fb2:	64a2                	ld	s1,8(sp)
    80004fb4:	6105                	addi	sp,sp,32
    80004fb6:	8082                	ret
      p->ofile[fd] = f;
    80004fb8:	01a50793          	addi	a5,a0,26
    80004fbc:	078e                	slli	a5,a5,0x3
    80004fbe:	963e                	add	a2,a2,a5
    80004fc0:	e204                	sd	s1,0(a2)
      return fd;
    80004fc2:	b7f5                	j	80004fae <fdalloc+0x2c>

0000000080004fc4 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80004fc4:	715d                	addi	sp,sp,-80
    80004fc6:	e486                	sd	ra,72(sp)
    80004fc8:	e0a2                	sd	s0,64(sp)
    80004fca:	fc26                	sd	s1,56(sp)
    80004fcc:	f84a                	sd	s2,48(sp)
    80004fce:	f44e                	sd	s3,40(sp)
    80004fd0:	f052                	sd	s4,32(sp)
    80004fd2:	ec56                	sd	s5,24(sp)
    80004fd4:	0880                	addi	s0,sp,80
    80004fd6:	89ae                	mv	s3,a1
    80004fd8:	8ab2                	mv	s5,a2
    80004fda:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80004fdc:	fb040593          	addi	a1,s0,-80
    80004fe0:	fffff097          	auipc	ra,0xfffff
    80004fe4:	e72080e7          	jalr	-398(ra) # 80003e52 <nameiparent>
    80004fe8:	892a                	mv	s2,a0
    80004fea:	12050e63          	beqz	a0,80005126 <create+0x162>
    return 0;

  ilock(dp);
    80004fee:	ffffe097          	auipc	ra,0xffffe
    80004ff2:	690080e7          	jalr	1680(ra) # 8000367e <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80004ff6:	4601                	li	a2,0
    80004ff8:	fb040593          	addi	a1,s0,-80
    80004ffc:	854a                	mv	a0,s2
    80004ffe:	fffff097          	auipc	ra,0xfffff
    80005002:	b64080e7          	jalr	-1180(ra) # 80003b62 <dirlookup>
    80005006:	84aa                	mv	s1,a0
    80005008:	c921                	beqz	a0,80005058 <create+0x94>
    iunlockput(dp);
    8000500a:	854a                	mv	a0,s2
    8000500c:	fffff097          	auipc	ra,0xfffff
    80005010:	8d4080e7          	jalr	-1836(ra) # 800038e0 <iunlockput>
    ilock(ip);
    80005014:	8526                	mv	a0,s1
    80005016:	ffffe097          	auipc	ra,0xffffe
    8000501a:	668080e7          	jalr	1640(ra) # 8000367e <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000501e:	2981                	sext.w	s3,s3
    80005020:	4789                	li	a5,2
    80005022:	02f99463          	bne	s3,a5,8000504a <create+0x86>
    80005026:	0444d783          	lhu	a5,68(s1)
    8000502a:	37f9                	addiw	a5,a5,-2
    8000502c:	17c2                	slli	a5,a5,0x30
    8000502e:	93c1                	srli	a5,a5,0x30
    80005030:	4705                	li	a4,1
    80005032:	00f76c63          	bltu	a4,a5,8000504a <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005036:	8526                	mv	a0,s1
    80005038:	60a6                	ld	ra,72(sp)
    8000503a:	6406                	ld	s0,64(sp)
    8000503c:	74e2                	ld	s1,56(sp)
    8000503e:	7942                	ld	s2,48(sp)
    80005040:	79a2                	ld	s3,40(sp)
    80005042:	7a02                	ld	s4,32(sp)
    80005044:	6ae2                	ld	s5,24(sp)
    80005046:	6161                	addi	sp,sp,80
    80005048:	8082                	ret
    iunlockput(ip);
    8000504a:	8526                	mv	a0,s1
    8000504c:	fffff097          	auipc	ra,0xfffff
    80005050:	894080e7          	jalr	-1900(ra) # 800038e0 <iunlockput>
    return 0;
    80005054:	4481                	li	s1,0
    80005056:	b7c5                	j	80005036 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005058:	85ce                	mv	a1,s3
    8000505a:	00092503          	lw	a0,0(s2)
    8000505e:	ffffe097          	auipc	ra,0xffffe
    80005062:	488080e7          	jalr	1160(ra) # 800034e6 <ialloc>
    80005066:	84aa                	mv	s1,a0
    80005068:	c521                	beqz	a0,800050b0 <create+0xec>
  ilock(ip);
    8000506a:	ffffe097          	auipc	ra,0xffffe
    8000506e:	614080e7          	jalr	1556(ra) # 8000367e <ilock>
  ip->major = major;
    80005072:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005076:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000507a:	4a05                	li	s4,1
    8000507c:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    80005080:	8526                	mv	a0,s1
    80005082:	ffffe097          	auipc	ra,0xffffe
    80005086:	532080e7          	jalr	1330(ra) # 800035b4 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000508a:	2981                	sext.w	s3,s3
    8000508c:	03498a63          	beq	s3,s4,800050c0 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005090:	40d0                	lw	a2,4(s1)
    80005092:	fb040593          	addi	a1,s0,-80
    80005096:	854a                	mv	a0,s2
    80005098:	fffff097          	auipc	ra,0xfffff
    8000509c:	cda080e7          	jalr	-806(ra) # 80003d72 <dirlink>
    800050a0:	06054b63          	bltz	a0,80005116 <create+0x152>
  iunlockput(dp);
    800050a4:	854a                	mv	a0,s2
    800050a6:	fffff097          	auipc	ra,0xfffff
    800050aa:	83a080e7          	jalr	-1990(ra) # 800038e0 <iunlockput>
  return ip;
    800050ae:	b761                	j	80005036 <create+0x72>
    panic("create: ialloc");
    800050b0:	00003517          	auipc	a0,0x3
    800050b4:	62850513          	addi	a0,a0,1576 # 800086d8 <syscalls+0x2a0>
    800050b8:	ffffb097          	auipc	ra,0xffffb
    800050bc:	472080e7          	jalr	1138(ra) # 8000052a <panic>
    dp->nlink++;  // for ".."
    800050c0:	04a95783          	lhu	a5,74(s2)
    800050c4:	2785                	addiw	a5,a5,1
    800050c6:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800050ca:	854a                	mv	a0,s2
    800050cc:	ffffe097          	auipc	ra,0xffffe
    800050d0:	4e8080e7          	jalr	1256(ra) # 800035b4 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800050d4:	40d0                	lw	a2,4(s1)
    800050d6:	00003597          	auipc	a1,0x3
    800050da:	61258593          	addi	a1,a1,1554 # 800086e8 <syscalls+0x2b0>
    800050de:	8526                	mv	a0,s1
    800050e0:	fffff097          	auipc	ra,0xfffff
    800050e4:	c92080e7          	jalr	-878(ra) # 80003d72 <dirlink>
    800050e8:	00054f63          	bltz	a0,80005106 <create+0x142>
    800050ec:	00492603          	lw	a2,4(s2)
    800050f0:	00003597          	auipc	a1,0x3
    800050f4:	60058593          	addi	a1,a1,1536 # 800086f0 <syscalls+0x2b8>
    800050f8:	8526                	mv	a0,s1
    800050fa:	fffff097          	auipc	ra,0xfffff
    800050fe:	c78080e7          	jalr	-904(ra) # 80003d72 <dirlink>
    80005102:	f80557e3          	bgez	a0,80005090 <create+0xcc>
      panic("create dots");
    80005106:	00003517          	auipc	a0,0x3
    8000510a:	5f250513          	addi	a0,a0,1522 # 800086f8 <syscalls+0x2c0>
    8000510e:	ffffb097          	auipc	ra,0xffffb
    80005112:	41c080e7          	jalr	1052(ra) # 8000052a <panic>
    panic("create: dirlink");
    80005116:	00003517          	auipc	a0,0x3
    8000511a:	5f250513          	addi	a0,a0,1522 # 80008708 <syscalls+0x2d0>
    8000511e:	ffffb097          	auipc	ra,0xffffb
    80005122:	40c080e7          	jalr	1036(ra) # 8000052a <panic>
    return 0;
    80005126:	84aa                	mv	s1,a0
    80005128:	b739                	j	80005036 <create+0x72>

000000008000512a <sys_dup>:
{
    8000512a:	7179                	addi	sp,sp,-48
    8000512c:	f406                	sd	ra,40(sp)
    8000512e:	f022                	sd	s0,32(sp)
    80005130:	ec26                	sd	s1,24(sp)
    80005132:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005134:	fd840613          	addi	a2,s0,-40
    80005138:	4581                	li	a1,0
    8000513a:	4501                	li	a0,0
    8000513c:	00000097          	auipc	ra,0x0
    80005140:	dde080e7          	jalr	-546(ra) # 80004f1a <argfd>
    return -1;
    80005144:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005146:	02054363          	bltz	a0,8000516c <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000514a:	fd843503          	ld	a0,-40(s0)
    8000514e:	00000097          	auipc	ra,0x0
    80005152:	e34080e7          	jalr	-460(ra) # 80004f82 <fdalloc>
    80005156:	84aa                	mv	s1,a0
    return -1;
    80005158:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000515a:	00054963          	bltz	a0,8000516c <sys_dup+0x42>
  filedup(f);
    8000515e:	fd843503          	ld	a0,-40(s0)
    80005162:	fffff097          	auipc	ra,0xfffff
    80005166:	36c080e7          	jalr	876(ra) # 800044ce <filedup>
  return fd;
    8000516a:	87a6                	mv	a5,s1
}
    8000516c:	853e                	mv	a0,a5
    8000516e:	70a2                	ld	ra,40(sp)
    80005170:	7402                	ld	s0,32(sp)
    80005172:	64e2                	ld	s1,24(sp)
    80005174:	6145                	addi	sp,sp,48
    80005176:	8082                	ret

0000000080005178 <sys_read>:
{
    80005178:	7179                	addi	sp,sp,-48
    8000517a:	f406                	sd	ra,40(sp)
    8000517c:	f022                	sd	s0,32(sp)
    8000517e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005180:	fe840613          	addi	a2,s0,-24
    80005184:	4581                	li	a1,0
    80005186:	4501                	li	a0,0
    80005188:	00000097          	auipc	ra,0x0
    8000518c:	d92080e7          	jalr	-622(ra) # 80004f1a <argfd>
    return -1;
    80005190:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005192:	04054163          	bltz	a0,800051d4 <sys_read+0x5c>
    80005196:	fe440593          	addi	a1,s0,-28
    8000519a:	4509                	li	a0,2
    8000519c:	ffffe097          	auipc	ra,0xffffe
    800051a0:	962080e7          	jalr	-1694(ra) # 80002afe <argint>
    return -1;
    800051a4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051a6:	02054763          	bltz	a0,800051d4 <sys_read+0x5c>
    800051aa:	fd840593          	addi	a1,s0,-40
    800051ae:	4505                	li	a0,1
    800051b0:	ffffe097          	auipc	ra,0xffffe
    800051b4:	970080e7          	jalr	-1680(ra) # 80002b20 <argaddr>
    return -1;
    800051b8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051ba:	00054d63          	bltz	a0,800051d4 <sys_read+0x5c>
  return fileread(f, p, n);
    800051be:	fe442603          	lw	a2,-28(s0)
    800051c2:	fd843583          	ld	a1,-40(s0)
    800051c6:	fe843503          	ld	a0,-24(s0)
    800051ca:	fffff097          	auipc	ra,0xfffff
    800051ce:	490080e7          	jalr	1168(ra) # 8000465a <fileread>
    800051d2:	87aa                	mv	a5,a0
}
    800051d4:	853e                	mv	a0,a5
    800051d6:	70a2                	ld	ra,40(sp)
    800051d8:	7402                	ld	s0,32(sp)
    800051da:	6145                	addi	sp,sp,48
    800051dc:	8082                	ret

00000000800051de <sys_write>:
{
    800051de:	7179                	addi	sp,sp,-48
    800051e0:	f406                	sd	ra,40(sp)
    800051e2:	f022                	sd	s0,32(sp)
    800051e4:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051e6:	fe840613          	addi	a2,s0,-24
    800051ea:	4581                	li	a1,0
    800051ec:	4501                	li	a0,0
    800051ee:	00000097          	auipc	ra,0x0
    800051f2:	d2c080e7          	jalr	-724(ra) # 80004f1a <argfd>
    return -1;
    800051f6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051f8:	04054163          	bltz	a0,8000523a <sys_write+0x5c>
    800051fc:	fe440593          	addi	a1,s0,-28
    80005200:	4509                	li	a0,2
    80005202:	ffffe097          	auipc	ra,0xffffe
    80005206:	8fc080e7          	jalr	-1796(ra) # 80002afe <argint>
    return -1;
    8000520a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000520c:	02054763          	bltz	a0,8000523a <sys_write+0x5c>
    80005210:	fd840593          	addi	a1,s0,-40
    80005214:	4505                	li	a0,1
    80005216:	ffffe097          	auipc	ra,0xffffe
    8000521a:	90a080e7          	jalr	-1782(ra) # 80002b20 <argaddr>
    return -1;
    8000521e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005220:	00054d63          	bltz	a0,8000523a <sys_write+0x5c>
  return filewrite(f, p, n);
    80005224:	fe442603          	lw	a2,-28(s0)
    80005228:	fd843583          	ld	a1,-40(s0)
    8000522c:	fe843503          	ld	a0,-24(s0)
    80005230:	fffff097          	auipc	ra,0xfffff
    80005234:	4ec080e7          	jalr	1260(ra) # 8000471c <filewrite>
    80005238:	87aa                	mv	a5,a0
}
    8000523a:	853e                	mv	a0,a5
    8000523c:	70a2                	ld	ra,40(sp)
    8000523e:	7402                	ld	s0,32(sp)
    80005240:	6145                	addi	sp,sp,48
    80005242:	8082                	ret

0000000080005244 <sys_close>:
{
    80005244:	1101                	addi	sp,sp,-32
    80005246:	ec06                	sd	ra,24(sp)
    80005248:	e822                	sd	s0,16(sp)
    8000524a:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000524c:	fe040613          	addi	a2,s0,-32
    80005250:	fec40593          	addi	a1,s0,-20
    80005254:	4501                	li	a0,0
    80005256:	00000097          	auipc	ra,0x0
    8000525a:	cc4080e7          	jalr	-828(ra) # 80004f1a <argfd>
    return -1;
    8000525e:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005260:	02054463          	bltz	a0,80005288 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005264:	ffffc097          	auipc	ra,0xffffc
    80005268:	76e080e7          	jalr	1902(ra) # 800019d2 <myproc>
    8000526c:	fec42783          	lw	a5,-20(s0)
    80005270:	07e9                	addi	a5,a5,26
    80005272:	078e                	slli	a5,a5,0x3
    80005274:	97aa                	add	a5,a5,a0
    80005276:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    8000527a:	fe043503          	ld	a0,-32(s0)
    8000527e:	fffff097          	auipc	ra,0xfffff
    80005282:	2a2080e7          	jalr	674(ra) # 80004520 <fileclose>
  return 0;
    80005286:	4781                	li	a5,0
}
    80005288:	853e                	mv	a0,a5
    8000528a:	60e2                	ld	ra,24(sp)
    8000528c:	6442                	ld	s0,16(sp)
    8000528e:	6105                	addi	sp,sp,32
    80005290:	8082                	ret

0000000080005292 <sys_fstat>:
{
    80005292:	1101                	addi	sp,sp,-32
    80005294:	ec06                	sd	ra,24(sp)
    80005296:	e822                	sd	s0,16(sp)
    80005298:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000529a:	fe840613          	addi	a2,s0,-24
    8000529e:	4581                	li	a1,0
    800052a0:	4501                	li	a0,0
    800052a2:	00000097          	auipc	ra,0x0
    800052a6:	c78080e7          	jalr	-904(ra) # 80004f1a <argfd>
    return -1;
    800052aa:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800052ac:	02054563          	bltz	a0,800052d6 <sys_fstat+0x44>
    800052b0:	fe040593          	addi	a1,s0,-32
    800052b4:	4505                	li	a0,1
    800052b6:	ffffe097          	auipc	ra,0xffffe
    800052ba:	86a080e7          	jalr	-1942(ra) # 80002b20 <argaddr>
    return -1;
    800052be:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800052c0:	00054b63          	bltz	a0,800052d6 <sys_fstat+0x44>
  return filestat(f, st);
    800052c4:	fe043583          	ld	a1,-32(s0)
    800052c8:	fe843503          	ld	a0,-24(s0)
    800052cc:	fffff097          	auipc	ra,0xfffff
    800052d0:	31c080e7          	jalr	796(ra) # 800045e8 <filestat>
    800052d4:	87aa                	mv	a5,a0
}
    800052d6:	853e                	mv	a0,a5
    800052d8:	60e2                	ld	ra,24(sp)
    800052da:	6442                	ld	s0,16(sp)
    800052dc:	6105                	addi	sp,sp,32
    800052de:	8082                	ret

00000000800052e0 <sys_link>:
{
    800052e0:	7169                	addi	sp,sp,-304
    800052e2:	f606                	sd	ra,296(sp)
    800052e4:	f222                	sd	s0,288(sp)
    800052e6:	ee26                	sd	s1,280(sp)
    800052e8:	ea4a                	sd	s2,272(sp)
    800052ea:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800052ec:	08000613          	li	a2,128
    800052f0:	ed040593          	addi	a1,s0,-304
    800052f4:	4501                	li	a0,0
    800052f6:	ffffe097          	auipc	ra,0xffffe
    800052fa:	84c080e7          	jalr	-1972(ra) # 80002b42 <argstr>
    return -1;
    800052fe:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005300:	10054e63          	bltz	a0,8000541c <sys_link+0x13c>
    80005304:	08000613          	li	a2,128
    80005308:	f5040593          	addi	a1,s0,-176
    8000530c:	4505                	li	a0,1
    8000530e:	ffffe097          	auipc	ra,0xffffe
    80005312:	834080e7          	jalr	-1996(ra) # 80002b42 <argstr>
    return -1;
    80005316:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005318:	10054263          	bltz	a0,8000541c <sys_link+0x13c>
  begin_op();
    8000531c:	fffff097          	auipc	ra,0xfffff
    80005320:	d38080e7          	jalr	-712(ra) # 80004054 <begin_op>
  if((ip = namei(old)) == 0){
    80005324:	ed040513          	addi	a0,s0,-304
    80005328:	fffff097          	auipc	ra,0xfffff
    8000532c:	b0c080e7          	jalr	-1268(ra) # 80003e34 <namei>
    80005330:	84aa                	mv	s1,a0
    80005332:	c551                	beqz	a0,800053be <sys_link+0xde>
  ilock(ip);
    80005334:	ffffe097          	auipc	ra,0xffffe
    80005338:	34a080e7          	jalr	842(ra) # 8000367e <ilock>
  if(ip->type == T_DIR){
    8000533c:	04449703          	lh	a4,68(s1)
    80005340:	4785                	li	a5,1
    80005342:	08f70463          	beq	a4,a5,800053ca <sys_link+0xea>
  ip->nlink++;
    80005346:	04a4d783          	lhu	a5,74(s1)
    8000534a:	2785                	addiw	a5,a5,1
    8000534c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005350:	8526                	mv	a0,s1
    80005352:	ffffe097          	auipc	ra,0xffffe
    80005356:	262080e7          	jalr	610(ra) # 800035b4 <iupdate>
  iunlock(ip);
    8000535a:	8526                	mv	a0,s1
    8000535c:	ffffe097          	auipc	ra,0xffffe
    80005360:	3e4080e7          	jalr	996(ra) # 80003740 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005364:	fd040593          	addi	a1,s0,-48
    80005368:	f5040513          	addi	a0,s0,-176
    8000536c:	fffff097          	auipc	ra,0xfffff
    80005370:	ae6080e7          	jalr	-1306(ra) # 80003e52 <nameiparent>
    80005374:	892a                	mv	s2,a0
    80005376:	c935                	beqz	a0,800053ea <sys_link+0x10a>
  ilock(dp);
    80005378:	ffffe097          	auipc	ra,0xffffe
    8000537c:	306080e7          	jalr	774(ra) # 8000367e <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005380:	00092703          	lw	a4,0(s2)
    80005384:	409c                	lw	a5,0(s1)
    80005386:	04f71d63          	bne	a4,a5,800053e0 <sys_link+0x100>
    8000538a:	40d0                	lw	a2,4(s1)
    8000538c:	fd040593          	addi	a1,s0,-48
    80005390:	854a                	mv	a0,s2
    80005392:	fffff097          	auipc	ra,0xfffff
    80005396:	9e0080e7          	jalr	-1568(ra) # 80003d72 <dirlink>
    8000539a:	04054363          	bltz	a0,800053e0 <sys_link+0x100>
  iunlockput(dp);
    8000539e:	854a                	mv	a0,s2
    800053a0:	ffffe097          	auipc	ra,0xffffe
    800053a4:	540080e7          	jalr	1344(ra) # 800038e0 <iunlockput>
  iput(ip);
    800053a8:	8526                	mv	a0,s1
    800053aa:	ffffe097          	auipc	ra,0xffffe
    800053ae:	48e080e7          	jalr	1166(ra) # 80003838 <iput>
  end_op();
    800053b2:	fffff097          	auipc	ra,0xfffff
    800053b6:	d22080e7          	jalr	-734(ra) # 800040d4 <end_op>
  return 0;
    800053ba:	4781                	li	a5,0
    800053bc:	a085                	j	8000541c <sys_link+0x13c>
    end_op();
    800053be:	fffff097          	auipc	ra,0xfffff
    800053c2:	d16080e7          	jalr	-746(ra) # 800040d4 <end_op>
    return -1;
    800053c6:	57fd                	li	a5,-1
    800053c8:	a891                	j	8000541c <sys_link+0x13c>
    iunlockput(ip);
    800053ca:	8526                	mv	a0,s1
    800053cc:	ffffe097          	auipc	ra,0xffffe
    800053d0:	514080e7          	jalr	1300(ra) # 800038e0 <iunlockput>
    end_op();
    800053d4:	fffff097          	auipc	ra,0xfffff
    800053d8:	d00080e7          	jalr	-768(ra) # 800040d4 <end_op>
    return -1;
    800053dc:	57fd                	li	a5,-1
    800053de:	a83d                	j	8000541c <sys_link+0x13c>
    iunlockput(dp);
    800053e0:	854a                	mv	a0,s2
    800053e2:	ffffe097          	auipc	ra,0xffffe
    800053e6:	4fe080e7          	jalr	1278(ra) # 800038e0 <iunlockput>
  ilock(ip);
    800053ea:	8526                	mv	a0,s1
    800053ec:	ffffe097          	auipc	ra,0xffffe
    800053f0:	292080e7          	jalr	658(ra) # 8000367e <ilock>
  ip->nlink--;
    800053f4:	04a4d783          	lhu	a5,74(s1)
    800053f8:	37fd                	addiw	a5,a5,-1
    800053fa:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800053fe:	8526                	mv	a0,s1
    80005400:	ffffe097          	auipc	ra,0xffffe
    80005404:	1b4080e7          	jalr	436(ra) # 800035b4 <iupdate>
  iunlockput(ip);
    80005408:	8526                	mv	a0,s1
    8000540a:	ffffe097          	auipc	ra,0xffffe
    8000540e:	4d6080e7          	jalr	1238(ra) # 800038e0 <iunlockput>
  end_op();
    80005412:	fffff097          	auipc	ra,0xfffff
    80005416:	cc2080e7          	jalr	-830(ra) # 800040d4 <end_op>
  return -1;
    8000541a:	57fd                	li	a5,-1
}
    8000541c:	853e                	mv	a0,a5
    8000541e:	70b2                	ld	ra,296(sp)
    80005420:	7412                	ld	s0,288(sp)
    80005422:	64f2                	ld	s1,280(sp)
    80005424:	6952                	ld	s2,272(sp)
    80005426:	6155                	addi	sp,sp,304
    80005428:	8082                	ret

000000008000542a <sys_unlink>:
{
    8000542a:	7151                	addi	sp,sp,-240
    8000542c:	f586                	sd	ra,232(sp)
    8000542e:	f1a2                	sd	s0,224(sp)
    80005430:	eda6                	sd	s1,216(sp)
    80005432:	e9ca                	sd	s2,208(sp)
    80005434:	e5ce                	sd	s3,200(sp)
    80005436:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005438:	08000613          	li	a2,128
    8000543c:	f3040593          	addi	a1,s0,-208
    80005440:	4501                	li	a0,0
    80005442:	ffffd097          	auipc	ra,0xffffd
    80005446:	700080e7          	jalr	1792(ra) # 80002b42 <argstr>
    8000544a:	18054163          	bltz	a0,800055cc <sys_unlink+0x1a2>
  begin_op();
    8000544e:	fffff097          	auipc	ra,0xfffff
    80005452:	c06080e7          	jalr	-1018(ra) # 80004054 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005456:	fb040593          	addi	a1,s0,-80
    8000545a:	f3040513          	addi	a0,s0,-208
    8000545e:	fffff097          	auipc	ra,0xfffff
    80005462:	9f4080e7          	jalr	-1548(ra) # 80003e52 <nameiparent>
    80005466:	84aa                	mv	s1,a0
    80005468:	c979                	beqz	a0,8000553e <sys_unlink+0x114>
  ilock(dp);
    8000546a:	ffffe097          	auipc	ra,0xffffe
    8000546e:	214080e7          	jalr	532(ra) # 8000367e <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005472:	00003597          	auipc	a1,0x3
    80005476:	27658593          	addi	a1,a1,630 # 800086e8 <syscalls+0x2b0>
    8000547a:	fb040513          	addi	a0,s0,-80
    8000547e:	ffffe097          	auipc	ra,0xffffe
    80005482:	6ca080e7          	jalr	1738(ra) # 80003b48 <namecmp>
    80005486:	14050a63          	beqz	a0,800055da <sys_unlink+0x1b0>
    8000548a:	00003597          	auipc	a1,0x3
    8000548e:	26658593          	addi	a1,a1,614 # 800086f0 <syscalls+0x2b8>
    80005492:	fb040513          	addi	a0,s0,-80
    80005496:	ffffe097          	auipc	ra,0xffffe
    8000549a:	6b2080e7          	jalr	1714(ra) # 80003b48 <namecmp>
    8000549e:	12050e63          	beqz	a0,800055da <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800054a2:	f2c40613          	addi	a2,s0,-212
    800054a6:	fb040593          	addi	a1,s0,-80
    800054aa:	8526                	mv	a0,s1
    800054ac:	ffffe097          	auipc	ra,0xffffe
    800054b0:	6b6080e7          	jalr	1718(ra) # 80003b62 <dirlookup>
    800054b4:	892a                	mv	s2,a0
    800054b6:	12050263          	beqz	a0,800055da <sys_unlink+0x1b0>
  ilock(ip);
    800054ba:	ffffe097          	auipc	ra,0xffffe
    800054be:	1c4080e7          	jalr	452(ra) # 8000367e <ilock>
  if(ip->nlink < 1)
    800054c2:	04a91783          	lh	a5,74(s2)
    800054c6:	08f05263          	blez	a5,8000554a <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800054ca:	04491703          	lh	a4,68(s2)
    800054ce:	4785                	li	a5,1
    800054d0:	08f70563          	beq	a4,a5,8000555a <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800054d4:	4641                	li	a2,16
    800054d6:	4581                	li	a1,0
    800054d8:	fc040513          	addi	a0,s0,-64
    800054dc:	ffffb097          	auipc	ra,0xffffb
    800054e0:	7e2080e7          	jalr	2018(ra) # 80000cbe <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800054e4:	4741                	li	a4,16
    800054e6:	f2c42683          	lw	a3,-212(s0)
    800054ea:	fc040613          	addi	a2,s0,-64
    800054ee:	4581                	li	a1,0
    800054f0:	8526                	mv	a0,s1
    800054f2:	ffffe097          	auipc	ra,0xffffe
    800054f6:	538080e7          	jalr	1336(ra) # 80003a2a <writei>
    800054fa:	47c1                	li	a5,16
    800054fc:	0af51563          	bne	a0,a5,800055a6 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005500:	04491703          	lh	a4,68(s2)
    80005504:	4785                	li	a5,1
    80005506:	0af70863          	beq	a4,a5,800055b6 <sys_unlink+0x18c>
  iunlockput(dp);
    8000550a:	8526                	mv	a0,s1
    8000550c:	ffffe097          	auipc	ra,0xffffe
    80005510:	3d4080e7          	jalr	980(ra) # 800038e0 <iunlockput>
  ip->nlink--;
    80005514:	04a95783          	lhu	a5,74(s2)
    80005518:	37fd                	addiw	a5,a5,-1
    8000551a:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000551e:	854a                	mv	a0,s2
    80005520:	ffffe097          	auipc	ra,0xffffe
    80005524:	094080e7          	jalr	148(ra) # 800035b4 <iupdate>
  iunlockput(ip);
    80005528:	854a                	mv	a0,s2
    8000552a:	ffffe097          	auipc	ra,0xffffe
    8000552e:	3b6080e7          	jalr	950(ra) # 800038e0 <iunlockput>
  end_op();
    80005532:	fffff097          	auipc	ra,0xfffff
    80005536:	ba2080e7          	jalr	-1118(ra) # 800040d4 <end_op>
  return 0;
    8000553a:	4501                	li	a0,0
    8000553c:	a84d                	j	800055ee <sys_unlink+0x1c4>
    end_op();
    8000553e:	fffff097          	auipc	ra,0xfffff
    80005542:	b96080e7          	jalr	-1130(ra) # 800040d4 <end_op>
    return -1;
    80005546:	557d                	li	a0,-1
    80005548:	a05d                	j	800055ee <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000554a:	00003517          	auipc	a0,0x3
    8000554e:	1ce50513          	addi	a0,a0,462 # 80008718 <syscalls+0x2e0>
    80005552:	ffffb097          	auipc	ra,0xffffb
    80005556:	fd8080e7          	jalr	-40(ra) # 8000052a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000555a:	04c92703          	lw	a4,76(s2)
    8000555e:	02000793          	li	a5,32
    80005562:	f6e7f9e3          	bgeu	a5,a4,800054d4 <sys_unlink+0xaa>
    80005566:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000556a:	4741                	li	a4,16
    8000556c:	86ce                	mv	a3,s3
    8000556e:	f1840613          	addi	a2,s0,-232
    80005572:	4581                	li	a1,0
    80005574:	854a                	mv	a0,s2
    80005576:	ffffe097          	auipc	ra,0xffffe
    8000557a:	3bc080e7          	jalr	956(ra) # 80003932 <readi>
    8000557e:	47c1                	li	a5,16
    80005580:	00f51b63          	bne	a0,a5,80005596 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005584:	f1845783          	lhu	a5,-232(s0)
    80005588:	e7a1                	bnez	a5,800055d0 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000558a:	29c1                	addiw	s3,s3,16
    8000558c:	04c92783          	lw	a5,76(s2)
    80005590:	fcf9ede3          	bltu	s3,a5,8000556a <sys_unlink+0x140>
    80005594:	b781                	j	800054d4 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005596:	00003517          	auipc	a0,0x3
    8000559a:	19a50513          	addi	a0,a0,410 # 80008730 <syscalls+0x2f8>
    8000559e:	ffffb097          	auipc	ra,0xffffb
    800055a2:	f8c080e7          	jalr	-116(ra) # 8000052a <panic>
    panic("unlink: writei");
    800055a6:	00003517          	auipc	a0,0x3
    800055aa:	1a250513          	addi	a0,a0,418 # 80008748 <syscalls+0x310>
    800055ae:	ffffb097          	auipc	ra,0xffffb
    800055b2:	f7c080e7          	jalr	-132(ra) # 8000052a <panic>
    dp->nlink--;
    800055b6:	04a4d783          	lhu	a5,74(s1)
    800055ba:	37fd                	addiw	a5,a5,-1
    800055bc:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800055c0:	8526                	mv	a0,s1
    800055c2:	ffffe097          	auipc	ra,0xffffe
    800055c6:	ff2080e7          	jalr	-14(ra) # 800035b4 <iupdate>
    800055ca:	b781                	j	8000550a <sys_unlink+0xe0>
    return -1;
    800055cc:	557d                	li	a0,-1
    800055ce:	a005                	j	800055ee <sys_unlink+0x1c4>
    iunlockput(ip);
    800055d0:	854a                	mv	a0,s2
    800055d2:	ffffe097          	auipc	ra,0xffffe
    800055d6:	30e080e7          	jalr	782(ra) # 800038e0 <iunlockput>
  iunlockput(dp);
    800055da:	8526                	mv	a0,s1
    800055dc:	ffffe097          	auipc	ra,0xffffe
    800055e0:	304080e7          	jalr	772(ra) # 800038e0 <iunlockput>
  end_op();
    800055e4:	fffff097          	auipc	ra,0xfffff
    800055e8:	af0080e7          	jalr	-1296(ra) # 800040d4 <end_op>
  return -1;
    800055ec:	557d                	li	a0,-1
}
    800055ee:	70ae                	ld	ra,232(sp)
    800055f0:	740e                	ld	s0,224(sp)
    800055f2:	64ee                	ld	s1,216(sp)
    800055f4:	694e                	ld	s2,208(sp)
    800055f6:	69ae                	ld	s3,200(sp)
    800055f8:	616d                	addi	sp,sp,240
    800055fa:	8082                	ret

00000000800055fc <sys_open>:

uint64
sys_open(void)
{
    800055fc:	7131                	addi	sp,sp,-192
    800055fe:	fd06                	sd	ra,184(sp)
    80005600:	f922                	sd	s0,176(sp)
    80005602:	f526                	sd	s1,168(sp)
    80005604:	f14a                	sd	s2,160(sp)
    80005606:	ed4e                	sd	s3,152(sp)
    80005608:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000560a:	08000613          	li	a2,128
    8000560e:	f5040593          	addi	a1,s0,-176
    80005612:	4501                	li	a0,0
    80005614:	ffffd097          	auipc	ra,0xffffd
    80005618:	52e080e7          	jalr	1326(ra) # 80002b42 <argstr>
    return -1;
    8000561c:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000561e:	0c054163          	bltz	a0,800056e0 <sys_open+0xe4>
    80005622:	f4c40593          	addi	a1,s0,-180
    80005626:	4505                	li	a0,1
    80005628:	ffffd097          	auipc	ra,0xffffd
    8000562c:	4d6080e7          	jalr	1238(ra) # 80002afe <argint>
    80005630:	0a054863          	bltz	a0,800056e0 <sys_open+0xe4>

  begin_op();
    80005634:	fffff097          	auipc	ra,0xfffff
    80005638:	a20080e7          	jalr	-1504(ra) # 80004054 <begin_op>

  if(omode & O_CREATE){
    8000563c:	f4c42783          	lw	a5,-180(s0)
    80005640:	2007f793          	andi	a5,a5,512
    80005644:	cbdd                	beqz	a5,800056fa <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005646:	4681                	li	a3,0
    80005648:	4601                	li	a2,0
    8000564a:	4589                	li	a1,2
    8000564c:	f5040513          	addi	a0,s0,-176
    80005650:	00000097          	auipc	ra,0x0
    80005654:	974080e7          	jalr	-1676(ra) # 80004fc4 <create>
    80005658:	892a                	mv	s2,a0
    if(ip == 0){
    8000565a:	c959                	beqz	a0,800056f0 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000565c:	04491703          	lh	a4,68(s2)
    80005660:	478d                	li	a5,3
    80005662:	00f71763          	bne	a4,a5,80005670 <sys_open+0x74>
    80005666:	04695703          	lhu	a4,70(s2)
    8000566a:	47a5                	li	a5,9
    8000566c:	0ce7ec63          	bltu	a5,a4,80005744 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005670:	fffff097          	auipc	ra,0xfffff
    80005674:	df4080e7          	jalr	-524(ra) # 80004464 <filealloc>
    80005678:	89aa                	mv	s3,a0
    8000567a:	10050263          	beqz	a0,8000577e <sys_open+0x182>
    8000567e:	00000097          	auipc	ra,0x0
    80005682:	904080e7          	jalr	-1788(ra) # 80004f82 <fdalloc>
    80005686:	84aa                	mv	s1,a0
    80005688:	0e054663          	bltz	a0,80005774 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000568c:	04491703          	lh	a4,68(s2)
    80005690:	478d                	li	a5,3
    80005692:	0cf70463          	beq	a4,a5,8000575a <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005696:	4789                	li	a5,2
    80005698:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    8000569c:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800056a0:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800056a4:	f4c42783          	lw	a5,-180(s0)
    800056a8:	0017c713          	xori	a4,a5,1
    800056ac:	8b05                	andi	a4,a4,1
    800056ae:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800056b2:	0037f713          	andi	a4,a5,3
    800056b6:	00e03733          	snez	a4,a4
    800056ba:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800056be:	4007f793          	andi	a5,a5,1024
    800056c2:	c791                	beqz	a5,800056ce <sys_open+0xd2>
    800056c4:	04491703          	lh	a4,68(s2)
    800056c8:	4789                	li	a5,2
    800056ca:	08f70f63          	beq	a4,a5,80005768 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800056ce:	854a                	mv	a0,s2
    800056d0:	ffffe097          	auipc	ra,0xffffe
    800056d4:	070080e7          	jalr	112(ra) # 80003740 <iunlock>
  end_op();
    800056d8:	fffff097          	auipc	ra,0xfffff
    800056dc:	9fc080e7          	jalr	-1540(ra) # 800040d4 <end_op>

  return fd;
}
    800056e0:	8526                	mv	a0,s1
    800056e2:	70ea                	ld	ra,184(sp)
    800056e4:	744a                	ld	s0,176(sp)
    800056e6:	74aa                	ld	s1,168(sp)
    800056e8:	790a                	ld	s2,160(sp)
    800056ea:	69ea                	ld	s3,152(sp)
    800056ec:	6129                	addi	sp,sp,192
    800056ee:	8082                	ret
      end_op();
    800056f0:	fffff097          	auipc	ra,0xfffff
    800056f4:	9e4080e7          	jalr	-1564(ra) # 800040d4 <end_op>
      return -1;
    800056f8:	b7e5                	j	800056e0 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800056fa:	f5040513          	addi	a0,s0,-176
    800056fe:	ffffe097          	auipc	ra,0xffffe
    80005702:	736080e7          	jalr	1846(ra) # 80003e34 <namei>
    80005706:	892a                	mv	s2,a0
    80005708:	c905                	beqz	a0,80005738 <sys_open+0x13c>
    ilock(ip);
    8000570a:	ffffe097          	auipc	ra,0xffffe
    8000570e:	f74080e7          	jalr	-140(ra) # 8000367e <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005712:	04491703          	lh	a4,68(s2)
    80005716:	4785                	li	a5,1
    80005718:	f4f712e3          	bne	a4,a5,8000565c <sys_open+0x60>
    8000571c:	f4c42783          	lw	a5,-180(s0)
    80005720:	dba1                	beqz	a5,80005670 <sys_open+0x74>
      iunlockput(ip);
    80005722:	854a                	mv	a0,s2
    80005724:	ffffe097          	auipc	ra,0xffffe
    80005728:	1bc080e7          	jalr	444(ra) # 800038e0 <iunlockput>
      end_op();
    8000572c:	fffff097          	auipc	ra,0xfffff
    80005730:	9a8080e7          	jalr	-1624(ra) # 800040d4 <end_op>
      return -1;
    80005734:	54fd                	li	s1,-1
    80005736:	b76d                	j	800056e0 <sys_open+0xe4>
      end_op();
    80005738:	fffff097          	auipc	ra,0xfffff
    8000573c:	99c080e7          	jalr	-1636(ra) # 800040d4 <end_op>
      return -1;
    80005740:	54fd                	li	s1,-1
    80005742:	bf79                	j	800056e0 <sys_open+0xe4>
    iunlockput(ip);
    80005744:	854a                	mv	a0,s2
    80005746:	ffffe097          	auipc	ra,0xffffe
    8000574a:	19a080e7          	jalr	410(ra) # 800038e0 <iunlockput>
    end_op();
    8000574e:	fffff097          	auipc	ra,0xfffff
    80005752:	986080e7          	jalr	-1658(ra) # 800040d4 <end_op>
    return -1;
    80005756:	54fd                	li	s1,-1
    80005758:	b761                	j	800056e0 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000575a:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    8000575e:	04691783          	lh	a5,70(s2)
    80005762:	02f99223          	sh	a5,36(s3)
    80005766:	bf2d                	j	800056a0 <sys_open+0xa4>
    itrunc(ip);
    80005768:	854a                	mv	a0,s2
    8000576a:	ffffe097          	auipc	ra,0xffffe
    8000576e:	022080e7          	jalr	34(ra) # 8000378c <itrunc>
    80005772:	bfb1                	j	800056ce <sys_open+0xd2>
      fileclose(f);
    80005774:	854e                	mv	a0,s3
    80005776:	fffff097          	auipc	ra,0xfffff
    8000577a:	daa080e7          	jalr	-598(ra) # 80004520 <fileclose>
    iunlockput(ip);
    8000577e:	854a                	mv	a0,s2
    80005780:	ffffe097          	auipc	ra,0xffffe
    80005784:	160080e7          	jalr	352(ra) # 800038e0 <iunlockput>
    end_op();
    80005788:	fffff097          	auipc	ra,0xfffff
    8000578c:	94c080e7          	jalr	-1716(ra) # 800040d4 <end_op>
    return -1;
    80005790:	54fd                	li	s1,-1
    80005792:	b7b9                	j	800056e0 <sys_open+0xe4>

0000000080005794 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005794:	7175                	addi	sp,sp,-144
    80005796:	e506                	sd	ra,136(sp)
    80005798:	e122                	sd	s0,128(sp)
    8000579a:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000579c:	fffff097          	auipc	ra,0xfffff
    800057a0:	8b8080e7          	jalr	-1864(ra) # 80004054 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800057a4:	08000613          	li	a2,128
    800057a8:	f7040593          	addi	a1,s0,-144
    800057ac:	4501                	li	a0,0
    800057ae:	ffffd097          	auipc	ra,0xffffd
    800057b2:	394080e7          	jalr	916(ra) # 80002b42 <argstr>
    800057b6:	02054963          	bltz	a0,800057e8 <sys_mkdir+0x54>
    800057ba:	4681                	li	a3,0
    800057bc:	4601                	li	a2,0
    800057be:	4585                	li	a1,1
    800057c0:	f7040513          	addi	a0,s0,-144
    800057c4:	00000097          	auipc	ra,0x0
    800057c8:	800080e7          	jalr	-2048(ra) # 80004fc4 <create>
    800057cc:	cd11                	beqz	a0,800057e8 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800057ce:	ffffe097          	auipc	ra,0xffffe
    800057d2:	112080e7          	jalr	274(ra) # 800038e0 <iunlockput>
  end_op();
    800057d6:	fffff097          	auipc	ra,0xfffff
    800057da:	8fe080e7          	jalr	-1794(ra) # 800040d4 <end_op>
  return 0;
    800057de:	4501                	li	a0,0
}
    800057e0:	60aa                	ld	ra,136(sp)
    800057e2:	640a                	ld	s0,128(sp)
    800057e4:	6149                	addi	sp,sp,144
    800057e6:	8082                	ret
    end_op();
    800057e8:	fffff097          	auipc	ra,0xfffff
    800057ec:	8ec080e7          	jalr	-1812(ra) # 800040d4 <end_op>
    return -1;
    800057f0:	557d                	li	a0,-1
    800057f2:	b7fd                	j	800057e0 <sys_mkdir+0x4c>

00000000800057f4 <sys_mknod>:

uint64
sys_mknod(void)
{
    800057f4:	7135                	addi	sp,sp,-160
    800057f6:	ed06                	sd	ra,152(sp)
    800057f8:	e922                	sd	s0,144(sp)
    800057fa:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800057fc:	fffff097          	auipc	ra,0xfffff
    80005800:	858080e7          	jalr	-1960(ra) # 80004054 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005804:	08000613          	li	a2,128
    80005808:	f7040593          	addi	a1,s0,-144
    8000580c:	4501                	li	a0,0
    8000580e:	ffffd097          	auipc	ra,0xffffd
    80005812:	334080e7          	jalr	820(ra) # 80002b42 <argstr>
    80005816:	04054a63          	bltz	a0,8000586a <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    8000581a:	f6c40593          	addi	a1,s0,-148
    8000581e:	4505                	li	a0,1
    80005820:	ffffd097          	auipc	ra,0xffffd
    80005824:	2de080e7          	jalr	734(ra) # 80002afe <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005828:	04054163          	bltz	a0,8000586a <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    8000582c:	f6840593          	addi	a1,s0,-152
    80005830:	4509                	li	a0,2
    80005832:	ffffd097          	auipc	ra,0xffffd
    80005836:	2cc080e7          	jalr	716(ra) # 80002afe <argint>
     argint(1, &major) < 0 ||
    8000583a:	02054863          	bltz	a0,8000586a <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000583e:	f6841683          	lh	a3,-152(s0)
    80005842:	f6c41603          	lh	a2,-148(s0)
    80005846:	458d                	li	a1,3
    80005848:	f7040513          	addi	a0,s0,-144
    8000584c:	fffff097          	auipc	ra,0xfffff
    80005850:	778080e7          	jalr	1912(ra) # 80004fc4 <create>
     argint(2, &minor) < 0 ||
    80005854:	c919                	beqz	a0,8000586a <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005856:	ffffe097          	auipc	ra,0xffffe
    8000585a:	08a080e7          	jalr	138(ra) # 800038e0 <iunlockput>
  end_op();
    8000585e:	fffff097          	auipc	ra,0xfffff
    80005862:	876080e7          	jalr	-1930(ra) # 800040d4 <end_op>
  return 0;
    80005866:	4501                	li	a0,0
    80005868:	a031                	j	80005874 <sys_mknod+0x80>
    end_op();
    8000586a:	fffff097          	auipc	ra,0xfffff
    8000586e:	86a080e7          	jalr	-1942(ra) # 800040d4 <end_op>
    return -1;
    80005872:	557d                	li	a0,-1
}
    80005874:	60ea                	ld	ra,152(sp)
    80005876:	644a                	ld	s0,144(sp)
    80005878:	610d                	addi	sp,sp,160
    8000587a:	8082                	ret

000000008000587c <sys_chdir>:

uint64
sys_chdir(void)
{
    8000587c:	7135                	addi	sp,sp,-160
    8000587e:	ed06                	sd	ra,152(sp)
    80005880:	e922                	sd	s0,144(sp)
    80005882:	e526                	sd	s1,136(sp)
    80005884:	e14a                	sd	s2,128(sp)
    80005886:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005888:	ffffc097          	auipc	ra,0xffffc
    8000588c:	14a080e7          	jalr	330(ra) # 800019d2 <myproc>
    80005890:	892a                	mv	s2,a0
  
  begin_op();
    80005892:	ffffe097          	auipc	ra,0xffffe
    80005896:	7c2080e7          	jalr	1986(ra) # 80004054 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    8000589a:	08000613          	li	a2,128
    8000589e:	f6040593          	addi	a1,s0,-160
    800058a2:	4501                	li	a0,0
    800058a4:	ffffd097          	auipc	ra,0xffffd
    800058a8:	29e080e7          	jalr	670(ra) # 80002b42 <argstr>
    800058ac:	04054b63          	bltz	a0,80005902 <sys_chdir+0x86>
    800058b0:	f6040513          	addi	a0,s0,-160
    800058b4:	ffffe097          	auipc	ra,0xffffe
    800058b8:	580080e7          	jalr	1408(ra) # 80003e34 <namei>
    800058bc:	84aa                	mv	s1,a0
    800058be:	c131                	beqz	a0,80005902 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800058c0:	ffffe097          	auipc	ra,0xffffe
    800058c4:	dbe080e7          	jalr	-578(ra) # 8000367e <ilock>
  if(ip->type != T_DIR){
    800058c8:	04449703          	lh	a4,68(s1)
    800058cc:	4785                	li	a5,1
    800058ce:	04f71063          	bne	a4,a5,8000590e <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800058d2:	8526                	mv	a0,s1
    800058d4:	ffffe097          	auipc	ra,0xffffe
    800058d8:	e6c080e7          	jalr	-404(ra) # 80003740 <iunlock>
  iput(p->cwd);
    800058dc:	15093503          	ld	a0,336(s2)
    800058e0:	ffffe097          	auipc	ra,0xffffe
    800058e4:	f58080e7          	jalr	-168(ra) # 80003838 <iput>
  end_op();
    800058e8:	ffffe097          	auipc	ra,0xffffe
    800058ec:	7ec080e7          	jalr	2028(ra) # 800040d4 <end_op>
  p->cwd = ip;
    800058f0:	14993823          	sd	s1,336(s2)
  return 0;
    800058f4:	4501                	li	a0,0
}
    800058f6:	60ea                	ld	ra,152(sp)
    800058f8:	644a                	ld	s0,144(sp)
    800058fa:	64aa                	ld	s1,136(sp)
    800058fc:	690a                	ld	s2,128(sp)
    800058fe:	610d                	addi	sp,sp,160
    80005900:	8082                	ret
    end_op();
    80005902:	ffffe097          	auipc	ra,0xffffe
    80005906:	7d2080e7          	jalr	2002(ra) # 800040d4 <end_op>
    return -1;
    8000590a:	557d                	li	a0,-1
    8000590c:	b7ed                	j	800058f6 <sys_chdir+0x7a>
    iunlockput(ip);
    8000590e:	8526                	mv	a0,s1
    80005910:	ffffe097          	auipc	ra,0xffffe
    80005914:	fd0080e7          	jalr	-48(ra) # 800038e0 <iunlockput>
    end_op();
    80005918:	ffffe097          	auipc	ra,0xffffe
    8000591c:	7bc080e7          	jalr	1980(ra) # 800040d4 <end_op>
    return -1;
    80005920:	557d                	li	a0,-1
    80005922:	bfd1                	j	800058f6 <sys_chdir+0x7a>

0000000080005924 <sys_exec>:

uint64
sys_exec(void)
{
    80005924:	7145                	addi	sp,sp,-464
    80005926:	e786                	sd	ra,456(sp)
    80005928:	e3a2                	sd	s0,448(sp)
    8000592a:	ff26                	sd	s1,440(sp)
    8000592c:	fb4a                	sd	s2,432(sp)
    8000592e:	f74e                	sd	s3,424(sp)
    80005930:	f352                	sd	s4,416(sp)
    80005932:	ef56                	sd	s5,408(sp)
    80005934:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005936:	08000613          	li	a2,128
    8000593a:	f4040593          	addi	a1,s0,-192
    8000593e:	4501                	li	a0,0
    80005940:	ffffd097          	auipc	ra,0xffffd
    80005944:	202080e7          	jalr	514(ra) # 80002b42 <argstr>
    return -1;
    80005948:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    8000594a:	0c054a63          	bltz	a0,80005a1e <sys_exec+0xfa>
    8000594e:	e3840593          	addi	a1,s0,-456
    80005952:	4505                	li	a0,1
    80005954:	ffffd097          	auipc	ra,0xffffd
    80005958:	1cc080e7          	jalr	460(ra) # 80002b20 <argaddr>
    8000595c:	0c054163          	bltz	a0,80005a1e <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005960:	10000613          	li	a2,256
    80005964:	4581                	li	a1,0
    80005966:	e4040513          	addi	a0,s0,-448
    8000596a:	ffffb097          	auipc	ra,0xffffb
    8000596e:	354080e7          	jalr	852(ra) # 80000cbe <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005972:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005976:	89a6                	mv	s3,s1
    80005978:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    8000597a:	02000a13          	li	s4,32
    8000597e:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005982:	00391793          	slli	a5,s2,0x3
    80005986:	e3040593          	addi	a1,s0,-464
    8000598a:	e3843503          	ld	a0,-456(s0)
    8000598e:	953e                	add	a0,a0,a5
    80005990:	ffffd097          	auipc	ra,0xffffd
    80005994:	0d4080e7          	jalr	212(ra) # 80002a64 <fetchaddr>
    80005998:	02054a63          	bltz	a0,800059cc <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    8000599c:	e3043783          	ld	a5,-464(s0)
    800059a0:	c3b9                	beqz	a5,800059e6 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800059a2:	ffffb097          	auipc	ra,0xffffb
    800059a6:	130080e7          	jalr	304(ra) # 80000ad2 <kalloc>
    800059aa:	85aa                	mv	a1,a0
    800059ac:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800059b0:	cd11                	beqz	a0,800059cc <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800059b2:	6605                	lui	a2,0x1
    800059b4:	e3043503          	ld	a0,-464(s0)
    800059b8:	ffffd097          	auipc	ra,0xffffd
    800059bc:	0fe080e7          	jalr	254(ra) # 80002ab6 <fetchstr>
    800059c0:	00054663          	bltz	a0,800059cc <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    800059c4:	0905                	addi	s2,s2,1
    800059c6:	09a1                	addi	s3,s3,8
    800059c8:	fb491be3          	bne	s2,s4,8000597e <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800059cc:	10048913          	addi	s2,s1,256
    800059d0:	6088                	ld	a0,0(s1)
    800059d2:	c529                	beqz	a0,80005a1c <sys_exec+0xf8>
    kfree(argv[i]);
    800059d4:	ffffb097          	auipc	ra,0xffffb
    800059d8:	002080e7          	jalr	2(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800059dc:	04a1                	addi	s1,s1,8
    800059de:	ff2499e3          	bne	s1,s2,800059d0 <sys_exec+0xac>
  return -1;
    800059e2:	597d                	li	s2,-1
    800059e4:	a82d                	j	80005a1e <sys_exec+0xfa>
      argv[i] = 0;
    800059e6:	0a8e                	slli	s5,s5,0x3
    800059e8:	fc040793          	addi	a5,s0,-64
    800059ec:	9abe                	add	s5,s5,a5
    800059ee:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ffd8e80>
  int ret = exec(path, argv);
    800059f2:	e4040593          	addi	a1,s0,-448
    800059f6:	f4040513          	addi	a0,s0,-192
    800059fa:	fffff097          	auipc	ra,0xfffff
    800059fe:	178080e7          	jalr	376(ra) # 80004b72 <exec>
    80005a02:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a04:	10048993          	addi	s3,s1,256
    80005a08:	6088                	ld	a0,0(s1)
    80005a0a:	c911                	beqz	a0,80005a1e <sys_exec+0xfa>
    kfree(argv[i]);
    80005a0c:	ffffb097          	auipc	ra,0xffffb
    80005a10:	fca080e7          	jalr	-54(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a14:	04a1                	addi	s1,s1,8
    80005a16:	ff3499e3          	bne	s1,s3,80005a08 <sys_exec+0xe4>
    80005a1a:	a011                	j	80005a1e <sys_exec+0xfa>
  return -1;
    80005a1c:	597d                	li	s2,-1
}
    80005a1e:	854a                	mv	a0,s2
    80005a20:	60be                	ld	ra,456(sp)
    80005a22:	641e                	ld	s0,448(sp)
    80005a24:	74fa                	ld	s1,440(sp)
    80005a26:	795a                	ld	s2,432(sp)
    80005a28:	79ba                	ld	s3,424(sp)
    80005a2a:	7a1a                	ld	s4,416(sp)
    80005a2c:	6afa                	ld	s5,408(sp)
    80005a2e:	6179                	addi	sp,sp,464
    80005a30:	8082                	ret

0000000080005a32 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005a32:	7139                	addi	sp,sp,-64
    80005a34:	fc06                	sd	ra,56(sp)
    80005a36:	f822                	sd	s0,48(sp)
    80005a38:	f426                	sd	s1,40(sp)
    80005a3a:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005a3c:	ffffc097          	auipc	ra,0xffffc
    80005a40:	f96080e7          	jalr	-106(ra) # 800019d2 <myproc>
    80005a44:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005a46:	fd840593          	addi	a1,s0,-40
    80005a4a:	4501                	li	a0,0
    80005a4c:	ffffd097          	auipc	ra,0xffffd
    80005a50:	0d4080e7          	jalr	212(ra) # 80002b20 <argaddr>
    return -1;
    80005a54:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005a56:	0e054063          	bltz	a0,80005b36 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005a5a:	fc840593          	addi	a1,s0,-56
    80005a5e:	fd040513          	addi	a0,s0,-48
    80005a62:	fffff097          	auipc	ra,0xfffff
    80005a66:	dee080e7          	jalr	-530(ra) # 80004850 <pipealloc>
    return -1;
    80005a6a:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005a6c:	0c054563          	bltz	a0,80005b36 <sys_pipe+0x104>
  fd0 = -1;
    80005a70:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005a74:	fd043503          	ld	a0,-48(s0)
    80005a78:	fffff097          	auipc	ra,0xfffff
    80005a7c:	50a080e7          	jalr	1290(ra) # 80004f82 <fdalloc>
    80005a80:	fca42223          	sw	a0,-60(s0)
    80005a84:	08054c63          	bltz	a0,80005b1c <sys_pipe+0xea>
    80005a88:	fc843503          	ld	a0,-56(s0)
    80005a8c:	fffff097          	auipc	ra,0xfffff
    80005a90:	4f6080e7          	jalr	1270(ra) # 80004f82 <fdalloc>
    80005a94:	fca42023          	sw	a0,-64(s0)
    80005a98:	06054863          	bltz	a0,80005b08 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005a9c:	4691                	li	a3,4
    80005a9e:	fc440613          	addi	a2,s0,-60
    80005aa2:	fd843583          	ld	a1,-40(s0)
    80005aa6:	68a8                	ld	a0,80(s1)
    80005aa8:	ffffc097          	auipc	ra,0xffffc
    80005aac:	bea080e7          	jalr	-1046(ra) # 80001692 <copyout>
    80005ab0:	02054063          	bltz	a0,80005ad0 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005ab4:	4691                	li	a3,4
    80005ab6:	fc040613          	addi	a2,s0,-64
    80005aba:	fd843583          	ld	a1,-40(s0)
    80005abe:	0591                	addi	a1,a1,4
    80005ac0:	68a8                	ld	a0,80(s1)
    80005ac2:	ffffc097          	auipc	ra,0xffffc
    80005ac6:	bd0080e7          	jalr	-1072(ra) # 80001692 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005aca:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005acc:	06055563          	bgez	a0,80005b36 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005ad0:	fc442783          	lw	a5,-60(s0)
    80005ad4:	07e9                	addi	a5,a5,26
    80005ad6:	078e                	slli	a5,a5,0x3
    80005ad8:	97a6                	add	a5,a5,s1
    80005ada:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005ade:	fc042503          	lw	a0,-64(s0)
    80005ae2:	0569                	addi	a0,a0,26
    80005ae4:	050e                	slli	a0,a0,0x3
    80005ae6:	9526                	add	a0,a0,s1
    80005ae8:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005aec:	fd043503          	ld	a0,-48(s0)
    80005af0:	fffff097          	auipc	ra,0xfffff
    80005af4:	a30080e7          	jalr	-1488(ra) # 80004520 <fileclose>
    fileclose(wf);
    80005af8:	fc843503          	ld	a0,-56(s0)
    80005afc:	fffff097          	auipc	ra,0xfffff
    80005b00:	a24080e7          	jalr	-1500(ra) # 80004520 <fileclose>
    return -1;
    80005b04:	57fd                	li	a5,-1
    80005b06:	a805                	j	80005b36 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005b08:	fc442783          	lw	a5,-60(s0)
    80005b0c:	0007c863          	bltz	a5,80005b1c <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005b10:	01a78513          	addi	a0,a5,26
    80005b14:	050e                	slli	a0,a0,0x3
    80005b16:	9526                	add	a0,a0,s1
    80005b18:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005b1c:	fd043503          	ld	a0,-48(s0)
    80005b20:	fffff097          	auipc	ra,0xfffff
    80005b24:	a00080e7          	jalr	-1536(ra) # 80004520 <fileclose>
    fileclose(wf);
    80005b28:	fc843503          	ld	a0,-56(s0)
    80005b2c:	fffff097          	auipc	ra,0xfffff
    80005b30:	9f4080e7          	jalr	-1548(ra) # 80004520 <fileclose>
    return -1;
    80005b34:	57fd                	li	a5,-1
}
    80005b36:	853e                	mv	a0,a5
    80005b38:	70e2                	ld	ra,56(sp)
    80005b3a:	7442                	ld	s0,48(sp)
    80005b3c:	74a2                	ld	s1,40(sp)
    80005b3e:	6121                	addi	sp,sp,64
    80005b40:	8082                	ret
	...

0000000080005b50 <kernelvec>:
    80005b50:	7111                	addi	sp,sp,-256
    80005b52:	e006                	sd	ra,0(sp)
    80005b54:	e40a                	sd	sp,8(sp)
    80005b56:	e80e                	sd	gp,16(sp)
    80005b58:	ec12                	sd	tp,24(sp)
    80005b5a:	f016                	sd	t0,32(sp)
    80005b5c:	f41a                	sd	t1,40(sp)
    80005b5e:	f81e                	sd	t2,48(sp)
    80005b60:	fc22                	sd	s0,56(sp)
    80005b62:	e0a6                	sd	s1,64(sp)
    80005b64:	e4aa                	sd	a0,72(sp)
    80005b66:	e8ae                	sd	a1,80(sp)
    80005b68:	ecb2                	sd	a2,88(sp)
    80005b6a:	f0b6                	sd	a3,96(sp)
    80005b6c:	f4ba                	sd	a4,104(sp)
    80005b6e:	f8be                	sd	a5,112(sp)
    80005b70:	fcc2                	sd	a6,120(sp)
    80005b72:	e146                	sd	a7,128(sp)
    80005b74:	e54a                	sd	s2,136(sp)
    80005b76:	e94e                	sd	s3,144(sp)
    80005b78:	ed52                	sd	s4,152(sp)
    80005b7a:	f156                	sd	s5,160(sp)
    80005b7c:	f55a                	sd	s6,168(sp)
    80005b7e:	f95e                	sd	s7,176(sp)
    80005b80:	fd62                	sd	s8,184(sp)
    80005b82:	e1e6                	sd	s9,192(sp)
    80005b84:	e5ea                	sd	s10,200(sp)
    80005b86:	e9ee                	sd	s11,208(sp)
    80005b88:	edf2                	sd	t3,216(sp)
    80005b8a:	f1f6                	sd	t4,224(sp)
    80005b8c:	f5fa                	sd	t5,232(sp)
    80005b8e:	f9fe                	sd	t6,240(sp)
    80005b90:	da1fc0ef          	jal	ra,80002930 <kerneltrap>
    80005b94:	6082                	ld	ra,0(sp)
    80005b96:	6122                	ld	sp,8(sp)
    80005b98:	61c2                	ld	gp,16(sp)
    80005b9a:	7282                	ld	t0,32(sp)
    80005b9c:	7322                	ld	t1,40(sp)
    80005b9e:	73c2                	ld	t2,48(sp)
    80005ba0:	7462                	ld	s0,56(sp)
    80005ba2:	6486                	ld	s1,64(sp)
    80005ba4:	6526                	ld	a0,72(sp)
    80005ba6:	65c6                	ld	a1,80(sp)
    80005ba8:	6666                	ld	a2,88(sp)
    80005baa:	7686                	ld	a3,96(sp)
    80005bac:	7726                	ld	a4,104(sp)
    80005bae:	77c6                	ld	a5,112(sp)
    80005bb0:	7866                	ld	a6,120(sp)
    80005bb2:	688a                	ld	a7,128(sp)
    80005bb4:	692a                	ld	s2,136(sp)
    80005bb6:	69ca                	ld	s3,144(sp)
    80005bb8:	6a6a                	ld	s4,152(sp)
    80005bba:	7a8a                	ld	s5,160(sp)
    80005bbc:	7b2a                	ld	s6,168(sp)
    80005bbe:	7bca                	ld	s7,176(sp)
    80005bc0:	7c6a                	ld	s8,184(sp)
    80005bc2:	6c8e                	ld	s9,192(sp)
    80005bc4:	6d2e                	ld	s10,200(sp)
    80005bc6:	6dce                	ld	s11,208(sp)
    80005bc8:	6e6e                	ld	t3,216(sp)
    80005bca:	7e8e                	ld	t4,224(sp)
    80005bcc:	7f2e                	ld	t5,232(sp)
    80005bce:	7fce                	ld	t6,240(sp)
    80005bd0:	6111                	addi	sp,sp,256
    80005bd2:	10200073          	sret
    80005bd6:	00000013          	nop
    80005bda:	00000013          	nop
    80005bde:	0001                	nop

0000000080005be0 <timervec>:
    80005be0:	34051573          	csrrw	a0,mscratch,a0
    80005be4:	e10c                	sd	a1,0(a0)
    80005be6:	e510                	sd	a2,8(a0)
    80005be8:	e914                	sd	a3,16(a0)
    80005bea:	6d0c                	ld	a1,24(a0)
    80005bec:	7110                	ld	a2,32(a0)
    80005bee:	6194                	ld	a3,0(a1)
    80005bf0:	96b2                	add	a3,a3,a2
    80005bf2:	e194                	sd	a3,0(a1)
    80005bf4:	4589                	li	a1,2
    80005bf6:	14459073          	csrw	sip,a1
    80005bfa:	6914                	ld	a3,16(a0)
    80005bfc:	6510                	ld	a2,8(a0)
    80005bfe:	610c                	ld	a1,0(a0)
    80005c00:	34051573          	csrrw	a0,mscratch,a0
    80005c04:	30200073          	mret
	...

0000000080005c0a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005c0a:	1141                	addi	sp,sp,-16
    80005c0c:	e422                	sd	s0,8(sp)
    80005c0e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005c10:	0c0007b7          	lui	a5,0xc000
    80005c14:	4705                	li	a4,1
    80005c16:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005c18:	c3d8                	sw	a4,4(a5)
}
    80005c1a:	6422                	ld	s0,8(sp)
    80005c1c:	0141                	addi	sp,sp,16
    80005c1e:	8082                	ret

0000000080005c20 <plicinithart>:

void
plicinithart(void)
{
    80005c20:	1141                	addi	sp,sp,-16
    80005c22:	e406                	sd	ra,8(sp)
    80005c24:	e022                	sd	s0,0(sp)
    80005c26:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005c28:	ffffc097          	auipc	ra,0xffffc
    80005c2c:	d7e080e7          	jalr	-642(ra) # 800019a6 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005c30:	0085171b          	slliw	a4,a0,0x8
    80005c34:	0c0027b7          	lui	a5,0xc002
    80005c38:	97ba                	add	a5,a5,a4
    80005c3a:	40200713          	li	a4,1026
    80005c3e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005c42:	00d5151b          	slliw	a0,a0,0xd
    80005c46:	0c2017b7          	lui	a5,0xc201
    80005c4a:	953e                	add	a0,a0,a5
    80005c4c:	00052023          	sw	zero,0(a0)
}
    80005c50:	60a2                	ld	ra,8(sp)
    80005c52:	6402                	ld	s0,0(sp)
    80005c54:	0141                	addi	sp,sp,16
    80005c56:	8082                	ret

0000000080005c58 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005c58:	1141                	addi	sp,sp,-16
    80005c5a:	e406                	sd	ra,8(sp)
    80005c5c:	e022                	sd	s0,0(sp)
    80005c5e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005c60:	ffffc097          	auipc	ra,0xffffc
    80005c64:	d46080e7          	jalr	-698(ra) # 800019a6 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005c68:	00d5179b          	slliw	a5,a0,0xd
    80005c6c:	0c201537          	lui	a0,0xc201
    80005c70:	953e                	add	a0,a0,a5
  return irq;
}
    80005c72:	4148                	lw	a0,4(a0)
    80005c74:	60a2                	ld	ra,8(sp)
    80005c76:	6402                	ld	s0,0(sp)
    80005c78:	0141                	addi	sp,sp,16
    80005c7a:	8082                	ret

0000000080005c7c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005c7c:	1101                	addi	sp,sp,-32
    80005c7e:	ec06                	sd	ra,24(sp)
    80005c80:	e822                	sd	s0,16(sp)
    80005c82:	e426                	sd	s1,8(sp)
    80005c84:	1000                	addi	s0,sp,32
    80005c86:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005c88:	ffffc097          	auipc	ra,0xffffc
    80005c8c:	d1e080e7          	jalr	-738(ra) # 800019a6 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005c90:	00d5151b          	slliw	a0,a0,0xd
    80005c94:	0c2017b7          	lui	a5,0xc201
    80005c98:	97aa                	add	a5,a5,a0
    80005c9a:	c3c4                	sw	s1,4(a5)
}
    80005c9c:	60e2                	ld	ra,24(sp)
    80005c9e:	6442                	ld	s0,16(sp)
    80005ca0:	64a2                	ld	s1,8(sp)
    80005ca2:	6105                	addi	sp,sp,32
    80005ca4:	8082                	ret

0000000080005ca6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005ca6:	1141                	addi	sp,sp,-16
    80005ca8:	e406                	sd	ra,8(sp)
    80005caa:	e022                	sd	s0,0(sp)
    80005cac:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005cae:	479d                	li	a5,7
    80005cb0:	06a7c963          	blt	a5,a0,80005d22 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005cb4:	0001d797          	auipc	a5,0x1d
    80005cb8:	34c78793          	addi	a5,a5,844 # 80023000 <disk>
    80005cbc:	00a78733          	add	a4,a5,a0
    80005cc0:	6789                	lui	a5,0x2
    80005cc2:	97ba                	add	a5,a5,a4
    80005cc4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005cc8:	e7ad                	bnez	a5,80005d32 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005cca:	00451793          	slli	a5,a0,0x4
    80005cce:	0001f717          	auipc	a4,0x1f
    80005cd2:	33270713          	addi	a4,a4,818 # 80025000 <disk+0x2000>
    80005cd6:	6314                	ld	a3,0(a4)
    80005cd8:	96be                	add	a3,a3,a5
    80005cda:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005cde:	6314                	ld	a3,0(a4)
    80005ce0:	96be                	add	a3,a3,a5
    80005ce2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005ce6:	6314                	ld	a3,0(a4)
    80005ce8:	96be                	add	a3,a3,a5
    80005cea:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005cee:	6318                	ld	a4,0(a4)
    80005cf0:	97ba                	add	a5,a5,a4
    80005cf2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005cf6:	0001d797          	auipc	a5,0x1d
    80005cfa:	30a78793          	addi	a5,a5,778 # 80023000 <disk>
    80005cfe:	97aa                	add	a5,a5,a0
    80005d00:	6509                	lui	a0,0x2
    80005d02:	953e                	add	a0,a0,a5
    80005d04:	4785                	li	a5,1
    80005d06:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005d0a:	0001f517          	auipc	a0,0x1f
    80005d0e:	30e50513          	addi	a0,a0,782 # 80025018 <disk+0x2018>
    80005d12:	ffffc097          	auipc	ra,0xffffc
    80005d16:	50c080e7          	jalr	1292(ra) # 8000221e <wakeup>
}
    80005d1a:	60a2                	ld	ra,8(sp)
    80005d1c:	6402                	ld	s0,0(sp)
    80005d1e:	0141                	addi	sp,sp,16
    80005d20:	8082                	ret
    panic("free_desc 1");
    80005d22:	00003517          	auipc	a0,0x3
    80005d26:	a3650513          	addi	a0,a0,-1482 # 80008758 <syscalls+0x320>
    80005d2a:	ffffb097          	auipc	ra,0xffffb
    80005d2e:	800080e7          	jalr	-2048(ra) # 8000052a <panic>
    panic("free_desc 2");
    80005d32:	00003517          	auipc	a0,0x3
    80005d36:	a3650513          	addi	a0,a0,-1482 # 80008768 <syscalls+0x330>
    80005d3a:	ffffa097          	auipc	ra,0xffffa
    80005d3e:	7f0080e7          	jalr	2032(ra) # 8000052a <panic>

0000000080005d42 <virtio_disk_init>:
{
    80005d42:	1101                	addi	sp,sp,-32
    80005d44:	ec06                	sd	ra,24(sp)
    80005d46:	e822                	sd	s0,16(sp)
    80005d48:	e426                	sd	s1,8(sp)
    80005d4a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005d4c:	00003597          	auipc	a1,0x3
    80005d50:	a2c58593          	addi	a1,a1,-1492 # 80008778 <syscalls+0x340>
    80005d54:	0001f517          	auipc	a0,0x1f
    80005d58:	3d450513          	addi	a0,a0,980 # 80025128 <disk+0x2128>
    80005d5c:	ffffb097          	auipc	ra,0xffffb
    80005d60:	dd6080e7          	jalr	-554(ra) # 80000b32 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005d64:	100017b7          	lui	a5,0x10001
    80005d68:	4398                	lw	a4,0(a5)
    80005d6a:	2701                	sext.w	a4,a4
    80005d6c:	747277b7          	lui	a5,0x74727
    80005d70:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005d74:	0ef71163          	bne	a4,a5,80005e56 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005d78:	100017b7          	lui	a5,0x10001
    80005d7c:	43dc                	lw	a5,4(a5)
    80005d7e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005d80:	4705                	li	a4,1
    80005d82:	0ce79a63          	bne	a5,a4,80005e56 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005d86:	100017b7          	lui	a5,0x10001
    80005d8a:	479c                	lw	a5,8(a5)
    80005d8c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005d8e:	4709                	li	a4,2
    80005d90:	0ce79363          	bne	a5,a4,80005e56 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005d94:	100017b7          	lui	a5,0x10001
    80005d98:	47d8                	lw	a4,12(a5)
    80005d9a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005d9c:	554d47b7          	lui	a5,0x554d4
    80005da0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005da4:	0af71963          	bne	a4,a5,80005e56 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005da8:	100017b7          	lui	a5,0x10001
    80005dac:	4705                	li	a4,1
    80005dae:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005db0:	470d                	li	a4,3
    80005db2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005db4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005db6:	c7ffe737          	lui	a4,0xc7ffe
    80005dba:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005dbe:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005dc0:	2701                	sext.w	a4,a4
    80005dc2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005dc4:	472d                	li	a4,11
    80005dc6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005dc8:	473d                	li	a4,15
    80005dca:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005dcc:	6705                	lui	a4,0x1
    80005dce:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005dd0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005dd4:	5bdc                	lw	a5,52(a5)
    80005dd6:	2781                	sext.w	a5,a5
  if(max == 0)
    80005dd8:	c7d9                	beqz	a5,80005e66 <virtio_disk_init+0x124>
  if(max < NUM)
    80005dda:	471d                	li	a4,7
    80005ddc:	08f77d63          	bgeu	a4,a5,80005e76 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005de0:	100014b7          	lui	s1,0x10001
    80005de4:	47a1                	li	a5,8
    80005de6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005de8:	6609                	lui	a2,0x2
    80005dea:	4581                	li	a1,0
    80005dec:	0001d517          	auipc	a0,0x1d
    80005df0:	21450513          	addi	a0,a0,532 # 80023000 <disk>
    80005df4:	ffffb097          	auipc	ra,0xffffb
    80005df8:	eca080e7          	jalr	-310(ra) # 80000cbe <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005dfc:	0001d717          	auipc	a4,0x1d
    80005e00:	20470713          	addi	a4,a4,516 # 80023000 <disk>
    80005e04:	00c75793          	srli	a5,a4,0xc
    80005e08:	2781                	sext.w	a5,a5
    80005e0a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005e0c:	0001f797          	auipc	a5,0x1f
    80005e10:	1f478793          	addi	a5,a5,500 # 80025000 <disk+0x2000>
    80005e14:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005e16:	0001d717          	auipc	a4,0x1d
    80005e1a:	26a70713          	addi	a4,a4,618 # 80023080 <disk+0x80>
    80005e1e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005e20:	0001e717          	auipc	a4,0x1e
    80005e24:	1e070713          	addi	a4,a4,480 # 80024000 <disk+0x1000>
    80005e28:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005e2a:	4705                	li	a4,1
    80005e2c:	00e78c23          	sb	a4,24(a5)
    80005e30:	00e78ca3          	sb	a4,25(a5)
    80005e34:	00e78d23          	sb	a4,26(a5)
    80005e38:	00e78da3          	sb	a4,27(a5)
    80005e3c:	00e78e23          	sb	a4,28(a5)
    80005e40:	00e78ea3          	sb	a4,29(a5)
    80005e44:	00e78f23          	sb	a4,30(a5)
    80005e48:	00e78fa3          	sb	a4,31(a5)
}
    80005e4c:	60e2                	ld	ra,24(sp)
    80005e4e:	6442                	ld	s0,16(sp)
    80005e50:	64a2                	ld	s1,8(sp)
    80005e52:	6105                	addi	sp,sp,32
    80005e54:	8082                	ret
    panic("could not find virtio disk");
    80005e56:	00003517          	auipc	a0,0x3
    80005e5a:	93250513          	addi	a0,a0,-1742 # 80008788 <syscalls+0x350>
    80005e5e:	ffffa097          	auipc	ra,0xffffa
    80005e62:	6cc080e7          	jalr	1740(ra) # 8000052a <panic>
    panic("virtio disk has no queue 0");
    80005e66:	00003517          	auipc	a0,0x3
    80005e6a:	94250513          	addi	a0,a0,-1726 # 800087a8 <syscalls+0x370>
    80005e6e:	ffffa097          	auipc	ra,0xffffa
    80005e72:	6bc080e7          	jalr	1724(ra) # 8000052a <panic>
    panic("virtio disk max queue too short");
    80005e76:	00003517          	auipc	a0,0x3
    80005e7a:	95250513          	addi	a0,a0,-1710 # 800087c8 <syscalls+0x390>
    80005e7e:	ffffa097          	auipc	ra,0xffffa
    80005e82:	6ac080e7          	jalr	1708(ra) # 8000052a <panic>

0000000080005e86 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005e86:	7119                	addi	sp,sp,-128
    80005e88:	fc86                	sd	ra,120(sp)
    80005e8a:	f8a2                	sd	s0,112(sp)
    80005e8c:	f4a6                	sd	s1,104(sp)
    80005e8e:	f0ca                	sd	s2,96(sp)
    80005e90:	ecce                	sd	s3,88(sp)
    80005e92:	e8d2                	sd	s4,80(sp)
    80005e94:	e4d6                	sd	s5,72(sp)
    80005e96:	e0da                	sd	s6,64(sp)
    80005e98:	fc5e                	sd	s7,56(sp)
    80005e9a:	f862                	sd	s8,48(sp)
    80005e9c:	f466                	sd	s9,40(sp)
    80005e9e:	f06a                	sd	s10,32(sp)
    80005ea0:	ec6e                	sd	s11,24(sp)
    80005ea2:	0100                	addi	s0,sp,128
    80005ea4:	8aaa                	mv	s5,a0
    80005ea6:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005ea8:	00c52c83          	lw	s9,12(a0)
    80005eac:	001c9c9b          	slliw	s9,s9,0x1
    80005eb0:	1c82                	slli	s9,s9,0x20
    80005eb2:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005eb6:	0001f517          	auipc	a0,0x1f
    80005eba:	27250513          	addi	a0,a0,626 # 80025128 <disk+0x2128>
    80005ebe:	ffffb097          	auipc	ra,0xffffb
    80005ec2:	d04080e7          	jalr	-764(ra) # 80000bc2 <acquire>
  for(int i = 0; i < 3; i++){
    80005ec6:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005ec8:	44a1                	li	s1,8
      disk.free[i] = 0;
    80005eca:	0001dc17          	auipc	s8,0x1d
    80005ece:	136c0c13          	addi	s8,s8,310 # 80023000 <disk>
    80005ed2:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80005ed4:	4b0d                	li	s6,3
    80005ed6:	a0ad                	j	80005f40 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80005ed8:	00fc0733          	add	a4,s8,a5
    80005edc:	975e                	add	a4,a4,s7
    80005ede:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80005ee2:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80005ee4:	0207c563          	bltz	a5,80005f0e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005ee8:	2905                	addiw	s2,s2,1
    80005eea:	0611                	addi	a2,a2,4
    80005eec:	19690d63          	beq	s2,s6,80006086 <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    80005ef0:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80005ef2:	0001f717          	auipc	a4,0x1f
    80005ef6:	12670713          	addi	a4,a4,294 # 80025018 <disk+0x2018>
    80005efa:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80005efc:	00074683          	lbu	a3,0(a4)
    80005f00:	fee1                	bnez	a3,80005ed8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005f02:	2785                	addiw	a5,a5,1
    80005f04:	0705                	addi	a4,a4,1
    80005f06:	fe979be3          	bne	a5,s1,80005efc <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005f0a:	57fd                	li	a5,-1
    80005f0c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80005f0e:	01205d63          	blez	s2,80005f28 <virtio_disk_rw+0xa2>
    80005f12:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80005f14:	000a2503          	lw	a0,0(s4)
    80005f18:	00000097          	auipc	ra,0x0
    80005f1c:	d8e080e7          	jalr	-626(ra) # 80005ca6 <free_desc>
      for(int j = 0; j < i; j++)
    80005f20:	2d85                	addiw	s11,s11,1
    80005f22:	0a11                	addi	s4,s4,4
    80005f24:	ffb918e3          	bne	s2,s11,80005f14 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005f28:	0001f597          	auipc	a1,0x1f
    80005f2c:	20058593          	addi	a1,a1,512 # 80025128 <disk+0x2128>
    80005f30:	0001f517          	auipc	a0,0x1f
    80005f34:	0e850513          	addi	a0,a0,232 # 80025018 <disk+0x2018>
    80005f38:	ffffc097          	auipc	ra,0xffffc
    80005f3c:	15a080e7          	jalr	346(ra) # 80002092 <sleep>
  for(int i = 0; i < 3; i++){
    80005f40:	f8040a13          	addi	s4,s0,-128
{
    80005f44:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80005f46:	894e                	mv	s2,s3
    80005f48:	b765                	j	80005ef0 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80005f4a:	0001f697          	auipc	a3,0x1f
    80005f4e:	0b66b683          	ld	a3,182(a3) # 80025000 <disk+0x2000>
    80005f52:	96ba                	add	a3,a3,a4
    80005f54:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80005f58:	0001d817          	auipc	a6,0x1d
    80005f5c:	0a880813          	addi	a6,a6,168 # 80023000 <disk>
    80005f60:	0001f697          	auipc	a3,0x1f
    80005f64:	0a068693          	addi	a3,a3,160 # 80025000 <disk+0x2000>
    80005f68:	6290                	ld	a2,0(a3)
    80005f6a:	963a                	add	a2,a2,a4
    80005f6c:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    80005f70:	0015e593          	ori	a1,a1,1
    80005f74:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80005f78:	f8842603          	lw	a2,-120(s0)
    80005f7c:	628c                	ld	a1,0(a3)
    80005f7e:	972e                	add	a4,a4,a1
    80005f80:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80005f84:	20050593          	addi	a1,a0,512
    80005f88:	0592                	slli	a1,a1,0x4
    80005f8a:	95c2                	add	a1,a1,a6
    80005f8c:	577d                	li	a4,-1
    80005f8e:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80005f92:	00461713          	slli	a4,a2,0x4
    80005f96:	6290                	ld	a2,0(a3)
    80005f98:	963a                	add	a2,a2,a4
    80005f9a:	03078793          	addi	a5,a5,48
    80005f9e:	97c2                	add	a5,a5,a6
    80005fa0:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    80005fa2:	629c                	ld	a5,0(a3)
    80005fa4:	97ba                	add	a5,a5,a4
    80005fa6:	4605                	li	a2,1
    80005fa8:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80005faa:	629c                	ld	a5,0(a3)
    80005fac:	97ba                	add	a5,a5,a4
    80005fae:	4809                	li	a6,2
    80005fb0:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80005fb4:	629c                	ld	a5,0(a3)
    80005fb6:	973e                	add	a4,a4,a5
    80005fb8:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80005fbc:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80005fc0:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80005fc4:	6698                	ld	a4,8(a3)
    80005fc6:	00275783          	lhu	a5,2(a4)
    80005fca:	8b9d                	andi	a5,a5,7
    80005fcc:	0786                	slli	a5,a5,0x1
    80005fce:	97ba                	add	a5,a5,a4
    80005fd0:	00a79223          	sh	a0,4(a5)

  __sync_synchronize();
    80005fd4:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80005fd8:	6698                	ld	a4,8(a3)
    80005fda:	00275783          	lhu	a5,2(a4)
    80005fde:	2785                	addiw	a5,a5,1
    80005fe0:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80005fe4:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80005fe8:	100017b7          	lui	a5,0x10001
    80005fec:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80005ff0:	004aa783          	lw	a5,4(s5)
    80005ff4:	02c79163          	bne	a5,a2,80006016 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80005ff8:	0001f917          	auipc	s2,0x1f
    80005ffc:	13090913          	addi	s2,s2,304 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006000:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006002:	85ca                	mv	a1,s2
    80006004:	8556                	mv	a0,s5
    80006006:	ffffc097          	auipc	ra,0xffffc
    8000600a:	08c080e7          	jalr	140(ra) # 80002092 <sleep>
  while(b->disk == 1) {
    8000600e:	004aa783          	lw	a5,4(s5)
    80006012:	fe9788e3          	beq	a5,s1,80006002 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80006016:	f8042903          	lw	s2,-128(s0)
    8000601a:	20090793          	addi	a5,s2,512
    8000601e:	00479713          	slli	a4,a5,0x4
    80006022:	0001d797          	auipc	a5,0x1d
    80006026:	fde78793          	addi	a5,a5,-34 # 80023000 <disk>
    8000602a:	97ba                	add	a5,a5,a4
    8000602c:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006030:	0001f997          	auipc	s3,0x1f
    80006034:	fd098993          	addi	s3,s3,-48 # 80025000 <disk+0x2000>
    80006038:	00491713          	slli	a4,s2,0x4
    8000603c:	0009b783          	ld	a5,0(s3)
    80006040:	97ba                	add	a5,a5,a4
    80006042:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006046:	854a                	mv	a0,s2
    80006048:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000604c:	00000097          	auipc	ra,0x0
    80006050:	c5a080e7          	jalr	-934(ra) # 80005ca6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006054:	8885                	andi	s1,s1,1
    80006056:	f0ed                	bnez	s1,80006038 <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006058:	0001f517          	auipc	a0,0x1f
    8000605c:	0d050513          	addi	a0,a0,208 # 80025128 <disk+0x2128>
    80006060:	ffffb097          	auipc	ra,0xffffb
    80006064:	c16080e7          	jalr	-1002(ra) # 80000c76 <release>
}
    80006068:	70e6                	ld	ra,120(sp)
    8000606a:	7446                	ld	s0,112(sp)
    8000606c:	74a6                	ld	s1,104(sp)
    8000606e:	7906                	ld	s2,96(sp)
    80006070:	69e6                	ld	s3,88(sp)
    80006072:	6a46                	ld	s4,80(sp)
    80006074:	6aa6                	ld	s5,72(sp)
    80006076:	6b06                	ld	s6,64(sp)
    80006078:	7be2                	ld	s7,56(sp)
    8000607a:	7c42                	ld	s8,48(sp)
    8000607c:	7ca2                	ld	s9,40(sp)
    8000607e:	7d02                	ld	s10,32(sp)
    80006080:	6de2                	ld	s11,24(sp)
    80006082:	6109                	addi	sp,sp,128
    80006084:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006086:	f8042503          	lw	a0,-128(s0)
    8000608a:	20050793          	addi	a5,a0,512
    8000608e:	0792                	slli	a5,a5,0x4
  if(write)
    80006090:	0001d817          	auipc	a6,0x1d
    80006094:	f7080813          	addi	a6,a6,-144 # 80023000 <disk>
    80006098:	00f80733          	add	a4,a6,a5
    8000609c:	01a036b3          	snez	a3,s10
    800060a0:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    800060a4:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800060a8:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    800060ac:	7679                	lui	a2,0xffffe
    800060ae:	963e                	add	a2,a2,a5
    800060b0:	0001f697          	auipc	a3,0x1f
    800060b4:	f5068693          	addi	a3,a3,-176 # 80025000 <disk+0x2000>
    800060b8:	6298                	ld	a4,0(a3)
    800060ba:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800060bc:	0a878593          	addi	a1,a5,168
    800060c0:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    800060c2:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800060c4:	6298                	ld	a4,0(a3)
    800060c6:	9732                	add	a4,a4,a2
    800060c8:	45c1                	li	a1,16
    800060ca:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800060cc:	6298                	ld	a4,0(a3)
    800060ce:	9732                	add	a4,a4,a2
    800060d0:	4585                	li	a1,1
    800060d2:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800060d6:	f8442703          	lw	a4,-124(s0)
    800060da:	628c                	ld	a1,0(a3)
    800060dc:	962e                	add	a2,a2,a1
    800060de:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    800060e2:	0712                	slli	a4,a4,0x4
    800060e4:	6290                	ld	a2,0(a3)
    800060e6:	963a                	add	a2,a2,a4
    800060e8:	058a8593          	addi	a1,s5,88
    800060ec:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800060ee:	6294                	ld	a3,0(a3)
    800060f0:	96ba                	add	a3,a3,a4
    800060f2:	40000613          	li	a2,1024
    800060f6:	c690                	sw	a2,8(a3)
  if(write)
    800060f8:	e40d19e3          	bnez	s10,80005f4a <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800060fc:	0001f697          	auipc	a3,0x1f
    80006100:	f046b683          	ld	a3,-252(a3) # 80025000 <disk+0x2000>
    80006104:	96ba                	add	a3,a3,a4
    80006106:	4609                	li	a2,2
    80006108:	00c69623          	sh	a2,12(a3)
    8000610c:	b5b1                	j	80005f58 <virtio_disk_rw+0xd2>

000000008000610e <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000610e:	1101                	addi	sp,sp,-32
    80006110:	ec06                	sd	ra,24(sp)
    80006112:	e822                	sd	s0,16(sp)
    80006114:	e426                	sd	s1,8(sp)
    80006116:	e04a                	sd	s2,0(sp)
    80006118:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000611a:	0001f517          	auipc	a0,0x1f
    8000611e:	00e50513          	addi	a0,a0,14 # 80025128 <disk+0x2128>
    80006122:	ffffb097          	auipc	ra,0xffffb
    80006126:	aa0080e7          	jalr	-1376(ra) # 80000bc2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000612a:	10001737          	lui	a4,0x10001
    8000612e:	533c                	lw	a5,96(a4)
    80006130:	8b8d                	andi	a5,a5,3
    80006132:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006134:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006138:	0001f797          	auipc	a5,0x1f
    8000613c:	ec878793          	addi	a5,a5,-312 # 80025000 <disk+0x2000>
    80006140:	6b94                	ld	a3,16(a5)
    80006142:	0207d703          	lhu	a4,32(a5)
    80006146:	0026d783          	lhu	a5,2(a3)
    8000614a:	06f70163          	beq	a4,a5,800061ac <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000614e:	0001d917          	auipc	s2,0x1d
    80006152:	eb290913          	addi	s2,s2,-334 # 80023000 <disk>
    80006156:	0001f497          	auipc	s1,0x1f
    8000615a:	eaa48493          	addi	s1,s1,-342 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000615e:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006162:	6898                	ld	a4,16(s1)
    80006164:	0204d783          	lhu	a5,32(s1)
    80006168:	8b9d                	andi	a5,a5,7
    8000616a:	078e                	slli	a5,a5,0x3
    8000616c:	97ba                	add	a5,a5,a4
    8000616e:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006170:	20078713          	addi	a4,a5,512
    80006174:	0712                	slli	a4,a4,0x4
    80006176:	974a                	add	a4,a4,s2
    80006178:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000617c:	e731                	bnez	a4,800061c8 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000617e:	20078793          	addi	a5,a5,512
    80006182:	0792                	slli	a5,a5,0x4
    80006184:	97ca                	add	a5,a5,s2
    80006186:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006188:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000618c:	ffffc097          	auipc	ra,0xffffc
    80006190:	092080e7          	jalr	146(ra) # 8000221e <wakeup>

    disk.used_idx += 1;
    80006194:	0204d783          	lhu	a5,32(s1)
    80006198:	2785                	addiw	a5,a5,1
    8000619a:	17c2                	slli	a5,a5,0x30
    8000619c:	93c1                	srli	a5,a5,0x30
    8000619e:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800061a2:	6898                	ld	a4,16(s1)
    800061a4:	00275703          	lhu	a4,2(a4)
    800061a8:	faf71be3          	bne	a4,a5,8000615e <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800061ac:	0001f517          	auipc	a0,0x1f
    800061b0:	f7c50513          	addi	a0,a0,-132 # 80025128 <disk+0x2128>
    800061b4:	ffffb097          	auipc	ra,0xffffb
    800061b8:	ac2080e7          	jalr	-1342(ra) # 80000c76 <release>
}
    800061bc:	60e2                	ld	ra,24(sp)
    800061be:	6442                	ld	s0,16(sp)
    800061c0:	64a2                	ld	s1,8(sp)
    800061c2:	6902                	ld	s2,0(sp)
    800061c4:	6105                	addi	sp,sp,32
    800061c6:	8082                	ret
      panic("virtio_disk_intr status");
    800061c8:	00002517          	auipc	a0,0x2
    800061cc:	62050513          	addi	a0,a0,1568 # 800087e8 <syscalls+0x3b0>
    800061d0:	ffffa097          	auipc	ra,0xffffa
    800061d4:	35a080e7          	jalr	858(ra) # 8000052a <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
