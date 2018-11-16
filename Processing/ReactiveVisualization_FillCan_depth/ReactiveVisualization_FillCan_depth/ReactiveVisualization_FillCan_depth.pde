/**
 * 
 * PixelFlow | Copyright (C) 2016 Thomas Diewald - http://thomasdiewald.com
 * 
 * A Processing/Java library for high performance GPU-Computing (GLSL).
 * MIT License: https://opensource.org/licenses/MIT
 * 
 */
 
 /**
 * oscP5sendreceive by andreas schlegel
 * example shows how to send and receive osc messages.
 * oscP5 website at http://www.sojamo.de/oscP5
 */


import com.thomasdiewald.pixelflow.java.DwPixelFlow;
import com.thomasdiewald.pixelflow.java.fluid.DwFluid2D;
import com.thomasdiewald.pixelflow.java.softbodydynamics.DwPhysics;
import com.thomasdiewald.pixelflow.java.softbodydynamics.particle.DwParticle2D;

import controlP5.Accordion; 
import controlP5.ControlP5;
import controlP5.Group;
import controlP5.RadioButton;
import controlP5.Toggle;
import processing.core.*;
import processing.opengl.PGraphics2D;

import java.util.Arrays;
import java.util.Map;

import oscP5.*;
import netP5.*;
  

int viewport_w = 1920;
int viewport_h = 800;
int viewport_x = 230;
int viewport_y = 0;

int gui_w = 200;
int gui_x = 20;
int gui_y = 20;

// particle system, cpu
ParticleSystem particlesystem;
DwPhysics.Param param_physics = new DwPhysics.Param();
DwPhysics<CustomVerletParticle2D> physics;


// some state variables for the GUI/display
int     BACKGROUND_COLOR           = 0;
boolean COLLISION_DETECTION        = true;

//velocity setting
float biggerVelocity = 1.2f;
float normalVelocity = 0.95f;


//osc
OscP5 oscP5;
NetAddress myRemoteLocation;

public void settings() {
  size(viewport_w, viewport_h, P2D);
  smooth(4);
}

public void setup() {
  surface.setLocation(viewport_x, viewport_y);

  // main library context
  DwPixelFlow context = new DwPixelFlow(this);
  context.print();
  context.printGL(); 

  // particle system object
  particlesystem = new ParticleSystem(this, width, height);

  // set some parameters
  particlesystem.PARTICLE_COUNT              = 6000;
  particlesystem.PARTICLE_SCREEN_FILL_FACTOR = 1.1f;
  particlesystem.PARTICLE_SHAPE_IDX          = 4;
  particlesystem.normal_Dvelocity = normalVelocity;
  particlesystem.MULT_GRAVITY                =0f;

  particlesystem.particle_param.DAMP_BOUNDS    = 0.9f;
  particlesystem.particle_param.DAMP_COLLISION = 1;
  //particlesystem.particle_param.DAMP_VELOCITY  = 0.95f;

  physics = new DwPhysics<CustomVerletParticle2D>(param_physics);
  param_physics.GRAVITY = new float[]{0, 0.1f};

  param_physics.bounds  = new float[]{0, 0, width, height};
  param_physics.iterations_collisions = 2;
  param_physics.iterations_springs    = 0; // no springs in this demo

  particlesystem.initParticles();

  createGUI();

  background(0);
  frameRate(60);
  
  //osc
  oscP5 = new OscP5(this,12000);
  myRemoteLocation = new NetAddress("127.0.0.1",12000);
  
 

  
  //skeletons = new Skeleton2D();
  skeletonsHM = new HashMap<String, PVector[]>();

  curVecHM = new HashMap<String, PVector[]>();
  preVecHM = new HashMap<String, PVector[]>();
  
  everyVecHM = new HashMap<String, PVector[]>();
}


//////////////////////////////////////// createNewParticle ///////////////////////////////////////////////


