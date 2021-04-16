////////////////////////////////////////////////////////////////////////////////
// Engineer:       Jiang Binze - jiangbinze@mail.ustc.edu.cn                  //
//                                                                            //
// Design Name:    alu module                                                 //
// Project Name:   RISCV Core                                                 //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    ALU                                                        //
//                                                                            //
// Mother Module Name:                                                        //
//                 ex_stage                                                   //
////////////////////////////////////////////////////////////////////////////////

module alu import core_pkg::*;
#(
    parameter DEBUG         = 0
)
(
    input   logic           alu_en,
    input   logic   [ALU_OP_WIDTH-1:0]  alu_op,
    input   logic   [31:0]  op_a,
    input   logic   [31:0]  op_b,

    output  logic   [31:0]  result
);

    always_comb begin : ALU
        result = 32'hdec0de_ff;
        case (alu_op)
            ALU_ADD:    result = $signed (op_a) + $signed (op_b);
            ALU_SUB:    result = $signed (op_a) - $signed (op_b);   
            ALU_SUBU:   result = $unsigned(op_a)- $unsigned(op_b);
            ALU_XOR:    result = op_a ^ op_b;
            ALU_OR:     result = op_a | op_b;
            ALU_AND:    result = op_a & op_b;
            ALU_SRA:    result = $signed(op_a) >>> $unsigned(op_b[4:0]);
            ALU_SRL:    result = $unsigned(op_a) >> $unsigned(op_b[4:0]);
            ALU_SLL:    result = op_a << op_b[4:0];
            ALU_SLT:    result = $signed(op_a) < $signed(op_b) ? 1 : 0;
            ALU_SLTU:   result = $unsigned(op_a) < $unsigned(op_b) ? 1 : 0;
            ALU_LUI:    result = op_b;
            default: ;
        endcase
    end

endmodule