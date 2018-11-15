using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DepthSender : MonoBehaviour {

    public OSC osc;
    public NuitrackModules nuitrackModules;
    OscMessage message;

    // Use this for initialization
    void Start () {
		
	}
	
	// Update is called once per frame
	void Update () {

        //message = new OscMessage();
        //message.address = "/skn"; //skeleton number
        //message.values.Add(skeletonNum);
        //print("send   " + message.address + "    " + skeletonNum);
        //osc.Send(message);



    }
}
