module multiport_controller #
(
parameter MEMORY_SIZE   = 1024,
parameter DATA_WIDTH    = 8,
parameter NUM_PORTS     = 6,
parameter READ_PORTS    = 4,
parameter WRITE_PORTS   = 2,
parameter MAX_BANKS     = 4,
parameter ARBITER_TYPE  = 0,
parameter ADDR_MAP_TYPE = 0
)

(
input clk,
input rst,

input  [NUM_PORTS-1:0] req,
input  [NUM_PORTS-1:0] we,

input  [NUM_PORTS-1:0][31:0] addr,
input  [NUM_PORTS-1:0][DATA_WIDTH-1:0] wdata,

output [NUM_PORTS-1:0] grant,
output [NUM_PORTS-1:0][$clog2(MAX_BANKS)-1:0] bank_sel,

output [NUM_PORTS-1:0][DATA_WIDTH-1:0] rdata

);

wire [NUM_PORTS-1:0][DATA_WIDTH-1:0] bank_rdata;
wire [NUM_PORTS-1:0][$clog2(MAX_BANKS)-1:0] mapped_bank;

generate

if(ADDR_MAP_TYPE==0)
begin

address_map_block #(
.NUM_PORTS(NUM_PORTS),
.NUM_BANKS(MAX_BANKS)
)

mapper(
.addr(addr),
.bank(mapped_bank)
);

end
else if(ADDR_MAP_TYPE==1)
begin

address_map_interleaved #(
.NUM_PORTS(NUM_PORTS),
.NUM_BANKS(MAX_BANKS)
)

mapper(
.addr(addr),
.bank(mapped_bank)
);

end
else
begin

address_map_xor #(
.NUM_PORTS(NUM_PORTS),
.NUM_BANKS(MAX_BANKS)
)

mapper(
.addr(addr),
.bank(mapped_bank)
);

end
endgenerate

assign bank_sel = mapped_bank;

generate
if(ARBITER_TYPE==0)
begin

arbiter_round_robin #(
.NUM_PORTS(NUM_PORTS)
)

arb(
.clk(clk),
.rst(rst),
.req(req),
.grant(grant)
);

end
else if(ARBITER_TYPE==1)
begin

arbiter_priority #(
.NUM_PORTS(NUM_PORTS)
)

arb(
.req(req),
.grant(grant)
);

end
else
begin

arbiter_age_based #(
.NUM_PORTS(NUM_PORTS)
)

arb(
.clk(clk),
.rst(rst),
.req(req),
.grant(grant)
);

end
endgenerate

wire [NUM_PORTS-1:0][DATA_WIDTH-1:0] write_data_broadcast;

write_broadcast #(
.NUM_PORTS(NUM_PORTS),
.DATA_WIDTH(DATA_WIDTH)
)

broadcast(
.we(we),
.wdata(wdata),
.out(write_data_broadcast)
);

genvar i;

generate
for(i=0;i<MAX_BANKS;i=i+1)

begin : BANKS

memory_bank #(
.DATA_WIDTH(DATA_WIDTH),
.MEMORY_SIZE(MEMORY_SIZE/MAX_BANKS)
)

bank
(
.clk(clk),
.addr(addr),
.bank_sel(mapped_bank),
.we(we),
.wdata(write_data_broadcast),
.rdata(bank_rdata)
);

end
endgenerate

read_mux #(
.NUM_PORTS(NUM_PORTS),
.DATA_WIDTH(DATA_WIDTH)
)

mux(
.bank_rdata(bank_rdata),
.sel(mapped_bank),
.rdata(rdata)
);

endmodule