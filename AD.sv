module AD #(
    parameter DATA = 16
) (
    input logic                     clk,
    input logic                     reset,

//Входы для двух каналов АЦП 
    input logic     [DATA-1:0]      analog_in [0:1],
    input logic                     clk_ad,                          

// Внешние пины для связи с spi_master
    input logic                     SDIO,        
    input logic                     SCLK,
    input logic                     CSB,                     

    output logic    [2*DATA-1:0]    digital_out
);


//==============Реализация внешнего устройства для АЦП==============

logic [2:0] GAIN = 3'b001;
logic CHANNEL = 1'b0;                                                                                                                               

logic [3:0] shift_reg = 4'b0000;
logic prev_SCLK;
logic prev_CSB;

always_ff @( posedge clk ) begin
    if(reset) begin
        prev_SCLK <= 1'b0;
        prev_CSB <= 1'b1;
        shift_reg <= 4'b0000;
    end else begin

        prev_SCLK <= SCLK;
        prev_CSB <= CSB;

        if(CSB == 1'b0 && SCLK == 1'b1 && prev_SCLK == 1'b0) begin

            shift_reg <= {shift_reg[2:0], SDIO};                                                                                        //Сдвигаем регистр в момент фронта SCLK, когда происходит запись CSB = 0
                                                                                                                                        
        end else if(prev_CSB == 1'b0 && CSB == 1'b1) begin                                                                              // Как только CSB становится 1, то передача прекращается и мы можем обрабатывать данные в shift_reg
            if (shift_reg[3] == 1'b0) begin                                                                                             // Если бит R/W 0, то это запись, если 1, то это чтение.    
                                                                                                                                        

                if(shift_reg[2] == 1'b0) begin

                    case(shift_reg[1:0])                                                                                                 // Адрес 0x00 для усиления
                        2'b00: GAIN <= 3'b001;                                                                                           // Коэффициент усиления 1
                        2'b01: GAIN <= 3'b010;                                                                                           // Коэффициент усиления 2
                        2'b10: GAIN <= 3'b100;                                                                                           // Коэффициент усиления 4
                        2'b11: GAIN <= 3'b111;                                                                                           // Коэффициент усиления 8    
                        default: GAIN <= 3'b001;
                    endcase

                end else begin

                    case(shift_reg[1:0])                                                                                                 // Адрес 0x01 для выбора канала
                        2'b00: CHANNEL <= 1'b0;
                        2'b01: CHANNEL <= 1'b1;
                        default: CHANNEL <= 1'b0;
                    endcase

                end
            end
        end
    end
end

//==============Реализация логики оцифровки аналогового сигнала==============
logic clk_ad_prev;
logic [DATA-1:0] clk_ad_reg;                                                                                                         // Стробирующие импульсы для АЦП
logic [DATA-1:0] analog_in_selected;

assign analog_in_selected = (CHANNEL == 1'b0) ? analog_in[0] : analog_in[1];                                                         // Выбираем канал

always_ff @(posedge clk) begin
    if(reset) begin
        clk_ad_prev <= 1'b0;
        clk_ad_reg <= 0;
    end else begin
            clk_ad_prev <= clk_ad;

        if(clk_ad_prev == 1'b0 && clk_ad == 1'b1) begin
            clk_ad_reg <= {DATA{1'b1}};                                                                                             // Стробирующий импульс для АЦП, который будет действовать в течение одного такта, что позволяет нам захватить значение аналогового сигнала в момент его изменения
        
        end else begin
            clk_ad_reg <= {DATA{1'b0}};
        
        end
    end
    
end

assign digital_out = clk_ad_reg * analog_in_selected * GAIN;

endmodule
