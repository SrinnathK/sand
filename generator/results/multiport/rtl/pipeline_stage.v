module pipeline_stage
#(
    parameter WIDTH = 64
)
(
    input wire clk,
    input wire reset,

    input wire [WIDTH-1:0] data_in,
    input wire valid_in,

    output reg [WIDTH-1:0] data_out,
    output reg valid_out
);

always @(posedge clk or posedge reset) begin
    if(reset) begin
        data_out <= {WIDTH{1'b0}};
        valid_out <= 1'b0;
    end
    else begin
        data_out <= data_in;
        valid_out <= valid_in;
    end
end

endmodule