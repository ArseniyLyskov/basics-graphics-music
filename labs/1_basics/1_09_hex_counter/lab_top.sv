`include "config.svh"

module lab_top
# (
    parameter  clk_mhz       = 50,
               w_key         = 4,
               w_sw          = 8,
               w_led         = 8,
               w_digit       = 8,
               w_gpio        = 100,

               screen_width  = 640,
               screen_height = 480,

               w_red         = 4,
               w_green       = 4,
               w_blue        = 4,

               w_x           = $clog2 ( screen_width  ),
               w_y           = $clog2 ( screen_height )
)
(
    input                        clk,
    input                        slow_clk,
    input                        rst,

    // Keys, switches, LEDs

    input        [w_key   - 1:0] key,
    input        [w_sw    - 1:0] sw,
    output logic [w_led   - 1:0] led,

    // A dynamic seven-segment display

    output logic [          7:0] abcdefgh,
    output logic [w_digit - 1:0] digit,

    // Graphics

    input        [w_x     - 1:0] x,
    input        [w_y     - 1:0] y,

    output logic [w_red   - 1:0] red,
    output logic [w_green - 1:0] green,
    output logic [w_blue  - 1:0] blue,

    // Microphone, sound output and UART

    input        [         23:0] mic,
    output       [         15:0] sound,

    input                        uart_rx,
    output                       uart_tx,

    // General-purpose Input/Output

    inout        [w_gpio  - 1:0] gpio
);

    //------------------------------------------------------------------------

    // assign led        = '0;
    // assign abcdefgh   = '0;
    // assign digit      = '0;
       assign red        = '0;
       assign green      = '0;
       assign blue       = '0;
       assign sound      = '0;
       assign uart_tx    = '1;

    //------------------------------------------------------------------------

    /* logic [31:0] period;

    localparam min_period = clk_mhz * 1000 * 1000 / 50,
               max_period = clk_mhz * 1000 * 1000 *  3;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            period <= 32' ((min_period + max_period) / 2);
        else if (key [0] & period != max_period)
            period <= period + 32'h1;
        else if (key [1] & period != min_period)
            period <= period - 32'h1;

    logic [31:0] cnt_1;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            cnt_1 <= '0;
        else if (cnt_1 == '0)
            cnt_1 <= period - 1'b1;
        else
            cnt_1 <= cnt_1 - 1'd1;

    logic [31:0] cnt_2;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            cnt_2 <= '0;
        else if (cnt_1 == '0)
            cnt_2 <= cnt_2 + 1'd1;

    assign led = cnt_2; */

    //------------------------------------------------------------------------

    // 4 bits per hexadecimal digit
    /* localparam w_display_number = w_digit * 4;

    seven_segment_display # (w_digit) i_7segment
    (
        .clk      ( clk                       ),
        .rst      ( rst                       ),
        .number   ( w_display_number' (cnt_2) ),
        .dots     ( w_digit' (0)              ),
        .abcdefgh ( abcdefgh                  ),
        .digit    ( digit                     )
    ); */

    //------------------------------------------------------------------------

    // Exercise 1:
    // Implement a circular line on seven-segment 
    // indicators using multi-bit shift registers

    // Exercise 2:
    // Add control of the speed of movement of the 
    // running line to the solution of exercise 1.

    localparam W_SHIFT_SPEED = $clog2(w_led);

    logic [31:0] counter;
    logic digit_strobe, shift_strobe;
    logic [W_SHIFT_SPEED - 1 : 0] shift_speed;
    logic [w_key - 1 : 0] key_r;

    always_ff @(posedge clk or posedge rst)
        if (rst) counter <= '0;
        else counter <= counter + 1'b1;

    always_ff @(posedge clk or posedge rst)
        if (rst) key_r <= '0;
        else key_r <= key;

    always_ff @(posedge clk or posedge rst)
        if (rst) shift_speed <= 1'b1; 
        else if (~ key_r[1] & key[1]) shift_speed <= shift_speed == w_led - 1 ? 0 : shift_speed + 1;
        else if (~ key_r[0] & key[0]) shift_speed <= shift_speed == 0 ? w_led - 1 : shift_speed - 1;

    assign digit_strobe = counter [14:0] == '0;
    assign shift_strobe = (counter [24 : 0] & {shift_speed < 1, shift_speed < 2, shift_speed < 3, {22{1'b1}}}) == '0;

    assign led = 1 << shift_speed;

    //   --a--
    //  |     |
    //  f     b
    //  |     |
    //   --g--
    //  |     |
    //  e     c
    //  |     |
    //   --d--  h

    localparam REG_SIZE = 16;

    enum logic [7:0] {
        A     = 8'b1110_1110,
        R     = 8'b0000_1010,
        S     = 8'b1011_0110,
        E     = 8'b1001_1110,
        N     = 8'b0010_1010,
        I     = 8'b0110_0000,
        Y     = 8'b0111_0110,
        space = 8'b0000_0000,
        L     = 8'b0001_1100,
        K     = 8'b1010_1110,
        O     = 8'b1111_1100,
        V     = 8'b0011_1000
    } seven_seg_encoding;

    logic [REG_SIZE - 1 : 0][7:0] shift_reg;

    always_ff @(posedge clk or posedge rst)
        if (rst) shift_reg <= { A, L, I, N, A, space, L, Y, S, K, O, V, A, space, space, space };
        else if (shift_strobe) shift_reg <= { shift_reg[REG_SIZE - 2 : 0], shift_reg[REG_SIZE - 1] };

    logic [$clog2(w_led) - 1 : 0] digit_reg;
    always_ff @ (posedge clk or posedge rst)
        if (rst) digit_reg <= '0;
        else if (digit_strobe) digit_reg <= digit_reg == w_digit - 1 ? 0 : digit_reg + 1;

    assign digit = 1 << digit_reg;
    assign abcdefgh = shift_reg[digit_reg];

endmodule
