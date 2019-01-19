
Shader "SP/Toon/Water/Style1"
{
	Properties
    {
		//[Header(Debug)]
		//[Toggle(_DEBUG_MODE)] _Debug_Mode("Use Debug Mode?", float) = 0
		//_DepthScale("Depth Scale", Range(0,1)) = 1

		[Header(Wave)]
		_WaveScale ("Wave Scale", Range(0.1,10) ) = 0.1
        _WaveStrength ("Wave Strength", Range(0.1,1) ) = 1
        //_WaveStep ("Wave Step", Float ) = 4
        //_WaveFactor ("Wave Factor", Range(0.2,0.3) ) = 0.25
        _WaveSpeedx1y1x2y2 ("Wave Speed x1 y1 x2 y2", Vector) = (0.005,0.004,-0.005,-0.004)
        _WaveMap ("Wave Map", 2D) = "white" {}
		
		[Header(Depth)]
        _DeepWaterColor ("Deep Water Color", Color) = (0.5,0.5,0.5,1)
        _DeepWaterDepth ("Deep Water Depth", Range(0.1, 5) ) = 1
        _ShallowWaterColor ("Shallow Water Color", Color) = (0.5,0.5,0.5,1)
        _ShallowWaterDepth ("Shallow Water Depth", Range(0.1, 3) ) = 0.8
        [NoScaleOffset] _DepthMap ("Depth Map", 2D) = "white" {}
		
        _MiddleWaterColor ("Middle Water Color", Color) = (0.5,0.5,0.5,1)
        _MiddleWaterDepth ("Middle Water Depth", Float ) = 0.4
		_EdgeWaterDepth ("Edge Water Depth", Float ) = 0.015
_DeepWaterOpacity ("Deep Water Opacity(0, 1)", Range(0, 1)) = 0.95

		[Header(Light)]
		_CustomLightIntensity("Light Intensity", Range(0.5,1.5)) = 1
		_CustomLightColor("Light Color", Color) = (0.5, 0.5, 0.5, 1)
		_CustomLightDir("Light Dir", Vector) = (1,1,1,1)

		[Header(Foam)]
		_FoamSpeed ("Foam Speed", Range (0, 0.5)) = 0.15
		_FoamStrength ("Foam Strength", Range (0.1, 1.0)) = 1.0
		//[NoScaleOffset] _BumpMap ("Normal Map ", 2D) = "bump" {}
		[NoScaleOffset] _FoamMap ("Foam Texture", 2D) = "white" {}
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
		//float4 bumpuv : TEXCOORD2;
		//float3 viewDir : TEXCOORD2;
		float2 foamuv : TEXCOORD3;
    };


    //uniform sampler2D_float _CameraDepthTexture;
   // uniform sampler2D_float _SceneDepthTexture;
	//uniform float4 _SceneDepthTexture_ST;

	//uniform float _WaveStep;
	uniform float _WaveScale;
	uniform float _WaveStrength;
	//uniform float _WaveFactor;
    uniform float4 _TimeEditor;
    uniform sampler2D _WaveMap;
	uniform float4 _WaveMap_ST;
    uniform float4 _WaveSpeedx1y1x2y2;

    uniform float4 _DeepWaterColor;
    uniform float _DeepWaterDepth;
    uniform float4 _ShallowWaterColor;
    uniform float _ShallowWaterDepth;
    uniform sampler2D _DepthMap;
	uniform float4 _DepthMap_ST;
	uniform float _DepthScale;

	uniform half   _CustomLightIntensity;
	uniform fixed4 _CustomLightColor;
	uniform float4 _CustomLightDir;

	//uniform sampler2D _BumpMap;
	uniform sampler2D _FoamMap;
	uniform sampler2D _FoamGradientMap;
	uniform float _FoamStrength;	  
	uniform float _FoamSpeed;
			
	uniform float _MiddleWaterDepth;
            uniform float4 _MiddleWaterColor;
	uniform float _EdgeWaterDepth;
            uniform float _DeepWaterOpacity;

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
        Tags {"Queue" = "Transparent"}
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
				//o.bumpuv = wpos.xzxz * float4(1, 1, 0.6, 0.6);
				o.foamuv = 7.0f * wpos.xz + 0.05 * float2(_SinTime.w, _SinTime.w);
				//o.viewDir = normalize(UnityWorldSpaceViewDir(mul(unity_ObjectToWorld, v.vertex)));

                return o;
            }
            
            fixed4 frag (v2f i) : COLOR
            {
			    float3 lightDirection = normalize(_CustomLightDir.xyz);
                float NdotL = max(0.0,dot( float3(0,1,0), lightDirection ));
                float3 directDiffuse = NdotL * _CustomLightColor.xyz * _CustomLightIntensity;

				float4 flowUV = float4(1, 1, 0.6, 0.6) * i.texcoord.xyxy + _WaveSpeedx1y1x2y2 * _Time.r;
                float4 height1 = tex2D(_WaveMap,TRANSFORM_TEX(flowUV.rg, _WaveMap));
                float4 height2 = tex2D(_WaveMap,TRANSFORM_TEX(flowUV.ba, _WaveMap));
                float3 height = saturate(height1.rgb + height2.rgb) *  0.25;

				#if _DEBUG_MODE
					float sceneZ= LinearEyeDepth (SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.scrPos)));
					float depth = saturate(_DepthScale * (sceneZ - i.scrPos.z));
				#else
					/*
					float2 depthUV = i.texcoord;
					#if UNITY_UV_STARTS_AT_TOP
						depthUV.x = 1 - depthUV.x;
						depthUV.y = 1 - depthUV.y;
					#endif
					//float sceneZ = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_SceneDepthTexture, i.texcoord));
					float sceneZ = LinearEyeDepth (SAMPLE_DEPTH_TEXTURE_PROJ(_SceneDepthTexture, UNITY_PROJ_COORD(i.scrPos)));
					float depth = saturate(_DepthScale * (sceneZ - i.scrPos.z));
					*/

					// On D3D when AA is used, the main texture and scene depth texture
					// will come out in different vertical orientations.
					// So flip sampling of the texture when that is the case (main texture
					// texel size will have negative Y).
					float2 depthUV = i.texcoord;
					//#if UNITY_UV_STARTS_AT_TOP
						depthUV.x = 1 - depthUV.x;
						depthUV.y = 1 - depthUV.y;
					//#endif
					float depth = tex2D(_DepthMap, TRANSFORM_TEX(depthUV, _DepthMap)).r;

				#endif

				float4 finalColor = float4(0, 0, 0, 1);
				float3 temp = 1.0 - floor(height * 4) * 0.33;
				float4 middleDeepColor = lerp(_ShallowWaterColor, _DeepWaterColor, saturate(depth/_DeepWaterDepth));
				float4 edgeMiddleColor = lerp(float4(1,1,1,0), middleDeepColor, saturate(depth/_ShallowWaterDepth));
                float4 diffuseColor = 1.0 - (1.0 - edgeMiddleColor) * float4(temp, 1);
                diffuseColor.rgb = (directDiffuse + UNITY_LIGHTMODEL_AMBIENT.rgb) * diffuseColor.rgb;
				finalColor = diffuseColor;

				//float3 Normal =  float3(0,1,0);
				//half3 halfVector = normalize(lightDirection + i.viewDir);
				//float diffFactor = max(0, dot(lightDirection, Normal)) * 0.8 + 0.2;
				//float nh = max(0, dot(halfVector, Normal));
				//float spec = pow(nh, _Specular * 128.0) * _Gloss;
				//finalColor.rgb = ((UNITY_LIGHTMODEL_AMBIENT.rgb + finalColor.rgb * _CustomLightColor.rgb * diffFactor) * diffuseColor.rgb + _SpecColor.rgb * spec * _CustomLightColor.rgb) * _CustomLightIntensity;
				//finalColor.a = finalColor.a + spec * _SpecColor.a;




				//half3 bump1 = UnpackNormal(tex2D( _BumpMap, i.bumpuv.xy)).rgb;
				//half3 bump2 = UnpackNormal(tex2D( _BumpMap, i.bumpuv.zw)).rgb;
				//half3 bump = (bump1 + bump2) * 0.5;

				float intensityFactor = 1 - saturate(depth / _FoamStrength);    
				half3 foamGradient = 1 - tex2D(_FoamGradientMap, float2(intensityFactor - _Time.y*_FoamSpeed, 0));
				//half3 foamColor = tex2D(_FoamMap, i.foamuv).rgb;
				//finalColor.rgb += foamGradient * intensityFactor * foamColor;
				finalColor.rgb += foamGradient * intensityFactor;


				//half3 foamGradient = 1 - tex2D(_FoamGradientMap, float2(intensityFactor - _Time.y*0.15, 0) + bump.xy * 0.15);
				//float2 foamDistortUV = bump.xy * 0.2;
				//half3 foamColor = tex2D(_FoamMap, i.foamuv + foamDistortUV).rgb;
				//half foamLightIntensity = saturate((_WorldSpaceLightPos0.y + 0.2) * 4);
				//finalColor.rgb += foamGradient * intensityFactor * foamColor * foamLightIntensity;

				return finalColor;
            }
            ENDCG
        }
    }

	SubShader
    {
        Tags {"Queue" = "Transparent"}
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
                float3 lightDirection = normalize(_CustomLightDir.xyz);
                float NdotL = max(0.0,dot( float3(0,1,0), lightDirection ));
                float3 directDiffuse = NdotL * _CustomLightColor.xyz * _CustomLightIntensity;

				float4 flowUV = float4(1, 1, 0.6, 0.6) * i.texcoord.xyxy + _WaveSpeedx1y1x2y2 * _Time.r;
                float4 height1 = tex2D(_WaveMap,TRANSFORM_TEX(flowUV.rg, _WaveMap));
                float4 height2 = tex2D(_WaveMap,TRANSFORM_TEX(flowUV.ba, _WaveMap));
                float3 height = saturate(height1.rgb + height2.rgb) * 0.25;

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
					float depth = tex2D(_DepthMap, TRANSFORM_TEX(depthUV, _DepthMap)).r;
				#endif

				float _WaveStep = 4;
				float3 temp = 1.0 - floor(height * _WaveStep) / (_WaveStep - 1);
				float4 middleDeepColor = lerp(_ShallowWaterColor, _DeepWaterColor, saturate(depth/_DeepWaterDepth));
				float4 edgeMiddleColor = lerp(float4(1,1,1,0), middleDeepColor, saturate(depth/_ShallowWaterDepth));
                float4 diffuseColor = 1.0 - (1.0 - edgeMiddleColor) * float4(temp, 1);
                diffuseColor.rgb = (directDiffuse + UNITY_LIGHTMODEL_AMBIENT.rgb) * diffuseColor.rgb;

				return diffuseColor;
            }
            ENDCG
        }
    }

	SubShader
    {
        Tags {"Queue" = "Transparent"}
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
                float3 lightDirection = normalize(_CustomLightDir.xyz);
                float NdotL = max(0.0,dot( float3(0,1,0), lightDirection ));
                float3 directDiffuse = NdotL * _CustomLightColor.xyz * _CustomLightIntensity;

				float _WaveStep = 4;
				float4 flowUV = float4(1, 1, 0.6, 0.6) * i.texcoord.xyxy + _WaveSpeedx1y1x2y2 * _Time.r;
                float4 height1 = tex2D(_WaveMap,TRANSFORM_TEX(flowUV.rg, _WaveMap));
                float4 height2 = tex2D(_WaveMap,TRANSFORM_TEX(flowUV.ba, _WaveMap));
                float3 height = saturate(height1.rgb + height2.rgb) * 0.25;
				float3 temp = 1.0 - floor(height * _WaveStep) / (_WaveStep - 1);
				float3 diffuseColor = (directDiffuse + UNITY_LIGHTMODEL_AMBIENT.rgb);
				diffuseColor *= (_DeepWaterColor.rgb+_ShallowWaterColor) * 0.5;

				return fixed4(diffuseColor, temp.r);
            }

            ENDCG
        }
    }

	FallBack "Diffuse"
}
