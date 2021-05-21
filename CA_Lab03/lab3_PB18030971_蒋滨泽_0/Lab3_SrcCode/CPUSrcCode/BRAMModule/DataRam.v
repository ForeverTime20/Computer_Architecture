`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: USTC ESLAB 
// Engineer: Wu Yuzhang
// 
// Design Name: RISCV-Pipline CPU
// Module Name: DataRamWrapper
// Target Devices: Nexys4
// Tool Versions: Vivado 2017.4.1
// Description: a Verilog-based ram which can be systhesis as BRAM
// 
//////////////////////////////////////////////////////////////////////////////////
//功能说明
    //同步读写bram，a、b双口可读写，a口用于CPU访问dataRam，b口用于外接debug_module进行读写
    //写使能为4bit，支持byte write
//输入
    //clk               输入时钟
    //addra             a口读写地址
    //dina              a口写输入数据
    //wea               a口写使能
    //addrb             b口读写地址
    //dinb              b口写输入数据
    //web               b口写使能
//输出
    //douta             a口读数据
    //doutb             b口读数据
//实验要求  
    //无需修改

module DataRam(
    input  clk,
    input  [ 3:0] wea, web,
    input  [31:0] addra, addrb,
    input  [31:0] dina , dinb,
    output reg [31:0] douta, doutb
);
initial begin douta=0; doutb=0; end
parameter INSTRUCTION_STREAM_FILE = "E:\\Users\\ForeverTime Ken\\Documents\\GitHub\\Computer_Architechture\\CA_Lab02\\Simulation\\testB_InstructionStream.txt";
wire addra_valid = ( addra[31:18]==14'h0 );
wire addrb_valid = ( addrb[31:18]==14'h0 );
wire [15:0] addral = addra[17:2];
wire [15:0] addrbl = addrb[17:2];

reg [31:0] ram_cell [0:1024];

// initial $readmemh(INSTRUCTION_STREAM_FILE, ram_cell);
initial begin
    // dst matrix C
    ram_cell[       0] = 32'h0;  // 32'h8e6a5b26;
    ram_cell[       1] = 32'h0;  // 32'h91af24b1;
    ram_cell[       2] = 32'h0;  // 32'hbeb3f140;
    ram_cell[       3] = 32'h0;  // 32'h0d01e4b4;
    ram_cell[       4] = 32'h0;  // 32'hfe4d0aec;
    ram_cell[       5] = 32'h0;  // 32'hb5e9ecda;
    ram_cell[       6] = 32'h0;  // 32'h254d7eeb;
    ram_cell[       7] = 32'h0;  // 32'hf1b6dbfb;
    ram_cell[       8] = 32'h0;  // 32'h377e2456;
    ram_cell[       9] = 32'h0;  // 32'h90dbcebc;
    ram_cell[      10] = 32'h0;  // 32'h334345aa;
    ram_cell[      11] = 32'h0;  // 32'h2a123b27;
    ram_cell[      12] = 32'h0;  // 32'hbb271431;
    ram_cell[      13] = 32'h0;  // 32'hdc00df7f;
    ram_cell[      14] = 32'h0;  // 32'h4e9fb76f;
    ram_cell[      15] = 32'h0;  // 32'he7a70b93;
    ram_cell[      16] = 32'h0;  // 32'hb03c25ab;
    ram_cell[      17] = 32'h0;  // 32'h00cc7552;
    ram_cell[      18] = 32'h0;  // 32'h70d45044;
    ram_cell[      19] = 32'h0;  // 32'h0495de76;
    ram_cell[      20] = 32'h0;  // 32'h89f8e43d;
    ram_cell[      21] = 32'h0;  // 32'h6a081a71;
    ram_cell[      22] = 32'h0;  // 32'hc4a0104c;
    ram_cell[      23] = 32'h0;  // 32'h421584fc;
    ram_cell[      24] = 32'h0;  // 32'hcce6201e;
    ram_cell[      25] = 32'h0;  // 32'hb68b8039;
    ram_cell[      26] = 32'h0;  // 32'hd32a999e;
    ram_cell[      27] = 32'h0;  // 32'h2d681b51;
    ram_cell[      28] = 32'h0;  // 32'h6b4436b6;
    ram_cell[      29] = 32'h0;  // 32'h63e27ef8;
    ram_cell[      30] = 32'h0;  // 32'h74e39e90;
    ram_cell[      31] = 32'h0;  // 32'he3b9445a;
    ram_cell[      32] = 32'h0;  // 32'hc0aa8f5f;
    ram_cell[      33] = 32'h0;  // 32'h0b499269;
    ram_cell[      34] = 32'h0;  // 32'he08c3312;
    ram_cell[      35] = 32'h0;  // 32'h17b958fb;
    ram_cell[      36] = 32'h0;  // 32'h4c6fd37a;
    ram_cell[      37] = 32'h0;  // 32'h4f9fe87c;
    ram_cell[      38] = 32'h0;  // 32'h15bff55d;
    ram_cell[      39] = 32'h0;  // 32'hdf12dc7b;
    ram_cell[      40] = 32'h0;  // 32'hf40bab0d;
    ram_cell[      41] = 32'h0;  // 32'h65b8d48d;
    ram_cell[      42] = 32'h0;  // 32'hf22ffa18;
    ram_cell[      43] = 32'h0;  // 32'he574f81e;
    ram_cell[      44] = 32'h0;  // 32'hed10d713;
    ram_cell[      45] = 32'h0;  // 32'h267bd52b;
    ram_cell[      46] = 32'h0;  // 32'h7c5a4359;
    ram_cell[      47] = 32'h0;  // 32'h24bc3a4d;
    ram_cell[      48] = 32'h0;  // 32'h4957a849;
    ram_cell[      49] = 32'h0;  // 32'hf1215367;
    ram_cell[      50] = 32'h0;  // 32'hac8bab82;
    ram_cell[      51] = 32'h0;  // 32'h412b70ab;
    ram_cell[      52] = 32'h0;  // 32'hb1eb1e88;
    ram_cell[      53] = 32'h0;  // 32'h8a8fbdba;
    ram_cell[      54] = 32'h0;  // 32'h042fc14d;
    ram_cell[      55] = 32'h0;  // 32'h8acb54b2;
    ram_cell[      56] = 32'h0;  // 32'hb5feaa3d;
    ram_cell[      57] = 32'h0;  // 32'h1a12c423;
    ram_cell[      58] = 32'h0;  // 32'h3fb486d9;
    ram_cell[      59] = 32'h0;  // 32'h1ab54348;
    ram_cell[      60] = 32'h0;  // 32'h6fe4d080;
    ram_cell[      61] = 32'h0;  // 32'h045455f9;
    ram_cell[      62] = 32'h0;  // 32'hc1995fe0;
    ram_cell[      63] = 32'h0;  // 32'hdfb55c30;
    // src matrix A
    ram_cell[      64] = 32'h3c5753e0;
    ram_cell[      65] = 32'h01eefa04;
    ram_cell[      66] = 32'hd2d70f78;
    ram_cell[      67] = 32'h6cd33d8d;
    ram_cell[      68] = 32'h446181df;
    ram_cell[      69] = 32'h9dea8ddc;
    ram_cell[      70] = 32'h1e4062ef;
    ram_cell[      71] = 32'h16992ca4;
    ram_cell[      72] = 32'hc02d7e2f;
    ram_cell[      73] = 32'h3b56f17d;
    ram_cell[      74] = 32'hb529e924;
    ram_cell[      75] = 32'hf7d36e83;
    ram_cell[      76] = 32'h8ccf4092;
    ram_cell[      77] = 32'hb7cdbb25;
    ram_cell[      78] = 32'h5e7c04d3;
    ram_cell[      79] = 32'hc4ed0b81;
    ram_cell[      80] = 32'h86c6eaa2;
    ram_cell[      81] = 32'habc67bb6;
    ram_cell[      82] = 32'h876ed38b;
    ram_cell[      83] = 32'h443456d5;
    ram_cell[      84] = 32'h0e3588cf;
    ram_cell[      85] = 32'hbe6d1515;
    ram_cell[      86] = 32'h2dfe1a39;
    ram_cell[      87] = 32'h20d955b6;
    ram_cell[      88] = 32'h1e672fae;
    ram_cell[      89] = 32'hcac467be;
    ram_cell[      90] = 32'h94989b46;
    ram_cell[      91] = 32'ha806a539;
    ram_cell[      92] = 32'hdc0dae48;
    ram_cell[      93] = 32'hbc750096;
    ram_cell[      94] = 32'ha23d6a1c;
    ram_cell[      95] = 32'hbc27d7e4;
    ram_cell[      96] = 32'hbc37027a;
    ram_cell[      97] = 32'hce90d7f1;
    ram_cell[      98] = 32'h46e34f6a;
    ram_cell[      99] = 32'h4421da3d;
    ram_cell[     100] = 32'he25c52b7;
    ram_cell[     101] = 32'h232270f5;
    ram_cell[     102] = 32'h514b14df;
    ram_cell[     103] = 32'h7cd85905;
    ram_cell[     104] = 32'hf56c275f;
    ram_cell[     105] = 32'h76af9010;
    ram_cell[     106] = 32'h14f6acfb;
    ram_cell[     107] = 32'hc3e9f867;
    ram_cell[     108] = 32'h389447d1;
    ram_cell[     109] = 32'h0814174c;
    ram_cell[     110] = 32'h01abe038;
    ram_cell[     111] = 32'h32e1a0dd;
    ram_cell[     112] = 32'h3bc5af35;
    ram_cell[     113] = 32'hc722f1a4;
    ram_cell[     114] = 32'h6253fe3b;
    ram_cell[     115] = 32'he090f232;
    ram_cell[     116] = 32'h4fb54d38;
    ram_cell[     117] = 32'h5ffdf4b1;
    ram_cell[     118] = 32'h06a93061;
    ram_cell[     119] = 32'hf686d559;
    ram_cell[     120] = 32'h9b18ff01;
    ram_cell[     121] = 32'h3fa0b833;
    ram_cell[     122] = 32'h9149ee5e;
    ram_cell[     123] = 32'h76f4e049;
    ram_cell[     124] = 32'h04ae7c67;
    ram_cell[     125] = 32'h996bb672;
    ram_cell[     126] = 32'h07e75bb7;
    ram_cell[     127] = 32'ha7529f2c;
    // src matrix B
    ram_cell[     128] = 32'h43175e9d;
    ram_cell[     129] = 32'h15a41daa;
    ram_cell[     130] = 32'h93f7ed93;
    ram_cell[     131] = 32'hac105ab0;
    ram_cell[     132] = 32'h90c80441;
    ram_cell[     133] = 32'hc74bffa2;
    ram_cell[     134] = 32'h6fd81c61;
    ram_cell[     135] = 32'he2ffc893;
    ram_cell[     136] = 32'ha900d302;
    ram_cell[     137] = 32'h791b6f5e;
    ram_cell[     138] = 32'h4c7ff270;
    ram_cell[     139] = 32'h7f6428fe;
    ram_cell[     140] = 32'h672bde07;
    ram_cell[     141] = 32'hf47a5485;
    ram_cell[     142] = 32'h1c7adfa8;
    ram_cell[     143] = 32'h3c6ba8a6;
    ram_cell[     144] = 32'hd3a7ebb5;
    ram_cell[     145] = 32'hd71028b0;
    ram_cell[     146] = 32'h217402e8;
    ram_cell[     147] = 32'h759080ff;
    ram_cell[     148] = 32'hf1936b40;
    ram_cell[     149] = 32'hd392a092;
    ram_cell[     150] = 32'hc72fa218;
    ram_cell[     151] = 32'h07c793df;
    ram_cell[     152] = 32'h6439928a;
    ram_cell[     153] = 32'ha0b897d5;
    ram_cell[     154] = 32'h0580aa9c;
    ram_cell[     155] = 32'hba48c0cb;
    ram_cell[     156] = 32'h8a83f6f2;
    ram_cell[     157] = 32'h81e298a6;
    ram_cell[     158] = 32'hf2a66986;
    ram_cell[     159] = 32'hf22ee0ee;
    ram_cell[     160] = 32'h7a96f46a;
    ram_cell[     161] = 32'hfc74ab95;
    ram_cell[     162] = 32'h8cd2b7f5;
    ram_cell[     163] = 32'h75eff400;
    ram_cell[     164] = 32'hb3a6db06;
    ram_cell[     165] = 32'h70827901;
    ram_cell[     166] = 32'hda50ca67;
    ram_cell[     167] = 32'h5557a67d;
    ram_cell[     168] = 32'h4e21fff8;
    ram_cell[     169] = 32'h371d5291;
    ram_cell[     170] = 32'hb29cfbc4;
    ram_cell[     171] = 32'h63d2b829;
    ram_cell[     172] = 32'h632a2735;
    ram_cell[     173] = 32'hdf7464d5;
    ram_cell[     174] = 32'ha30cc421;
    ram_cell[     175] = 32'h6b6a7a4c;
    ram_cell[     176] = 32'he7118d28;
    ram_cell[     177] = 32'h1b3c85af;
    ram_cell[     178] = 32'h61f76aaf;
    ram_cell[     179] = 32'hbb125d67;
    ram_cell[     180] = 32'h6027f6aa;
    ram_cell[     181] = 32'h8135a2d9;
    ram_cell[     182] = 32'hb36fc828;
    ram_cell[     183] = 32'h10a53fd6;
    ram_cell[     184] = 32'h8dbf1eaf;
    ram_cell[     185] = 32'h5698dbc7;
    ram_cell[     186] = 32'h1c7476cc;
    ram_cell[     187] = 32'h47fd23ba;
    ram_cell[     188] = 32'h33e75924;
    ram_cell[     189] = 32'h60eac816;
    ram_cell[     190] = 32'h62e2f591;
    ram_cell[     191] = 32'hf880376c;
end


always @ (posedge clk)
    douta <= addra_valid ? ram_cell[addral] : 0;
    
always @ (posedge clk)
    doutb <= addrb_valid ? ram_cell[addrbl] : 0;

always @ (posedge clk)
    if(wea[0] & addra_valid) 
        ram_cell[addral][ 7: 0] <= dina[ 7: 0];
        
always @ (posedge clk)
    if(wea[1] & addra_valid) 
        ram_cell[addral][15: 8] <= dina[15: 8];
        
always @ (posedge clk)
    if(wea[2] & addra_valid) 
        ram_cell[addral][23:16] <= dina[23:16];
        
always @ (posedge clk)
    if(wea[3] & addra_valid) 
        ram_cell[addral][31:24] <= dina[31:24];
        
always @ (posedge clk)
    if(web[0] & addrb_valid) 
        ram_cell[addrbl][ 7: 0] <= dinb[ 7: 0];
                
always @ (posedge clk)
    if(web[1] & addrb_valid) 
        ram_cell[addrbl][15: 8] <= dinb[15: 8];
                
always @ (posedge clk)
    if(web[2] & addrb_valid) 
        ram_cell[addrbl][23:16] <= dinb[23:16];
                
always @ (posedge clk)
    if(web[3] & addrb_valid) 
        ram_cell[addrbl][31:24] <= dinb[31:24];

endmodule
