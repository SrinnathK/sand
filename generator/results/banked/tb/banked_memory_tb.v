`timescale 1ns/1ps

module banked_memory_tb;

parameter DATA_WIDTH = 8;
parameter ADDR_WIDTH = 7;
parameter NUM_READ_PORTS = 2;
parameter NUM_WRITE_PORTS = 1;

reg clk;
reg rst;

reg [NUM_WRITE_PORTS-1:0] write_en;
reg [ADDR_WIDTH-1:0] write_addr [0:NUM_WRITE_PORTS-1];
reg [DATA_WIDTH-1:0] write_data [0:NUM_WRITE_PORTS-1];

reg [ADDR_WIDTH-1:0] read_addr [0:NUM_READ_PORTS-1];
wire [DATA_WIDTH-1:0] read_data [0:NUM_READ_PORTS-1];

integer i;

banked_memory_top dut (
    .clk(clk),
    .rst(rst)
);

always #5 clk = ~clk;

initial begin

    clk = 0;
    rst = 1;

    #20 rst = 0;

    // ---------------------------
    // WRITE TEST
    // ---------------------------

    for(i=0;i<NUM_WRITE_PORTS;i=i+1) begin
        write_en[i] = 1;
        write_addr[i] = i;
        write_data[i] = i + 100;
    end

    #10;

    for(i=0;i<NUM_WRITE_PORTS;i=i+1)
        write_en[i] = 0;

    // ---------------------------
    // READ TEST
    // ---------------------------

    for(i=0;i<NUM_READ_PORTS;i=i+1)
        read_addr[i] = i;

    #20;

    for(i=0;i<NUM_READ_PORTS;i=i+1)
        $display("READ[%0d] = %0d", i, read_data[i]);

    // ---------------------------
    // RANDOM ACCESS TEST
    // ---------------------------

    repeat(20) begin

        for(i=0;i<NUM_WRITE_PORTS;i=i+1) begin
            write_en[i] = $random;
            write_addr[i] = $random;
            write_data[i] = $random;
        end

        for(i=0;i<NUM_READ_PORTS;i=i+1)
            read_addr[i] = $random;

        #10;

    end

    $display("Simulation Finished");

    #50 $finish;

end

endmodule