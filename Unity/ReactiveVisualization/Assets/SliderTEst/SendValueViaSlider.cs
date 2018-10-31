using UnityEngine;
using System.Collections;
using UnityEngine.UI;
public class SendValueViaSlider : MonoBehaviour
{

    public OSC osc;
    public Slider slider;
    public Slider slider2;

    public Slider slider_1_x;
    public Slider slider_1_y;
    public Slider slider_2_x;
    public Slider slider_2_y;

    float slider_1_x_Value;
    float slider_1_y_Value;
    float slider_2_x_Value;
    float slider_2_y_Value;

    int isCorrectGesture = 0;

    
    // Use this for initialization
    void Start()
    {
        slider_1_x_Value = slider_1_x.value;
        slider_1_y_Value = slider_1_y.value;
        slider_2_x_Value = slider_2_x.value;
        slider_2_y_Value = slider_2_y.value;
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

        //mouseF();
        slider_1_x_Value = slider_1_x.value;
        slider_1_y_Value = slider_1_y.value;
        slider_2_x_Value = slider_2_x.value;
        slider_2_y_Value = slider_2_y.value;

        OscMessage message = new OscMessage();

        
        message.address = "/test";
        //message.values.Add(isCorrectGesture);
        //message.values.Add(slider.value);




        //a group of joints
        message.values.Add(slider_1_x_Value);
        message.values.Add(slider_1_y_Value);
        message.values.Add(slider_2_x_Value);
        message.values.Add(slider_2_y_Value);
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
