module monolithic_memory_top
#(
    parameter ADDR_WIDTH = 7,
parameter DATA_WIDTH = 8
)
(
    input clk,
    input valid,
    input we,
    input [ADDR_WIDTH-1:0] addr,
    input [DATA_WIDTH-1:0] write_data,

    output valid_out,
    output [DATA_WIDTH-1:0] read_data
);

wire valid_r;
wire we_r;
wire [ADDR_WIDTH-1:0] addr_r;
wire [DATA_WIDTH-1:0] data_r;

wire valid_d;
wire [ADDR_WIDTH-1:0] addr_d;

wire [DATA_WIDTH-1:0] mem_out;

/* Request stage */

monolithic_request_stage
#(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
)
req_stage
(
    .clk(clk),
    .valid_in(valid),
    .we_in(we),
    .addr_in(addr),
    .data_in(write_data),

    .valid_out(valid_r),
    .we_out(we_r),
    .addr_out(addr_r),
    .data_out(data_r)
);

/* Decode stage */

monolithic_decode_stage
#(
    .ADDR_WIDTH(ADDR_WIDTH)
)
decode_stage
(
    .clk(clk),
    .valid_in(valid_r),
    .addr_in(addr_r),

    .valid_out(valid_d),
    .addr_out(addr_d)
);

/* Memory stage */

monolithic_memory_stage
#(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
)
mem_stage
(
    .clk(clk),
    .we(we_r),
    .addr(addr_d),
    .write_data(data_r),

    .read_data(mem_out)
);

/* Output stage */

monolithic_output_stage
#(
    .DATA_WIDTH(DATA_WIDTH)
)
out_stage
(
    .clk(clk),
    .valid_in(valid_d),
    .data_in(mem_out),

    .valid_out(valid_out),
    .data_out(read_data)
);

endmodule