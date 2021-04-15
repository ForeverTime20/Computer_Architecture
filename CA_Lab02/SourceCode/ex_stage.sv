////////////////////////////////////////////////////////////////////////////////
// Engineer:       Jiang Binze - jiangbinze@mail.ustc.edu.cn                  //
//                                                                            //
// Design Name:    ex_stage module                                            //
// Project Name:   RISCV Core                                                 //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    Execute Instruction in this stage                          //
//                                                                            //
// Mother Module Name:                                                        //
//                 core                                                       //
////////////////////////////////////////////////////////////////////////////////

module ex_stage import core_pkg::*;
#(
    parameter DEBUG          = 0
)
(
    input   logic           clk,
    input   logic           rst_n,

    input   logic           stall_ex_i,
    input   logic           clear_ex_i,

    // From ID stage
    input   logic   [31:0]  pc_id_i,
    input   logic           alu_en_i,
    input   logic   [ALU_OP_WIDTH-1:0]  alu_op_i,
    input   logic   [ALU_SRC_WIDTH-1:0] alu_src_1_i,
    input   logic   [ALU_SRC_WIDTH-1:0] alu_src_2_i,
    input   logic   [4 :0]  rs1_raddr_i,
    input   logic   [4 :0]  rs2_raddr_i,
    input   logic   [31:0]  rs1_rdata_i,
    input   logic   [31:0]  rs2_rdata_i,
    input   logic           rs1_used_i,
    input   logic           rs2_used_i,
    input   logic   [31:0]  imm_i,
    input   logic   [4 :0]  regfile_waddr_i,
    input   logic           regfile_we_i,
    input   logic   [WB_WR_MUX_OP_WIDTH-1:0] regfile_wr_mux_i,
    input   logic           mem_req_i,
    input   logic           mem_we_i,
    input   logic   [2 :0]  mem_type_i,
    input   logic   [BRCH_OP_WIDTH-1:0] branch_type_i,

    // handle branches
    output  logic           branch_decision_o,
    output  logic   [31:0]  branch_target_o,

    // to controller
    output  logic   [4 :0]  rs1_raddr_o,
    output  logic   [4 :0]  rs2_raddr_o,
    output  logic           rs1_used_o,
    output  logic           rs2_used_o,

    // EX-MEM Pipeline
    output  logic   [31:0]  pc_ex_o,
    output  logic   [31:0]  alu_result_mem_o,
    output  logic   [4 :0]  regfile_waddr_mem_o,
    output  logic           regfile_we_mem_o,
    output  logic   [WB_WR_MUX_OP_WIDTH-1:0] regfile_wr_mux_mem_o,
    output  logic           mem_req_mem_o,
    output  logic           mem_we_mem_o,
    output  logic   [2 :0]  mem_type_mem_o,
    output  logic   [31:0]  mem_wdata_mem_o,

    // Forward Data
    input   logic   [31:0]  regfile_wdata_mem_i,
    input   logic   [31:0]  regfile_wdata_wb_i,
    input   logic   [1 :0]  rs1_forward_i,
    input   logic   [1 :0]  rs2_forward_i
);

    // ID-EX Pipeline regs
    logic   [31:0]  pc_ex;
    logic           alu_en;
    logic   [ALU_OP_WIDTH-1:0] alu_op;
    logic   [ALU_SRC_WIDTH-1:0] alu_src_1;
    logic   [ALU_SRC_WIDTH-1:0] alu_src_2;
    logic   [4 :0]  rs1_raddr;
    logic   [4 :0]  rs2_raddr;
    logic   [31:0]  rs1_rdata;
    logic   [31:0]  rs2_rdata;
    logic           rs1_used;
    logic           rs2_used;
    logic   [31:0]  imm;
    logic   [4 :0]  regfile_waddr;
    logic           regfile_we;
    logic   [WB_WR_MUX_OP_WIDTH-1:0] regfile_wr_mux;
    logic           mem_req;
    logic           mem_we;
    logic   [2 :0]  mem_type;
    logic   [BRCH_OP_WIDTH-1:0] branch_type;

    // datapath signals in EX
    logic   [31:0]  rs1_rdata_fw;
    logic   [31:0]  rs2_rdata_fw;
    logic   [31:0]  alu_operand_a;
    logic   [31:0]  alu_operand_b;

    // signals for EX-MEM Pipeline
    logic   [31:0]  alu_result;

    // ID-EX Pipeline
    always_ff @( posedge clk, negedge rst_n ) begin : ID_EX_PIPELINE
        if(clear_ex_i | (~rst_n)) begin
            // clear all pipeline regs
            // pc not included
            alu_en              <= 1'b0;
            alu_op              <= '0;
            alu_src_1           <= '0;
            alu_src_2           <= '0;
            rs1_raddr           <= '0;
            rs2_raddr           <= '0;
            rs1_rdata           <= '0;
            rs2_rdata           <= '0;
            rs1_used            <= 1'b0;
            rs2_used            <= 1'b0;
            imm                 <= 32'h0;
            regfile_waddr       <= 5'h0;
            regfile_we          <= 1'b0;
            regfile_wr_mux      <= '0;
            mem_req             <= 1'b0;
            mem_we              <= 1'b0;
            mem_type              <= '0;
            branch_type         <= BRCH_NOP;
        end
        else if(~stall_ex_i) begin
            // unstall whole pipeline
            pc_ex               <= pc_id_i;
            alu_en              <= alu_en_i;
            alu_op              <= alu_op_i;
            alu_src_1           <= alu_src_1_i;
            alu_src_2           <= alu_src_2_i;
            rs1_raddr           <= rs1_raddr_i;
            rs2_raddr           <= rs2_raddr_i;
            rs1_rdata           <= rs1_rdata_i;
            rs2_rdata           <= rs2_rdata_i;
            rs1_used            <= rs1_used_i;
            rs2_used            <= rs2_used_i;
            imm                 <= imm_i;
            regfile_waddr       <= regfile_waddr_i;
            regfile_we          <= regfile_we_i;
            regfile_wr_mux      <= regfile_wr_mux_i;
            mem_req             <= mem_req_i;
            mem_we              <= mem_we_i;
            mem_type              <= mem_type_i;
            branch_type         <= branch_type_i;
        end
    end

    // Forward rs1, rs2 data
    always_comb begin : ALU_OP_A_FWD
        rs1_rdata_fw = rs1_rdata;
        case(rs1_forward_i)
            2'b01:  rs1_rdata_fw = regfile_wdata_mem_i;
            2'b10:  rs1_rdata_fw = regfile_wdata_wb_i;
            default: ;
        endcase
    end

    always_comb begin : ALU_OP_B_FWD
        rs2_rdata_fw = rs2_rdata;
        case (rs2_forward_i)
            2'b01:  rs2_rdata_fw = regfile_wdata_mem_i;
            2'b10:  rs2_rdata_fw = regfile_wdata_wb_i; 
            default: ;
        endcase
    end

    // ALU operands select
    always_comb begin : ALU_OP_A_MUX
        alu_operand_a = 32'hdec0de_ff;
        case (alu_src_1)
            ALU_SRC_REG:    alu_operand_a = rs1_rdata_fw;
            ALU_SRC_PC:     alu_operand_a = pc_ex;
            ALU_SRC_IMM:    alu_operand_a = imm;
            default: ;
        endcase
    end

    always_comb begin : ALU_OP_B_MUX
        alu_operand_b = 32'hdec0de_ff;
        case (alu_src_2)
            ALU_SRC_REG:    alu_operand_b = rs2_rdata_fw;
            ALU_SRC_PC:     alu_operand_b = pc_ex;
            ALU_SRC_IMM:    alu_operand_b = imm; 
            default: ;
        endcase
    end

  ////////////////////////////
  //     _    _    _   _    //
  //    / \  | |  | | | |   //
  //   / _ \ | |  | | | |   //
  //  / ___ \| |__| |_| |   //
  // /_/   \_\_____\___/    //
  //                        //
  ////////////////////////////
    alu alu_i
    (
        .alu_en             ( alu_en            ),
        .alu_op             ( alu_op            ),
        .op_a               ( alu_operand_a     ),
        .op_b               ( alu_operand_b     ),

        .result             ( alu_result        )
    );

    // handle branches
    assign branch_target_o = branch_type == BRCH_JALR ? alu_result : pc_ex + imm;
    always_comb begin : BRANCH_DECISION
        branch_decision_o = 1'b0;
        case (branch_type)
            BRCH_BEQ: begin
                if(alu_result == 32'h0)
                    branch_decision_o = 1'b1;
            end 

            BRCH_BNE: begin
                if(alu_result != 32'h0)
                    branch_decision_o = 1'b1;
            end

            BRCH_BLT: begin
                if($signed(alu_result) < 32'h0)
                    branch_decision_o = 1'b1;
            end

            BRCH_BGE: begin
                if($signed(alu_result) >= 32'h0)
                    branch_decision_o = 1'b1;
            end

            BRCH_BLTU: begin
                if($signed(alu_result) < 32'h0)
                    branch_decision_o = 1'b1;
            end

            BRCH_BGEU: begin
                if($signed(alu_result) >= 32'h0)
                    branch_decision_o = 1'b1;
            end

            BRCH_JALR: begin
                branch_decision_o = 1'b1;
            end
            default: ;
        endcase
    end

    // goto controller
    assign rs1_raddr_o = rs1_raddr;
    assign rs2_raddr_o = rs2_raddr;
    assign rs1_used_o = rs1_used;
    assign rs2_used_o = rs2_used;

    // output to mem stage
    assign pc_ex_o              = pc_ex;
    assign alu_result_mem_o     = branch_type == BRCH_JALR ? pc_ex + 32'd4 : alu_result;
    assign regfile_waddr_mem_o  = regfile_waddr;
    assign regfile_we_mem_o     = regfile_we;
    assign regfile_wr_mux_mem_o = regfile_wr_mux;
    assign mem_req_mem_o        = mem_req;
    assign mem_we_mem_o         = mem_we;
    assign mem_type_mem_o         = mem_type;
    assign mem_wdata_mem_o      = rs2_rdata_fw;

endmodule