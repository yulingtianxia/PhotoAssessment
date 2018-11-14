import coremltools

coreml_model = coremltools.converters.caffe.convert(
    ('models/EmotiW_VGG_S.caffemodel', 'models/deploy.prototxt'),
    image_input_names='data',
    class_labels='models/emotions.txt'
)
coreml_model.author = 'Gil Levi and Tal Hassner'
coreml_model.license = 'Unknown'
coreml_model.short_description = 'Emotion Recognition in the Wild via Convolutional Neural Networks and Mapped Binary Patterns'
coreml_model.input_description['data'] = 'An image with a face.'
coreml_model.output_description['prob'] = 'The probabilities for each emotion, for the given input.'
coreml_model.output_description['classLabel'] = 'The most likely type of emotion, for the given input.'

coreml_model.save('models/CNNEmotions.mlmodel')

# coreml_model_fp16 = coremltools.utils.convert_neural_network_weights_to_fp16(coreml_model)
# coreml_model_fp16.save('models/CNNEmotions_p16.mlmodel')
#
# coreml_model_quantized = coremltools.models.neural_network.quantization_utils.quantize_weights(coreml_model, 4)
# coreml_model_quantized.save('models/CNNEmotions_p4.mlmodel')

coreml_model_quantized = coremltools.models.neural_network.quantization_utils.quantize_weights(coreml_model, 2)
coreml_model_quantized.save('models/CNNEmotions_p2.mlmodel')