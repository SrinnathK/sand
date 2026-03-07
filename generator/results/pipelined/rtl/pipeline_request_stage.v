module pipeline_request_stage
#(
    parameter DATA_WIDTH = 8,
parameter ADDR_WIDTH = 7
)
(
    input wire clk,
    input wire reset,

    input wire req_valid,
    input wire req_write,
    input wire [ADDR_WIDTH-1:0] req_addr,
    input wire [DATA_WIDTH-1:0] req_wdata,

    output reg out_valid,
    output reg out_write,
    output reg [ADDR_WIDTH-1:0] out_addr,
    output reg [DATA_WIDTH-1:0] out_wdata
);

always @(posedge clk or posedge reset) begin
    if(reset) begin
        out_valid <= 0;
    end
    else begin
        out_valid <= req_valid;
        out_write <= req_write;
        out_addr  <= req_addr;
        out_wdata <= req_wdata;
    end
end

endmodule