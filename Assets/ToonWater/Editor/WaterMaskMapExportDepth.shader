
Shader "Hidden/WaterMaskMapExportDepth" {
	Properties
	{
		_DepthScale("Depth Scale", Range(0,1)) = 1
	}

	SubShader {
		
		Tags { "RenderType"="Qpaque" "IgnoreProjector"="True" "PreviewType"="Plane"}
		Pass{
		
		LOD 200

		Fog { Mode Off}
		Lighting Off

		CGPROGRAM
		#include "UnityCG.cginc"
 		#pragma vertex vert
		#pragma fragment frag

      	sampler2D _CameraDepthTexture;
		float _DepthScale;

 		struct v2f 
		{
			half4 pos : SV_POSITION;
			float4 scrPos:TEXCOORD0;
  	  	};
 
		v2f vert (appdata_base v)
		{
			v2f o;
			UNITY_INITIALIZE_OUTPUT(v2f, o);
			o.pos = UnityObjectToClipPos (v.vertex);
			o.scrPos = ComputeScreenPos(o.pos);

			return o;
		}

		half4 frag(v2f i) : COLOR
		{
			float depth = Linear01Depth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.scrPos)));
			depth = saturate(depth * _DepthScale);
			return float4(depth, depth, depth, 1.0f);
		}
 		ENDCG
		} 
	}
	FallBack "Diffuse"
}
