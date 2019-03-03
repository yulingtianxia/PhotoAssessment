//
//  PhotoMPSProcessor.swift
//  PhotoAssessment
//
//  Created by 杨萧玉 on 2018/11/17.
//  Copyright © 2018 杨萧玉. All rights reserved.
//

#if os(iOS) || os(watchOS) || os(tvOS)
import UIKit
#elseif os(macOS)
import Cocoa
#endif
import MetalPerformanceShaders

public typealias Fingerprint = [UInt32: Double]

@available(iOS 11.0, macOS 10.13, tvOS 11.0, *)
open class PhotoMPSProcessor: NSObject {
    
    private let device: MTLDevice?
    private let commandQueue: MTLCommandQueue?
    private let saturationPipelineState: MTLComputePipelineState?
    private let fingerprintPipelineState: MTLComputePipelineState?
    private let cosinePipelineState: MTLComputePipelineState?
    
    public override init() {
        
        // Load default device.
        device = MTLCreateSystemDefaultDevice()

        // Create new command queue.
        commandQueue = device?.makeCommandQueue()
        
        if let device = device {
            let rgb2hsv = device.supportNonuniformThreadgroupSize() ? "rgb2hsvKernelNonuniform" : "rgb2hsvKernel"
            saturationPipelineState = makePipelineState(device: device, functionName: rgb2hsv)
            
            let fingerprint = device.supportNonuniformThreadgroupSize() ? "fingerprintKernelNonuniform" : "fingerprintKernel"
            fingerprintPipelineState = makePipelineState(device: device, functionName: fingerprint)
            let cosine = device.supportNonuniformThreadgroupSize() ? "cosineKernelNonuniform" : "cosineKernel"
            cosinePipelineState = makePipelineState(device: device, functionName: cosine)
        }
        else {
            saturationPipelineState = nil
            fingerprintPipelineState = nil
            cosinePipelineState = nil
        }
        
        super.init()
    }
    
    /// Downsample image
    ///
    /// - Parameters:
    ///   - imagePixels: image pixels with rgba8 format
    ///   - width: image width
    ///   - height: image height
    ///   - scaleDimension: scale dimension
    ///   - block: completion block
    @objc public func downsample(imagePixels: [UInt32], width: Int, height: Int, scaleDimension: Int, completionHandler block: @escaping ([UInt32]?) -> Void) {
        
        // Make sure the current device supports MetalPerformanceShaders.
        guard let device = device, MPSSupportsMTLDevice(device) else {
            print("Metal Performance Shaders not Supported on current Device")
            block(nil)
            return
        }
        
        var pixels = imagePixels
        // TextureDescriptors
        let scaleSrcTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: width, height: height, mipmapped: false)
        scaleSrcTextureDescriptor.usage = [.shaderRead]
        
