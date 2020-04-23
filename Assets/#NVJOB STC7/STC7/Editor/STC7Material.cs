// Copyright (c) 2016 Unity Technologies. MIT license - license_unity.txt
// #NVJOB STC7. MIT license - license_nvjob.txt
// #NVJOB STC7 V3.2 - https://nvjob.github.io/unity/nvjob-stc-7
// #NVJOB Nicholas Veselov - https://nvjob.github.io


using System.Collections.Generic;
using System.Linq;
using UnityEngine;


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


namespace UnityEditor
{
    [CanEditMultipleObjects]
    internal class STC7Material : MaterialEditor
    {
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


        enum STCGeometryType { Branch = 0, BranchDetail, Frond, Leaf, Mesh }
        string[] STCGTypeString = { "STC_GTYPE_BRANCH", "STC_GTYPE_BRANCHDETAIL", "STC_GTYPE_FROND", "STC_GTYPE_LEAF", "STC_GTYPE_MESH" };
        bool ShouldEnableAlphaTest(STCGeometryType geomType) { return geomType == STCGeometryType.Frond || geomType == STCGeometryType.Leaf; }
        Color smLineColor = Color.HSVToRGB(0, 0, 0.55f), bgLineColor = Color.HSVToRGB(0, 0, 0.3f);
        int smLinePadding = 20, bgLinePadding = 35;
        bool billboard;


        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


        public override void OnInspectorGUI()
        {
            //--------------

            SetDefaultGUIWidths();
            serializedObject.Update();
            SerializedProperty shaderFind = serializedObject.FindProperty("m_Shader");
            if (!isVisible || shaderFind.hasMultipleDifferentValues || shaderFind.objectReferenceValue == null) return;

            //--------------

            List<MaterialProperty> allProps = new List<MaterialProperty>(GetMaterialProperties(targets));
            billboard = allProps.Find(prop => prop.name == "_Shadow_Cutoff") == null;

            //--------------

            STCGeometryType[] geomTypes = new STCGeometryType[targets.Length];
            for (int i = 0; i < targets.Length; ++i)
            {
                geomTypes[i] = STCGeometryType.Branch;
                for (int j = 0; j < STCGTypeString.Length; ++j)
                {
                    if (((Material)targets[i]).shaderKeywords.Contains(STCGTypeString[j]))
                    {
                        geomTypes[i] = (STCGeometryType)j;
                        break;
                    }
                }
            }

            //--------------

            EditorGUI.showMixedValue = geomTypes.Distinct().Count() > 1;
            EditorGUI.BeginChangeCheck();
            Header();

            //--------------

            if (billboard == false) // Not Billboard
            {
                EditorGUILayout.LabelField("Geometry Type & Culling:", EditorStyles.boldLabel);
                DrawUILine(smLineColor, 1, smLinePadding);
                GeometryTypeCH(allProps, geomTypes);
                DrawUILine(bgLineColor, 2, bgLinePadding);
            }

            //--------------

            EditorGUILayout.LabelField("Texture and Color Settings:", EditorStyles.boldLabel);
            DrawUILine(smLineColor, 1, smLinePadding);
            MainTexture(allProps, geomTypes);
            SpecularMap(allProps);
            OcclusionMap(allProps);
            EmissionMap(allProps);
            BumpMap(allProps);
            DrawUILine(bgLineColor, 2, bgLinePadding);

            //--------------

            EditorGUILayout.LabelField("Color and Light Tuning:", EditorStyles.boldLabel);
            DrawUILine(smLineColor, 1, smLinePadding);
            ColorLightTuning(allProps);
            DrawUILine(bgLineColor, 2, bgLinePadding);

            //--------------

            EditorGUILayout.LabelField("Wind Settings:", EditorStyles.boldLabel);
            DrawUILine(smLineColor, 1, smLinePadding);
            WindSettings(allProps);

            //--------------

            foreach (MaterialProperty prop in allProps)
            {
                if ((prop.flags & MaterialProperty.PropFlags.HideInInspector) != 0) continue;
                ShaderProperty(prop, prop.displayName);
            }

            //--------------

            Information();
            RenderQueueField();
            EnableInstancingField();
            DoubleSidedGIField();
            EditorGUILayout.Space();
            EditorGUILayout.Space();

            //-------------- 
        }


        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


