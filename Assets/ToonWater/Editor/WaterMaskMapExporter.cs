using UnityEngine;
using UnityEditor;
using System.Collections.Generic;
using System.IO;

public class WaterMaskData
{
    public static float maskMapSize
    {
        get { return EditorPrefs.GetFloat("Water_MaskMapSize", 256); }
        set { EditorPrefs.SetFloat("Water_MaskMapSize", value); }
    }

    public static float depthScale
    {
        get { return EditorPrefs.GetFloat("Water_DepthScale", 9); }
        set { EditorPrefs.SetFloat("Water_DepthScale", value); }
    }

    public static bool checkCameraPos
    {
        get { return EditorPrefs.GetBool("Water_CheckCameraPos", false); }
        set { EditorPrefs.SetBool("Water_CheckCameraPos", value); }
    }

    public static float cameraYPos
    {
        get { return EditorPrefs.GetFloat("Water_CameraYPos", 0); }
        set { EditorPrefs.SetFloat("Water_CameraYPos", value); }
    }
}

public class WaterMaskMapExporter : EditorWindow
{
    private GameObject objectNeedExport;
    private int objectNeedExportLayer;
    private GameObject waterExportObj;
    private RenderTexture rt1;
    private RenderTexture rt2;
    private RenderTexture rt3;

    struct reInfo
    {
        public GameObject obj;
        public int layer;
        public Renderer re;
        public int index;
        public Shader sh;
    };
    List<reInfo> reInfoList;

    struct terrainInfo
    {
        public GameObject obj;
        public int layer;
    }
    List<terrainInfo> teInfoList;


    [MenuItem("Tools/Water/ExportWaterMaskMap")]
    public static void ShowWindow()
    {
        EditorWindow.GetWindow(typeof(WaterMaskMapExporter));
    }
    
    void OnGUI()
    {
        GUILayout.Label("Attention!\nmake sure the position of water object you select is right", EditorStyles.boldLabel);

        objectNeedExport = EditorGUILayout.ObjectField("Object to Export", objectNeedExport,typeof(GameObject) , true) as GameObject;
        WaterMaskData.maskMapSize = EditorGUILayout.FloatField("Water Mask Map Size", WaterMaskData.maskMapSize);
        WaterMaskData.depthScale = EditorGUILayout.FloatField("Water Depth Scale", WaterMaskData.depthScale);
        WaterMaskData.checkCameraPos = EditorGUILayout.ToggleLeft("Manual Check Camera Position", WaterMaskData.checkCameraPos);
        WaterMaskData.cameraYPos = EditorGUILayout.FloatField("    Camera Y Position", WaterMaskData.cameraYPos);

        Export();    
    }
    
