import numpy as np
import struct


if __name__ == "__main__":
    kernelsfile = [
    "kernels/conv2d_0int",
    "kernels/conv2d_1int",
    "kernels/conv2d_2int"
    ]
    Ks = [
    np.load(f"{kernelsfile[0]}.npy").astype(np.int8),
    np.load(f"{kernelsfile[1]}.npy").astype(np.int8),
    np.load(f"{kernelsfile[2]}.npy").astype(np.int8)
    ] # shape = (OutputChannels, KernelHeight, KernelWidth, InputChannels)
    for i in range(len(Ks)):
        Ks[i] = np.transpose(Ks[i], (0, 3, 1, 2)) # shape = (OutputChannels, InputChannels, KernelHeight, KernelWidth)
        np.save(f"{kernelsfile[i]}_reshaped.npy", Ks[i])