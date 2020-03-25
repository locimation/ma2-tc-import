local print=gma.echo
local Get = gma.show.getobj;
local function Exec(t)
  for _,c in ipairs(t) do
    gma.cmd(c);
  end;
end;
local function Error(m)
  gma.gui.msgbox('Error', m);
end;

return function()

-- Prompt for sequence number
local seqNo = gma.textinput("Enter sequence number", 1);
if(not seqNo or not tonumber(seqNo)) then Error("Invalid sequence number"); return; end;
local seq = Get.handle('sequence ' .. seqNo);
if(not seq) then
  local create = gma.gui.confirm("Not Found", "Sequence does not exist. Create it?");
  if(not create) then return; end;
  local name = gma.textinput("New sequence name", "Sequ " .. seqNo);
  Exec({
    'BlindEdit On',
    'ClearAll',
    'Store Sequence ' .. seqNo,
    'Label Sequence ' .. seqNo .. ' "' .. name .. '"',
    'BlindEdit Off'
  });
  seq = Get.handle('sequence ' .. seqNo);
end;

-- Get timecode offset
local offset = gma.textinput("Timecode offset (seconds)", 0);
if(not offset) then return; end;

-- Enumerate existing cues
local existing_cues = {};
print(Get.amount(seq));
for i=1,Get.amount(seq) do
  local cue = Get.child(seq, i);
  if(cue) then
    local cue_no = tonumber(Get.number(cue)); 
    existing_cues[cue_no] = true;
  end;
end;

-- Read CSV
local f = io.open("temp/markers.csv");
local text = f:read('*all');
f:close();

-- Parse CSV
local markers = {};
local props;
for line in text:gmatch('([^\r\n]+)') do
  local values = {};
  for v in line:gmatch('([^,]+)') do
    table.insert(values, v);
  end;
  if(not props) then props = values;
  else
    local marker = {};
    for i,v in ipairs(values) do
      marker[props[i]] = v;
    end;
    table.insert(markers, marker);
  end;
end;

-- Update / create cues
Exec({'BlindEdit On', 'ClearAll'});
for i,m in ipairs(markers) do
  local cue_no = tonumber(m["#"]:match('^M(%d+)$'));
  local cue_ref = 'Sequence ' .. seqNo .. ' Cue ' .. cue_no 
  local cue = Get.handle(cue_ref);

  -- Create nonexistent cues
  if(not cue) then
    Exec({
      'Store ' .. cue_ref .. ' /nc'
    });
  end;

  -- Relabel new or default-named cues
  if(not cue or Get.name(cue):match('^Cue ' .. cue_no .. '$')) then
    Exec({
      'Label ' .. cue_ref .. ' "' .. m.Name .. '"'
    });
  end;
 
  -- Set the timecode trigger 
  Exec({'Assign ' .. cue_ref .. ' /Trig="Timecode" /TrigTime=' .. (m.Start + offset) });
  
end;
Exec({'BlindEdit Off'});

end;