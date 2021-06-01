`timescale 1ns / 1ps

module cpu_tb();
    reg clk = 1'b1;
    reg rst = 1'b1;
    
    reg [63:0] clk_counts;
    reg [63:0] cache_reqs;
    reg [63:0] cache_misses;
    reg [63:0] branch_reqs;
    reg [63:0] branch_misses;
    reg [31:0] pc_old;
    wire       cache_req;
    wire       cache_miss;
    wire       branch_req;
    wire       branch_miss;
    
    always  #2 clk = ~clk;
    initial #8 rst = 1'b0;
    initial cache_reqs = 64'h0;
    initial cache_misses = 64'h0;
    initial branch_reqs = 64'h0;
    initial branch_misses = 64'h0;
    initial clk_counts = 64'h0;

    assign cache_req = core_i.mem_req_wb;
    assign cache_miss = core_i.mem_miss;
    assign branch_req = (core_i.branch_type != 4'b1000 && core_i.branch_type != 4'b1111) ? 1 : 0;
    assign branch_miss = (core_i.branch_decision != core_i.branch_prediction) ? 1 : 0;
    always@(posedge clk) begin
        pc_old <= core_i.pc_me;
        if(!rst)
            clk_counts <= clk_counts + 1;
        if(pc_old != core_i.pc_me && cache_req)
            cache_reqs <= cache_reqs + 1;
        if(pc_old != core_i.pc_me && cache_miss)
            cache_misses <= cache_misses + 1;
        if(pc_old != core_i.pc_me && branch_req)
            branch_reqs <= branch_reqs + 1;
        if(pc_old != core_i.pc_me && branch_miss && branch_req)
            branch_misses <= branch_misses + 1;
    end
    
    RV32Core core_i(
        .clk    ( clk          ),
        .rst    ( rst          )
    );



endmodule
