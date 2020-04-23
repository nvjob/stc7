// Copyright (c) 2016 Unity Technologies. MIT license - license_unity.txt
// #NVJOB STC7. MIT license - license_nvjob.txt
// #NVJOB STC7 V3.2 - https://nvjob.github.io/unity/nvjob-stc-7
// #NVJOB Nicholas Veselov - https://nvjob.github.io


Shader "#NVJOB/STC7" {


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


Properties {
//----------------------------------------------

[HideInInspector][MaterialEnum(Off,0,Front,1,Back,2)] _Cull("Backface Culling", Int) = 2

[HideInInspector][NoScaleOffset]_MainTex("Main Texture", 2D) = "white" {}
[HideInInspector][NoScaleOffset]_DetailTex("Detail Texture", 2D) = "black" {}
[HideInInspector][HDR]_Color("Main Color", Color) = (1,1,1,1)
[HideInInspector][HDR]_HueVariation("Hue Color", Color) = (1.0,0.5,0.0,0.1)
[HideInInspector]_Cutoff("Alpha Cutoff", Range(0.01,0.99)) = 0.333
[HideInInspector]_Shadow_Cutoff("Shadow Cutoff", Range(0.001,0.999)) = 0.333

[HideInInspector][NoScaleOffset]_SpecMap("Specular Map Texture", 2D) = "white" {}
[HideInInspector]_SpecMapInts("Specular Intensity", Range(0, 10)) = 1
[HideInInspector]_Shininess("Shininess", Range(-1, 2)) = 0.078125
[HideInInspector]_Gloss("Gloss", Range(-1, 2)) = 1
[HideInInspector][HDR]_SpecColor("Specular Color", Color) = (0.5, 0.5, 0.5, 1)

[HideInInspector][NoScaleOffset]_OcclusionMap("Occlusion Map Texture", 2D) = "white" {}
[HideInInspector]_IntensityOc("Strength Occlusion", Range(0.03, 10)) = 1

[HideInInspector][NoScaleOffset]_EmissionTex("Emission Map Texture (Subsurface)", 2D) = "white" {}
[HideInInspector][HDR]_EmissionColor("Emission Color", Color) = (0,0,0,0)

[HideInInspector][NoScaleOffset]_BumpMap("Normal Map Texture", 2D) = "bump" {}
[HideInInspector]_IntensityNm("Strength Normal", Range(-10, 10)) = 1

[HideInInspector]_Light("Light", Range(0, 10)) = 1
[HideInInspector]_Brightness("Brightness", Range(0, 5)) = 1
[HideInInspector]_Saturation("Saturation", Range(0, 10)) = 1
[HideInInspector]_Contrast("Contrast", Range(-1, 5)) = 1

[HideInInspector][MaterialEnum(None,0,Fastest,1,Fast,2,Better,3,Best,4,Palm,5)] _WindQuality("Wind Quality", Range(0,5)) = 0
[HideInInspector]_WindSpeed("Wind Speed", Range(0.01, 10)) = 1
[HideInInspector]_WindAmplitude("Wind Amplitude", Range(0.001, 10)) = 1
[HideInInspector]_WindDegreeSlope("Wind Degree Slope", Range(0.001, 10)) = 1
[HideInInspector]_WindConstantTilt("Wind Constant Tilt", Range(0.001, 10)) = 1
[HideInInspector]_LeafRipple("Leaf Ripple", Range(0.001, 100)) = 1
[HideInInspector]_LeafRippleSpeed("Leaf Ripple Speed", Range(0.001, 10)) = 1
[HideInInspector]_LeafTumble("Leaf Tumble", Range(0.001, 10)) = 1
[HideInInspector]_LeafTumbleSpeed("Leaf Tumble Speed", Range(0.001, 5)) = 1
[HideInInspector]_BranchRipple("Branch Ripple", Range(0.001, 20)) = 1
[HideInInspector]_BranchRippleSpeed("Branch Ripple Speed", Range(0.001, 10)) = 1
[HideInInspector]_BranchTwitch("Branch Twitch", Range(0.001, 10)) = 1
[HideInInspector]_BranchWhip("Elasticity", Range(0.01, 10)) = 1
[HideInInspector]_BranchTurbulences("Turbulences", Range(0.001, 10)) = 1
[HideInInspector]_BranchForceHeaviness("Branch Force Wind", Range(0.001, 10)) = 1
[HideInInspector]_BranchHeaviness("Branch Heaviness", Range(-10, 10)) = 1

//----------------------------------------------
}


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


SubShader {
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

Tags { "Queue"="Geometry" "IgnoreProjector"="True" "RenderType"="Opaque" "DisableBatching"="LODFading" }
LOD 400
Cull [_Cull]

CGPROGRAM
#pragma surface surf BlinnPhong vertex:STCShaderVert nolightmap dithercrossfade exclude_path:prepass noforwardadd nolppv halfasview interpolateview novertexlights
#pragma target 3.0
#pragma multi_compile_vertex LOD_FADE_PERCENTAGE
#pragma instancing_options assumeuniformscaling lodfade maxcount:50
#pragma shader_feature_local STC_GTYPE_BRANCH STC_GTYPE_BRANCHDETAIL STC_GTYPE_FROND STC_GTYPE_LEAF STC_GTYPE_MESH
#pragma shader_feature_local EFFECT_ALBEDO
#pragma shader_feature_local EFFECT_HUE_VARIATION
#pragma shader_feature_local EFFECT_SPECULAR
#pragma shader_feature_local EFFECT_OCLUSION
#pragma shader_feature_local EFFECT_EMISSION
#pragma shader_feature_local EFFECT_BUMP
#pragma shader_feature_local COLOR_TUNING
#define ENABLE_WIND

//----------------------------------------------

#include "STC7.cginc"

//----------------------------------------------

void surf(Input IN, inout SurfaceOutput OUT) {
STCShaderFragOut o;
STCShaderFrag(IN, o);
STCShader_COPY_FRAG(OUT, o)
}

ENDCG


///////////////////////////////////////////////////////////////////////////////////////////////////////////////
// For Vertex Lit Rendering


Pass {
//----------------------------------------------

Tags { "LightMode" = "Vertex" }

CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#pragma target 3.0
#pragma multi_compile_fog
#pragma multi_compile_vertex LOD_FADE_PERCENTAGE LOD_FADE_CROSSFADE
#pragma multi_compile_fragment __ LOD_FADE_CROSSFADE
#pragma multi_compile_instancing
#pragma instancing_options assumeuniformscaling lodfade maxcount:50
#pragma shader_feature STC_GTYPE_BRANCH STC_GTYPE_BRANCHDETAIL STC_GTYPE_FROND STC_GTYPE_LEAF STC_GTYPE_MESH
#pragma shader_feature_local EFFECT_ALBEDO
#pragma shader_feature_local EFFECT_HUE_VARIATION
#pragma shader_feature_local EFFECT_OCLUSION
#pragma shader_feature_local EFFECT_EMISSION
#pragma shader_feature_local COLOR_TUNING
#define ENABLE_WIND

//----------------------------------------------

#include "STC7.cginc"

//----------------------------------------------

struct v2f {
UNITY_POSITION(vertex);
UNITY_FOG_COORDS(0)
Input data      : TEXCOORD1;
UNITY_VERTEX_INPUT_INSTANCE_ID
UNITY_VERTEX_OUTPUT_STEREO
};

//----------------------------------------------

v2f vert(STCShaderVB v) {
v2f o;
UNITY_SETUP_INSTANCE_ID(v);
UNITY_TRANSFER_INSTANCE_ID(v, o);
UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
STCShaderVert(v, o.data);
o.data.color.rgb *= ShadeVertexLightsFull(v.vertex, v.normal, 4, true);
o.vertex = UnityObjectToClipPos(v.vertex);
UNITY_TRANSFER_FOG(o,o.vertex);
return o;
}

//----------------------------------------------

fixed4 frag(v2f i) : SV_Target {
UNITY_SETUP_INSTANCE_ID(i);
STCShaderFragOut o;
STCShaderFrag(i.data, o);
UNITY_APPLY_DITHER_CROSSFADE(i.vertex.xy);
#ifdef STCShader_ALPHATEST
fixed4 c = fixed4(o.Albedo, o.Alpha);
#else
fixed4 c = fixed4(o.Albedo, 1);
#endif
UNITY_APPLY_FOG(i.fogCoord, c);
return c;
}

//----------------------------------------------

ENDCG
//----------------------------------------------
}


///////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Shadow Caster


Pass{
//----------------------------------------------

Tags { "LightMode" = "ShadowCaster" }

CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#pragma target 3.0
#pragma instancing_options assumeuniformscaling lodfade maxcount:50
#pragma multi_compile_instancing
#pragma shader_feature_local STC_GTYPE_BRANCH STC_GTYPE_BRANCHDETAIL STC_GTYPE_FROND STC_GTYPE_LEAF STC_GTYPE_MESH
#pragma multi_compile_shadowcaster
#define ENABLE_WIND

//----------------------------------------------

#include "STC7.cginc"

//----------------------------------------------

fixed _Shadow_Cutoff;

struct v2f {
V2F_SHADOW_CASTER;
#ifdef STCShader_ALPHATEST
float2 uv : TEXCOORD1;
#endif
UNITY_VERTEX_INPUT_INSTANCE_ID
UNITY_VERTEX_OUTPUT_STEREO
};

//----------------------------------------------

v2f vert(STCShaderVB v) {
v2f o;
UNITY_SETUP_INSTANCE_ID(v);
UNITY_TRANSFER_INSTANCE_ID(v, o);
UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
#ifdef STCShader_ALPHATEST
o.uv = v.texcoord.xy;
#endif
OffsetSTCShaderVertex(v, 0);
TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
return o;
}

//----------------------------------------------

float4 frag(v2f i) : SV_Target {
UNITY_SETUP_INSTANCE_ID(i);
#ifdef STCShader_ALPHATEST
clip(tex2D(_MainTex, i.uv).a - _Shadow_Cutoff);
#endif
SHADOW_CASTER_FRAGMENT(i)
}

//----------------------------------------------

ENDCG
//----------------------------------------------
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
}


FallBack "Transparent/Cutout/VertexLit"
CustomEditor "STC7Material"

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
}