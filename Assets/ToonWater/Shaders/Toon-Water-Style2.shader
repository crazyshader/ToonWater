
Shader "SP/Water/ToonWater"
{
	Properties
    {
		[Header(Debug)]
		[Toggle(_DEBUG_MODE)] _Debug_Mode("Use Debug Mode?", float) = 0

		[Header(Wave)]
		_WaveScale ("Wave Scale", float) = 0.1
        _WaveStrength ("Wave Strength", float) = 1
        _WaveSpeedx1y1x2y2 ("Wave Speed x1 y1 x2 y2", Vector) = (0.005,0.004,-0.005,-0.004)
        _WaveMap ("Wave Map", 2D) = "white" {}
		
		[Header(Depth)]
		_DepthScale("Depth Scale", float) = 1
        _DeepWaterColor ("Deep Water Color", Color) = (0.5,0.5,0.5,1)
        _DeepWaterDepth ("Deep Water Depth", float) = 1
        _ShallowWaterColor ("Shallow Water Color", Color) = (0.5,0.5,0.5,1)
        _ShallowWaterDepth ("Shallow Water Depth", float ) = 0.8
        [NoScaleOffset] _DepthMap ("Water Depth Map", 2D) = "white" {}
		
		[Header(Light)]
		_CustomLightIntensity("Light Intensity", float) = 1
		_CustomLightColor("Light Color", Color) = (0.5, 0.5, 0.5, 1)
		_CustomLightDir("Light Direction", Vector) = (1,1,1,1)

		[Header(Foam)]
		_FoamSpeed ("Foam Speed", float) = 0.5
		_FoamStrength ("Foam Strength", float) = 0.5
		[NoScaleOffset] _FoamGradientMap ("Foam Gradient ", 2D) = "white" {}
    }

	CGINCLUDE

    struct a2v
    {
        float4 vertex : POSITION;
        float2 texcoord : TEXCOORD0;
    };

    struct v2f
    {
        float4 vertex : SV_POSITION;
        float2 texcoord : TEXCOORD0;
        float4 scrPos : TEXCOORD1;
		float2 foamuv : TEXCOORD2;
    };

#if _DEBUG_MODE
    uniform sampler2D_float _CameraDepthTexture;
#endif

    uniform float _WaveScale;
    uniform float _WaveStrength;
    uniform sampler2D _WaveMap;
    uniform float4 _WaveMap_ST;
    uniform float4 _WaveSpeedx1y1x2y2;

    uniform float _DepthScale;
    uniform float4 _DeepWaterColor;
    uniform float _DeepWaterDepth;
    uniform float4 _ShallowWaterColor;
    uniform float _ShallowWaterDepth;
    uniform sampler2D _DepthMap;
    uniform float4 _DepthMap_ST;

	uniform half   _CustomLightIntensity;
	uniform fixed4 _CustomLightColor;
	uniform float4 _CustomLightDir;

	uniform sampler2D _FoamGradientMap;
	uniform float _FoamStrength;	  
	uniform float _FoamSpeed;
			
	float calculateSurface(float x, float z, float scale)
	{
		float y = 0.0;
		y += (sin(x * 1.0 / scale + _Time.y * 1.0) + sin(x * 2.3 / scale + _Time.y * 1.5) 
			+ sin(x * 3.3 / scale + _Time.y * 0.4)) / 3.0;
		y += (sin(z * 0.2 / scale + _Time.y * 1.8) + sin(z * 1.8 / scale + _Time.y * 1.8) 
			+ sin(z * 2.8 / scale + _Time.y * 0.8)) / 3.0;
		return y;
	}

	ENDCG

    SubShader
    {
        Tags {"Queue" = "Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "PreviewType"="Plane" }
		LOD 400
		
		Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
			#pragma shader_feature _DEBUG_MODE

            #include "UnityCG.cginc"

            v2f vert (a2v v)
            {
                v2f o;

				v.vertex.y += _WaveStrength * calculateSurface(v.vertex.x, v.vertex.z, _WaveScale);
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.scrPos = ComputeScreenPos(o.vertex);
                COMPUTE_EYEDEPTH(o.scrPos.z);
				o.texcoord = v.texcoord;
				float4 wpos = mul (unity_ObjectToWorld, v.vertex);
				o.foamuv = 7.0f * wpos.xz + 0.05 * float2(_SinTime.w, _SinTime.w);

                return o;
            }
            
            fixed4 frag (v2f i) : COLOR
            {
				#if _DEBUG_MODE
					float sceneZ= LinearEyeDepth (SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.scrPos)));
					float depth = saturate(_DepthScale * (sceneZ - i.scrPos.z));
				#else
					// On D3D when AA is used, the main texture and scene depth texture
					// will come out in different vertical orientations.
					// So flip sampling of the texture when that is the case (main texture
					// texel size will have negative Y).
					float2 depthUV = i.texcoord;
					//#if UNITY_UV_STARTS_AT_TOP
						depthUV.x = 1 - depthUV.x;
						depthUV.y = 1 - depthUV.y;
					//#endif
					float depth = tex2D(_DepthMap, TRANSFORM_TEX(depthUV, _DepthMap)).r * _DepthScale;
				#endif

				float4 flowUV = float4(1, 1, 0.6, 0.6) * i.texcoord.xyxy + _WaveSpeedx1y1x2y2 * _Time.r;
                float4 height1 = tex2D(_WaveMap,TRANSFORM_TEX(flowUV.rg, _WaveMap));
                float4 height2 = tex2D(_WaveMap,TRANSFORM_TEX(flowUV.ba, _WaveMap));
                float3 height = saturate(height1.rgb + height2.rgb) * 0.25;

				float3 temp = 1.0 - floor(height * 4) * 0.33;
				float4 middleDeepColor = lerp(_ShallowWaterColor, _DeepWaterColor, saturate(depth/_DeepWaterDepth));
				float4 edgeMiddleColor = lerp(float4(1,1,1,0), middleDeepColor, saturate(depth/_ShallowWaterDepth));
                float4 diffuseColor = 1.0 - (1.0 - edgeMiddleColor) * float4(temp, 1);
				
                float3 lightDirection = normalize(_CustomLightDir.xyz);
                float NdotL = max(0.0,dot( float3(0,1,0), lightDirection ));
                float3 directDiffuse = NdotL * _CustomLightColor.xyz * _CustomLightIntensity;
                diffuseColor.rgb = (directDiffuse + UNITY_LIGHTMODEL_AMBIENT.rgb) * diffuseColor.rgb;

				float4 finalColor = diffuseColor;
				float intensityFactor = 1 - saturate(depth / _FoamStrength);    
				half3 foamGradient = 1 - tex2D(_FoamGradientMap, float2(intensityFactor - _Time.y * _FoamSpeed, 0));
				finalColor.rgb += foamGradient * intensityFactor;

				return finalColor;
            }
            ENDCG
        }
    }

	SubShader
    {
        Tags {"Queue" = "Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "PreviewType"="Plane" }
		LOD 300

        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
			#pragma shader_feature _DEBUG_MODE

            #include "UnityCG.cginc"

            v2f vert (a2v v)
            {
                v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f, o);
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.scrPos = ComputeScreenPos(o.vertex);
                COMPUTE_EYEDEPTH(o.scrPos.z);
				o.texcoord = v.texcoord;

                return o;
            }
            
            fixed4 frag (v2f i) : COLOR
            {
				#if _DEBUG_MODE
					float sceneZ= LinearEyeDepth (SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.scrPos)));
					float depth = saturate(_DepthScale * (sceneZ - i.scrPos.z));
				#else
					float2 depthUV = i.texcoord;
					//#if UNITY_UV_STARTS_AT_TOP
						depthUV.x = 1 - depthUV.x;
						depthUV.y = 1 - depthUV.y;
					//#endif
					float depth = tex2D(_DepthMap, TRANSFORM_TEX(depthUV, _DepthMap)).r * _DepthScale;
				#endif

				float4 flowUV = float4(1, 1, 0.6, 0.6) * i.texcoord.xyxy + _WaveSpeedx1y1x2y2 * _Time.r;
                float4 height1 = tex2D(_WaveMap,TRANSFORM_TEX(flowUV.rg, _WaveMap));
                float4 height2 = tex2D(_WaveMap,TRANSFORM_TEX(flowUV.ba, _WaveMap));
                float3 height = saturate(height1.rgb + height2.rgb) * 0.25;

				float3 temp = 1.0 - floor(height * 4) * 0.33;
				float4 middleDeepColor = lerp(_ShallowWaterColor, _DeepWaterColor, saturate(depth/_DeepWaterDepth));
				float4 edgeMiddleColor = lerp(float4(1,1,1,0), middleDeepColor, saturate(depth/_ShallowWaterDepth));
                float4 diffuseColor = 1.0 - (1.0 - edgeMiddleColor) * float4(temp, 1);

                float3 lightDirection = normalize(_CustomLightDir.xyz);
                float NdotL = max(0.0,dot( float3(0,1,0), lightDirection ));
                float3 directDiffuse = NdotL * _CustomLightColor.xyz * _CustomLightIntensity;
                diffuseColor.rgb = (directDiffuse + UNITY_LIGHTMODEL_AMBIENT.rgb) * diffuseColor.rgb;

				return diffuseColor;
            }
            ENDCG
        }
    }

	SubShader
    {
        Tags {"Queue" = "Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "PreviewType"="Plane" }
		LOD 200

        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
			#pragma shader_feature _DEBUG_MODE

            #include "UnityCG.cginc"

            v2f vert (a2v v)
            {
                v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f, o);
                o.vertex = UnityObjectToClipPos(v.vertex);
				o.texcoord = v.texcoord;

                return o;
            }
            
            fixed4 frag (v2f i) : COLOR
            {
				float4 flowUV = float4(1, 1, 0.6, 0.6) * i.texcoord.xyxy + _WaveSpeedx1y1x2y2 * _Time.r;
                float4 height1 = tex2D(_WaveMap,TRANSFORM_TEX(flowUV.rg, _WaveMap));
                float4 height2 = tex2D(_WaveMap,TRANSFORM_TEX(flowUV.ba, _WaveMap));
                float3 height = saturate(height1.rgb + height2.rgb) * 0.25;
				float3 temp = 1.0 - floor(height * 4) * 0.33;

                float3 lightDirection = normalize(_CustomLightDir.xyz);
                float NdotL = max(0.0,dot( float3(0,1,0), lightDirection ));
                float3 directDiffuse = NdotL * _CustomLightColor.xyz * _CustomLightIntensity;
				float3 diffuseColor = (directDiffuse + UNITY_LIGHTMODEL_AMBIENT.rgb);
				diffuseColor *= (_DeepWaterColor.rgb+_ShallowWaterColor) * 0.5;

				return fixed4(diffuseColor, saturate(temp.r));
            }

            ENDCG
        }
    }

	FallBack "Mobile/Diffuse"
}
