module replicated_memory_top
#(
    parameter DATA_WIDTH      = 8,
parameter ADDR_WIDTH      = 7,
parameter NUM_READ_PORTS  = 3
)
(
    input wire clk,
    input wire reset,

    input wire write_enable,
    input wire [ADDR_WIDTH-1:0] write_addr,
    input wire [DATA_WIDTH-1:0] write_data,

    input wire [NUM_READ_PORTS*ADDR_WIDTH-1:0] read_addr,

    output wire [NUM_READ_PORTS*DATA_WIDTH-1:0] read_data
);

wire [NUM_READ_PORTS-1:0] we_broadcast;
wire [NUM_READ_PORTS*ADDR_WIDTH-1:0] addr_broadcast;
wire [NUM_READ_PORTS*DATA_WIDTH-1:0] data_broadcast;

write_broadcast
#(
    .NUM_REPLICAS(NUM_READ_PORTS),
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
)
broadcast_unit
(
    .write_enable(write_enable),
    .write_addr(write_addr),
    .write_data(write_data),

    .we_out(we_broadcast),
    .addr_out(addr_broadcast),
    .data_out(data_broadcast)
);

genvar i;

generate
    for(i = 0; i < NUM_READ_PORTS; i = i + 1) begin : replica_block

        wire [ADDR_WIDTH-1:0] local_read_addr;
        wire [DATA_WIDTH-1:0] mem_read_data;
        wire [DATA_WIDTH-1:0] forwarded_data;

        assign local_read_addr = read_addr[i*ADDR_WIDTH +: ADDR_WIDTH];

        memory_bank
        #(
            .DATA_WIDTH(DATA_WIDTH),
            .ADDR_WIDTH(ADDR_WIDTH)
        )
        bank_inst
        (
            .clk(clk),
            .we(we_broadcast[i]),
            .addr(addr_broadcast[i*ADDR_WIDTH +: ADDR_WIDTH]),
            .write_data(data_broadcast[i*DATA_WIDTH +: DATA_WIDTH]),
            .read_data(mem_read_data)
        );

        replicated_forwarding_unit
        #(
            .DATA_WIDTH(DATA_WIDTH),
            .ADDR_WIDTH(ADDR_WIDTH)
        )
        forwarding_unit
        (
            .read_addr(local_read_addr),
            .write_addr(write_addr),
            .write_data(write_data),
            .write_enable(write_enable),
            .mem_data(mem_read_data),
            .read_data(forwarded_data)
        );

        assign read_data[i*DATA_WIDTH +: DATA_WIDTH] = forwarded_data;

    end
endgenerate

endmodule