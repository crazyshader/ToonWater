using UnityEngine;
using UnityEngine.Rendering;

public class ToonWater : MonoBehaviour
{
    public Camera DepthCamera;

    void Start ()
	{
        DepthCamera.depthTextureMode |= DepthTextureMode.Depth;

        /*
        RenderTexture colorBufferRT = new RenderTexture(Screen.width, Screen.height, 0);
        colorBufferRT.Create();
        RenderTexture depthBufferRT = new RenderTexture(Screen.width, Screen.height, 24, RenderTextureFormat.Depth);
        depthBufferRT.Create();
        DepthCamera.SetTargetBuffers(colorBufferRT.colorBuffer, depthBufferRT.depthBuffer);

        {
            CommandBuffer command = new CommandBuffer();
            command.name = "Set depth texture";
            command.SetGlobalTexture("_SceneDepthTexture", depthBufferRT);
            DepthCamera.AddCommandBuffer(CameraEvent.AfterSkybox, command);
        }
        
        {
            CommandBuffer command = new CommandBuffer();
            command.name = "blit to Back buffer";
            command.SetRenderTarget(BuiltinRenderTextureType.CameraTarget);
            command.Blit(colorBufferRT, BuiltinRenderTextureType.CurrentActive);
            //command.SetGlobalTexture("_SceneColorTexture", m_ColorBuffer);
            DepthCamera.AddCommandBuffer(CameraEvent.AfterEverything, command);
        }
        */
    }
}