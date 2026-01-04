module traffic_light ( input CLOCK_50, 
                     input [1:0] SW, // switches
                     input [0:0] KEY, // reset is key0
                     output reg [2:0] LED_N, // lights for north
                     output reg [2:0] LED_E, // lights for east
                     output [6:0] HEX0,
                     output [6:0] HEX1
);

    reg [1:0] state; // variable to hold the state: 0=N_Grn, 1=Y_Y(to E), 2=E_Grn, 3=Y_Y(to N)
    reg [5:0] timer_sec; // variable to count the seconds down
    wire one_hz_enable; // a signal that turns on once per second
    
    parameter CNT_MAX = 50000000; //for a 50MHz clock; 50000000 cycles =1 sec

    // Logic to create a 1-second pulse from the fast clock
    reg [31:0] clk_cnt; //arbitrarely big counter variable (larger than the 50 million)
    always @(posedge CLOCK_50 or negedge KEY[0]) begin
        if(KEY[0] == 0) begin
            clk_cnt <= 0;
        end else begin
            if(clk_cnt == CNT_MAX - 1) begin
                clk_cnt <= 0; // reset counter back to 0 when 1 sec passes
            end else begin
                clk_cnt <= clk_cnt + 1;
            end
        end
    end

    // logic for the 1 second tick; set the wire to 1 only when the counter finishes
    assign one_hz_enable = (clk_cnt == CNT_MAX - 1) ? 1'b1 : 1'b0; 

    // FSM
    // state 0: North Green
    // state 1: Yellow - Yellow (switching to East)
    // state 2: East Green
    // state 3: Yellow - Yellow (switching to North)
    
    always @(posedge CLOCK_50 or negedge KEY[0]) begin
        if(!KEY[0]) begin
            state <= 0;
            timer_sec <= 30; // start with 30s green
        end else begin
            if(one_hz_enable) begin // only do this every one second
                if(timer_sec > 0) 
                    timer_sec <= timer_sec - 1; // count down the timer if it hasn't reached zero
                
                // Logic for changing states when time runs out
                if(timer_sec == 0) begin

                    if(state == 0) begin // Currently North is Green
                        // // time is up, so check if a car is waiting at East: if car at east, switch. if no car east, stay green.
                        if(SW[1] == 1) begin
                            state <= 1;
                            timer_sec <= 5; 
                        end else begin
                             // If no car at East, we stay Green.
                             state <= 0; 
                             timer_sec <= 0; // keep at 0, so we check again next second
                        end
                    end
                    else if(state == 1) begin // Transition state (Yellow-Yellow)
                        state <= 2;  // Move to East Green
                        timer_sec <= 30;
                    end
                    else if(state == 2) begin // currently East is Green
                        // time is up, check if a car is waiting at North: if car at north, switch
                        if(SW[0] == 1) begin
                            state <= 3;
                            timer_sec <= 5;
                        end
                    end
                    else if(state == 3) begin // YY transition
                        state <= 0; // Loop back to North Green
                        timer_sec <= 30;
                    end
                end 
            end
        end
    end

    // Output logic for LEDs
    // I am using bit 2 for Red, 1 for Yellow, 0 for Green
    always @(*) begin
        if(state == 0) begin // North Green State
            LED_N = 3'b001; // green
            LED_E = 3'b100; // red
        end
        else if(state == 1) begin // Transition state
            // both must be yellow
            LED_N = 3'b010; // North Yellow
            LED_E = 3'b010; // East Yellow
        end
        else if(state == 2) begin
            LED_N = 3'b100; // north red on
            LED_E = 3'b001; // east green on
        end
        else if(state == 3) begin
            // both must be yellow
            LED_N = 3'b010;
            LED_E = 3'b010;
        end
        else begin // Default case; just to be safe
            LED_N = 3'b100;
            LED_E = 3'b100;
        end
    end

    // Display logic
    wire [3:0] ones;
    wire [3:0] tens;
    
    // simple math for digits
    assign ones = timer_sec % 10;
    assign tens = timer_sec / 10;

    // instantiate hex decoders
    HexDecoder h0(ones, HEX0);
    HexDecoder h1(tens, HEX1);

endmodule

// Helper module for 7 segment—I used an LLM for this submodule tbh; too mundane to do from scratch
module HexDecoder(in, out);
    input [3:0] in;
    output reg [6:0] out;

    always @(*) begin
        // active low
        case(in)
            0: out = 7'b1000000;
            1: out = 7'b1111001;
            2: out = 7'b0100100;
            3: out = 7'b0110000;
            4: out = 7'b0011001;
            5: out = 7'b0010010; 
            6: out = 7'b0000010;
            7: out = 7'b1111000;
            8: out = 7'b0000000;
            9: out = 7'b0010000;
            default: out = 7'b1111111;
        endcase
    end
endmodule
