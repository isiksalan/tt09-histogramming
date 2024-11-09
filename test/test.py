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
    await ClockCycles(dut.clk, 10)  # Wait longer after reset
    
    # Debug: Print initial state
    dut._log.info(f"Initial ready state: {dut.uio_out.value.integer}")
    
    # Helper function to wait for ready or timeout
    async def wait_for_ready(timeout_cycles=5000):  # Increased timeout
        for i in range(timeout_cycles):
            await RisingEdge(dut.clk)
            if (i % 100) == 0:  # Debug print every 100 cycles
                dut._log.info(f"Cycle {i}: uio_out = {dut.uio_out.value.integer:08b}")
            ready_bit = (dut.uio_out.value.integer)  # No bit masking yet, let's see raw value
            if ready_bit:
                dut._log.info(f"Ready detected at cycle {i}")
                return True
        return False
    
    # Helper function to write data to histogram
    async def write_to_bin(bin_value, count):
        dut._log.info(f"Starting write_to_bin for bin {bin_value}, count {count}")
        for i in range(count):
            # Debug print every 10 writes
            if (i % 10) == 0:
                dut._log.info(f"Write {i} to bin {bin_value}")
            
            # Wait for ready with debug info
            ready = await wait_for_ready()
            if not ready:
                dut._log.error(f"Timeout on write {i} to bin {bin_value}")
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
            dut.ui_in.value = 0  # Clear all control bits
            dut.uio_in.value = 0
            await RisingEdge(dut.clk)
            
            # Debug: Print state after write
            if (i % 10) == 0:
                dut._log.info(f"After write {i}: uio_out = {dut.uio_out.value.integer:08b}")
    
    try:
        # Test Case 1 with debugging
        dut._log.info("Test Case 1: Filling 8-bit bin 5 until overflow")
        await write_to_bin(5, 10)  # Start with just 10 writes to debug
        dut._log.info("Test Case 1 completed")
        await ClockCycles(dut.clk, 100)
        
    except Exception as e:
        dut._log.error(f"Test failed with error: {str(e)}")
        raise
    
    # Final wait
    await ClockCycles(dut.clk, 100)