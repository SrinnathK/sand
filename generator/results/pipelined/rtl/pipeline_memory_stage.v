module pipeline_memory_stage
#(
    parameter DATA_WIDTH = 8,
parameter ADDR_WIDTH = 7,
parameter NUM_BANKS  = 4
)
(
    input wire clk,
    input wire rst,

    input wire in_valid,
    input wire in_write,
    input wire [ADDR_WIDTH-1:0] in_addr,
    input wire [DATA_WIDTH-1:0] in_wdata,
    input wire [$clog2(NUM_BANKS)-1:0] in_bank,

    output reg resp_valid,
    output wire [DATA_WIDTH-1:0] resp_rdata
);

wire [NUM_BANKS-1:0] bank_enable;

bank_selector
#(
    .NUM_BANKS(NUM_BANKS)
)
selector
(
    .bank_id(in_bank),
    .enable(in_valid),
    .bank_enable(bank_enable)
);

wire [NUM_BANKS*DATA_WIDTH-1:0] bank_rdata;

genvar i;

generate
    for(i=0;i<NUM_BANKS;i=i+1) begin : bank_loop

        memory_bank
        #(
            .DATA_WIDTH(DATA_WIDTH),
            .ADDR_WIDTH(ADDR_WIDTH)
        )
        bank_inst
        (
            .clk(clk),
            .we(bank_enable[i] & in_write),
            .addr(in_addr),
            .write_data(in_wdata),
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
    .bank_select(in_bank),
    .bank_data(bank_rdata),
    .read_data(resp_rdata)
);

always @(posedge clk or posedge rst) begin
    if(rst)
        resp_valid <= 0;
    else
        resp_valid <= in_valid;
end

endmodule