        void GeometryTypeCH(List<MaterialProperty> allProps, STCGeometryType[] geomTypes)
        {
            //--------------

            STCGeometryType setGeomType = (STCGeometryType)EditorGUILayout.EnumPopup("Geometry Type", geomTypes[0]);
            if (EditorGUI.EndChangeCheck())
            {
                bool shouldEnableAlphaTest = ShouldEnableAlphaTest(setGeomType);
                UnityEngine.Rendering.CullMode cullMode = shouldEnableAlphaTest ? UnityEngine.Rendering.CullMode.Off : UnityEngine.Rendering.CullMode.Back;

                foreach (Material m in targets.Cast<Material>())
                {
                    if (shouldEnableAlphaTest) m.SetOverrideTag("RenderType", "treeTransparentCutout");
                    for (int i = 0; i < STCGTypeString.Length; ++i) m.DisableKeyword(STCGTypeString[i]);
                    m.EnableKeyword(STCGTypeString[(int)setGeomType]);
                    m.renderQueue = shouldEnableAlphaTest ? (int)UnityEngine.Rendering.RenderQueue.AlphaTest : (int)UnityEngine.Rendering.RenderQueue.Geometry;
                    m.SetInt("_Cull", (int)cullMode);
                }
            }
            EditorGUI.showMixedValue = false;

            MaterialProperty culling = allProps.Find(prop => prop.name == "_Cull");
            if (culling != null)
            {
                allProps.Remove(culling);
                ShaderProperty(culling, culling.displayName);
            }

            //--------------
        }


        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


        void MainTexture(List<MaterialProperty> allProps, STCGeometryType[] geomTypes)
        {
            //--------------

            MaterialProperty mainTex = allProps.Find(prop => prop.name == "_MainTex");
            MaterialProperty detailTex = allProps.Find(prop => prop.name == "_DetailTex");
            MaterialProperty hueVariation = allProps.Find(prop => prop.name == "_HueVariation");
            MaterialProperty colorMat = allProps.Find(prop => prop.name == "_Color");
            MaterialProperty alphaCutoff = allProps.Find(prop => prop.name == "_Cutoff");
            MaterialProperty shadowCutoff = allProps.Find(prop => prop.name == "_Shadow_Cutoff");

            if (mainTex != null)
            {
                allProps.Remove(mainTex);
                if (detailTex != null) allProps.Remove(detailTex);

                IEnumerable<bool> enableAlbedo = targets.Select(t => ((Material)t).shaderKeywords.Contains("EFFECT_ALBEDO"));
                bool? enable = EditorGUILayout.Toggle("Albedo Map", enableAlbedo.First());

                if (enableAlbedo.First())
                {
                    ShaderProperty(mainTex, mainTex.displayName);
                    if (detailTex != null && geomTypes.Contains(STCGeometryType.BranchDetail)) ShaderProperty(detailTex, detailTex.displayName);
                }

                if (enable != null)
                {
                    foreach (Material m in targets.Cast<Material>())
                    {
                        if (enable.Value) m.EnableKeyword("EFFECT_ALBEDO");
                        else m.DisableKeyword("EFFECT_ALBEDO");
                    }
                }
            }

            IEnumerable<bool> enableHueVariation = targets.Select(t => ((Material)t).shaderKeywords.Contains("EFFECT_HUE_VARIATION"));
            if (enableHueVariation != null && hueVariation != null)
            {
                allProps.Remove(hueVariation);
                bool? enable = EditorGUILayout.Toggle("Hue Variation", enableHueVariation.First());
                if (enableHueVariation.First()) ShaderProperty(hueVariation, hueVariation.displayName);
                if (enable != null)
                {
                    foreach (Material m in targets.Cast<Material>())
                    {
                        if (enable.Value) m.EnableKeyword("EFFECT_HUE_VARIATION");
                        else m.DisableKeyword("EFFECT_HUE_VARIATION");
                    }
                }
            }

            if (colorMat != null)
            {
                allProps.Remove(colorMat);
                ShaderProperty(colorMat, colorMat.displayName);
            }

            if (alphaCutoff != null)
            {
                allProps.Remove(alphaCutoff);
                if (geomTypes.Any(t => ShouldEnableAlphaTest(t)) || shadowCutoff == null) ShaderProperty(alphaCutoff, alphaCutoff.displayName);
            }

            if (shadowCutoff != null)
            {
                allProps.Remove(shadowCutoff);
                if (geomTypes.Any(t => ShouldEnableAlphaTest(t))) ShaderProperty(shadowCutoff, shadowCutoff.displayName);
            }

            DrawUILine(smLineColor, 1, smLinePadding);

            //--------------
        }


        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


