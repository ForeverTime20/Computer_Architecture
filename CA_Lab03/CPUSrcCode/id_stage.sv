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
    parameter DEBUG        = 0,
    parameter USE_RAM_IP   = 0,
    parameter USE_CACHE    = 0
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
    output  logic   [ALU_SRC_WIDTH-1 :0]  alu_src_1_ex_o,
    output  logic   [ALU_SRC_WIDTH-1 :0]  alu_src_2_ex_o,
    output  logic   [4 :0]  rs1_raddr_ex_o,
    output  logic   [4 :0]  rs2_raddr_ex_o,
    output  logic   [31:0]  rs1_rdata_ex_o,
    output  logic   [31:0]  rs2_rdata_ex_o,
    output  logic           rs1_used_ex_o,
    output  logic           rs2_used_ex_o,
    output  logic   [31:0]  imm_ex_o,
    output  logic   [4 :0]  regfile_waddr_ex_o,
    output  logic           regfile_we_ex_o,
    output  logic   [WB_WR_MUX_OP_WIDTH-1:0] regfile_wr_mux_ex_o,
    output  logic           mem_req_ex_o,
    output  logic           mem_we_ex_o,
    output  logic   [2 :0]  mem_type_ex_o,
    output  logic   [BRCH_OP_WIDTH-1:0] branch_type_ex_o,
    output  logic   [CSR_ADDR_WIDTH-1:0] csr_addr_ex_o,
    output  logic   [2 :0]  csr_type_ex_o,
    output  logic           csr_we_ex_o,   

    input   logic   [4 :0]  regfile_waddr_wb_i,
    input   logic           regfile_we_wb_i,
    input   logic   [31:0]  regfile_wdata_wb_i
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

    localparam IMM_OP_WIDTH     = 3;
    localparam IMM_I            = 0;
    localparam IMM_IZ           = 1;
    localparam IMM_S            = 2;
    localparam IMM_SB           = 3;
    localparam IMM_U            = 4;
    localparam IMM_UJ           = 5;
    localparam IMM_FOUR         = 6;
    localparam IMM_Z            = 7;


    logic   [31:0]  instr_raw;
    logic   [31:0]  instr;
    logic   [31:0]  instr_old;
    logic   [31:0]  pc_id;
    logic           stall_ff;
    logic           clear_ff;

    // datapath signals
    logic   [31:0]  jump_target;
    logic   [4 :0]  rs1_raddr;
    logic   [4 :0]  rs2_raddr;
    logic   [31:0]  rs1_rdata;
    logic   [31:0]  rs2_rdata;
    logic   [31:0]  imm_i_type;
    logic   [31:0]  imm_iz_type;
    logic   [31:0]  imm_z_type;
    logic   [31:0]  imm_s_type;
    logic   [31:0]  imm_sb_type;
    logic   [31:0]  imm_u_type;
    logic   [31:0]  imm_uj_type;
    logic   [4 :0]  regfile_waddr;

    // control signals
    logic           jump_decision;
    logic           alu_en;
    logic   [ALU_OP_WIDTH-1:0]  alu_op;
    logic   [ALU_SRC_WIDTH-1 :0]  alu_src_1;
    logic   [ALU_SRC_WIDTH-1 :0]  alu_src_2;
    logic           rs1_used;
    logic           rs2_used;
    logic           mem_req;
    logic           mem_we;
    logic   [2 :0]  mem_type;
    logic           regfile_we;
    logic   [WB_WR_MUX_OP_WIDTH-1:0]  regfile_wr_mux;
    logic   [BRCH_OP_WIDTH-1:0] branch_type;
    logic   [CSR_ADDR_WIDTH-1:0] csr_addr;
    logic   [2 :0]  csr_type;
    logic           csr_we;

    // control signals only in ID
    logic           illegal_instr;
    logic   [IMM_OP_WIDTH-1:0]  imm_sel;

