#include <iostream>
#include <cmath>
#include <memory>

#include <verilated.h>
#include <verilated_vcd_c.h>

#include "Vtop_module.h"

vluint64_t main_time = 0;

uint16_t quant(double voltage) {
    if (voltage > 1) voltage = 1;
    else if(voltage < -1) voltage = -1;

    return (int16_t)(voltage*16384.0);
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

    

    const double V_REF = 3.3;
    const int ADC_BITS = 12;

    std::cout << "Testbench has been starting" << std::endl;

    while (!Verilated::gotFinish() &&  main_time < 5000) {

	if(main_time == 20) top->reset = 0;

	if (main_time % 10 < 5) {
	    top->clk = 1;
	} else {
	    top->clk = 0;
	}  

	if(main_time % 100 < 50) {
	    top->clk_ad = 1;
	} else {
	    top->clk_ad = 0;
	}
// Generate signals 

	double time_s = main_time * 1e-9;
    
    double V1 = 0.25 * cos(2 * M_PI * 1e6 * time_s);
    double V2 = 0.25 * cos(2 * M_PI * 250e3 * time_s);

	top->ch_analog[0] = quant(V1);

	top->ch_analog[1] = quant(V2);

// First packet SDIO

	if (main_time == 100) {
	    top->start_cmd = 1;
	    top->rnw_cmd = 0;
	    top->addr_cmd = 0;
	    top->data_cmd = 1;
       	}

	if (main_time == 250){
	    top->start_cmd = 0;
	    top->rnw_cmd = 1;
	}

// Second packet SDIO

	if (main_time == 2500) {
	    top->start_cmd = 1;
	    top->rnw_cmd = 0;
	    top->addr_cmd = 1;
	    top->data_cmd = 0;
       	}

	if (main_time == 2650){
	    top->start_cmd = 0;
	    top->rnw_cmd = 1;
	}

// End while 
	

	top->eval();
	tfp->dump(main_time);
	main_time++;

    }

    top->eval();

    tfp->dump(main_time);

    main_time++;

    std::cout << "Testbanch has already finished" << std::endl;
    tfp->close();

    delete top;
    delete tfp;
    top->final();

    return 0;
}


