module pipelined_memory_top
#(
    parameter DATA_WIDTH = 8,
parameter ADDR_WIDTH = 7,
parameter NUM_BANKS  = 2
)
(
    input wire clk,
    input wire reset,

    input wire req_valid,
    input wire req_write,
    input wire [ADDR_WIDTH-1:0] req_addr,
    input wire [DATA_WIDTH-1:0] req_wdata,

    output wire resp_valid,
    output wire [DATA_WIDTH-1:0] resp_rdata
);

wire stage1_valid;
wire stage1_write;
wire [ADDR_WIDTH-1:0] stage1_addr;
wire [DATA_WIDTH-1:0] stage1_wdata;

pipeline_request_stage
#(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
)
req_stage
(
    .clk(clk),
    .reset(reset),

    .req_valid(req_valid),
    .req_write(req_write),
    .req_addr(req_addr),
    .req_wdata(req_wdata),

    .out_valid(stage1_valid),
    .out_write(stage1_write),
    .out_addr(stage1_addr),
    .out_wdata(stage1_wdata)
);

wire stage2_valid;
wire stage2_write;
wire [ADDR_WIDTH-1:0] stage2_addr;
wire [DATA_WIDTH-1:0] stage2_wdata;
wire [$clog2(NUM_BANKS)-1:0] stage2_bank;

pipeline_decode_stage
#(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .NUM_BANKS(NUM_BANKS)
)
decode_stage
(
    .clk(clk),
    .reset(reset),

    .in_valid(stage1_valid),
    .in_write(stage1_write),
    .in_addr(stage1_addr),
    .in_wdata(stage1_wdata),

    .out_valid(stage2_valid),
    .out_write(stage2_write),
    .out_addr(stage2_addr),
    .out_wdata(stage2_wdata),
    .out_bank(stage2_bank)
);

wire stage3_valid;
wire stage3_write;
wire [ADDR_WIDTH-1:0] stage3_addr;
wire [DATA_WIDTH-1:0] stage3_wdata;
wire [$clog2(NUM_BANKS)-1:0] stage3_bank;

pipeline_arbiter_stage
#(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .NUM_BANKS(NUM_BANKS)
)
arb_stage
(
    .clk(clk),
    .reset(reset),

    .in_valid(stage2_valid),
    .in_write(stage2_write),
    .in_addr(stage2_addr),
    .in_wdata(stage2_wdata),
    .in_bank(stage2_bank),

    .out_valid(stage3_valid),
    .out_write(stage3_write),
    .out_addr(stage3_addr),
    .out_wdata(stage3_wdata),
    .out_bank(stage3_bank)
);

pipeline_memory_stage
#(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .NUM_BANKS(NUM_BANKS)
)
mem_stage
(
    .clk(clk),
    .in_valid(stage3_valid),
    .in_write(stage3_write),
    .in_addr(stage3_addr),
    .in_wdata(stage3_wdata),
    .in_bank(stage3_bank),

    .resp_valid(resp_valid),
    .resp_rdata(resp_rdata)
);

endmodule