local print=gma.echo
local Get = gma.show.getobj;
local Prop = gma.show.property;
local function Exec(t)
  if(type(t) ~= 'table') then t = {t}; end;
  for _,c in ipairs(t) do
    gma.cmd(c);
  end;
end;
local function Error(m)
  gma.gui.msgbox('Error', m);
end;

local function getSeqForExec(no)
  Exec('Li Exec ' .. no .. ' /f=_exec_config.csv');
  local fh = io.open('reports/_exec_config.csv');
  local data = fh:read('*all'); fh:close();
  local seqNo = data:match('Sequence=Seq ([^( ]+)');
  return tonumber(seqNo);
end;

return function()

  local execNo = gma.textinput("Executor number to export from", "");
  if(not Get.handle('Exec ' .. execNo)) then Error('Executor does not exist.'); return; end;

  local seqNo = getSeqForExec(execNo);
  if(not seqNo) then Error('Sequence not assigned to executor.'); return; end;

  local tcNo = tonumber(gma.textinput('Timecode pool item to import to', 1));
  if(not tcNo) then Error('Invalid Timecode pool item number'); return; end;

  local seq = Get.handle('Sequence ' .. seqNo);
  local events = {};
  for i=1,Get.amount(seq) do 
    local q = Get.child(seq, i);
    if(q) then
      local cue = {
        name = Get.name(q),
        label = Get.label(q),
        number = Get.number(q)
      };
      for j=1,Prop.amount(q) do
        cue[Prop.name(q,j):gsub('\x7C',' ')] = Prop.get(q,j);
      end;
      if(cue.Trig == 'Timecode') then
        local time = tonumber(cue['Trig Time']);
        table.insert(events, { cue = i, name = cue.name, time = time, number = cue.number });
      end;
    end;
  end;

  if(#events < 1) then return; end;

  -- Sort by trigger time
  table.sort(events, function(a,b) return a.time < b.time; end);
 
  -- Construct events
  local eventXml = '';
  for i,e in ipairs(events) do
    local event = string.format(
      '\t\t\t\t<Event index="%d" time="%d" command="Goto" pressed="true" step="%d">\n' ..
      '\t\t\t\t\t<Cue name="%s">\n' ..
      '\t\t\t\t\t\t<No>1</No>\n' ..
      '\t\t\t\t\t\t<No>%d</No>\n' ..
      '\t\t\t\t\t\t<No>%d</No>\n' ..
      '\t\t\t\t\t</Cue>\n' ..
      '\t\t\t\t</Event>\n',
      i-1, math.floor(e.time*30+0.5), e.cue, e.name, seqNo, e.cue
    );
    eventXml = eventXml .. event; 
  end;

  Exec({
    'BlindEdit On',
    'ClearAll',
    'Store Timecode ' .. tcNo .. ' /nc',
    'Export Timecode ' .. tcNo .. ' "_tc_temp.xml" /nc',
    'BlindEdit Off'
  });

  local fh = io.open('importexport/_tc_temp.xml');
  local xml = fh:read('*all'); fh:close();
  xml = xml:gsub('<Timecode([^\n]+) />', '<Timecode%1>\n\t</Timecode>');

  -- Get Executor name
  local exec = Get.handle('Executor ' .. execNo);
  local execName = Get.name(exec);
  local execId = {Get.number(exec):match('(%d+)%.(%d+)')};

  -- Construct new track
  local trackNo = -1;
  for track in xml:gmatch('Track index="(%d+)"') do
    if(tonumber(track) > trackNo) then trackNo = tonumber(track); end;
  end; trackNo = trackNo + 1;
  local track = string.format(
    '\t\t<Track index="%d" active="true" expanded="true">\n' ..
    '\t\t\t<Object name="%s">\n' ..
    '\t\t\t\t<No>30</No>\n' ..
    '\t\t\t\t<No>1</No>\n' ..
    '\t\t\t\t<No>%d</No>\n' ..
    '\t\t\t\t<No>%d</No>\n' ..
    '\t\t\t</Object>\n' ..
    '\t\t\t<SubTrack index="0">\n' ..
    '%s' .. -- events go here
    '\t\t\t</SubTrack>\n' ..
    '\t\t</Track>\n',
    trackNo,
    execName,
    execId[1],
    execId[2],
    eventXml
  );

  -- Generate complete XML
  xml = xml:gsub('\t</Timecode>', track .. '\t</Timecode>');
  local fh = io.open('importexport/_tc_temp_output.xml', 'w');
  fh:write(xml); fh:close();

  -- Import into timecode slot
  Exec('Import "_tc_temp_output.xml" At Timecode ' .. tcNo .. ' /nc');

  -- Set sequence cues back to "Go"
  if(not gma.gui.confirm('Reset to GO', 'Set sequence cue triggers to "Go"?')) then return end;
  for i,e in ipairs(events) do 
    Exec('Assign Sequence ' .. seqNo .. ' Cue ' .. e.number .. ' /Trig=Go');
  end;

end;