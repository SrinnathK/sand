module read_mux
#(
    parameter NUM_BANKS  = 2,
    parameter DATA_WIDTH = 8
)
(
    input  wire [$clog2(NUM_BANKS)-1:0] bank_select,
    input  wire [NUM_BANKS*DATA_WIDTH-1:0] bank_data,
    output reg  [DATA_WIDTH-1:0] read_data
);

integer i;

always @(*) begin
    read_data = {DATA_WIDTH{1'b0}};

    for(i = 0; i < NUM_BANKS; i = i + 1) begin
        if(bank_select == i)
            read_data = bank_data[i*DATA_WIDTH +: DATA_WIDTH];
    end
end

endmodule