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
    acc = acc >> 7
    acc = acc << 7

    for i in range(acc.shape[-1]):
        acc[...,i] = np.round(acc[...,i] >> w_scale[i])
    acc = np.where(acc > 127, 127, acc)
    acc = np.where(acc < -128, -128, acc)
    acc = acc.astype(np.int8)
    return acc

def run_inference(x):
    x = quant_conv(x, W["c0"], W_SCALES["c0"]) # first conv
    x = x.astype(np.int32)
    x = tf.nn.max_pool(x, ksize=3, strides=3, padding="VALID").numpy().astype(np.int8)
    x = quant_conv(x, W["c1"], W_SCALES["c1"]) # second conv
    x = quant_conv(x, W["c2"], W_SCALES["c2"]) # third conv
    gap = tf.reduce_mean(x.astype(np.float32), axis=[1,2])
    
    return gap

def data_preprocess(x):
    if x.ndim == 3: # for single image inference
        x = np.expand_dims(x, axis=0)
    x = x[:,3:23,3:23].astype(np.float32)
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
    # 顯示比對結果與準確度
    #for i in range(len(x_test)):
    #    result = "✔️ 正確" if pred[i] == y_test[i] else "❌ 錯誤"
    #    print(f"Index {i:4d}: Label = {y_test[i]} | Predict = {pred[i]} → {result}")
    print(f"INT8 模型準確率: {acc*100:.2f}%")
