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

module branch_target_buffer import core_pkg::*;
#(
    parameter DEBUG         = 0,
    parameter PC_ADDR_LEN   = 32,
    parameter INDEX_ADDR_LEN= 5
)
(
    input   logic           clk,
    input   logic           rst_n,

    input   logic   [PC_ADDR_LEN-1:0]   pc_query_i,

    input   logic   [PC_ADDR_LEN-1:0]   pc_brancher_i,
    input   logic                       pc_we_i,
    input   logic   [PC_ADDR_LEN-1:0]   pc_target_i,
    input   logic                       pc_clear_i,

    output  logic                       miss_o,
    output  logic   [PC_ADDR_LEN-1:0]   predicted_addr_o
);

    localparam  BTB_SIZE    = 1 << INDEX_ADDR_LEN;

    // buffer regs of btb
    logic [BTB_SIZE-1:0][PC_ADDR_LEN-1:0]   entry_pc;
    logic [BTB_SIZE-1:0][PC_ADDR_LEN-1:0]   predicted_addr;
    logic [BTB_SIZE-1:0]                    valid;

    // read logic, output miss and predicted addr
    generate
        assign miss_o           = (pc_query_i == entry_pc[pc_query_i[INDEX_ADDR_LEN-1:0]] && valid[pc_query_i[INDEX_ADDR_LEN-1:0]]) ? 0 : 1;
        assign predicted_addr_o = predicted_addr[pc_query_i[INDEX_ADDR_LEN-1:0]];
    endgenerate

    // update logic, write btb according to inputs 
    int i;
    generate
        always_ff @( posedge clk) begin : BTB_WRITE
            if(~rst_n) begin
                for(i = 0; i < BTB_SIZE; i++) begin
                    entry_pc[i] <= '0;
                    valid[i]    <= 1'b0;
                end
            end
            else begin
                if(pc_we_i) begin
                    entry_pc[pc_brancher_i[INDEX_ADDR_LEN-1:0]]         <= pc_brancher_i;
                    valid[pc_brancher_i[INDEX_ADDR_LEN-1:0]]            <= 1'b1;
                    predicted_addr[pc_brancher_i[INDEX_ADDR_LEN-1:0]]   <= pc_target_i;
                end
                if(pc_clear_i) begin
                    entry_pc[pc_brancher_i[INDEX_ADDR_LEN-1:0]]         <= '0;
                    valid[pc_brancher_i[INDEX_ADDR_LEN-1:0]]            <= 1'b0;
                    predicted_addr[pc_brancher_i[INDEX_ADDR_LEN-1:0]]   <= '0;
                end
            end
        end
    endgenerate

endmodule