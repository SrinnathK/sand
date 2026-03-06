module monolithic_memory_stage
#(
    parameter ADDR_WIDTH = 7,
parameter DATA_WIDTH = 8
)
(
    input clk,
    input we,
    input [ADDR_WIDTH-1:0] addr,
    input [DATA_WIDTH-1:0] write_data,

    output [DATA_WIDTH-1:0] read_data
);

memory_bank
#(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
)
mem (
    .clk(clk),
    .we(we),
    .addr(addr),
    .write_data(write_data),
    .read_data(read_data)
);

endmodule