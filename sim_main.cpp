#include <iostream>
#include <cmath>
#include <string>
#include <memory>
#include <fstream>

#include <verilated.h>
#include <verilated_vcd_c.h>

// Убедись, что тут правильное имя твоего топ-модуля! 
// Если компилируешь top_module.sv, то оставляй Vtop_module.h
#include "Vtop_module.h" 

vluint64_t main_time = 0;

// Квантователь на 12 бит (от -2048 до +2047)
uint16_t quant(double voltage) {
    if (voltage > 1.0) voltage = 1.0;
    else if(voltage < -1.0) voltage = -1.0;

    return (uint16_t)((int16_t)(voltage * 2047.0));
}

int main (int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    Vtop_module *top = new Vtop_module;

    Verilated::traceEverOn(true);
    VerilatedVcdC *tfp = new VerilatedVcdC;
    top->trace(tfp, 99);
    tfp->open("waveform.vcd");

    
    top->clk = 0;
    top->clk_ad = 0;
    top->reset = 1;
    top->start_cmd = 0;
    top->rnw_cmd = 1;
    top->addr_cmd = 0;
    top->data_cmd = 0;
    top->ch_analog[0] = 0;
    top->ch_analog[1] = 0;

    std::ofstream csv_file("signal_data.csv");
    csv_file << "time_s,ch_analog_0\n";

    // ==========================================
    // 1. НАСТРОЙКИ ВРЕМЕНИ И ЧАСТОТ
    // ==========================================
    const double TIME_STEP_S = 0.1e-9;      // Шаг: 0.1 нс
    const double FREQ_FPGA = 150e6;         // ПЛИС: 150 МГц
    const double FREQ_ADC  = 1.2e9;         // АЦП: 1.2 ГГц
    const double HALF_PERIOD_FPGA = 1.0 / (2.0 * FREQ_FPGA);
    const double HALF_PERIOD_ADC  = 1.0 / (2.0 * FREQ_ADC);

    // ==========================================
    // 2. РАДИО И ДАННЫЕ (QPSK)
    // ==========================================
    const double f_carrier = 500e6;   // Несущая 500 МГц
    const int sym_period_ticks = 500; // Смена символа каждые 50 нс
    
    // Наше сообщение
    std::string message = "Hello world"; 
    int total_bits = message.length() * 8;
    int total_symbols = total_bits / 2; // 2 бита на символ

    double timer_fpga = 0.0;
    double timer_adc = 0.0;

    std::cout << "Starting simulation..." << std::endl;
    std::cout << "Message: '" << message << "' (" << total_bits << " bits, " << total_symbols << " symbols)" << std::endl;

    // Симулируем 50 000 шагов (5 микросекунд)
    while (!Verilated::gotFinish() && main_time < 50000) {

        // Держим сброс активным 20 нс (200 тиков)
        if(main_time == 200) top->reset = 0;

        // --- ГЕНЕРАЦИЯ ТАКТОВ ---
        timer_fpga += TIME_STEP_S;
        if (timer_fpga >= HALF_PERIOD_FPGA) {
            top->clk = !top->clk;           
            timer_fpga -= HALF_PERIOD_FPGA; 
        }

        timer_adc += TIME_STEP_S;
        if (timer_adc >= HALF_PERIOD_ADC) {
            top->clk_ad = !top->clk_ad;
            timer_adc -= HALF_PERIOD_ADC;
        }

        // --- ГЕНЕРАЦИЯ QPSK СИГНАЛА С ДАННЫМИ ---
        double time_s = main_time * TIME_STEP_S;
        
        // 1. Узнаем, какой сейчас по счету символ передается
        // % total_symbols заставляет сообщение повторяться по кругу
        int current_symbol = (main_time / sym_period_ticks) % total_symbols;
        
        // 2. Находим нужный байт и позицию бита
        int byte_idx = (current_symbol * 2) / 8;
        int bit_pos  = (current_symbol * 2) % 8;
        
        // 3. Вытаскиваем биты (от младших к старшим)
        uint8_t current_byte = (uint8_t)message[byte_idx];
        int bit_I = (current_byte >> bit_pos) & 0x01;
        int bit_Q = (current_byte >> (bit_pos + 1)) & 0x01;

        // 4. Превращаем биты в уровни: 1 -> +0.5, 0 -> -0.5
        double I_val = (bit_I == 1) ? 0.5 : -0.5;
        double Q_val = (bit_Q == 1) ? 0.5 : -0.5;

        // 5. Модулируем несущую
        double V_qpsk = I_val * cos(2 * M_PI * f_carrier * time_s) 
                      - Q_val * sin(2 * M_PI * f_carrier * time_s);

        // Второй канал оставим пустым (нули), чтобы не отвлекал, 
        // или можешь вернуть туда синус при желании
        top->ch_analog[0] = quant(V_qpsk);
        top->ch_analog[1] = 0;

        // --- SPI Команды ---
        if (main_time == 1000) {
            top->start_cmd = 1;
            top->rnw_cmd = 0;
            top->addr_cmd = 0;
            top->data_cmd = 1;
        }
        if (main_time == 2500){
            top->start_cmd = 0;
            top->rnw_cmd = 1;
        }

        // --- Запись состояния ---
        top->eval();
        tfp->dump(main_time);

       
        csv_file << time_s << "," << (int16_t)top->ch_analog[0] << "\n";

        main_time++;
    }

    top->eval();
    tfp->dump(main_time);
    main_time++;

    csv_file.close();
    std::cout << "Simulation finished successfully!" << std::endl;
    tfp->close();

    
    top->final();
    delete top;

    return 0;
}