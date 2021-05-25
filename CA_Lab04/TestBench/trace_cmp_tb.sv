`timescale 1ns / 1ps

`define TRACE_REF_FILE "../../../../cpu_trace.txt"

module trace_cmp_tb(

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
    reg     [31:0]  ref_reg_write_addr;
    reg     [31:0]  ref_reg_write_data;
    reg     [31:0]  ref_pc_wb;

    assign  reg_write_enable    =   cpu_core.regfile_we & (~cpu_core.wb_stage_i.stall_wb_i);
    assign  reg_write_addr      =   cpu_core.regfile_waddr;
    assign  reg_write_data      =   cpu_core.regfile_wdata;
    assign  pc_wb               =   cpu_core.wb_stage_i.pc_wb;
    // assign  pipeline_valid      =   cpu_core.ex_valid;

    // open the trace file;
    integer trace_ref;
    initial begin
        trace_ref = $fopen(`TRACE_REF_FILE, "r");
    end

    // get reference
    reg trace_cmp_flag;
    always @(posedge clk) begin 
        #1;
        if(reg_write_enable && reg_write_addr!=5'd0) begin
            trace_cmp_flag=1'b0;
            while (!trace_cmp_flag && !($feof(trace_ref))) begin
                $fscanf(trace_ref, "%h %h %h %h", trace_cmp_flag,
                        ref_pc_wb, ref_reg_write_addr, ref_reg_write_data);
            end
        end
    end

    //compare result in rsing edge 
    reg debug_wb_err;
    always @(posedge clk) begin
        #2;
        if(!resetn) begin
            debug_wb_err <= 1'b0;
        end
        else if(reg_write_enable && reg_write_addr!=5'd0) begin
            // if ( (reg_write_addr!==ref_reg_write_addr)
            //     ||(reg_write_data!==ref_reg_write_data && reg_write_addr != 32'h01) ) begin
           if (  (pc_wb!==ref_pc_wb) || (reg_write_addr!==ref_reg_write_addr)
               ||(reg_write_data!==ref_reg_write_data) ) begin

                $display("--------------------------------------------------------------");
                $display("[%t] Error!!!",$time);
                $display("    reference: pc_wb = 0x%8h, write_reg_addr = 0x%2h, write_reg_data = 0x%8h",
                         ref_pc_wb, ref_reg_write_addr, ref_reg_write_data);
                $display("    mycpu    : pc_wb = 0x%8h, write_reg_addr = 0x%2h, write_reg_data = 0x%8h",
                         pc_wb, reg_write_addr, reg_write_data);
                $display("--------------------------------------------------------------");
                debug_wb_err <= 1'b1;
                #40;
                $finish;
            end
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