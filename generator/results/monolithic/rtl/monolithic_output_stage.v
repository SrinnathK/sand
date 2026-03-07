module monolithic_output_stage
#(
parameter DATA_WIDTH = 8
)
(
    input clk,
    input valid_in,
    input [DATA_WIDTH-1:0] data_in,

    output reg valid_out,
    output reg [DATA_WIDTH-1:0] data_out
);

always @(posedge clk) begin
    valid_out <= valid_in;
    data_out <= data_in;
end

endmodule