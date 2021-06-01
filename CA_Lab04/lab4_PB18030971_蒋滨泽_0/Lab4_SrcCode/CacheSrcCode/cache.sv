// `define FIFO
`define DEBUG
module cache #(
    parameter  LINE_ADDR_LEN = 3, // line内地�???长度，决定了每个line具有2^3个word
    parameter  SET_ADDR_LEN  = 3, // 组地�???长度，决定了�???共有2^3=8�???
    parameter  TAG_ADDR_LEN  = 6, // tag长度
    parameter  WAY_CNT       = 4  // 组相连度，决定了每组中有多少路line，这里是直接映射型cache，因此该参数没用�???
)(
    input   logic           clk, 
    input   logic           rst,
    output  logic           miss,       // 对CPU发出的miss信号
    input   logic   [31:0]  addr,       // 读写请求地址
    input   logic           rd_req,     // 读请求信�???
    output  logic   [31:0]  rd_data,    // 读出的数据，�???次读�???个word
    input   logic           wr_req,     // 写请求信�???
    input   logic   [31:0]  wr_data     // 要写入的数据，一次写�???个word
);

    localparam                      MEM_ADDR_LEN    = TAG_ADDR_LEN + SET_ADDR_LEN ;                                  // 计算主存地址长度 MEM_ADDR_LEN，主存大�???=2^MEM_ADDR_LEN个line
    localparam                      UNUSED_ADDR_LEN = 32 - TAG_ADDR_LEN - SET_ADDR_LEN - LINE_ADDR_LEN - 2 ;         // 计算未使用的地址的长�???

    localparam                      LINE_SIZE       = 1 << LINE_ADDR_LEN  ;                                          // 计算 line �??? word 的数量，�??? 2^LINE_ADDR_LEN 个word �??? line
    localparam                      SET_SIZE        = 1 << SET_ADDR_LEN   ;                                          // 计算�???共有多少组，�??? 2^SET_ADDR_LEN 个组

    reg     [            31:0]      cache_mem    [SET_SIZE][WAY_CNT][LINE_SIZE];    // SET_SIZE个line，每个line有LINE_SIZE个word
    reg     [TAG_ADDR_LEN-1:0]      cache_tags   [SET_SIZE][WAY_CNT];               // SET_SIZE个TAG
    reg                             valid        [SET_SIZE][WAY_CNT];               // SET_SIZE个valid(有效�???)
    reg                             dirty        [SET_SIZE][WAY_CNT];               // SET_SIZE个dirty(脏位)

    wire    [              2-1:0]   word_addr;
    wire    [  LINE_ADDR_LEN-1:0]   line_addr;
    wire    [   SET_ADDR_LEN-1:0]   set_addr;
    wire    [   TAG_ADDR_LEN-1:0]   tag_addr;
    wire    [UNUSED_ADDR_LEN-1:0]   unused_addr;

    logic                           mem_rd_req;
    logic                           mem_wr_req;
    logic   [               31:0]   mem_wr_line [LINE_SIZE];
    logic   [               31:0]   mem_rd_line [LINE_SIZE];
    logic   [   MEM_ADDR_LEN-1:0]   mem_addr;

    enum    {IDLE, SWPO, SWPI, WRIT} current_state, next_state, old_state;

    logic   [       WAY_CNT-1:0]    way_hit;
    logic   [ $clog2(WAY_CNT):0]    way_hit_num;
    logic   [              31:0]    replace_num;
    logic   [              31:0]    line_age[SET_SIZE][WAY_CNT];
    logic                           we_word;
    logic                           we_line;

    // DataPath
    assign {unused_addr, tag_addr, set_addr, line_addr, word_addr} = addr;
    assign miss         = (!(|way_hit)) && (rd_req || wr_req);
    genvar i;
    generate
        for(i = 0;i < WAY_CNT; i++) begin: GEN_WAY_HIT
            assign way_hit[i]   = (tag_addr == cache_tags[set_addr][i] && valid[set_addr][i]) ? 1'b1 : 1'b0;
        end
    endgenerate
    
    integer j;
    always_comb begin: GEN_WAY_HIT_NUM
        way_hit_num = '0;
        for(j = 0;j < WAY_CNT; j++) begin
            if(way_hit[j]) begin
                way_hit_num = j;
            end
        end
    end

    // cache memory management
    integer k, l, m;
        always_ff @( posedge clk ) begin: CACHE_WR
            if(rst) begin
                for(k = 0;k < SET_SIZE; k++) begin
                    for(l = 0;l < WAY_CNT; l++) begin
                        cache_tags[k][l]    <= '0;
                        valid[k][l]         <= '0;
                        // dirty[k][l]         <= '0;
                        // for(m = 0;m < LINE_SIZE; m++) begin
                        //     cache_mem[k][l][m] <='0;
                        // end
                    end
                end
            end
            if(we_word) begin
                dirty[set_addr][way_hit_num] <=1'b1;
                cache_mem[set_addr][way_hit_num][line_addr] <= wr_data;
            end
            else if(we_line)  begin
                cache_tags[set_addr][replace_num] <= tag_addr;
                valid[set_addr][replace_num] <= 1'b1;
                dirty[set_addr][replace_num] <= 1'b0;
                for(k = 0;k < LINE_SIZE; k++) begin
                    cache_mem[set_addr][replace_num][k] <= mem_rd_line[k];
                end
            end
        end
    always_ff @( posedge clk ) begin: CACHE_RD
        if(rst) begin
            rd_data <= '0;
        end
        if(!miss) begin
            rd_data <= cache_mem[set_addr][way_hit_num][line_addr];
        end
    end

    // mem bus 
    assign mem_addr = mem_wr_req ? ({cache_tags[set_addr][replace_num], set_addr}) : ({tag_addr, set_addr});
    genvar o;
    generate
        for(o = 0;o < LINE_SIZE; o++) begin
            assign mem_wr_line[o] = cache_mem[set_addr][replace_num][o];
        end
    endgenerate

`ifdef DEBUG
    logic debug_line_age_clear;
    assign debug_line_age_clear = replace_num == 0 && old_state == WRIT && (!miss);
