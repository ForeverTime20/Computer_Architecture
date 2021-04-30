////////////////////////////////////////////////////////////////////////////////
// Engineer:       Jiang Binze - jiangbinze@mail.ustc.edu.cn                  //
//                                                                            //
// Design Name:    csr register file module                                   //
// Project Name:   RISCV Core                                                 //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    control and status register file                           //
//                                                                            //
// Mother Module Name:                                                        //
//                 ex_stage                                                   //
////////////////////////////////////////////////////////////////////////////////

module csr_registers
#(
    parameter DEBUG             = 0,
    parameter XLEN              = 32,
    parameter CSR_NUM           = 2**12,
    parameter ADDR_WIDTH        = (CSR_NUM > 1) ? $clog2(CSR_NUM) : 1
)
(
    input   logic           clk,
    input   logic           rst_n,

    input   logic   [ADDR_WIDTH-1:0]    raddr_a_i,
    output  logic   [XLEN-1:0]          rdata_a_o,

    input   logic   [ADDR_WIDTH-1:0]    raddr_b_i,
    output  logic   [XLEN-1:0]          rdata_b_o,

    input   logic   [ADDR_WIDTH-1:0]    waddr_a_i,
    input   logic   [XLEN-1:0]          wdata_a_i,
    input   logic                       we_a_i
);

    // CSR register
    logic   [CSR_NUM-1:0][XLEN-1:0]     csr;
    // write enable signal
    logic   [CSR_NUM-1:0]   we;

  //-----------------------------------------------------------------------------
  //-- READ : Read address decoder RAD
  //-----------------------------------------------------------------------------
    generate
        assign rdata_a_o = csr[raddr_a_i];
        assign rdata_b_o = csr[raddr_b_i];
    endgenerate

    // WRITE ENABLE
    genvar cidx;
    generate
        for(cidx = 0;cidx < CSR_NUM; cidx++) begin: GEN_WE
            assign we[cidx] = (waddr_a_i == cidx) ? we_a_i : 1'b0;
        end
    endgenerate

    // WRITE
    genvar i;
    generate
        for (i = 0; i < CSR_NUM; i++) begin: CSR_WRITE
            always_ff @( posedge clk, negedge rst_n ) begin
                if(~rst_n) begin
                    csr[i] <= 32'b0;
                end else begin
                    if(we[i])
                        csr[i] <= wdata_a_i;
                end
            end
        end
    endgenerate

endmodule