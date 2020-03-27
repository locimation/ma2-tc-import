--[[

  Timecode Live Sync Plugin

  Author: Michael Goodyear
  Email: michael@locimation.com
  Version: 1.0
  
  Copyright 2020 Locimation Pty Ltd

  Permission is hereby granted, free of charge,
  to any person obtaining a copy of this software
  and associated documentation files (the "Software"),
  to deal in the Software without restriction, including
  without limitation the rights to use, copy, modify,
  merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom
  the Software is furnished to do so, subject to the
  following conditions:

  The above copyright notice and this permission
  notice shall be included in all copies or substantial
  portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY
  OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
  LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
  EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
  FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN
  AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
  OTHER DEALINGS IN THE SOFTWARE.


]]

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