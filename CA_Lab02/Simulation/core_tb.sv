module core_tb
(

);

    logic clk, rst;

    initial begin
        clk = 0;
        rst = 1;
        #100
        rst = 0;
    end

    always #1 clk = ~clk;

    RV32Core RV32Core_i
    (
        .CPU_CLK            ( clk           ),
        .CPU_RST            ( rst           )
    );

endmodule