        let scalaDesTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: scaleDimension, height: scaleDimension, mipmapped: false)
        scalaDesTextureDescriptor.usage = [.shaderWrite, .shaderRead]
        
        // Textures
        guard let scaleSrcTexture: MTLTexture = device.makeTexture(descriptor: scaleSrcTextureDescriptor) else {
            block(nil)
            return
        }
        
        guard let scaleDesTexture: MTLTexture = device.makeTexture(descriptor: scalaDesTextureDescriptor) else {
            block(nil)
            return
        }
        
        // Fill scaleSrcTexture with pixels
        let scaleRegion = MTLRegionMake2D(0, 0, width, height)
        scaleSrcTexture.replace(region: scaleRegion, mipmapLevel: 0, withBytes: &pixels, bytesPerRow: 4 * width)
        
        // Run Image Filters
        guard let commandBuffer = commandQueue?.makeCommandBuffer() else {
            block(nil)
            return
        }
        
        let scale = MPSImageBilinearScale(device: device)
        scale.encode(commandBuffer: commandBuffer, sourceTexture: scaleSrcTexture, destinationTexture: scaleDesTexture)
        commandBuffer.addCompletedHandler { (buffer) in
            
            var result = [UInt32](repeatElement(0, count: scaleDimension * scaleDimension))
            let region = MTLRegionMake2D(0, 0, scaleDimension, scaleDimension)
            
            scaleDesTexture.getBytes(&result, bytesPerRow: 4 * scaleDimension, from: region, mipmapLevel: 0)
            
            block(result)
//            Debug
//            let image = self.imageOf(rgbaTexture: scaleDesTexture)
        }
        commandBuffer.commit()
    }
    
    /// Edge detect for image
    ///
    /// - Parameters:
    ///   - imagePixels: image pixels with rgba8 format
    ///   - width: image width
    ///   - height: image height
    ///   - block: completion block
    @objc public func edgeDetect(ofImagePixels imagePixels: [UInt32], width: Int, height: Int, completionHandler block: @escaping (_ mean: Int8, _ variance: Int8) -> Void) {
        
        // Make sure the current device supports MetalPerformanceShaders.
        guard let device = device, MPSSupportsMTLDevice(device) else {
            print("Metal Performance Shaders not Supported on current Device")
            block(0, 0)
            return
        }
        
        var pixels = imagePixels
        
        // TextureDescriptors
        let sobelSrcTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Snorm, width: width, height: height, mipmapped: false)
        sobelSrcTextureDescriptor.usage = [.shaderRead]
        
        let sobelDesTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .r8Snorm, width: width, height: height, mipmapped: false)
        sobelDesTextureDescriptor.usage = [.shaderWrite, .shaderRead]
        
        let varianceTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .r8Snorm, width: 2, height: 1, mipmapped: false)
        varianceTextureDescriptor.usage = [.shaderWrite, .shaderRead]
        
        // Textures
        guard let sobelSrcTexture: MTLTexture = device.makeTexture(descriptor: sobelSrcTextureDescriptor) else {
            print("make sobelSrcTexture failed")
            block(0, 0)
            return
        }
        
        guard let sobelDesTexture: MTLTexture = device.makeTexture(descriptor: sobelDesTextureDescriptor) else {
            print("make sobelDesTexture failed")
            block(0, 0)
            return
        }
        
        guard let varianceTexture: MTLTexture = device.makeTexture(descriptor: varianceTextureDescriptor) else {
            print("make varianceTexture failed")
            block(0, 0)
            return
        }
        
        // Fill sobelSrcTexture with pixels
        let sobelRegion = MTLRegionMake2D(0, 0, width, height)
        sobelSrcTexture.replace(region: sobelRegion, mipmapLevel: 0, withBytes: &pixels, bytesPerRow: 4 * width)
        
        // Run Image Filters
        guard let commandBuffer = commandQueue?.makeCommandBuffer() else {
            print("make CommandBuffer failed")
            block(0, 0)
            return
        }
        
        let sobel = MPSImageSobel(device: device)
        let meanAndVariance = MPSImageStatisticsMeanAndVariance(device: device)
        sobel.encode(commandBuffer: commandBuffer, sourceTexture: sobelSrcTexture, destinationTexture: sobelDesTexture)
        meanAndVariance.encode(commandBuffer: commandBuffer, sourceTexture: sobelDesTexture, destinationTexture: varianceTexture)
        commandBuffer.addCompletedHandler { (buffer) in
            
            var result = [Int8](repeatElement(0, count: 2))
            let region = MTLRegionMake2D(0, 0, 2, 1)
            
            varianceTexture.getBytes(&result, bytesPerRow: 1 * 2, from: region, mipmapLevel: 0)
            block(result.first!, result.last!)
//            Debug
//            let grayImage = self.imageOf(grayTexture: sobelDesTexture)
        }
        commandBuffer.commit()
    }
    
    /// Mean saturation of image.
    ///
    /// - Parameters:
    ///   - imagePixels: image pixels with rgba8 format
    ///   - width: image width
    ///   - height: image height
    ///   - block: completion block
    @objc public func meanSaturation(ofImagePixels imagePixels: [UInt32], width: Int, height: Int, completionHandler block: @escaping (Float) -> Void) {
        
        // Make sure the current device supports MetalPerformanceShaders.
        guard let device = device, MPSSupportsMTLDevice(device) else {
            print("Metal Performance Shaders not Supported on current Device")
            block(0)
            return
        }
        
        var pixels = imagePixels
        
        // TextureDescriptors
        let saturationSrcTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: width, height: height, mipmapped: false)
        saturationSrcTextureDescriptor.usage = [.shaderRead]
        
        let saturationDesTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .r32Float, width: width, height: height, mipmapped: false)
        saturationDesTextureDescriptor.usage = [.shaderWrite, .shaderRead]
        
        let meanTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .r32Float, width: 1, height: 1, mipmapped: false)
        meanTextureDescriptor.usage = [.shaderWrite, .shaderRead]
        
        // Textures
        guard let saturationSrcTexture: MTLTexture = device.makeTexture(descriptor: saturationSrcTextureDescriptor) else {
            print("make saturationSrcTexture failed")
            block(0)
            return
        }
        
        guard let saturationDesTexture: MTLTexture = device.makeTexture(descriptor: saturationDesTextureDescriptor) else {
            print("make saturationDesTexture failed")
            block(0)
            return
        }
        
        guard let meanTexture: MTLTexture = device.makeTexture(descriptor: meanTextureDescriptor) else {
            print("make meanTexture failed")
            block(0)
            return
        }
        
        // Fill sobelSrcTexture with pixels
        let saturationRegion = MTLRegionMake2D(0, 0, width, height)
        saturationSrcTexture.replace(region: saturationRegion, mipmapLevel: 0, withBytes: &pixels, bytesPerRow: 4 * width)
        
        // Run Image Filters
        guard let commandBuffer = commandQueue?.makeCommandBuffer() else {
            print("make CommandBuffer failed")
            block(0)
            return
        }
        
        guard let pipelineState = saturationPipelineState else {
            print("Failed to create saturationPipelineState")
            block(0)
            return
        }
        
        let saturation = MPSSaturationKernel(device: device, computePipelineState: pipelineState)
        let mean = MPSImageStatisticsMean(device: device)
        saturation.encode(commandBuffer: commandBuffer, sourceTexture: saturationSrcTexture, destinationTexture: saturationDesTexture)
        mean.encode(commandBuffer: commandBuffer, sourceTexture: saturationDesTexture, destinationTexture: meanTexture)
        commandBuffer.addCompletedHandler { (buffer) in
            
            var result = [Float32](repeatElement(0, count: 1))
            let region = MTLRegionMake2D(0, 0, 1, 1)
            
            meanTexture.getBytes(&result, bytesPerRow: 4, from: region, mipmapLevel: 0)
            block(result.first!)
        }
        commandBuffer.commit()
    }
    
    /// Fingerprint of image.
    ///
    /// - Parameters:
    ///   - imagePixels: image pixels with rgba8 format
    ///   - width: image width
    ///   - height: image height
    ///   - block: completion block
    @objc public func fingerprint(ofImagePixels imagePixels: [UInt32], width: Int, height: Int, completionHandler block: @escaping (Fingerprint?) -> Void) {
        
        // Make sure the current device supports MetalPerformanceShaders.
        guard let device = device, MPSSupportsMTLDevice(device) else {
            print("Metal Performance Shaders not Supported on current Device")
            block(nil)
            return
        }
        
        var pixels = imagePixels
        
        // TextureDescriptors
        let fpSrcTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Uint, width: width, height: height, mipmapped: false)
        fpSrcTextureDescriptor.usage = [.shaderRead]
        
        // Textures
        guard let fpSrcTexture: MTLTexture = device.makeTexture(descriptor: fpSrcTextureDescriptor) else {
            print("make fpSrcTexture failed")
            block(nil)
            return
        }
        
        // Fill fpSrcTexture with pixels
        let fpRegion = MTLRegionMake2D(0, 0, width, height)
        fpSrcTexture.replace(region: fpRegion, mipmapLevel: 0, withBytes: &pixels, bytesPerRow: 4 * width)
        
        // Run Image Filters
        guard let commandBuffer = commandQueue?.makeCommandBuffer() else {
            print("make CommandBuffer failed")
            block(nil)
            return
        }
        
        guard let computePipelineState = fingerprintPipelineState else {
            print("Failed to create fingerprintPipelineState")
            block(nil)
            return
        }
        
        let fp = MSPFingerprintImageKernel(device: device, computePipelineState: computePipelineState)
        let bufferLength = fp.bufferLength()
        let fpBuffer = device.makeBuffer(length: bufferLength, options: .storageModeShared)

        fp.encode(commandBuffer: commandBuffer, sourceTexture: fpSrcTexture, fingerprint: fpBuffer)
        commandBuffer.addCompletedHandler { (buffer) in
            if let buf = fpBuffer {
                let sum = width * height
                let bufferPtr = buf.contents()
                let uint32Ptr = bufferPtr.bindMemory(to: UInt32.self, capacity: bufferLength)
                let uint32Buffer = UnsafeBufferPointer(start: uint32Ptr, count: bufferLength / MemoryLayout<UInt32>.size)
                let output = Array(uint32Buffer)
                let histogram: Fingerprint = output.enumerated().reduce(Fingerprint(), { (dict, arg1) -> Fingerprint in
                    let (offset, element) = arg1
                    if element > 0 {
                        var dict = dict
                        dict[UInt32(offset)] = Double(element) / Double(sum)
                        return dict
                    }
                    return dict
                })
                block(histogram)
            }
            else {
                block(nil)
            }
        }
        commandBuffer.commit()
    }
    
    /// Cosine similarity of two fingerprints.
    ///
    /// - Parameters:
    ///   - a: fingerprint of image
    ///   - b: fingerprint of image
    ///   - block: completion block
    @objc public func cosineSimilarity(ofFingerprint a: [UInt32], withAnother b: [UInt32], completionHandler block: @escaping (Double) -> Void) {
        // Make sure the current device supports MetalPerformanceShaders.
        guard let device = device, MPSSupportsMTLDevice(device) else {
            print("Metal Performance Shaders not Supported on current Device")
            block(0)
            return
        }
        
        guard a.count == b.count else {
            print("Input fingerprint size not equal")
            block(0)
            return
        }
        
        let size = a.count
        
        // TextureDescriptors
        let fpTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Uint, width: size, height: 1, mipmapped: false)
        fpTextureDescriptor.usage = [.shaderRead]
        
        // Textures
        guard let fpATexture: MTLTexture = device.makeTexture(descriptor: fpTextureDescriptor) else {
            print("make fpTexture failed")
            block(0)
            return
        }
        
        guard let fpBTexture: MTLTexture = device.makeTexture(descriptor: fpTextureDescriptor) else {
            print("make fpTexture failed")
            block(0)
            return
        }

        var aFingerprint = a
        var bFingerprint = b
        
        // Fill fpSrcTexture with pixels
        let fpRegion = MTLRegionMake2D(0, 0, size, 1)
        fpATexture.replace(region: fpRegion, mipmapLevel: 0, withBytes: &aFingerprint, bytesPerRow: 4 * size)
        fpBTexture.replace(region: fpRegion, mipmapLevel: 0, withBytes: &bFingerprint, bytesPerRow: 4 * size)
        
        guard let computePipelineState = cosinePipelineState else {
            print("Failed to create cosinePipelineState")
            block(0)
            return
        }
        
        let cosine = MPSCosineImageKernel(device: device, computePipelineState: computePipelineState)
        
        
        // Run Image Filters
        guard let commandBuffer = commandQueue?.makeCommandBuffer() else {
            print("make CommandBuffer failed")
            block(0)
            return
        }
        
        let bufferLength = cosine.bufferLength()
        let cosineBuffer = device.makeBuffer(length: bufferLength, options: .storageModeShared)
        cosine.encode(commandBuffer: commandBuffer, primaryTexture: fpATexture, secondaryTexture: fpBTexture, cosine: cosineBuffer)
        
        commandBuffer.addCompletedHandler { (cbuff) in
            
            if let buf = cosineBuffer {
                let bufferPtr = buf.contents()
                let uint32Ptr = bufferPtr.bindMemory(to: UInt32.self, capacity: bufferLength)
                let uint32Buffer = UnsafeBufferPointer(start: uint32Ptr, count: bufferLength / MemoryLayout<UInt32>.size)
                let output = Array(uint32Buffer)
                
                if output.count == 3 {
                    let sumAB = Double(output[0])
                    let sumAA = sqrt(Double(output[1]))
                    let sumBB = sqrt(Double(output[2]))
                    
                    let result = sumAB / (sumAA * sumBB)
                    block(result)
                    return
                }
            }
            block(0)
        }
        commandBuffer.commit()
    }
}

