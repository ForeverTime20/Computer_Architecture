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

module csr_registers import core_pkg::*;
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



endmodule