# Lab01实验报告

蒋滨泽	PB18030971

## 1.描述执行一条XOR指令的过程

数据通路如下：

![](\img\XOR.png)

|         | 数据通路                                                     | 控制信号                                                     |
| ------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| IF(红)  | PC指向XOR指令的地址，取出的指令送往IF/ID段寄存器。           | BrE=0；JalrE=0；JalD=0；                                     |
| ID(绿)  | Rs1=Instr[19:15];Rs2=Instr[24:20];分别送往寄存器堆读出对应寄存器号的数据RegOut1D，RegOut2D；Rd=Instr[11:7]送往ID/EX段寄存器。同时指令被送往Control Unit产生控制信号。 |                                                              |
| EX(红)  | RegOut1E与RegOut2E分别经过多选器送往ALU进行运算，运算结果ALUOutE送入EX/MEM段间寄存器；目的寄存器号RdE送往EX/MEM段间寄存器。传递控制信号。 | AluControlE=ALU_XOR；Forward1E=0；Forward2E=0；AluSrc1E=1；AluSrc2E=0； |
| MEM(绿) | ALU运算结果AluOutM经过多选器送至MEM/WB段间寄存器，目的寄存器RdM送往MEM/WB段间寄存器。传递控制信号。 | MemWriteM=0；                                                |
| WB(黄)  | 运算结果通过多选器和寄存器写端口写入寄存器堆，目标寄存器号标识要写入的寄存器。 | RegWrite=1；MemtoReg=0；                                     |

## 2.描述执行一条BEQ指令的过程

数据通路如下：

![](\img\BEQ.png)

|        | 数据通路                                                     | 控制信号                                                     |
| ------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| IF(红) | PC指向BEQ指令的地址，取出的指令送往IF/ID段寄存器。           | BrE=0；JalrE=0；JalD=0；                                     |
| ID(绿) | Rs1=Instr[19:15];Rs2=Instr[24:20];分别送往寄存器堆读出对应寄存器号的数据RegOut1D，RegOut2D；ImmD跳转地址的偏移量送往ID/EX段寄存器。同时指令被送往Control Unit产生控制信号。 |                                                              |
| EX(红) | RegOut1E与RegOut2E分别经过多选器送往Branch Decision进行运算，分支判断结果返回至NPC Generator；跳转目标地址也一同被送至NPC Generator。传递控制信号到取指部分。 | Forward1E=0；Forward2E=0；AluSrc1E=1；AluSrc2E=0；BrType=BEQ；BrE=分支是否发生；JalrE=0；JalD=0； |

## 3.描述执行一条LHU指令的过程

数据通路如下：

![](\img\LHU.png)

|         | 数据通路                                                     | 控制信号                                                     |
| ------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| IF(红)  | PC指向LHU指令的地址，取出的指令送往IF/ID段寄存器。           | BrE=0；JalrE=0；JalD=0；                                     |
| ID(绿)  | Rs1=Instr[19:15];ImmD=Instr[31:20];送往寄存器堆读出对应寄存器号的数据RegOut1D；Rd=Instr[11:7]送往ID/EX段寄存器。ImmD跳转地址的偏移量送往ID/EX段寄存器。同时指令被送往Control Unit产生控制信号。 |                                                              |
| EX(红)  | RegOut1E与偏移量ImmE分别经过多选器送往ALU进行加法运算得到跳转地址，运算结果ALUOutE送入EX/MEM段间寄存器；目的寄存器号RdE送往EX/MEM段间寄存器。传递控制信号。 | AluControlE=ALU_ADD；Forward1E=0；Forward2E=0；AluSrc1E=1；AluSrc2E=2； |
| MEM(绿) | ALU运算结果AluOutM送往DataMemory取出数据并存到段间寄存器，目的寄存器RdM送往MEM/WB段间寄存器。传递控制信号。 | MemWriteM=0；                                                |
| WB(黄)  | Data Ext将取出的数据选择16位并进行无符号数值扩展到32位，结果通过多选器和寄存器写端口写入寄存器堆，目标寄存器号标识要写入的寄存器。 | RegWrite=1；MemtoReg=1；LoadedBytesSelect=2Byte；            |

## 4.如果要实现CSR指令，设计图中还需要增加什么部件和数据通路？

数据通路如下图，部分控制信号省略：

![](\img\CSR.png)

IF段：无

ID段：增加CSR格式的扩展模块；RegFile添加CSR寄存器文件；控制单元生成CSR的读写使能信号；Op2数据多选器增加对CSR的选择，段寄存器保存读出的CSR数据和CSR地址（Instr[31:20]）；立即数扩展模块增加对CSR立即数的扩展；

EX段：传递CSR数据与地址，选择立即数或源寄存器数据与CSR数据运算并送至段寄存器；

MEM段：传递数据和控制信号；

WB段：将ALU运算结果配合CSR Write、CSR addr信号写入CSR；CSR数据配合寄存器写使能信号和RdW写入目的通用寄存器；

## 5.Verilog如何实现立即数的扩展？

- I-Type：

  ```verilog
  assign 	imm	= {{21{Instr[31]}}, Instr[30:20]};
  ```

- S-Type：

  ```verilog
  assign	imm = {{21{Instr[31]}}, Instr[30:25], Instr[11:7]};
  ```

- B-Type：

  ```verilog
  assign 	imm = {{20{Instr[31]}}, Instr[7], Instr[30:25], instr[11:8], 1'b0};
  ```

- U-Type：

  ```verilog
  assign  imm = {Instr[31:12], 12'b0};
  ```

- J-Type：

  ```verilog
  assign	imm = {{12{Instr[31]}}, Instr[19:12], Instr[20], Instr[31:21], 1'b0};
  ```

## 6.如何实现Data Memory的非字对齐的Load和Store？

在Data Memory使用字节交叉编址，按照地址 mod4 的余数将不同字节映射到4个不同的存储体，可自由选择不同的存储体load store。

## 7.ALU模块中，默认wire变量是有符号数还是无符号数？

## 8.简述BranchE信号的作用

## 9.NPC Generator中对于不同跳转target的选择有没有优先级？

## 10.Harzard模块中，有哪几类冲突需要插入气泡，分别使流水线停顿几个周期？

## 11.Harzard模块中采用静态分支预测器，遇到branch指令时，如何控制flush和stall信号？

## 12.0号寄存器的值始终为0，是否会对forward的处理产生影响？