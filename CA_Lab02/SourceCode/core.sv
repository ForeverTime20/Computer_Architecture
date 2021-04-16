////////////////////////////////////////////////////////////////////////////////
// Engineer:       Jiang Binze - jiangbinze@mail.ustc.edu.cn                  //
//                                                                            //
// Design Name:    Top level module                                           //
// Project Name:   RISCV Core                                                 //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    Top level module of the RISC-V core.                       //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

module RV32Core import core_pkg::*;
#(
    parameter DEBUG             = 0
)
(
    input   logic           CPU_CLK,
    input   logic           CPU_RST,

    // Debug Signals
    input   logic   [31:0]  CPU_Debug_DataRAM_A2,
    input   logic   [31:0]  CPU_Debug_DataRAM_WD2,
    input   logic   [3 :0]  CPU_Debug_DataRAM_WE2,
    output  logic   [31:0]  CPU_Debug_DataRAM_RD2,
    input   logic   [31:0]  CPU_Debug_InstRAM_A2,
    input   logic   [31:0]  CPU_Debug_InstRAM_WD2,
    input   logic   [3 :0]  CPU_Debug_InstRAM_WE2,
    output  logic   [31:0]  CPU_Debug_InstRAM_RD2
);

    logic   [31:0]  pc_if;
    logic   [31:0]  pc_id;
    logic   [31:0]  pc_ex;
    logic   [31:0]  pc_me;
    logic   [31:0]  pc_wb;

    logic           stall_if;
    logic           stall_id;
    logic           stall_ex;
    logic           stall_me;
    logic           stall_wb;
    logic           clear_if;
    logic           clear_id;
    logic           clear_ex;
    logic           clear_me;
    logic           clear_wb;

    // IF-ID
    logic   [31:0]  instr;

  //////////////////////////////////////////////////
  //   ___ _____   ____ _____  _    ____ _____    //
  //  |_ _|  ___| / ___|_   _|/ \  / ___| ____|   //
  //   | || |_    \___ \ | | / _ \| |  _|  _|     //
  //   | ||  _|    ___) || |/ ___ \ |_| | |___    //
  //  |___|_|     |____/ |_/_/   \_\____|_____|   //
  //                                              //
  //////////////////////////////////////////////////
    if_stage
    #(
        .DEBUG              ( DEBUG             )
    )
    if_stage_i
    (
        .clk                ( CPU_CLK           ),
        .rst_n              ( ~CPU_RST          ),

        .stall_if_i         ( stall_if          ),
        .clear_if_i         ( clear_if          ),

        .pc_set_i           ( ),
        .pc_mux_i           ( ),
        .boot_addr_i        ( ),
        .jump_target_id_i   ( ),
        .branch_target_ex_i ( ),

        // IF-ID Pipeline
        .pc_if_o            ( pc_if             )
        // .instr_o            ( instr             )
    );

  /////////////////////////////////////////////////
  //   ___ ____    ____ _____  _    ____ _____   //
  //  |_ _|  _ \  / ___|_   _|/ \  / ___| ____|  //
  //   | || | | | \___ \ | | / _ \| |  _|  _|    //
  //   | || |_| |  ___) || |/ ___ \ |_| | |___   //
  //  |___|____/  |____/ |_/_/   \_\____|_____|  //
  //                                             //
  /////////////////////////////////////////////////
    id_stage
    #(
        .DEBUG              ( DEBUG             )
    )
    id_stage_i
    (
        .clk                ( CPU_CLK           ),
        .rst_n              ( ~CPU_RST          ),

        .stall_id_i         ( stall_id          ),
        .clear_id_i         ( clear_id          ),

        // From IF stage
        .pc_if_i            ( pc_if             ),
        // .instr_i            ( instr             ),

        // jumps in id
        .jump_decision_o    ( ),
        .jump_target_o      ( ),

        // ID-EX Pipeline
        .pc_id_o            ( pc_id             ),
        .alu_en_ex_o        (          ),
        .alu_op_ex_o        (          ),
        .alu_src_1_ex_o     ( ),
        .alu_src_2_ex_o     ( ),
        .rs1_raddr_ex_o     ( ),
        .rs2_raddr_ex_o     ( ),
        .rs1_rdata_ex_o     ( ),
        .rs2_rdata_ex_o     ( ),
        .rs1_used_ex_o      ( ),
        .rs2_used_ex_o      ( ),
        .imm_ex_o           ( ),
        .regfile_waddr_ex_o ( ),
        .regfile_we_ex_o    ( ),
        .regfile_wr_mux_ex_o( ),
        .mem_req_ex_o       ( ),
        .mem_we_ex_o        ( ),
        .mem_type_ex_o        ( ),
        .branch_type_ex_o   ( ),

        // From WB stage
        .regfile_waddr_wb_i ( ),
        .regfile_we_wb_i    ( ),
        .regfile_wdata_wb_i ( )
    );

  /////////////////////////////////////////////////////
  //   _______  __  ____ _____  _    ____ _____      //
  //  | ____\ \/ / / ___|_   _|/ \  / ___| ____|     //
  //  |  _|  \  /  \___ \ | | / _ \| |  _|  _|       //
  //  | |___ /  \   ___) || |/ ___ \ |_| | |___      //
  //  |_____/_/\_\ |____/ |_/_/   \_\____|_____|     //
  //                                                 //
  /////////////////////////////////////////////////////
    ex_stage
    #(
        .DEBUG              ( DEBUG             )
    )
    ex_stage_i
    (
        .clk                ( CPU_CLK           ),
        .rst_n              ( ~CPU_RST          ),

        .stall_ex_i         ( stall_ex          ),
        .clear_ex_i         ( clear_ex          ),

        // From ID stage
        .pc_id_i            ( pc_id             ),
        .alu_en_i           ( ),
        .alu_op_i           ( ),
        .alu_src_1_i        ( ),
        .alu_src_2_i        ( ),
        .rs1_raddr_i        ( ),
        .rs2_raddr_i        ( ),
        .rs1_rdata_i        ( ),
        .rs2_rdata_i        ( ),
        .rs1_used_i         ( ),
        .rs2_used_i         ( ),
        .imm_i              ( ),
        .regfile_waddr_i    ( ),
        .regfile_we_i       ( ),
        .regfile_wr_mux_i   ( ),
        .mem_req_i          ( ),
        .mem_we_i           ( ),
        .mem_type_i           ( ),
        .branch_type_i      ( ),

        // handle branches
        .branch_decision_o  ( ),
        .branch_target_o    ( ),

        // to controller
        .rs1_raddr_o        ( ),
        .rs2_raddr_o        ( ),
        .rs1_used_o         ( ),
        .rs2_used_o         ( ),

        // EX-MEM Pipeline
        .pc_ex_o            ( pc_ex             ),
        .alu_result_mem_o   ( ),
        .regfile_waddr_mem_o( ),
        .regfile_we_mem_o   ( ),
        .regfile_wr_mux_mem_o( ),
        .mem_req_mem_o      ( ),
        .mem_we_mem_o       ( ),
        .mem_type_mem_o       ( ),
        .mem_wdata_mem_o    ( ),
        
        // Forward Data
        .regfile_wdata_mem_i( ),
        .regfile_wdata_wb_i ( ),
        .rs1_forward_i      ( ),
        .rs2_forward_i      ( )
    );

    // MEM stage
    mem_stage
    #( 
        .DEBUG              ( DEBUG             )
    )
    mem_stage_i
    (
        .clk                ( CPU_CLK           ),
        .rst_n              ( ~CPU_RST          ),

        .stall_mem_i        ( stall_me          ),
        .clear_mem_i        ( clear_me          ),

        // From EX
        .pc_ex_i            ( pc_ex             ),
        .alu_result_i       ( ),
        .regfile_waddr_i    ( ),
        .regfile_we_i       ( ),
        .regfile_wr_mux_i   ( ),
        .mem_req_i          ( ),
        .mem_we_i           ( ),
        .mem_type_i           ( ),
        .mem_wdata_i        ( ),

        // to controller
        .mem_req_o          ( ),    // used to justify whether it is a load instr
        .regfile_waddr_o    ( ),
        .regfile_we_o       ( ),
        // forward
        .regfile_wdata_o    ( ),

        // MEM-WB Pipeline
        .pc_mem_o           ( pc_me            ),
        .mem_req_wb_o       ( ),
        .mem_we_wb_o        ( ),
        .mem_be_wb_o        ( ),
        .mem_type_wb_o      ( ),
        .mem_addr_wb_o      ( ),
        .mem_wdata_wb_o     ( ),
        .regfile_waddr_wb_o ( ),
        .regfile_wdata_wb_o ( ),
        .regfile_we_wb_o    ( ),
        .regfile_wr_mux_wb_o( )
    );

    // WB stage
    wb_stage
    #(
        .DEBUG              ( DEBUG             )
    )
    wb_stage_i
    (
        .clk                ( CPU_CLK           ),
        .rst_n              ( ~CPU_RST          ),
        
        .stall_wb_i         ( stall_wb          ),
        .clear_wb_i         ( clear_wb          ),

        // From MEM
        .pc_mem_i           ( pc_me             ),
        .mem_req_i          ( ),
        .mem_we_i           ( ),
        .mem_be_i           ( ),
        .mem_type_i         ( ),
        .mem_addr_i         ( ),
        .mem_wdata_i        ( ),
        .regfile_waddr_i    ( ),
        .regfile_wdata_i    ( ),
        .regfile_we_i       ( ),
        .regfile_wr_mux_i   ( ),

        // out
        .regfile_waddr_o    ( ),
        .regfile_wdata_o    ( ),
        .regfile_we_o       ( )
    );

endmodule