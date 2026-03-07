module interleaved_memory_controller
#(
    parameter DATA_WIDTH = 8,
parameter ADDR_WIDTH = 7,
parameter NUM_BANKS  = 4
)
(
    input wire clk,
    input wire reset,

    input wire req_valid,
    input wire req_write,
    input wire [ADDR_WIDTH-1:0] req_addr,
    input wire [DATA_WIDTH-1:0] req_wdata,

    output wire [$clog2(NUM_BANKS)-1:0] bank_id,
    output wire [NUM_BANKS-1:0] bank_enable,

    output reg resp_valid
);

address_map_interleaved
#(
    .ADDR_WIDTH(ADDR_WIDTH),
    .NUM_BANKS(NUM_BANKS)
)
mapper
(
    .addr(req_addr),
    .bank(bank_id)
);

bank_selector
#(
    .NUM_BANKS(NUM_BANKS)
)
selector
(
    .bank_id(bank_id),
    .enable(req_valid),
    .bank_enable(bank_enable)
);

always @(posedge clk or posedge reset)
begin
    if(reset)
        resp_valid <= 0;
    else
        resp_valid <= req_valid;
end

endmodule