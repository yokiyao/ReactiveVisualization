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
  param_physics.iterations_collisions = 4;
  param_physics.iterations_springs    = 0; // no springs in this demo

  particlesystem.initParticles();

  createGUI();

  background(0);
  frameRate(60);
  
  //osc
  oscP5 = new OscP5(this,12000);
  myRemoteLocation = new NetAddress("127.0.0.1",12000);
  
  osc_grpA_x = new float[]{};
  osc_grpA_y = new float[]{};
  osc_grpB_x = new float[]{};
  osc_grpB_y = new float[]{};
  prePos_x = new float[]{};
  prePos_y = new float[]{};
  conRadius = new float[]{};
  distance = new float[]{};
  

  
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
  float radius   = 30; 
  //float rest_len = radius * 3 * radius_collision_scale;

  CustomVerletParticle2D pa = new CustomVerletParticle2D(idx_curr);
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

void createParticleInCircle(float posx, float posy, boolean add) {

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

    CustomVerletParticle2D pa = new CustomVerletParticle2D(idx_fornew + i);
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
public void draw() {        

  if (keyPressed && key == ' ') {
    createParticle(mouseX, mouseY);
  }

  if (mousePressed && mouseButton == LEFT && !alreadyAdd) {
    alreadyAdd = true;
    addBiggerVeloctiyToParticles(true);
    createParticleInCircle(mouseX, mouseY, true);
  }
  
  
  //  add force: Middle Mouse Button (MMB) -> particle[0]
  //if (/*mousePressed && mouseButton == CENTER*/ abs(OSCupdateX - moveX) > 10 || abs(OSCupdateY - moveY) > 10) {
  //  moveX = OSCupdateX;
  //  moveY = OSCupdateY;
  //  float[] mouse = {moveX, moveY};
  //  particlesystem.particles[0].moveTo(mouse, 0.3f);
  //  particlesystem.particles[0].setRadius(30);
  //  //println(particlesystem.particles[0].getVelocity());
  //  particlesystem.particles[0].enableCollisions(false);
  //} else {
  //  particlesystem.particles[0].enableCollisions(true);
  //  particlesystem.particles[0].setRadius(0);
  //}
  


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

float[] pointX, pointY;
int segmentNum = 5;
float posx, posy;
float[] pos;
float[] distance;
float[] conRadius;
void drawConnections(){

 
  
  for (int i = 0; i < groupNum; i++){
    distance[i] = dist(osc_grpA_x[i], osc_grpA_y[i], osc_grpB_x[i], osc_grpB_y[i]);
    conRadius[i] = distance[i]/segmentNum/2;
    
    for (int j = 0; j < segmentNum + 1; j++){
      
     posx = (osc_grpB_x[i] - osc_grpA_x[i]) / segmentNum * j + osc_grpA_x[i];
     posy = (osc_grpB_y[i] - osc_grpA_y[i]) / segmentNum * j + osc_grpA_y[i];
     
     int n = i * (segmentNum + 1) + j;
     if (abs(prePos_x[n] - posx) > 10 || abs(prePos_y[n] - posy) > 10 ){
       
       prePos_x[n] = posx;
       prePos_y[n] = posy;
       float[] pos = { prePos_x[n], prePos_y[n]};  
       particlesystem.particles[n].moveTo(pos, 0.3f);
       particlesystem.particles[n].setRadius(conRadius[i]);
       particlesystem.particles[n].enableCollisions(false);
       particlesystem.particles[n].isOccupied = true;
       return;
     }
     else{
       particlesystem.particles[n].setRadius(particlesystem.passRadius);
       particlesystem.particles[n].enableCollisions(true);
       particlesystem.particles[n].isOccupied = false;
     }
     
   }
 }
  //print(particlesystem.particles[0].cx + ".." + particlesystem.particles[0].cy +  ".." +
  //particlesystem.particles[5].cx + ".." + particlesystem.particles[5].cy);
  //float[] p = {500, 500};
  //  particlesystem.particles[0].moveTo(p, 0.3f);

  
  // if (abs(OSCupdateX - moveX) > 10 || abs(OSCupdateY - moveY) > 10) {
  //  paX = OSCupdateX;
  //  moveY = OSCupdateY;
  //  float[] mouse = {moveX, moveY};
  //  particlesystem.particles[0].moveTo(mouse, 0.3f);
  //  particlesystem.particles[0].setRadius(30);
  //  //println(particlesystem.particles[0].getVelocity());
  //  particlesystem.particles[0].enableCollisions(false);
  //} else {
  //  particlesystem.particles[0].enableCollisions(true);
  //  particlesystem.particles[0].setRadius(0);
  //}
  
}


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


float OSCupdateX = width/2;
float OSCupdateY = height/2;
int groupNum = 2;
float[] osc_grpA_x, osc_grpA_y, osc_grpB_x, osc_grpB_y;
//float[] grpA_x, grpA_y, grpB_x, grpB_y;
float[] prePos_x, prePos_y;



/* incoming osc message are forwarded to the oscEvent method. */
void oscEvent(OscMessage theOscMessage) {

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
  println("### received an osc message. with address pattern "+theOscMessage.addrPattern());
  */
  
  
   // receive two pos
   if(theOscMessage.checkAddrPattern("/test")==true) {
     //print(theOscMessage.addrPattern());
    // check if the typetag is the right one.
    //if(theOscMessage.checkTypetag("ffffffff")) {
      // parse theOscMessage and extract the values from the osc message arguments. 
      for (int i = 0; i < groupNum; i+=1 ){
        osc_grpA_x = expand(osc_grpA_x, osc_grpA_x.length + 1);
        osc_grpA_y = expand(osc_grpA_y, osc_grpA_y.length + 1);
        //grpA_x = expand(grpA_x, grpA_x.length + 1);
        //grpA_y = expand(grpA_y, grpA_y.length + 1);        
        osc_grpB_x = expand(osc_grpB_x, osc_grpB_x.length + 1);
        osc_grpB_y = expand(osc_grpB_y, osc_grpB_y.length + 1);
        
        prePos_x =  expand(prePos_x, prePos_x.length + (segmentNum + 1));
        prePos_y =  expand(prePos_y, prePos_y.length + (segmentNum + 1));
        
        conRadius = expand(conRadius, conRadius.length + 1);
        distance = expand(distance, distance.length + 1);
        //grpB_x = expand(grpB_x, grpB_x.length + 1);
        //grpB_y = expand(grpB_y, grpB_y.length + 1);
        osc_grpA_x[i] = theOscMessage.get(i*4).floatValue();
        osc_grpA_y[i] = theOscMessage.get(i*4+1).floatValue();       
        osc_grpB_x[i] = theOscMessage.get(i*4+2).floatValue();
        osc_grpB_y[i] = theOscMessage.get(i*4+3).floatValue();   
        print("### received an osc message /test with typetag ffffffff.");
        println(" values: "+osc_grpA_x[i]+", "+osc_grpA_y[i]+", "+osc_grpB_x[i]+", "+osc_grpB_y[i]);
 
       drawConnections();
      }
      
     
      //return;
    //}  
  } 
  //println("### received an osc message. with address pattern "+theOscMessage.addrPattern());
  
}
