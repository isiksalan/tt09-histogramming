
# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

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
    
    # Helper function to write a value
    async def write_value(value):
        dut.ui_in.value = (1 << 7) | (value & 0x3F)
        await ClockCycles(dut.clk, 1)
        dut.ui_in.value = 0
        await ClockCycles(dut.clk, 1)
    
    # Helper function for output sequence
    async def wait_for_output():
        while (dut.uio_out.value.integer & 0x04):  # Wait for ready low
            await ClockCycles(dut.clk, 1)
        
        outputs = []
        while not (dut.uio_out.value.integer & 0x08):  # Until last_bin
            if (dut.uio_out.value.integer & 0x10):  # If valid
                outputs.append(dut.uo_out.value.integer)
            await ClockCycles(dut.clk, 1)
        
        dut._log.info(f"Outputs: {outputs}")
        return outputs

    # Test 1: Write odd and even numbers
    dut._log.info("Test 1: Basic odd/even test")
    await write_value(3)    # Should be counted
    await write_value(4)    # Should be ignored
    await write_value(5)    # Should be counted
    
    # Test 2: Overflow test
    dut._log.info("Test 2: Overflow test")
    for _ in range(15):    # Fill bin 5 until overflow
        await write_value(5)
    
    # Get and verify outputs
    outputs = await wait_for_output()
    
    # Wait for ready
    while not (dut.uio_out.value.integer & 0x04):
        await ClockCycles(dut.clk, 1)
    
    # Test 3: Enable test
    dut._log.info("Test 3: Enable test")
    dut.ena.value = 0
    await write_value(3)    # Should be ignored when disabled
    dut.ena.value = 1
    
    await ClockCycles(dut.clk, 100)
    dut._log.info("Test completed")
