using System;
using UnityEngine;
using Intel.RealSense;
using System.Linq;
using System.Collections.Generic;

public class PointCloudGenerator1 : MonoBehaviour
{
    public bool mirrored;
    public float pointsSize = 1;
    public int skipParticles = 2;
    //public ParticleSystem pointCloudParticles;

    //private ParticleSystem.Particle[] particles = new ParticleSystem.Particle[0];
    private PointCloud pc = new PointCloud();
    private Points.Vertex[] vertices;
    private byte[] lastColorImage;
    private Align aligner;
    GameObject cube;
    // Use this for initialization
    void Start()
    {
        aligner = new Align(Intel.RealSense.Stream.Color);
        if(RealSenseDevice.Instance.ActiveProfile.Streams.FirstOrDefault(x => x.Stream == Stream.Depth) == null)
        {
            Debug.Log("Can't create point cloud, depthstream must be enabled");
            return;
        }
        if (RealSenseDevice.Instance.ActiveProfile.Streams.FirstOrDefault(x => x.Stream == Stream.Color) != null)
        {
            RealSenseDevice.Instance.onNewSampleSet += OnFrames;
        }
        else
        {
            RealSenseDevice.Instance.onNewSample += OnFrame;
        }

        cube = GameObject.Find("Cube");
    }

    private void OnFrame(Frame frame)
    {
        if (frame.Profile.Stream != Stream.Depth)
            return;
        var depthFrame = frame as DepthFrame;
        if (!UpdateParticleParams(depthFrame.Width, depthFrame.Height))
        {
            Debug.Log("Unable to craete point cloud");
            return;
        }

        using (var points = pc.Calculate(depthFrame))
        {
            setParticals(points, null);
        }
    }

    //object l = new object();
    private void OnFrames(FrameSet frames)
    {
        using (var aligned = aligner.Process(frames))
        {
            using (var colorFrame = aligned.ColorFrame)
            using (var depthFrame = aligned.DepthFrame)
            {
                if (depthFrame == null)
                {
                    Debug.Log("No depth frame in frameset, can't create point cloud");
                    return;
                }

                if (!UpdateParticleParams(depthFrame.Width, depthFrame.Height))
                {
                    Debug.Log("Unable to craete point cloud");
                    return;
                }

                using (var points = pc.Calculate(depthFrame))
                {
                    setParticals(points, colorFrame);
                }
            }
        }
    }


    List<Vector3> particlesInRangePos = new List<Vector3>();
    List<GameObject> cubes = new List<GameObject>();
    private void setParticals(Points points, VideoFrame colorFrame)
    {
        if (points == null)
            throw new Exception("Frame in queue is not a points frame");

        if (colorFrame != null)
        {
            if (lastColorImage == null)
            {
                int colorFrameSize = colorFrame.Height * colorFrame.Stride;
                lastColorImage = new byte[colorFrameSize];
            }
            colorFrame.CopyTo(lastColorImage);
        }

        vertices = vertices ?? new Points.Vertex[points.Count];
        points.CopyTo(vertices);

       // Debug.Assert(vertices.Length == particles.Length);
        int mirror = mirrored ? -1 : 1;
        particlesInRangePos = new List<Vector3>();
        //Destroy(GameObject.Find("Cube")); 

        destroy = true;
        

        for (int index = 0; index < vertices.Length; index += skipParticles)
        {
            var v = vertices[index];
            if (v.z > 0 && v.z < 0.5)
            {

                //particles[index].position = new Vector3(v.x * mirror, v.y, v.z);
                particlesInRangePos.Add(new Vector3(v.x * mirror, v.y,v.z));
               
                //particles[index].startSize = v.z * pointsSize * 0.02f;
                // if (lastColorImage != null)
                //particles[index].startColor = new Color32(lastColorImage[index * 3], lastColorImage[index * 3 + 1], lastColorImage[index * 3 + 2], 255);
                // else
                //  {
                //      byte z = (byte)(v.z / 2f * 255);
                //particles[index].startColor = new Color32(z, z, z, 255);
                //  }
                //DrawGizmos();
            }
            else //Required since we reuse the array
            {
               // particles[index].position = Vector3.zero;
                //particles[index].startSize = 0;
               // particles[index].startColor = Color.black;
            }
        }
    }
    [SerializeField]
    private float size = 1f;
    public Vector3 GetNearestPointOnGrid(Vector3 position)
    {
        position -= transform.position;

        int xCount = Mathf.RoundToInt(position.x / size);
        int yCount = Mathf.RoundToInt(position.y / size);
        int zCount = Mathf.RoundToInt(position.z / size);

        Vector3 result = new Vector3(
            (float)xCount * size,
            (float)yCount * size,
            (float)zCount * size);

        result += transform.position;

        return result;
    }


    private bool UpdateParticleParams(int width, int height)
    {
        var numParticles = (width * height);
       // if (particles.Length != numParticles)
       // {
       //     particles = new ParticleSystem.Particle[numParticles];
       // }

        return true;
    }
    bool destroy = false;
    float sumx;
    float sumy;
    Vector3 average;
    void Update()
    {

        //Either way, update particles
        //print(particlesInRangePos.Count);
        // pointCloudParticles.SetParticles(particles, particles.Length);
        if (particlesInRangePos.Count != 0)
        {
            //if (destroy)
            //{
            //    foreach (GameObject c in cubes)
            //    {
            //        Destroy(c);
            //        cubes = new List<GameObject>();
            //        destroy = false;
            //    }
            //}

            print(particlesInRangePos.Count + "..." + 1 / Time.deltaTime);
            sumx = 0;
            sumy = 0;

            for (int i = 0; i < particlesInRangePos.Count; i++)
            {
                sumx += particlesInRangePos[i].x;
                sumy += particlesInRangePos[i].y;
                average = new Vector3(300*sumx / particlesInRangePos.Count, 300*sumy / particlesInRangePos.Count, 0);
                
                //    cubes.Add(cube);
              
            }
          
            print(average);
            cube.transform.position = average;
            //cube.transform.localScale = new Vector3(1f, 1f, 1f);
        }

      

        particlesInRangePos.Clear(); 
        
    }
}