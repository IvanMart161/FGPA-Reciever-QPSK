`timescale 100ps / 100ps

module top_module #(
    parameter DATA = 12,
    parameter LANES = 8 
) (
    input logic                 clk_150,
    input logic                 clk_75,
    input logic                 reset,

    // Входы для АЦП
    input logic signed [DATA-1:0] ch_analog [0:1],
    input logic                 clk_ad,
    
    // Команды мастера
    input logic                 start_cmd,
    input logic                 rnw_cmd,                                                    
    input logic                 addr_cmd,
    input logic [1:0]           data_cmd,

    // Выходы: теперь их 8, и мы добавили data_valid
    output logic signed [DATA-1:0] digital_out [0:LANES-1],
    output logic                   data_valid_out
);

    wire sdio_wire;
    wire sclk_wire;
    wire csb_wire;

    

    AD #(
        .DATA(DATA),
        .LANES(LANES) 
    ) adc (
        .clk(clk_150),
        .reset(reset),
        .analog_in(ch_analog),
        .clk_ad(clk_ad),
        .SDIO(sdio_wire),
        .SCLK(sclk_wire),
        .CSB(csb_wire),
        .digital_out(digital_out),
        .data_valid(data_valid_out) 
    );

    spi_master #(
        .addr(1),
        .data(2)
    ) master (
        .clk(clk_150),
        .reset(reset),
        .start(start_cmd),
        .rnw(rnw_cmd),
        .data_in(data_cmd),
        .address(addr_cmd),
        .SDIO(sdio_wire),
        .SCLK(sclk_wire),
        .CSB(csb_wire)
    );

    wire [DATA-1:0] i_channel;                          // Синфазный канал (sin)
    wire [DATA-1:0] q_channel;                          // Квадратурный канал (cos)
    wire [DATA-1:0] data_adc;                           // Данные с АЦП

    nco #(
        .DATA(DATA),
        .ACC(32),
        .LANES(LANES)
    ) (
        .clk(clk_150),
        .reset(reset),

        .cos_out(i_channel),
        .sin_out(q_channel)
    );

    mixer #(
        .ADC_WIDTH(WIDTH),
        .DDS_WIDTH(WIDTH),
        .LANES(LANES)
    ) (
        .clk(clk_150),
        .cos_in(i_channel),
        .sin_in(q_channel),
// ДОПИСАТЬ

    );
endmodule
