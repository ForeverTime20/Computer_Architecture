////////////////////////////////////////////////////////////////////////////////
// Engineer:       Jiang Binze - jiangbinze@mail.ustc.edu.cn                  //
//                                                                            //
// Design Name:    wb_stage module                                            //
// Project Name:   RISCV Core                                                 //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    write back operations in this stage                        //
//                                                                            //
// Mother Module Name:                                                        //
//                 core                                                       //
////////////////////////////////////////////////////////////////////////////////

module wb_stage import core_pkg::*;
#(
    parameter DEBUG             = 0
)
(
    input   logic           clk,
    input   logic           rst_n,

    input   logic           stall_wb_i,
    input   logic           clear_wb_i,

    input   logic   [31:0]  pc_mem_i,
    input   logic           mem_req_i,
    input   logic           mem_we_i,
    input   logic   [3 :0]  mem_be_i,
    input   logic   [2 :0]  mem_type_i,
    input   logic   [31:0]  mem_addr_i,
    input   logic   [31:0]  mem_wdata_i,
    input   logic   [4 :0]  regfile_waddr_i,
    input   logic   [31:0]  regfile_wdata_i,
    input   logic           regfile_we_i,
    input   logic   [WB_WR_MUX_OP_WIDTH-1:0] regfile_wr_mux_i,

    output  logic   [4 :0]  regfile_waddr_o,
    output  logic   [31:0]  regfile_wdata_o,
    output  logic           regfile_we_o
);

    // MEM-WB Pipeline regs
    logic   [31:0]  pc_wb;
    logic           mem_req;
    logic           mem_we;
    logic   [3 :0]  mem_be;
    logic   [2 :0]  mem_type;
    logic   [31:0]  mem_addr;
    logic   [31:0]  mem_wdata;
    logic   [4 :0]  regfile_waddr;
    logic   [31:0]  regfile_wdata;
    logic           regfile_we;
    logic   [WB_WR_MUX_OP_WIDTH-1:0] regfile_wr_mux;

    // datapath signals
    logic           stall_ff;
    logic           clear_ff;
    logic   [31:0]  mem_rdata;
    logic   [31:0]  mem_rdata_raw;
    logic   [31:0]  mem_rdata_old;
    logic   [31:0]  mem_rdata_ext;

    // MEM-WB Pipeline
    always_ff @( posedge clk, negedge rst_n ) begin : MEM_WB_PIPELINE
        if(~rst_n | clear_wb_i) begin
            // pc not included
            mem_req         <= 1'b0;
            mem_we          <= 1'b0;
            mem_be          <= 4'b0;
            mem_type        <= 3'b0;
            mem_addr        <= 32'h0;
            mem_wdata       <= 32'h0;
            regfile_waddr   <= 5'b0;
            regfile_wdata   <= 32'h0;
            regfile_we      <= 1'b0;
            regfile_wr_mux  <= '0;
        end
        else if(~stall_wb_i) begin
            pc_wb           <= pc_mem_i;
            mem_req         <= mem_req_i;
            mem_we          <= mem_we_i;
            mem_be          <= mem_be_i;
            mem_type        <= mem_type_i;
            mem_addr        <= mem_addr_i;
            mem_wdata       <= mem_wdata_i;
            regfile_waddr   <= regfile_waddr_i;
            regfile_wdata   <= regfile_wdata_i;
            regfile_we      <= regfile_we_i;
            regfile_wr_mux  <= regfile_wr_mux_i;
        end
    end

    // DATA RAM READ/WRITE
    always_ff @( posedge clk ) begin : STALL_CLEAR_WB
        stall_ff        <= stall_wb_i;
        clear_ff        <= clear_wb_i;
        mem_rdata_old   <= mem_rdata_raw;
    end
    assign mem_rdata = stall_ff ? mem_rdata_old : (clear_ff ? 32'h0 : mem_rdata_raw);
    DataRam DataRamInst (
        .clk    ( clk            ),                      //请完善代码
        .wea    ( {4{mem_we_i}} & mem_be_i ),                      //请完善代码
        .addra  ( mem_addr_i     ),                      //请完善代码
        .dina   ( mem_wdata_i    ),                      //请完善代码
        .douta  ( mem_rdata_raw  )
        // .web    ( WE2            ),
        // .addrb  ( A2[31:2]       ),
        // .dinb   ( WD2            ),
        // .doutb  ( RD2            )
    );  

    // load data extension
    always_comb begin : MEM_DATA_EXT
        mem_rdata_ext = mem_rdata;
        case (mem_type)
            3'b000: begin   // LB
                case (mem_be)
                    4'b0001:    mem_rdata_ext = {{24{mem_rdata[7]}}, mem_rdata[7:0]};
                    4'b0010:    mem_rdata_ext = {{24{mem_rdata[15]}}, mem_rdata[15:8]};
                    4'b0100:    mem_rdata_ext = {{24{mem_rdata[23]}}, mem_rdata[23:16]};
                    4'b1000:    mem_rdata_ext = {{24{mem_rdata[31]}}, mem_rdata[31:24]}; 
                    default: ;
                endcase
            end 

            3'b001: begin   // LH
                case (mem_be)
                    4'b0011:    mem_rdata_ext = {{16{mem_rdata[15]}}, mem_rdata[15:0]};
                    4'b1100:    mem_rdata_ext = {{16{mem_rdata[31]}}, mem_rdata[31:16]}; 
                    default: ;
                endcase
            end

            3'b010: begin   // LW
                mem_rdata_ext = mem_rdata;
            end

            3'b100: begin   // LBU
                case (mem_be)
                    4'b0001:    mem_rdata_ext = {24'b0, mem_rdata[7:0]};
                    4'b0010:    mem_rdata_ext = {24'b0, mem_rdata[15:8]};
                    4'b0100:    mem_rdata_ext = {24'b0, mem_rdata[23:16]};
                    4'b1000:    mem_rdata_ext = {24'b0, mem_rdata[31:24]}; 
                    default: ;
                endcase
            end 

            3'b101: begin   // LHU
                case (mem_be)
                    4'b0011:    mem_rdata_ext = {16'b0, mem_rdata[15:0]};
                    4'b1100:    mem_rdata_ext = {16'b0, mem_rdata[31:16]}; 
                    default: ;
                endcase
            end

            default: ;
        endcase
    end

    // output, write back
    assign regfile_waddr_o  = regfile_waddr;
    always_comb begin : WRITE_BACK_MUX
        regfile_wdata_o = regfile_wdata;
        case (regfile_wr_mux)
            WB_WR_MUX_ALU:   regfile_wdata_o = regfile_wdata;
            WB_WR_MUX_MEM:   regfile_wdata_o = mem_rdata_ext;
            default: ;
        endcase
    end
    assign regfile_we_o     = regfile_we;

endmodule