// creates a new particle, and links it with the previous one
public void createParticle(float spawn_x, float spawn_y) {

  //println("create a new one");
  // just in case, to avoid position conflicts
  spawn_x += random(-0.01f, +0.01f);
  spawn_y += random(-0.01f, +0.01f);

  int idx_curr = particlesystem.PARTICLE_COUNT;
  //int idx_curr = physics.getParticlesCount();
  //int   idx_prev = idx_curr - 1;
  float radius_collision_scale = 1.1f;
  float radius   = 1; 
  //float rest_len = radius * 3 * radius_collision_scale;

  CustomVerletParticle2D pa = new CustomVerletParticle2D(particlesystem.papplet, idx_curr);
  pa.setMass(1);
  //pa.setParamByRef(param_chain);
  pa.setParamByRef(particlesystem.particle_param);
  pa.setPosition(spawn_x, spawn_y);
  pa.setRadius(radius);
  pa.setRadiusCollision(radius * radius_collision_scale);
  pa.setCollisionGroup(idx_curr); // every particle has a different collision-ID
  addParticleToList(pa);
}

//////////////////////////////////////// add one particle to list ///////////////////////////////////////////////

public void addParticleToList(CustomVerletParticle2D particle) {
  if (particlesystem.PARTICLE_COUNT >= particlesystem.particles.length) {
    int new_len = (int) Math.max(2, Math.ceil(particlesystem.PARTICLE_COUNT /**1.5f*/ + 1) );
    if (particlesystem.particles == null) {
      particlesystem.particles = new CustomVerletParticle2D[new_len];
    } 
    else {
      particlesystem.particles = Arrays.copyOf(particlesystem.particles, new_len);
    }
  }
  particlesystem.particles[particlesystem.PARTICLE_COUNT++] = particle;
  physics.setParticles(particlesystem.particles, particlesystem.PARTICLE_COUNT);
  //particlesystem.particles[particlesystem.PARTICLE_COUNT -1].setColor(0xFF00000);
}

//////////////////////////////////////// findNearestParticle ///////////////////////////////////////////////

DwParticle particle_mouse = null;

public DwParticle findNearestParticle(float mx, float my, float search_radius) {
  float dd_min_sq = search_radius * search_radius;
  DwParticle2D[] particles = physics.getParticles();
  DwParticle particle = null;
  for (int i = 0; i < particles.length; i++) {
    float dx = mx - particles[i].cx;
    float dy = my - particles[i].cy;
    float dd_sq =  dx*dx + dy*dy;
    if ( dd_sq < dd_min_sq) {
      dd_min_sq = dd_sq;
      particle = particles[i];
    }
  }
  return particle;
}

//////////////////////////////////////// findNearestParticleSS ///////////////////////////////////////////////

public ArrayList<CustomVerletParticle2D> findParticlesWithinRadius(float mx, float my, float search_radius) {
  float dd_min_sq = search_radius * search_radius;
  CustomVerletParticle2D[] particles = physics.getParticles();
  ArrayList<CustomVerletParticle2D> list = new ArrayList<CustomVerletParticle2D>();
  for (int i = 0; i < particles.length; i++) {
    float dx = mx - particles[i].cx;
    float dy = my - particles[i].cy;
    float dd_sq =  dx*dx + dy*dy;
    if (dd_sq < dd_min_sq) {
      list.add(particles[i]);
    }
  }
  return list;
}

/////////////////////////////////// add v to particles //////////////////////////////////

public float cirRad = 80;
ArrayList<CustomVerletParticle2D> gotlist = new ArrayList <CustomVerletParticle2D> ();

void addBiggerVeloctiyToParticles(boolean add) {

  ArrayList<CustomVerletParticle2D> list = findParticlesWithinRadius(mouseX, mouseY, cirRad);
 
  if (add){
    for (CustomVerletParticle2D tmp : list){
      tmp.DAMP_VELOCITY = biggerVelocity;
      //tmp.setRadius(5);
      //tmp.setCollisionGroup(colGroupID);  
      gotlist = list;
    
    }
  } 
  else {  
    for (CustomVerletParticle2D tmp : gotlist) {
      tmp.DAMP_VELOCITY = particlesystem.normal_Dvelocity;
      //tmp.setRadius(2);  
    }
  }
}

