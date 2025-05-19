import tensorflow as tf
import numpy as np
import struct

W_SCALES = {
    "c0": [6, 6, 6,],
    "c1": [7, 7, ],
    "c2": [8, 7, 7, 8, 8, 8, 8, 7, 8, 8, ],
}

# 載入 INT8 權重
W = {
    "c0": np.load("kernels/conv2d_0int.npy").astype(np.int8),
    "c1": np.load("kernels/conv2d_1int.npy").astype(np.int8),
    "c2": np.load("kernels/conv2d_2int.npy").astype(np.int8),
}
# 轉成指定格式 [H,W,inC,outC]
for key in W:
    w = W[key]
    W[key] = w.transpose(1,2,3,0)

def load_mnist_images(filename):
    with open(filename, 'rb') as f:
        magic, num, rows, cols = struct.unpack('>IIII', f.read(16))
        assert magic == 2051
        return np.frombuffer(f.read(), dtype=np.uint8).reshape(num, 28, 28, 1)
def load_mnist_labels(filename):
    with open(filename, 'rb') as f:
        magic, num = struct.unpack('>II', f.read(8))
        assert magic == 2049
        return np.frombuffer(f.read(), dtype=np.uint8)

def quant_conv(x_int8, w_int8, w_scale):
    x = x_int8.astype(np.int32) 
    w = w_int8.astype(np.int32)
    
    # int32 卷積
    with tf.device('/CPU:0'):
        acc = tf.nn.conv2d(x, w, strides=1, padding="VALID")
    # per-channel scale
    acc = acc.numpy().astype(np.int32)
    #acc = acc >> 7
    #acc = acc << 7
    if w_scale==W_SCALES["c1"]:
        print("conv2d_2 input:")
        II = np.transpose(x[9997], (2, 0, 1)) # [inC, H, W]
        print(II)
        print(f"conv2d_2 weight shape: {w.shape}") # [H, W, inC, outC]
        print("conv2d_2 weight:")
        IW = np.transpose(w, (3, 2, 0, 1)) # [outC, inC, H, W]
        print(IW)
        print("conv2d_2 output:")
        OO = np.transpose(acc[9997], (2, 0, 1)) # [outC, H, W]
        print(OO)
        ch1 = II[0][0][1] * IW[0][0][0][0] + II[0][0][2] * IW[0][0][0][1] + II[0][0][3] * IW[0][0][0][2] +\
            II[0][1][1] * IW[0][0][1][0] + II[0][1][2] * IW[0][0][1][1] + II[0][1][3] * IW[0][0][1][2] +\
            II[0][2][1] * IW[0][0][2][0] + II[0][2][2] * IW[0][0][2][1] + II[0][2][3] * IW[0][0][2][2]
        ch2 = II[1][0][1] * IW[0][1][0][0] + II[1][0][2] * IW[0][1][0][1] + II[1][0][3] * IW[0][1][0][2] +\
            II[1][1][1] * IW[0][1][1][0] + II[1][1][2] * IW[0][1][1][1] + II[1][1][3] * IW[0][1][1][2] +\
            II[1][2][1] * IW[0][1][2][0] + II[1][2][2] * IW[0][1][2][1] + II[1][2][3] * IW[0][1][2][2]
        ch3 = II[2][0][1] * IW[0][2][0][0] + II[2][0][2] * IW[0][2][0][1] + II[2][0][3] * IW[0][2][0][2] +\
            II[2][1][1] * IW[0][2][1][0] + II[2][1][2] * IW[0][2][1][1] + II[2][1][3] * IW[0][2][1][2] +\
            II[2][2][1] * IW[0][2][2][0] + II[2][2][2] * IW[0][2][2][1] + II[2][2][3] * IW[0][2][2][2]
        mul = ch1 + ch2 + ch3
        print(f"\
ch1 = {II[0][0][1]} * {IW[0][0][0][0]}\t + {II[0][0][2]} * {IW[0][0][0][1]}\t + {II[0][0][3]} * {IW[0][0][0][2]} +\n\
      {II[0][1][1]} * {IW[0][0][1][0]}\t + {II[0][1][2]} * {IW[0][0][1][1]}\t + {II[0][1][3]} * {IW[0][0][1][2]} +\n\
      {II[0][2][1]} * {IW[0][0][2][0]}\t + {II[0][2][2]} * {IW[0][0][2][1]}\t + {II[0][2][3]} * {IW[0][0][2][2]}\n\
ch2 = {II[1][0][1]} * {IW[0][1][0][0]}\t + {II[1][0][2]} * {IW[0][1][0][1]}\t + {II[1][0][3]} * {IW[0][1][0][2]} +\n\
      {II[1][1][1]} * {IW[0][1][1][0]}\t + {II[1][1][2]} * {IW[0][1][1][1]}\t + {II[1][1][3]} * {IW[0][1][1][2]} +\n\
      {II[1][2][1]} * {IW[0][1][2][0]}\t + {II[1][2][2]} * {IW[0][1][2][1]}\t + {II[1][2][3]} * {IW[0][1][2][2]}\n\
ch3 = {II[2][0][1]} * {IW[0][2][0][0]}\t + {II[2][0][2]} * {IW[0][2][0][1]}\t + {II[2][0][3]} * {IW[0][2][0][2]} +\n\
      {II[2][1][1]} * {IW[0][2][1][0]}\t + {II[2][1][2]} * {IW[0][2][1][1]}\t + {II[2][1][3]} * {IW[0][2][1][2]} +\n\
      {II[2][2][1]} * {IW[0][2][2][0]}\t + {II[2][2][2]} * {IW[0][2][2][1]}\t + {II[2][2][3]} * {IW[0][2][2][2]}")
        print(f"mul = {mul}")
    for i in range(acc.shape[-1]):
        acc[...,i] = np.round(acc[...,i] >> w_scale[i])
    acc = np.where(acc > 127, 127, acc)
    acc = np.where(acc < -128, -128, acc)
    acc = acc.astype(np.int8)
    return acc

