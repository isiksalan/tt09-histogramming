# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, Timer, FallingEdge

@cocotb.test()
async def test_histogram(dut):
    dut._log.info("Start")
    
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
    await ClockCycles(dut.clk, 10)
    
    # Helper function to write to a bin
    async def write_value(value):
        # Set write_enable and value
        dut.ui_in.value = (1 << 7) | (value & 0x3F)
        await ClockCycles(dut.clk, 1)
        # Clear write_enable
        dut.ui_in.value = 0
        await ClockCycles(dut.clk, 1)
    
    # Helper function to wait for output sequence
    async def wait_for_output_sequence():
        # Wait for ready to go low
        while dut.uio_out.value.integer & 0x04:
            await ClockCycles(dut.clk, 1)
        
        dut._log.info("Output sequence started")
        bin_values = []
        
        # Wait for valid to go high
        while not (dut.uio_out.value.integer & 0x10):
            await ClockCycles(dut.clk, 1)
        
        # Collect all bin values until last_bin
        while not (dut.uio_out.value.integer & 0x08):  # Last bin bit
            if dut.uio_out.value.integer & 0x10:  # Valid bit
                bin_values.append(dut.uo_out.value.integer)
            await ClockCycles(dut.clk, 1)
            
        dut._log.info(f"Collected bin values: {bin_values}")
        return bin_values
    
    # Test 1: Write to multiple odd values
    dut._log.info("Test 1: Writing to odd values")
    await write_value(5)  # Should go to bin 2
    await write_value(7)  # Should go to bin 3
    await write_value(3)  # Should go to bin 1
    await ClockCycles(dut.clk, 5)
    
    # Test 2: Write to even values (should be ignored)
    dut._log.info("Test 2: Writing even values (should be ignored)")
    await write_value(2)
    await write_value(4)
    await write_value(6)
    await ClockCycles(dut.clk, 5)
    
    # Test 3: Overflow a bin
    dut._log.info("Test 3: Overflow test")
    for _ in range(16):  # Write to bin 5 until overflow
        await write_value(5)
        await ClockCycles(dut.clk, 1)
    
    # Wait for and verify output sequence
    bin_values = await wait_for_output_sequence()
    
    # Wait for ready to go high again
    while not (dut.uio_out.value.integer & 0x04):
        await ClockCycles(dut.clk, 1)
    
    # Test 4: Write to edge cases
    dut._log.info("Test 4: Edge cases")
    await write_value(1)   # First odd value
    await write_value(63)  # Last odd value
    await ClockCycles(dut.clk, 5)
    
    # Test 5: Test enable
    dut._log.info("Test 5: Testing enable")
    dut.ena.value = 0
    await write_value(5)  # Should be ignored when disabled
    await ClockCycles(dut.clk, 5)
    dut.ena.value = 1
    
    # Final wait
    await ClockCycles(dut.clk, 100)
    dut._log.info("Test completed")