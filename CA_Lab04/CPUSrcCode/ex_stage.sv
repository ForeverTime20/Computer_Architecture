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
    parameter DEBUG          = 0,
    parameter USE_BTB        = 0,
    parameter USE_BHT        = 0

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
    input   logic   [CSR_ADDR_WIDTH-1:0] csr_addr_i,
    input   logic   [2 :0]  csr_type_i,
    input   logic           csr_we_i,
    input   logic           branch_prediction_i,

    // handle branches
    output  logic           branch_decision_o,
    output  logic   [31:0]  branch_target_o,
    output  logic           branch_prediction_o,
    output  logic           branch_in_ex_o,

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
    logic   [CSR_ADDR_WIDTH-1:0] csr_addr;
    logic   [2 :0]  csr_type;
    logic           csr_we;
    logic           branch_prediction;

    // datapath signals in EX
    logic   [31:0]  rs1_rdata_fw;
    logic   [31:0]  rs2_rdata_fw;
    logic   [31:0]  alu_operand_a;
    logic   [31:0]  alu_operand_b;
    logic   [CSR_ADDR_WIDTH-1:0] csr_raddr_a;
    logic   [CSR_XLEN-1:0] csr_rdata_a;
    logic   [CSR_ADDR_WIDTH-1:0] csr_raddr_b;
    logic   [CSR_XLEN-1:0] csr_rdata_b;
    logic   [CSR_ADDR_WIDTH-1:0] csr_waddr_a;
    logic   [CSR_XLEN-1:0] csr_wdata_a;

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
            mem_type            <= '0;
            branch_type         <= BRCH_NOP;
            csr_addr            <= '0;
            csr_type            <= CSR_NONE;
            csr_we              <= 1'b0;
            branch_prediction   <= 1'b0;
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
            mem_type            <= mem_type_i;
            branch_type         <= branch_type_i;
            csr_addr            <= csr_addr_i;
            csr_type            <= csr_type_i;
            csr_we              <= csr_we_i;
            branch_prediction   <= branch_prediction_i;
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
            ALU_SRC_CSR:    alu_operand_a = csr_rdata_a;
            default: ;
        endcase
    end

    always_comb begin : ALU_OP_B_MUX
        alu_operand_b = 32'hdec0de_ff;
        case (alu_src_2)
            ALU_SRC_REG:    alu_operand_b = rs2_rdata_fw;
            ALU_SRC_PC:     alu_operand_b = pc_ex;
            ALU_SRC_IMM:    alu_operand_b = imm; 
            ALU_SRC_CSR:    alu_operand_b = csr_rdata_b;
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
    assign branch_target_o      = alu_result;
    assign branch_prediction_o  = branch_prediction;
    assign branch_in_ex_o       = branch_type == BRCH_NOP ? 0 : 1;
    always_comb begin : BRANCH_DECISION
        branch_decision_o = 1'b0;
        case (branch_type)
            BRCH_BEQ: begin
                if(rs1_rdata_fw == rs2_rdata_fw)
                    branch_decision_o = 1'b1;
            end 

            BRCH_BNE: begin
                if(rs1_rdata_fw != rs2_rdata_fw)
                    branch_decision_o = 1'b1;
            end

            BRCH_BLT: begin
                if($signed(rs1_rdata_fw) < $signed(rs2_rdata_fw))
                    branch_decision_o = 1'b1;
            end

            BRCH_BGE: begin
                if($signed(rs1_rdata_fw) >= $signed(rs2_rdata_fw))
                    branch_decision_o = 1'b1;
            end

            BRCH_BLTU: begin
                if(rs1_rdata_fw < rs2_rdata_fw)
                    branch_decision_o = 1'b1;
            end

            BRCH_BGEU: begin
                if(rs1_rdata_fw >= rs2_rdata_fw)
                    branch_decision_o = 1'b1;
            end

            BRCH_JALR: begin
                branch_decision_o = 1'b1;
            end
            default: ;
        endcase
    end

  //////////////////////////////////////
  //        ____ ____  ____           //
  //       / ___/ ___||  _ \ ___      //
  //      | |   \___ \| |_) / __|     //
  //      | |___ ___) |  _ <\__ \     //
  //       \____|____/|_| \_\___/     //
  //                                  //
  //   Control and Status Registers   //
  //////////////////////////////////////
    assign csr_raddr_a  = csr_addr;
    assign csr_raddr_b  = csr_addr;
    assign csr_waddr_a  = csr_addr;
    always_comb begin :CSR_WDATA
        csr_wdata_a = alu_result;
        case (csr_type)
            CSR_RC:  csr_wdata_a = csr_rdata_b & {~rs1_rdata_fw};
            CSR_RCI: csr_wdata_a = csr_rdata_b & {27'b1, {~imm[4:0]}};
            CSR_RSI: csr_wdata_a = csr_rdata_b | {27'b0, imm[4:0]};
            CSR_RW:  csr_wdata_a = rs1_rdata_fw;
            CSR_RWI: csr_wdata_a = imm;
            default: ;
        endcase
    end
    csr_registers
    #(
        .DEBUG              ( DEBUG             ),
        .XLEN               ( CSR_XLEN          ),
        .CSR_NUM            ( CSR_NUM           )
    )
    csr_registers_i
    (
        .clk                ( clk               ),
        .rst_n              ( rst_n             ),
        
        .raddr_a_i          ( csr_raddr_a       ),
        .rdata_a_o          ( csr_rdata_a       ),

        .raddr_b_i          ( csr_raddr_b       ),
        .rdata_b_o          ( csr_rdata_b       ),

        .waddr_a_i          ( csr_waddr_a       ),
        .wdata_a_i          ( csr_wdata_a       ),
        .we_a_i             ( csr_we            )    
    );

    // goto controller
    assign rs1_raddr_o = rs1_raddr;
    assign rs2_raddr_o = rs2_raddr;
    assign rs1_used_o = rs1_used;
    assign rs2_used_o = rs2_used;

    // output to mem stage
    assign pc_ex_o              = pc_ex;
    // alert: in some cases, alu_result output is not really from alu
    assign alu_result_mem_o     = csr_type == CSR_NONE ? (branch_type == BRCH_JALR ? pc_ex + 32'd4 : alu_result) : csr_rdata_b;
    assign regfile_waddr_mem_o  = regfile_waddr;
    assign regfile_we_mem_o     = regfile_we;
    assign regfile_wr_mux_mem_o = regfile_wr_mux;
    assign mem_req_mem_o        = mem_req;
    assign mem_we_mem_o         = mem_we;
    assign mem_type_mem_o         = mem_type;
    assign mem_wdata_mem_o      = rs2_rdata_fw;

endmodule