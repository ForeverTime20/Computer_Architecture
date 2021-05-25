////////////////////////////////////////////////////////////////////////////////
// Engineer:       Jiang Binze - jiangbinze@mail.ustc.edu.cn                  //
//                                                                            //
// Design Name:    branch_history_table module                                //
// Project Name:   RISCV Core                                                 //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    record branch history in ex stage                          //
//                                                                            //
// Mother Module Name:                                                        //
//                 if_stage                                                   //
////////////////////////////////////////////////////////////////////////////////

module branch_history_table import core_pkg::*;
#(
    parameter DEBUG         = 0,
    parameter PC_ADDR_LEN   = 32,       // addr length of pc
    parameter INDEX_ADDR_LEN= 5,        // index length of pc, pc[index_length-1:0]
    // parameter LHT_BITS      = 0,        // local history table size, set to 0 to not using history table
    parameter LPT_BITS      = 2         // number of local prediction bits in table
)
(
    input   logic           clk,
    input   logic           rst_n,

    input   logic   [PC_ADDR_LEN-1:0]   pc_query_i,

    input   logic   [PC_ADDR_LEN-1:0]   pc_brancher_i,
    input   logic                       branch_fact_i,
    input   logic                       update_i,

    output  logic                       prediction_o
);

    localparam BHT_SIZE     = 1 << INDEX_ADDR_LEN;
    // localparam LHT_SIZE     = 1 << LHT_BITS;
    localparam MAX_VALUE    = (1 << LPT_BITS) - 1;
    localparam THRESHOLD    = ((1 << LPT_BITS) - 1) / 2;
    
    // history table regs of bht
    logic [LPT_BITS-1:0]  bht[BHT_SIZE-1:0];

    // read logic, output branch prediction
    generate
        assign prediction_o = (bht[pc_query_i[INDEX_ADDR_LEN-1:0]] > THRESHOLD) ? 1 : 0;
    endgenerate

    // update logic
    int j;
    generate
        always_ff @( posedge clk ) begin : BHT_UPDATE
            if(!rst_n) begin
                for( j = 0; j < BHT_SIZE; j++) begin
                    bht[j] <= '0;
                end
            end
            else begin
                // if there is a branch in ex stage, and it happened, update bht, watchout overflow
                if(update_i && branch_fact_i && !(&bht[pc_brancher_i[INDEX_ADDR_LEN-1:0]])) begin
                    bht[pc_brancher_i[INDEX_ADDR_LEN-1:0]] <= bht[pc_brancher_i[INDEX_ADDR_LEN-1:0]] + 1;
                end
                // branch in ex stage didn't happen, update bht with -1
                if(update_i && !branch_fact_i && (|bht[pc_brancher_i[INDEX_ADDR_LEN-1:0]])) begin
                    bht[pc_brancher_i[INDEX_ADDR_LEN-1:0]] <= bht[pc_brancher_i[INDEX_ADDR_LEN-1:0]] - 1;
                end
            end
        end
    endgenerate

endmodule