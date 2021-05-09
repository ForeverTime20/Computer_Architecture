`timescale 1ns / 1ps

module cpu_tb();
    reg clk = 1'b1;
    reg rst = 1'b1;
    
    reg [63:0] cache_reqs;
    reg [63:0] cache_misses;
    reg [31:0] pc_old;
    wire       cache_req;
    wire       cache_miss;
    
    always  #2 clk = ~clk;
    initial #8 rst = 1'b0;
    initial cache_reqs = 32'h0;
    initial cache_misses = 32'h0;

    assign cache_req = core_i.mem_req_wb;
    assign cache_miss = core_i.mem_miss;
    always@(posedge clk) begin
        pc_old <= core_i.pc_me;
        if(pc_old != core_i.pc_me && cache_req)
            cache_reqs <= cache_reqs + 1;
        if(pc_old != core_i.pc_me && cache_miss)
            cache_misses <= cache_misses + 1;
    end
    
    RV32Core core_i(
        .clk    ( clk          ),
        .rst    ( rst          )
    );



endmodule
