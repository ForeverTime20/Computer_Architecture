////////////////////////////////////////////////////////////////////////////////
// Engineer:       Jiang Binze - jiangbinze@mail.ustc.edu.cn                  //
//                                                                            //
// Design Name:    id_stage module                                            //
// Project Name:   RISCV Core                                                 //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    Decode Instruction in this stage                           //
//                 (instruction fetch is done here)                           //
//                                                                            //
// Mother Module Name:                                                        //
//                 core                                                       //
////////////////////////////////////////////////////////////////////////////////

module id_stage import core_pkg::*;
#(
    parameter DDEBUG        = 0
)
(
    input   logic           clk,
    input   logic           rst_n,

    input   logic           stall_id_i,
    input   logic           clear_id_i,

    input   logic   [31:0]  pc_if_i,

    output  logic           jump_decision_o,
    output  logic   [31:0]  jump_target_o,

    output  logic   [31:0]  pc_id_o,
    output  logic           alu_en_ex_o,
    output  logic   [ALU_OP_WIDTH-1:0]  alu_op_ex_o,
    output  logic   [3 :0]  alu_src_1_ex_o,
    output  logic   [3 :0]  alu_src_2_ex_o,
    output  logic   [4 :0]  rs1_raddr_ex_o,
    output  logic   [4 :0]  rs2_raddr_ex_o,
    output  logic   [31:0]  rs1_rdata_ex_o,
    output  logic   [31:0]  rs2_rdata_ex_o,
    output  logic           rs1_used_ex_o,
    output  logic           rs2_used_ex_o,
    output  logic   [31:0]  imm_ex_o,
    output  logic   [4 :0]  regfile_waddr_ex_o,
    output  logic           regfile_we_ex_o,
    output  logic   [3 :0]  regfile_wr_mux_ex_o,
    output  logic           mem_req_ex_o,
    output  logic           mem_we_ex_o,
    output  logic   [3 :0]  mem_be_ex_o,
    output  logic   [BRCH_OP_WIDTH-1:0] branch_type_ex_o,

    input   logic   [4 :0]  regfile_waddr_wb_i,
    input   logic           regfile_we_wb_i,
    input   logic   [31:0]  regfile_wdata_i
);

  // Source/Destination register instruction index
    localparam REG_S1_MSB = 19;
    localparam REG_S1_LSB = 15;

    localparam REG_S2_MSB = 24;
    localparam REG_S2_LSB = 20;

    localparam REG_S4_MSB = 31;
    localparam REG_S4_LSB = 27;

    localparam REG_D_MSB  = 11;
    localparam REG_D_LSB  = 7;


    logic   [31:0]  instr_raw;
    logic   [31:0]  instr;
    logic   [31:0]  instr_old;
    logic   [31:0]  pc_id;
    logic           stall_ff;
    logic           clear_ff;

    // datapath signals
    logic   [4 :0]  rs1_raddr;
    logic   [4 :0]  rs2_raddr;
    logic   [31:0]  rs1_rdata;
    logic   [31:0]  rs2_rdata;
    logic   [31:0]  imm;
    logic   [31:0]  imm_i_type;
    logic   [31:0]  imm_iz_type;
    logic   [31:0]  imm_s_type;
    logic   [31:0]  imm_sb_type;
    logic   [31:0]  imm_u_type;
    logic   [31:0]  imm_uj_type;
    logic   [4 :0]  regfile_waddr;

    // control signals
    logic           alu_en;
    logic   [ALU_OP_WIDTH-1:0]  alu_op;
    logic   [3 :0]  alu_src_1;
    logic   [3 :0]  alu_src_2;
    logic           rs1_used;
    logic           rs2_used;
    logic           mem_req;
    logic           mem_we;
    logic   [3 :0]  mem_be;
    logic           regfile_we;
    logic   [3 :0]  regfile_wr_mux;
    logic   [BRCH_OP_WIDTH-1:0] branch_type;


    // IF-ID Seg Reg
    // InstructionRam InstructionRamInst (
    //      .clk    ( clk        ),
    //      .addra  ( pc_if_i    ),
    //      .douta  ( instr_raw  ),
    //      .web    ( |WE2       ),
    //      .addrb  ( A2[31:2]   ),
    //      .dinb   ( WD2        ),
    //      .doutb  ( RD2        )
    //  );

    always_ff @( posedge clk ) begin : PC_ID
        if(~stall_id_i)
            pc_id   <= clear_id_i ? 32'h0 : pc_if_i;
    end

    always_ff @( posedge clk ) begin : SYN_ID_INSTR
        stall_ff    <= stall_id_i;
        clear_ff    <= clear_id_i;
        instr_old   <= instr_raw;
    end

    assign  instr   = stall_ff ? instr_old : (clear_ff ? 32'h0 : instr_raw);

    // end of IF-ID Seg Reg

    // datapath
    assign  rs1_raddr   = instr[REG_S1_MSB:REG_S1_LSB];
    assign  rs2_raddr   = instr[REG_S2_MSB:REG_S2_LSB];
    assign  imm_i_type  = { {20 {instr[31]}}, instr[31:20] };
    assign  imm_iz_type = {            20'b0, instr[31:20] };
    assign  imm_s_type  = { {20 {instr[31]}}, instr[31:25], instr[11:7] };
    assign  imm_sb_type = { {20 {instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0 };
    assign  imm_u_type  = { instr[31:12], 12'b0 };
    assign  imm_uj_type = { {12 {instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0 };
    assign  regfile_waddr=instr[REG_D_MSB:REG_D_LSB];

    

endmodule