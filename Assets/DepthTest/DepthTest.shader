// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "SP/DepthTest"
{
	Properties
	{
		[HDR]_TintColor ("Tint Color", Color) = (0.5,0.5,0.5,0.5)
		_MainTex ("Particle Texture", 2D) = "white" {}
		_InvFade ("Soft Particles Factor", Range(0.0,10.0)) = 1.0
		[KeywordEnum(UnityEye,Unity01,CustomEye,Custom01)] _DepthType("DepthType", Float) = 0
		[Toggle(_DEBUGDEPTH_ON)] _DebugDepth("DebugDepth", Float) = 0		
	}


	Category 
	{
		SubShader
		{
			Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "PreviewType"="Plane" }
			Blend SrcAlpha OneMinusSrcAlpha
			//ColorMask RGB
			Cull Off
			Lighting Off 
			ZWrite Off
			ZTest LEqual
			
			Pass {
			
				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#pragma target 2.0
				#pragma multi_compile_particles
				#pragma multi_compile_fog

				#pragma shader_feature _DEBUGDEPTH_ON
				#pragma shader_feature _DEPTHTYPE_UNITYEYE _DEPTHTYPE_UNITY01 _DEPTHTYPE_CUSTOMEYE _DEPTHTYPE_CUSTOM01

				#include "UnityCG.cginc"

				struct appdata_t 
				{
					float4 vertex : POSITION;
					fixed4 color : COLOR;
					float4 texcoord : TEXCOORD0;
					UNITY_VERTEX_INPUT_INSTANCE_ID
					
				};

				struct v2f 
				{
					float4 vertex : SV_POSITION;
					fixed4 color : COLOR;
					float4 texcoord : TEXCOORD0;
					UNITY_FOG_COORDS(1)
					//#ifdef SOFTPARTICLES_ON
					float4 projPos : TEXCOORD2;
					//#endif
					float4 screenPos : TEXCOORD3;
					UNITY_VERTEX_INPUT_INSTANCE_ID
					UNITY_VERTEX_OUTPUT_STEREO
					
				};
				
				
				#if UNITY_VERSION >= 560
				UNITY_DECLARE_DEPTH_TEXTURE( _CameraDepthTexture );
				#else
				uniform sampler2D_float _CameraDepthTexture;
				#endif

				//Don't delete this comment
				// uniform sampler2D_float _CameraDepthTexture;

				uniform sampler2D _MainTex;
				uniform fixed4 _TintColor;
				uniform float4 _MainTex_ST;
				uniform float _InvFade;

				uniform sampler2D_float _DepthTexture;
				
				v2f vert ( appdata_t v  )
				{
					v2f o;
					UNITY_SETUP_INSTANCE_ID(v);
					UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
					UNITY_TRANSFER_INSTANCE_ID(v, o);
					

					v.vertex.xyz +=  float3( 0, 0, 0 ) ;
					o.vertex = UnityObjectToClipPos(v.vertex);
					//#ifdef SOFTPARTICLES_ON
						o.projPos = ComputeScreenPos (o.vertex);
						COMPUTE_EYEDEPTH(o.projPos.z);
					//#endif

					o.screenPos = ComputeScreenPos (o.vertex);
					o.screenPos.z = COMPUTE_DEPTH_01;

					o.color = v.color;
					o.texcoord = v.texcoord;
					UNITY_TRANSFER_FOG(o,o.vertex);
					return o;
				}

				inline void DepthTest(v2f input)
				{
					float depth = Linear01Depth(SAMPLE_DEPTH_TEXTURE_PROJ(_DepthTexture, UNITY_PROJ_COORD(input.screenPos)));
					clip(depth - input.screenPos.z + 0.001);
				}

				fixed4 frag ( v2f i  ) : SV_Target
				{
					//DepthTest(i);

					#if defined(_DEPTHTYPE_UNITYEYE)
						_InvFade = 0.01;
						float sceneZ = LinearEyeDepth (SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos)));
						float partZ = i.projPos.z;
						float fade = saturate (_InvFade * abs(sceneZ-partZ));
						i.color.a *= fade;
					#elif defined(_DEPTHTYPE_UNITY01)
						_InvFade = 1;
						float sceneZ = Linear01Depth (SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.screenPos)));
						float partZ = i.screenPos.z;
						float fade = saturate (_InvFade * abs(sceneZ-partZ));
						i.color.a *= fade;
					#elif defined(_DEPTHTYPE_CUSTOMEYE)
						_InvFade = 0.01;
						float sceneZ = LinearEyeDepth (SAMPLE_DEPTH_TEXTURE_PROJ(_DepthTexture, UNITY_PROJ_COORD(i.projPos)));
						float partZ = i.projPos.z;
						float fade = saturate (_InvFade * abs(sceneZ-partZ));
						i.color.a *= fade;
					#elif defined(_DEPTHTYPE_CUSTOM01)
						_InvFade = 1;
						float sceneZ =  Linear01Depth(SAMPLE_DEPTH_TEXTURE_PROJ(_DepthTexture, UNITY_PROJ_COORD(i.screenPos)));
						float partZ = i.screenPos.z;
						float fade = saturate (_InvFade * abs(sceneZ-partZ));
						i.color.a *= fade;
					#endif

					#ifdef _DEBUGDEPTH_ON
						fixed depthColor = fade;
						return fixed4(depthColor, depthColor, depthColor, 1);
					#endif

					fixed4 col = 2.0f * i.color * _TintColor * tex2D(_MainTex, i.texcoord.xy*_MainTex_ST.xy + _MainTex_ST.zw );
					UNITY_APPLY_FOG(i.fogCoord, col);
					return col;
				}
				ENDCG 
			}
		}	
	}
	CustomEditor "ASEMaterialInspector"
}
