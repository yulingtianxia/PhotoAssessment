//
//  MPSCosineImageKernel.swift
//  PhotoAssessment
//
//  Created by 杨萧玉 on 2019/3/3.
//  Copyright © 2019 杨萧玉. All rights reserved.
//

import MetalPerformanceShaders
import Metal

class MPSCosineImageKernel {
    
    let computePipelineState: MTLComputePipelineState
    let threadGroupSize: MTLSize
    let device: MTLDevice
    
    init(device: MTLDevice, computePipelineState: MTLComputePipelineState) {
        self.device = device
        self.computePipelineState = computePipelineState
        let w = computePipelineState.threadExecutionWidth;
        let h = computePipelineState.maxTotalThreadsPerThreadgroup / w;
        threadGroupSize = MTLSize(width: w, height: h, depth: 1);
    }
    
    func bufferLength() -> Int {
        // PACosineBuffer * 4.
        return 12
    }
    
    func encode(commandBuffer: MTLCommandBuffer, primaryTexture: MTLTexture, secondaryTexture: MTLTexture, cosine buffer: MTLBuffer?) {
        
        guard primaryTexture.width == secondaryTexture.width && primaryTexture.height == secondaryTexture.height else {
            return
        }
        
        let encoder = commandBuffer.makeComputeCommandEncoder()
        encoder?.pushDebugGroup("cosine")
        encoder?.setComputePipelineState(computePipelineState)
        encoder?.setTexture(primaryTexture, index: 0)
        encoder?.setTexture(secondaryTexture, index: 1)
        encoder?.setBuffer(buffer, offset: 0, index: 0)
        
        if device.supportNonuniformThreadgroupSize() {
            let threadsPerGrid = MTLSize(width: primaryTexture.width, height: primaryTexture.height, depth: 1);
            encoder?.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadGroupSize)
        }
        else {
            let w = threadGroupSize.width;
            let h = threadGroupSize.height;
            let threadgroupsPerGrid = MTLSize(width: (primaryTexture.width + w - 1) / w, height: (primaryTexture.height + h - 1) / h, depth: 1);
            encoder?.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadGroupSize)
        }
        
        encoder?.popDebugGroup()
        encoder?.endEncoding()
    }
}