`endif

`ifdef FIFO
        always_ff @( posedge clk ) begin
            if(rst) begin
                integer p,q;
                for(p = 0;p < SET_SIZE; p++) begin
                    for(q = 0;q < WAY_CNT; q++) begin
                        line_age[p][q] <= '0;
                    end
                end
            end
            if(!miss) begin
                integer p,q;
                for(p = 0;p < WAY_CNT; p++) begin
                    if(p == replace_num && old_state == WRIT) begin
                        line_age[set_addr][p] <= '0;
                    end
                    else begin
                        line_age[set_addr][p] <= line_age[set_addr][p] + 1;
                    end
                end
            end
        end
`else // LRU
        // Line age
        integer p,q;
        always_ff @( posedge clk ) begin
            if(rst) begin
                for(p = 0;p < SET_SIZE; p++) begin
                    for(q = 0;q<WAY_CNT; q++) begin
                        line_age[p][q] <= '0;
                    end
                end
            end
            // if(!miss) begin
                for(p = 0;p < WAY_CNT; p++) begin
                    if((rd_req || wr_req) && (!miss) && p == way_hit_num)
                        line_age[set_addr][p] <= '0;
                    else
                        line_age[set_addr][p] <= line_age[set_addr][p] + 1;
                end
            // end
        end
`endif

    // replace num
    integer n;
    always_comb begin
        replace_num = '0;
        for (n = 0; n < WAY_CNT; n++) begin
            if(line_age[set_addr][replace_num] < line_age[set_addr][n]) begin
                replace_num = n;
            end
        end
    end

    //////////////////////////////////////////////////
    //                                              //
    //               state machine                  //
    //                                              //
    //////////////////////////////////////////////////
    always_ff @( posedge clk ) begin: STATE_CHANGE
        if(rst)
            current_state   <=  IDLE;
        else
            current_state   <=  next_state;
    end
    // next state logic
    always_comb begin: NEXT_STATE
        case(current_state)
        IDLE: begin
            if(rst) begin
                next_state = IDLE;
            end
            else begin
                if(!miss) begin
                    next_state = IDLE;
                end
                else begin
                    if(valid[set_addr][replace_num] & dirty[set_addr][replace_num]) begin
                        next_state = SWPO;
                    end
                    else begin
                        next_state = SWPI;
                    end
                end
            end
        end

        SWPO: begin
            if(mem_gnt)
                next_state = SWPI;
            else
                next_state = SWPO; 
        end

        SWPI: begin
            if(mem_gnt) 
                next_state = WRIT;
            else
                next_state = SWPI;
        end

        WRIT: begin
            next_state = IDLE;
        end

        default: next_state = IDLE;
        endcase
    end
    // state machine control logics
    always_comb begin: CTRL_LOGIC
        mem_rd_req      = 1'b0;
        mem_wr_req      = 1'b0;
        we_word         = 1'b0;
        we_line         = 1'b0;
        case(current_state)
        IDLE: begin
            if(!miss && wr_req) begin
                we_word = 1'b1;
            end
        end

        SWPO: begin
            mem_wr_req = 1'b1;
        end

        SWPI: begin
            mem_rd_req = 1'b1;
        end

        WRIT: begin
            we_line = 1'b1;
        end

        default: ;
        endcase
    end 


main_mem #(     // 主存，每次读写以line 为单�???
    .LINE_ADDR_LEN  ( LINE_ADDR_LEN          ),
    .ADDR_LEN       ( MEM_ADDR_LEN           )
) main_mem_instance (
    .clk            ( clk                    ),
    .rst            ( rst                    ),
    .gnt            ( mem_gnt                ),
    .addr           ( mem_addr               ),
    .rd_req         ( mem_rd_req             ),
    .rd_line        ( mem_rd_line            ),
    .wr_req         ( mem_wr_req             ),
    .wr_line        ( mem_wr_line            )
);

// Patch 1: cache miss old 
    always_ff @(posedge clk) begin
        old_state <= current_state;
    end
    initial begin
        for(int z = 0;z < WAY_CNT;z++)
            line_age[0][z] <= 32'h0;
    end

endmodule





