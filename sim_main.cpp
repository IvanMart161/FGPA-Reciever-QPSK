#include <iostream>
#include <cmath>
#include <memory>

#include <verilated.h>
#include <verilated_vcd_c.h>

#include "Vtop_module.h"

vluint64_t main_time = 0;

uint32_t quant(double voltage, double v_ref, int bits) {
    if (voltage < 0) {
        voltage = 0;
    } else if (voltage > v_ref) {
        voltage = v_ref;
    }
    
    double q_step = v_ref / pow(2,bits);
    return (uint32_t)(voltage / q_step);
}

int main (int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    Vtop_module *top = new Vtop_module;

    Verilated::traceEverOn(true);
    VerilatedVcdC *tfp = new VerilatedVcdC;
    top->trace(tfp, 99);
    tfp->open("waveform.vcd");
    
    top->clk = 0;
    top->reset = 1;
    top->start_cmd = 0;

    const double V_REF = 3.3;
    const int ADC_BITS = 12;

    std::cout << "Testbench has been starting" << std::endl;

    for(int step = 0; step < 2000; step++) {
        if(main_time > 20) top->reset = 0;

        top->clk = !top->clk;

        if (main_time % 4 == 0) top->clk_ad = !top->clk_ad;

        if (main_time < 50) {
        top->rnw_cmd = 0;  // Запись
        top->addr_cmd = 0; // Настройка GAIN
        top->data_cmd = 1; // Усиление x2
    }

        double t = (double)main_time / 100.0;
        double analog_volts = 1.65 + 1.65*sin(t);

        top->ch_analog[0] = quant(analog_volts, V_REF, ADC_BITS);

        

        if (main_time == 50) top->start_cmd = 1;
        if (main_time == 60) top->start_cmd = 0;

        top->eval();
        tfp->dump(main_time);
        main_time++;
    }

    top->eval();

    tfp->dump(main_time);

    main_time++;

    std::cout << "Testbanch has already finished" << std::endl;
    tfp->close();
    top->final();

    return 0;
}


