﻿using UnityEngine;
using System.Collections;
using UnityEngine.UI;
using System;
public class JointsSender : MonoBehaviour
{

    public OSC osc;
    public NativeAvatar avatar;
    Vector3[] startingGroup;
    Vector3[] endingGroup;


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
        //QualitySettings.vSyncCount = 0;
        //Application.targetFrameRate = 30;
    }


    void mouseF()
    {
        if (Input.GetMouseButtonDown(0))
        {
            isCorrectGesture = 1;
        }
        else
        {
            isCorrectGesture = 0;
        }
    }
    // Update is called once per frame
    void Update()
    {
        //Debug.Log(1 / Time.deltaTime);

        OscMessage message = new OscMessage();

        message.address = "/test";
        //a group of joints
        if (avatar.userTracked != 0)
        {
            for (int i = 0; i < groupNum; i++)
            {
                
                message.values.Add(avatar.jointPositions[i * 2].x);
                message.values.Add(avatar.jointPositions[i * 2].y);
                message.values.Add(avatar.jointPositions[i * 2 + 1].x);
                message.values.Add(avatar.jointPositions[i * 2 + 1].y);
                
            }

        }
        else
        {
            for (int i = 0; i < groupNum; i++)
            {
                message.values.Add(0);
                message.values.Add(0);
                message.values.Add(0);
                message.values.Add(0);
            }

        }

        //message.values.Add(slider_A_x.value);
        //message.values.Add(slider_A_y.value);
        //message.values.Add(slider_B_x.value);
        //message.values.Add(slider_B_y.value);
        //print(slider.value);
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
