`timescale 1ns/1ps

module tb_traffic;

    reg clk;
    reg [1:0] sw;
    reg reset_n;
    wire [2:0] led_n;
    wire [2:0] led_e;
    wire [6:0] h0;
    wire [6:0] h1;

    traffic_light dut (
        .CLOCK_50(clk),
        .SW(sw),
        .KEY(reset_n),
        .LED_N(led_n),
        .LED_E(led_e),
        .HEX0(h0),
        .HEX1(h1)
    );

    // make simulation faster
    // override the counter max value so 1 sec = 5 clocks
    defparam dut.CNT_MAX = 5; 

    initial begin
        $dumpfile("tb_traffic.vcd");
        $dumpvars(0,tb_traffic);
        clk = 0;
        forever #10 clk = ~clk; // 50mhz ish
    end

    initial begin
        $display("starting simulation...");
        reset_n = 0;
        sw = 0;
        #100;
        reset_n = 1;
        $display("reset done");

        // 1. Check default state (North Green)
        #200; 
        if(led_n == 3'b001) $display("North is Green");
        
        // wait, make sure it stays green if no cars
        #500;
        
        // 2. Car comes at East (SW1)
        $display("Car at East now");
        sw[1] = 1;
        
        // wait for timer (30s) + transition. 
        // since we speed up simulation, just wait enough clocks 30s * 5 clocks = 150 clocks. plus buffer.
        #2000; 
        
        // check if it switched to East Green
        // but first check the Yellow-Yellow state (2 = 010)
        // Hard to catch exact moment in print without monitor, 
        // but lets check final state
        if(led_e == 3'b001) $display("East is Green now");
        else $display("Error: East not green?");

        // 3. Car comes at North (Cycle)
        sw[0] = 1; // now both are 1
        $display("Cars both sides");

        // wait for cycle back to North
        #2000;
        if(led_n == 3'b001) $display("Back to North Green");
        
        // wait for cycle back to East
        #2000;
        if(led_e == 3'b001) $display("Back to East Green");
        
        $display("test finished");
        $stop;
    end

endmodule
