module memory_top#(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 16,
    parameter NUM_BANKS  = 4
)
(
    input wire clk,
    input wire we,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] write_data,

    output wire [DATA_WIDTH-1:0] read_data
);

wire [$clog2(NUM_BANKS)-1:0] bank_id;
wire [NUM_BANKS-1:0] bank_enable;

wire [NUM_BANKS*DATA_WIDTH-1:0] bank_data;

wire [ADDR_WIDTH-1:0] bank_addr;

address_map_interleaved #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .NUM_BANKS(NUM_BANKS)
) mapper (
    .addr(addr),
    .bank(bank_id)
);


banked_memory_controller #(
    .NUM_BANKS(NUM_BANKS)
) 

controller (
    .bank_id(bank_id),
    .req(1'b1),
    .bank_enable(bank_enable)
);

genvar i;

generate
    for(i = 0; i < NUM_BANKS; i = i + 1)
    begin : banks

        memory_bank #(
            .DATA_WIDTH(DATA_WIDTH),
            .ADDR_WIDTH(ADDR_WIDTH-2)
        ) mem_bank (
            .clk(clk),
            .we(we & bank_enable[i]),
            .addr(addr[ADDR_WIDTH-1:2]),
            .write_data(write_data),
            .read_data(bank_data[i*DATA_WIDTH +: DATA_WIDTH])
        );

    end
endgenerate

read_mux #(
    .NUM_BANKS(NUM_BANKS),
    .DATA_WIDTH(DATA_WIDTH)
) mux (
    .bank_select(bank_id),
    .bank_data(bank_data),
    .read_data(read_data)
);

endmodule