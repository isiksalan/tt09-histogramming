# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
from cocotb.triggers import RisingEdge

def hex_to_bits(hex_constant):
    binary_string = bin(int(hex_constant, 16))[2:]
    binary_string = binary_string.zfill(len(hex_constant) * 4)
    for bit in binary_string:
        yield int(bit)

class ShiftRegister64:
    def __init__(self):
        self.register = [0] * 64

    def shift_left(self, new_bit=0):
        if new_bit not in [0, 1]:
            raise ValueError("new_bit must be 0 or 1")
        self.register = self.register[1:] + [new_bit]

    def shift_right(self, new_bit=0):
        if new_bit not in [0, 1]:
            raise ValueError("new_bit must be 0 or 1")
        self.register = [new_bit] + self.register[:-1]

    def get_value(self):
        return int("".join(map(str, self.register)), 2)

    def __str__(self):
        return "".join(map(str, self.register))

@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

    store_result_reg = ShiftRegister64()

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())
    
    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    
    key_vectors = [ "00000000000000000000000000000000",
                    "00000000000000000000000000000000",
                    "00000000000000000000000000000000",
                    "00000000000000000000000000000000",
                    "00000000000000000000000000000000",
                    "00000000000000000000000000000000",
                    "00000000000000000000000000000000",
                    "00000000000000000000000000000000",
                    "00000000000000000000000000000000",
                    "00000000000000000000000000000000",
                    "00000000000000000000000000000000",
                    "00000000000000000000000000000000",
                    "00000000000000000000000000000000",
                    "00000000000000000000000000000000",
                    "00000000000000000000000000000000",
                    "00000000000000000000000000000000",
                    "00000000000000000000000000000000",
                    "00000000000000000000000000000000",
                    "00000000000000000000000000000000",
                    "00000000000000000000000000000000",
                    "00000000000000000000000000000000",
                    "00000000000000000000000000000000"
                    ]
    plain_vectors = [ "0000000000000000",
                      "0123456789abcdef",
                      "12153524c0895e81",
                      "8484d609b1f05663",
                      "06b97b0d46df998d",
                      "b2c2846589375212",
                      "00f3e30106d7cd0d",
                      "3b23f1761e8dcd3d",
                      "76d457ed462df78c",
                      "7cfde9f9e33724c6",
                      "e2f784c5d513d2aa",
                      "72aff7e5bbd27277",
                      "8932d61247ecdb8f",
                      "793069f2e77696ce",
                      "f4007ae8e2ca4ec5",
                      "2e58495cde8e28bd",
                      "96ab582db2a72665",
                      "b1ef62630573870a",
                      "c03b228010642120",
                      "557845aacecccc9d",
                      "cb203e968983b813",
                      "86bc380da9a7d653"]

    cipher_vectors = ["3decb2a0850cdba1",
                      "da261393c73be9ce",
                      "29db5fe262572f4e",
                      "a58bcbceb726f210",
                      "19bfe686099fe7fa",
                      "eb06fdd69c4dddf4",
                      "7b7ce8a1efea53e7",
                      "cd9d69d3429b7991",
                      "f52fac312b2611ba",
                      "4298653a31c425a0",
                      "8a3f43d852728672",
                      "ad8a4dbd629df00f",
                      "8ddf481dd666cd19",
                      "1621a0b4c308d2c3",
                      "0f129144c1f2aa19",
                      "89816d9688fd485a",
                      "737817fb01526e1f",
                      "43721b5b4edde754",
                      "63e2323b3084a74a",
                      "9de67e7a1325a1df",
                      "12b0145845f2da84",
                      "cbe4f5ec505ad9ee"]
    
    start   = 0
    getct   = 0
    loadkey = 0
    loadpt  = 0
    keyi    = 0
    datai   = 0
    dut.ui_in.value = ((start<<5) + (getct<<4) + (loadkey<<3) + (loadpt<<2) + (keyi<<1) + datai)
    dut._log.info("Test project behavior")
    await ClockCycles(dut.clk, 1)

    for (key, pt, ct) in zip(key_vectors, plain_vectors, cipher_vectors):
        await ClockCycles(dut.clk, 2)
    
        start   = 0
        getct   = 0
        loadkey = 0
        loadpt  = 0
        keyi    = 0
        datai   = 0
        dut.ui_in.value = ((start<<5) + (getct<<4) + (loadkey<<3) + (loadpt<<2) + (keyi<<1) + datai)
        await ClockCycles(dut.clk, 2)
        
        # load pt
        for bit in hex_to_bits(pt):
            loadpt  = 1
            datai   = bit
            dut.ui_in.value = ((start<<5) + (getct<<4) + (loadkey<<3) + (loadpt<<2) + (keyi<<1) + datai)
            await ClockCycles(dut.clk, 1)
        datai = 0
        loadpt = 0
        
        # load key
        for bit in hex_to_bits(key):
            loadkey = 1
            keyi    = bit
            dut.ui_in.value = ((start<<5) + (getct<<4) + (loadkey<<3) + (loadpt<<2) + (keyi<<1) + datai)
            await ClockCycles(dut.clk, 1)
        keyi = 0
        loadkey = 0

        dut.ui_in.value = ((start<<5) + (getct<<4) + (loadkey<<3) + (loadpt<<2) + (keyi<<1) + datai)
        await ClockCycles(dut.clk, 1)

        # start encryption
        start = 1
        dut.ui_in.value = ((start<<5) + (getct<<4) + (loadkey<<3) + (loadpt<<2) + (keyi<<1) + datai)
        await ClockCycles(dut.clk, 1)
        start = 0
        dut.ui_in.value = ((start<<5) + (getct<<4) + (loadkey<<3) + (loadpt<<2) + (keyi<<1) + datai)
        await ClockCycles(dut.clk, 5)
        
        # wait for done
        while (((dut.uo_out.value.integer >> 1) & 1) == 0):
           await ClockCycles(dut.clk, 1)

        # read ct
        getct   = 1
        dut.ui_in.value = ((start<<5) + (getct<<4) + (loadkey<<3) + (loadpt<<2) + (keyi<<1) + datai)
        for i in range(64):
            await RisingEdge(dut.clk)
            store_result_reg.shift_left(dut.uo_out.value.integer & 1)
                
        print("Key ", key)
        print("PT  ", pt)
        print("CT  ", ct)
        print("OUT ", hex(store_result_reg.get_value()))
        assert(store_result_reg.get_value() == int(ct, 16))

        await ClockCycles(dut.clk, 2)

    
