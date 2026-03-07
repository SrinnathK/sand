module arbiter_round_robin
#(
    parameter N = 4
)
(
    input wire clk,
    input wire reset,

    input wire [N-1:0] req,
    output reg [N-1:0] grant
);

reg [$clog2(N)-1:0] pointer;

integer i;
integer index;
reg found;

always @(*) begin
    grant = 0;
    found = 0;

    for(i = 1; i <= N; i = i + 1) begin
        index = (pointer + i) % N;

        if(req[index] && !found) begin
            grant[index] = 1'b1;
            found = 1'b1;
        end
    end
end

always @(posedge clk or posedge reset) begin
    if(reset)
        pointer <= 0;
    else begin
        for(i = 0; i < N; i = i + 1)
            if(grant[i])
                pointer <= i;
    end
end

endmodule