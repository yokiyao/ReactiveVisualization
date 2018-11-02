using UnityEngine;
using System.Collections;
using UnityEngine.UI;
using System;
public class JointsSender : MonoBehaviour
{

    public OSC osc;
    //public Slider slider;
    //public Slider slider2;

    //public Slider slider_A_x;
    //public Slider slider_A_y;
    //public Slider slider_B_x;
    //public Slider slider_B_y;
    //public Slider slider_C_x;
    //public Slider slider_C_y;

    //public Slider[] slider_a_x;
    //public Slider[] slider_a_y;
    //public Slider[] slider_b_x;
    //public Slider[] slider_b_y;

    float slider_1_x_Value;
    float slider_1_y_Value;
    float slider_2_x_Value;
    float slider_2_y_Value;

    int isCorrectGesture = 0;
    public int groupNum = 2;
    public Toggle isDetected;
    [Serializable]
    public struct JointSlider
    {
        public Slider x;
        public Slider y;
    }

    public Slider controlSlider;
    public JointSlider[] slider_a;

    public JointSlider[] slider_b;

    // Use this for initialization
    void Start()
    {
        //slider_a_x = new Slider[groupNum];
        //slider_a_y = new Slider[groupNum];
        //slider_b_x = new Slider[groupNum];
        //slider_b_y = new Slider[groupNum];
        //slider_1_x_Value = slider_1_x.value;
        //slider_1_y_Value = slider_1_y.value;
        //slider_2_x_Value = slider_2_x.value;
        //slider_2_y_Value = slider_2_y.value;
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
        //slider_a[0].y.value = slider_b[1].y.value  = controlSlider.value; 

        //mouseF();
        //slider_1_x_Value = slider_1_x.value;
        //slider_1_y_Value = slider_1_y.value;
        //slider_2_x_Value = slider_2_x.value;
        //slider_2_y_Value = slider_2_y.value;

        OscMessage message = new OscMessage();


        message.address = "/test";
        //message.values.Add(isCorrectGesture);
        //message.values.Add(slider.value);




        //a group of joints
        if (isDetected.isOn)
        {
            for (int i = 0; i < groupNum; i++)
            {
                message.values.Add(slider_a[i].x.value);
                message.values.Add(slider_a[i].y.value);
                message.values.Add(slider_b[i].x.value);
                message.values.Add(slider_b[i].y.value);
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
