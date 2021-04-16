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
    
    // ID-EX
    logic           alu_ex_ex;
    logic   [ALU_OP_WIDTH-1:0]  alu_op_ex;
    logic   [ALU_SRC_WIDTH-1:0] alu_src_1_ex;
    logic   [ALU_SRC_WIDTH-1:0] alu_src_2_ex;
    logic   [4 :0]  rs1_raddr_ex;
    logic   [4 :0]  rs2_raddr_ex;
    logic   [31:0]  rs1_rdata_ex;
    logic   [31:0]  rs2_rdata_ex;
    logic           rs1_used_ex;
    logic           rs2_used_ex;
    logic   [31:0]  imm_ex;
    logic   [4 :0]  regfile_waddr_ex;
    logic           regfile_we_ex;
    logic   [WB_WR_MUX_OP_WIDTH-1:0] regfile_wr_mux_ex;
    logic           mem_req_ex;
    logic           mem_we_ex;
    logic   [2 :0]  mem_type_ex;
    logic   [BRCH_OP_WIDTH-1:0] branch_type_ex;

    // EX-MEM
    logic   [31:0]  alu_result_mem;
    logic   [4 :0]  regfile_waddr_mem;
    logic           regfile_we_mem;
    logic   [WB_WR_MUX_OP_WIDTH-1:0] regfile_wr_mux_mem;
    logic           mem_req_mem;
    logic           mem_we_mem;
    logic   [2 :0]  mem_type_mem;
    logic   [31:0]  mem_wdata_mem;

    // MEM-WB
    logic           mem_req_wb;
    logic           mem_we_wb;
    logic   [3 :0]  mem_be_wb;
    logic   [2 :0]  mem_type_wb;
    logic   [31:0]  mem_addr_wb;
    logic   [31:0]  mem_wdata_wb;
    logic   [4 :0]  regfile_waddr_wb;
    logic   [31:0]  regfile_wdata_wb;
    logic           regfile_we_wb;
    logic   [WB_WR_MUX_OP_WIDTH-1:0] regfile_wr_mux_wb;

    // WB out
    logic   [4 :0]  regfile_waddr;
    logic   [31:0]  regfile_wdata;
    logic           regfile_we;

    // TO Controller
    logic           jump_decision;
    logic           branch_decision;
    logic           pc_set;
    logic   [3 :0]  pc_mux;
    logic   [4 :0]  rs1_raddr;
    logic   [4 :0]  rs2_raddr;
    logic           rs1_used;
    logic           rs2_used;
    logic           mem_req;
    logic   [4 :0]  regfile_waddr_ctrl_m;
    logic           regfile_we_ctrl_m;
    logic   [4 :0]  regfile_waddr_ctrl_w;
    logic           regfile_we_ctrl_w;

    // Forward signals
    logic   [31:0]  regfile_wdata_fw_mem;
    logic   [31:0]  regfile_wdata_fw_wb = regfile_wdata;
    logic   [1 :0]  rs1_forward;
    logic   [1 :0]  rs2_forward;
    // Jumps and Branches
    logic   [31:0]  jump_target;
    logic   [31:0]  branch_target;

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

        .pc_set_i           ( pc_set            ),
        .pc_mux_i           ( pc_mux            ),
        .boot_addr_i        ( 32'h0             ),
        .jump_target_id_i   ( jump_target       ),
        .branch_target_ex_i ( branch_target     ),

        // IF-ID Pipeline
        .pc_if_o            ( pc_if             )
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

        // jumps in id
        .jump_decision_o    ( jump_decision     ),
        .jump_target_o      ( branch_decision   ),

        // ID-EX Pipeline
        .pc_id_o            ( pc_id             ),
        .alu_en_ex_o        ( alu_en_ex         ),
        .alu_op_ex_o        ( alu_op_ex         ),
        .alu_src_1_ex_o     ( alu_src_1_ex      ),
        .alu_src_2_ex_o     ( alu_src_2_ex      ),
        .rs1_raddr_ex_o     ( rs1_raddr_ex      ),
        .rs2_raddr_ex_o     ( rs2_raddr_ex      ),
        .rs1_rdata_ex_o     ( rs1_rdata_ex      ),
        .rs2_rdata_ex_o     ( rs2_rdata_ex      ),
        .rs1_used_ex_o      ( rs1_used_ex       ),
        .rs2_used_ex_o      ( rs2_used_ex       ),
        .imm_ex_o           ( imm_ex            ),
        .regfile_waddr_ex_o ( regfile_waddr_ex  ),
        .regfile_we_ex_o    ( regfile_we_ex     ),
        .regfile_wr_mux_ex_o( regfile_wr_mux_ex ),
        .mem_req_ex_o       ( mem_req_ex        ),
        .mem_we_ex_o        ( mem_we_ex         ),
        .mem_type_ex_o      ( mem_type_ex       ),
        .branch_type_ex_o   ( branch_type_ex    ),

        // From WB stage
        .regfile_waddr_wb_i ( regfile_waddr     ),
        .regfile_we_wb_i    ( regfile_we        ),
        .regfile_wdata_wb_i ( regfile_wdata     )
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
        .alu_en_i           ( alu_en_ex         ),       
        .alu_op_i           ( alu_op_ex         ),
        .alu_src_1_i        ( alu_src_1_ex      ),
        .alu_src_2_i        ( alu_src_2_ex      ),
        .rs1_raddr_i        ( rs1_raddr_ex      ),
        .rs2_raddr_i        ( rs2_raddr_ex      ),
        .rs1_rdata_i        ( rs1_rdata_ex      ),
        .rs2_rdata_i        ( rs2_rdata_ex      ),
        .rs1_used_i         ( rs1_used_ex       ),
        .rs2_used_i         ( rs2_used_ex       ),
        .imm_i              ( imm_ex            ),
        .regfile_waddr_i    ( regfile_waddr_ex  ),
        .regfile_we_i       ( regfile_we_ex     ),
        .regfile_wr_mux_i   ( regfile_wr_mux_ex ),
        .mem_req_i          ( mem_req_ex        ),
        .mem_we_i           ( mem_we_ex         ),
        .mem_type_i         ( mem_type_ex       ),
        .branch_type_i      ( branch_type_ex    ),

        // handle branches
        .branch_decision_o  ( branch_decision   ),
        .branch_target_o    ( branch_target     ),

        // to controller
        .rs1_raddr_o        ( rs1_raddr         ),
        .rs2_raddr_o        ( rs2_raddr         ),
        .rs1_used_o         ( rs1_used          ),
        .rs2_used_o         ( rs2_used          ),

        // EX-MEM Pipeline
        .pc_ex_o            ( pc_ex             ),
        .alu_result_mem_o   ( alu_result_mem    ),
        .regfile_waddr_mem_o( regfile_waddr_mem ),
        .regfile_we_mem_o   ( regfile_we_mem    ),
        .regfile_wr_mux_mem_o(regfile_wr_mux_mem),
        .mem_req_mem_o      ( mem_req_mem       ),
        .mem_we_mem_o       ( mem_we_mem        ),
        .mem_type_mem_o     ( mem_type_mem      ),
        .mem_wdata_mem_o    ( mem_wdata_mem     ),
        
        // Forward Data
        .regfile_wdata_mem_i( regfile_wdata_fw_mem),
        .regfile_wdata_wb_i ( regfile_wdata_fw_wb),
        .rs1_forward_i      ( rs1_forward       ),
        .rs2_forward_i      ( rs2_forward       )
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
        .alu_result_i       ( alu_result_mem    ),
        .regfile_waddr_i    ( regfile_waddr_mem ),
        .regfile_we_i       ( regfile_we_mem    ),
        .regfile_wr_mux_i   ( regfile_wr_mux_mem),
        .mem_req_i          ( mem_req_mem       ),
        .mem_we_i           ( mem_we_mem        ),
        .mem_type_i         ( mem_type_mem      ),
        .mem_wdata_i        ( mem_wdata_mem     ),

        // to controller
        .mem_req_o          ( mem_req           ),    // used to justify whether it is a load instr
        .regfile_waddr_o    ( regfile_waddr_ctrl_m),
        .regfile_we_o       ( regfile_we_ctrl_m),
        // forward
        .regfile_wdata_o    ( regfile_wdata_fw_mem),

        // MEM-WB Pipeline
        .pc_mem_o           ( pc_me             ),
        .mem_req_wb_o       ( mem_req_wb        ), 
        .mem_we_wb_o        ( mem_we_wb         ),
        .mem_be_wb_o        ( mem_be_wb         ),
        .mem_type_wb_o      ( mem_type_wb       ),
        .mem_addr_wb_o      ( mem_addr_wb       ),
        .mem_wdata_wb_o     ( mem_wdata_wb      ),
        .regfile_waddr_wb_o ( regfile_waddr_wb  ),
        .regfile_wdata_wb_o ( regfile_wdata_wb  ),
        .regfile_we_wb_o    ( regfile_we_wb     ),
        .regfile_wr_mux_wb_o( regfile_wr_mux_wb )
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
        .mem_req_i          ( mem_req_wb        ),
        .mem_we_i           ( mem_we_wb         ),
        .mem_be_i           ( mem_be_wb         ),
        .mem_type_i         ( mem_type_wb       ),
        .mem_addr_i         ( mem_addr_wb       ),
        .mem_wdata_i        ( mem_wdata_wb      ),
        .regfile_waddr_i    ( regfile_waddr_wb  ),
        .regfile_wdata_i    ( regfile_wdata_wb  ),
        .regfile_we_i       ( regfile_we_wb     ),
        .regfile_wr_mux_i   ( regfile_wr_mux_wb ),

        // out
        .regfile_waddr_o    ( regfile_waddr     ),
        .regfile_wdata_o    ( regfile_wdata     ),
        .regfile_we_o       ( regfile_we        )
    );

endmodule