        void SpecularMap(List<MaterialProperty> allProps)
        {
            //--------------

            MaterialProperty specMap = allProps.Find(prop => prop.name == "_SpecMap");
            MaterialProperty specMapInts = allProps.Find(prop => prop.name == "_SpecMapInts");
            MaterialProperty shininess = allProps.Find(prop => prop.name == "_Shininess");
            MaterialProperty gloss = allProps.Find(prop => prop.name == "_Gloss");
            MaterialProperty specColorMat = allProps.Find(prop => prop.name == "_SpecColor");

            if (specMap != null && specMapInts != null && shininess != null && specColorMat != null)
            {
                allProps.Remove(specMap);
                allProps.Remove(specMapInts);
                allProps.Remove(shininess);
                allProps.Remove(gloss);
                allProps.Remove(specColorMat);

                IEnumerable<bool> enableSpecMap = targets.Select(t => ((Material)t).shaderKeywords.Contains("EFFECT_SPECULAR"));
                bool? enable = EditorGUILayout.Toggle("Specular Map", enableSpecMap.First());

                if (enableSpecMap.First())
                {
                    ShaderProperty(specMap, specMap.displayName);
                    ShaderProperty(specMapInts, specMapInts.displayName);
                    ShaderProperty(shininess, shininess.displayName);
                    ShaderProperty(gloss, gloss.displayName);
                    ShaderProperty(specColorMat, specColorMat.displayName);
                }

                if (enable != null)
                {
                    foreach (Material m in targets.Cast<Material>())
                    {
                        if (enable.Value) m.EnableKeyword("EFFECT_SPECULAR");
                        else m.DisableKeyword("EFFECT_SPECULAR");
                    }
                }
            }

            DrawUILine(smLineColor, 1, smLinePadding);

            //--------------
        }


        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


        void OcclusionMap(List<MaterialProperty> allProps)
        {
            //--------------

            MaterialProperty occlusionMap = allProps.Find(prop => prop.name == "_OcclusionMap");
            MaterialProperty nntensityOC = allProps.Find(prop => prop.name == "_IntensityOc");

            if (occlusionMap != null && nntensityOC != null)
            {
                allProps.Remove(occlusionMap);
                allProps.Remove(nntensityOC);

                IEnumerable<bool> enableOcclusion = targets.Select(t => ((Material)t).shaderKeywords.Contains("EFFECT_OCLUSION"));
                bool? enable = EditorGUILayout.Toggle("Occlusion Map", enableOcclusion.First());

                if (enableOcclusion.First())
                {
                    ShaderProperty(occlusionMap, occlusionMap.displayName);
                    ShaderProperty(nntensityOC, nntensityOC.displayName);
                }

                if (enable != null)
                {
                    foreach (Material m in targets.Cast<Material>())
                    {
                        if (enable.Value) m.EnableKeyword("EFFECT_OCLUSION");
                        else m.DisableKeyword("EFFECT_OCLUSION");
                    }
                }
            }

            DrawUILine(smLineColor, 1, smLinePadding);

            //--------------
        }


        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


        void EmissionMap(List<MaterialProperty> allProps)
        {
            //--------------

            MaterialProperty emissionTex = allProps.Find(prop => prop.name == "_EmissionTex");
            MaterialProperty emissionColorMat = allProps.Find(prop => prop.name == "_EmissionColor");

            if (emissionTex != null && emissionColorMat != null)
            {
                allProps.Remove(emissionTex);
                allProps.Remove(emissionColorMat);

                IEnumerable<bool> enableemissionTex = targets.Select(t => ((Material)t).shaderKeywords.Contains("EFFECT_EMISSION"));
                bool? enable = EditorGUILayout.Toggle("Emission Map (Subsurface)", enableemissionTex.First());

                if (enableemissionTex.First())
                {
                    ShaderProperty(emissionTex, emissionTex.displayName);
                    ShaderProperty(emissionColorMat, emissionColorMat.displayName);
                }

                if (enable != null)
                {
                    foreach (Material m in targets.Cast<Material>())
                    {
                        if (enable.Value) m.EnableKeyword("EFFECT_EMISSION");
                        else m.DisableKeyword("EFFECT_EMISSION");
                    }
                }
            }

            DrawUILine(smLineColor, 1, smLinePadding);

            //--------------
        }


        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


