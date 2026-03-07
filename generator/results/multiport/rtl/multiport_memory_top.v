module multiport_memory_top #
(
parameter MEMORY_SIZE     = 1024,
parameter DATA_WIDTH      = 8,
parameter NUM_PORTS       = 4,
parameter READ_PORTS      = 2,
parameter WRITE_PORTS     = 2,

parameter PRIORITY        = 0,
parameter CLOCK_FREQUENCY = 500,
parameter ACCESS_PATTERN  = 0,

parameter MAX_BANKS       = 4,
parameter PIPELINE_DEPTH  = 1,

parameter ARBITER_TYPE    = 0,
parameter ADDR_MAP_TYPE   = 0
)
(
input clk,
input rst,

input  [NUM_PORTS-1:0] req,
input  [NUM_PORTS-1:0] we,

input  [NUM_PORTS*32-1:0] addr,
input  [NUM_PORTS*DATA_WIDTH-1:0] wdata,

output [NUM_PORTS*DATA_WIDTH-1:0] rdata,
output [NUM_PORTS-1:0] ready
);

wire [NUM_PORTS-1:0] grant;
wire [NUM_PORTS*$clog2(MAX_BANKS)-1:0] bank_sel;

wire [NUM_PORTS*DATA_WIDTH-1:0] bank_rdata;
wire [NUM_PORTS*DATA_WIDTH-1:0] pipeline_rdata;


multiport_controller #(
.MEMORY_SIZE(MEMORY_SIZE),
.DATA_WIDTH(DATA_WIDTH),
.NUM_PORTS(NUM_PORTS),
.READ_PORTS(READ_PORTS),
.WRITE_PORTS(WRITE_PORTS),
.MAX_BANKS(MAX_BANKS),
.ARBITER_TYPE(ARBITER_TYPE),
.ADDR_MAP_TYPE(ADDR_MAP_TYPE)
)

controller(
.clk(clk),
.rst(rst),
.req(req),
.we(we),
.addr(addr),
.wdata(wdata),
.grant(grant),
.bank_sel(bank_sel),
.rdata(bank_rdata)
);


/////////////////////////////////////////////////////
// Pipeline
/////////////////////////////////////////////////////

genvar i;

generate
for(i = 0; i < NUM_PORTS; i = i + 1)
begin : PIPE

pipeline_stage #(
.WIDTH(DATA_WIDTH)
)
pipe_stage(
.clk(clk),
.data_in(bank_rdata[i*DATA_WIDTH +: DATA_WIDTH]),
.data_out(pipeline_rdata[i*DATA_WIDTH +: DATA_WIDTH])
);

end
endgenerate


assign rdata = pipeline_rdata;
assign ready = grant;

endmodule