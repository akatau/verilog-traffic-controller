module traffic_light ( input CLOCK_50, 
                     input [1:0] SW, // switches
                     input [0:0] KEY, // reset is key0
                     output reg [2:0] LED_N, // lights for north
                     output reg [2:0] LED_E, // lights for east
);

    reg [1:0] state; // 0=N_Grn, 1=Yel, 2=E_Grn, 3=Yel2
    reg [5:0] timer_sec;
    wire one_hz_enable;
    
    parameter CNT_MAX = 50000000; //for a 50MHz clock; 50000000 cycles =1 sec

    // Generate 1 second pulse
    reg [31:0] clk_cnt;
    always @(posedge CLOCK_50 or negedge KEY[0]) begin
        if(KEY[0] == 0) begin
            clk_cnt <= 0;
        end else begin
            if(clk_cnt == CNT_MAX - 1) begin
                clk_cnt <= 0;
            end else begin
                clk_cnt <= clk_cnt + 1;
            end
        end
    end
    assign one_hz_enable = (clk_cnt == CNT_MAX - 1) ? 1'b1 : 1'b0;

    // FSM
    // state 0: North Green
    // state 1: Yellow - Yellow (switching to East)
    // state 2: East Green
    // state 3: Yellow - Yellow (switching to North)
    
    always @(posedge CLOCK_50 or negedge KEY[0]) begin
        if(!KEY[0]) begin
            state <= 0;
            timer_sec <= 30; // start with 30s
        end else begin
            if(one_hz_enable) begin
                if(timer_sec > 0)
                    timer_sec <= timer_sec - 1;
                
                // State transitions
                if(timer_sec == 0) begin
                    if(state == 0) begin // North Green
                        // if car at east, switch. if no car east, stay green.
                        if(SW[1] == 1) begin
                            state <= 1;
                            timer_sec <= 5; 
                        end else begin
                             // If no car at East, we stay Green.
                             state <= 0; 
                             timer_sec <= 0; // keep at 0, so we check again next second
                        end
                    end
                    else if(state == 1) begin // YY transition
                        state <= 2;
                        timer_sec <= 30;
                    end
                    else if(state == 2) begin // East Green
                        // if car at north, switch
                        if(SW[0] == 1) begin
                            state <= 3;
                            timer_sec <= 5;
                        end
                    end
                    else if(state == 3) begin // YY transition
                        state <= 0;
                        timer_sec <= 30;
                    end
                end 
            end
        end
    end

    // Output logic for LEDs
    // LED format: Red(bit2), Yellow(bit1), Green(bit0)
    always @(*) begin
        if(state == 0) begin
            LED_N = 3'b001; // green
            LED_E = 3'b100; // red
        end
        else if(state == 1) begin
            // requirement: both yellow
            LED_N = 3'b010; 
            LED_E = 3'b010; 
        end
        else if(state == 2) begin
            LED_N = 3'b100; // red
            LED_E = 3'b001; // green
        end
        else if(state == 3) begin
            // requirement: both yellow
            LED_N = 3'b010;
            LED_E = 3'b010;
        end
        else begin
            LED_N = 3'b100;
            LED_E = 3'b100;
        end
    end

endmodule