        void BumpMap(List<MaterialProperty> allProps)
        {
            //--------------

            MaterialProperty bumpMap = allProps.Find(prop => prop.name == "_BumpMap");
            MaterialProperty nntensityNm = allProps.Find(prop => prop.name == "_IntensityNm");

            if (bumpMap != null && nntensityNm != null)
            {
                allProps.Remove(bumpMap);
                allProps.Remove(nntensityNm);

                IEnumerable<bool> enableBump = targets.Select(t => ((Material)t).shaderKeywords.Contains("EFFECT_BUMP"));
                bool? enable = EditorGUILayout.Toggle("Normal Map", enableBump.First());

                if (enableBump.First())
                {
                    ShaderProperty(bumpMap, bumpMap.displayName);
                    ShaderProperty(nntensityNm, nntensityNm.displayName);
                }

                if (enable != null)
                {
                    foreach (Material m in targets.Cast<Material>())
                    {
                        if (enable.Value) m.EnableKeyword("EFFECT_BUMP");
                        else m.DisableKeyword("EFFECT_BUMP");
                    }
                }
            }

            //--------------
        }


        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


        void ColorLightTuning(List<MaterialProperty> allProps)
        {
            //--------------

            MaterialProperty light = allProps.Find(prop => prop.name == "_Light");
            MaterialProperty brightness = allProps.Find(prop => prop.name == "_Brightness");
            MaterialProperty saturation = allProps.Find(prop => prop.name == "_Saturation");
            MaterialProperty contrast = allProps.Find(prop => prop.name == "_Contrast");

            if (light != null && brightness != null && saturation != null && contrast != null)
            {
                allProps.Remove(light);
                allProps.Remove(brightness);
                allProps.Remove(saturation);
                allProps.Remove(contrast);

                IEnumerable<bool> enablColorTun = targets.Select(t => ((Material)t).shaderKeywords.Contains("COLOR_TUNING"));
                bool? enable = EditorGUILayout.Toggle("Enable Tuning", enablColorTun.First());

                if (enablColorTun.First())
                {
                    ShaderProperty(light, light.displayName);
                    ShaderProperty(brightness, brightness.displayName);
                    ShaderProperty(saturation, saturation.displayName);
                    ShaderProperty(contrast, contrast.displayName);
                }

                if (enable != null)
                {
                    foreach (Material m in targets.Cast<Material>())
                    {
                        if (enable.Value) m.EnableKeyword("COLOR_TUNING");
                        else m.DisableKeyword("COLOR_TUNING");
                    }
                }
            }

            //--------------
        }


        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


