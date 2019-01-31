
Shader "Hidden/WaterMaskMapCompareDepth" {
	Properties {
		_SceneDepthTexture ("depth", 2D) = "white" {}
		_WaterDepthTexture ("depth", 2D) = "white" {}
		_DepthFactor ("DepthFactor", Float) = 1
	}
	
	SubShader {
		
		Tags { "RenderType"="Qpaque" "IgnoreProjector"="True" "PreviewType"="Plane"}
		Pass{
		
		LOD 200

		Cull Off
		Fog { Mode Off}
		Lighting Off
		ZTest Off

		CGPROGRAM
		#pragma exclude_renderers gles
		#include "UnityCG.cginc"
 		#pragma vertex vert
		#pragma fragment frag

      	sampler2D _SceneDepthTexture;
		sampler2D _WaterDepthTexture;
		float _DepthFactor;

 		struct v2f 
		{
			half4 pos : SV_POSITION;
			float4 projPos : TEXCOORD2;
  	  	};
 
		v2f vert(appdata_base v)
		{
			v2f o;
			UNITY_INITIALIZE_OUTPUT(v2f, o);
			o.pos = UnityObjectToClipPos (v.vertex);			
			o.projPos = ComputeScreenPos (o.pos);

 		 	return o;
 		}

		half4 frag( v2f i ) : SV_Target
		{
			float sceneZ = Linear01Depth (SAMPLE_DEPTH_TEXTURE_PROJ(_SceneDepthTexture, UNITY_PROJ_COORD(i.projPos)));
			float waterZ = Linear01Depth (SAMPLE_DEPTH_TEXTURE_PROJ(_WaterDepthTexture, UNITY_PROJ_COORD(i.projPos)));
			float depth = saturate (1-_DepthFactor *(waterZ-sceneZ));
			return fixed4(depth, depth, depth, 1);
   		}

 		ENDCG
		} 
	}
}