/////////////////////////////// create a circle collider ////////////////////////////////
ArrayList <CustomVerletParticle2D> circleColliders = new ArrayList<CustomVerletParticle2D>();

void createParticleInCircle(float posx, float posy) {

  // just in case, to avoid position conflicts
  posx += random(-0.01f, +0.01f);
  posy += random(-0.01f, +0.01f);

  float degree = 1;
  float partRad = sin(radians(degree / 2)) * cirRad;
  int num = int(360 / degree);

  ////////////////

  //int   idx_prev = idx_curr - 1;
  float radius_collision_scale = 1.1f;
  int idx_curr = physics.getParticlesCount();
  //println("idx_curr" + idx_curr);
  int idx_fornew = idx_curr;

  for (int i = 0; i < num + 1; i += 1) {
    float x = posx + cirRad * cos(radians(i * degree));
    float y = posy + cirRad * sin(radians(i * degree));

    CustomVerletParticle2D pa = new CustomVerletParticle2D(particlesystem.papplet, idx_fornew + i);
    circleColliders.add(pa);  
    pa.setMass(1);
    //pa.setParamByRef(param_chain);
    pa.setParamByRef(particlesystem.particle_param);
    pa.setPosition(x, y);
    pa.setRadius(partRad * 2);
    pa.setRadiusCollision(partRad * 2 * radius_collision_scale);
    pa.setCollisionGroup(idx_curr); // same collison id
    pa.enable_collisions = false;
    pa.DAMP_VELOCITY = 0;

    addParticleToList(pa);
    // println(pa.idx);
    // ellipse(x, y, partRad * 2, partRad * 2);
  }
}


boolean alreadyAdd = false; 

// float buffer for pixel transfer from OpenGL to the host application
float[] fluid_velocity;
float moveX = width/2;
float moveY = height/2;

int occupiedCount;
public void draw() {        

  /*test isOccupied
  occupiedCount = 0;
  for (int k = 0; k < particlesystem.PARTICLE_COUNT; k++){
    if (particlesystem.particles[k].isOccupied == true){
     occupiedCount ++; 
    }
    
  }
  
  print("occupiedCount    " + occupiedCount + "        ");
  */
  
//println(particlesystem.particles[500].ax);
  
  if (keyPressed && key == ' ') {
    createParticle(mouseX, mouseY);
    println(mouseX + "   " + mouseY + "   " + frameCount);
  }

  if (mousePressed && mouseButton == LEFT && !alreadyAdd) {
    alreadyAdd = true;
    addBiggerVeloctiyToParticles(true);
    createParticleInCircle(mouseX, mouseY);
  }
  
  if (mousePressed && mouseButton == RIGHT){
    float[] pos = {mouseX, mouseY};
     particlesystem.particles[2222].moveTo(pos, 0.3);
     particlesystem.particles[2222].setRadius(30);
     
  }
  float[] a = {100,100};
     particlesystem.particles[2222].addForce(a);

  // update physics step
  boolean collision_detection = COLLISION_DETECTION && particlesystem.particle_param.DAMP_COLLISION != 0.0;

  physics.param.GRAVITY[1] = 0.05f * particlesystem.MULT_GRAVITY;
  physics.param.iterations_collisions = collision_detection ? 4 : 0;

  physics.setParticles(particlesystem.particles, particlesystem.particles.length);
  physics.update(1);


  // display textures
  background(0);

  // draw particlesystem
  PGraphics pg = this.g;
  pg.hint(DISABLE_DEPTH_MASK);
  pg.blendMode(BLEND);
  //    pg.blendMode(ADD);
  particlesystem.display(pg);
  pg.blendMode(BLEND);

  // info
  String txt_fps = String.format(getClass().getName()+ "   [size %d/%d]   [frame %d]   [fps %6.2f]", width, height, frameCount, frameRate);
  surface.setTitle(txt_fps);
}

