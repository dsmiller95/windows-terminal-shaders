
// Define map for PS input
struct PSInput {
  float4 pos : SV_POSITION;
  float2 uv : TEXCOORD0;
};

// The terminal graphics as a texture
Texture2D shaderTexture : register(t0);
SamplerState samplerState : register(s0);
Texture2D image : register(t1);

Texture2D sampleR : register(t2);
Texture2D sampleG : register(t3);
Texture2D sampleBlack : register(t4);

// Terminal settings such as the resolution of the texture
cbuffer PixelShaderSettings {
  float  Time;
  float  Scale;
  float2 Resolution;
  float4 Background;
};
// --------------------


// Settings - Debug
#define DEBUG                   1
#define DEBUG_ROTATION          ((Time/10) % 3)
#define DEBUG_SEGMENTS          1
#define DEBUG_OFFSET            0.425
#define DEBUG_WIDTH             0.4
#define SHOW_UV                 0

#define SHOW_POS                0


#define ZOOM                1
//#define OFF                float2(-0.3, .1)
#define OFF                float2(0, 0)

static const float3 Red = float3(1.0, 0, 0);
static const float3 Green = float3(0, 1.0, 0);
static const float3 Black = float3(0, 0, 0);
static const float Epsilon = 0.000001;

float3 minComp(float3 x){
	return min(x.x, min(x.y, x.z));
}
float3 maxComp(float3 x){
	return max(x.x, max(x.y, x.z));
}

bool isNaN(float x){
    return !(x < 0.f || x > 0.f || x == 0.f);
}
bool isOutOfBounds(float x){
	return x > 1 || x < 0 || isNaN(x);
}
bool3 isOutOfBounds(float3 x){
	return bool3(isOutOfBounds(x.x), isOutOfBounds(x.y), isOutOfBounds(x.z));
}

float outOfBoundsOnly(float x, float err){
	return isOutOfBounds(x) * err;
}
float3 outOfBoundsOnly(float3 x, float err){
	return isOutOfBounds(x) * float3(err);
}

float outOfBoundsGuard(float x, float err){
	return x > 1 ? err : x < 0 ? err : x;
}
float3 outOfBoundsGuard(float3 x, float err){
	return float3(outOfBoundsGuard(x.x, err), outOfBoundsGuard(x.y, err), outOfBoundsGuard(x.z, err));
}

float3 U(float3 x){
	return x.yzx;
}

float safeDivide(float num, float den){
	den = length(den) <= Epsilon ? sign(den) * Epsilon : den;
	return num / den;
}


float getRatioAssumeLinear(float3 num, float3 den){
	if(abs(den.x) > Epsilon){
		return num.x / den.x;
	}
	if(abs(den.y) > Epsilon){
		return num.y / den.y;
	}
	if(abs(den.z) > Epsilon){
		return num.z / den.z;
	}
	return 0;
}

float4 main(PSInput pin) : SV_TARGET
{
  float4 pos = pin.pos;
  float2 uv = pin.uv;
  
  uv = (uv - 0.5) / ZOOM + float2(0.5) + OFF;

  float3 redSample = sampleR.Sample(samplerState, uv).xyz;
  float3 greenSample = sampleG.Sample(samplerState, uv).xyz;
  float3 blackSample = sampleBlack.Sample(samplerState, uv).xyz;

  float3 a = redSample - Red;
  float3 b = U(greenSample) - Red;
  
  float aR = redSample - Red;
  float cR = blackSample - Red;
  float alphaR = getRatioAssumeLinear(aR, cR);//safeDivide(dot(aR, cR), dot(cR, cR));
  
  
  float aG = greenSample - Green;
  float cG = blackSample - Green;
  float alphaG = safeDivide(dot(aG, cG), dot(cG, cG));
//  float alphaG = getRatioAssumeLinear(aG, cG);
  
//  float alpha = getRatioAssumeLinear(aR, cR);
  float alpha = alphaG;// min(alphaR, alphaG);
  alpha = clamp(alpha, 0, 1);
  float3 variance = aR - alpha * cR;
  alpha = alpha;
  
  float3 RCa = Red + (blackSample - redSample);
  alpha = RCa.r;

  
  float3 trueColor = abs(alpha) <= Epsilon ? blackSample : blackSample * (1. / alpha);
//  trueColor = outOfBoundsGuard(trueColor, 1);
  float3 greenColor = lerp(Green, trueColor, alpha);
  float3 blackColor = lerp(Black, trueColor, alpha);
  
  float dist = length(greenSample - greenColor);
  float similarity = dot(greenSample, greenColor) / (length(greenSample) * length(greenColor));
  similarity = 1 - ((similarity + 1) / 2);
//  return float4(dist, similarity, 0, 1);
//  return float4(alpha > 1, alpha < 0, isNaN(alpha), 1.0);
//  return float4(RCa, 1);
//  return float4(greenColor, 1);
//  return float4(greenSample, 1);
  return float4(trueColor, alpha);
}