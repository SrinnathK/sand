module replicated_memory_read_port
#(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 10
)
(
    input wire clk,

    input wire [ADDR_WIDTH-1:0] read_addr,
    output reg [DATA_WIDTH-1:0] read_data,

    input wire [DATA_WIDTH-1:0] mem_data
);

always @(posedge clk) begin
    read_data <= mem_data;
end

endmodule