//////////////////////////////////////draw connections between two points //////////////////////////

//int segmentNum = 8;

//float posx;
//float posy;
//boolean enter = false;
//int prevF;
///*
//void drawConnections(String skKey){ 
  
//  for (int i = 0; i < 12; i++){
//    PVector startingJoint = skeletonsHM.get(skKey)[i*2];
//    PVector endingJoint = skeletonsHM.get(skKey)[i*2+1];
    
//    float distance = dist(startingJoint.x, startingJoint.y, endingJoint.x, endingJoint.y);
//    float conRadius = distance/segmentNum/2;
    
//    for (int j = 0; j < segmentNum + 1; j++){
//      if (prevF != frameCount) enter = false;
//      int n = i * (segmentNum + 1) + j;
//      preVecHM.get(skKey)[n] = curVecHM.get(skKey)[n];
      
//      curVecHM.get(skKey)[n] = new PVector((endingJoint.x - startingJoint.x) / segmentNum * j + startingJoint.x, (endingJoint.y - startingJoint.y) / segmentNum * j + startingJoint.y);
     
     
//         float[] pos = {curVecHM.get(skKey)[n].x, curVecHM.get(skKey)[n].y};  
//        particlesystem.particles[n].moveTo(pos, 1f);
      
//      if ((abs(preVecHM.get(skKey)[n].x - curVecHM.get(skKey)[n].x) > 5 || abs(preVecHM.get(skKey)[n].y - curVecHM.get(skKey)[n].y) > 5)){  
//        enter = true;
//        //float preCurDist = dist(preVecHM.get(skKey)[n].x, preVecHM.get(skKey)[n].y, curVecHM.get(skKey)[n].x, curVecHM.get(skKey)[n].y);
     
//      //if (preOSCPos_x[n] != curOSCPos_y[n]){
//        particlesystem.particles[n].setRadius(0);
//        particlesystem.particles[n].setRadiusCollision(conRadius);
        
//        particlesystem.particles[n].enableCollisions(false);
        
//        particlesystem.particles[n].isOccupied = true;
     
//        prevF = frameCount;

//       }
//       else if (((abs( preVecHM.get(skKey)[n].x - curVecHM.get(skKey)[n].x) <= 5 && abs( preVecHM.get(skKey)[n].y - curVecHM.get(skKey)[n].y) <= 5))
//         && !enter){
        
//        particlesystem.particles[n].setRadius(particlesystem.passRadius);
//        particlesystem.particles[n].enableCollisions(true);
//        particlesystem.particles[n].isOccupied = false;
        
//       }
  
//    }
//  }

  
//}
//*/

////re-write drawConncetion. only detect the joint position
//void drawConnections(String skKey){ 
  
//  for (int i = 0; i < 12; i++){
    
//    preVecHM.get(skKey)[i*2] = curVecHM.get(skKey)[i*2];
//    preVecHM.get(skKey)[i*2+1] = curVecHM.get(skKey)[i*2+1];
    
//    PVector startingJoint = skeletonsHM.get(skKey)[i*2];
//    PVector endingJoint = skeletonsHM.get(skKey)[i*2+1];
    
//    curVecHM.get(skKey)[i*2] = startingJoint;
//    curVecHM.get(skKey)[i*2+1] = endingJoint;
    
//    //println("previous     " + preVecHM.get(skKey)[i*2] + "     current" +  curVecHM.get(skKey)[i*2] + "          ");
    
