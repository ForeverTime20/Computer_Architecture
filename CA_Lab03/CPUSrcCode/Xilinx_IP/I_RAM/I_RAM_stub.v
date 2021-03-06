// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2019.2 (win64) Build 2708876 Wed Nov  6 21:40:23 MST 2019
// Date        : Sun May  9 11:27:13 2021
// Host        : DESKTOP-JF8LJ9R running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub {E:/Users/ForeverTime
//               Ken/Documents/GitHub/Computer_Architechture/CA_Lab03/CPUSrcCode/Xilinx_IP/I_RAM/I_RAM_stub.v}
// Design      : I_RAM
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a100tcsg324-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "blk_mem_gen_v8_4_4,Vivado 2019.2" *)
module I_RAM(clka, addra, douta)
/* synthesis syn_black_box black_box_pad_pin="clka,addra[15:0],douta[31:0]" */;
  input clka;
  input [15:0]addra;
  output [31:0]douta;
endmodule
