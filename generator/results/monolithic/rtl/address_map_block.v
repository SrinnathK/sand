module address_map_block
#(
    parameter ADDR_WIDTH = 7,
parameter NUM_BANKS  = 1
)
(
    input  wire [ADDR_WIDTH-1:0] addr,
    output wire [$clog2(NUM_BANKS)-1:0] bank
);

localparam BANK_BITS = $clog2(NUM_BANKS);

assign bank = addr[ADDR_WIDTH-1 -: BANK_BITS];

endmodule