    void Export()
    {
        if (GUILayout.Button("Export") == false)
            return;

        if (Application.isPlaying==false)
        {
            EditorUtility.DisplayDialog("Error", "This Function MUST Process IN GAME MODE!", "OK");
            return;
        }
        if(objectNeedExport == null)
        {
            EditorUtility.DisplayDialog("Error", "The Water GameObject is null!", "OK");
            return;
        }

        Renderer rdObjNE = objectNeedExport.GetComponent<MeshRenderer>();
        if(rdObjNE == null)
        {
            EditorUtility.DisplayDialog("Error", "The Water GameObject Depend on 'MeshRenderer'!", "OK");
            return;
        }

        string savePath = EditorUtility.SaveFilePanel("Export", Application.dataPath, objectNeedExport.name + "_WaterMaskMap", "jpg");
        if (string.IsNullOrEmpty(savePath)) return;

        if (null != waterExportObj)
        {
            DestroyImmediate(waterExportObj);
            waterExportObj = null;
        }

        Rect rect = new Rect(0, 0, (int)WaterMaskData.maskMapSize, (int)WaterMaskData.maskMapSize);
        rt1 = new RenderTexture((int)rect.width, (int)rect.height, 0, RenderTextureFormat.Depth);
        rt2 = new RenderTexture((int)rect.width, (int)rect.height, 0, RenderTextureFormat.Depth);
        rt3 = new RenderTexture((int)rect.width, (int)rect.height, 0, RenderTextureFormat.ARGB32);

        reInfoList = new List<reInfo>();
        teInfoList = new List<terrainInfo>();
        Shader wmmed = Shader.Find("Hidden/WaterMaskMapExportDepth");
        Shader wmmcd = Shader.Find("Hidden/WaterMaskMapCompareDepth");

        float sceneMaxHeight = 0;
        GameObject[] gameObjs = FindObjectsOfType(typeof(GameObject)) as GameObject[];
        foreach( GameObject gameObj in gameObjs )
        {
            if (gameObj == objectNeedExport) continue;                
            Terrain terrain = gameObj.GetComponent<Terrain>();
            if (terrain != null)
            {
                TerrainCollider terrainCollider = gameObj.GetComponent<TerrainCollider>();
                if (terrainCollider != null)
                {
                    Bounds bounds = terrainCollider.terrainData.bounds;
                    float height = gameObj.transform.TransformPoint(new Vector3(0, bounds.max.y, 0)).y;
                    sceneMaxHeight = height > sceneMaxHeight ? height : sceneMaxHeight;
                }

                Material mtl = new Material(wmmed);                 
                terrain.materialTemplate = mtl;
                terrainInfo ti = new terrainInfo();
                ti.obj = gameObj;              
                ti.layer = gameObj.layer;
                teInfoList.Add(ti);
            }

            Renderer r = gameObj.GetComponent<MeshRenderer>();
            if( r!=null )
            {
                sceneMaxHeight = r.bounds.max.y > sceneMaxHeight ? r.bounds.max.y : sceneMaxHeight;

                for ( int i = 0; i < r.materials.Length; i++ )
                {
                    if (r.materials[i] == null) continue;

                    reInfo ri = new reInfo();
                    ri.obj = gameObj;
                    ri.layer = gameObj.layer;
                    ri.re = r;
                    ri.index = i;
                    ri.sh = r.materials[i].shader;
                    reInfoList.Add(ri);
                    gameObj.layer = 0;
                    r.materials[i].shader = wmmed;
                }
            }
        }

        if (WaterMaskData.checkCameraPos)
        {
            sceneMaxHeight = WaterMaskData.cameraYPos;
        }

        Vector3 exportPos = objectNeedExport.transform.TransformPoint(Vector3.zero);
        float camFarClipPlane = sceneMaxHeight - exportPos.y + 0.5f;
        waterExportObj = new GameObject("WaterExportObj");
        waterExportObj.transform.localPosition = Vector3.zero;
        waterExportObj.transform.localRotation = Quaternion.identity;
        waterExportObj.transform.localScale = Vector3.one;
        GameObject sceneCameraObj = new GameObject("SceneCamera");
        sceneCameraObj.transform.parent = waterExportObj.transform;
        sceneCameraObj.transform.localPosition = new Vector3(exportPos.x, sceneMaxHeight, exportPos.z);
        Quaternion quaternion = Quaternion.identity;
        quaternion.eulerAngles = new Vector3(90, 0, 0);
        sceneCameraObj.transform.localRotation = quaternion;
        sceneCameraObj.transform.localScale = Vector3.one;
        Camera sceneCamera = sceneCameraObj.AddComponent<Camera>();
        sceneCamera.clearFlags = CameraClearFlags.SolidColor;
        sceneCamera.backgroundColor = Color.clear;
        sceneCamera.orthographic = true;
        sceneCamera.orthographicSize = 10;
        sceneCamera.nearClipPlane = 0;
        sceneCamera.farClipPlane = camFarClipPlane;
        sceneCamera.rect = new Rect(0, 0, 1, 1);
        sceneCamera.depthTextureMode |= DepthTextureMode.Depth;

        GameObject waterCameraObj = Instantiate(sceneCameraObj);
        waterCameraObj.transform.parent = waterExportObj.transform;
        waterCameraObj.name = "WaterCamera";
        Camera waterCamera = waterCameraObj.GetComponent<Camera>() as Camera;
        waterCamera.depthTextureMode |= DepthTextureMode.Depth;
        GameObject exportCameraObj = Instantiate(sceneCameraObj);
        exportCameraObj.transform.parent = waterExportObj.transform;
        quaternion.eulerAngles = new Vector3(-90, 0, 0);
        exportCameraObj.transform.localRotation = quaternion;
        exportCameraObj.name = "ExportCamera";

        Camera exportCamera = exportCameraObj.GetComponent<Camera>() as Camera;
        Vector3 extObjNE = rdObjNE.bounds.extents;
        float maxt = extObjNE.x > extObjNE.y ? extObjNE.x : extObjNE.y;
        maxt = maxt > extObjNE.z ? maxt : extObjNE.z;
        float cameraSize = maxt;
        sceneCamera.orthographicSize = cameraSize;
        waterCamera.orthographicSize = cameraSize;
        exportCamera.orthographicSize = cameraSize;
        objectNeedExportLayer = objectNeedExport.layer;
		objectNeedExport.layer = 30; 
        sceneCamera.cullingMask &= ~(1 << 30);
        waterCamera.cullingMask = 1 << 30;
        exportCamera.cullingMask = 1 << 31;

        GameObject panelObject = GameObject.CreatePrimitive(PrimitiveType.Plane);
        panelObject.name = "Panel Object";
        panelObject.transform.parent = exportCamera.transform;
        panelObject.transform.localPosition = new Vector3(0, 0, camFarClipPlane / 2);
        panelObject.transform.localScale = objectNeedExport.transform.localScale;
        panelObject.layer = 31;
        Renderer panelRenderer = panelObject.GetComponent<MeshRenderer>();
        panelRenderer.material = Instantiate(rdObjNE.material) as Material;
        panelRenderer.material.shader = wmmcd;
        panelRenderer.material.SetTexture("_SceneDepthTexture", rt1);
        panelRenderer.material.SetTexture("_WaterDepthTexture", rt2);
        panelRenderer.material.SetFloat("_DepthFactor", WaterMaskData.depthScale);

        Shader waterShader = rdObjNE.material.shader;
        rdObjNE.material.shader = wmmed;

        //Debug.LogFormat("Camera Info:{0} {1} {1}", cameraSize, sceneMaxHeight, camFarClipPlane);
        CaptureCamera(sceneCamera, waterCamera, exportCamera, rect, savePath);

        for( int i = 0; i < reInfoList.Count; i++ )
        {
            reInfo ri = reInfoList[i];
            if (null == ri.re) continue;
            ri.re.materials[ri.index].shader = ri.sh;
            ri.obj.layer = ri.layer;
        }

        for (int i = 0; i < teInfoList.Count; i++)
        {
            terrainInfo ti = teInfoList[i];
            Terrain terrain = ti.obj.GetComponent<Terrain>();
            if( terrain )
            {
                terrain.materialTemplate = null;
                ti.obj.layer = ti.layer;
            }
        }

        rdObjNE.material.shader = waterShader;
        objectNeedExport.layer = objectNeedExportLayer;
    }

    Texture2D CaptureCamera(Camera camera1, Camera camera2, Camera camera3, Rect rect, string savePath)
    {
        camera1.targetTexture = rt1;
        camera2.targetTexture = rt2;
        camera3.targetTexture = rt3;

        camera1.Render();
        camera2.Render();
        camera3.Render();

        RenderTexture.active = camera3.targetTexture;
        Texture2D screenShot = new Texture2D((int)rect.width, (int)rect.height, TextureFormat.ARGB32, false);
        screenShot.ReadPixels(rect, 0, 0);
        screenShot.Apply();

        RenderTexture.active = null;
        byte[] bytes = screenShot.EncodeToJPG();        
        File.WriteAllBytes(savePath, bytes);

        waterExportObj.SetActive(false);

        return screenShot;
    }
      
}