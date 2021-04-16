`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: USTC ESLAB 
// Engineer: Wu Yuzhang
// 
// Design Name: RISCV-Pipline CPU
// Module Name: InstructionRamWrapper
// Target Devices: Nexys4
// Tool Versions: Vivado 2017.4.1
// Description: a Verilog-based ram which can be systhesis as BRAM
// 
//////////////////////////////////////////////////////////////////////////////////
//功能说明
    //同步读写bram，a口只读，用于取指，b口可读写，用于外接debug_module进行读写
    //写使能为1bit，不支持byte write
//输入
    //clk               输入时钟
    //addra             a口读地址
    //addrb             b口读写地址
    //dinb              b口写输入数据
    //web               b口写使能
//输出
    //douta             a口读数据
    //doutb             b口读数据
//实验要求  
    //无需修改

module InstructionRam(
    input  clk,
    input  web,
    input  [31:0] addra, addrb,
    input  [31:0] dinb,
    output reg [31:0] douta, doutb
);
initial begin douta=0; doutb=0; end
parameter INSTRUCTION_STREAM_FILE = "E:\\Users\\ForeverTime Ken\\Documents\\GitHub\\Computer_Architechture\\CA_Lab02\\Simulation\\3testAll.inst";
wire addra_valid = ( addra[31:18]==14'h0 );
wire addrb_valid = ( addrb[31:18]==14'h0 );
wire [15:0] addral = addra[17:2];
wire [15:0] addrbl = addrb[17:2];

reg [31:0] ram_cell [0:65535];

initial $readmemh(INSTRUCTION_STREAM_FILE, ram_cell);

always @ (posedge clk)
    douta <= addra_valid ? ram_cell[addral] : 0;
    
always @ (posedge clk)
    doutb <= addrb_valid ? ram_cell[addrbl] : 0;

always @ (posedge clk)
    if(web & addrb_valid) 
        ram_cell[addrbl] <= dinb;

endmodule

