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
    
    # Helper function to capture all bin values
    async def capture_bin_values():
        bin_values = []
        timeout = 1000
        count = 0
        
        while count < timeout:
            await RisingEdge(dut.clk)
            if dut.uio_out.value.integer & 0x1:  # valid_out is high
                bin_values.append(dut.uo_out.value.integer)
            if dut.uio_out.value.integer & 0x2:  # last_bin is high
                break
            count += 1
        
        return bin_values
    
    # Helper function to write data to histogram
    async def write_to_bin(bin_value, count):
        success_count = 0
        for i in range(count):
            # Wait for ready with timeout
            ready_timeout = 1000
            for _ in range(ready_timeout):
                await RisingEdge(dut.clk)
                if dut.uio_out.value.integer & 0x4:  # ready bit
                    break
            else:
                dut._log.error(f"Failed at write {i} to bin {bin_value} after {success_count} successful writes")
                assert False, f"Ready signal not detected after {ready_timeout} cycles"

            # Write data
            dut.ui_in.value = (1 << 7) | (bin_value & 0x3F)  # write_en and bin value
            dut.uio_in.value = 0  # Lower bits
            await RisingEdge(dut.clk)
            
            # Clear write_en
            dut.ui_in.value = bin_value & 0x3F
            await RisingEdge(dut.clk)
            
            success_count += 1
            
            # Wait for any output sequence to complete
            while (dut.uio_out.value.integer & 0x1):  # valid_out high
                await RisingEdge(dut.clk)
    
    # Test Case 1: Fill an 8-bit bin (bin 5) until overflow
    dut._log.info("Test Case 1: Filling 8-bit bin 5 until overflow")
    await write_to_bin(5, 256)
    bin_values = await capture_bin_values()
    assert len(bin_values) > 5, "Not enough bins captured"
    assert bin_values[5] == 255, f"Bin 5 should be 255, got {bin_values[5]}"
    for i in range(10):
        if i != 5:
            assert bin_values[i] == 0, f"Bin {i} should be 0, got {bin_values[i]}"
    
    # Test Case 2: Fill a 4-bit bin (bin 15) until overflow
    dut._log.info("Test Case 2: Fill 4-bit bin 15 until overflow")
    await write_to_bin(15, 16)
    bin_values = await capture_bin_values()
    assert bin_values[15] == 15, f"Bin 15 should be 15 (4-bit max), got {bin_values[15]}"
    
    # Test Case 3: Test boundary between 8-bit and 4-bit regions
    dut._log.info("Test Case 3: Testing boundary")
    await write_to_bin(9, 100)   # Last 8-bit bin
    await write_to_bin(10, 10)   # First 4-bit bin
    bin_values = await capture_bin_values()
    assert bin_values[9] == 100, f"Last 8-bit bin should be 100, got {bin_values[9]}"
    assert bin_values[10] == 10, f"First 4-bit bin should be 10, got {bin_values[10]}"
    
    # Test Case 4: Random pattern test across both regions
    dut._log.info("Test Case 4: Random pattern test")
    for i in range(10):
        await write_to_bin(i, 50)  # Write 50 counts to 8-bit bins
    for i in range(10, 20):
        await write_to_bin(i, 10)  # Write 10 counts to some 4-bit bins
    bin_values = await capture_bin_values()
    for i in range(10):
        assert bin_values[i] == 50, f"8-bit bin {i} should be 50, got {bin_values[i]}"
    for i in range(10, 20):
        assert bin_values[i] == 10, f"4-bit bin {i} should be 10, got {bin_values[i]}"
    
    # Test Case 5: Edge case testing
    dut._log.info("Test Case 5: Edge case testing")
    test_values = [(0, 10), (9, 10), (10, 10), (63, 10)]
    for bin_idx, count in test_values:
        await write_to_bin(bin_idx, count)
    bin_values = await capture_bin_values()
    for bin_idx, expected_count in test_values:
        assert bin_values[bin_idx] == expected_count, \
               f"Bin {bin_idx} should be {expected_count}, got {bin_values[bin_idx]}"
    
    # Final wait
    await ClockCycles(dut.clk, 100)
    dut._log.info("Test completed successfully")