module interleaved_memory_top
#(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 10,
    parameter NUM_BANKS  = 4
)
(
    input wire clk,
    input wire reset,

    input wire req_valid,
    input wire req_write,
    input wire [ADDR_WIDTH-1:0] req_addr,
    input wire [DATA_WIDTH-1:0] req_wdata,

    output wire resp_valid,
    output wire [DATA_WIDTH-1:0] resp_rdata
);

wire [$clog2(NUM_BANKS)-1:0] bank_id;
wire [NUM_BANKS-1:0] bank_enable;

interleaved_memory_controller
#(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .NUM_BANKS(NUM_BANKS)
)
controller
(
    .clk(clk),
    .reset(reset),

    .req_valid(req_valid),
    .req_write(req_write),
    .req_addr(req_addr),
    .req_wdata(req_wdata),

    .bank_id(bank_id),
    .bank_enable(bank_enable),

    .resp_valid(resp_valid)
);

interleaved_bank_array
#(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .NUM_BANKS(NUM_BANKS)
)
banks
(
    .clk(clk),

    .write_enable(req_write),
    .addr(req_addr),
    .write_data(req_wdata),

    .bank_enable(bank_enable),
    .bank_select(bank_id),

    .read_data(resp_rdata)
);

endmodule