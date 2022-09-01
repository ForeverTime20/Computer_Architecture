`timescale 1ns / 1ps

`define TRACE_REF_FILE "./cpu_trace.txt"

module trace_gen_tb(

);

    reg clk;
    reg resetn;

    initial begin
        clk = 1'b0;
        resetn = 1'b0;
        #1000;
        resetn = 1'b1;
    end
    always #5 clk=~clk;

    initial begin

    end

    RV32Core cpu_core
    (
        .clk                ( clk                   ),
        .rst                ( ~resetn               )
    );

// trace part
    wire            reg_write_enable;
    wire    [5 :0]  reg_write_addr;
    wire    [31:0]  reg_write_data;
    wire    [31:0]  pc_wb;

    assign  reg_write_enable    =   cpu_core.regfile_we;
    assign  reg_write_addr      =   cpu_core.regfile_waddr;
    assign  reg_write_data      =   cpu_core.regfile_wdata;
    assign  pc_wb               =   cpu_core.wb_stage_i.pc_wb;

    // open the trace file;
    integer trace_ref;
    initial begin
        trace_ref = $fopen(`TRACE_REF_FILE, "w");
    end

    // generate trace
    always @(posedge clk) begin
        if(reg_write_enable && reg_write_addr!=5'd0) begin
            $fdisplay(trace_ref, "%h %h %h %h", '1,
                      pc_wb, reg_write_addr, reg_write_data);
        end
    end

    //monitor test
    initial begin
        $timeformat(-9,0," ns",10);
        while(!resetn) #5;
        $display("==============================================================");
        $display("Test begin!");

        #10000;
        while('1) begin
            #10000;
            $display ("        [%t] Test is running, pc_wb = 0x%8h",$time, pc_wb);
        end
    end


endmodule