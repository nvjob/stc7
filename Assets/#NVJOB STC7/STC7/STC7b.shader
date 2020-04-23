// Copyright (c) 2016 Unity Technologies. MIT license - license_unity.txt
// #NVJOB STC7. MIT license - license_nvjob.txt
// #NVJOB STC7 V3.2 - https://nvjob.github.io/unity/nvjob-stc-7
// #NVJOB Nicholas Veselov - https://nvjob.github.io


Shader "#NVJOB/STC7 billboard" {


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


Properties {
//----------------------------------------------

[HideInInspector][NoScaleOffset]_MainTex("Main Texture", 2D) = "white" {}
[HideInInspector][HDR]_Color("Main Color", Color) = (1,1,1,1)
[HideInInspector][HDR]_HueVariation("Hue Color", Color) = (1.0,0.5,0.0,0.1)
[HideInInspector]_Cutoff("Alpha cutoff", Range(0.01,0.99)) = 0.5

[HideInInspector][NoScaleOffset]_SpecMap("Specular Map Texture", 2D) = "white" {}
[HideInInspector]_SpecMapInts("Specular Intensity", Range(0, 10)) = 1
[HideInInspector]_Shininess("Shininess", Range(0.03, 1)) = 0.078125
[HideInInspector]_Gloss("Gloss", Range(0.03, 1)) = 1
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

[HideInInspector][MaterialEnum(None,0,Fastest,1)] _WindQuality("Wind Quality", Range(0,1)) = 0
[HideInInspector]_WindSpeed("Wind Speed", Range(0.01, 10)) = 1
[HideInInspector]_WindAmplitude("Wind Amplitude", Range(0.01, 10)) = 1
[HideInInspector]_WindDegreeSlope("Wind Degree Slope", Range(0.01, 10)) = 1
[HideInInspector]_WindConstantTilt("Wind Constant Tilt", Range(0.01, 10)) = 1

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
#pragma shader_feature_local EFFECT_ALBEDO
#pragma shader_feature_local EFFECT_HUE_VARIATION
#pragma shader_feature_local EFFECT_SPECULAR
#pragma shader_feature_local EFFECT_OCLUSION
#pragma shader_feature_local EFFECT_EMISSION
#pragma shader_feature_local EFFECT_BUMP
#pragma shader_feature_local COLOR_TUNING
#define ENABLE_WIND

//----------------------------------------------

#include "STC7b.cginc"

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
#pragma shader_feature_local EFFECT_ALBEDO
#pragma shader_feature_local EFFECT_HUE_VARIATION
#pragma shader_feature_local EFFECT_OCLUSION
#pragma shader_feature_local EFFECT_EMISSION
#pragma shader_feature_local COLOR_TUNING
#define ENABLE_WIND

//----------------------------------------------

#include "STC7b.cginc"

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
