﻿using UnityEngine;
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
    
    
    // Use this for initialization
    void Start()
    {
        
        nuitrackModules.SkeletonTracker.SetNumActiveUsers(6);
        
         //QualitySettings.vSyncCount = 0;
         //Application.targetFrameRate = 30;
        
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

        osc.Send(message);


   

    }


}
