import tensorflow as tf
from keras import layers
import tensorflow_model_optimization as tfmot
import numpy as np
# 1. 載入並前處理 MNIST 資料集

(x_train, y_train), (x_test, y_test) = tf.keras.datasets.mnist.load_data()

# 先把 shape 從 (60000, 28, 28) → (60000, 22, 22)（去掉邊緣）
x_train = x_train[:, 3:25, 3:25]
x_test = x_test[:, 3:25, 3:25]
#x_train = x_train.astype("float32") / 255.0
#x_train = (x_train - 0.5) * 2
x_train = np.where(x_train > 20, 1, 0)
#x_train = np.clip(x_train*127, -128, 127)
#x_test = x_test.astype("float32") / 255.0

#x_test = (x_test - 0.5) * 2
x_test = np.where(x_test > 20, 1, 0)
#x_test = np.clip(x_test*127, -128, 127)
# 再 reshape 成帶 channel 的形狀
x_train = x_train.reshape(-1, 22, 22, 1).astype("float32")
x_test = x_test.reshape(-1, 22, 22, 1).astype("float32")

# 2. 定義 MLP 模型
#def build_mnist_model():
#    model = tf.keras.Sequential([
#        layers.Input(shape=(784,)),
#        layers.Dense(3, activation='relu',use_bias= False),
#        layers.Dense(10 ,use_bias= False)
#    ])
#    return model

def build_mnist_model():
    #initializer = tf.keras.initializers.he_normal()
    model = tf.keras.Sequential([
        layers.Input(shape=(22, 22, 1)),
        # 使用小型卷積層
        layers.Conv2D(3, kernel_size=(3, 3), use_bias=False),
        #layers.Conv2D(2, kernel_size=(3, 3), use_bias=False),
        layers.MaxPooling2D(pool_size=(3, 3)),
        layers.Conv2D(2, kernel_size=(3, 3), use_bias=False),
        #layers.Conv2D(3, kernel_size=(2, 2), use_bias=False, kernel_initializer=initializer),
        # 增加卷積層通道數至10（對應10個類別）
        layers.Conv2D(10, kernel_size=(2, 2),use_bias=False),
        # 全局平均池化直接將每個特徵圖降為一個值
        layers.GlobalAveragePooling2D()
        # 注意：不需要Flatten和Dense層
    ])
    return model

# 3. 訓練 float model
float_model = build_mnist_model()
float_model.compile(optimizer='adam',
                    loss=tf.keras.losses.SparseCategoricalCrossentropy(from_logits=True),
                    metrics=['accuracy'])
float_model.fit(x_train, y_train, validation_data=(x_test, y_test), epochs=7)
float_model.summary()

float_model.save("mnist_conv_spilt.h5")
print("已成功儲存 mnist_conv_spilt.h5")

# 4. 準備 QAT 模型
print("start QAT")
annotated_model = tfmot.quantization.keras.quantize_annotate_model(float_model)
qat_model = tfmot.quantization.keras.quantize_apply(annotated_model)

qat_model.compile(optimizer=tf.keras.optimizers.Adam(learning_rate=1e-3),
                  loss=tf.keras.losses.SparseCategoricalCrossentropy(from_logits=True),
                  metrics=['accuracy'])
qat_model.fit(x_train, y_train, validation_data=(x_test, y_test), epochs=5)



# 5. 建立代表性資料集生成器
def representative_data_gen():
    for i in range(100):
        yield [x_train[i:i+1]]

# 6. 匯出為量化的 TFLite 模型
converter = tf.lite.TFLiteConverter.from_keras_model(qat_model)
converter.optimizations = [tf.lite.Optimize.DEFAULT]
converter.representative_dataset = representative_data_gen
converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS_INT8]
converter.inference_input_type = tf.int8
converter.inference_output_type = tf.int8
converter.inference_input_type = tf.int8
converter.inference_output_type = tf.int8

converter._experimental_quantize_input_output = True


tflite_model = converter.convert()

with open("mnist_conv_spilt.tflite", "wb") as f:
    f.write(tflite_model)

print(" 已成功儲存 mnist_conv_spilt.tflite")

# 讀取 tflite 模型
interpreter = tf.lite.Interpreter(model_path="mnist_conv_spilt.tflite")
interpreter.allocate_tensors()

# 取得所有 tensor 詳細資訊
tensor_details = interpreter.get_tensor_details()
print("=== 所有 tensor 名稱 ===")
for t in tensor_details:
    print(t['index'], t['name'], t['dtype'], t['shape'])

for tensor in tensor_details:
    name = tensor['name']
    quantization = tensor['quantization']  # (scale, zero_point)

    if quantization != (0.0, 0):  # 只列出有量化的
        print(f"Tensor Name: {name}")
        print(f"  Scale: {quantization[0]}")
        print(f"  Zero Point: {quantization[1]}")
        print()


import csv
csv_output_path = "quant_params.csv"
with open(csv_output_path, mode='w', newline='') as csv_file:
    writer = csv.writer(csv_file)
    writer.writerow(['Tensor Name', 'DType', 'Scale(s)', 'Zero Point(s)'])

    for tensor in tensor_details:
        name = tensor['name']
        dtype = tensor['dtype']
        quant_params = tensor['quantization_parameters']
        scales = quant_params['scales']
        zero_points = quant_params['zero_points']

        # 只匯出有量化參數的 tensor（通常是 int8）
        # 將 list 轉成字串寫入 CSV
        scale_str = ', '.join([str(s) for s in scales])
        zp_str = ', '.join([str(zp) for zp in zero_points])
        writer.writerow([name, str(dtype), scale_str, zp_str])

print(f"✅ 已將量化參數匯出至：{csv_output_path}")