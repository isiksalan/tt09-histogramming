# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
from cocotb.triggers import RisingEdge

class HistogramResults:
    def __init__(self):
        self.data_out = []
        self.valid_out = False
        self.last_bin = False
        
    def clear(self):
        self.data_out = []
        self.valid_out = False
        self.last_bin = False

@cocotb.test()
async def test_histogram(dut):
    dut._log.info("Start of histogram test")
    
    results = HistogramResults()
    
    # Create a 10us period clock (100KHz)
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())
    
    # Reset
    dut._log.info("Applying reset")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)  # Additional cycles after reset
    
    # Helper function to write data to histogram
    async def write_data(data, write_en=1):
        """ Write data to the histogram module, with optional write enable control. """
        dut.ui_in.value = 0  # Clear ui_in first to avoid any glitches
        await ClockCycles(dut.clk, 1)
        
        # Set data and write enable
        dut.ui_in.value = (write_en << 7) | ((data >> 8) & 0x7F)  # High bits for ui_in
        dut.uio_in.value = data & 0xFF                            # Low bits for uio_in
        await ClockCycles(dut.clk, 2)  # Keep stable for two cycles

    # Helper function to capture output sequence
    async def capture_output_sequence():
        """ Capture and verify the output sequence until last_bin is set or timeout occurs. """
        results.clear()
        timeout = 5000  # Extended timeout if sequence takes longer
        counter = 0

        await ClockCycles(dut.clk, 10)  # Initial delay to process writes
        
        while counter < timeout:
            await RisingEdge(dut.clk)
            data_value = dut.uo_out.value.integer
            
            # Check if valid_out is set
            if dut.uio_out.value.integer & 0x1:
                results.data_out.append(data_value)
                results.valid_out = True
            
            # Check if last_bin is set
            if dut.uio_out.value.integer & 0x2:
                results.last_bin = True
                break  # Stop capture once last_bin is detected
                
            counter += 1
        
        # Print captured data for debugging
        dut._log.info(f"Captured data sequence: {results.data_out}")
        return results.data_out

    # Test Case 1: Fill an 8-bit bin (bin 5) until overflow
    dut._log.info("Test Case 1: Filling 8-bit bin 5 until overflow")
    for _ in range(256):  # Should trigger at 255
        await write_data(5)
    
    output_data = await capture_output_sequence()
    
    # Debugging statement to see the captured output
    dut._log.info(f"Output data captured: {output_data}")

    # Verify bin 5 reached maximum value (255)
    assert output_data[5] == 255, f"Bin 5 should be 255, got {output_data[5]}"
    # Verify other 8-bit bins are 0
    for i in range(10):
        if i != 5:
            assert output_data[i] == 0, f"Bin {i} should be 0, got {output_data[i]}"
    print("Key Test Case 1 - Bin 5:")
    print(f"Expected: 255")
    print(f"Got: {output_data[5]}")
    
    # Test Case 2: Fill a 4-bit bin (bin 15) until overflow
    dut._log.info("Test Case 2: Fill 4-bit bin 15 until overflow")
    for _ in range(16):  # Should trigger at 15
        await write_data(15)
    
    output_data = await capture_output_sequence()
    
    # Debugging statement to see the captured output
    dut._log.info(f"Output data captured: {output_data}")

    # Verify bin 15 reached maximum value (15 for 4-bit)
    assert output_data[15] == 15, f"Bin 15 should be 15 (4-bit max), got {output_data[15]}"
    print("Key Test Case 2 - Bin 15:")
    print(f"Expected: 15")
    print(f"Got: {output_data[15]}")
    
    # Test Case 3: Test boundary between 8-bit and 4-bit regions
    dut._log.info("Test Case 3: Testing boundary between 8-bit and 4-bit regions")
    # Write to last 8-bit bin (bin 9)
    for _ in range(100):
        await write_data(9)
    # Write to first 4-bit bin (bin 10)
    for _ in range(10):
        await write_data(10)
    
    output_data = await capture_output_sequence()
    
    # Debugging statement to see the captured output
    dut._log.info(f"Output data captured: {output_data}")

    # Verify boundary conditions
    assert output_data[9] == 100, f"Last 8-bit bin should be 100, got {output_data[9]}"
    assert output_data[10] == 10, f"First 4-bit bin should be 10, got {output_data[10]}"
    print("Key Test Case 3 - Boundary:")
    print(f"Expected: Bin 9 = 100, Bin 10 = 10")
    print(f"Got: Bin 9 = {output_data[9]}, Bin 10 = {output_data[10]}")
    
    # Test Case 4: Edge case testing
    dut._log.info("Test Case 4: Edge case testing")
    test_values = [
        (0, 10),   # First bin
        (9, 10),   # Last 8-bit bin
        (10, 10),  # First 4-bit bin
        (63, 10)   # Last bin
    ]
    
    for bin_idx, count in test_values:
        for _ in range(count):
            await write_data(bin_idx)
    
    output_data = await capture_output_sequence()
    
    # Debugging statement to see the captured output
    dut._log.info(f"Output data captured: {output_data}")

    # Verify all edge cases
    for bin_idx, expected_count in test_values:
        assert output_data[bin_idx] == expected_count, \
            f"Bin {bin_idx} should be {expected_count}, got {output_data[bin_idx]}"
        print(f"Key Test Case 4 - Bin {bin_idx}:")
        print(f"Expected: {expected_count}")
        print(f"Got: {output_data[bin_idx]}")
    
    # Test Case 5: Write enable functionality
    dut._log.info("Test Case 5: Testing write_en functionality")
    # Get current value of bin 5
    initial_value = output_data[5]
    # Try to write with write_en=0
    await write_data(5, write_en=0)
    output_data = await capture_output_sequence()
    
    # Debugging statement to see the captured output
    dut._log.info(f"Output data captured after write_en=0: {output_data}")

    # Verify value didn't change
    assert output_data[5] == initial_value, \
        f"Bin 5 should not change when write_en=0, expected {initial_value}, got {output_data[5]}"
    print("Key Test Case 5 - Write Enable:")
    print(f"Expected: No change ({initial_value})")
    print(f"Got: {output_data[5]}")
    
    await ClockCycles(dut.clk, 100)
    dut._log.info("All tests completed successfully!")
