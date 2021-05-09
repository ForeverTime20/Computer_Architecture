`timescale 1ns / 1ps

module cpu_tb();
    reg clk = 1'b1;
    reg rst = 1'b1;
    
    always  #2 clk = ~clk;
    initial #8 rst = 1'b0;
    
    RV32Core RV32ICore_tb_inst(
        .clk    ( clk          ),
        .rst    ( rst          )
    );
    
endmodule
