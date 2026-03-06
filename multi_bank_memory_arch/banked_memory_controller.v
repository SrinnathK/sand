module banked_memory_controller#(
    parameter NUM_BANKS = 4
)
(
    input wire [$clog2(NUM_BANKS)-1:0] bank_id,
    input wire req,

    output wire [NUM_BANKS-1:0] bank_enable
);

bank_selector #(
    .NUM_BANKS(NUM_BANKS)
) selector (
    .bank_id(bank_id),
    .enable(req),
    .bank_enable(bank_enable)
);

endmodule