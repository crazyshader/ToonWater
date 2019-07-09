// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "ToogleShaderTemplate"
{
	Properties
	{
		[KeywordEnum(UnityEye,Unity01,CustomEye,Custom01)] _DepthType("DepthType", Float) = 0
		[Toggle(_DEBUGDEPTH_ON)] _DebugDepth("DebugDepth", Float) = 0
	}
	
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100
		CGINCLUDE
		#pragma target 3.0
		ENDCG
		Blend Off
		Cull Back
		ColorMask RGBA
		ZWrite On
		ZTest LEqual
		Offset 0 , 0
		
		

		Pass
		{
			Name "Unlit"
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_instancing
			#include "UnityCG.cginc"
			#pragma shader_feature _DEBUGDEPTH_ON
			#pragma shader_feature _DEPTHTYPE_UNITYEYE _DEPTHTYPE_UNITY01 _DEPTHTYPE_CUSTOMEYE _DEPTHTYPE_CUSTOM01


			struct appdata
			{
				float4 vertex : POSITION;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				
			};
			
			struct v2f
			{
				float4 vertex : SV_POSITION;
				
				UNITY_VERTEX_OUTPUT_STEREO
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

						
			v2f vert ( appdata v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				UNITY_TRANSFER_INSTANCE_ID(v, o);

				
				
				v.vertex.xyz +=  float3(0,0,0) ;
				o.vertex = UnityObjectToClipPos(v.vertex);
				return o;
			}
			
			fixed4 frag (v2f i ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(i);
				fixed4 finalColor;
				#ifdef _DEBUGDEPTH_ON
				float staticSwitch18 = 1.0;
				#else
				float staticSwitch18 = 0.5;
				#endif
				#if defined(_DEPTHTYPE_UNITYEYE)
				float4 staticSwitch13 = float4(1,0,0,0);
				#elif defined(_DEPTHTYPE_UNITY01)
				float4 staticSwitch13 = float4(0,1,0,0);
				#elif defined(_DEPTHTYPE_CUSTOMEYE)
				float4 staticSwitch13 = float4(0,0,1,0);
				#elif defined(_DEPTHTYPE_CUSTOM01)
				float4 staticSwitch13 = float4(1,1,0,0);
				#else
				float4 staticSwitch13 = float4(1,0,0,0);
				#endif
				
				
				finalColor = ( staticSwitch18 * staticSwitch13 );
				return finalColor;
			}
			ENDCG
		}
	}
	CustomEditor "ASEMaterialInspector"
	
	
}
/*ASEBEGIN
Version=16200
48;142;1324;631;919.9263;450.0289;1.38117;True;True
Node;AmplifyShaderEditor.Vector4Node;14;-690.7109,-209.3773;Float;False;Constant;_Vector0;Vector 0;1;0;Create;True;0;0;False;0;1,0,0,0;0,0,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;21;-450.3284,-168.2703;Float;False;Constant;_Float1;Float 1;2;0;Create;True;0;0;False;0;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;20;-450.3285,-273.2391;Float;False;Constant;_Float0;Float 0;2;0;Create;True;0;0;False;0;0.5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.Vector4Node;15;-685.5708,-17.90178;Float;False;Constant;_Vector1;Vector 1;1;0;Create;True;0;0;False;0;0,1,0,0;0,0,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector4Node;17;-675.2901,345.7732;Float;False;Constant;_Vector3;Vector 3;1;0;Create;True;0;0;False;0;1,1,0,0;0,0,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector4Node;16;-680.4307,173.5737;Float;False;Constant;_Vector2;Vector 2;1;0;Create;True;0;0;False;0;0,0,1,0;0,0,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.StaticSwitch;18;-281.4855,-208.1216;Float;False;Property;_DebugDepth;DebugDepth;1;0;Create;True;0;0;False;0;0;0;0;True;;Toggle;2;Key0;Key1;9;1;FLOAT;0;False;0;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT;0;False;7;FLOAT;0;False;8;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;13;-354.7829,31.33391;Float;False;Property;_DepthType;DepthType;0;0;Create;True;0;0;False;0;0;0;0;True;;KeywordEnum;4;UnityEye;Unity01;CustomEye;Custom01;9;1;FLOAT4;0,0,0,0;False;0;FLOAT4;0,0,0,0;False;2;FLOAT4;0,0,0,0;False;3;FLOAT4;0,0,0,0;False;4;FLOAT4;0,0,0,0;False;5;FLOAT4;0,0,0,0;False;6;FLOAT4;0,0,0,0;False;7;FLOAT4;0,0,0,0;False;8;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;19;-35.14735,-49.03243;Float;False;2;2;0;FLOAT;0;False;1;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;0;157.6433,-52.54037;Float;False;True;2;Float;ASEMaterialInspector;0;1;ToogleShaderTemplate;0770190933193b94aaa3065e307002fa;0;0;Unlit;2;True;0;1;False;-1;0;False;-1;0;1;False;-1;0;False;-1;True;0;False;-1;0;False;-1;True;False;True;0;False;-1;True;True;True;True;True;0;False;-1;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;1;RenderType=Opaque=RenderType;True;2;0;False;False;False;False;False;False;False;False;False;False;False;0;;0;0;Standard;0;2;0;FLOAT4;0,0,0,0;False;1;FLOAT3;0,0,0;False;0
WireConnection;18;1;20;0
WireConnection;18;0;21;0
WireConnection;13;1;14;0
WireConnection;13;0;15;0
WireConnection;13;2;16;0
WireConnection;13;3;17;0
WireConnection;19;0;18;0
WireConnection;19;1;13;0
WireConnection;0;0;19;0
ASEEND*/
//CHKSM=96BD35DF97CAE5848E1FF8E3D35E7A34B2CC3B81