def run_inference(x):
    # print("Con2d_1 input l:")
    # for i in range(3):
        # for j in range(3):
            # print(x[9999][3+i][6+j][0], end=",")
    # print()
    # print("Con2d_1 input lb:")
    # for i in range(3):
        # for j in range(3):
            # print(x[9999][4+i][6+j][0], end=",")
    # print()
    # print("Con2d_1 input b:")
    # for i in range(3):
        # for j in range(3):
            # print(x[9999][5+i][7+j][0], end=",")
    # print()
    x = quant_conv(x, W["c0"], W_SCALES["c0"]) # first conv

    # print("Maxpooling input:")
    # y = np.transpose(x[9997], (2, 0, 1))
    # print(y)

    x = tf.nn.max_pool(x, ksize=3, strides=3, padding="VALID").numpy().astype(np.int8)
    # print("Con2d_2 input:")
    # y = np.transpose(x[9999], (2, 0, 1))
    # print(y, end=",")

    x = quant_conv(x, W["c1"], W_SCALES["c1"]) # second conv
    # Wprint("Con2d_2 output:")
    # y = np.transpose(x[9997], (2, 0, 1))
    # print(y)

    x = quant_conv(x, W["c2"], W_SCALES["c2"]) # third conv
    #gap = tf.reduce_sum(x.astype(np.float32), axis=[1,2])
    gap = tf.reduce_sum(x, axis=[1,2])
    return gap

def data_preprocess(x):
    x = x[:,3:23,3:23]
    x = np.where(x > 20, 1, 0)
    return x

if __name__ == "__main__":
    # 載入 MNIST 測試資料
    x_test = load_mnist_images("t10k-images.idx3-ubyte")
    y_test = load_mnist_labels("t10k-labels.idx1-ubyte")
    # 取出前 3 筆資料 並對輸入資料預處理
    x_test = data_preprocess(x_test)
    y_test = y_test
    # 模型推論
    logits = run_inference(x_test)
    # 比對預測結果
    pred = np.argmax(logits, axis=1)
    acc = np.mean(pred == y_test)
