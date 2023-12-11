# NES

This repository contains the code for the Fall 2023 UIUC ECE 385 Final Project by Gabriel Wozniak (gfw3) and George Vintila (gvinti2). 

The repository is set up for two individual demonstrations, one for demonstrating NES PPU functionality and NES CPU functionality. Unfortunately we were not able to integrate the two components for a complete NES system.

### DEMO 1: CPU

To run the CPU simulation, create a new Vivado RTL project with all the usual settings and add sources from the directory under "NES_CPU.srcs." Set the "testbench" file to be the top level. Run a simulation and then add various CPU signals. The main important signals to monitor are AB_out, DB_in, DB_out, PC_Reg_out, Op_State, and all of the relevant output registers (Ex: X_Reg_out).

The final CPU will be titled "CPU_v3." The Test_ROM_v2 BRAM file that will be connected to the CPU will contain the Klaus 6502 functional test file based on the github link here: https://github.com/Klaus2m5/6502_65C02_functional_tests. More information on all of this will be provided in the final report


### DEMO 2: PPU

The PPU demo is meant to be run on hardware by generating a bitstream and programming an Urbana board. 

To run the PPU demo, create a new Vivado RTL project with the following settings: add sources from the directory "RTL", and add constraints from "Constraints/ppu_hw_test.xdc". Additionally, once the Vivado project is instantiated, you will need to import the "hdmi_tx_1.0" IP into the project by going to IP catalog, right clicking on "Vivado Repositories", clicking "Add repository" and adding the directory "IP/hdmi_tx_1.0". After all these steps are complete, set the top-level file to "NES" from "NES.sv" and compile the bitstream. You may also need to upgrade the IPs individually before synthesis.

The end result is an HDMI signal which renders a random scrolling background made up of Super Mario Bros sprites as well as a floating sprite which moves in a circle. The screen effects are controlled by manipulation of the PPU registers.
