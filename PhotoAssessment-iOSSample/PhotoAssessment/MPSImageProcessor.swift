//
//  MPSImageProcessor.swift
//  PhotoAssessment
//
//  Created by 杨萧玉 on 2018/11/17.
//  Copyright © 2018 杨萧玉. All rights reserved.
//

import UIKit
import MetalKit
import MetalPerformanceShaders

class MPSImageProcessor {
    
    private let device: MTLDevice?
    private let commandQueue: MTLCommandQueue?
    private let sobel: MPSImageSobel?
    private let meanAndVariance: MPSImageStatisticsMeanAndVariance?
    private let scale: MPSImageBilinearScale?
    
    init?() {
        // Load default device.
        device = MTLCreateSystemDefaultDevice()
        
        // Make sure the current device supports MetalPerformanceShaders.
        guard MPSSupportsMTLDevice(device) else {
            print("Metal Performance Shaders not Supported on current Device")
            return nil
        }
        
        // Create new command queue.
        commandQueue = device?.makeCommandQueue()
        
        if let device = device {
            sobel = MPSImageSobel(device: device)
            meanAndVariance = MPSImageStatisticsMeanAndVariance(device: device)
            scale = MPSImageBilinearScale(device: device)
        }
        else {
            return nil
        }
    }
    
    func downsample(imagePixels: [Int32], width: Int, height: Int, scaleDimension: Int, _ block: @escaping ([Int32]?) -> Void) -> Void {
        var pixels = imagePixels
        // TextureDescriptors
        let scaleSrcTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Snorm, width: width, height: height, mipmapped: false)
        scaleSrcTextureDescriptor.usage = [.shaderWrite, .shaderRead]
        
        let scalaDesTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Snorm, width: scaleDimension, height: scaleDimension, mipmapped: false)
        scalaDesTextureDescriptor.usage = [.shaderWrite, .shaderRead]
        
        // Textures
        guard let scaleSrcTexture: MTLTexture = device?.makeTexture(descriptor: scaleSrcTextureDescriptor) else {
            block(nil)
            return
        }
        
        guard let scaleDesTexture: MTLTexture = device?.makeTexture(descriptor: scalaDesTextureDescriptor) else {
            block(nil)
            return
        }
        
        // Fill sobelSrcTexture with pixels
        let scaleRegion = MTLRegionMake2D(0, 0, width, height)
        scaleSrcTexture.replace(region: scaleRegion, mipmapLevel: 0, withBytes: &pixels, bytesPerRow: 4 * width)
        
        // Run Image Filters
        if let commandBuffer = commandQueue?.makeCommandBuffer() {
            scale?.encode(commandBuffer: commandBuffer, sourceTexture: scaleSrcTexture, destinationTexture: scaleDesTexture)
            commandBuffer.addCompletedHandler { (buffer) in
                
                var result = [Int32](repeatElement(0, count: scaleDimension * scaleDimension))
                let region = MTLRegionMake2D(0, 0, scaleDimension, scaleDimension)
                
                scaleDesTexture.getBytes(&result, bytesPerRow: 4 * scaleDimension, from: region, mipmapLevel: 0)
//                let image = self.imageOf(rgbaTexture: scaleDesTexture)
                block(result)
            }
            commandBuffer.commit()
        }
        else {
            block(nil)
        }
    }
    
    func edgeDetect(imagePixels: [Int32], width: Int, height: Int, _ block: @escaping (Int8?, Int8?) -> Void) -> Void {
        
        var pixels = imagePixels
        
        // TextureDescriptors
        let sobelSrcTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Snorm, width: width, height: height, mipmapped: false)
        sobelSrcTextureDescriptor.usage = [.shaderWrite, .shaderRead]
        
        let sobelDesTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .r8Snorm, width: width, height: height, mipmapped: false)
        sobelDesTextureDescriptor.usage = [.shaderWrite, .shaderRead]
        
        let varianceTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .r8Snorm, width: 2, height: 1, mipmapped: false)
        varianceTextureDescriptor.usage = [.shaderWrite, .shaderRead]
        
        // Textures
        guard let sobelSrcTexture: MTLTexture = device?.makeTexture(descriptor: sobelSrcTextureDescriptor) else {
            block(nil, nil)
            return
        }
        
        guard let sobelDesTexture: MTLTexture = device?.makeTexture(descriptor: sobelDesTextureDescriptor) else {
            block(nil, nil)
            return
        }
        
        guard let varianceTexture: MTLTexture = device?.makeTexture(descriptor: varianceTextureDescriptor) else {
            block(nil, nil)
            return
        }
        
        // Fill sobelSrcTexture with pixels
        let sobelRegion = MTLRegionMake2D(0, 0, width, height)
        sobelSrcTexture.replace(region: sobelRegion, mipmapLevel: 0, withBytes: &pixels, bytesPerRow: 4 * width)
        
        // Run Image Filters
        if let commandBuffer = commandQueue?.makeCommandBuffer() {
            sobel?.encode(commandBuffer: commandBuffer, sourceTexture: sobelSrcTexture, destinationTexture: sobelDesTexture)
            meanAndVariance?.encode(commandBuffer: commandBuffer, sourceTexture: sobelDesTexture, destinationTexture: varianceTexture)
            commandBuffer.addCompletedHandler { (buffer) in
//                let grayImage = self.imageOf(grayTexture: sobelDesTexture)
                
                var result = [Int8](repeatElement(0, count: 2))
                let region = MTLRegionMake2D(0, 0, 2, 1)
                
                varianceTexture.getBytes(&result, bytesPerRow: 1 * 2, from: region, mipmapLevel: 0)
                print("result:\(result)")
                block(result.first, result.last)
            }
            commandBuffer.commit()
        }
        else {
            block(nil, nil)
        }
    }
    
    fileprivate func imageOf(grayTexture: MTLTexture) -> UIImage? {
        let width = grayTexture.width
        let height = grayTexture.height
        var pixelsResult = [Int8](repeatElement(0, count: width * height))
        let region = MTLRegionMake2D(0, 0, width, height)
        grayTexture.getBytes(&pixelsResult, bytesPerRow: 1 * width, from: region, mipmapLevel: 0)
        let context = CGContext(data: &pixelsResult, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 1 * width, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue )
        
        if let ciImage = context?.makeImage() {
            let imageResult = UIImage(cgImage: ciImage, scale: 0.0, orientation: UIImage.Orientation.downMirrored)
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
        
        if let ciImage = context?.makeImage() {
            let imageResult = UIImage(cgImage: ciImage, scale: 0.0, orientation: UIImage.Orientation.downMirrored)
            return imageResult
        }
        return nil
    }
}
