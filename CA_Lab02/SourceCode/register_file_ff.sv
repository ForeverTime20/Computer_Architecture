////////////////////////////////////////////////////////////////////////////////
// Engineer:       Jiang Binze - jiangbinze@mail.ustc.edu.cn                  //
//                                                                            //
// Design Name:    register file module                                       //
// Project Name:   RISCV Core                                                 //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    register file                                              //
//                                                                            //
// Mother Module Name:                                                        //
//                 id_stage                                                   //
////////////////////////////////////////////////////////////////////////////////
module register_file
#(
    parameter ADDR_WIDTH    = 5,
    parameter DATA_WIDTH    = 32
)
(
    // Clock and Reset
    input  logic         clk,
    input  logic         rst_n,

    //Read port R1
    input  logic [ADDR_WIDTH-1:0]  raddr_a_i,
    output logic [DATA_WIDTH-1:0]  rdata_a_o,

    //Read port R2
    input  logic [ADDR_WIDTH-1:0]  raddr_b_i,
    output logic [DATA_WIDTH-1:0]  rdata_b_o,

    // Write port W1
    input logic [ADDR_WIDTH-1:0]   waddr_a_i,
    input logic [DATA_WIDTH-1:0]   wdata_a_i,
    input logic                    we_a_i

);

    // number of integer registers
    localparam    NUM_WORDS     = 2**(ADDR_WIDTH);
    // integer register file
    logic [NUM_WORDS-1:0][DATA_WIDTH-1:0]     mem;
    // write enable signal
    logic [NUM_WORDS-1:0]   we;

    // READ
    generate
        assign rdata_a_o = mem[raddr_a_i[ADDR_WIDTH-1:0]];
        assign rdata_b_o = mem[raddr_b_i[ADDR_WIDTH-1:0]];
    endgenerate

    // WRITE ENABLE
    genvar gidx;
    generate
        for(gidx = 0;gidx < NUM_WORDS; gidx++) begin: GEN_WE
            assign we[gidx] = (waddr_a_i == gidx) ? we_a_i : 1'b0;
        end
    endgenerate

    // WRITE
    genvar i, l;
    generate
        always_ff @( posedge clk or negedge rst_n ) begin : R0
            if(~rst_n) begin
                mem[0] <= 32'b0;
            end else begin
                mem[0] <= 32'b0;
            end
        end

        for (i = 1; i < NUM_WORDS; i++) begin: GEN_RF
            always_ff @( posedge clk, negedge rst_n ) begin : REG_WRITE
                if(~rst_n) begin
                    mem[i] <= 32'b0;
                end else begin
                    if(we[i])
                        mem[i] <= wdata_a_i;
                end
            end
        end
    endgenerate

endmodule