//    float distance = dist(startingJoint.x, startingJoint.y, endingJoint.x, endingJoint.y);
//    float conRadius = distance/segmentNum/2;
    
    
//    //starting point or ending point moves more than 5 pixel
//    //if (preVecHM.get(skKey)[i*2].dist(curVecHM.get(skKey)[i*2]) > 15 || preVecHM.get(skKey)[i*2+1].dist(curVecHM.get(skKey)[i*2+1]) > 15){
//      if ((startingJoint.x == width || startingJoint.y == height) || (endingJoint.x == width || endingJoint.y == height)) break;
        
//      //if (preVecHM.get(skKey)[i*2].dist(curVecHM.get(skKey)[i*2]) > 5 || preVecHM.get(skKey)[i*2+1].dist(curVecHM.get(skKey)[i*2+1]) > 5){
//        for (int j = 0; j < segmentNum + 1; j++){
//          // if (prevF != frameCount) enter = false;
//           int  n = i * (segmentNum + 1) + j;
//           everyVecHM.get(skKey)[n] = new PVector((endingJoint.x - startingJoint.x) / segmentNum * j + startingJoint.x, (endingJoint.y - startingJoint.y) / segmentNum * j + startingJoint.y);
//           float[] pos = {everyVecHM.get(skKey)[n].x, everyVecHM.get(skKey)[n].y};
//           particlesystem.particles[n].moveTo(pos, 1f);
//           //createParticle(pos[0],pos[1]);
//           //enter = true;
//           float px = particlesystem.particles[n].px;
//           float py = particlesystem.particles[n].py;
//           float cx = particlesystem.particles[n].cx;
//           float cy = particlesystem.particles[n].cy;
//           float d = dist(px, py, cx, cy);
//           //ArrayList<CustomVerletParticle2D> list = new ArrayList<CustomVerletParticle2D>();
//           if (d > 5){
//             particlesystem.particles[n].setRadius(conRadius);
//             particlesystem.particles[n].enableCollisions(false);
//             particlesystem.particles[n].isOccupied = true;
            
//            //list = findParticlesWithinRadius(particlesystem.particles[i].cx, particlesystem.particles[i].cy, 20);
//             //for (CustomVerletParticle2D near : list) {
//               //float[] a = {particlesystem.particles[i].cx - px, cy - py};
//               //near.addForce(a);
//              //near.isOccupied = true;
//            // }

//           }
//           else{
//             particlesystem.particles[n].setRadius(0);
//             particlesystem.particles[n].isOccupied = false;
             
//           }
           
//           //particlesystem.particles[n].setRadiusCollision(conRadius);
           
//           //prevF = frameCount;
          
//        }
        
//          //resetUnusedParticle(i, conRadius);
      
//    //}
//    //else if (preVecHM.get(skKey)[i*2].dist(curVecHM.get(skKey)[i*2]) <= 5 && preVecHM.get(skKey)[i*2+1].dist(curVecHM.get(skKey)[i*2+1]) <= 5
//    //  && !enter){
        
//    //    for (int j = 0; j < segmentNum + 1; j++){
//    //       int n = 1 * (segmentNum + 1) + j;
//    //       particlesystem.particles[n].setRadius(0);
//    //       particlesystem.particles[n].enableCollisions(true);
//    //       particlesystem.particles[n].isOccupied = false;
//    //    }
//    //}
//  }
  

  
//}
  


//void SetNormalRadius(){
//  //print("skeletonNum      " + skeletonNum);
//  for (int i = 0; i < skeletonNum * (segmentNum + 1); i++){
//   particlesystem.particles[i].setRadius(particlesystem.passRadius);
//   //print("setNormalRadius    " + i);
//  }
  
//}

public void activateCollisionDetection(float[] val) {
  COLLISION_DETECTION = (val[0] > 0);
}




public void mouseReleased() {
  if (mouseButton == LEFT) {
    addBiggerVeloctiyToParticles(false);

    particlesystem.particles = Arrays.copyOfRange(particlesystem.particles, 0, 6000);
    //particlesystem.particles[5999] = pa_last;
    physics.setParticles(particlesystem.particles, particlesystem.particles.length);
    //println(physics.getParticlesCount());
    particlesystem.PARTICLE_COUNT = physics.getParticlesCount();
    alreadyAdd = false;

    circleColliders.clear();
    //println("cc" + circleColliders.size());
  }
}



