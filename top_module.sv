module top_module #(
    parameter DATA = 16
) (
    input logic                 clk,
    input logic                 reset,

// Входы для АЦП
    input logic signed     [DATA-1:0]  ch_analog [0:1],
    input logic                 clk_ad,
    
// Команды мастера
    input logic                 start_cmd,
    input logic                 rnw_cmd,                                                    
    input logic                 addr_cmd,
    input logic     [1:0]       data_cmd,

    output logic signed    [15:0]      digital_out [0:3]
);
    wire sdio_wire;
    wire sclk_wire;
    wire csb_wire;

    AD #(
        .DATA(DATA)
    ) adc (
        .clk(clk),
        .reset(reset),
        .analog_in(ch_analog),
        .clk_ad(clk_ad),
        .SDIO(sdio_wire),
        .SCLK(sclk_wire),
        .CSB(csb_wire),
        .digital_out(digital_out)
    );

    spi_master #(
        .addr(1),
        .data(2)
    ) master (
        .clk(clk),
        .reset(reset),
        .start(start_cmd),
        .rnw(rnw_cmd),
        .data_in(data_cmd),
        .address(addr_cmd),
        .SDIO(sdio_wire),
        .SCLK(sclk_wire),
        .CSB(csb_wire)
    );

endmodule
