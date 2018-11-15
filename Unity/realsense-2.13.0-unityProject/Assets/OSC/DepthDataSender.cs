using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DepthDataSender : MonoBehaviour {

    public OSC osc;
    public PointCloudGenerator pcGenerator;
    public PointCloudGenerator1 pcGeneratorWithoutViz;
    OscMessage message;
    List<Vector3> particlesInRangePos = new List<Vector3>();

    // Use this for initialization
    void Start () {
		
	}
	
	// Update is called once per frame
	void Update () {
        particlesInRangePos = pcGenerator.particlesInRangePos;

        if (particlesInRangePos.Count == 0) return;

        message = new OscMessage();
        message.address = "/num";
        message.values.Add(particlesInRangePos.Count);
        osc.Send(message);

        message = new OscMessage();
        message.address = "/depth";

        for (int i = 0; i < particlesInRangePos.Count; i++)
        {
            Vector3 depthPoint = Camera.main.WorldToViewportPoint(new Vector3(particlesInRangePos[i].x, particlesInRangePos[i].y, particlesInRangePos[i].z));
            message.values.Add(depthPoint.x);
            message.values.Add(depthPoint.y);
        }

        print(particlesInRangePos.Count + "..." + 1 / Time.deltaTime);
        osc.Send(message);

    }
}
