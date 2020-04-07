// Copyright (c) 2016 Unity Technologies. MIT license - license_unity.txt
// #NVJOB shader for SpeedTree 7 (STC7). MIT license - license_nvjob.txt
// #NVJOB shader for SpeedTree 7 (STC7) V3.1 - https://nvjob.github.io/unity/nvjob-stc-7
// #NVJOB Nicholas Veselov - https://nvjob.github.io


Shader "#NVJOB/For SpeedTree 7/Billboard" {


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


Properties {
//----------------------------------------------

[NoScaleOffset]_MainTex("Main Texture", 2D) = "white" {}
[HDR]_Color("Main Color", Color) = (1,1,1,1)
[HDR]_HueVariation("Hue Color", Color) = (1.0,0.5,0.0,0.1)
_Cutoff("Alpha cutoff", Range(0.01,0.99)) = 0.5

[NoScaleOffset]_SpecMap("Specular Map Texture", 2D) = "white" {}
_SpecMapInts("Specular Intensity", Range(0, 10)) = 1
_Shininess("Shininess", Range(0.03, 1)) = 0.078125
_Gloss("Gloss", Range(0.03, 1)) = 1
[HDR]_SpecColor("Specular Color", Color) = (0.5, 0.5, 0.5, 1)

[NoScaleOffset]_OcclusionMap("Occlusion Map Texture", 2D) = "white" {}
_IntensityOc("Strength Occlusion", Range(0.03, 10)) = 1

[NoScaleOffset]_EmissionTex("Emission Map Texture (Subsurface)", 2D) = "white" {}
[HDR]_EmissionColor("Emission Color", Color) = (0,0,0,0)

[NoScaleOffset]_BumpMap("Normal Map Texture", 2D) = "bump" {}
_IntensityNm("Strength Normal", Range(-10, 10)) = 1

_Light("Light", Range(0, 10)) = 1
_Brightness("Brightness", Range(0, 5)) = 1
_Saturation("Saturation", Range(0, 10)) = 1
_Contrast("Contrast", Range(-1, 5)) = 1

[MaterialEnum(None,0,Fastest,1)] _WindQuality("Wind Quality", Range(0,1)) = 0
_WindSpeed("Wind Speed", Range(0.01, 10)) = 1
_WindAmplitude("Wind Amplitude", Range(0.01, 10)) = 1
_WindDegreeSlope("Wind Degree Slope", Range(0.01, 10)) = 1
_WindConstantTilt("Wind Constant Tilt", Range(0.01, 10)) = 1

//----------------------------------------------
}


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



SubShader {
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

Tags { "Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="TransparentCutout" "DisableBatching"="LODFading" }
LOD 400

CGPROGRAM
#pragma surface surf BlinnPhong vertex:STCShaderBillboardVert exclude_path:prepass nolightmap dithercrossfade noforwardadd nolppv halfasview interpolateview novertexlights
#pragma target 3.0
#pragma multi_compile __ BILLBOARD_FACE_CAMERA_POS
#pragma shader_feature EFFECT_ALBEDO
#pragma shader_feature EFFECT_HUE_VARIATION
#pragma shader_feature EFFECT_SPECULAR
#pragma shader_feature EFFECT_OCLUSION
#pragma shader_feature EFFECT_EMISSION
#pragma shader_feature EFFECT_BUMP
#pragma shader_feature COLOR_TUNING
#define ENABLE_WIND

//----------------------------------------------

#include "STBCustomCore7.cginc"

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
Tags { "LightMode" = "Vertex" }

CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#pragma target 3.0
#pragma multi_compile_fog
#pragma multi_compile __ LOD_FADE_CROSSFADE
#pragma multi_compile __ BILLBOARD_FACE_CAMERA_POS
#pragma shader_feature EFFECT_HUE_VARIATION
#define ENABLE_WIND

//----------------------------------------------

#include "STBCustomCore7.cginc"

//----------------------------------------------


struct v2f {
UNITY_POSITION(vertex);
UNITY_FOG_COORDS(0)
Input data      : TEXCOORD1;
UNITY_VERTEX_OUTPUT_STEREO
};

//----------------------------------------------

v2f vert(STCShaderBillboardData v) {
v2f o;
UNITY_SETUP_INSTANCE_ID(v);
UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
STCShaderBillboardVert(v, o.data);
o.data.color.rgb *= ShadeVertexLightsFull(v.vertex, v.normal, 4, true);
o.vertex = UnityObjectToClipPos(v.vertex);
UNITY_TRANSFER_FOG(o,o.vertex);
return o;
}

//----------------------------------------------

fixed4 frag(v2f i) : SV_Target {
STCShaderFragOut o;
STCShaderFrag(i.data, o);
UNITY_APPLY_DITHER_CROSSFADE(i.vertex.xy);
fixed4 c = fixed4(o.Albedo, o.Alpha);
UNITY_APPLY_FOG(i.fogCoord, c);
return c;
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
