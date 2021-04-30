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
    parameter DEBUG         = 0
)
(
    input   logic           clk,
    input   logic           rst_n,

    input   logic           stall_if_i,
    input   logic           clear_if_i,

    input   logic           pc_set_i,
    input   logic   [3 :0]  pc_mux_i,
    input   logic   [31:0]  boot_addr_i,
    input   logic   [31:0]  jump_target_id_i,
    input   logic   [31:0]  branch_target_ex_i,

    output  logic   [31:0]  pc_if_o
);

    logic   [31:0]  pc_q;
    logic   [31:0]  pc_n;



    always_ff @(posedge clk, negedge rst_n) begin : PC_REG
        if(rst_n == 1'b0)
            pc_q    <= 32'h0;
        else
            pc_q    <= pc_n;
    end

    always_comb begin : NEXT_PC
        pc_n    = pc_q + 32'h4;
        if(stall_if_i)
            pc_n = pc_q;
        
        if(clear_if_i)
            pc_n = 32'h0;

        if(pc_set_i) begin
            case(pc_mux_i)
            PC_BOOT:    pc_n = boot_addr_i;
            PC_BRANCH:  pc_n = branch_target_ex_i;
            PC_JUMP:    pc_n = jump_target_id_i;
            default:;
            endcase
        end
    end

    assign  pc_if_o = pc_q;

endmodule