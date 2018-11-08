using UnityEngine;
using System.Collections;
using UnityEngine.UI;
using System;
using System.Collections.Generic;
public class MultiSkeletonsJointsSender : MonoBehaviour
{

    public OSC osc;
    public NuitrackModules nuitrackModules;
    Vector3[] startingGroup;
    Vector3[] endingGroup;
    Dictionary<int, Dictionary<nuitrack.JointType, GameObject>> joints = new Dictionary<int, Dictionary<nuitrack.JointType, GameObject>>();

    nuitrack.JointType[,] connectionsInfo;

    int isCorrectGesture = 0;
    public int groupNum = 2;
    //public Toggle isDetected;
    //[Serializable]
    //public struct JointSlider
    //{
    //    public Slider x;
    //    public Slider y;
    //}

    //public Slider controlSlider;
    //public JointSlider[] slider_a;

    //public JointSlider[] slider_b;

    // Use this for initialization
    void Start()
    {
        startingGroup = new Vector3[groupNum];
        endingGroup = new Vector3[groupNum];
        nuitrackModules.SkeletonTracker.SetNumActiveUsers(6);
        
         //QualitySettings.vSyncCount = 0;
         //Application.targetFrameRate = 30;
         ;
    }


   
    Vector2[] jointsPositions;

    void ProcessSkeletons(nuitrack.SkeletonData skeletonData)
    {
        if ((skeletonData == null) || (skeletonData.NumUsers == 0))
        {

            Debug.Log("isNull");
            //print(skeletonData.NumUsers);
        }
        else
        {
            Debug.Log("isNotNull");
            print(skeletonData.NumUsers);
        }
        
    }

    public void SendToProcessing()
    {
        OscMessage message = new OscMessage();
        message.address = "/test";
        message.values.Add(1);
        osc.Send(message);
    }

    int skeletonNum;
    int connectionsLength = 0;
    // Update is called once per frame
    void Update()
    {
        //Debug.Log(1 / Time.deltaTime);
        while (connectionsLength == 0)
        {
            connectionsInfo = nuitrackModules.skeletonsVisualization.GetComponent<SkeletonsVisualization_Sender>().connectionsInfo; 
            connectionsLength = nuitrackModules.skeletonsVisualization.GetComponent<SkeletonsVisualization_Sender>().connectionsLength;
            //print(connectionsLength);
            print(connectionsInfo[0, 0]);

        }

        joints = nuitrackModules.skeletonsVisualization.GetComponent<SkeletonsVisualization_Sender>().joints;
        OscMessage message = new OscMessage();
        //jointsPositions = nuitrackModules.skeletonsVisualizationPrefab.GetComponent<SkeletonsVisualization_Sender>().jointsPositions;
        message.address = "/test";

        skeletonNum = joints.Count;

        if (skeletonNum == 0 || nuitrackModules.SkeletonData == null) return;

        print("skip");
        print("skeletonNum  " + skeletonNum);
        //print()
        
        for (int i = 1; i < skeletonNum + 1; i++)
        {
            for (int j = 0; j < connectionsLength; j++)
            {
                Vector3 transferVec_1 = Camera.main.WorldToViewportPoint(joints[i][connectionsInfo[j, 0]].transform.position);
                Vector3 transferVec_2 = Camera.main.WorldToViewportPoint(joints[i][connectionsInfo[j, 1]].transform.position);
                if (connectionsInfo[j, 1] == nuitrack.JointType.RightHand) print(connectionsInfo[j, 1] + "transfered:.." + transferVec_1);
                if (connectionsInfo[j, 1] == nuitrack.JointType.RightHand)  print(connectionsInfo[j, 1] + "..." + joints[i][connectionsInfo[j, 0]].transform.position);
                message.values.Add(transferVec_1.x);
                message.values.Add(transferVec_1.y);
                message.values.Add(transferVec_2.x);
                message.values.Add(transferVec_2.y);

            }
        }

        //for (int i = 0; i < groupNum; i++)
        //{
        //    message.values.Add(jointsPositions[i * 2].x);
        //    message.values.Add(jointsPositions[i * 2].y);
        //    message.values.Add(jointsPositions[i * 2 + 1].x);
        //    message.values.Add(jointsPositions[i * 2 + 1].y);


        osc.Send(message);


        //message = new OscMessage();
        //message.address = "/UpdateX";
        ////if (isConfirmed)
        ////{
        ////isConfirmed = false;
        //message.values.Add(inputX.text);
        //osc.Send(message);

        //}
        //else
        //{
        //    message.values.Add("null");
        //    osc.Send(message);
        //}

        //message = new OscMessage();
        //message.address = "/UpdateY";
        //message.values.Add(transform.position.y);
        //osc.Send(message);

        //message = new OscMessage();
        //message.address = "/UpdateZ";
        //message.values.Add(transform.position.z);
        //osc.Send(message);


    }


}
