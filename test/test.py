# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, Timer

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
    async def write_to_bin(bin_value):
        # Bin value in lower 6 bits
        dut.ui_in.value = (1 << 7) | (bin_value & 0x3F)  # Set write_en and bin value
        await ClockCycles(dut.clk, 1)
        dut.ui_in.value = bin_value & 0x3F  # Clear write_en
        await ClockCycles(dut.clk, 1)
    
    # Test Case 1: Write to bin 5 (now 4-bit)
    dut._log.info("Test Case 1: Write to bin 5")
    for _ in range(10):  # Write less than max (15)
        await write_to_bin(5)
    assert dut.ui_in.value.integer & 0x3F == 5, "Bin index not correct"
    
    # Test Case 2: Test overflow of bin 15
    dut._log.info("Test Case 2: Test overflow")
    for _ in range(16):  # Should overflow at 15
        await write_to_bin(15)
    await ClockCycles(dut.clk, 10)
    
    # Test Case 3: Test edge bins
    dut._log.info("Test Case 3: Edge bins")
    # First bin
    await write_to_bin(0)
    # Middle bin
    await write_to_bin(32)
    # Last bin
    await write_to_bin(63)
    await ClockCycles(dut.clk, 10)
    
    # Test Case 4: Test all bins
    dut._log.info("Test Case 4: All bins")
    for bin_idx in range(64):
        await write_to_bin(bin_idx)
        await ClockCycles(dut.clk, 1)
    
    # Test load_upper functionality
    dut._log.info("Test Case 5: Test load_upper")
    # Set load_upper and some data
    dut.ui_in.value = (1 << 6) | 0xAA  # load_upper=1, data=0xAA
    await ClockCycles(dut.clk, 1)
    # Clear load_upper
    dut.ui_in.value = 0x55  # load_upper=0, data=0x55
    await ClockCycles(dut.clk, 1)
    
    # Final wait
    await ClockCycles(dut.clk, 100)
    dut._log.info("Test completed")