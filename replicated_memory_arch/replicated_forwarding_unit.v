module replicated_forwarding_unit
#(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 10
)
(
    input wire [ADDR_WIDTH-1:0] read_addr,
    input wire [ADDR_WIDTH-1:0] write_addr,
    input wire [DATA_WIDTH-1:0] write_data,

    input wire write_enable,

    input wire [DATA_WIDTH-1:0] mem_data,

    output reg [DATA_WIDTH-1:0] read_data
);

always @(*) begin
    if(write_enable && (read_addr == write_addr))
        read_data = write_data;
    else
        read_data = mem_data;
end

endmodule