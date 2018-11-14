import coremltools
from coremltools.models import _MLMODEL_FULL_PRECISION


coreml_model = coremltools.converters.keras.convert('models/nasnet.h5',
                                                    'image',
                                                    'scores',
                                                    'image',
                                                    model_precision=_MLMODEL_FULL_PRECISION)
coreml_model.author = 'Hossein Talebi, Peyman Milanfar'
coreml_model.short_description = 'Automatically learned quality assessment for images has recently become a hot topic due to its usefulness in a wide variety of applications such as evaluating image capture pipelines, storage techniques and sharing media. Despite the subjective nature of this problem, most existing methods only predict the mean opinion score provided by datasets such as AVA [1] and TID2013 [2]. Our approach differs from others in that we predict the distribution of human opinion scores using a convolutional neural network. Our architecture also has the advantage of being significantly simpler than other methods with comparable performance. Our proposed approach relies on the success (and retraining) of proven, state-of-the-art deep object recognition networks. Our resulting network can be used to not only score images reliably and with high correlation to human perception, but also to assist with adaptation and optimization of photo editing/enhancement algorithms in a photographic pipeline. All this is done without need for a "golden" reference image, consequently allowing for single-image, semantic- and perceptually-aware, no-reference quality assessment.'
coreml_model.license = 'Unknown'
coreml_model.save('models/NIMANasnet.mlmodel')

coreml_model_quantized = coremltools.models.neural_network.quantization_utils.quantize_weights(coreml_model, 8)
coreml_model_quantized.save('models/NIMANasnet_p8.mlmodel')