ControlP5 cp5;

public void createGUI() {
  cp5 = new ControlP5(this);

  int sx, sy, px, py, oy;

  sx = 100; 
  sy = 14; 
  oy = (int)(sy*1.5f);

  ////////////////////////////////////////////////////////////////////////////
  // GUI - PARTICLES
  ////////////////////////////////////////////////////////////////////////////
  Group group_particles = cp5.addGroup("Particles");
  {

    group_particles.setHeight(20).setSize(gui_w, 260)
      .setBackgroundColor(color(16, 180)).setColorBackground(color(16, 180));
    group_particles.getCaptionLabel().align(CENTER, CENTER);

    sx = 100; 
    px = 10; 
    py = 10;
    oy = (int)(sy*1.4f);

    cp5.addButton("reset particles").setGroup(group_particles).setWidth(160).setPosition(10, 10).plugTo(particlesystem, "initParticles");

    cp5.addSlider("Particle count").setGroup(group_particles).setSize(sx, sy).setPosition(px, py+=oy+10)
      .setRange(10, 12000).setValue(particlesystem.PARTICLE_COUNT).plugTo(particlesystem, "setParticleCount");

    cp5.addSlider("Fill Factor").setGroup(group_particles).setSize(sx, sy).setPosition(px, py+=oy)
      .setRange(0.2f, 1.5f).setValue(particlesystem.PARTICLE_SCREEN_FILL_FACTOR).plugTo(particlesystem, "setFillFactor");

    cp5.addSlider("VELOCITY").setGroup(group_particles).setSize(sx, sy).setPosition(px, py+=oy+10)
      .setRange(0.85f, 1.0f).setValue(particlesystem.particle_param.DAMP_VELOCITY).plugTo(particlesystem.particle_param, "DAMP_VELOCITY");

    cp5.addSlider("GRAVITY").setGroup(group_particles).setSize(sx, sy).setPosition(px, py+=oy)
      .setRange(0, 10f).setValue(particlesystem.MULT_GRAVITY).plugTo(particlesystem, "MULT_GRAVITY");

    cp5.addSlider("FLUID").setGroup(group_particles).setSize(sx, sy).setPosition(px, py+=oy)
      .setRange(0, 1f).setValue(particlesystem.MULT_FLUID).plugTo(particlesystem, "MULT_FLUID");

    cp5.addSlider("SPRINGINESS").setGroup(group_particles).setSize(sx, sy).setPosition(px, py+=oy)
      .setRange(0, 1f).setValue(particlesystem.particle_param.DAMP_COLLISION).plugTo(particlesystem.particle_param, "DAMP_COLLISION");

    cp5.addCheckBox("activateCollisionDetection").setGroup(group_particles).setSize(40, 18).setPosition(px, py+=(int)(oy*1.5f))
      .setItemsPerRow(1).setSpacingColumn(3).setSpacingRow(3)
      .addItem("collision detection", 0)
      .activate(COLLISION_DETECTION ? 0 : 2);

    RadioButton rgb_shape = cp5.addRadio("setParticleShape").setGroup(group_particles).setSize(50, 18).setPosition(px, py+=(int)(oy*1.5f))
      .setSpacingColumn(2).setSpacingRow(2).setItemsPerRow(3).plugTo(particlesystem, "setParticleShape")
      .addItem("disk", 0)
      .addItem("spot", 1)
      .addItem("donut", 2)
      .addItem("rect", 3)
      .addItem("circle", 4)
      .activate(particlesystem.PARTICLE_SHAPE_IDX);
    for (Toggle toggle : rgb_shape.getItems()) toggle.getCaptionLabel().alignX(CENTER);
  }
}