        void WindSettings(List<MaterialProperty> allProps)
        {
            //--------------

            MaterialProperty windQuality = allProps.Find(prop => prop.name == "_WindQuality");
            float windType = windQuality.floatValue;

            if (windQuality != null)
            {
                allProps.Remove(windQuality);
                ShaderProperty(windQuality, windQuality.displayName);
            }

            //--------------

            MaterialProperty windSpeed = allProps.Find(prop => prop.name == "_WindSpeed");
            MaterialProperty windAmplitude = allProps.Find(prop => prop.name == "_WindAmplitude");
            MaterialProperty windDegreeSlope = allProps.Find(prop => prop.name == "_WindDegreeSlope");
            MaterialProperty windConstantTilt = allProps.Find(prop => prop.name == "_WindConstantTilt");

            if (windSpeed != null)
            {
                allProps.Remove(windSpeed);
                if (windType >= 1) ShaderProperty(windSpeed, windSpeed.displayName);
            }

            if (windAmplitude != null)
            {
                allProps.Remove(windAmplitude);
                if (windType >= 1) ShaderProperty(windAmplitude, windAmplitude.displayName);
            }

            if (windDegreeSlope != null)
            {
                allProps.Remove(windDegreeSlope);
                if (windType >= 1) ShaderProperty(windDegreeSlope, windDegreeSlope.displayName);
            }

            if (windConstantTilt != null)
            {
                allProps.Remove(windConstantTilt);
                if (windType >= 1) ShaderProperty(windConstantTilt, windConstantTilt.displayName);
            }

            if (windType >= 1 && billboard == false) DrawUILine(smLineColor, 1, smLinePadding);

            //--------------

            MaterialProperty leafRipple = allProps.Find(prop => prop.name == "_LeafRipple");
            MaterialProperty leafRippleSpeed = allProps.Find(prop => prop.name == "_LeafRippleSpeed");
            MaterialProperty leafTumble = allProps.Find(prop => prop.name == "_LeafTumble");
            MaterialProperty leafTumbleSpeed = allProps.Find(prop => prop.name == "_LeafTumbleSpeed");

            if (leafRipple != null)
            {
                allProps.Remove(leafRipple);
                if (windType >= 2 && windType < 5) ShaderProperty(leafRipple, leafRipple.displayName);
            }

            if (leafRippleSpeed != null)
            {
                allProps.Remove(leafRippleSpeed);
                if (windType >= 2 && windType < 5) ShaderProperty(leafRippleSpeed, leafRippleSpeed.displayName);
            }

            if (leafTumble != null)
            {
                allProps.Remove(leafTumble);
                if (windType == 4) ShaderProperty(leafTumble, leafTumble.displayName);
            }

            if (leafTumbleSpeed != null)
            {
                allProps.Remove(leafTumbleSpeed);
                if (windType == 4) ShaderProperty(leafTumbleSpeed, leafTumbleSpeed.displayName);
            }

            //--------------

            MaterialProperty branchRipple = allProps.Find(prop => prop.name == "_BranchRipple");
            MaterialProperty branchRippleSpeed = allProps.Find(prop => prop.name == "_BranchRippleSpeed");
            MaterialProperty branchTwitch = allProps.Find(prop => prop.name == "_BranchTwitch");
            MaterialProperty branchWhip = allProps.Find(prop => prop.name == "_BranchWhip");
            MaterialProperty branchTurbulences = allProps.Find(prop => prop.name == "_BranchTurbulences");
            MaterialProperty branchForceHeaviness = allProps.Find(prop => prop.name == "_BranchForceHeaviness");
            MaterialProperty branchHeaviness = allProps.Find(prop => prop.name == "_BranchHeaviness");

            if (branchRipple != null)
            {
                allProps.Remove(branchRipple);
                if (windType >= 3) ShaderProperty(branchRipple, branchRipple.displayName);
            }

            if (branchRippleSpeed != null)
            {
                allProps.Remove(branchRippleSpeed);
                if (windType >= 3) ShaderProperty(branchRippleSpeed, branchRippleSpeed.displayName);
            }

            if (branchTwitch != null)
            {
                allProps.Remove(branchTwitch);
                if (windType >= 3) ShaderProperty(branchTwitch, branchTwitch.displayName);
            }

            if (branchWhip != null)
            {
                allProps.Remove(branchWhip);
                if (windType == 5) ShaderProperty(branchWhip, branchWhip.displayName);
            }

            if (branchTurbulences != null)
            {
                allProps.Remove(branchTurbulences);
                if (windType == 5) ShaderProperty(branchTurbulences, branchTurbulences.displayName);
            }

            if (branchForceHeaviness != null)
            {
                allProps.Remove(branchForceHeaviness);
                if (windType == 5) ShaderProperty(branchForceHeaviness, branchForceHeaviness.displayName);
            }

            if (branchHeaviness != null)
            {
                allProps.Remove(branchHeaviness);
                if (windType == 5) ShaderProperty(branchHeaviness, branchHeaviness.displayName);
            }

            //--------------
        }


        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


        void Header()
        {
            //--------------

            EditorGUILayout.Space();
            EditorGUILayout.Space();
            GUIStyle guiStyle = new GUIStyle();
            guiStyle.fontSize = 17;
            EditorGUILayout.LabelField("#NVJOB STC7 (v3.2)", guiStyle);
            DrawUILine(bgLineColor, 2, bgLinePadding);

            //--------------
        }


        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


        void Information()
        {
            //--------------

            DrawUILine(bgLineColor, 2, bgLinePadding);
            if (GUILayout.Button("Description and Instructions")) Help.BrowseURL("https://nvjob.github.io/unity/nvjob-stc-7");
            if (GUILayout.Button("#NVJOB Store")) Help.BrowseURL("https://nvjob.github.io/store/");
            DrawUILine(bgLineColor, 2, bgLinePadding);

            //--------------
        }


        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


        public static void DrawUILine(Color color, int thickness = 2, int padding = 10)
        {
            //--------------

            Rect line = EditorGUILayout.GetControlRect(GUILayout.Height(padding + thickness));
            line.height = thickness;
            line.y += padding / 2;
            line.x -= 2;
            EditorGUI.DrawRect(line, color);

            //--------------
        }


        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    }
}
