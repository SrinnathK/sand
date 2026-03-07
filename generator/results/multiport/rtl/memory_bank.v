module memory_bank
#(
    parameter DATA_WIDTH = 8,
parameter ADDR_WIDTH = 7
)
(
    input wire clk,
    input wire we,

    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] write_data,
    output reg [DATA_WIDTH-1:0] read_data
);

localparam DEPTH = (1 << ADDR_WIDTH);

reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

always @(posedge clk) begin
    if (we)
        mem[addr] <= write_data;

    read_data <= mem[addr];
end

endmodule