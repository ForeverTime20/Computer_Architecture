////////////////////////////////////////////////////////////////////////////////
// Engineer:       Jiang Binze - jiangbinze@mail.ustc.edu.cn                  //
//                                                                            //
// Design Name:    if_stage module                                            //
// Project Name:   RISCV Core                                                 //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    Instruction Fetch module of the RISC-V core.               //
//                 Due to slight changes in Instruction Fetch,                //
//                 this module now will only provide PC, instruction          // 
//                 fetch will be done in id stage.                            //
//                                                                            //
// Mother Module Name:                                                        //
//                 core                                                       //
////////////////////////////////////////////////////////////////////////////////

module if_stage import core_pkg::*;
#(
    parameter DEBUG         = 0,
    parameter USE_BTB       = 0,
    parameter USE_BHT       = 0
)
(
    input   logic           clk,
    input   logic           rst_n,

    input   logic           stall_if_i,
    input   logic           clear_if_i,

    input   logic           pc_set_i,
    input   logic   [3 :0]  pc_mux_i,
    input   logic   [31:0]  pc_ex_i,
    input   logic   [31:0]  boot_addr_i,
    input   logic   [31:0]  jump_target_id_i,
    input   logic   [31:0]  branch_target_ex_i,

    // IF-ID Pipeline
    output  logic   [31:0]  pc_if_o,
    output  logic           branch_prediction_if_o,

    // branch prediction wires
    input   logic   [31:0]  btb_pc_brancher_i,
    input   logic           btb_pc_we_i,
    input   logic   [31:0]  btb_pc_target_i,
    input   logic           btb_pc_clear_i,

    input   logic   [31:0]  bht_pc_brancher_i,
    input   logic           bht_branch_fact_i,
    input   logic           bht_we_i
);

    logic   [31:0]  pc_q;
    logic   [31:0]  pc_n;

    // btb variables
    logic   [31:0]  btb_predicted_addr;
    logic           btb_miss;
    // bht variables
    logic           bht_prediction;

    always_ff @(posedge clk, negedge rst_n) begin : PC_REG
        if(rst_n == 1'b0)
            pc_q    <= 32'h0;
        else
            pc_q    <= pc_n;
    end

generate
    if(USE_BTB && !USE_BHT) begin
        // use branch target buffer, without branch predicition table
        branch_target_buffer
        #(
            .DEBUG              ( DEBUG             ),
            .PC_ADDR_LEN        ( 32                ),
            .INDEX_ADDR_LEN     ( 8                 )
        )btb_i
        (
            .clk                ( clk               ),
            .rst_n              ( rst_n             ),

            .pc_query_i         ( pc_q              ),

            .pc_brancher_i      ( btb_pc_brancher_i ),
            .pc_we_i            ( btb_pc_we_i       ),
            .pc_target_i        ( btb_pc_target_i   ),
            .pc_clear_i         ( btb_pc_clear_i    ),

            .miss_o             ( btb_miss          ),
            .predicted_addr_o   ( btb_predicted_addr) 
        );
        // generate next pc, btb considered
        always_comb begin : NEXT_PC
            pc_n    = pc_q + 32'h4;
            if(!btb_miss) begin
                pc_n = btb_predicted_addr;
            end
            if(pc_set_i) begin
                case(pc_mux_i)
                PC_BOOT:    pc_n = boot_addr_i;
                PC_BRANCH:  pc_n = branch_target_ex_i;
                PC_JUMP:    pc_n = jump_target_id_i;
                PC_EX_INCR: pc_n = pc_ex_i + 4;
                default:;
                endcase
            end
            if(stall_if_i)
                pc_n = pc_q;
            
            if(clear_if_i)
                pc_n = 32'h0;
        end
        // branch predicition signal
        assign branch_prediction_if_o = !btb_miss;
    end
    else if(USE_BTB && USE_BHT) begin
        // use branch target buffer, and with branch prediction table
        branch_target_buffer
        #(
            .DEBUG              ( DEBUG             ),
            .PC_ADDR_LEN        ( 32                ),
            .INDEX_ADDR_LEN     ( 8                 )
        )btb_i
        (
            .clk                ( clk               ),
            .rst_n              ( rst_n             ),

            .pc_query_i         ( pc_q              ),

            .pc_brancher_i      ( btb_pc_brancher_i ),
            .pc_we_i            ( btb_pc_we_i       ),
            .pc_target_i        ( btb_pc_target_i   ),
            .pc_clear_i         ( btb_pc_clear_i    ),

            .miss_o             ( btb_miss          ),
            .predicted_addr_o   ( btb_predicted_addr) 
        );

        branch_history_table
        #(
            .DEBUG              ( DEBUG             ),
            .PC_ADDR_LEN        ( 32                ),
            .INDEX_ADDR_LEN     ( 8                 ),
            .LPT_BITS           ( 2                 )
        )bht_i
        (
            .clk                ( clk               ),
            .rst_n              ( rst_n             ),

            .pc_query_i         ( pc_q              ),
            
            .pc_brancher_i      ( bht_pc_brancher_i ),
            .branch_fact_i      ( bht_branch_fact_i ),
            .update_i           ( bht_we_i          ),

            .prediction_o       ( bht_prediction    )
        );

        // generate next pc, btb considered
        always_comb begin : NEXT_PC
            pc_n    = pc_q + 32'h4;
            if( bht_prediction && !btb_miss) begin
                pc_n = btb_predicted_addr;
            end
            if(pc_set_i) begin
                case(pc_mux_i)
                PC_BOOT:    pc_n = boot_addr_i;
                PC_BRANCH:  pc_n = branch_target_ex_i;
                PC_JUMP:    pc_n = jump_target_id_i;
                PC_EX_INCR: pc_n = pc_ex_i + 4;
                default:;
                endcase
            end
            if(stall_if_i)
                pc_n = pc_q;
            
            if(clear_if_i)
                pc_n = 32'h0;
        end

        // branch predicition signal
        assign branch_prediction_if_o = bht_prediction && !btb_miss;
    end
    else begin
        // do not use any branch prediction
        always_comb begin : NEXT_PC
            pc_n    = pc_q + 32'h4;
            if(pc_set_i) begin
                case(pc_mux_i)
                PC_BOOT:    pc_n = boot_addr_i;
                PC_BRANCH:  pc_n = branch_target_ex_i;
                PC_JUMP:    pc_n = jump_target_id_i;
                PC_EX_INCR: pc_n = pc_ex_i + 4;
                default:;
                endcase
            end
            if(stall_if_i)
                pc_n = pc_q;
            
            if(clear_if_i)
                pc_n = 32'h0;

        end
    end
endgenerate

    assign  pc_if_o = pc_q;

endmodule