//
//  PhotoAssessmentShaders.metal
//  PhotoAssessment
//
//  Created by 杨萧玉 on 2019/2/24.
//  Copyright © 2019 杨萧玉. All rights reserved.
//

#include <metal_stdlib>
#include <simd/simd.h>
using namespace metal;


kernel void
rgb2hsvKernel(texture2d<float, access::read> inTexture [[texture(0)]],
              texture2d<float, access::write> outTexture [[texture(1)]],
              uint2 gid [[thread_position_in_grid]])
{
    if((gid.x >= outTexture.get_width()) || (gid.y >= outTexture.get_height()))
    {
        return;
    }
    
    float4 c = inTexture.read(gid);
    float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    float4 p = mix(float4(c.yz, K.wz), float4(c.zy, K.xy), step(c.y, c.z));
    float4 q = mix(float4(p.xyw, c.w), float4(c.w, p.yzx), step(p.x, c.w));
    
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
//    float4 hsv = float4(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x, 1.0);
    outTexture.write(float4(d / (q.x + e), 0, 0, 0), gid);
}

kernel void
fingerprintKernel(texture2d<uint, access::read> inTexture [[texture(0)]],
              texture2d<uint, access::write> outTexture [[texture(1)]],
              uint2 gid [[thread_position_in_grid]])
{
    if((gid.x >= outTexture.get_width()) || (gid.y >= outTexture.get_height()))
    {
        return;
    }
    
    uint4 c = inTexture.read(gid);
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    uint blockCount = 4;
    uint rowCount = min(blockCount, height);
    uint countPerRow = min(blockCount, width);
    uint hStep = width / countPerRow;
    uint vStep = height / rowCount;
    uint row = gid.y / vStep;
    uint col = gid.x / hStep;
    
    outTexture.write(uint4(row * countPerRow + col, c.y / 16, c.z / 16, c.w / 16), gid);
}


