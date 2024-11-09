# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, Timer
from cocotb.regression import TestFactory

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
    
    # Helper function to wait for ready or timeout
    async def wait_for_ready(timeout_cycles=1000):
        for _ in range(timeout_cycles):
            await RisingEdge(dut.clk)
            if dut.uio_out.value.integer & 0x4:  # Check ready
                return True
        return False
    
    # Helper function to write data to histogram
    async def write_to_bin(bin_value, count):
        for _ in range(count):
            if not await wait_for_ready():
                raise cocotb.result.TestFailure("Timeout waiting for ready")
                
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
            await RisingEdge(dut.clk)
    
    try:
        # Test Case 1: Fill an 8-bit bin (bin 5) until overflow
        dut._log.info("Test Case 1: Filling 8-bit bin 5 until overflow")
        await write_to_bin(5, 256)  # Should trigger at 255
        await ClockCycles(dut.clk, 100)
        
        # Test Case 2: Fill a 4-bit bin (bin 15) until overflow
        dut._log.info("Test Case 2: Fill 4-bit bin 15 until overflow")
        await write_to_bin(15, 16)  # Should trigger at 15
        await ClockCycles(dut.clk, 100)
        
        # Test Case 3: Test boundary between 8-bit and 4-bit regions
        dut._log.info("Test Case 3: Testing boundary")
        await write_to_bin(9, 100)   # Last 8-bit bin
        await write_to_bin(10, 10)   # First 4-bit bin
        await ClockCycles(dut.clk, 100)
        
        # Test Case 4: Random pattern test across both regions
        dut._log.info("Test Case 4: Random pattern test")
        # Test 8-bit bins
        for i in range(10):
            await write_to_bin(i, 50)  # Write 50 counts to 8-bit bins
        # Test 4-bit bins
        for i in range(10, 20):
            await write_to_bin(i, 10)  # Write 10 counts to some 4-bit bins
        await ClockCycles(dut.clk, 100)
        
        # Test Case 5: Edge case testing
        dut._log.info("Test Case 5: Edge case testing")
        await write_to_bin(0, 10)     # First bin
        await write_to_bin(9, 10)     # Last 8-bit bin
        await write_to_bin(10, 10)    # First 4-bit bin
        await write_to_bin(63, 10)    # Last bin
        await ClockCycles(dut.clk, 100)
        
        dut._log.info("Test completed successfully")
        
    except Exception as e:
        dut._log.error(f"Test failed with error: {str(e)}")
        raise
    
    # Final wait to ensure all operations complete
    await ClockCycles(dut.clk, 100)