////////////////////////////////////////////// OSC ////////////////////////////////////////////

//float OSCupdateX = width/2;
//float OSCupdateY = height/2;
//int groupNum = 48;
//float[] osc_grpA_x, osc_grpA_y, osc_grpB_x, osc_grpB_y;
////float[] grpA_x, grpA_y, grpB_x, grpB_y;
//float[] preOSCPos_x, preOSCPos_y, curOSCPos_x, curOSCPos_y;

//ArrayList<Skeleton2D> skeletonArray = new ArrayList<Skeleton2D>();
//Skeleton2D skeletons;

HashMap <String, PVector[]> skeletonsHM;
HashMap <String, PVector[]> curVecHM;
HashMap <String, PVector[]> preVecHM;
HashMap <String, PVector[]> everyVecHM;
int skeletonNum;


int depthPointCount;
PVector[] depthPoint;
PVector[] prevDepthPoint;
PVector[] currentDepthPoint;
/* incoming osc message are forwarded to the oscEvent method. */
void oscEvent(OscMessage theOscMessage) {
  //print("### received an osc message.");
  
   //if (theOscMessage.checkAddrPattern("/lost") == true){
     //SetNormalRadius(); 
     //print("lost");
  //}
  
  //if (theOscMessage.checkAddrPattern("/skn") == true){
  //   skeletonNum = theOscMessage.get(0).intValue();
     //print("skn    " + skeletonNum);
     //return;
  //}
  
 
  
  //for (int skeN = 1; skeN < skeletonNum + 1; skeN++){
    
  //   if (theOscMessage.checkAddrPattern("/sk" + skeN) == true){
  //      //create an empty joints array
  //      if (!skeletonsHM.containsKey("sk" + skeN)){
  //         //PVector[] joints = new PVector[24];
  //         skeletonsHM.put("sk" + skeN, new PVector[24]);
  //         curVecHM.put("sk" + skeN, new PVector[/*12*(segmentNum+1)*/24]);
  //         preVecHM.put("sk" + skeN, new PVector[/*12*(segmentNum+1)*/24]);
  //         everyVecHM.put("sk" + skeN, new PVector[12 * (segmentNum + 1)]);
           
  //         //print(skeletonsHM.get("sk1").length);
  //       }
         
  //       //skeletonsHM.get("sk1")[0].x =10;
  //       //skeletonsHM.get("sk1")[0] = new PVector(1,1);
  //       //println(skeletonsHM.get("sk1")[0]);
  //       for (int n = 0; n < 12; n++){
           
  //         skeletonsHM.get("sk" + skeN)[n*2] = new PVector((1-theOscMessage.get(n*4).floatValue()) * width, (1-theOscMessage.get(n*4+1).floatValue())*height);
  //         skeletonsHM.get("sk" + skeN)[n*2+1] = new PVector((1-theOscMessage.get(n*4 + 2).floatValue()) * width, (1-theOscMessage.get(n*4 + 3).floatValue())*height);
    
  //         //println(skeletonsHM.get("sk" + skeN)[n*2] + "   " + n);
  //         //println(skeletonsHM.get("sk" + skeN)[n*2 + 1]);
  //       }
       
  //       drawConnections("sk" + skeN);
       
        
  //    }
    
  //}
  
 
  
  /* sk2
  
  if (theOscMessage.checkAddrPattern("/sk2") == true){
    if (!skeletonsHM.containsKey("sk2")){
       //PVector[] joints = new PVector[24];
       skeletonsHM.put("sk2", new PVector[24]);
       curVecHM.put("sk2", new PVector[12*(segmentNum+1)]);
       preVecHM.put("sk2", new PVector[12*(segmentNum+1)]);
      
       
       //print(skeletonsHM.get("sk2").length);
     }
     
     //skeletonsHM.get("sk1")[0].x =10;
     //skeletonsHM.get("sk1")[0] = new PVector(1,1);
     //println(skeletonsHM.get("sk2")[0]);
     for (int n = 0; n < 12; n++){
       
       skeletonsHM.get("sk2")[n*2] = new PVector((1-theOscMessage.get(n*4).floatValue()) * width, (1-theOscMessage.get(n*4+1).floatValue())*height);
       skeletonsHM.get("sk2")[n*2+1] = new PVector((1-theOscMessage.get(n*4 + 2).floatValue()) * width, (1-theOscMessage.get(n*4 + 3).floatValue())*height);

       println(skeletonsHM.get("sk2")[n*2]);
       println(skeletonsHM.get("sk2")[n*2 + 1]);
     }
   
     drawConnections("sk2");
   
    
    
    
  }
  */
  
  
  /* single particle collider
  if(theOscMessage.checkAddrPattern("/test")==true) {
    // check if the typetag is the right one.
    if(theOscMessage.checkTypetag("ff")) {
      // parse theOscMessage and extract the values from the osc message arguments. 
      
      OSCupdateX = theOscMessage.get(0).floatValue();  
      OSCupdateY = theOscMessage.get(1).floatValue();
      
      print("### received an osc message /test with typetag ff.");
      println(" values: "+OSCupdateX+", "+OSCupdateY);
      return;
    }  
  } 
  
  */
println("### received an osc message. with address pattern "+theOscMessage.addrPattern());
 //depth
 if (theOscMessage.checkAddrPattern("/num") == true){
   depthPointCount = theOscMessage.get(0).intValue();
   println(depthPointCount);
     
   
 }
 prevDepthPoint = depthPoint;
 depthPoint = new PVector[]{};
 depthPoint = new PVector[depthPointCount];
 
 //remove some prev opoint
 //if (depthPointCount < prevDepthPoint.length){
 //    int n = prevDepthPoint.length - depthPointCount;
 //    for (int k = 0; k < n; k++){
 //     prevDepthPoint = shorten(prevDepthPoint);
 //    }
   
 //}
 
 //println(depthPoint.length);
 //depthPoint = new PVector[depthPointCount];
 if (theOscMessage.checkAddrPattern("/depth") == true){
     for (int i = 0; i < depthPointCount; i++){
        depthPoint[i] = new PVector(theOscMessage.get(i*2).floatValue(), theOscMessage.get(i*2+1).floatValue());;
        //println(depthPoint[i].y);
        
     }
 }
 drawDepthPoint();
  
}

