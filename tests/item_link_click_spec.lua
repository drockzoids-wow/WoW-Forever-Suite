local Suite, equal, Combat = ...
local items=Suite.Items
local oldItem,oldModified,oldHandler,oldPrint=C_Item,IsModifiedClick,HandleModifiedItemClick,Suite.Print
local oldRequested=items.linkRequested
local shift,loaded,calls,requests,message=true,true,0,0,nil
items.linkRequested={}
local link="|cff00ff00|Hitem:100:0:0:0|h[Copper Bar]|h|r"
C_Item={GetItemInfo=function() if loaded then return "Copper Bar",link end end,RequestLoadItemDataByID=function() requests=requests+1 end}
IsModifiedClick=function(kind) equal(kind,"CHATLINK","item click uses native link modifier"); return shift end
HandleModifiedItemClick=function(value) calls=calls+1; equal(value,link,"native handler receives full validated item hyperlink"); return true end
Suite.Print=function(value) message=value end
Combat(false)
equal(items:ModifiedClick(100,"LeftButton"),true,"Shift-click is consumed by item linking")
equal(calls,1,"native handler owns auction/chat destination")
shift=false
equal(items:ModifiedClick(100,"LeftButton"),false,"ordinary click keeps its original action")
shift=true
equal(items:ModifiedClick(100,"RightButton"),false,"right-click cannot insert item text")
Combat(true)
equal(items:ModifiedClick(100,"LeftButton"),false,"combat does not route item linking")
equal(calls,1,"combat performs no native link action")
Combat(false); loaded=false
items:ModifiedClick(100,"LeftButton"); items:ModifiedClick(100,"LeftButton")
equal(requests,1,"uncached links request metadata once")
equal(calls,1,"uncached clicks never insert guessed links or deferred searches")
equal(message:find("again",1,true)~=nil,true,"uncached link asks for a new click")
loaded=true; items:ModifiedClick(100,"LeftButton")
equal(calls,2,"explicit click after loading forwards item")
link="|Hitem:200:0|h[Other]|h"; items:ModifiedClick(100,"LeftButton")
equal(calls,2,"mismatched item link cannot search another item")
link={secret=true}; items:ModifiedClick(100,"LeftButton")
equal(calls,2,"restricted native link output is not inspected or forwarded")
items:ModifiedClick({secret=true},"LeftButton")
equal(calls,2,"restricted item identity never reaches native click handler")
C_Item,IsModifiedClick,HandleModifiedItemClick,Suite.Print=oldItem,oldModified,oldHandler,oldPrint
items.linkRequested=oldRequested