generate
    if(USE_RAM_IP) begin: GEN_INST_IP
        I_RAM I_RAM_i
        (
            .clka           ( clk               ),
            .addra          ( {pc_if_i[17:2]} ),
            .douta          ( instr_raw         )
        );
    end
    else begin
        // IF-ID Seg Reg
        InstructionRam InstructionRamInst (
            .clk    ( clk        ),
            .addra  ( pc_if_i    ),
            .douta  ( instr_raw  ),
            .web    ( 1'b0       ),
            .addrb  ( 32'h0      ),
             .dinb   ( 32'h0      ),
            .doutb  (            )
        );
    end
endgenerate

    always_ff @( posedge clk ) begin : PC_ID
        if(~stall_id_i)
            pc_id   <= clear_id_i ? 32'h0 : pc_if_i;
    end

    always_ff @( posedge clk ) begin : SYN_ID_INSTR
        stall_ff    <= stall_id_i;
        clear_ff    <= clear_id_i;
        instr_old   <= instr_raw;
    end

    assign  instr   = stall_ff ? instr_old : (clear_ff ? 32'h0000_0013 : instr_raw);

    // end of IF-ID Seg Reg

    // datapath
    assign  jump_target = pc_id + imm_uj_type;
    assign  rs1_raddr   = instr[REG_S1_MSB:REG_S1_LSB];
    assign  rs2_raddr   = instr[REG_S2_MSB:REG_S2_LSB];
    assign  imm_i_type  = { {20 {instr[31]}}, instr[31:20] };
    assign  imm_iz_type = {            20'b0, instr[31:20] };
    assign  imm_z_type  = {            27'b0, instr[19:15] };
    assign  imm_s_type  = { {20 {instr[31]}}, instr[31:25], instr[11:7] };
    assign  imm_sb_type = { {19 {instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0 };
    assign  imm_u_type  = { instr[31:12], 12'b0 };
    assign  imm_uj_type = { {12 {instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0 };
    assign  regfile_waddr=instr[REG_D_MSB:REG_D_LSB];
    assign  csr_addr    = instr[31:20];

    register_file
    #(
        .DEBUG              ( DEBUG              ),
        .ADDR_WIDTH         ( 5                  ),
        .DATA_WIDTH         ( 32                 )
    )
    register_file_i
    (
        .clk                ( clk                ),
        .rst_n              ( rst_n              ),

        // Read port a
        .raddr_a_i          ( rs1_raddr          ),
        .rdata_a_o          ( rs1_rdata          ),

        // Read port b
        .raddr_b_i          ( rs2_raddr          ),
        .rdata_b_o          ( rs2_rdata          ),

        // Write port a
        .waddr_a_i          ( regfile_waddr_wb_i ),
        .wdata_a_i          ( regfile_wdata_wb_i ),
        .we_a_i             ( regfile_we_wb_i    )
    );

  ///////////////////////////////////////////////
  //  ____  _____ ____ ___  ____  _____ ____   //
  // |  _ \| ____/ ___/ _ \|  _ \| ____|  _ \  //
  // | | | |  _|| |  | | | | | | |  _| | |_) | //
  // | |_| | |__| |__| |_| | |_| | |___|  _ <  //
  // |____/|_____\____\___/|____/|_____|_| \_\ //
  //                                           //
  ///////////////////////////////////////////////
    always_comb begin : DECODER
        jump_decision   = 1'b0;
        alu_en          = 1'b0;
        alu_op          = ALU_ADD;
        alu_src_1       = '0;
        alu_src_2       = '0;
        rs1_used        = 1'b0;
        rs2_used        = 1'b0;
        mem_req         = 1'b0;
        mem_we          = 1'b0;
        mem_type          = 3'b111;   // because 3'b111 is not an option, thus we can detect illegal instr
        regfile_we      = 1'b0;
        regfile_wr_mux  = '0;
        branch_type     = BRCH_NOP;
        csr_type        = CSR_NONE;
        csr_we          = 1'b0;

        illegal_instr   = 1'b0;
        imm_sel         = '0;
        case(instr[6:0])
            OPCODE_JAL: begin
                // Jump and Link
                jump_decision   = 1'b1;
                alu_en          = 1'b1;
                alu_op          = ALU_ADD;
                alu_src_1       = ALU_SRC_PC;
                alu_src_2       = ALU_SRC_IMM;
                regfile_we      = 1'b1;
                regfile_wr_mux  = WB_WR_MUX_ALU;
                imm_sel         = IMM_FOUR;
            end

            OPCODE_JALR: begin
                // Jump and Link Register
                alu_en          = 1'b1;
                alu_op          = ALU_ADD;
                alu_src_1       = ALU_SRC_REG;
                alu_src_2       = ALU_SRC_IMM;
                rs1_used        = 1'b1;
                regfile_we      = 1'b1;
                regfile_wr_mux  = WB_WR_MUX_ALU;
                branch_type     = BRCH_JALR;
                imm_sel         = IMM_I;
            end

            OPCODE_BRANCH: begin
                // Branches
                alu_en          = 1'b1;
                alu_src_1       = ALU_SRC_PC;
                alu_src_2       = ALU_SRC_IMM;
                alu_op          = ALU_ADD;
                rs1_used        = 1'b1;
                rs2_used        = 1'b1;
                branch_type     = {1'b0, instr[14:12]};
                imm_sel         = IMM_SB;
                // case( {1'b0, instr[14:12]} )
                //     BRCH_BEQ, BRCH_BNE,
                //     BRCH_BGE, BRCH_BLT: alu_op  = ALU_SUB;
                //     BRCH_BGEU,BRCH_BLTU:alu_op  = ALU_SUBU;
                //     default: illegal_instr = 1'b1;
                // endcase
            end

            OPCODE_STORE: begin
                alu_en          = 1'b1;
                alu_op          = ALU_ADD;
                alu_src_1       = ALU_SRC_REG;  // addr = rs1 + sext[offset]
                alu_src_2       = ALU_SRC_IMM;
                rs1_used        = 1'b1;
                rs2_used        = 1'b1;
                mem_req         = 1'b1;
                mem_we          = 1'b1;
                imm_sel         = IMM_S;
                // store size
                case (instr[14:12])
                    3'b000: mem_type  = 3'b000; // SB
                    3'b001: mem_type  = 3'b001; // SH
                    3'b010: mem_type  = 3'b010; // SW
                    default: illegal_instr = 1;
                endcase
            end

            OPCODE_LOAD: begin
                alu_en          = 1'b1;
                alu_op          = ALU_ADD;
                alu_src_1       = ALU_SRC_REG;
                alu_src_2       = ALU_SRC_IMM;
                rs1_used        = 1'b1;
                mem_req         = 1'b1;
                regfile_we      = 1'b1;
                regfile_wr_mux  = WB_WR_MUX_MEM;
                imm_sel         = IMM_I;
                // load size
                case (instr[14:12])
                    3'b000: mem_type  = 3'b000; // LB
                    3'b001: mem_type  = 3'b001; // LH
                    3'b010: mem_type  = 3'b010; // LW
                    3'b100: mem_type  = 3'b100; // LBU
                    3'b101: mem_type  = 3'b101; // LHU
                    default: illegal_instr = 1;
                endcase
            end

            OPCODE_LUI: begin
                // Load Upper Immediate
                alu_en          = 1'b1;
                alu_op          = ALU_LUI;
                alu_src_2       = ALU_SRC_IMM;
                regfile_we      = 1'b1;
                regfile_wr_mux  = WB_WR_MUX_ALU;
                imm_sel         = IMM_U;
            end

            OPCODE_AUIPC: begin
                // Add Upper Immediate to PC, save to reg rd
                alu_en          = 1'b1;
                alu_op          = ALU_ADD;
                alu_src_1       = ALU_SRC_PC;
                alu_src_2       = ALU_SRC_IMM;
                regfile_we      = 1'b1;
                regfile_wr_mux  = WB_WR_MUX_ALU;
                imm_sel         = IMM_U;
            end

            OPCODE_OPIMM: begin
                // Register-Immediate ALU Operations
                alu_en          = 1'b1;
                case(instr[14:12])
                    3'b000: alu_op = ALU_ADD;  // Add Immediate
                    3'b010: alu_op = ALU_SLT;  // Set to one if Lower Than Immediate
                    3'b011: alu_op = ALU_SLTU; // Set to one if Lower Than Immediate Unsigned
                    3'b100: alu_op = ALU_XOR;  // Exclusive Or with Immediate
                    3'b110: alu_op = ALU_OR;   // Or with Immediate
                    3'b111: alu_op = ALU_AND;  // And with Immediate
                    3'b001: begin
                            alu_op = ALU_SLL;  // Shift Left Logical by Immediate
                            if (instr[31:25] != 7'b0)
                                illegal_instr = 1'b1;
                            end

                    3'b101: begin
                            if (instr[31:25] == 7'b0)
                                alu_op = ALU_SRL;  // Shift Right Logical by Immediate
                            else if (instr[31:25] == 7'b010_0000)
                                alu_op = ALU_SRA;  // Shift Right Arithmetically by Immediate
                            else
                                illegal_instr = 1'b1;
                            end
                    default:    illegal_instr = 1'b1;
                endcase
                alu_src_1       = ALU_SRC_REG;
                alu_src_2       = ALU_SRC_IMM;
                rs1_used        = 1'b1;
                regfile_we      = 1'b1;
                regfile_wr_mux  = WB_WR_MUX_ALU;
                imm_sel         = IMM_I;
            end

            OPCODE_OP: begin
                // Register-Register ALU operation
                alu_en          = 1'b1;
                case ({instr[30:25], instr[14:12]})
                    // RV32I ALU operations
                    {6'b00_0000, 3'b000}: alu_op = ALU_ADD;   // Add
                    {6'b10_0000, 3'b000}: alu_op = ALU_SUB;   // Sub
                    {6'b00_0000, 3'b010}: alu_op = ALU_SLT;  // Set Lower Than
                    {6'b00_0000, 3'b011}: alu_op = ALU_SLTU;  // Set Lower Than Unsigned
                    {6'b00_0000, 3'b100}: alu_op = ALU_XOR;   // Xor
                    {6'b00_0000, 3'b110}: alu_op = ALU_OR;    // Or
                    {6'b00_0000, 3'b111}: alu_op = ALU_AND;   // And
                    {6'b00_0000, 3'b001}: alu_op = ALU_SLL;   // Shift Left Logical
                    {6'b00_0000, 3'b101}: alu_op = ALU_SRL;   // Shift Right Logical
                    {6'b10_0000, 3'b101}: alu_op = ALU_SRA;   // Shift Right Arithmetic
                    default: illegal_instr = 1'b1;
                endcase
                alu_src_1       = ALU_SRC_REG;
                alu_src_2       = ALU_SRC_REG;
                rs1_used        = 1'b1;
                rs2_used        = 1'b1;
                regfile_we      = 1'b1;
                regfile_wr_mux  = WB_WR_MUX_ALU;
            end

            OPCODE_SYSTEM: begin
                // CSR operations
                csr_type = instr[14:12];
                csr_we   = 1'b1;
                case (instr[14:12])
                    CSR_RC: begin
                        alu_en          = 1'b1;
                        alu_op          = ALU_AND;
                        alu_src_1       = ALU_SRC_REG;
                        alu_src_2       = ALU_SRC_CSR;
                        rs1_used        = 1'b1;
                    end

                    CSR_RCI: begin
                        alu_en          = 1'b1;
                        alu_op          = ALU_AND;
                        alu_src_1       = ALU_SRC_IMM;
                        alu_src_2       = ALU_SRC_CSR;
                        imm_sel         = IMM_Z;
                    end

                    CSR_RS: begin
                        alu_en          = 1'b1;
                        alu_op          = ALU_OR;
                        alu_src_1       = ALU_SRC_REG;
                        alu_src_2       = ALU_SRC_CSR;
                        rs1_used        = 1'b1;
                    end

                    CSR_RSI: begin
                        alu_en          = 1'b1;
                        alu_op          = ALU_OR;
                        alu_src_1       = ALU_SRC_IMM;
                        alu_src_2       = ALU_SRC_CSR;
                        imm_sel         = IMM_Z;
                    end

                    CSR_RW: begin
                        rs1_used        = 1'b1;
                    end

                    CSR_RWI: begin
                        imm_sel         = IMM_Z;
                    end
                    default: ;
                endcase
                regfile_we      = 1'b1;
                regfile_wr_mux  = WB_WR_MUX_ALU;
            end

            default: illegal_instr = 1'b1;
        endcase
    end

//////////////////////////////////////////////////////////
// handle jumps                                         //
//////////////////////////////////////////////////////////
    assign jump_decision_o      = jump_decision;
    assign jump_target_o        = pc_id + imm_uj_type;

//////////////////////////////////////////////////////////
// outut to ex                                          //
//////////////////////////////////////////////////////////
    assign pc_id_o              = pc_id;
    assign alu_en_ex_o          = alu_en;
    assign alu_op_ex_o          = alu_op;
    assign alu_src_1_ex_o       = alu_src_1;
    assign alu_src_2_ex_o       = alu_src_2;
    assign rs1_raddr_ex_o       = rs1_raddr;
    assign rs2_raddr_ex_o       = rs2_raddr;
    assign rs1_rdata_ex_o       = ((regfile_we_wb_i) && (regfile_waddr_wb_i == rs1_raddr) && (rs1_used) && (rs1_raddr != '0)) ? regfile_wdata_wb_i : rs1_rdata;
    assign rs2_rdata_ex_o       = ((regfile_we_wb_i) && (regfile_waddr_wb_i == rs2_raddr) && (rs2_used) && (rs2_raddr != '0)) ? regfile_wdata_wb_i : rs2_rdata;
    assign rs1_used_ex_o        = rs1_used;
    assign rs2_used_ex_o        = rs2_used;
    always_comb begin : IMM_SELECT
        imm_ex_o    =   '0;
        case(imm_sel)
            IMM_I:  imm_ex_o = imm_i_type;
            IMM_IZ: imm_ex_o = imm_iz_type;
            IMM_Z:  imm_ex_o = imm_z_type;
            IMM_S:  imm_ex_o = imm_s_type;
            IMM_SB: imm_ex_o = imm_sb_type;
            IMM_U:  imm_ex_o = imm_u_type;
            IMM_UJ: imm_ex_o = imm_uj_type;
            IMM_FOUR:imm_ex_o= 32'd4;
            default:;
        endcase
    end
    assign regfile_waddr_ex_o   = regfile_waddr;
    assign regfile_we_ex_o      = regfile_we;
    assign regfile_wr_mux_ex_o  = regfile_wr_mux;
    assign mem_req_ex_o         = mem_req;
    assign mem_we_ex_o          = mem_we;
    assign mem_type_ex_o          = mem_type;
    assign branch_type_ex_o     = branch_type;
    assign csr_addr_ex_o        = csr_addr;
    assign csr_type_ex_o        = csr_type;
    assign csr_we_ex_o          = csr_we;

endmodule