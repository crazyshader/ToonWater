using UnityEngine;

public class WaterTest : MonoBehaviour
{
    public GameObject WaterObj;
    private bool m_show = true;

    public void ShowWater()
    {
        m_show = !m_show;
        WaterObj.SetActive(m_show);
    }

    public void SwitchLOD0()
    {
        Shader.globalMaximumLOD = 400;
    }

    public void SwitchLOD1()
    {
        Shader.globalMaximumLOD = 300;
    }

    public void SwitchLOD2()
    {
        Shader.globalMaximumLOD = 200;
    }
}
