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

#define HistogramBufferSize (2048) // 4 channels. 8*8*8*4 entrys.

typedef struct
{
    atomic_uint bucket[HistogramBufferSize];
} PAHistogramBuffer;

typedef struct
{
    atomic_uint ab;
    atomic_uint aa;
    atomic_uint bb;
} PACosineBuffer;

void rgb2hsv(texture2d<float, access::read> inTexture [[texture(0)]],
             texture2d<float, access::write> outTexture [[texture(1)]],
             uint2 gid [[thread_position_in_grid]]) {
    float4 c = inTexture.read(gid);
    float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    float4 p = c.z < c.y ? float4(c.yz, K.wz) : float4(c.zy, K.xy);
    float4 q = c.w < p.x ? float4(p.xyw, c.w) : float4(c.w, p.yzx);
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    //    float4 hsv = float4(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x, 1.0);
    outTexture.write(float4(d / (q.x + e), 0, 0, 0), gid);
}

kernel void
rgb2hsvKernelNonuniform(texture2d<float, access::read> inTexture [[texture(0)]],
              texture2d<float, access::write> outTexture [[texture(1)]],
              uint2 gid [[thread_position_in_grid]])
{
    rgb2hsv(inTexture, outTexture, gid);
}

kernel void
rgb2hsvKernel(texture2d<float, access::read> inTexture [[texture(0)]],
              texture2d<float, access::write> outTexture [[texture(1)]],
              uint2 gid [[thread_position_in_grid]])
{
    if((gid.x >= outTexture.get_width()) || (gid.y >= outTexture.get_height()))
    {
        return;
    }
    
    rgb2hsv(inTexture, outTexture, gid);
}

void fingerprint(texture2d<uint, access::read> inTexture [[texture(0)]],
                 device PAHistogramBuffer &buffer [[buffer(0)]],
                 uint2 gid [[thread_position_in_grid]])
{
    uint4 c = inTexture.read(gid);
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    uint blockCount = 2;
    uint rowCount = min(blockCount, height);
    uint countPerRow = min(blockCount, width);
    uint hStep = width / countPerRow;
    uint vStep = height / rowCount;
    uint row = gid.y / vStep;
    uint col = gid.x / hStep;
    
    // |-3bit-|-3bit-|-3bit-|-2bit-|
    uint result = (row * countPerRow + col) + ((c.y >> 5) << 2) + ((c.z >> 5) << 5) + ((c.w >> 5) << 8);
    atomic_fetch_add_explicit(&buffer.bucket[result], 1, memory_order_relaxed);
}

kernel void
fingerprintKernelNonuniform(texture2d<uint, access::read> inTexture [[texture(0)]],
                  device PAHistogramBuffer &buffer [[buffer(0)]],
                  uint2 gid [[thread_position_in_grid]])
{
    fingerprint(inTexture, buffer, gid);
}

kernel void
fingerprintKernel(texture2d<uint, access::read> inTexture [[texture(0)]],
                  device PAHistogramBuffer &buffer [[buffer(0)]],
                  uint2 gid [[thread_position_in_grid]])
{
    if((gid.x >= inTexture.get_width()) || (gid.y >= inTexture.get_height()))
    {
        return;
    }
    
    fingerprint(inTexture, buffer, gid);
}


void cosine(texture2d<uint, access::read> inTextureA [[texture(0)]],
            texture2d<uint, access::read> inTextureB [[texture(1)]],
            device PACosineBuffer &buffer [[buffer(0)]],
            uint2 gid [[thread_position_in_grid]])
{
    uint4 color_a = inTextureA.read(gid);
    uint a = (color_a.w << 24) | (color_a.z << 16) | (color_a.y << 8) | color_a.x;
    uint4 color_b = inTextureB.read(gid);
    uint b = (color_b.w << 24) | (color_b.z << 16) | (color_b.y << 8) | color_b.x;
    
    atomic_fetch_add_explicit(&buffer.ab, a * b, memory_order_relaxed);
    atomic_fetch_add_explicit(&buffer.aa, a * a, memory_order_relaxed);
    atomic_fetch_add_explicit(&buffer.bb, b * b, memory_order_relaxed);
}

kernel void
cosineKernelNonuniform(texture2d<uint, access::read> inTextureA [[texture(0)]],
                       texture2d<uint, access::read> inTextureB [[texture(1)]],
                       device PACosineBuffer &buffer [[buffer(0)]],
                       uint2 gid [[thread_position_in_grid]])
{
    cosine(inTextureA, inTextureB, buffer, gid);
}

kernel void
cosineKernel(texture2d<uint, access::read> inTextureA [[texture(0)]],
             texture2d<uint, access::read> inTextureB [[texture(1)]],
             device PACosineBuffer &buffer [[buffer(0)]],
             uint2 gid [[thread_position_in_grid]])
{
    if((gid.x >= inTextureA.get_width()) || (gid.y >= inTextureA.get_height()))
    {
        return;
    }
    
    cosine(inTextureA, inTextureB, buffer, gid);
}
