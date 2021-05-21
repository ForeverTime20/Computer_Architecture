////////////////////////////////////////////////////////////////////////////////
// Engineer:       Jiang Binze - jiangbinze@mail.ustc.edu.cn                  //
//                                                                            //
// Design Name:    controller module                                          //
// Project Name:   RISCV Core                                                 //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    control pipeline stall/clear/harzards                      //
//                                                                            //
// Mother Module Name:                                                        //
//                 core                                                       //
////////////////////////////////////////////////////////////////////////////////

module controller import core_pkg::*;
#(
    parameter DEBUG         = 0
)
(
    input   logic           clk,
    input   logic           rst_n,

    // branches and jumps
    input   logic           jump_decision_i,
    input   logic           branch_decision_i,
    output  logic           pc_set_o,
    output  logic   [3 :0]  pc_mux_o,

    // pipeline stall, clear signals
    output  logic           stall_if_o,
    output  logic           stall_id_o,
    output  logic           stall_ex_o,
    output  logic           stall_mem_o,
    output  logic           stall_wb_o,
    output  logic           clear_if_o,
    output  logic           clear_id_o,
    output  logic           clear_ex_o,
    output  logic           clear_mem_o,
    output  logic           clear_wb_o,

    // ex, mem, wb info
    input   logic   [4 :0]  rs1_raddr_ex_i,
    input   logic   [4 :0]  rs2_raddr_ex_i,
    input   logic           rs1_used_ex_i,
    input   logic           rs2_used_ex_i,
    input   logic           mem_req_i,
    input   logic   [4 :0]  regfile_waddr_mem_i,
    input   logic           regfile_we_mem_i,
    input   logic   [4 :0]  regfile_waddr_wb_i,
    input   logic           regfile_we_wb_i,

    // forward signals
    output  logic   [1 :0]  rs1_forward_o,
    output  logic   [1 :0]  rs2_forward_o,

    input   logic           mem_miss_i
);

    // forward 1
    always_comb begin : RS1_FORWARD
        // 2'b01: forward mem
        // 2'b10: forward wb
        rs1_forward_o = 2'b00;
        if(regfile_we_wb_i && rs1_used_ex_i && (regfile_waddr_wb_i == rs1_raddr_ex_i) && (regfile_waddr_wb_i != '0))
            rs1_forward_o = 2'b10;
        if(regfile_we_mem_i && rs1_used_ex_i && (regfile_waddr_mem_i == rs1_raddr_ex_i) && (regfile_waddr_mem_i != '0))
            rs1_forward_o = 2'b01;
    end

    // forward 2
    always_comb begin : RS2_FORWARD
        // 2'b01: forward mem
        // 2'b10: forward wb
        rs2_forward_o = 2'b00;
        if(regfile_we_wb_i && rs2_used_ex_i && (regfile_waddr_wb_i == rs2_raddr_ex_i) && (regfile_waddr_wb_i != '0))
            rs2_forward_o = 2'b10;
        if(regfile_we_mem_i && rs2_used_ex_i && (regfile_waddr_mem_i == rs2_raddr_ex_i) && (regfile_waddr_mem_i != '0))
            rs2_forward_o = 2'b01;
    end

    // branches and jumps
    always_comb begin : PC_SET_MUX
        // priority increases
        pc_set_o    = 1'b0;
        pc_mux_o    = PC_BOOT;
        if(jump_decision_i) begin
            pc_set_o    = 1'b1;
            pc_mux_o    = PC_JUMP;
        end
        if(branch_decision_i) begin
            pc_set_o    = 1'b1;
            pc_mux_o    = PC_BRANCH;
        end
    end

    always_comb begin : STALL_CLEAR
        stall_if_o  = 1'b0;
        stall_id_o  = 1'b0;
        stall_ex_o  = 1'b0;
        stall_mem_o = 1'b0;
        stall_wb_o  = 1'b0;
        clear_if_o  = 1'b0;
        clear_id_o  = 1'b0;
        clear_ex_o  = 1'b0;
        clear_mem_o = 1'b0;
        clear_wb_o  = 1'b0;
        if(jump_decision_i) begin
            clear_id_o  = 1'b1;
        end

        if(branch_decision_i) begin
            clear_id_o  = 1'b1;
            clear_ex_o  = 1'b1;
        end

        if(mem_req_i && regfile_we_mem_i && 
           (rs1_used_ex_i || rs2_used_ex_i) &&
           (regfile_waddr_mem_i == rs1_raddr_ex_i || regfile_waddr_mem_i == rs2_raddr_ex_i))
        begin
            clear_if_o  = 1'b0;
            clear_id_o  = 1'b0;
            clear_ex_o  = 1'b0;
            stall_if_o  = 1'b1;
            stall_id_o  = 1'b1;
            stall_ex_o  = 1'b1;
            clear_mem_o = 1'b1;
        end

        if(mem_miss_i) begin
            clear_if_o  = 1'b0;
            clear_id_o  = 1'b0;
            clear_ex_o  = 1'b0;
            clear_mem_o = 1'b0;
            clear_wb_o  = 1'b0;
            stall_if_o  = 1'b1;
            stall_id_o  = 1'b1;
            stall_ex_o  = 1'b1;
            stall_mem_o = 1'b1;
            stall_wb_o  = 1'b1;
        end
    end

endmodule