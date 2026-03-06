module monolithic_request_stage
#(
    parameter ADDR_WIDTH = 7,
parameter DATA_WIDTH = 8
)
(
    input clk,
    input valid_in,
    input we_in,
    input [ADDR_WIDTH-1:0] addr_in,
    input [DATA_WIDTH-1:0] data_in,

    output reg valid_out,
    output reg we_out,
    output reg [ADDR_WIDTH-1:0] addr_out,
    output reg [DATA_WIDTH-1:0] data_out
);

always @(posedge clk) begin
    valid_out <= valid_in;
    we_out <= we_in;
    addr_out <= addr_in;
    data_out <= data_in;
end

endmodule