<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

tt09-led-serial is a nibble-serial implementation of the LED block cipher, proposed in 2012 and defined in [The LED Block Cipher](https://eprint.iacr.org/2012/600.pdf) by J. Guo et. al. The cipher encrypts a 64-bit block of plaintext with a 128-bit key into a 64-bit block of ciphertext. The nibble-serial implementation enables a very compact implementation as most of the datapath logic can be reused over each nibble. The downside is that such nibble-serial implementations have a much larger latency. The nibble-serial architecture 


## How to test

You give it a clock and it runs, and you can watch the output bits.

## External hardware

No external hardware requirements.
