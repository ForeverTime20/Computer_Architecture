package core_pkg;

// Opcodes
    parameter OPCODE_SYSTEM    = 7'h73;
    parameter OPCODE_FENCE     = 7'h0f;
    parameter OPCODE_OP        = 7'h33;
    parameter OPCODE_OPIMM     = 7'h13;
    parameter OPCODE_STORE     = 7'h23;
    parameter OPCODE_LOAD      = 7'h03;
    parameter OPCODE_BRANCH    = 7'h63;
    parameter OPCODE_JALR      = 7'h67;
    parameter OPCODE_JAL       = 7'h6f;
    parameter OPCODE_AUIPC     = 7'h17;
    parameter OPCODE_LUI       = 7'h37;

// ALU Operands
    parameter ALU_OP_WIDTH = 7;

    parameter ALU_ADD   = 7'b0011000;
    parameter ALU_SUB   = 7'b0011001;
    parameter ALU_ADDU  = 7'b0011010;
    parameter ALU_SUBU  = 7'b0011011;
    parameter ALU_ADDR  = 7'b0011100;
    parameter ALU_SUBR  = 7'b0011101;
    parameter ALU_ADDUR = 7'b0011110;
    parameter ALU_SUBUR = 7'b0011111;

    parameter ALU_XOR   = 7'b0101111;
    parameter ALU_OR    = 7'b0101110;
    parameter ALU_AND   = 7'b0010101;

    // Shifts
    parameter ALU_SRA   = 7'b0100100;
    parameter ALU_SRL   = 7'b0100101;
    parameter ALU_ROR   = 7'b0100110;
    parameter ALU_SLL   = 7'b0100111;

    // Sign-/zero-extensions
    parameter ALU_EXTS  = 7'b0111110;
    parameter ALU_EXT   = 7'b0111111;

    // Comparisons
    parameter ALU_LTS   = 7'b0000000;
    parameter ALU_LTU   = 7'b0000001;
    parameter ALU_LES   = 7'b0000100;
    parameter ALU_LEU   = 7'b0000101;
    parameter ALU_GTS   = 7'b0001000;
    parameter ALU_GTU   = 7'b0001001;
    parameter ALU_GES   = 7'b0001010;
    parameter ALU_GEU   = 7'b0001011;
    parameter ALU_EQ    = 7'b0001100;
    parameter ALU_NE    = 7'b0001101;

    // Set Lower Than operations
    parameter ALU_SLTS  = 7'b0000010;
    parameter ALU_SLTU  = 7'b0000011;
    parameter ALU_SLETS = 7'b0000110;
    parameter ALU_SLETU = 7'b0000111;

// ALU Source Oprands Select
    // 4-BIT, remain to be fixed

// Branch Type Operands
    parameter BRCH_OP_WIDTH = 4;
    parameter BRCH_NOP  = 0;
    parameter BRCH_BEQ  = 1;
    parameter BRCH_BNE  = 2;
    parameter BRCH_BLT  = 3;
    parameter BRCH_BLTU = 4;
    parameter BRCH_BGE  = 5;
    parameter BRCH_BGEU = 6;

// IF stage
    // PC mux selector defines
    parameter PC_BOOT          = 4'b0000;
    parameter PC_JUMP          = 4'b0010;
    parameter PC_BRANCH        = 4'b0011;

// ID stage

endpackage