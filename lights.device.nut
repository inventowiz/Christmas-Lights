servo <- hardware.pin1;
servo.configure(PWM_OUT, 0.02,1.0);

local state = 0;
local delay = 0; // mins after/before rise/set to toggle
local UTCoffset = -5; // UTC to EST

local sun = {}; // Default 8AM on, 5PM off
sun.riseh <- 8;
sun.risem <- 0;
sun.seth <- 17;
sun.setm <- 0;
 
server.log("Hardware Configured");
 
function setServo(value) 
{
    servo.write(value*0.001);
}

function lightsOn(val){
    if(state == 1) {return;}
    server.log("Lights on");
    agent.send("postlog","Lights on");
    state = 1;
    setServo(100); //turn clockwise
    imp.wakeup(1.0,function(){
        setServo(0); //stop after 1 seconds
    })
}
function lightsOff(val){
    if(state == 0) {return;}
    server.log("Lights out");
    agent.send("postlog","Lights out");
    state = 0;
    setServo(20); //turn clockwise
    imp.wakeup(1.0,function(){
        setServo(0); //stop after 1 seconds
    }) 
}

function checkTime(){
  local now = date();
  now.hour += UTCoffset;
  if(now.hour < 0) {now.hour += 24;}
  now.hour %= 24;
  if(!(now.min % 10)) {
    server.log(format("Checking Time: It's %i:%i...",now.hour,now.min));
    agent.send("postlog",format("Checking Time: It's %i:%i...",now.hour,now.min));
  }
  if((now.hour == sun.seth && now.min == sun.setm) // astro
      || (now.hour == 6 && now.min == 0)){         // 6AM
    server.log(format("It's %i:%i!",now.hour,now.min));
    agent.send("postlog",format("It's %i:%i!",now.hour,now.min));
    lightsOn(0);
  }
  else if((now.hour == sun.riseh && now.min == sun.risem) // astro
            || (now.hour == 3 && now.min == 0)){          // 3AM 
    server.log(format("It's %i:%i!",now.hour,now.min));
    agent.send("postlog",format("It's %i:%i!",now.hour,now.min));
    lightsOff(0);
  }
  else if(now.hour == 2 && now.min == 00){
    // 2AM get astronomy data
    server.log(format("It's %i:%i, poll API",now.hour,now.min));
    agent.send("postlog",format("It's %i:%i, poll API",now.hour,now.min));
    agent.send("astro",0);
  }
  else{
    if(!(now.min % 10)) {
      if(state){
        server.log(format("Lights will turn off at %i:%i",sun.riseh,sun.risem));
        agent.send("postlog",format("Lights will turn off at %i:%i",sun.riseh,sun.risem));
      }else{
        server.log(format("Lights will turn on at %i:%i",sun.seth,sun.setm));
        agent.send("postlog",format("Lights will turn on at %i:%i",sun.seth,sun.setm));
      }
    }
  }
  imp.wakeup(60,checkTime); //Wakeup every minute
}

function setAstro(data){
  server.log("Updating sun data");
  agent.send("postlog","Updating sun data");
  sun.riseh = data["sunrise"]["hour"].tointeger();
  sun.risem = data["sunrise"]["minute"].tointeger() + delay;
  if(sun.risem >= 60){
    sun.riseh ++; // Don't care about overflow here, unlikely to be around midnight
    sun.risem %= 60;
    server.log(format("Overflow, updating to %i:%i",sun.riseh,sun.risem));
    agent.send("postlog",format("Overflow, updating to %i:%i",sun.riseh,sun.risem));
  }
  sun.seth = data["sunset"]["hour"].tointeger();
  sun.setm = data["sunset"]["minute"].tointeger() - delay;
  if(sun.setm < 0){
    sun.seth --; // Don't care about overflow here, unlikely to be around midnight
    sun.setm = 60 + sun.setm;
    server.log(format("Underflow, updating to %i:%i",sun.seth,sun.setm));
  }
}
agent.on("astroResp",setAstro)

function powerHandler(state) {
    server.log("got a power message from the agent"); // log something
    agent.send("postlog","got a power message from the agent");
    if(state){
      lightsOn(1);
    }else{
      lightsOff(1);
    }
    agent.send("status",state); // allow agent to get state
}
// whenever we get a "power" message, run the powerHandler function 
agent.on("power", powerHandler);

agent.send("astro",0); // Get initial data on reset
checkTime(); // Start time loop