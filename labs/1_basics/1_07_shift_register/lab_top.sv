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

    logic [31:0] cnt;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            cnt <= '0;
        else
            cnt <= cnt + 1'd1;

    wire shift = (cnt [21:0] == '0);
    wire switch_reg = (cnt [14:0] == '0);
    wire button_on = | key;

    //------------------------------------------------------------------------

    /* logic [w_led - 1:0] shift_reg;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            shift_reg <= '1;
        else if (shift)
            shift_reg <= { button_on, shift_reg [w_led - 1:1] };

    assign led = shift_reg; */

    // Exercise 1: Make the light move in the opposite direction.

    /* logic [w_led - 1:0] shift_reg;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            shift_reg <= '1;
        else if (shift)
            shift_reg <= { shift_reg [w_led - 2:0], button_on };

    assign led = shift_reg; */

    // Exercise 2: Make the light moving in a loop.
    // Use another key to reset the moving lights back to no lights.

    /* logic [w_led - 1:0] shift_reg;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            shift_reg <= '0;
        else if (shift)
            shift_reg <= { shift_reg[0] | button_on, shift_reg[w_led - 1:1] };

    assign led = shift_reg; */

    // Exercise 3: Display the state of the shift register
    // on a seven-segment display, moving the light in a circle.

    localparam REG_SIZE = 16;
    logic [REG_SIZE - 1 : 0] shift_reg;

    logic [7:0] abcdefgh_table [0 : REG_SIZE - 1] = '{
        'b1000_0000, 'b0000_0100, 'b0000_0010, 'b0100_0000, 'b1000_0000, 
        'b1000_0000, 'b0100_0000, 'b0010_0000, 'b0001_0000, 'b0010_0000,
        'b0000_0010, 'b0000_1000, 'b0001_0000, 'b0001_0000, 'b0000_1000,
        'b0000_0100
    };
    logic [w_digit - 1 : 0] digit_table [0 : REG_SIZE - 1] = '{
        'b1000, 'b0100, 'b0100, 'b0100, 'b0010, 
        'b0001, 'b0001, 'b0001, 'b0001, 'b0010,
        'b0010, 'b0010, 'b0100, 'b1000, 'b1000,
        'b1000
    };

    logic [$clog2(REG_SIZE) - 1 : 0] reg_sel;
    always_ff @ (posedge clk or posedge rst)
        if (rst)
            reg_sel <= '0;
        else if (switch_reg)
            reg_sel <= (reg_sel == REG_SIZE - 1) ? 0 : reg_sel + 1;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            shift_reg <= '0;
        else if (shift)
            shift_reg <= { shift_reg[REG_SIZE - 2: 0], shift_reg[REG_SIZE - 1] | button_on };

    assign abcdefgh = shift_reg[reg_sel] ? abcdefgh_table [reg_sel] : '0;
    assign digit    = digit_table [reg_sel];

endmodule
