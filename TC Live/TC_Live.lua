local print = gma.echo;
local Get = gma.show.getobj;
local Prop = gma.show.property;
local function Error(m)
  gma.gui.msgbox('Error', m);
end;

-- Load HTTP package
for _,p in pairs({'socket', 'ltn12', 'mime' }) do
  package.loaded[p] = require('socket/' .. p);
end; local http = require('socket/http');

-- Cache responses
local lastResponse;
local last = {};

-- Main Loop
return function()

  local seqNo = gma.textinput("Enter sequence number", 1);
  if(not seqNo or not tonumber(seqNo)) then Error("Invalid sequence number"); return; end;
  local seq = Get.handle('Sequence ' .. seqNo);
  if(not seq) then Error("Sequence does not exist"); return; end;

  while(true) do (function()

    local response = http.request('http://localhost:18080/_/MARKER');
    if(response == lastResponse) then return; end; -- no changes to effect 
 
    for name, i, time in response:gmatch('MARKER\t([^\t]+)\t([^\t]+)\t([^\t]+)') do
      local cueRef = "Sequence " .. seqNo .. " Cue " .. i;
      if(last[i] ~= time) then
        gma.cmd(string.format('Assign %s /Trig="Timecode" /TrigTime=%s', cueRef, tonumber(time)));
      end; last[i] = time;  
    end; lastResponse = response;

    gma.sleep(0.5); 

  end)() end;

end

  end)() end;

end