# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge

class HistogramResults:
    def __init__(self):
        self.data_out = []
        self.captured_data = [0] * 64
        self.capture_index = 0
        self.test_count = 0
        
    def clear(self):
        self.data_out = []
        self.capture_index = 0
        self.test_count = 0

@cocotb.test()
async def test_histogram(dut):
    dut._log.info("Start")
    
    results = HistogramResults()
    
    # Create a 40ns period clock 
    clock = Clock(dut.clk, 40, units="ns")
    cocotb.start_soon(clock.start())
    
    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    
    # Helper function to write data to histogram
    async def write_to_bin(bin_value, count):
        for _ in range(count):
            await RisingEdge(dut.clk)
            if dut.uio_out.value.integer & 0x4:  # Check ready bit
                # Write upper byte
                dut.ui_in.value = (0 << 7) | (1 << 6) | 0  # load_upper=1
                dut.uio_in.value = 0
                await RisingEdge(dut.clk)
                
                # Write lower byte with write_en
                dut.ui_in.value = (1 << 7) | (0 << 6) | (bin_value & 0x3F)  # write_en=1
                dut.uio_in.value = 0
                await RisingEdge(dut.clk)
                
                # Clear write_en
                dut.ui_in.value = (0 << 7) | (0 << 6) | (bin_value & 0x3F)
                
                # Wait for completion
                while not (dut.uio_out.value.integer & 0x4) and not (dut.uio_out.value.integer & 0x2):
                    await RisingEdge(dut.clk)
                if dut.uio_out.value.integer & 0x2:  # last_bin
                    await RisingEdge(dut.clk)
    
    # Test Case 1: Fill an 8-bit bin (bin 5) until overflow
    dut._log.info("Test Case 1: Filling 8-bit bin 5 until overflow")
    await write_to_bin(5, 256)  # Should trigger at 255
    
    # Wait for output sequence
    while not (dut.uio_out.value.integer & 0x4):  # Wait for ready
        await RisingEdge(dut.clk)
    await ClockCycles(dut.clk, 10)
    
    # Test Case 2: Fill a 4-bit bin (bin 15) until overflow
    dut._log.info("Test Case 2: Fill 4-bit bin 15 until overflow")
    await write_to_bin(15, 16)  # Should trigger at 15
    
    # Wait for output sequence
    while not (dut.uio_out.value.integer & 0x4):
        await RisingEdge(dut.clk)
    await ClockCycles(dut.clk, 10)
    
    # Test Case 3: Test boundary between 8-bit and 4-bit regions
    dut._log.info("Test Case 3: Testing boundary between 8-bit and 4-bit regions")
    await write_to_bin(9, 100)   # Last 8-bit bin
    await write_to_bin(10, 10)   # First 4-bit bin
    
    # Wait for completion
    while not (dut.uio_out.value.integer & 0x4):
        await RisingEdge(dut.clk)
    await ClockCycles(dut.clk, 10)
    
    # Test Case 4: Random pattern test across both regions
    dut._log.info("Test Case 4: Random pattern test across both regions")
    # Test 8-bit bins
    for i in range(10):
        await write_to_bin(i, 50)  # Write 50 counts to 8-bit bins
    
    # Test 4-bit bins
    for i in range(10, 20):
        await write_to_bin(i, 10)  # Write 10 counts to some 4-bit bins
    
    # Wait for completion
    while not (dut.uio_out.value.integer & 0x4):
        await RisingEdge(dut.clk)
    await ClockCycles(dut.clk, 10)
    
    # Test Case 5: Edge case testing
    dut._log.info("Test Case 5: Edge case testing")
    await write_to_bin(0, 10)     # First bin
    await write_to_bin(9, 10)     # Last 8-bit bin
    await write_to_bin(10, 10)    # First 4-bit bin
    await write_to_bin(63, 10)    # Last bin
    
    # Wait for completion
    while not (dut.uio_out.value.integer & 0x4):
        await RisingEdge(dut.clk)
    await ClockCycles(dut.clk, 10)
    
    # Capture and monitor output data
    @cocotb.coroutine
    async def monitor_outputs():
        while True:
            await RisingEdge(dut.clk)
            if dut.uio_out.value.integer & 0x1:  # valid_out
                value = dut.uo_out.value.integer
                results.captured_data[results.capture_index] = value
                if results.capture_index < 10:
                    dut._log.info(f"Time={cocotb.utils.get_sim_time('ns')} Captured 8-bit bin[{results.capture_index}] = {value}")
                else:
                    dut._log.info(f"Time={cocotb.utils.get_sim_time('ns')} Captured 4-bit bin[{results.capture_index}] = {value}")
                results.capture_index += 1
            
            if dut.uio_out.value.integer & 0x2:  # last_bin
                dut._log.info(f"\nCompleted bin output sequence at time {cocotb.utils.get_sim_time('ns')}")
                results.capture_index = 0
                results.test_count += 1
    
    # Start monitoring in parallel
    cocotb.start_soon(monitor_outputs())
    
    # End simulation
    await ClockCycles(dut.clk, 100)
    dut._log.info("Test completed")