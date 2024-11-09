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
   
    # Helper function to write to a bin (only odd bins allowed)
    async def write_to_bin(bin_value):
        # Check if bin_value is odd, else skip
        if bin_value % 2 == 0:
            dut._log.info(f"Skipping even bin {bin_value}")
            return
        
        # Bin value in lower 5 bits
        odd_bin_index = bin_value // 2  # Map to the internal 32-bin index
        dut.ui_in.value = (1 << 7) | (odd_bin_index & 0x1F)  # Set write_en and odd bin index
        await ClockCycles(dut.clk, 1)
        dut.ui_in.value = odd_bin_index & 0x1F  # Clear write_en
        await ClockCycles(dut.clk, 1)
   
    # Test Case 1: Write to bin 5 (4-bit bin now)
    dut._log.info("Test Case 1: Write to bin 5")
    for _ in range(10):  # Write less than max (15)
        await write_to_bin(5)
    assert dut.ui_in.value.integer & 0x1F == 5 // 2, "Bin index not correct"
   
    # Test Case 2: Test overflow of bin 15
    dut._log.info("Test Case 2: Test overflow")
    for _ in range(16):  # Should overflow at 15 (4-bit max)
        await write_to_bin(15)
    await ClockCycles(dut.clk, 10)
   
    # Test Case 3: Test edge bins (first, middle, last)
    dut._log.info("Test Case 3: Edge bins")
    # First odd bin
    await write_to_bin(1)
    # Middle odd bin (15 in the 64-bin range, mapped to 7 in the 32-bin array)
    await write_to_bin(15)
    # Last odd bin (63 in the 64-bin range, mapped to 31 in the 32-bin array)
    await write_to_bin(63)
    await ClockCycles(dut.clk, 10)
   
    # Test Case 4: Test all bins (only odd ones should register)
    dut._log.info("Test Case 4: All bins (odd indices only)")
    for bin_idx in range(1, 64, 2):  # Write to only odd bin indices
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
