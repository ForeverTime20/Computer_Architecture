////////////////////////////////////////////////////////////////////////////////
// Engineer:       Jiang Binze - jiangbinze@mail.ustc.edu.cn                  //
//                                                                            //
// Design Name:    mem_stage module                                           //
// Project Name:   RISCV Core                                                 //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    memory operations in this stage                            //
//                                                                            //
// Mother Module Name:                                                        //
//                 core                                                       //
////////////////////////////////////////////////////////////////////////////////

module mem_stage import core_pkg::*;
#(
    parameter DEBUG         = 0
)
(
    input   logic           clk,
    input   logic           rst_n,

    input   logic           stall_mem_i,
    input   logic           clear_mem_i,

    input   logic   [31:0]  pc_ex_i,
    input   logic   [31:0]  alu_result_i,
    input   logic   [4 :0]  regfile_waddr_i,
    input   logic           regfile_we_i,
    input   logic   [WB_WR_MUX_OP_WIDTH-1:0] regfile_wr_mux_i,
    input   logic           mem_req_i,
    input   logic           mem_we_i,
    input   logic   [2 :0]  mem_type_i,
    input   logic   [31:0]  mem_wdata_i,

    output  logic           mem_req_o,
    output  logic   [4 :0]  regfile_waddr_o,
    output  logic           regfile_we_o,

    output  logic   [31:0]  regfile_wdata_o,

    output  logic   [31:0]  pc_mem_o,
    output  logic           mem_req_wb_o,
    output  logic           mem_we_wb_o,
    output  logic   [3 :0]  mem_be_wb_o,
    output  logic   [2 :0]  mem_type_wb_o,
    output  logic   [31:0]  mem_wdata_wb_o,
    output  logic   [4 :0]  regfile_waddr_wb_o,
    output  logic   [31:0]  regfile_wdata_wb_o,
    output  logic           regfile_we_wb_o,
    output  logic   [WB_WR_MUX_OP_WIDTH-1:0] regfile_wr_mux_wb_o
);

    // EX-MEM Pipeline regs
    logic   [31:0]  pc_mem;
    logic   [31:0]  alu_result;
    logic   [4 :0]  regfile_waddr;
    logic           regfile_we;
    logic   [WB_WR_MUX_OP_WIDTH-1:0] regfile_wr_mux;
    logic           mem_req;
    logic           mem_we;
    logic   [2 :0]  mem_type;
    logic   [31:0]  mem_wdata;

    // datapath signals
    logic   [3 :0]  mem_be;
    
    // EX-MEM Pipeline
    always_ff @( posedge clk, negedge rst_n ) begin : EX_MEM_PIPELINE
        if(~rst_n | clear_mem_i) begin
            // pc not included
            alu_result      <= 32'h0;
            regfile_waddr   <= 5'b0;
            regfile_we      <= 1'b0;
            regfile_wr_mux  <= '0;
            mem_req         <= 1'b0;
            mem_we          <= 1'b0;
            mem_type        <= 3'b0;
            mem_wdata       <= 32'h0;
        end 
        else if (~stall_mem_i) begin
            pc_mem          <= pc_ex_i;
            alu_result      <= alu_result_i;
            regfile_waddr   <= regfile_waddr_i;
            regfile_we      <= regfile_we_i;
            regfile_wr_mux  <= regfile_wr_mux_i;
            mem_req         <= mem_req_i;
            mem_we          <= mem_we_i;
            mem_type        <= mem_type_i;
            mem_wdata       <= mem_wdata_i;
        end
    end

    // to controller
    assign mem_req_o        = mem_req;
    assign regfile_waddr_o  = regfile_waddr;
    assign regfile_we_o     = regfile_we;
    assign regfile_wdata_o  = alu_result;

    // generate byte enable signals
    always_comb begin : GEN_BYTE_EN
        mem_be = 4'b0;
        if(mem_req) begin
            case (mem_type)
                3'b000, 3'b100: begin // LB/SB/LBU
                    case (alu_result[1:0])
                        2'b00:  mem_be = 4'b0001;
                        2'b01:  mem_be = 4'b0010;
                        2'b10:  mem_be = 4'b0100;
                        2'b11:  mem_be = 4'b1000; 
                        default: ;
                    endcase
                end 

                3'b001, 3'b101: begin // SH/LH/LHU
                    case (alu_result[1:0])
                        2'b00:  mem_be = 4'b0011;
                        2'b10:  mem_be = 4'b1100;
                        default: ;
                    endcase
                end

                3'b010: begin // SW/LW
                    mem_be = 4'b1111;
                end
                default: ;
            endcase
        end
    end

    // output to wb stage
    assign pc_mem_o             = pc_mem;
    assign mem_req_wb_o         = mem_req;
    assign mem_we_wb_o          = mem_we;
    assign mem_be_wb_o          = mem_be;
    assign mem_type_wb_o        = mem_type;
    always_comb begin : MEM_WDATA
        mem_wdata_wb_o = mem_wdata;
        case (mem_be)
            4'b0001:    mem_wdata_wb_o = { 24'b0, mem_wdata[7:0] };
            4'b0010:    mem_wdata_wb_o = { 16'b0, mem_wdata[7:0], 8'b0 };
            4'b0100:    mem_wdata_wb_o = { 8'b0, mem_wdata[7:0], 16'b0 };
            4'b1000:    mem_wdata_wb_o = { mem_wdata[7:0], 24'b0 };
            4'b0011:    mem_wdata_wb_o = { 16'b0, mem_wdata[15:0] };
            4'b1100:    mem_wdata_wb_o = { mem_wdata[15:0], 16'b0 }; 
            4'b1111:    mem_wdata_wb_o = mem_wdata;
            default: ;
        endcase
    end
    assign regfile_waddr_wb_o   = regfile_waddr;
    assign regfile_wdata_wb_o   = alu_result;
    assign regfile_we_wb_o      = regfile_we;
    assign regfile_wr_mux_wb_o  = regfile_wr_mux;

endmodule