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

    parameter ALU_XOR   = 7'b0101111;
    parameter ALU_OR    = 7'b0101110;
    parameter ALU_AND   = 7'b0010101;

    // Shifts
    parameter ALU_SRA   = 7'b0100100;
    parameter ALU_SRL   = 7'b0100101;
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

    // Load Upper Immediates
    parameter ALU_LUI   = 7'b0011100;

// ALU Source Oprands Select
    // 2-BIT, remain to be fixed
    parameter ALU_SRC_WIDTH = 2;
    parameter ALU_SRC_REG = 0;
    parameter ALU_SRC_IMM = 1;
    parameter ALU_SRC_PC  = 2;

// Branch Type Operands
    parameter BRCH_OP_WIDTH = 4;
    parameter BRCH_NOP  = 4'b1000;
    parameter BRCH_BEQ  = 4'b0000;
    parameter BRCH_BNE  = 4'b0001;
    parameter BRCH_BLT  = 4'b0100;
    parameter BRCH_BLTU = 4'b0110;
    parameter BRCH_BGE  = 4'b0101;
    parameter BRCH_BGEU = 4'b0111;
    parameter BRCH_JALR = 4'b1111;

// IF stage
    // PC mux selector defines
    parameter PC_BOOT          = 4'b0000;
    parameter PC_JUMP          = 4'b0010;
    parameter PC_BRANCH        = 4'b0011;

// ID stage

// WB stage
    // Write data select
    parameter WB_WR_MUX_OP_WIDTH = 2;
    parameter WB_WR_MUX_ALU = 0;
    parameter WB_MR_MUX_MEM = 1;
    parameter WB_WR_MUX_PCINCR = 2;
endpackage