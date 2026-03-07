module bank_selector
#(
    parameter NUM_BANKS = 1
)
(
    input  wire [$clog2(NUM_BANKS)-1:0] bank_id,
    input  wire enable,

    output reg [NUM_BANKS-1:0] bank_enable
);

integer i;

always @(*) begin
    bank_enable = {NUM_BANKS{1'b0}};

    if(enable) begin
        for(i = 0; i < NUM_BANKS; i = i + 1) begin
            if(i == bank_id)
                bank_enable[i] = 1'b1;
        end
    end
end

endmodule