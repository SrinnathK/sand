module interleaved_bank_array
#(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 10,
    parameter NUM_BANKS  = 4
)
(
    input wire clk,

    input wire write_enable,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] write_data,

    input wire [NUM_BANKS-1:0] bank_enable,
    input wire [$clog2(NUM_BANKS)-1:0] bank_select,

    output wire [DATA_WIDTH-1:0] read_data
);

wire [NUM_BANKS*DATA_WIDTH-1:0] bank_rdata;

genvar i;

generate
    for(i=0;i<NUM_BANKS;i=i+1)
    begin : bank_loop

        memory_bank
        #(
            .DATA_WIDTH(DATA_WIDTH),
            .ADDR_WIDTH(ADDR_WIDTH)
        )
        bank_inst
        (
            .clk(clk),
            .we(write_enable & bank_enable[i]),
            .addr(addr),
            .write_data(write_data),
            .read_data(bank_rdata[i*DATA_WIDTH +: DATA_WIDTH])
        );

    end
endgenerate

read_mux
#(
    .NUM_BANKS(NUM_BANKS),
    .DATA_WIDTH(DATA_WIDTH)
)
mux
(
    .bank_select(bank_select),
    .bank_data(bank_rdata),
    .read_data(read_data)
);

endmodule