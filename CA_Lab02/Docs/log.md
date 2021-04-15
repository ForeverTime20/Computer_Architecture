- WB段写寄存器时，ID段读取寄存器需要做特殊处理。
- JALR指令在EX段执行时，ALU计算的是跳转地址，在往MEM段输出ALUout时，要手动选择为pc+4
- slli rd, rs1, shamt x[rd] = x[rs1] ≪ shamt
  立即数逻辑左移(Shift Left Logical Immediate). I-type, RV32I and RV64I.
  把寄存器x[rs1]左移shamt位，空出的位置填入0，结果写入x[rd]。对于RV32I，仅当shamt[5]=0
  时，指令才是有效的  

