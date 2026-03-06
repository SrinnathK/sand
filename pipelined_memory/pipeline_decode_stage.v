module pipeline_decode_stage
#(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 10,
    parameter NUM_BANKS = 4
)
(
    input wire clk,
    input wire reset,

    input wire in_valid,
    input wire in_write,
    input wire [ADDR_WIDTH-1:0] in_addr,
    input wire [DATA_WIDTH-1:0] in_wdata,

    output reg out_valid,
    output reg out_write,
    output reg [ADDR_WIDTH-1:0] out_addr,
    output reg [DATA_WIDTH-1:0] out_wdata,
    output reg [$clog2(NUM_BANKS)-1:0] out_bank
);

wire [$clog2(NUM_BANKS)-1:0] bank;

address_map_interleaved
#(
    .ADDR_WIDTH(ADDR_WIDTH),
    .NUM_BANKS(NUM_BANKS)
)
mapper
(
    .addr(in_addr),
    .bank(bank)
);

always @(posedge clk or posedge reset) begin
    if(reset)
        out_valid <= 0;
    else begin
        out_valid <= in_valid;
        out_write <= in_write;
        out_addr  <= in_addr;
        out_wdata <= in_wdata;
        out_bank  <= bank;
    end
end

endmodule