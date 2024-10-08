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
                    "0123456789abcdef0123456789abcdef",
                    "12153524c0895e818484d609b1f05663",
                    "b2c284658937521200f3e30106d7cd0d",
                    "76d457ed462df78c7cfde9f9e33724c6",
                    "72aff7e5bbd272778932d61247ecdb8f",
                    "f4007ae8e2ca4ec52e58495cde8e28bd",
                    "b1ef62630573870ac03b228010642120",
                    "cb203e968983b81386bc380da9a7d653",
                    "81174a02d7563eae0effe91de7c572cf",
                    "e5730aca9e314c3c7968bdf2452e618a",
                    "3c20f378c48a128975c50deb5b0265b6",
                    "de7502bc150fdd2a85d79a0bb897be71",
                    "9dcc603b1d06333abf23327e0aaa4b15",
                    "312307622635fb4c4fa1559f47b9a18f",
                    "cfc4569fae7d945cadcbc05b44de3789",
                    "ebfec0d7a8c7fc514b212f96061d7f0c",
                    "bb825a771ef2ed3d090cdb12bf05007e",
                    "0fd28f1fe9ebf6d342d92f85bc148878",
                    "9ff2ae3f150caf2a2c156358c33f3886",
                    "7d3599fa937dbc2639961773d18bb4a3",
                    "afd8565f22290d447bf8fdf7e59b36cb"
                    ]
    plain_vectors = [ "0000000000000000",
                      "0123456789abcdef",
                      "06b97b0d46df998d",
                      "3b23f1761e8dcd3d",
                      "e2f784c5d513d2aa",
                      "793069f2e77696ce",
                      "96ab582db2a72665",
                      "557845aacecccc9d",
                      "359fdd6beaa62ad5",
                      "118449230509650a",
                      "20c4b341ec4b34d8",
                      "634bf9c6571513ae",
                      "42f2418527f2554f",
                      "78d99bf16c9c4bd9",
                      "7c6da9f8dbcd60b7",
                      "a4ae3249e8233ed0",
                      "e12ccec26457edc8",
                      "36e5816d1cd9e739",
                      "2dda595b248b4b49",
                      "c71a0c8ece2ff29c",
                      "9799a82fd9d292b3",
                      "f3091ae62d28db5a"]

    cipher_vectors = ["3decb2a0850cdba1",
                      "d6b824587f014fc2",
                      "1781b5f1c3e67ed6",
                      "0a627927d1851988",
                      "4679760eddeaf958",
                      "941b3206ae02a6b4",
                      "6de351f4a8298e8a",
                      "d0e2ef923639a1db",
                      "2d010099bde0561b",
                      "88f2cc4c878b421a",
                      "f8c86b412901382e",
                      "7f14c329952a97b0",
                      "4a433ca74398839b",
                      "dc43ccf2c1b46c61",
                      "dc61ef0623bab5ae",
                      "6241572ed45dabcf",
                      "4e95440bb4fe958f",
                      "35577dec2c738c1a",
                      "8f63a1ebaf904c64",
                      "f0b6d7b8f4abaecf",
                      "4ed64cbd98d969ae",
                    "52f537019e3613f8"]

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

    