void drawDepthPoint(){
  for (int i = 0; i < depthPointCount; i++){
    //if (depthPoint[i].x <1 && depthPoint[i].y < 1){
      float[] pos = {width*depthPoint[i].x, height*depthPoint[i].y};
      
           //particlesystem.particles[i].moveTo(pos, 0.3f);
           particlesystem.particles[i].setPosition(width*depthPoint[i].x, height*depthPoint[i].y);
           float px = particlesystem.particles[i].px;
           float py = particlesystem.particles[i].py;
           float cx = particlesystem.particles[i].cx;
           float cy = particlesystem.particles[i].cy;
           float d = dist(px, py, cx, cy);
        if (d >10){
         particlesystem.particles[i].setRadius(15);
         particlesystem.particles[i].isOccupied = true;
          println("enterif" + frameCount);
        }
        
      
      else{
         particlesystem.initParticlesSize(i);
         particlesystem.particles[i].isOccupied = false;
          //println("idx      " + i + "occ" + particlesystem.particles[i].isOccupied + "    frameCount      " + frameCount);
          println("enterelse" + frameCount);
          //println("idx     "  + i + "       pos       " + particlesystem.particles[i].cx);
      }
      
     
    }
  //}
  //for ( int j = depthPointCount; j < particlesystem.particles.length; j++){
  //  particlesystem.particles[j].isOccupied = false;
  //  particlesystem.particles[j].setRadius(particlesystem.passRadius);
  //}
  
}
