module monolithic_decode_stage
#(
    parameter ADDR_WIDTH = 7
)
(
    input clk,
    input valid_in,
    input [ADDR_WIDTH-1:0] addr_in,

    output reg valid_out,
    output reg [ADDR_WIDTH-1:0] addr_out
);

always @(posedge clk) begin
    valid_out <= valid_in;
    addr_out <= addr_in;
end

endmodule