#if os(iOS) || os(watchOS) || os(tvOS)
fileprivate func imageOf(grayTexture: MTLTexture) -> UIImage? {
    let width = grayTexture.width
    let height = grayTexture.height
    var pixelsResult = [Int8](repeatElement(0, count: width * height))
    let region = MTLRegionMake2D(0, 0, width, height)
    grayTexture.getBytes(&pixelsResult, bytesPerRow: 1 * width, from: region, mipmapLevel: 0)
    let context = CGContext(data: &pixelsResult, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 1 * width, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue )
    
    if let cgImage = context?.makeImage() {
        let imageResult = UIImage(cgImage: cgImage, scale: 0.0, orientation: UIImage.Orientation.downMirrored)
        return imageResult
    }
    return nil
}

fileprivate func imageOf(rgbaTexture: MTLTexture) -> UIImage? {
    let width = rgbaTexture.width
    let height = rgbaTexture.height
    var pixelsResult = [Int32](repeatElement(0, count: width * height))
    let region = MTLRegionMake2D(0, 0, width, height)
    rgbaTexture.getBytes(&pixelsResult, bytesPerRow: 4 * width, from: region, mipmapLevel: 0)
    let context = CGContext(data: &pixelsResult, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 4 * width, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
    
    if let cgImage = context?.makeImage() {
        let imageResult = UIImage(cgImage: cgImage, scale: 0.0, orientation: UIImage.Orientation.downMirrored)
        return imageResult
    }
    return nil
}
#elseif os(macOS)

#endif

fileprivate func makePipelineState(device: MTLDevice, functionName: String) -> MTLComputePipelineState? {
    let library = device.makeDefaultLibrary()
    let computePipelineState: MTLComputePipelineState?
    if let function = library?.makeFunction(name: functionName) {
        do {
            try computePipelineState = device.makeComputePipelineState(function: function)
        } catch {
            computePipelineState = nil
            print("Failed to create ComputePipelineState: \(error.localizedDescription)")
        }
    }
    else {
        computePipelineState = nil
        print("missing metal function")
    }
    return computePipelineState
}
