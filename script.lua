PermNone=0
PermAuth=1
PermMod=2
PermModPlus=2.69
PermAdmin=3
PermDev=69
PermOwner=420
PermsList={{PermAdmin,"Admin","Admin"},{PermMod,"Moderator","Mod"},{PermModPlus,"Moderator","Mod"},{PermDev,"Developer","Dev"},{PermOwner,"Owner","Owner"},{PermNone,"Player","Player"},{PermAuth,"Player","Player"}}

g_savedata = {}
NoSave={Player={},SeatQueue={},VehicleTPQueue={},ChatMessageClearQueue={},LastObjectID=0,CurrentObjectID=0,FlaresDetectedLast=0,AntiLagData={LastAbove=0,WeatherLastDetected=0}}
Ticks=0




LastMS=server.getTimeMillisec()
ServerStartTime=0
LastTimeUpdate=0
TimeDifference=0
LastSave=0
LastAnnounceTime=0
LastAnnouncement=0
ServerConfig={
	Version="3.0.3",
	TpsHistoryLength=12,
	SpeedHistoryLength=5,
	ResetSettings=false,
	MessageHistoryLength=200,
	ItemsPerRequest=8,
	AdminPermLevel=PermMod,
	TPSBelow=40,
	TPSBelowTime=25,
	TPSDiffrence=18,
	TPSScanTime=9,
	TPSMaxStrikes=6,
	MaxPartsCount=60,

	ServerDataName="ServerA",
	ServerData={
		ServerA={
			Port=8000,
			AutoAuth=true,
			AuthOnAcceptPopup=false,
			AuthCommand={"accept","auth","bob"},
			AuthPopupText="",
			RequireReAuthOnWarn=true,
			RemovePlayerVehiclesOnWarn=true,
			DefaultKit={0,15,6},
			Autosave=false,
			ServerName="Stormworks Server",
			RandomAnnouncementsFrequency=300,
			BannedWords={},
			RandomAnnouncements={
				"You can do ?help for command help",
				"?pvp [Player ID/Name] will tell you that players pvp status",
				"If you want to know a vehicles pvp state at a glance do ?pvp_view",
				"Spawning laggy vehicles is not allowed",
				"Do ?rules to view the server rules",
				"If you see someone breaking the rules do ?report (PlayerID) (Report Reason)",
				"If you want to know a vehicles pvp state at a glance do ?pvp_view",
				"Remember to check a players pvp status before pvping using ?pvp_view or ?pvp [Player ID/Name]",
				"During pvp you must have your pvp on (To toggle your pvp do ?pvp)",
				"You can teleport your vehicle to you by doing ?tvtm (Vehicle ID)",
				"Don't fire into or out of the hanger",
				"Consider the play experience of others: Don't spawn big vehicles"
			}
		}
	}

}

TPS=0
TPSList={}
TPSDivisor=0
TpList={}

ScriptReloaded=false
for X =1,ServerConfig["TpsHistoryLength"],1 do
	TPSDivisor=TPSDivisor + X	
	table.insert(TPSList,0)
end
TPSDivisor=1/TPSDivisor

SpeedDivisor=0
for X =1,ServerConfig["SpeedHistoryLength"],1 do
	SpeedDivisor=SpeedDivisor + X	
end
SpeedDivisor=1/SpeedDivisor


GiveItems={{"diving",1,{100,100},2}, {"firefighter",2,{nil,nil},2}, {"scuba",3,{100,100},2}, {"parachute",4,{1,nil},2}, {"arctic",5,{nil,nil},2}, {"binoculars",6,{nil,nil},0}, {"cable",7,{nil,nil},1}, {"compass",8,{nil,nil},0}, {"defibrillator",9,{4,nil},1}, {"fire_extinguisher",10,{nil,9},1}, {"first_aid",11,{4,nil},0}, {"flare",12,{4,nil},0}, {"flaregun",13,{1,nil},0}, {"flaregun_ammo",14,{4,nil},0}, {"flashlight",15,{nil,100},0}, {"hose",16,{nil,nil},1}, {"night_vision_binoculars",17,{nil,100},0}, {"oxygen_mask",18,{nil,100},0}, {"radio",19,{nil,100},0}, {"radio_signal_locator",20,{nil,100},1}, {"remote_control",21,{nil,100},0}, {"rope",22,{nil,nil},1}, {"strobe_light",23,{0,100},0}, {"strobe_light_infrared",24,{0,100},0}, {"transponder",25,{0,100},0}, {"underwater_welding_torch",26,{nil,250},1}, {"welding_torch",27,{nil,400},1}, {"coal",28,{nil,nil},0}, {"hazmat",29,{nil,nil},2},{"radiation_detector",30,{nil,100},0}, {"c4",31,{1,nil},0}, {"c4_detonator",32,{nil,nil},0}, {"speargun",33,{1,nil},1}, {"speargun_ammo",34,{4,nil},0}, {"pistol",35,{17,nil},0}, {"pistol_ammo",36,{17,nil},0}, {"smg",37,{40,nil},1}, {"smg_ammo",38,{40,nil},0}, {"rifle",39,{30,nil},1}, {"rifle_ammo",40,{30,nil},0}, {"grenade",41,{1,nil},0},{"glowstick",72,{12,nil},0},{"dog_whistle",73,{nil,nil},0},{"bomb_disposal",74,{nil,nil},2},{"chest_rig",75,{nil,nil},2},{"black_hawk_vest",76,{nil,nil},2},{"plate_vest",77,{nil,nil},2},{"armor_vest",78,{nil,nil},2},{"space_suit",79,{100,100},2},{"space_exploration_suit",80,{100,100},2},{"fishing_rod",81,{nil,nil},1}}

function GetServerConfigData()
	return ServerConfig["ServerData"][ServerConfig["ServerDataName"]]
end

function Announce(Title,Message,PeerID)
	if PeerID == nil then
		PeerID=-1
	end
	server.announce(Title,Message,PeerID)
	AddToMessageHistory(Title,Message,PeerID)
end

function FixBlankPlayer(PlayerName,PeerID)
	if PlayerName == nil then
		return PlayerName
	end
	if RemoveTrailingAndLeading(tostring(tostring(PlayerName):gsub('%W',''))) == "blank" then
		PlayerName="Blank " .. tostring(PeerID)
		--Announce("efawef",PlayerName)
	end
	return PlayerName
end

function AddToMessageHistory(Title,Message,PeerID)
	if PeerID == -1 then
		for _,Y in pairs(FilteredServerPlayers()) do
			AddToPlayerMessageHistory(Title,Message,Y.id)
		end
	else
		AddToPlayerMessageHistory(Title,Message,PeerID)
	end
end

function AddToPlayerMessageHistory(Title,Message,PeerID)
	
	if NoSave["Player"][PeerID] ~= nil then
		table.insert(NoSave["Player"][PeerID]["MessageHistory"],{Title,Message})
		if #NoSave["Player"][PeerID]["MessageHistory"] > ServerConfig["MessageHistoryLength"] then
			table.remove(NoSave["Player"][PeerID]["MessageHistory"],1)
		end
	end
end

function SendMessageHistory()

	for _,Y in pairs(FilteredServerPlayers()) do
		for C=0, ServerConfig["MessageHistoryLength"] - #NoSave["Player"][Y.id]["MessageHistory"], 1 do
			server.announce(" "," ",Y.id)
		end
		--S.announce("WEFewa",tostring(#NoSave["Player"][Y.id]["MessageHistory"]))
		for _,B in pairs(NoSave["Player"][Y.id]["MessageHistory"]) do
			server.announce(B[1],B[2],Y.id)
		end
	end
end

function HeartBeatSend()
	local Uptime=FormatTime(math.floor(g_savedata["Seconds"] - ServerStartTime))
	local UptimeString=tostring(Uptime[4] * 24 + Uptime[3]) .. "h," .. tostring(Uptime[2]) .. "m"
	local Out={"HeartBeat",TPS,#server.getPlayers() - 1,UptimeString}
	local PlayerList=" "
	for _,Y in pairs(FilteredServerPlayers()) do
		if tostring(Y.steam_id) ~= "0" then
			PlayerList=PlayerList .. "- ".. Y.name .. " (" .. tostring(Y.id) .. ")/|n"
		end
	end
	if PlayerList == " " then
		PlayerList="No players online"
	end
	table.insert(Out,PlayerList)
	SendHttp(Out)
end

function DiscordNotify(PeerID,Title,Message,Type,Discord)
	if Discord == true then
		SendHttp({"TypeDiscordCommandResponse",Title,Message,NotificationType})
	else
		server.notify(PeerID,Title,Message,Type)
	end
end

function GetSteamID(PeerID)
	if NoSave["Player"][PeerID] == nil then
		return "0"
	end
	return tostring(NoSave["Player"][PeerID]["SteamID"])
end

function GetPlayerData(PeerID)
	for X,Y in pairs(FilteredServerPlayers()) do
		if Y.id == tonumber(PeerID) then
			return Y
		end
	end
	return nil
end



function SendHttp(List)
	local Per=ServerConfig["ItemsPerRequest"]
	local Total=math.ceil(#List / Per)

	local TimeStamp=server.getTimeMillisec()

	local StringList={"1/"..tostring(Total) .. "\n" .. tostring(TimeStamp) .. "\n"}
	local Z=1
	for X,Y in pairs(List) do
		
		StringList[Z]=StringList[Z] .. tostring(Y) .. "\n"
		if X % Per == 0 and X ~= 1 and X ~= #List then
			Z=Z + 1
			StringList[Z]=tostring(Z) .."/"..tostring(Total) .. "\n" .. tostring(TimeStamp) .. "\n"
		end
	end
	for _,Y in pairs(StringList) do
		server.httpGet(ServerConfig["ServerData"][ServerConfig["ServerDataName"]]["Port"], "HTTP/1.1 200 OK\n" .. Y)
		--S.announce(tostring(X),tostring(Y))
	end
end

function FormatTime(Seconds)
	local Years=math.floor(Seconds / 31536000)
	local Days=math.floor((Seconds % 31536000) / 86400)
	local Hours=math.floor((Seconds % 86400) / 3600)
	local Minutes=math.floor((Seconds % 3600) / 60)
	local Seconds=math.floor((Seconds % 60))
	return {Seconds,Minutes,Hours,Days,Years}
end


function OnlyNumbers(String)
	return not (String == "" or String == nil or String:find("%D"))
end

function RemoveNonAscii(String)
	return string.gsub(String, "[\128-\255]", "")
end

function RemoveTrailingAndLeading(String)
	return string.match(String,'^%s*(.-)%s*$')
end

function AutoComplete(String,List)
	local StartOfString={}
	local MiddleOfString={}
	for Y,X in pairs(List) do
		local Start,End=string.find(X,String)
		if X == String then
			return X,Y
		end
		if Start == 1 then
			table.insert(StartOfString,{X,Y})
		elseif Start ~= nil then
			if Start > 1 and string.len(String) > 1 then
				table.insert(MiddleOfString,{X,Y})
			end
		end
	end
	local AllEqualStart=true
	if #StartOfString > 0 then
		for _,X in pairs(StartOfString) do
			if X[1] ~= StartOfString[1][1] then
				AllEqualStart=false
				break
			end
		end
	else
		AllEqualStart=false
	end

	if #StartOfString == 1 or AllEqualStart == true then
		return StartOfString[1][1],StartOfString[1][2]
	elseif #StartOfString == 0 and #MiddleOfString == 1 then
		return MiddleOfString[1][1],MiddleOfString[1][2]
	end
	return nil,nil
end

function ConvertToPeer(String,List)
	if String == nil then
		return
	end
	local ReturnSteamID=false
	if List == nil then
		List={}
	else
		ReturnSteamID=true
	end
	String=string.lower(String)
	local FullyNumbers=OnlyNumbers(String)
	local AutoCompletePlayerNames={}
	for _,Y in pairs(List) do
		local NameFiltered=string.lower(RemoveNonAscii(FixBlankPlayer(Y.Name,Y.id)))
		if (tostring(Y.SteamID) == tostring(String) and FullyNumbers) or NameFiltered == String then
			return tostring(Y.SteamID)
		end
		table.insert(AutoCompletePlayerNames,NameFiltered)
	end

	for _,Y in pairs(FilteredServerPlayers()) do
		local NameFiltered=string.lower(RemoveNonAscii(FixBlankPlayer(Y.name,Y.id)))
		if ((tonumber(Y.id) == tonumber(String) or tostring(Y.steam_id) == tostring(String)) and FullyNumbers) or NameFiltered == String then
			if ReturnSteamID == true then
				return tostring(Y.steam_id)
			else
				return Y.id
			end
		end
		table.insert(AutoCompletePlayerNames,NameFiltered)
	end
	String=string.gsub(String, "%W", "%%%1" )
	local AutoCompleteResult=AutoComplete(String,AutoCompletePlayerNames)
	if AutoCompleteResult ~= nil then
		for _,Y in pairs(List) do
			if string.lower(RemoveNonAscii(Y.Name)) == string.lower(AutoCompleteResult) then
				return tostring(Y.SteamID)
			end
		end
		for _,Y in pairs(FilteredServerPlayers()) do
			if string.lower(RemoveNonAscii(FixBlankPlayer(Y.name,Y.id))) == string.lower(AutoCompleteResult) then
				if ReturnSteamID == true then
					return tostring(Y.steam_id)
				else
					return Y.id
				end
			end
		end
	end

end

function Lines(String)
	local LineList = {}
	for X in String:gmatch("[^\r\n]+") do
   		table.insert(LineList, X)
	end
	return LineList
end

function ReplaceNil(Text)
	if Text == "nil" then
		return nil
	end
	return Text
end

function httpReply(Port, Request, Reply)

	local ReplyList=Lines(Reply)

 	if ReplyList[1] == "TypeDiscordMessage" then
		Announce("[Discord] " .. ReplyList[2],ReplyList[3])
	elseif ReplyList[1] == "TypeServerRestarting" then
		Announce("[Server]","The server will be restarting shortly")
		server.save()
	elseif ReplyList[1] == "TypeExecuteCommand" then
		onCustomCommand(ReplyList[2], -1, true, true, ReplaceNil(ReplyList[3]), ReplaceNil(ReplyList[4]), ReplaceNil(ReplyList[5]), ReplaceNil(ReplyList[6]), ReplaceNil(ReplyList[7]),ReplaceNil(ReplyList[9]),true)
	end
end

function FilteredServerPlayers()
	local Output={}
	for _,X in pairs(server.getPlayers()) do
		if NoSave["Player"][X.id] ~= nil then
			if g_savedata["PlayerData"][tostring(X["steam_id"])] ~= nil then
				
				table.insert(Output,X)
			end
		end
	end
	return Output
end

function ParsePermissions(Permissions,ShortForm)
	if ShortForm == nil then
		ShortForm=false
	end
	if Permissions > 100000 then
		if ShortForm == true then
			return "Dev"
		else
			return "Developer"
		end
	end
	for _,X in pairs(PermsList) do
		if X[1] == Permissions then
			if ShortForm == true then
				return X[3]
			else
				return X[2]
			end
		end
	end
end

function UpdatePlayerPermissionsMessage(PeerID,SendPermissionMessage)
	if SendPermissionMessage == true then
		local PermString=ParsePermissions(NoSave["Player"][PeerID]["Permissions"])
		if PermString ~= nil then
			Announce("[Server]","You have been given permission: " .. PermString,PeerID)
		end
	end
end
function UpdatePlayerPermissions(PeerID,SendPermissionMessage)
	local SteamID=GetSteamID(PeerID)
	local PlayerData=GetPlayerData(PeerID)
	if PlayerData["admin"] and NoSave["Player"][PeerID]["Permissions"] < PermAdmin then
		NoSave["Player"][PeerID]["Permissions"]=PermAdmin
		UpdatePlayerPermissionsMessage(PeerID,SendPermissionMessage)
	end
	if PlayerData["auth"] and NoSave["Player"][PeerID]["Permissions"] < PermAuth then
		NoSave["Player"][PeerID]["Permissions"]=PermAuth
		UpdatePlayerPermissionsMessage(PeerID,SendPermissionMessage)
	end
end

function InvalidPlayerID(PeerID,Discord)
	DiscordNotify(PeerID, "Invalid ID", "Please enter a valid player ID/Name", 6,Discord)

end

function GetPerms(PeerID)
	if PeerID == -1 then
		return 100000000
	end
	if NoSave["Player"][PeerID] == nil then
		return 0
	end
	return NoSave["Player"][PeerID]["Permissions"]
end

function AnnounceAbovePerms(Name,Message,MinimumPermissions,ExcludePlayerID)
	if ExcludePlayerID == nil then
		ExcludePlayerID=-1
	end
	for X,Y in pairs(FilteredServerPlayers()) do
		if GetPerms(Y.id) >= MinimumPermissions then
			if Y.id ~= ExcludePlayerID then
				Announce(Name,Message,Y.id)
			end
		end
	end
end

function PlayerOnline(PeerID)
	if PeerID == nil then
		return false
	end
	return NoSave["Player"][tonumber(PeerID)] ~= nil
end

function ValidateSettings(ResetSettings)
	local ExpectedSettings={UIEnabled=true,UIDefaultState=true,VehicleTooltips=true,AllowPvpPrevent=true,AnnouncePvpChange=true,NonAdminTpToPlayer=false,NonAdminTeleportVehicles=true,NonAdminGoto=true,NonAdminGotoOnlyOwned=true,ClearVehiclesOnLeave=true,NonAdminTpCommand=true,EnforceVehicleLimit=true,VehicleLimit=1,NonAdminPrivateMessage=true,RemoveBodysOnLeave=true,NonAdminToolCommand=true,NonAdminRepair=true,NoDropsOnDeath=true,DisableItemDrops=false,EnforceItemLimit=true,ItemLimit=3,NonAdminViewStaff=true,NonAdminHeal=true,NonAdminHealOther=false,EnableSelfKill=true,NonAdminFlip=true,NonAdminPvpView=true,AntiRadiation=true,UseDefaultKit=true,RandomAnnouncementsEnabled=true,NonAdminEject=true,EjectTpLocation=4,NonAdminClearSelfInv=true,NonAdminCharge=true,NonAdminFill=true,NonAdminInfItems=true,ShowPermissionsInChat=false,AntiEMP=true,AntiOilSpill=true}

	if g_savedata["Settings"] == nil then
		g_savedata["Settings"]={}
	end

	for X,Y in pairs(ExpectedSettings) do
		if g_savedata["Settings"][X] == nil or ResetSettings then
			g_savedata["Settings"][X]=Y
		end
	end
end

function GetSetting(Setting)
	return g_savedata["Settings"][Setting]
end

function ValidateVehicleData(GroupID,PeerID)
	local ExpectedVehicleData={GroupID=GroupID,OwnerID=PeerID,OwnerSteamID=nil,Parts={},MainBody=-1,SpawnTime=g_savedata["Seconds"],Voxels=0,Mass=0,VehicleComponents={},Loaded=false,StartTPS=TPS,LoadedTime=0,AntiLagCleared=false,MaxTPS=TPS,AntiLagVehicleStrikes=0,Speeds={},LastPosition=server.getPlayerPos(PeerID),Speed=0,Name="Unknown"}
	if g_savedata["Vehicles"][GroupID] == nil then
		g_savedata["Vehicles"][GroupID]={}
	end
	
	for X,Y in pairs(ExpectedVehicleData) do
		if g_savedata["Vehicles"][GroupID][X] == nil then
			g_savedata["Vehicles"][GroupID][X]=Y
		end
	end
	if PeerID ~= nil then
		g_savedata["Vehicles"][GroupID]["OwnerSteamID"]=GetSteamID(PeerID)
	end
end

function ValidatePlayerSaveData(PlayerSteamID,Name)
	local ExpectedPlayerData={FirstJoin=-1,LastJoin=0,Playtime=0,Name=Name,History={},Banned={State=false,BanTime=0,BannedTime=0,Reason=""},WarnCount=0,KickCount=0,JoinCount=0,VehicleCount=0,DeathCount=0,Balance=4200}
	
	if g_savedata["PlayerData"][PlayerSteamID] == nil then
		g_savedata["PlayerData"][PlayerSteamID]={}
	end
	for X,Y in pairs(ExpectedPlayerData) do
		if g_savedata["PlayerData"][PlayerSteamID][X] == nil then
			g_savedata["PlayerData"][PlayerSteamID][X]=Y
		end
	end
	g_savedata["PlayerData"][PlayerSteamID]["Balance"]=(math.floor((g_savedata["PlayerData"][PlayerSteamID]["Balance"] * 100)) / 100)
end

function ValidatePlayerData(PeerID)

	local ExpectedNoSaveData={PeerID=PeerID,SteamID="",UI=GetSetting("UIDefaultState"),Pvp=not GetSetting("AllowPvpPrevent"),AntiSteal=true,Permissions=0,MessageHistory={},Seat={VehicleID=-1,GroupID=-1,X=0,Y=0,Z=0},Speeds={},LastPosition=server.getPlayerPos(PeerID),Speed=0,LastMessager=-1,Muted=false,PvpOffOnRespawn=false,LastShowedDeathMessage=0,PvpView=false,BanView=false,Muted=false,Joined=g_savedata["Seconds"],Freeze={State=false,Pos=nil},TrackVehicles={State=false},Blind=false,BlackListedPlayers={},Follow={State=false,Followed=-1,Height=100},DisableInv=false,Seated=false,DisableVehicleSpawning=false}
	if NoSave["Player"][PeerID] == nil then
		NoSave["Player"][PeerID]={}
	end

	for X,Y in pairs(ExpectedNoSaveData) do
		if NoSave["Player"][PeerID][X] == nil then
			NoSave["Player"][PeerID][X]=Y
		end
	end

	if CountItems(NoSave["Player"][PeerID]["Speeds"]) < ServerConfig["SpeedHistoryLength"] then
		for X =1,ServerConfig["SpeedHistoryLength"],1 do
			table.insert(NoSave["Player"][PeerID]["Speeds"],0)	
		end
	end

	for _,Y in pairs(server.getPlayers()) do
		if NoSave["Player"][Y.id] ~= nil then
			NoSave["Player"][Y.id]["SteamID"]=tostring(Y["steam_id"])
		end
	end
	local PlayerSteamID=GetSteamID(PeerID)
	ValidatePlayerSaveData(PlayerSteamID,server.getPlayerName(PeerID))
	UpdatePlayerPermissions(PeerID,true)
	

end

function CharacterIDToPlayerID(CharacterID)
	for _,X in pairs(FilteredServerPlayers()) do
		if tostring(server.getPlayerCharacterID(X.id)) == tostring(CharacterID) then
			return X.id
		end
	end
end

function ChangePvp(PeerID,State,Notify)
	local AnnounceChange=false
	if NoSave["Player"][PeerID]["Pvp"] ~= State and Notify then
		AnnounceChange=true
	end
	NoSave["Player"][PeerID]["Pvp"]=State
	local PlayerName=FixBlankPlayer(server.getPlayerName(PeerID),PeerID)
	SendHttp({"TypeChangePvp",PlayerName,GetSteamID(PeerID),tostring(NoSave["Player"][PeerID]["Pvp"])})
	if AnnounceChange then
		local RequiredPerms=PermMod
		
		if GetSetting("AnnouncePvpChange") then
			RequiredPerms=PermNone
		end
		
		AnnounceAbovePerms("[Pvp]", PlayerName .. " has changed their pvp state to " .. tostring(NoSave["Player"][PeerID]["Pvp"]),RequiredPerms,-1)
	end
	for _,Y in pairs(g_savedata["Vehicles"]) do
		if tonumber(PeerID) == Y["OwnerID"] then
			if Y["MainBody"] ~= nil then
				for _,A in pairs(FilteredServerPlayers()) do
					PvpViewPopup(Y["GroupID"],A.id)
					TrackVehiclesPopup(Y["GroupID"],A.id)
				end
			end
			for X,_ in pairs(Y["Parts"]) do
				server.setVehicleInvulnerable(tonumber(X),not State)
				SetVehicleToolTip(X,Y["GroupID"],PeerID)
			end
		end
	end
end

function ChangeAntiSteal(PeerID,State)
	NoSave["Player"][PeerID]["AntiSteal"]=State
	for _,Y in pairs(g_savedata["Vehicles"]) do
		if tonumber(PeerID) == Y["OwnerID"] then
			for X,_ in pairs(Y["Parts"]) do
				server.setVehicleEditable(tonumber(X),not State)
			end
		end
	end
end

function CountItems(Table)
	local Count=0
	for _,__ in pairs(Table) do
		Count=Count + 1
	end
	return Count
end

function CheckVehicleDespawns()
	for X,Y in pairs(g_savedata["Vehicles"]) do
		if CountItems(Y["Parts"]) == 0 then
			
			onGroupDespawn(math.floor(Y["GroupID"]),Y["OwnerID"])
			g_savedata["Vehicles"][X]=nil	
			for _,A in pairs(FilteredServerPlayers()) do
				PvpViewPopup(Y["GroupID"],A.id)
				TrackVehiclesPopup(Y["GroupID"],A.id)
			end
		end
	end
end

function SplitOnNewLine(String)
	local Output={}
	for X in String:gmatch('[^\n]+') do
		table.insert(Output,X)
	end
	return Output
end

function CheckVehiclesExist() 
	for _,X in pairs(g_savedata["Vehicles"]) do
		for Y,_ in pairs(X["Parts"]) do
			local _,Found=server.getVehicleData(Y)
			if Found == false then
				g_savedata["Vehicles"][X["GroupID"]]["Parts"][Y]=nil
			end
		end
	end
end

function onCreate()
	math.randomseed(server.getTimeMillisec())

	--ServerConfig["ServerData"][ServerConfig["ServerDataName"]]["BannedWords"]=
	table.sort(ServerConfig["ServerData"][ServerConfig["ServerDataName"]]["BannedWords"],function(X,Y) return string.len(X) > string.len(Y) end)


	if g_savedata["PlayerData"] == nil then
		g_savedata["PlayerData"]={}
	end
	if g_savedata["Vehicles"] == nil then
		g_savedata["Vehicles"]={}
	end
	if g_savedata["Items"] == nil then
		g_savedata["Items"]={}
	end
	if g_savedata["Stats"] == nil then
		g_savedata["Stats"]={}
		
	end

	if g_savedata["NonCorrectedSeconds"] == nil then
		g_savedata["NonCorrectedSeconds"]=0
	end
	if g_savedata["Seconds"] == nil then
		g_savedata["Seconds"]=0
	end
	NoSave["AntiLagData"]["LastAbove"]=g_savedata["Seconds"] + 30
	LastAnnounceTime=g_savedata["Seconds"] 
	LastTimeUpdate=g_savedata["Seconds"]
	ServerStartTime=g_savedata["Seconds"]
	ValidateSettings(ServerConfig["ResetSettings"])
	for _,Y in pairs(server.getPlayers()) do
		ValidatePlayerData(Y.id)
		local PlayerSteamID=GetSteamID(Y.id)

		local BanStatus=CheckBannedStatus(PlayerSteamID)
		if BanStatus ~= false and GetPerms(Y.id) < 10000 then
			SetupBannedPlayer(PlayerSteamID,Y.id,BanStatus)
		end
	end

	for X,Y in pairs(g_savedata["Items"]) do
		if NoSave["Player"][Y] == nil then
			server.despawnObject(X,true)
			g_savedata["Items"][X]=nil
		end
	end
	CheckVehiclesExist()
	CheckVehicleDespawns()
	if g_savedata["Settings"]["RemoveBodysOnLeave"] then
		server.setGameSetting("despawn_on_leave", true)
	else
		server.setGameSetting("despawn_on_leave", false)
	end
	for _,X in pairs(g_savedata["Vehicles"]) do
		for _,A in pairs(FilteredServerPlayers()) do
			PvpViewPopup(X["GroupID"],A.id)
			TrackVehiclesPopup(X["GroupID"],A.id)
		end
		for Y,_ in pairs(X["Parts"]) do
			server.setVehicleEditable(Y, false)

			if NoSave["Player"][X["OwnerID"]] ~= nil then 
				if NoSave["Player"][X["OwnerID"]]["Pvp"] == false then 
					server.setVehicleInvulnerable(tonumber(Y),true)
				end
				if g_savedata["Settings"]["VehicleTooltips"] == true then
					SetVehicleToolTip(tonumber(Y),X["GroupID"],X["OwnerID"])
				else
					server.setVehicleTooltip(tonumber(Y),"")
				end
			elseif GetSetting("ClearVehiclesOnLeave") then
				server.despawnVehicleGroup(X["GroupID"],true)
			end
		end
	end

	local Zones = server.getZones()
	for _,X in pairs(Zones) do 
		local ZoneData=SplitOnNewLine(X["tags_full"])
		if ZoneData[2] ~= "" then 
			TpList[tostring(ZoneData[1])]={ZoneData[2],X["transform"]}
		end
	end

	Announce("[Server]","Reloaded Scripts")
	ScriptReloaded=true
end



function SetVehicleToolTip(VehicleID,GroupID,PeerID)
	local Name = FixBlankPlayer(server.getPlayerName(PeerID),PeerID)
	server.setVehicleTooltip(VehicleID,"Owner(" .. tostring(math.floor(PeerID)) .."):" .. Name .. "\nVehicle: #" .. math.floor(GroupID) .. "\nPart: #" ..tostring(tonumber(VehicleID) + 1000) .. "\nPvp: " .. tostring(NoSave["Player"][PeerID]["Pvp"]))
end

function ComputeTPS()
	local CurrentTPS=(1000 / (server.getTimeMillisec() - LastMS)) * 5

	for X,Y in pairs(TPSList) do
		TPSList[X]=TPSList[X + 1]
	end
	TPSList[ServerConfig["TpsHistoryLength"]]=CurrentTPS

	TPS=0
	for X =1,ServerConfig["TpsHistoryLength"],1 do
		TPS=TPS + (TPSList[X] * (TPSDivisor * X))
	end

	TPS=math.floor(TPS * 10) / 10
	LastMS=server.getTimeMillisec()
end

function TrainString(Text,Chars)
	if #Text > Chars then
		return string.sub(Text,1,Chars-3) .. "..."
	else
		return Text
	end
end

function UpdatePlayerUI(PlayerData,UptimeString)
	local VehicleList=""
	for _,A in pairs(g_savedata["Vehicles"]) do
		if tonumber(A["OwnerID"]) == tonumber(PlayerData.id) then
			VehicleList=VehicleList .. A["Name"] .. " #" .. math.floor(A["GroupID"]) .. "\n"
		end
	end
	if VehicleList == "" then
		VehicleList="[No Spawned Vehicles]\n"
	end

	local Playtime=FormatTime(math.floor(g_savedata["PlayerData"][tostring(PlayerData["steam_id"])]["Playtime"]))
	local PlaytimeString="[" .. tostring(Playtime[4] * 24 + Playtime[3]) .. "h," .. tostring(Playtime[2]) .. "m," .. tostring(Playtime[1]) .. "s]"

	local PvpString="[Pvp On]"
	if NoSave["Player"][PlayerData.id]["Pvp"] == false and (GetSetting("AllowPvpPrevent") or GetPerms(PlayerData.id) >= PermMod) then
		PvpString="[Pvp Off]"
	end

	local AntiStealString="[Antisteal On]"
	if NoSave["Player"][PlayerData.id]["AntiSteal"] == false then
		AntiStealString="[Antisteal Off]"
	end	

	local PlayerPos= server.getPlayerPos(PlayerData.id)		
	local PlayerX,PlayerY,PlayerZ = matrix.position(PlayerPos)


	local PvpEnabledPlayers="[Pvp Players]\n"
	local AnyPvp=false
	for _,A in pairs(NoSave["Player"]) do
		if A["Pvp"] then
			AnyPvp=true
			PvpEnabledPlayers=PvpEnabledPlayers .. TrainString(FixBlankPlayer(server.getPlayerName(A["PeerID"]),A["PeerID"]),15) .. "\n"
		end
	end
	if AnyPvp == false then
		PvpEnabledPlayers=PvpEnabledPlayers .. "No Players\n"
	end
	PvpEnabledPlayers=PvpEnabledPlayers .. "\n"
	local UIBuilder="-INFO-\nTPS: " .. TPS .. "\nVersion: " .. ServerConfig["Version"].."\nUptime:\n" .. UptimeString .. "\n\nPlaytime:\n" .. PlaytimeString .. "\n\n" .. PvpString .. "\n" .. AntiStealString .. "\n\n" .. PvpEnabledPlayers .. VehicleList .. "\nM/S: " .. tostring(NoSave["Player"][PlayerData.id]["Speed"]) .. "\nAlt:" .. (math.floor(PlayerY * 10) / 10) .. "m"


	server.setPopupScreen(PlayerData.id, 1, "", true,UIBuilder, -0.9, 0.5)
end

function ComputePlayerSpeed(PeerID)
	local PlayerPos=server.getPlayerPos(PeerID)
	local CurrentSpeed=matrix.distance(NoSave["Player"][PeerID]["LastPosition"],PlayerPos) * 12
	NoSave["Player"][PeerID]["LastPosition"]=PlayerPos
	for X,Y in pairs(NoSave["Player"][PeerID]["Speeds"]) do
		NoSave["Player"][PeerID]["Speeds"][X]=NoSave["Player"][PeerID]["Speeds"][X + 1]
	end
	NoSave["Player"][PeerID]["Speeds"][ServerConfig["SpeedHistoryLength"]]=CurrentSpeed

	local Speed=0
	for X =1,ServerConfig["SpeedHistoryLength"],1 do
		Speed=Speed + (NoSave["Player"][PeerID]["Speeds"][X] * (SpeedDivisor * X))
	end

	NoSave["Player"][PeerID]["Speed"]=math.floor(Speed * 10) / 10
end

function ConvertToBase64(Number,Digits)
	local DigitList={"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z","0","1","2","3","4","5","6","7","8","9","+","/"}
	local CheckValue=(64 ^ Digits) - 1
	if Number > CheckValue then
		Number=CheckValue 
	end
	local Multiplyer=64 ^ (Digits - 1)
	local Output=""
	for X=1,Digits do
		local Value=math.floor(Number / Multiplyer)
		Number=Number % Multiplyer
		Multiplyer=Multiplyer / 64
		Output=Output .. DigitList[Value + 1]
	end
	return Output
end

function onButtonPress(VehicleID, PeerID, ButtonNumber, Pressed)
	for _,X in pairs(g_savedata["Vehicles"]) do
		if X["Parts"][VehicleID] ~= nil then
			if NoSave["Player"][X["OwnerID"]] ~= nil then
				for _,Y in pairs(NoSave["Player"][X["OwnerID"]]["BlackListedPlayers"]) do
					if Y["SteamID"] == GetSteamID(PeerID) then
						RunEjectBlacklisted(PeerID,X["OwnerID"])
						return
					end
				end
			end
		end
	end
end


function RunEjectBlacklisted(PeerID,OwnerID)
	if TpList[tostring(GetSetting("EjectTpLocation"))] ~= nil then
		server.setPlayerPos(PeerID,TpList[tostring(GetSetting("EjectTpLocation"))][2])
	else
		server.setPlayerPos(PeerID,matrix.translation(0,0,0))
	end
	server.notify(PeerID,"Blacklisted","You are blacklisted from player with ID " .. math.floor(OwnerID) .. "'s vehicles",6)
	NoSave["Player"][tonumber(PeerID)]["Seat"]={VehicleID=-1,GroupID=-1,X=0,Y=0,Z=0}
end


function onPlayerSit(PeerID, VehicleID, SeatName)
	for _,X in pairs(g_savedata["Vehicles"]) do
		if X["Parts"][VehicleID] ~= nil then
			if NoSave["Player"][X["OwnerID"]] ~= nil then
				for _,Y in pairs(NoSave["Player"][X["OwnerID"]]["BlackListedPlayers"]) do
					if Y["SteamID"] == GetSteamID(PeerID) then
						RunEjectBlacklisted(PeerID,X["OwnerID"])
						return
					end
				end
			end
		end
	end
end

function RestartServer()
	SendHttp({"TypeRestart"})
end

function onTick()
	Ticks=Ticks + 1
	
	if ScriptReloaded then

		--AnnounceAbovePerms("[Ticks]", tostring(Ticks),PermMod,-1)
		for _,X in pairs(FilteredServerPlayers()) do
			local ObjectID = server.getPlayerCharacterID(X.id)
			if NoSave["Player"][X.id]["Pvp"] == false and (GetSetting("AllowPvpPrevent") or GetPerms(X.id) >= PermMod) then
				
				server.reviveCharacter(ObjectID)
				server.setCharacterData(ObjectID, 100000000, false, true)
			end
			if NoSave["Player"][X.id]["Freeze"]["State"] then
				server.setPlayerPos(X.id,NoSave["Player"][X.id]["Freeze"]["Pos"])
			else
				if NoSave["Player"][X.id]["Follow"]["State"] == true then
					if NoSave["Player"][NoSave["Player"][X.id]["Follow"]["Followed"]] ~= nil then
						local FollowedPos=server.getPlayerPos(NoSave["Player"][X.id]["Follow"]["Followed"])
						local FollowedX,FollowedY,FollowedZ= matrix.position(FollowedPos)
						server.setPlayerPos(X.id,matrix.translation(FollowedX,FollowedY + NoSave["Player"][X.id]["Follow"]["Height"],FollowedZ))
					end
				end
			end
		end
		
		if #NoSave["SeatQueue"] > 0 then
			for X,Y in pairs(NoSave["SeatQueue"]) do
				local Simulating, Found = server.getVehicleSimulating(Y["VehicleID"])
				if Found == false then
					table.remove(NoSave["SeatQueue"],X)
					server.notify(Y["PeerID"], "Invalid ID", "Please enter a valid vehicle ID", 6)
					break
				end
				if Simulating == true then
					local ObjectID=server.getPlayerCharacterID(Y["PeerID"])
					server.setSeated(ObjectID, Y["VehicleID"], Y["X"], Y["Y"], Y["Z"])
					ParseCommandGotoOutput(Y["PeerID"],Y["Type"],Y["GroupID"])
					table.remove(NoSave["SeatQueue"],X)
					break
				end
			end
		end
		
		if #NoSave["VehicleTPQueue"] > 0 then
			for X,Y in pairs(NoSave["VehicleTPQueue"]) do
			
				if Y["Type"] == "Group" then
					server.setGroupPos(Y["ID"], Y["TargetPos"])
				elseif Y["Type"] == "Vehicle" then
					server.setVehiclePos(Y["ID"], Y["TargetPos"])
				elseif Y["Type"] == "VehicleSafe" then
					server.setVehiclePosSafe(Y["ID"], Y["TargetPos"])
				elseif Y["Type"] == "MoveVehicle" then
					server.moveVehicle(Y["ID"],Y["TargetPos"])
				end
				ReseatPlayers(Y["SeatedPlayers"], Y["TargetPos"])
				table.remove(NoSave["VehicleTPQueue"],X)
				break
			end
		end

		if #NoSave["ChatMessageClearQueue"] > 0 then
			for X,Y in pairs(NoSave["ChatMessageClearQueue"]) do
				SendMessageHistory()
				table.remove(NoSave["ChatMessageClearQueue"],X)
				break
			end
		end

		if Ticks % 5 == 0 then
			TimeDifference=TimeDifference+ (server.getTimeMillisec() - LastMS)
			


			if LastTimeUpdate < math.floor(g_savedata["Seconds"] + (TimeDifference / 1000)) then
				g_savedata["Seconds"]=math.floor(g_savedata["Seconds"] + (TimeDifference / 1000))

				for _,X in pairs(FilteredServerPlayers()) do
					if g_savedata["PlayerData"][tostring(X["steam_id"])] ~= nil then
						g_savedata["PlayerData"][tostring(X["steam_id"])]["Playtime"]=math.floor(g_savedata["PlayerData"][tostring(X["steam_id"])]["Playtime"] + (TimeDifference / 1000)) 
						g_savedata["PlayerData"][tostring(X["steam_id"])]["LastJoin"]=g_savedata["Seconds"]
					end
				end
				LastTimeUpdate=g_savedata["Seconds"]
				TimeDifference=0
			end
			for _,X in pairs(FilteredServerPlayers()) do
				ComputePlayerSpeed(X.id)
				if NoSave["Player"][tonumber(X.id)]["DisableInv"] == true then
					local PlayerObjectID=server.getPlayerCharacterID(X.id)
					for T=1, 10 do
						server.setCharacterItem(PlayerObjectID,T,0,false,0,0)
					end
				end
			end
			ComputeTPS()

			if GetSetting("AntiRadiation") == true then
				server.clearRadiation()
			end
			if GetSetting("AntiOilSpill") == true then
				server.clearOilSpill()
			end
			if Ticks % 10 == 0 then
				g_savedata["NonCorrectedSeconds"]=g_savedata["NonCorrectedSeconds"] + 0.15625
				local Uptime=FormatTime(math.floor(g_savedata["Seconds"] - ServerStartTime))
				local UptimeString="[" .. tostring(Uptime[4] * 24 + Uptime[3]) .. "h," .. tostring(Uptime[2]) .. "m," .. tostring(Uptime[1]) .. "s]"
				for _,Y in pairs(FilteredServerPlayers()) do
					if NoSave["Player"][Y.id]["BanView"] then
						server.removePopup(Y.id,1)
						BannedPlayerUI(Y.id)
						server.setPlayerPos(Y.id,matrix.translation(69.420,69.420,69.420))
					else
						if GetSetting("UIEnabled") and NoSave["Player"][Y.id]["UI"] then
							UpdatePlayerUI(Y,UptimeString)
						else
							server.removePopup(Y.id,1)
							server.removePopup(Y.id,3)
						end
					end
				end

				for Y,X in pairs(g_savedata["Vehicles"]) do
					
					for _,A in pairs(FilteredServerPlayers()) do
						if NoSave["Player"][A.id]["PvpView"] == true then
							PvpViewPopup(X['GroupID'],A.id)
						end
						if NoSave["Player"][A.id]["TrackVehicles"]["State"] == true then
							TrackVehiclesPopup(X['GroupID'],A.id)
						end
					end
				end
				if Ticks % 30 == 0 then
					local ServerConfigData=GetServerConfigData()
					HeartBeatSend()

					
					if GetSetting("RandomAnnouncementsEnabled") then
						if LastAnnounceTime + ServerConfigData["RandomAnnouncementsFrequency"] < g_savedata["Seconds"] then
							LastAnnounceTime=g_savedata["Seconds"]
							LastAnnouncement=LastAnnouncement + 1
							Announce("[Server]",ServerConfigData["RandomAnnouncements"][LastAnnouncement])
							if LastAnnouncement == #ServerConfigData["RandomAnnouncements"] then
								LastAnnouncement=0
							end

						end
					end

					if (g_savedata["Seconds"] - LastSave) > 300 and ServerConfigData["Autosave"] == true then
					
						server.save()
						LastSave=g_savedata["Seconds"]
					end
					for _,Y in pairs(FilteredServerPlayers()) do
						local CharacterID=server.getPlayerCharacterID(Y.id)
						local SeatVehicle, Found = server.getCharacterVehicle(CharacterID)
						if Found and SeatVehicle ~= nil then
							local PlayersInVehicle=GetPlayersInVehicle(SeatVehicle)
							if PlayersInVehicle[Y.id] ~= nil then
								
								local Ejected=false
								if g_savedata["Vehicles"][PlayersInVehicle[Y.id][5]] ~= nil then
									local OwnerID=g_savedata["Vehicles"][PlayersInVehicle[Y.id][5]]["OwnerID"]
									if NoSave["Player"][OwnerID] ~= nil then
										for _,X in pairs(NoSave["Player"][OwnerID]["BlackListedPlayers"]) do
											if X["SteamID"] == tostring(Y.steam_id) then
												RunEjectBlacklisted(Y.id,OwnerID)
												
												Ejected=true
											end
										end
									end
								end
								if Ejected == false then
									NoSave["Player"][Y.id]["Seat"]={VehicleID=SeatVehicle,GroupID=PlayersInVehicle[Y.id][5],X=PlayersInVehicle[Y.id][2],Y=PlayersInVehicle[Y.id][3],Z=PlayersInVehicle[Y.id][4]}
									NoSave["Player"][Y.id]["Seated"]=true
								end
							end
						else
							NoSave["Player"][Y.id]["Seated"]=false
						end
					end
				end

			end
		end
	end
end

function GetAfterFirstArg(FullMessage,String)
	local MessageLow=string.lower(FullMessage)
	local i, j = string.find(MessageLow, string.lower(String):gsub("%W", "%%%1") .. " ")
	if j == nil or i == nil then
		return ""
	end
	return string.sub(FullMessage,j + 1,-1)
end

function CheckVehicleLimits(PeerID)
	local VehicleCount=CountPlayerVehicle(PeerID)
	if VehicleCount > GetSetting("VehicleLimit") then
		local OldestVehicle=ReturnFirstVehicle(PeerID)
		
		server.notify(PeerID, "Vehicle Limit Reached", "You have reached the server vehicle limit of " .. math.floor(GetSetting("VehicleLimit")) ..  ". Despawning your oldest vehicle #" .. math.floor(OldestVehicle) , 8)
		server.despawnVehicleGroup(OldestVehicle,true)
	end
end

function ReturnComponentNumber(Component)
	local Number=CountItems(Component)
	if Number == nil then
		return 0
	end
	return Number
end

function GetVehicleWithMostVoxels(GroupID) 
	local MostVoxels={-1,0}
	local TotalVoxels=0
	local VehicleComponents={signs=0,seats=0,buttons=0,dials=0,tanks=0,batteries=0,hoppers=0,guns=0,rope_hooks=0}
	local TotalMass=0
	for X,_ in pairs(g_savedata["Vehicles"][GroupID]["Parts"]) do
		local VehicleData,Found=server.getVehicleComponents(tonumber(X))
		if Found == true then
			local Voxels=VehicleData["voxels"]
			TotalMass=TotalMass + VehicleData["mass"]
			if VehicleData["components"] ~= nil then
				VehicleComponents["signs"]=VehicleComponents["signs"] + ReturnComponentNumber(VehicleData["components"]["signs"])
				VehicleComponents["seats"]=VehicleComponents["seats"] + ReturnComponentNumber(VehicleData["components"]["seats"])
				VehicleComponents["buttons"]=VehicleComponents["buttons"] + ReturnComponentNumber(VehicleData["components"]["buttons"])
				VehicleComponents["dials"]=VehicleComponents["dials"] + ReturnComponentNumber(VehicleData["components"]["dials"])
				VehicleComponents["tanks"]=VehicleComponents["tanks"] + ReturnComponentNumber(VehicleData["components"]["tanks"])
				VehicleComponents["batteries"]=VehicleComponents["batteries"] + ReturnComponentNumber(VehicleData["components"]["batteries"])
				VehicleComponents["hoppers"]=VehicleComponents["hoppers"] + ReturnComponentNumber(VehicleData["components"]["hoppers"])
				VehicleComponents["guns"]=VehicleComponents["guns"] + ReturnComponentNumber(VehicleData["components"]["guns"])
				VehicleComponents["rope_hooks"]=VehicleComponents["rope_hooks"] + ReturnComponentNumber(VehicleData["components"]["rope_hooks"])
			end
			if Voxels == nil then
				return -1,0
			end
			TotalVoxels=TotalVoxels + Voxels
			if Voxels > MostVoxels[2] then
				MostVoxels={X,Voxels}
			end
		end
	end
	g_savedata["Vehicles"][GroupID]["MainBody"]= MostVoxels[1]
	g_savedata["Vehicles"][GroupID]["Voxels"]=TotalVoxels
	g_savedata["Vehicles"][GroupID]["Mass"]=TotalMass
	g_savedata["Vehicles"][GroupID]["VehicleComponents"]=VehicleComponents
end

function onGroupLoad(GroupID)
	if g_savedata["Vehicles"][GroupID]["Loaded"] == false then
		g_savedata["Vehicles"][GroupID]["Loaded"]=true
		local OwnerID=g_savedata["Vehicles"][GroupID]["OwnerID"]
		local PlayerName=FixBlankPlayer(server.getPlayerName(OwnerID),OwnerID)

		g_savedata["Vehicles"][GroupID]["Name"]="Unknown"
		if g_savedata["Vehicles"][GroupID]["MainBody"] ~= -1 then
			local VehicleData=server.getVehicleData(g_savedata["Vehicles"][GroupID]["MainBody"])
			if VehicleData["name"] ~= "" then
				g_savedata["Vehicles"][GroupID]["Name"]=VehicleData["name"]
				--Announce("Test",VehicleData["name"])
			end
		end
		AnnounceAbovePerms("[Vehicle Loaded]", PlayerName .. "'s vehicle named " .. g_savedata["Vehicles"][GroupID]["Name"] .. " and with ID " .. GroupID .. " has fully loaded",PermMod,OwnerID)
		if g_savedata["Vehicles"][GroupID]["MainBody"] ~= -1 then
			for _,X in pairs(FilteredServerPlayers()) do
				PvpViewPopup(GroupID,X.id)
				TrackVehiclesPopup(GroupID,X.id)
			end
			
		end
		g_savedata["Vehicles"][GroupID]["LoadedTime"]=g_savedata["NonCorrectedSeconds"]
	end
end

function onGroupSpawn(GroupID, PeerID, X, Y, Z, Cost)
	if PeerID ~= nil and PeerID > -1 and Cost ~= nil then
		server.notify(PeerID, "Vehicle Spawned", "Vehicle ID: " .. GroupID, 8)
		local Name=FixBlankPlayer(server.getPlayerName(PeerID),PeerID)
		local PlayerSteamID=GetSteamID(PeerID)
		g_savedata["PlayerData"][PlayerSteamID]["VehicleCount"]=g_savedata["PlayerData"][PlayerSteamID]["VehicleCount"] + 1
		AnnounceAbovePerms("[Vehicle Spawned]", Name .. " has spawned vehicle with ID " .. GroupID,PermMod,PeerID)
		SendHttp({"TypeVehicleSpawn",GroupID,PeerID,Name,PlayerSteamID,g_savedata["Vehicles"][GroupID]["Name"]})


		if GetSetting("EnforceVehicleLimit") == true then
			CheckVehicleLimits(PeerID)
		end

	end
end

function onGroupDespawn(GroupID,PeerID)
	
	if NoSave["Player"][PeerID] ~= nil then
		local Name=FixBlankPlayer(server.getPlayerName(PeerID),PeerID)
		AnnounceAbovePerms("[Vehicle Despawned]", Name .. " has despawned vehicle named " .. g_savedata["Vehicles"][GroupID]["Name"] .. " with ID " .. GroupID,PermMod,PeerID)
		server.notify(PeerID, "Vehicle Despawned", "Vehicle ID: " .. GroupID, 8)

		SendHttp({"TypeVehicleDespawn",GroupID,Name,GetSteamID(PeerID),g_savedata["Vehicles"][GroupID]["Name"]})
	end
end



function onVehicleSpawn(VehicleID, PeerID, X, Y, Z, Cost,GroupID)
	
	if PeerID ~= nil and PeerID > -1 and Cost ~= nil then
		server.setVehicleEditable(VehicleID, false)
		ValidateVehicleData(GroupID,PeerID)
		
		g_savedata["Vehicles"][GroupID]["Parts"][VehicleID]=false
		if GetSetting("VehicleTooltips") then
			SetVehicleToolTip(VehicleID,GroupID,PeerID)
		end

		if NoSave["Player"][PeerID]["Pvp"] == false and (GetSetting("AllowPvpPrevent") or GetPerms(PeerID) >= PermMod) then 
			server.setVehicleInvulnerable(VehicleID,true)
		else
			server.setVehicleInvulnerable(VehicleID,false)
		end


		
		if NoSave["Player"][PeerID]["AntiSteal"] == false then
			server.setVehicleEditable(VehicleID, true)
		end
			
	end
end

function onVehicleLoad(VehicleID)
	local GroupID,Sucess=server.getVehicleData(VehicleID)
	if Sucess == true then
		GroupID=GroupID["group_id"]
		if g_savedata["Vehicles"][GroupID] ~= nil then
			if g_savedata["Vehicles"][GroupID]["Parts"][VehicleID] == false then
				
				g_savedata["Vehicles"][GroupID]["Parts"][VehicleID]=true
				for _,Y in pairs(g_savedata["Vehicles"][GroupID]["Parts"]) do
					if Y == false then
						return
					end
				end
				onGroupLoad(GroupID)
			end
			
		end
	end
end

function onVehicleDespawn(VehicleID, PeerID)
	for X,Y in pairs(g_savedata["Vehicles"]) do
		if Y["Parts"][VehicleID] ~= nil then
			g_savedata["Vehicles"][Y["GroupID"]]["Parts"][VehicleID]=nil
		end
		if g_savedata["Vehicles"][Y["GroupID"]]["MainBody"] == VehicleID then
			GetVehicleWithMostVoxels(Y["GroupID"])
		end
	end
	CheckVehicleDespawns()
end

function GetPlayersInVehicle(VehicleID)
	local VehicleData, Found=server.getVehicleComponents(VehicleID)
	
	local PlayersFound={}
	if Found then
		if VehicleData["components"] ~= nil then
			if VehicleData["components"]["seats"] ~= nil then
				local GroupID=server.getVehicleData(VehicleID)["group_id"]
				for _,X in pairs(VehicleData["components"]["seats"]) do
					if X["seated_id"] ~= 4294967295 then
						local SeatedID=CharacterIDToPlayerID(X["seated_id"])
						if SeatedID ~= nil then
							PlayersFound[SeatedID]={SeatedID,X["pos"]["x"],X["pos"]["y"],X["pos"]["z"],GroupID}
						end
					end
				end
			end
		end
	end
	return PlayersFound
end

function TeleportPlayerToVehicle(VehicleID,PeerID)
	local VehiclePos = server.getVehiclePos(VehicleID)
	server.setPlayerPos(PeerID, VehiclePos)
end

function GotoVehicle(GroupID,PeerID)
	
	if NoSave["Player"][PeerID]["Seat"]["GroupID"] == GroupID then
		local SeatData = server.getVehicleSeat(NoSave["Player"][PeerID]["Seat"]["VehicleID"], NoSave["Player"][PeerID]["Seat"]["X"], NoSave["Player"][PeerID]["Seat"]["Y"],  NoSave["Player"][PeerID]["Seat"]["Z"])
		if SeatData ~= nil then
			local PlayerInVehicle=false
			if SeatData["seated_id"] ~= 4294967295 then
				if server.getPlayerCharacterID(PeerID) == SeatData["seated_id"] then
					PlayerInVehicle=true
				end
			end
			if SeatData["seated_id"] == 4294967295 or g_savedata["Vehicles"][GroupID]["OwnerID"] == PeerID or PlayerInVehicle then
				NoSave["Player"][PeerID]["Follow"]={State=false,Followed=-1,Height=100}
				if SeatData["seated_id"] ~= 4294967295 and PlayerInVehicle == false then
					local ObjectPos= server.getObjectPos(SeatData["seated_id"])
					server.setObjectPos(SeatData["seated_id"], ObjectPos)
				end
				TeleportPlayerToVehicle(NoSave["Player"][PeerID]["Seat"]["VehicleID"],PeerID)
				table.insert(NoSave["SeatQueue"],{PeerID=PeerID,GroupID=GroupID,VehicleID=NoSave["Player"][PeerID]["Seat"]["VehicleID"],X=NoSave["Player"][PeerID]["Seat"]["X"], Y=NoSave["Player"][PeerID]["Seat"]["Y"],  Z=NoSave["Player"][PeerID]["Seat"]["Z"],Type="LastSeat"})
				return 1
			end
		end
	end
	if g_savedata["Vehicles"][tonumber(GroupID)] ~= nil then
		if (not GetSetting("NonAdminGotoOnlyOwned")) or g_savedata["Vehicles"][tonumber(GroupID)]["OwnerID"] == PeerID or GetPerms(PeerID) >= PermMod then
			for X,_ in pairs(g_savedata["Vehicles"][tonumber(GroupID)]["Parts"]) do
				local VehicleData, Found=server.getVehicleComponents(X)
				if Found then
					if VehicleData["components"] ~= nil then
						if VehicleData["components"]["seats"] ~= nil then
							for _,A in pairs(VehicleData["components"]["seats"]) do
								--Announce("eawfwef",A["seated_id"],1)
								if A["seated_id"] == 4294967295 then
									NoSave["Player"][PeerID]["Follow"]={State=false,Followed=-1,Height=100}
									TeleportPlayerToVehicle(X,PeerID)
									table.insert(NoSave["SeatQueue"],{PeerID=PeerID,GroupID=GroupID,VehicleID=X,X=A["pos"]["x"], Y=A["pos"]["y"],  Z=A["pos"]["z"],Type="FoundSeat"})
									return 1
								end
							end
						end
					end
				end
			end
			
			return -2
		else
			return -1
		end
	else
		return -3
	end
end



function ShowAuthPopup(PeerID)
	local ServerConfigData=GetServerConfigData()
	server.setPopupScreen(PeerID, 2, "", true, ServerConfigData["AuthPopupText"], 0, 0)
end

function onPlayerDie(SteamID, Name, PeerID, Admin, Auth)
	if NoSave["Player"][PeerID]["Pvp"] == true or not (GetSetting("AllowPvpPrevent") or GetPerms(PeerID) >= PermMod) then
		if NoSave["Player"][PeerID]["LastShowedDeathMessage"] + 2 < g_savedata["Seconds"]  then
			local PermString=""
			if g_savedata["Settings"]["ShowPermissionsInChat"] == true then
				PermString="[" .. ParsePermissions(GetPerms(PeerID),true) .. "] "
			end
			Announce("[Death]",PermString..  Name .. " has died")
			SendHttp({"TypeDeath",PeerID,Name,SteamID})
			NoSave["Player"][PeerID]["LastShowedDeathMessage"]=g_savedata["Seconds"]
			if g_savedata["PlayerData"][tostring(SteamID)] ~= nil then
				g_savedata["PlayerData"][tostring(SteamID)]["DeathCount"]=g_savedata["PlayerData"][tostring(SteamID)]["DeathCount"] + 1
			end
		end
	end
end

function GetPlayerItemDrops(PeerID)
	local Drops={}
	for X,Y in pairs(g_savedata["Items"]) do
		if Y == PeerID then
			table.insert(Drops,X)
		end
	end
	return Drops
end

function onEquipmentDrop(DropperID, TargetID, EquipmentID)
	local PlayerID=CharacterIDToPlayerID(DropperID)
	local DropperData= server.getObjectData(DropperID)
	--Announce("test",tostring(PlayerID) .. " " .. tostring(EquipmentID))
	if GetSetting("NoDropsOnDeath") and (DropperData["dead"] or DropperData["incapacitated"]) then
		server.despawnObject(TargetID,true)
		return
	end

	if GetSetting("DisableItemDrops") then
		server.despawnObject(TargetID,true)
		server.notify(PlayerID, "AntiLag","Droping items has been disabled", 6)
		return
	end

	g_savedata["Items"][TargetID]=PlayerID
	if GetSetting("EnforceItemLimit") then
		
		while true == true do
			local Drops=GetPlayerItemDrops(PlayerID)
			--Announce("fawe",tostring(CountItems(Drops)))
			if CountItems(Drops) > GetSetting("ItemLimit") then
				Lowest=100000000000
				for _,X in pairs(Drops) do
					if X < Lowest then
						Lowest=X
					end
				end
				server.despawnObject(Lowest,true)
				g_savedata["Items"][Lowest]=nil
			else
				break
			end
		end
	end
	
end

function onEquipmentPickup(DropperID, TargetID, EquipmentID)
	g_savedata["Items"][TargetID]=nil
end

function GiveDefaultKit(PeerID)
	local ServerConfigData=GetServerConfigData() 
	local PlayerObjectID=server.getPlayerCharacterID(PeerID)
	for X=1, 10 do
		local SlotEquipment= ServerConfigData["DefaultKit"][X]
		if SlotEquipment ~= nil and SlotEquipment ~= 0 then
			GiveItem(PeerID,SwItemToLocalItem(SlotEquipment),X)
		else
			server.setCharacterItem(PlayerObjectID, X, 0, false)
		end
	end
end

function onPlayerRespawn(PeerID)
	if NoSave["Player"][PeerID] ~= nil then
		if NoSave["Player"][PeerID]["PvpOffOnRespawn"] then
			NoSave["Player"][PeerID]["Pvp"]=false
			NoSave["Player"][PeerID]["PvpOffOnRespawn"]=false
		end
		if GetSetting("UseDefaultKit") == true then
			GiveDefaultKit(PeerID)
		end
	end
end

function DespawnPlayerItems(PeerID)
	local Drops=GetPlayerItemDrops(PlayerID)
	for _,X in pairs(Drops) do
		server.despawnObject(X,true)
		g_savedata["Items"][X]=nil
	end
end

function CheckBannedStatus(SteamID)
	if g_savedata["PlayerData"][SteamID] ~= nil then
		--Announce("awafwe", tostring(g_savedata["PlayerData"][SteamID]["Banned"]["State"]))
		if g_savedata["PlayerData"][SteamID]["Banned"]["State"] == true then
			--Announce("awafwe","2")
			local BanTime=g_savedata["PlayerData"][SteamID]["Banned"]["BanTime"]
			local BannedTime=g_savedata["PlayerData"][SteamID]["Banned"]["BannedTime"]
			local Remaining=(BannedTime + BanTime) - g_savedata["Seconds"]
			if Remaining < 0 then
				g_savedata["PlayerData"][SteamID]["Banned"]["State"] =false
				
			else
				return Remaining
			end
		end
	end
	return false
end

function BlindPlayer(PeerID,BlindState)
	local Count=0
	for X=-1.2,1.2,0.1 do
		for Y=-1.2,1.2,0.2 do
			Count=Count + 1
			if BlindState then
				server.setPopupScreen(PeerID, Count + 10000 , "blind", true, "  \n   \n   \n   \n   \n   \n   \n   \n   \n   \n   \n   \n   \n   \n   \n   ", X, Y)
			else
				server.removePopup(PeerID,  Count + 10000)
			end
		end
	end
end

function BannedPlayerUI(PeerID)
	local SteamID=GetSteamID(PeerID)
	local BanStatus = CheckBannedStatus(SteamID)
	if BanStatus ~= false then
		local BanTimeString=BanTimeStampFormatter(BanStatus)
		local ServerConfigData=GetServerConfigData()
		server.setPopupScreen(PeerID, 100000 , "blind", true, "Tempbanned", 0, 0.6)
		server.setPopupScreen(PeerID, 100001 , "blind", true, "Time Left:\n" .. BanTimeString, 0, 0.5)
		server.setPopupScreen(PeerID, 100002 , "blind", true, "Reason:\n" .. g_savedata["PlayerData"][SteamID]["Banned"]["Reason"], 0, 0.2)
		if ServerConfigData["DiscordLink"] ~= "" then
			server.setPopupScreen(PeerID, 100003 , "blind", true, "You can appeal on the discord:\n" .. ServerConfigData["DiscordLink"], 0.5, 0.5)
		end
		if NoSave["Player"][PeerID]["Joined"] + 120 < g_savedata["Seconds"] then
			server.kickPlayer(PeerID)
		end
	else
		server.kickPlayer(PeerID)
	end
end

function SetupBannedPlayer(SteamID,PeerID,BanStatus)
	local BanTimeString=BanTimeStampFormatter(BanStatus)
	AnnounceAbovePerms("[Server]",FixBlankPlayer(server.getPlayerName(PeerID),PeerID) .. ' is banned for "' .. g_savedata["PlayerData"][SteamID]["Banned"]["Reason"] .. '" with ' .. BanTimeString .. " remaining",PermNone,-1)
	BlindPlayer(PeerID,true)
	NoSave["Player"][PeerID]["BanView"]=true
	NoSave["Player"][PeerID]["Muted"] =true
end

function onPlayerJoin(SteamID, Name, PeerID, Admin, Auth)
	SteamID=tostring(SteamID)
	ValidatePlayerData(PeerID)

	local OldNameString=""
	if g_savedata["PlayerData"][SteamID] ~= nil then
		if g_savedata["PlayerData"][SteamID]["FirstJoin"] == -1 then
			g_savedata["PlayerData"][SteamID]["FirstJoin"]=g_savedata["Seconds"]
		end
		g_savedata["PlayerData"][SteamID]["JoinCount"]=g_savedata["PlayerData"][SteamID]["JoinCount"] + 1
		if g_savedata["PlayerData"][SteamID]["Name"] ~= server.getPlayerName(PeerID) then
			if g_savedata["PlayerData"][SteamID]["Name"] ~= "" then
				OldNameString=" (Previously " .. g_savedata["PlayerData"][SteamID]["Name"]  .. ")"
			end
			g_savedata["PlayerData"][SteamID]["Name"]=server.getPlayerName(PeerID)
		end
	end
	local PermString=""
	if g_savedata["Settings"]["ShowPermissionsInChat"] == true then
		PermString="[" .. ParsePermissions(GetPerms(PeerID),true) .. "] "
	end
	for _,Y in pairs(FilteredServerPlayers()) do
		if GetPerms(Y.id) >= PermMod then
			Announce("[Server]", PermString .. Name .. " joined the game" .. OldNameString .. ". Their steam ID is " ..tostring(SteamID),Y.id)
		else
			Announce("[Server]", PermString .. Name .. " joined the game" .. OldNameString, Y.id)
		end
	end
	
	server.removeAuth(PeerID)
	AddToMessageHistory("[Server]","De-Authed " .. Name,-1)
	server.removeAdmin(PeerID)
	AddToMessageHistory("[Server]","De-Admin " .. Name,-1)
	
	local BanStatus=CheckBannedStatus(SteamID)
	if BanStatus ~= false and GetPerms(PeerID) < 10000 then
		SetupBannedPlayer(SteamID,PeerID,BanStatus)
		SendHttp({"TypeBannedPlayerJoin",PeerID,Name,SteamID})
	else
		SendHttp({"TypePlayerJoin",PeerID,Name,SteamID})
	end

	

	
	local ServerConfigData=GetServerConfigData()
	if NoSave["Player"][PeerID]["BanView"] == false then
		if ServerConfigData["AutoAuth"] == true then
			server.addAuth(PeerID)
			UpdatePlayerPermissions(PeerID)
		elseif ServerConfigData["AuthOnAcceptPopup"] == true then
			ShowAuthPopup(PeerID)
		end

		if GetSetting("UseDefaultKit") == true then
			GiveDefaultKit(PeerID)
		end

		if GetPerms(PeerID) >= ServerConfig["AdminPermLevel"] then
			server.addAdmin(PeerID)
			AddToMessageHistory("[Server]","Admin " .. Name,-1)
		end

		Announce("[Server]", "Welcome to " .. ServerConfigData["ServerName"] .. ". For command help do ?help. To view the rules do ?rules.", PeerID)
		for Y,X in pairs(g_savedata["PlayerData"][SteamID]["History"]) do
			if X["Seen"] == nil then
				g_savedata["PlayerData"][SteamID]["History"][Y]["Seen"]=true
			end
	
			if X["Seen"] == false and X["Type"] == "Warn" then
				Announce("Offline Warn","While offline you were warned by " .. X["StaffMember"]  .. ' for "' .. X["Reason"] .. '". You are at ' .. math.floor(X["Warns"]) .. " warns",PeerID)
				g_savedata["PlayerData"][SteamID]["History"][Y]["Seen"]=true
			end
		end

		
	end
	
end

function onPlayerLeave(SteamID, Name, PeerID, Admin, Auth)
	DespawnPlayerItems(PeerID)
	local PermString=""
	if g_savedata["Settings"]["ShowPermissionsInChat"] == true then
		PermString="[" .. ParsePermissions(GetPerms(PeerID),true) .. "] "
	end
	for _,Y in pairs(FilteredServerPlayers()) do
		if GetPerms(Y.id) >= PermMod then
			Announce("[Server]", PermString .. Name .. " left the game. Their steam ID is " ..tostring(SteamID),Y.id)
		else
			Announce("[Server]",PermString .. Name .. " left the game",Y.id)
		end

		if NoSave["Player"][Y.id]["Follow"]["State"] == true then
			if NoSave["Player"][Y.id]["Follow"]["Followed"] == PeerID then
				NoSave["Player"][Y.id]["Follow"]={State=false,Followed=-1,Height=100}
				server.notify(Y.id,"Unfollow Success", "The player you were following has left the server. Following has been ended.", 6)	
			end
		end
	end
	
	if GetSetting("ClearVehiclesOnLeave") == true then
		for _,Y in pairs(g_savedata["Vehicles"]) do
			if Y["OwnerID"] == PeerID then
				server.despawnVehicleGroup(Y["GroupID"],true)
			end
		end
	end
	

	if NoSave["Player"][PeerID] ~= nil then
		if NoSave["Player"][PeerID]["BanView"] ~= true then
			SendHttp({"TypePlayerLeave",PeerID,Name,SteamID})
		else
			SendHttp({"TypeBannedPlayerLeave",PeerID,Name,SteamID})
		end
		NoSave["Player"][PeerID]=nil
	end
end

function FilterText(Text)
	local BannedWords=GetServerConfigData()["BannedWords"]
	for _,X in pairs(BannedWords) do
		Text=Text:gsub(X,string.rep("*",string.len(X)))
	end
	return Text
end

function onChatMessage(PeerID, PlayerName, Message)
	--Announce("Test",":"..PlayerName..":")
	--if RemoveTrailingAndLeading(PlayerName:gsub('%W','')) == "" then
	PlayerName=FixBlankPlayer(PlayerName,PeerID)
	Message=FilterText(Message)
	if NoSave["Player"][PeerID]["Muted"] == false then
		if g_savedata["Settings"]["ShowPermissionsInChat"] == true then
			local PermString=ParsePermissions(GetPerms(PeerID),true)
			AddToMessageHistory("[".. PermString .. "] " .. PlayerName,Message,-1)
			table.insert(NoSave["ChatMessageClearQueue"],"ClearChat")
		else
			AddToMessageHistory(PlayerName,Message,-1)
		end
		SendHttp({"TypeChatMessage",PeerID,PlayerName,Message,GetSteamID(PeerID)})
	else
		AnnounceAbovePerms("[Muted]",PlayerName .. " - " .. Message,PermMod,-1)
		SendHttp({"TypeMutedChatMessage",PeerID,PlayerName,Message,GetSteamID(PeerID)})
		AddToMessageHistory("[Server]","You are muted",PeerID)
		table.insert(NoSave["ChatMessageClearQueue"],"ClearChat")
	end
end

function CommandClearVehicle(FullMessage, PeerID, Admin, Auth, Command, One, Two, Three, Four, Five,Discord)
	if One == nil then
		local Found=false
		for X,Y in pairs(g_savedata["Vehicles"]) do
			if Y["OwnerID"] == PeerID then
				is_success = server.despawnVehicleGroup(Y["GroupID"], true)
				Found=true
			end
		end
		if not Found then
			server.notify(PeerID, "Despawn Failed", "You have no spawned vehicles", 6)
		end
		return
	else
		if g_savedata["Vehicles"][tonumber(One)] ~= nil then
			if g_savedata["Vehicles"][tonumber(One)]["OwnerID"] == PeerID or GetPerms(PeerID) >= PermMod then
				
				if g_savedata["Vehicles"][tonumber(One)]["OwnerID"] ~= PeerID then
					server.notify(PeerID, "Despawn Success", "Despawned vehicle with ID " .. One, 5)
				end
				server.despawnVehicleGroup(tonumber(One), true)
				return
			end
		else
			if GetPerms(PeerID) >= PermMod then
				local Success = server.despawnVehicleGroup(tonumber(One), true)
				if Success then
					server.notify(PeerID, "Force Despawn Success", "Despawned vehicle with ID " .. One, 5)
				else
					server.notify(PeerID, "Force Despawn Failed", "Unable to despawn vehicle with ID " .. One, 6)
				end
				return
			end
		end
	end
	server.notify(PeerID, "Invalid ID", "Non admins can only despawn vehicles that they spawned", 6)
end

function CommandPvp(FullMessage, PeerID, Admin, Auth, Command, One, Two, Three, Four, Five, Discord)
	if One == nil then
		if GetSetting("AllowPvpPrevent") or GetPerms(PeerID) >= PermMod then
			local PlayerName = FixBlankPlayer(server.getPlayerName(PeerID),PeerID)
			ChangePvp(PeerID,not NoSave["Player"][PeerID]["Pvp"],true)
			
			server.notify(PeerID, "Pvp Setting Changed", "Set pvp to " .. tostring(NoSave["Player"][PeerID]["Pvp"]), 5)
		else
			server.notify(PeerID, "Pvp Toggle Failed", "Pvp state changing not enabled for non admins", 6)
		end
	else
		local OneID=ConvertToPeer(One)
		if OneID ~= nil then
			local PlayerName = FixBlankPlayer(server.getPlayerName(tonumber(OneID)),tonumber(OneID))
			DiscordNotify(PeerID, "Pvp Status", PlayerName .. " has set pvp to " .. tostring(NoSave["Player"][tonumber(OneID)]["Pvp"]), 5,Discord)
		else
			DiscordNotify(PeerID, "Invalid ID", "Please enter a valid player ID", 6,Discord)
		end
	end
end

function CommandAntiSteal(FullMessage, PeerID, Admin, Auth, Command, One, Two, Three, Four, Five, Discord)
	if NoSave["Player"][PeerID]["AntiSteal"] then
		
		ChangeAntiSteal(PeerID,false)
	else
		ChangeAntiSteal(PeerID,true)
	end
	server.notify(PeerID, "Antisteal Setting Changed", "Set antisteal to " .. tostring(NoSave["Player"][PeerID]["AntiSteal"]), 5)	
end

function CommandTTP(FullMessage, PeerID, Admin, Auth, Command, One, Two, Three, Four, Five, Discord)
	
	if GetPerms(PeerID) >= PermMod or GetSetting("NonAdminTpToPlayer") then 
		local OneID=ConvertToPeer(One)
		if OneID ~= nil then
			local Pos= server.getPlayerPos(tonumber(OneID))
			NoSave["Player"][PeerID]["Follow"]={State=false,Followed=-1,Height=100}
			server.setPlayerPos(PeerID, Pos)
			server.notify(PeerID, "TTP Success", "Teleported to player with ID " .. OneID, 5)
		else
			InvalidPlayerID(PeerID)
		end
	else
		server.notify(PeerID, "TTP Failed", "Teleporting to player is not enabled for non admins", 6)
	end
		
end

function CommandTTM(FullMessage, PeerID, Admin, Auth, Command, One, Two, Three, Four, Five, Discord)
	
	local OneID=ConvertToPeer(One)
	if OneID ~= nil then
		local Pos= server.getPlayerPos(tonumber(PeerID))
		server.setPlayerPos(OneID, Pos)
		server.notify(PeerID, "TTM Success", "Player with ID " .. OneID .. " has been teleported to you", 5)
	else
		InvalidPlayerID(PeerID)
	end
		
end

function PlayerSeatedGroupList(GroupID)
	local GroupPlayersInVehicle={}
	if g_savedata["Vehicles"][GroupID] ~= nil then
		for X,_ in pairs(g_savedata["Vehicles"][GroupID]["Parts"]) do
			GroupPlayersInVehicle[tostring(X)]=GetPlayersInVehicle(tonumber(X))
		end
	end
	return GroupPlayersInVehicle
end

function ReseatPlayers(PlayerGroupSeats,TargetPos)
	for X,Y in pairs(PlayerGroupSeats) do
		for _,A in pairs(Y) do
			if TargetPos ~= nil then
				server.setPlayerPos(A[1], TargetPos)
			end
			table.insert(NoSave["SeatQueue"],{PeerID=A[1],GroupID=A[5],VehicleID=X,X=A[2], Y=A[3],  Z=A[4],Type="VehicleTeleport"})
		end
	end
end

function CountPlayerVehicle( PeerID)
	local VehicleCount=0
	for _,X in pairs(g_savedata["Vehicles"]) do
		if X["OwnerID"] == PeerID then
			VehicleCount=VehicleCount + 1
		end
	end
	return VehicleCount
end

function ReturnFirstVehicle(PeerID)
	local LowestVehicleID=1000000000
	for _,X in pairs(g_savedata["Vehicles"]) do
		if X["OwnerID"] == PeerID then
			if X["GroupID"] < LowestVehicleID then
				LowestVehicleID=X["GroupID"]
			end
		end
	end
	return LowestVehicleID
end

function CommandTVTM(FullMessage, PeerID, Admin, Auth, Command, One, Two, Three, Four, Five, Discord)
	if GetPerms(PeerID) >= PermMod or GetSetting("NonAdminTeleportVehicles") then 
		if (One == nil or One == "") and CountPlayerVehicle(PeerID) == 1 then
			One=ReturnFirstVehicle(PeerID)
		end
		if g_savedata["Vehicles"][tonumber(One)] ~= nil then
			
			if g_savedata["Vehicles"][tonumber(One)]["OwnerID"] == PeerID or GetPerms(PeerID) >= PermMod then
				local Playersiting=PlayerSeatedGroupList(tonumber(One))
					
				local PlayerPos= server.getPlayerPos(PeerID)
				local PlayerLookX, PlayerLookY, PlayerLookZ = server.getPlayerLookDirection(PeerID)				
				local PlayerX,PlayerY,PlayerZ = matrix.position(PlayerPos)


				local TargetPos=matrix.multiply(matrix.translation(PlayerX,PlayerY + 3.5,PlayerZ),matrix.rotationY(math.atan(PlayerLookX,PlayerLookZ)))--+MA.pi


				table.insert(NoSave["VehicleTPQueue"],{TargetPos=TargetPos,Type="Group",ID=tonumber(One),SeatedPlayers=Playersiting})

				
				server.notify(PeerID, "TVTM Success", "Vehicle with ID " .. One .. " has been teleported to you", 5)
			else
				server.notify(PeerID, "Invalid ID", "Non admins can only teleport vehicles that they spawned", 6)
			end
		else
			server.notify(PeerID, "Invalid ID", "Please enter a valid vehicle ID", 6)
		end
	else
		server.notify(PeerID, "TVTM Failed", "Teleporting a vehicle to you is not enabled for non admins", 6)
	end
		
end

function CommandGps(FullMessage, PeerID, Admin, Auth, Command, One, Two, Three, Four, Five, Discord)
	local Pos= server.getPlayerPos(PeerID)
	local X,Y,Z = matrix.position(Pos)
	server.notify(PeerID, "Your Position", "X: " .. math.floor(X * 100) / 100 .. "  Y: " .. math.floor(Y * 100) / 100 .. "  Z: " .. math.floor(Z * 100) / 100 , 5)
		
end

function CommandUI(FullMessage, PeerID, Admin, Auth, Command, One, Two, Three, Four, Five, Discord)
	
	if GetSetting("UIEnabled") == true or GetPerms(PeerID) >= PermMod then
		if NoSave["Player"][PeerID]["UI"] then
			NoSave["Player"][PeerID]["UI"]=false
		else
			NoSave["Player"][PeerID]["UI"]=true
		end
		server.notify(PeerID, "UI Setting Change Success", "Set showing UI to " .. tostring(NoSave["Player"][PeerID]["UI"]), 5)
	else
		server.notify(PeerID, "UI Toggle Failed", "Only admins can toggle the UI.", 6)
	end
end

function ParseCommandGotoOutput(PeerID,Output,VehicleID)
	if Output == -2 then
		server.notify(PeerID,"Goto Failed","No unoccupied seat found for vehicle with ID " .. VehicleID,6)	
	elseif Output == -1 then
		server.notify(PeerID,"Goto Failed","Non admins can only goto a vehicle they own",6)	
	elseif Output == -3 then
		server.notify(PeerID, "Invalid ID", "Please enter a valid vehicle ID", 6)
	elseif Output == "LastSeat" then
		server.notify(PeerID,"Goto Success","Teleported you to your last seat",5)	
	elseif Output == "FoundSeat" then
		server.notify(PeerID,"Goto Success","Teleported to first unoccupied seat found for vehicle with ID " .. VehicleID,5)	
	end
end

function CommandGoto(FullMessage, PeerID, Admin, Auth, Command, One, Two, Three, Four, Five, Discord)
	if GetSetting("NonAdminGoto") or GetPerms(PeerID) >= PermMod then
		if tonumber(One) == nil then
			if NoSave["Player"][PeerID]["Seat"]["GroupID"] ~= -1 then
				local Result=GotoVehicle(NoSave["Player"][PeerID]["Seat"]["GroupID"],PeerID)
				ParseCommandGotoOutput(PeerID,Result,NoSave["Player"][PeerID]["Seat"]["GroupID"])
			else
				server.notify(PeerID, "Goto Failed", "No seat found", 6)
			end
		else
			if g_savedata["Vehicles"][tonumber(One)] ~= nil then
				local Result=GotoVehicle(tonumber(One),PeerID)
				ParseCommandGotoOutput(PeerID,Result,tonumber(One))
			else
				server.notify(PeerID, "Invalid ID", "Please enter a valid vehicle ID", 6)
			end
		end
	else
		server.notify(PeerID, "Goto Failed", "Goto seat command is not enabled for non admins", 6)
	end
end

function CommandEject(FullMessage, PeerID, Admin, Auth, Command, One, Two, Three, Four, Five, Discord)
	if GetSetting("NonAdminEject") == true or GetPerms(PeerID) >= PermMod then
		local OneID=ConvertToPeer(One)
		local Found=false
		for _,X in pairs(g_savedata["Vehicles"]) do
			if X["OwnerID"] == PeerID then
				local PlayersSitting=PlayerSeatedGroupList(tonumber(X["GroupID"]))
				for A,B in pairs(PlayersSitting) do
					if CountItems(B) > 0 then
						for _,C in pairs(B) do
							local PlayerID=C[1]
							if (OneID == nil or OneID == PlayerID) and (PlayerID ~= PeerID) then
								Found=true
								server.notify(PlayerID, "Eject Success", "You have been ejected from vehicle with ID " .. tostring(math.floor(X["GroupID"])), 5)
								server.notify(PeerID, "Eject Success", "Ejected player with ID " .. tostring(math.floor(PlayerID)), 5)
								NoSave["Player"][tonumber(PlayerID)]["Seat"]={VehicleID=-1,GroupID=-1,X=0,Y=0,Z=0}
								if TpList[tostring(GetSetting("EjectTpLocation"))] ~= nil then
									server.setPlayerPos(PlayerID,TpList[tostring(GetSetting("EjectTpLocation"))][2])
								else
									server.setPlayerPos(PlayerID,matrix.translation(x,y,z))
								end
							end
						end
					end
				end
			end
		end

		if Found == false then
			server.notify(PeerID, "Eject Failed", "No players to eject", 6)
		end
	else
		server.notify(PeerID, "Eject Failed", "Eject command is not enabled for non admins", 6)
	end
end

function CommandAuth(FullMessage, PeerID, Admin, Auth, Command, One, Two, Three, Four, Five, Discord)
	if NoSave["Player"][tonumber(PeerID)]["DisableVehicleSpawning"] == true then
		server.notify(PeerID, "Auth Failed", "You cannot be authed as your vehicle spawning is disabled.", 6)
		return
	end
	if string.lower(Command) == "?bob" then
		Announce("[Psst]","Hey! You discovered an easter egg :D",PeerID)
	end
	server.notify(PeerID, "Auth Success", "You have been authed.", 5)
	local PlayerData=GetPlayerData(PeerID)
	if PlayerData["auth"] == false then
		server.addAuth(PeerID)
	end
	UpdatePlayerPermissions(PeerID)
	server.removePopup(PeerID,2)
end

function ReturnAuthCommandPermissions()
	if GetServerConfigData()["AuthOnAcceptPopup"] == true then
		return PermNone
	end
	return -1
end

function CommandListVehicles(FullMessage, PeerID, Admin, Auth, Command, One, Two, Three, Four, Five, Discord)

	local Out={"TypeListVehiclesReturn",0}
	if Discord ~= true then
		Announce("[Server]","Spawned Vehicles:\n",PeerID)
	end
	local VehicleCount=0
	local DetailedView=false
	if One ~= nil then
		if string.lower(One) == "true" then
			DetailedView=true	
		end
	end

	for _,Y in pairs(g_savedata["Vehicles"]) do
		VehicleCount=VehicleCount + 1
		local Name =Y["Name"]--S.getVehicleName(X)
		local OwnerName=FixBlankPlayer(server.getPlayerName(Y["OwnerID"]),Y["OwnerID"])
		local OutItem="Name: " .. Name .. ";:Vehicle ID: " .. tostring(Y["GroupID"]) .. ";:Owner: [" .. OwnerName .. "(" .. GetSteamID(Y["OwnerID"]) .. ")](https://steamcommunity.com/profiles/" .. tostring(GetSteamID(Y["OwnerID"])) .. ")"
		
		if Y["Voxels"] ~= nil then 
			OutItem=OutItem .. ";:Voxels: " .. Y["Voxels"]
			

		else
			OutItem=OutItem .. ";:Voxels: 0"
		end
		table.insert(Out,OutItem)
		if Discord ~= true then
			Announce(" ","Name: " .. Name,PeerID)
			Announce(" ","Vehicle ID: " .. Y["GroupID"],PeerID)
			Announce(" ","Owner Name: " .. OwnerName,PeerID)
			if DetailedView == true then
				if Y["Voxels"] ~= nil then
					Announce(" ","Voxels: " .. Y["Voxels"],PeerID)
				end
			end
			Announce(" "," " ,PeerID)
		end
		
		
		
	end
	if VehicleCount == 0 then
		if Discord ~= true then
			Announce("     ", "No spawned vehicles",PeerID)
		end
		table.insert(Out,"No spawned vehicles")
	end
	if Discord == true then
		Out[2]=VehicleCount
		SendHttp(Out)
	end


end

function CommandVehicleData(FullMessage, PeerID, Admin, Auth, Command, One, Two, Three, Four, Five, Discord)

	--local Out={"TypeVehicleDataReturn",0}
	----if Discord ~= true then
	--	Announce("[Server]","Spawned Vehicles:\n",PeerID)
	--end
	--local VehicleCount=0
	local VehicleData=g_savedata["Vehicles"][tonumber(One)]
	if VehicleData ~= nil then
		
		local Name =VehicleData["Name"]--S.getVehicleName(X)
		local OwnerName=FixBlankPlayer(server.getPlayerName(VehicleData["OwnerID"]),VehicleData["OwnerID"])
		Announce("[Server]","Vehicle Data:",PeerID)
		Announce(" ","Name: " .. Name,PeerID)
		Announce(" ","Vehicle ID: " .. VehicleData["GroupID"],PeerID)
		Announce(" ","Owner Name: " .. OwnerName,PeerID)
		if VehicleData["Voxels"] ~= nil then
			Announce(" ","Voxels: " .. VehicleData["Voxels"],PeerID)
		end
	else
		server.notify(PeerID, "Invalid ID", "Please enter a valid vehicle ID", 6)
	end
	--Announce(" "," " ,PeerID)
	--end
		
		
	--if Discord == true then
	--	Out[2]=VehicleCount
	--	SendHttp(Out)
	--end


end

function CommandTP(FullMessage, PeerID, Admin, Auth, Command, One, Two, Three, Four, Five, Discord)
	if GetSetting("NonAdminTpCommand") == true or GetPerms(PeerID) >= PermMod then
		if One ~= nil and One ~= "" and One ~= " " then
			if TpList[tostring(One)] ~= nil then
				NoSave["Player"][PeerID]["Follow"]={State=false,Followed=-1,Height=100}
				server.setPlayerPos(PeerID,TpList[tostring(One)][2])
				server.notify(PeerID, "Teleport Success", "Teleported to " .. TpList[tostring(One)][1], 5)
			else
				server.notify(PeerID, "Invalid Destination", "There is no teleport point with the ID ".. One, 6)
			end
			return
		end
		Announce("[Server]", "Teleport Locations", PeerID)

		for X=1, CountItems(TpList) do
			if TpList[tostring(X)] ~= nil then
				if TpList[tostring(X)][1] ~= nil then
					Announce("       ", tostring(X) .. " . " .. TpList[tostring(X)][1], PeerID)
				end
			end
		end
	else
		server.notify(PeerID,"Teleport Failed","TP command not enabled for non admins.",6)
	end
end

function SwItemToLocalItem(EquipmentID)
	for X,Y in pairs(GiveItems) do
		if Y[2] == EquipmentID then
			return X
		end
	end
end


function GiveItem(PeerID,EquipmentID,TargetSlot)
	local ItemData=GiveItems[tonumber(EquipmentID)]
	local Slot=1

	local PlayerObjectID=server.getPlayerCharacterID(PeerID)
	if ItemData[4] == 0 then
		if TargetSlot == nil then
			for X = 2,9,1 do 
				local SlotSearch= server.getCharacterItem(PlayerObjectID, X)
				if SlotSearch == 0 then
			
					Slot=X
					break
				end
				if Slot == 1 then
					Slot=2
				end
			end
		else
			Slot=TargetSlot
		end
	elseif ItemData[4] == 2 then
		Slot=10
	end

	local Int=ItemData[3][1]
	local Float=ItemData[3][2]
	server.setCharacterItem(PlayerObjectID, Slot, ItemData[2], false,Int,Float)
end

function CommandTool(FullMessage, PeerID, Admin, Auth, Command, One, Two, Three, Four, Five, Discord)
	if GetSetting("NonAdminToolCommand") == true or GetPerms(PeerID) >= PermMod then

		local OneMessage=GetAfterFirstArg(FullMessage,Command)
		
		local ToolListFormatted={}

		for _,Y in pairs(GiveItems) do
			table.insert(ToolListFormatted,Y[1])
		end

		local AutoComp,AutoCompID=AutoComplete(string.gsub(string.lower(OneMessage)," ","_"),ToolListFormatted)
		if AutoComp ~= nil then
			OneMessage=AutoCompID

		else
			OneMessage=tonumber(OneMessage)
		end

		if tonumber(OneMessage) ~= nil then
			if GiveItems[tonumber(OneMessage)] ~= nil then
				local ServerConfigData=GetServerConfigData()
				for _,Z in pairs(ServerConfigData["BannedItems"]) do
					if GiveItems[tonumber(OneMessage)][2] == Z then
						server.notify(PeerID, "Tool Give Falied", "Item with ID " .. tostring(OneMessage) .. " is banned", 6)
						return
					end
				end
				GiveItem(PeerID,tonumber(OneMessage))
				server.notify(PeerID, "Tool Give Success", "Gave " .. string.gsub(tostring(GiveItems[tonumber(OneMessage)][1]),"_"," ") ..  " #" .. tonumber(OneMessage), 5)
				return
			end
		end
		Announce("[Server]", "Giveable Tools:", PeerID)
		for X,Y in pairs(GiveItems) do
			Announce("       ", tostring(X) .. ". " .. string.gsub(Y[1],"_"," "), PeerID)
		end
		
	else
		server.notify(PeerID, "Tool Give Falied", "Giving items not enabled for non admins", 6)
	end
end

function CommandAnnounce(FullMessage, PeerID, Admin, Auth, Command, One, Two, Three, Four, Five, Discord)
	
	local OneType=string.lower(One)

	if OneType == "notify" or OneType == "notification" then
		Message=GetAfterFirstArg(FullMessage,Command .. " " .. One)
		server.notify(-1, "Announcement", Message, 8)	
		if Discord then
			DiscordNotify(PeerID,"Announce Success","Announcement sent",5)
		end
	elseif OneType == "message" or OneType == "chat" then
		Message=GetAfterFirstArg(FullMessage,Command .. " " .. One)
		Announce("[Announcement]",Message)
		if Discord then
			DiscordNotify(PeerID,"Announce Success","Announcement sent",5)
		end
	else
		DiscordNotify(PeerID,"Announce Failed","Please input a announce type (Chat or Notify)",6)
	end
end

function PvpViewPopup(GroupID,PeerID)
	if NoSave["Player"][PeerID] ~= nil then
		if NoSave["Player"][PeerID]["PvpView"] and g_savedata["Vehicles"][GroupID] ~= nil then
			local MainBodyID=g_savedata["Vehicles"][GroupID]["MainBody"]
			local PlayerPos=server.getPlayerPos(PeerID)
			local VehiclePos=server.getVehiclePos(MainBodyID)
			local Distance=matrix.distance(PlayerPos,VehiclePos)
			server.setPopup(PeerID,GroupID + 6942,"PvpView",true,"Pvp:\n" .. tostring(NoSave["Player"][g_savedata["Vehicles"][GroupID]["OwnerID"]]["Pvp"]),0,4 + math.min(Distance / 20,50),0,2000,MainBodyID)
		else
			server.removePopup(PeerID,GroupID + 6942)
		end
	end
end

function TrackVehiclesPopup(GroupID,PeerID)
	if NoSave["Player"][PeerID] ~= nil then
		if NoSave["Player"][PeerID]["TrackVehicles"]["State"] and g_savedata["Vehicles"][GroupID] ~= nil then
			local OwnerID=g_savedata["Vehicles"][GroupID]["OwnerID"]
			local MainBodyID=g_savedata["Vehicles"][GroupID]["MainBody"]
			local PlayerPos=server.getPlayerPos(PeerID)
			local VehiclePos=server.getVehiclePos(MainBodyID)
			local Distance=matrix.distance(PlayerPos,VehiclePos)
			server.setPopup(PeerID,GroupID + 69420,"TrackVehicles",true,"Owner: " .. FixBlankPlayer(server.getPlayerName(OwnerID),OwnerID) .. "\nID: " .. tostring(math.floor(GroupID)) .. "\nPvp: " .. tostring(NoSave["Player"][OwnerID]["Pvp"]),0,4 + math.min(Distance / 20,50),0,30000,MainBodyID)
		else
			server.removePopup(PeerID,GroupID + 69420)
		end
	end
end

function CommandPvpView(FullMessage, PeerID, Admin, Auth, Command, One, Two, Three, Four, Five, Discord)
	if GetSetting("NonAdminPvpView") or GetPerms(PeerID) >= PermMod then
		if NoSave["Player"][PeerID]["PvpView"] then
			NoSave["Player"][PeerID]["PvpView"]=false

		else
			NoSave["Player"][PeerID]["PvpView"]=true
		end
		for _,X in pairs(g_savedata["Vehicles"]) do
			PvpViewPopup(X["GroupID"],PeerID)
		end
		server.notify(PeerID, "Pvp View State Changed", "Set pvp view state to " .. tostring(NoSave["Player"][PeerID]["PvpView"]), 5)
	else
		server.notify(PeerID, "Pvp View Failed", "Toggling pvp view is not enabled for non admins", 6)	
	end
end

function CommandTrackVehicles(FullMessage, PeerID, Admin, Auth, Command, One, Two, Three, Four, Five, Discord)
	if NoSave["Player"][PeerID]["TrackVehicles"]["State"] then
		NoSave["Player"][PeerID]["TrackVehicles"]={State=false}

	else
		NoSave["Player"][PeerID]["TrackVehicles"]={State=true}
	end
	for _,X in pairs(g_savedata["Vehicles"]) do
		TrackVehiclesPopup(X["GroupID"],PeerID)
	end
	server.notify(PeerID, "Track Vehicles State Changed", "Set track vehicles state to " .. tostring(NoSave["Player"][PeerID]["TrackVehicles"]["State"]), 5)

end

function CommandSettings(FullMessage, PeerID, Admin, Auth, Command, One, Two, Three, Four, Five, Discord)
	if GetPerms(PeerID) >= PermAdmin then
		if One ~= nil then
			local NumberSetting={VehicleLimit="number",EjectTpLocation="number",ItemLimit="number"}
			if g_savedata["Settings"][One] ~= nil then
				if NumberSetting[One] == "number" then
					if OnlyNumbers(Two) == true then
						Two=tonumber(Two)
					else
						server.notify(PeerID,"Invalid Setting Value","Value must be a number",6)
						return
					end
				else
					if Two ~= nil then
						Two=string.lower(Two)
						if Two == "true" then
							Two=true
						elseif Two == "false" then
							Two=false
						else
							server.notify(PeerID,"Invalid Setting Value","Value must be a bool",6)
							return
						end
					else
						server.notify(PeerID,"Invalid Setting Value","Value must be a bool",6)
						return
					end
				end
				
				
				g_savedata["Settings"][One]=Two
				server.notify(PeerID, "Setting Changed", One .. " changed to " .. tostring(g_savedata["Settings"][One]), 5)
				if One == "VehicleTooltips" then
					for _,X in pairs(g_savedata["Vehicles"]) do
						for Y,_ in pairs(g_savedata["Vehicles"]) do
							if g_savedata["Settings"][One] == true then
								SetVehicleToolTip(Y,X["GroupID"],X["OwnerID"])
							else
								server.setVehicleTooltip(tonumber(Y),"")
							end
						end
					end
				elseif One == "AllowPvpPrevent" then
					if Two == true then
						for _,X in pairs(FilteredServerPlayers()) do
							if GetPerms(X.id) < PermMod then
								NoSave["Player"][tonumber(X.id)]["Pvp"]=true
							end
						end
					end
				end
			else
				server.notify(PeerID,"Invalid Setting","There is no setting with ID " .. One,6)
			end
		else
			Announce("[Server]", "Settings (Settings are case sensitive):", PeerID)
			
			for X,Y in pairs(g_savedata["Settings"]) do
				Announce("       ", tostring(X) .. "=" .. tostring(Y), PeerID)
			end
		end
	else
		server.notify(PeerID,"Settings Failed","Settings command not enabled for non admins.",6)
	end
end

function CommandMessage(FullMessage, PeerID, Admin, Auth, Command, One, Two, Three, Four, Five, Discord)
	if GetSetting("NonAdminPrivateMessage") or GetPerms(PeerID) >= PermMod then
		local OneID=ConvertToPeer(One)
		if OneID ~= nil then
			local Message=GetAfterFirstArg(FullMessage,Command .. " " .. One)
			local InitatorName=FixBlankPlayer(server.getPlayerName(PeerID),PeerID)
			local ReciverName=FixBlankPlayer(server.getPlayerName(OneID),OneID)

			NoSave["Player"][PeerID]["LastMessager"]=tonumber(OneID)
			NoSave["Player"][tonumber(OneID)]["LastMessager"]=PeerID
			Announce("You - " .. ReciverName, Message, PeerID)
			Announce(InitatorName .. " - You", Message, tonumber(OneID))
			SendHttp({"TypePrivateMessage",InitatorName,GetSteamID(PeerID),ReciverName,GetSteamID(OneID),Message})
			for _,Y in pairs(FilteredServerPlayers()) do
				if GetPerms(Y.id) >= PermMod then
					if Y.id ~= tonumber(OneID) and Y.id ~= PeerID then
						Announce(InitatorName .. " - " .. ReciverName , Message,Y.id)
					end
				end
			end
			return true
		else
			InvalidPlayerID(PeerID)
		end
	else
		server.notify(PeerID, "Messaging Failed", "Private messaging isn't enabled for non admins", 6)
	end
end

function CommandReply(FullMessage, PeerID, Admin, Auth, Command, One, Two, Three, Four, Five, Discord)
	if GetSetting("NonAdminPrivateMessage") or GetPerms(PeerID) >= PermMod then
		if NoSave["Player"][PeerID]["LastMessager"] ~= -1 then
			OneID=NoSave["Player"][PeerID]["LastMessager"]
			if PlayerOnline(OneID) then
				local Message=GetAfterFirstArg(FullMessage,Command)
				local InitatorName=FixBlankPlayer(server.getPlayerName(PeerID),PeerID)
				local ReciverName=FixBlankPlayer(server.getPlayerName(OneID),OneID)

				NoSave["Player"][PeerID]["LastMessager"]=tonumber(OneID)
				NoSave["Player"][tonumber(OneID)]["LastMessager"]=PeerID
				Announce("You - " .. ReciverName, Message, PeerID)
				Announce(InitatorName .. " - You", Message, tonumber(OneID))
				SendHttp({"TypePrivateMessage",InitatorName,GetSteamID(PeerID),ReciverName,GetSteamID(OneID),Message})
				for _,Y in pairs(FilteredServerPlayers()) do
					if GetPerms(Y.id) >= PermMod then
						if Y.id ~= tonumber(OneID) and Y.id ~= PeerID then
							Announce(InitatorName .. " - " .. ReciverName , Message,Y.id)
						end
					end
				end
				return true
			else
				server.notify(PeerID, "Reply Failed", "No player to reply to", 6)
				NoSave["Player"][PeerID]["LastMessager"]=-1
			end
		else
			server.notify(PeerID, "Reply Failed", "No player to reply to", 6)
		end
	else
		server.notify(PeerID, "Reply Failed", "Private messaging isn't enabled for non admins", 6)
	end
end

function CommandStaffChat(FullMessage, PeerID, Admin, Auth, Command, One, Two, Three, Four, Five, Discord)
	local PlayerName=FixBlankPlayer(server.getPlayerName(PeerID),PeerID)
	local Message=GetAfterFirstArg(FullMessage,Command)
	local PermString=""
	if Discord == true then
		PlayerName="[Discord] " .. Five
		
	else
		SendHttp({"TypeStaffChat",PlayerName,Message})
		if g_savedata["Settings"]["ShowPermissionsInChat"] == true then
			PermString="[" .. ParsePermissions(GetPerms(PeerID),true) .. "] "
		end
	end

	AnnounceAbovePerms("[Staff Chat]",PermString .. PlayerName .. " - " .. Message,PermMod,-1)
end

function VerifyAsSteamID(SteamID)
	if SteamID == nil then
		return false
	end
	if tonumber(SteamID, 10) == nil then
		return false
	end
	local Start,End= string.find(SteamID,"7656")
	if Start ~= 1 then
		return false
	end

	if string.len(SteamID) ~= 17 then
		return false
	end
	return true
end

function CommandFollow(FullMessage, PeerID, Admin, Auth, Command, One, Two, Three, Four, Five, Discord)
	local OneID=ConvertToPeer(One)

	if NoSave["Player"][OneID] ~= nil or One == nil then
		if OneID == nil then
			if NoSave["Player"][PeerID]["Follow"]["State"] == false then
				server.notify(PeerID,"Unfollow Failed","You are not following anyone",6)
				return
			end
			
			server.notify(PeerID,"Unfollow Success","Stopped following player with ID " .. math.floor(NoSave["Player"][PeerID]["Follow"]["Followed"]),5)
			NoSave["Player"][PeerID]["Follow"]={State=false,Followed=-1,Height=100}
		else
			local Height=100
			if Two ~= nil then
				if tonumber(Two) ~= nil then
					Height=tonumber(Two)
				end
			end
			NoSave["Player"][PeerID]["Follow"]={State=true,Followed=OneID,Height=Height}
			server.notify(PeerID,"Follow Success","Following player with ID " .. math.floor(tonumber(OneID))  .. " at height " .. Height,5)
		end
	else
		InvalidPlayerID(PeerID)	
	end

end

function matrix.getMatrixRotation(RoationMatrix) --returns radians for the functions: M.rotation X and Y and Z (credit to woe and quale)
	
    local z = -math.atan(RoationMatrix[5],RoationMatrix[1])
    --rot_M = M.multiply(rot_M, M.rotationY(-z))
    return math.atan(RoationMatrix[7],RoationMatrix[6]), math.atan(RoationMatrix[9],RoationMatrix[11]), z
end


function Flip(VehicleID,PeerID)
	local Playersiting={}
	Playersiting[VehicleID]=GetPlayersInVehicle(VehicleID)
	local VehicleMatrix = server.getVehiclePos(VehicleID)
	local XRot, YRot, ZRot = matrix.getMatrixRotation(VehicleMatrix)

	
	local XPos,YPos,ZPos = matrix.position(VehicleMatrix)

	local NewPos= matrix.multiply(matrix.translation(XPos,YPos + 2,ZPos),matrix.rotationY(YRot))


	table.insert(NoSave["VehicleTPQueue"],{TargetPos=NewPos,Type="Vehicle",ID=VehicleID,SeatedPlayers=Playersiting})
end

function SteamIDToPeerID(SteamID)
	for _,X in pairs(FilteredServerPlayers()) do
		if tostring(X.steam_id) == SteamID then
			return X.id
		end
	end
	return nil
end

function CommandAddToBlackList(FullMessage, PeerID, Admin, Auth, Command, One, Two, Three, Four, Five, Discord)
	local TwoSteamID=ConvertToPeer(Two,NoSave["Player"][PeerID]["BlackListedPlayers"])


	if TwoSteamID ~= nil and Two ~= " " and Two ~= "" then
		local TwoID=SteamIDToPeerID(TwoSteamID)
		if TwoID == nil then
			TwoID=TwoSteamID
		end

		if TwoSteamID == GetSteamID(PeerID) then
			server.notify(PeerID,"Blacklist Add Failed","You cannot add yourself to your blacklist",6)
			return
		end

		for _,X in pairs(NoSave["Player"][PeerID]["BlackListedPlayers"]) do
			if X["SteamID"] == TwoSteamID then
				server.notify(PeerID,"Blacklist Add Failed","Player with ID " .. TwoID .. " is already in your blacklist",6)
				return
			end
		end

		table.insert(NoSave["Player"][PeerID]["BlackListedPlayers"],{SteamID=TwoSteamID,Name=FixBlankPlayer(server.getPlayerName(TwoID),TwoID)})

		server.notify(PeerID,"Blacklist Add Success","Added player with ID " .. TwoID .. " to your blacklist",5)
	else
		InvalidPlayerID(PeerID)
	end
end

function CommandRemoveFromBlackList(FullMessage, PeerID, Admin, Auth, Command, One, Two, Three, Four, Five, Discord)
	local TwoSteamID=ConvertToPeer(Two,NoSave["Player"][PeerID]["BlackListedPlayers"])


	if TwoSteamID ~= nil and Two ~= " " and Two ~= "" then
		local TwoID=SteamIDToPeerID(TwoSteamID)
		if TwoID == nil then
			TwoID=TwoSteamID
		end

		for Y,X in pairs(NoSave["Player"][PeerID]["BlackListedPlayers"]) do
			if X["SteamID"] == TwoSteamID then
				server.notify(PeerID,"Blacklist Remove Success","Removed player with ID " .. TwoID .. " from your blacklist",5)
				NoSave["Player"][PeerID]["BlackListedPlayers"][Y]=nil
				return
			end
		end

		server.notify(PeerID,"Blacklist Remove Failed","Player with ID " .. TwoID .. " is not in your blacklist",6)
	else
		InvalidPlayerID(PeerID)
	end
end

function CommandListBlackList(FullMessage, PeerID, Admin, Auth, Command, One, Two, Three, Four, Five, Discord)
	Announce("[Server]", "Blacklist:", PeerID)
	for _,X in pairs(NoSave["Player"][PeerID]["BlackListedPlayers"]) do
		Announce("        ",tostring(X["Name"]),PeerID)
	end
	if #NoSave["Player"][PeerID]["BlackListedPlayers"] == 0 then
		Announce("        ","You have no one on your blacklist",PeerID)
	end
end

function ListBlackListCommands(PeerID)
	local PermLevel=GetPerms(PeerID)
	Announce("[Server]", "Blacklist Subcommands:", PeerID)
	Announce("        ", "[] means optional.", PeerID)
	Announce("        ", "() means required.", PeerID)

	for X,Y in pairs(BlackListCommands) do
		if PermLevel >= Y[5] then
			Announce("?blacklist ".. Y[2][1] ..  Y[3],Y[4],PeerID)
		end
	end
end
BlackListCommands={
	{CommandAddToBlackList,{"add"}," (Player ID)","Adds a player to your blacklist.",PermNone,false,false,false},
	{CommandRemoveFromBlackList,{"remove"}," (Player ID)","Removes a player from your blacklist",PermNone,false,false,false},
	{CommandListBlackList,{"list"},"","Lists out all the players you have blacklisted.",PermNone,false,false,false}
}
function CommandBlacklist(FullMessage, PeerID, Admin, Auth, Command, One, Two, Three, Four, Five, Discord)
	if One == nil then
		One=""
	end
	local CommandParsed=GetCommand(string.lower(One),PeerID,BlackListCommands,"")
	if CommandParsed[1] ~= nil then
		CommandParsed[1](FullMessage, PeerID, Admin, Auth, Command, One, Two, Three, Four, Five,Discord)
		return
	end
	ListBlackListCommands(PeerID)
	DiscordNotify(PeerID, "Unknown Subcommand", "No blacklist subcommand found", 6,Discord)
end


function CommandFreeze(FullMessage, PeerID, Admin, Auth, Command, One, Two, Three, Four, Five, Discord)
	local PlayerName=FixBlankPlayer(server.getPlayerName(PeerID),PeerID)
	local OneID=ConvertToPeer(One)
	if PlayerOnline(OneID) then
		if NoSave["Player"][tonumber(OneID)]["Freeze"]["State"] == false then
			local Pos = server.getPlayerPos(tonumber(OneID))
			NoSave["Player"][tonumber(OneID)]["Freeze"]={State=true,Pos=Pos}
			server.notify(PeerID,"Freeze Success","Froze player with ID " .. OneID,5)
			server.notify(tonumber(OneID),"Freeze Success","You were frozen by " .. PlayerName,5)
		else
				
			NoSave["Player"][tonumber(OneID)]["Freeze"]["State"]=false
			server.notify(PeerID,"Unfreeze Success","Unfroze player with ID " .. OneID,5)
			server.notify(tonumber(OneID),"Unfreeze Success","You were unfrozen by " .. PlayerName,5)
		end
	else 
		InvalidPlayerID(PeerID)	
	end	
end

function CommandClearInventory(FullMessage, PeerID, Admin, Auth, Command, One, Two, Three, Four, Five, Discord)
	if GetSetting("NonAdminClearSelfInv") == true or GetPerms(PeerID) < PermMod then
		local PlayerName=FixBlankPlayer(server.getPlayerName(PeerID),PeerID)
		local OneID=ConvertToPeer(One)
		if One == nil then
			OneID=PeerID
		end
		if GetPerms(PeerID) < PermMod then
			OneID=PeerID
		end
		if PlayerOnline(OneID) then
			local PlayerObjectID=server.getPlayerCharacterID(OneID)
			for T=1, 10 do
				server.setCharacterItem(PlayerObjectID,T,0,false,0,0)
			end
			if OneID ~= PeerID then
				server.notify(tonumber(OneID),"Clear Inventory Success","Your inventory was cleared by " .. PlayerName,5)
			end
			server.notify(tonumber(PeerID),"Clear Inventory Success","Cleared inventory of player with ID " .. OneID,5)
		else 
			InvalidPlayerID(PeerID)	
		end	
	else
		server.notify(PeerID, "Clear Inventory Failed", "Clearing your inventory isn't enabled for non admins", 6)
	end
end

function CommandToggleInv(FullMessage, PeerID, Admin, Auth, Command, One, Two, Three, Four, Five, Discord)
	local PlayerName=FixBlankPlayer(server.getPlayerName(PeerID),PeerID)
	local OneID=ConvertToPeer(One)
	if PlayerOnline(OneID) then
		if NoSave["Player"][tonumber(OneID)]["DisableInv"] == false then
			NoSave["Player"][tonumber(OneID)]["DisableInv"]=true
			server.notify(PeerID,"Toggle Inv Success","Disabled inventory for player with ID " .. OneID,5)
			server.notify(tonumber(OneID),"Toggle Inv Success","Your inventory was disabled by " .. PlayerName,5)
		else
				
			NoSave["Player"][tonumber(OneID)]["DisableInv"]=false
			server.notify(PeerID,"Toggle Inv Success","Enabled inventory for player with ID " .. OneID,5)
			server.notify(tonumber(OneID),"Toggle Inv Success","Your inventory was enabled by " .. PlayerName,5)
		end
	else 
		InvalidPlayerID(PeerID)	
	end	
end

function CommandToggleSpawn(FullMessage, PeerID, Admin, Auth, Command, One, Two, Three, Four, Five, Discord)
	local PlayerName=FixBlankPlayer(server.getPlayerName(PeerID),PeerID)
	local OneID=ConvertToPeer(One)
	if PlayerOnline(OneID) then
		if NoSave["Player"][tonumber(OneID)]["DisableVehicleSpawning"] == false then
			NoSave["Player"][tonumber(OneID)]["DisableVehicleSpawning"]=true
			server.notify(PeerID,"Toggle Spawning Success","Disabled vehicle spawning for player with ID " .. OneID,5)
			server.notify(tonumber(OneID),"Toggle Spawning Success","Your vehicle spawning was disabled by " .. PlayerName,5)
			server.removeAuth(tonumber(OneID))
			for Y,X in pairs(g_savedata["Vehicles"]) do
				if X["OwnerID"] == OneID then
					server.despawnVehicleGroup(X["GroupID"],true)
				end
			end
		else
				
			NoSave["Player"][tonumber(OneID)]["DisableVehicleSpawning"]=false
			server.notify(PeerID,"Toggle Spawning Success","Enabled vehicle spawning for player with ID " .. OneID,5)
			server.notify(tonumber(OneID),"Toggle Spawning Success","Your vehicle spawning was enabled by " .. PlayerName,5)
			server.addAuth(tonumber(OneID))
		end
		UpdatePlayerPermissions(PeerID)
	else 
		InvalidPlayerID(PeerID)	
	end	
end

function CommandFlip(FullMessage, PeerID, Admin, Auth, Command, One, Two, Three, Four, Five, Discord)
	if GetSetting("NonAdminFlip")  or GetPerms(PeerID) >= PermMod then
		if g_savedata["Vehicles"][tonumber(One)] ~= nil or One == nil then
			if One ~= nil then

				
				if g_savedata["Vehicles"][tonumber(One)]["OwnerID"] == PeerID or GetPerms(PeerID) >= PermMod then
					local Playersiting=PlayerSeatedGroupList(tonumber(One))
					for X,_ in pairs(g_savedata["Vehicles"][tonumber(One)]["Parts"]) do
					
						Flip(X,PeerID)
						--server.resetVehicleState(tonumber(A))
					end
					server.notify(PeerID, "Flip Success", "Flipped vehicle with ID  " .. tonumber(One), 5)
				else
					server.notify(PeerID, "Invalid ID", "Non admins can only flip vehicles that they spawned", 6)
				end
			else
				local FlipedOne=false
				for X,Y in pairs(g_savedata["Vehicles"]) do
					if Y["OwnerID"] == PeerID then
						FlipedOne=true
						local Playersiting=PlayerSeatedGroupList(tonumber(X))
						for A,_ in pairs(g_savedata["Vehicles"][tonumber(X)]["Parts"]) do
							Flip(A,PeerID)
							--server.resetVehicleState(tonumber(A))
							
						end
						server.notify(PeerID, "Flip Success", "Flipped vehicle with ID  " .. tonumber(X), 5)
					end
				end
				if not FlipedOne then
					server.notify(PeerID, "Flip Failed", "You have no spawned vehicles", 6)
				end
			end

		else
			server.notify(PeerID, "Invalid ID", "Please enter a valid vehicle ID", 6)
		end
	else
		server.notify(PeerID, "Flip Failed", "Flip command not enabled for non admins", 6)
	end
end


function LastSeen(SteamID)
	local TimeDifference=g_savedata["Seconds"] - g_savedata["PlayerData"][SteamID]["LastJoin"]
	if math.abs(TimeDifference) < 3 then
		return 0
	end
	if g_savedata["PlayerData"][SteamID]["LastJoin"] == 0 then
		TimeDifference=-1
	end
	return TimeDifference
end



function CommandHistory(FullMessage, PeerID, Admin, Auth, Command, One, Two, Three, Four, Five, Discord)
	local OneID=ConvertToPeer(One)
	local OneSteamID=""
	if OneID == nil then
		if VerifyAsSteamID(One) then
			OneSteamID=One
		end
	else
		OneSteamID=GetSteamID(OneID)
	end

	local OneName=FixBlankPlayer(server.getPlayerName(OneID),OneID)
	if OneID == nil then
		
		OneName=tostring(OneSteamID)
	end

	if OneSteamID ~= "" and One ~= " " and One ~= "" then
		
		
		ValidatePlayerSaveData(OneSteamID,"")
		if g_savedata["PlayerData"][OneSteamID]["Name"] ~= nil and g_savedata["PlayerData"][OneSteamID]["Name"] ~= "" then
			OneName=g_savedata["PlayerData"][OneSteamID]["Name"]
		end
		local LastSeenReturn=LastSeen(OneSteamID)
		local LastSeenString="Never Joined"
		if LastSeenReturn ~= -1 then
			local LastSeenFormatted=FormatTime(math.floor(LastSeenReturn))
			LastSeenString=tostring(LastSeenFormatted[5]) .. "y," .. tostring(LastSeenFormatted[4]) .. "d," .. tostring(LastSeenFormatted[3]) .. "h," .. tostring(LastSeenFormatted[2] + (math.floor(LastSeenFormatted[1] / 6) / 10)) .. "m"
		end
		local Playtime=FormatTime(math.floor(g_savedata["PlayerData"][OneSteamID]["Playtime"]))
		local PlaytimeString=tostring(Playtime[4] * 24 + Playtime[3]) .. "h," .. tostring(Playtime[2]) .. "m," .. tostring(Playtime[1]) .. "s"

		local BanData=g_savedata["PlayerData"][OneSteamID]["Banned"]
		local BanStatus=CheckBannedStatus(OneSteamID)
		local History={"TypeHistoryReturn",OneName,OneSteamID,g_savedata["PlayerData"][OneSteamID]["WarnCount"],g_savedata["PlayerData"][OneSteamID]["KickCount"],g_savedata["PlayerData"][OneSteamID]["JoinCount"],g_savedata["PlayerData"][OneSteamID]["VehicleCount"],g_savedata["PlayerData"][OneSteamID]["DeathCount"],tostring(PlaytimeString),LastSeenString,tostring(BanData["State"])}

		
		
		if Discord ~= true then
			Announce("[Server]", "History For Player " .. OneName .. ":" , PeerID)
			Announce("Total Warns", math.floor(g_savedata["PlayerData"][OneSteamID]["WarnCount"]),PeerID)
			Announce("Total Kicks", math.floor(g_savedata["PlayerData"][OneSteamID]["KickCount"]),PeerID)
			Announce("Total Joins", math.floor(g_savedata["PlayerData"][OneSteamID]["JoinCount"]),PeerID)
			Announce("Total Vehicles Spawned", math.floor(g_savedata["PlayerData"][OneSteamID]["VehicleCount"]),PeerID)
			Announce("Total Deaths", math.floor(g_savedata["PlayerData"][OneSteamID]["DeathCount"]),PeerID)
			Announce("Playtime", PlaytimeString,PeerID)
			Announce("Last Seen", LastSeenString,PeerID)
			Announce("Active Ban", tostring(BanData["State"]),PeerID)
		end


		if BanData["State"] == true then
			local BanTime=BanTimeStampFormatter(BanData["BanTime"])
			local BanTimeRemaining=BanTimeStampFormatter(BanStatus)
			table.insert(History,BanTime)
			table.insert(History,BanTimeRemaining)
			if Discord ~= true then
				Announce("  Time",BanTime,PeerID)
				Announce("  Remaining Time", BanTimeRemaining,PeerID)
			end
		else
			table.insert(History,"")
			table.insert(History,"")
		end

		if Discord ~= true then
			Announce("   ", " ", PeerID)
			Announce("   ", "History (Latest First):", PeerID)
		end
		if #g_savedata["PlayerData"][OneSteamID]["History"] > 0 then
			for X,Y in pairs(g_savedata["PlayerData"][OneSteamID]["History"]) do
				if Y["StaffMember"] == nil then
					g_savedata["PlayerData"][OneSteamID]["History"][X]["StaffMember"]="No Staff Found"
				end

				local ChatTitle,ChatMessage="", ""
				if Y["Time"] == nil then
					g_savedata["PlayerData"][OneSteamID]["History"][X]["Time"]=g_savedata["Seconds"]
				end
				
				if Y["Type"] == "Warn" then
					if Y["Warns"] == nil then
						g_savedata["PlayerData"][OneSteamID]["History"][X]["Warns"]=1
					end
					ChatTitle="Warn"
					ChatMessage="Warns: " .. math.floor(Y["Warns"]) .. ' Reason: "' .. Y["Reason"] .. '" Staff: ' .. Y["StaffMember"] .. " Timestamp: " .. BanTimeStampFormatter(g_savedata["Seconds"] - Y["Time"]) .. " ago"
				elseif Y["Type"] == "Clear" then
					ChatTitle="Warns Cleared"
					ChatMessage='Reason: "' .. Y["Reason"] .. '" Staff: ' .. Y["StaffMember"] .. " Timestamp: " .. BanTimeStampFormatter(g_savedata["Seconds"] - Y["Time"]) .. " ago"
				elseif Y["Type"] == "Kicked" then
					ChatTitle="Kicked"
					ChatMessage= "Warns: " ..math.floor(Y["Warns"]) .. ' Reason: "' .. Y["Reason"] .. '" Staff: ' .. Y["StaffMember"] .. " Timestamp: " .. BanTimeStampFormatter(g_savedata["Seconds"] - Y["Time"]) .. " ago"
					
				elseif Y["Type"] == "Tempban" then
					ChatTitle="Tempban"
					ChatMessage= "Time: " .. BanTimeStampFormatter(Y["BanTime"]) .. ' Reason: "' .. Y["Reason"] .. '" Staff: ' .. Y["StaffMember"] .. " Timestamp: " .. BanTimeStampFormatter(g_savedata["Seconds"] - Y["Time"]) .. " ago"
				elseif Y["Type"] == "Unban" then
					ChatTitle="Unban"
					ChatMessage='Reason: "' .. Y["Reason"] .. '" Staff: ' .. Y["StaffMember"] .. " Timestamp: " .. BanTimeStampFormatter(g_savedata["Seconds"] - Y["Time"]) .. " ago"
				elseif Y["Type"] == "Note" then
					ChatTitle="Note"
					ChatMessage="Staff: " .. Y["StaffMember"] .. ' Text: "' .. Y["Note"] .. '"'
				end

				if ChatTitle ~= "" then
					if Discord ~= true then
						Announce(ChatTitle,ChatMessage,PeerID)
					else
						table.insert(History,ChatTitle .. " - " .. ChatMessage)
					end
				end
			end

		else
			if Discord ~= true then
				Announce("", "No Player History", PeerID)
			else
				table.insert(History,"  - No Player History")
			end
		end
		if Discord == true then
			SendHttp(History)
		end
	else
		DiscordNotify(PeerID, "Invalid ID", "Please enter a valid player ID / Name / SteamID", 6,Discord)
	end



	--[[

	One=IDNames(One)
	if One == nil then
		InvalidPlayerID(ID,SteamID(ID) == "0")
		return
	end
	local OneName="ERROR"
	local SteamIDOne=0
	CheckWarnExists(One)
	if PlayerOnline(One) then
		SteamIDOne=SteamID(tonumber(One))
		OneName = PNameT(tonumber(One))
		
	else
		SteamIDOne=TSr(One)
		OneName=g_savedata["Warns"][SteamIDOne]["Name"]
	end
	if g_savedata["Warns"][SteamIDOne] == nil then
		SpecialNotify(ID, "No History", "No history for player with SteamID " .. SteamIDOne, 6)
		return
	end
	if #g_savedata["Warns"][SteamIDOne]["List"] > -1 then
		EvalBan(SteamIDOne)
		local PlayTime=GetPlaytime(SteamIDOne)
		if SteamID(ID) ~= "0" then
			Announce("[Server]", "History For Player " .. OneName .. ":" , ID)
			Announce("Total Warns", MA.floor(g_savedata["Warns"][SteamIDOne]["TotalWarns"]),ID)
			Announce("Total Kicks", MA.floor(g_savedata["Warns"][SteamIDOne]["TotalKicks"]),ID)
			Announce("Total Joins", MA.floor(g_savedata["Warns"][SteamIDOne]["Joins"]),ID)
			Announce("Total Vehicles Spawned", MA.floor(g_savedata["Warns"][SteamIDOne]["VehiclesSpawned"]),ID)
			Announce("Total Deaths", MA.floor(g_savedata["Warns"][SteamIDOne]["Deaths"]),ID)
			Announce("Playtime", PlayTime,ID)
			if g_savedata["Warns"][SteamIDOne] ~= nil then
				if g_savedata["Warns"][tostring(SteamIDOne)]["LastSeen"] ~= nil then
					TimeLeft=TimeFormater((g_savedata["SecCount"]  / 60 - g_savedata["Warns"][tostring(SteamIDOne)]["LastSeen"] / 60))
					Announce("Last Seen",tostring(TimeLeft[1] * 52 + TimeLeft[2] * 4 + TimeLeft[3]) .. " weeks " .. tostring(TimeLeft[4]) .. " days " .. tostring(TimeLeft[5]) .. " hours " .. tostring(math.floor(TimeLeft[6])) .. " minutes ago",ID)
				end
			end
			
			YBan=g_savedata["Warns"][SteamIDOne]["Baned"]
			Announce("Active Ban", tostring(YBan["Active"]),ID)
			if YBan["Active"] then
				Time=MA.floor(((YBan["Time"] / 60) - ((g_savedata["SecCount"] / 60) - (YBan["StartTime"] / 60))) * 10) / 10
				Announce("  Time (Mins)",YBan["Time"] / 60,ID)
				Announce("  Remaining Time (Mins)", Time,ID)
			end
				--Announce("Type", "Warns : Reason", ID)
			if #g_savedata["Warns"][SteamIDOne]["List"] > 0 then
				for X,Y in pairs(g_savedata["Warns"][SteamIDOne]["List"]) do
					if Y["Staff"] == nil then
						g_savedata["Warns"][SteamIDOne]["List"][X]["Staff"]="No Staff Found"
					end
					if Y["Type"] == "Warn" then
						Announce("Warned", "Warns: " .. MA.floor(Y["Warns"]) .. ' Reason: "' .. Y["Reason"] .. '" Staff: ' .. Y["Staff"], ID)
					elseif Y["Type"] == "Clear" then
						Announce("Warns Cleared",'Reason: "' .. Y["Reason"] .. '" Staff: ' .. Y["Staff"], ID)
					elseif Y["Type"] == "Kicked" then
						Announce("Kicked",  "Warns: " ..MA.floor(Y["Warns"]) .. ' Reason: "' .. Y["Reason"] .. '" Staff: ' .. Y["Staff"], ID)
						
					elseif Y["Type"] == "TempBan" then
						Announce("Tempban",  "Time: " .. Y["Time"] .. ' Reason: "' .. Y["Reason"] .. '" Staff: ' .. Y["Staff"] , ID)
					elseif Y["Type"] == "Unban" then
						Announce("Unban",  'Reason: "' .. Y["Reason"] .. '" Staff: ' .. Y["Staff"] , ID)
					elseif Y["Type"] == "Note" then
						Announce("Note",   "Staff: " .. Y["Staff"] .. ' Text: "' .. Y["Note"] .. '"', ID)
					end
						
				end
			else
				Announce("", "No Player History", ID)
			end
		else
			Out=FormatDataForHTTP(SteamIDOne,OneName,"TypeHistoryReturn")
			SendHttp(Out)
		end
	else
			
		SpecialNotify(ID, "No History", "No history for player with ID " .. One, 6)
	end	
	]]--
end

function BanTimeStampFormatter(BanTime)
	local BanTimeList=FormatTime(BanTime)
	return tostring(BanTimeList[5]) .. "y," .. tostring(BanTimeList[4]) .. "d," .. tostring(BanTimeList[3]) .. "h," .. tostring(BanTimeList[2] + (math.floor(BanTimeList[1] / 6) / 10)) .. "m"
end

function ConverTimeStampToSeconds(String)
	local EndUnit=string.lower(String:sub(-1))
	local Time=String:sub(1,-2)
	if Time == "" or Time == nil or tonumber(Time) == nil or EndUnit == "" or EndUnit == nil then
		return nil
	end
	local Units={s=1,m=60,h=3600,d=86400,w=604800,y=31536000}
	
	for X,Y in pairs(Units) do
		if X == EndUnit then
			return tonumber(Time) * Y
		end
	end
	return nil
end

function CommandInfiniteItems(FullMessage, PeerID, Admin, Auth, Command, One, Two, Three, Four, Five, Discord)
	if GetSetting("NonAdminInfItems") or  GetPerms(PeerID) >= PermMod then
		local PlayerObjectID = server.getPlayerCharacterID(PeerID)
		if One == nil then
			
			for X=1,9 do
				ItemID= server.getCharacterItem(PlayerObjectID, X)
				if ItemID ~= 28 then
					server.setCharacterItem(PlayerObjectID, X,ItemID, false, 696969,696969)
				end
			end
			server.notify(PeerID, "Infinite Items Success", "All items in all slots have been given 696969 ammo/uses/battery",5)
		else
			if tonumber(One) ~= nil then
				if tonumber(One) > 0 and tonumber(One) < 11 then
					local ItemID= server.getCharacterItem(PlayerObjectID, tonumber(One))
					if ItemID ~= 0 then
						if ItemID ~= 28 then
							server.setCharacterItem(PlayerObjectID, tonumber(One),ItemID, false, 696969,696969)
						end
						server.notify(PeerID, "Infinite Items Success", "Gave item in slot " .. tostring(One) ..", 696969 ammo/uses/battery",5)
					else
						server.notify(PeerID, "Infinite Items Failed", "There is no item in slot " .. tostring(One),6)
					end
					return
				end
			end
			server.notify(PeerID, "Infinite Items Failed", "Please enter a valid slot 1-10",6)
			
		end
	else
		server.notify(PeerID, "Infinite Items Failed", "Infinite items is not enabled for non admins", 6)	
	end
end

function Charge(GroupID,PeerID)

	if g_savedata["Vehicles"][tonumber(GroupID)] ~= nil then

		for X,_ in pairs(g_savedata["Vehicles"][tonumber(GroupID)]["Parts"]) do
			PartData = server.getVehicleComponents(tonumber(X))
			--Announce("SDF", TSr(Found))
			if PartData ~= nil then
				if PartData["components"]  ~= nil then
					if PartData["components"]["batteries"] ~= nil then
						for _,Y in pairs(PartData["components"]["batteries"]) do
							server.setVehicleBattery(X, Y["pos"]["x"], Y["pos"]["y"], Y["pos"]["z"], 1)
							--S.setVehicleBattery(VehicleID, Y["pos"]["x"] - 1, Y["pos"]["y"] - 1, Y["pos"]["z"] - 1, 1)
						end
						
					end

				end

			end
		end
	end
end


function Fill(GroupID,PeerID)

	--Announce("SDF", "1")
	if g_savedata["Vehicles"][tonumber(GroupID)] ~= nil then

		for X,_ in pairs(g_savedata["Vehicles"][tonumber(GroupID)]["Parts"]) do
			PartData = server.getVehicleComponents(tonumber(X))
			if PartData ~= nil then
				if PartData["components"]  ~= nil then
					if PartData["components"]["tanks"]  ~= nil then
						for _,Y in pairs(PartData["components"]["tanks"]) do
							server.setVehicleTank(X, Y["pos"]["x"], Y["pos"]["y"], Y["pos"]["z"], Y["capacity"], Y["fluid_type"])
						end 
					end

				end

			end
		end
	end

end


function CommandCharge(FullMessage, PeerID, Admin, Auth, Command, One, Two, Three, Four, Five, Discord)
	if GetSetting("NonAdminCharge")  or GetPerms(PeerID) >= PermMod then
		if One ~= nil then
			if g_savedata["Vehicles"][tonumber(One)] == nil then
				server.notify(PeerID, "Invalid ID", "Please enter a valid vehicle ID", 6)
				return
			elseif g_savedata["Vehicles"][tonumber(One)]["OwnerID"] ~= PeerID and GetPerms(PeerID) < PermMod then
				server.notify(PeerID, "Invalid ID", "Only admins can charge vehicles that they don't own", 6)
				return
			end
			Charge(tonumber(One),PeerID)
			server.notify(PeerID, "PeerID Success", "Charged all batteries in vehicle with ID " .. tonumber(One), 5)
		else
			for _,Y in pairs(g_savedata["Vehicles"]) do
				if Y["OwnerID"] == PeerID then
					Charge(Y["GroupID"],PeerID)
				end
			end
			server.notify(PeerID, "Charge Success", "Charged all of your spawned vehicle's batteries", 5)
		end
	else
		server.notify(PeerID, "Charge Failed", "Charge batterys command not enabled for non admins", 6)
	end
end

function CommandFill(FullMessage, PeerID, Admin, Auth, Command, One, Two, Three, Four, Five, Discord)
	if GetSetting("NonAdminFill") or GetPerms(PeerID) >= PermMod then
		if One ~= nil then
			if g_savedata["Vehicles"][tonumber(One)] == nil then
				server.notify(PeerID, "Invalid ID", "Please enter a valid vehicle ID", 6)
				return
			elseif g_savedata["Vehicles"][tonumber(One)]["OwnerID"] ~= PeerID and GetPerms(PeerID) < PermMod then
				server.notify(PeerID, "Invalid ID", "Only admins can fill the tanks of vehicles that they don't own", 6)
				return
			end
			Fill(tonumber(One),PeerID)
			server.notify(PeerID, "Fill Success", "Filled all tanks in vehicle with ID " .. tonumber(One), 5)
		else
			for _,Y in pairs(g_savedata["Vehicles"]) do
				if Y["OwnerID"] == PeerID then
					
					Fill(Y["GroupID"],PeerID)
				end
			end
			server.notify(PeerID, "Fill Success", "Filled all of your spawned vehicle's tanks", 5)
		end
	else
		server.notify(PeerID, "Fill Failed", "Fill tanks command not enabled for non admins", 6)
	end	
end

function CommandDiscordLink(FullMessage, PeerID, Admin, Auth, Command, One, Two, Three, Four, Five, Discord)
	local ServerConfigData=GetServerConfigData()
	if ServerConfigData["DiscordLink"] ~= nil and ServerConfigData["DiscordLink"] ~= "" then
		Announce("[Server]", "The link for the discord server is " .. ServerConfigData["DiscordLink"], PeerID)
		server.notify(PeerID, "Discord Success", "The discord link has been sent in chat", 5)
	else
		server.notify(PeerID, "Discord Failed", "This server does not have an assocated discord server", 6)
	end	
end

function CommandHeal(FullMessage, PeerID, Admin, Auth, Command, One, Two, Three, Four, Five, Discord)
	if GetSetting("NonAdminHeal") or GetPerms(PeerID) >= PermMod then
		local OneID=ConvertToPeer(One)
		if not (GetSetting("NonAdminHealOther") or GetPerms(PeerID) >= PermMod) or (One == nil or One == "") then
			OneID=PeerID
		end
		if NoSave["Player"][OneID] ~= nil then
			
			local OneObjectID= server.getPlayerCharacterID(tonumber(OneID))
			server.setCharacterData(OneObjectID, 100, false, false)
			server.notify(PeerID, "Heal Success", "Player with ID " .. OneID .. " has been healed", 5)
		else
			InvalidPlayerID(PeerID)
		end
	else
		server.notify(PeerID, "Heal Failed", "Healing command is not enabled for non admins", 6)
	end	
end

function CommandKill(FullMessage, PeerID, Admin, Auth, Command, One, Two, Three, Four, Five, Discord)

	if GetSetting("EnableSelfKill")  or GetPerms(PeerID) >= PermMod then
		local OneID=PeerID
		if GetPerms(PeerID) >= PermMod and One ~= nil then
			OneID=ConvertToPeer(One)
		end
		if NoSave["Player"][OneID] ~= nil then
			if NoSave["Player"][OneID]["Pvp"] == false and tonumber(PeerID) == tonumber(OneID) then
				NoSave["Player"][OneID]["Pvp"] = true	
				NoSave["Player"][OneID]["PvpOffOnRespawn"]=true
			end
			if  NoSave["Player"][OneID]["Pvp"] == true then
				local OneObjectID = server.getPlayerCharacterID(OneID)
				server.killCharacter(OneObjectID)
				server.notify(PeerID, "Kill Success", "Killed player with ID  " .. OneID, 5)
			else
				server.notify(PeerID,"Kill Failed","Cannot kill a player with pvp off",6)	
			end
		else
			InvalidPlayerID(PeerID)
		end
	else
		server.notify(PeerID, "Kill Failed", "Kill Command not enabled for non admins", 6)
	end	
end

function CommandListStaff(FullMessage, PeerID, Admin, Auth, Command, One, Two, Three, Four, Five, Discord)
	if GetSetting("NonAdminViewStaff") or GetPerms(PeerID) >= PermMod or Discord == true then
		if Discord ~= true then
			Announce("[Server]", "Online Staff:",PeerID)
		end
		local AnyStaffFound=false
		local Out={"TypeListStaff"}
		for _,X in pairs(FilteredServerPlayers()) do
			local PlayerPerm=GetPerms(X.id)
			if PlayerPerm >= PermMod then
				local PermString=ParsePermissions(PlayerPerm)
				AnyStaffFound=true
				if Discord ~= true then
					Announce("     ", X["name"] .. " - " .. PermString ,PeerID)
				else
					table.insert(Out, X["name"] .. " - " .. PermString )
				end
			end
		end
		if not AnyStaffFound then
			if Discord ~= true then
				Announce("     ", "No staff online",PeerID)
			else
				table.insert(Out, "No staff online")
			end
		end
		if Discord == true then
			SendHttp(Out)
		end
	else
		DiscordNotify(PeerID, "List Staff Failed", "Listing staff members is not enabled for non admins", 6)
	end
end


function CommandRepair(FullMessage, PeerID, Admin, Auth, Command, One, Two, Three, Four, Five, Discord)
	if GetSetting("NonAdminRepair")  or GetPerms(PeerID) >= PermMod then
		if g_savedata["Vehicles"][tonumber(One)] ~= nil or One == nil then
			if One ~= nil then

				
				if g_savedata["Vehicles"][tonumber(One)]["OwnerID"] == PeerID or GetPerms(PeerID) >= PermMod then
					local Playersiting=PlayerSeatedGroupList(tonumber(One))
					for X,_ in pairs(g_savedata["Vehicles"][tonumber(One)]["Parts"]) do
					
						local VehiclePos=server.getVehiclePos(tonumber(X))
						server.resetVehicleState(tonumber(X))
						local TargetPos=matrix.multiply(VehiclePos,matrix.translation(0,1 ,0))
						table.insert(NoSave["VehicleTPQueue"],{TargetPos=TargetPos,Type="Vehicle",ID=tonumber(X),SeatedPlayers={}})
						
					end
					ReseatPlayers(Playersiting)
					server.notify(PeerID, "Repair Success", "Repaired vehicle with ID  " .. tonumber(One), 5)
				else
					server.notify(PeerID, "Invalid ID", "Non admins can only repair vehicles that they spawned", 6)
				end
			else
				local RepairedOne=false
				for X,Y in pairs(g_savedata["Vehicles"]) do
					if Y["OwnerID"] == PeerID then
						RepairedOne=true
						local Playersiting=PlayerSeatedGroupList(tonumber(X))
						for A,_ in pairs(g_savedata["Vehicles"][tonumber(X)]["Parts"]) do
							local VehiclePos=server.getVehiclePos(tonumber(A))
							server.resetVehicleState(tonumber(A))
							local TargetPos=matrix.multiply(VehiclePos,matrix.translation(0,1 ,0))
							table.insert(NoSave["VehicleTPQueue"],{TargetPos=TargetPos,Type="Vehicle",ID=tonumber(A),SeatedPlayers={}})
							
						end
						ReseatPlayers(Playersiting)
						server.notify(PeerID, "Repair Success", "Repaired vehicle with ID  " .. tonumber(X), 5)
					end
				end
				if not RepairedOne then
					server.notify(PeerID, "Repair Failed", "You have no spawned vehicles", 6)
				end
			end

		else
			server.notify(PeerID, "Invalid ID", "Please enter a valid vehicle ID", 6)
		end
	else
		server.notify(PeerID, "Repair Failed", "Repair command not enabled for non admins", 6)
	end
end

function CommandStats(FullMessage, PeerID, Admin, Auth, Command, One, Two, Three, Four, Five, Discord)
	local TotalUniquePlayers=CountItems(g_savedata["PlayerData"])
	local TotalJoins=0
	local TotalWarns=0
	local TotalBans=0
	local TotalVehicles=0
	local TotalDeaths=0
	local TotalPlayerTime=0
	for _,X in pairs(g_savedata["PlayerData"]) do
		TotalJoins=math.floor(TotalJoins + X["JoinCount"])
		TotalWarns=math.floor(TotalWarns + X["WarnCount"])
		TotalVehicles=math.floor(TotalVehicles + X["VehicleCount"])
		TotalDeaths=math.floor(TotalDeaths + X["DeathCount"])
		TotalPlayerTime=math.floor(TotalPlayerTime + X["Playtime"])
		if X["Banned"] ~= nil then
			if X["Banned"]["State"] == true then
				TotalBans=math.floor(TotalBans + 1)
			end
		end

		

		

	end
	local TotalPlayTimeString=BanTimeStampFormatter(TotalPlayerTime)
	local TotalUptimeString=BanTimeStampFormatter(g_savedata["Seconds"])
	if Discord == true then
		Output={"TypeStatsReturn",TotalJoins,TotalUniquePlayers,TotalWarns,TotalBans,TotalDeaths,TotalPlayTimeString,TotalUptimeString}
		SendHttp(Output)
	else
		Announce("[Server]","Server Stats:",PeerID)
		Announce("","Total Joins: " .. TotalJoins,PeerID)
		Announce("","Total Unique Joins: " .. TotalUniquePlayers,PeerID)
		Announce("","Total Warns: " .. TotalWarns,PeerID)
		Announce("","Total Bans: " .. TotalBans,PeerID)
		Announce("","Total Deaths: " .. TotalDeaths,PeerID)
		Announce("","Total Playtime: " .. TotalPlayTimeString,PeerID)
		Announce("","Total Uptime: " .. TotalUptimeString,PeerID)
	end
	

end

function CommandHelp(FullMessage, PeerID, Admin, Auth, Command, One, Two, Three, Four, Five, Discord)
	local PermLevel=GetPerms(PeerID)
	Announce("[Server]", "Commands:", PeerID)
	Announce("        ", "Script created by Fireblade2534", PeerID)
	Announce("        ", "[] means optional.", PeerID)
	Announce("        ", "() means required.", PeerID)
	Announce("        ", "", PeerID)	

	for X,Y in pairs(CommandDirectory) do
		if PermLevel >= Y[5] and Y[5] >= 0 then
			Announce("?" .. Y[2][1] .. " "..  Y[3],Y[4],PeerID)
		end
	end
end


CommandDirectory={
	{CommandHelp,{"help","h","commands","halp"},"","Shows command help.",PermNone,false,true,false},
	{CommandClearVehicle,{"clear","c","despawn","remove","clean","d"},"[Vehicle ID]","With a vehicle id the command will clear that vehicle. Without a vehicle id the command will despawn all of your spawned vehicles.",PermNone,false,false,false},
	{CommandPvp,{"pvp","check_pvp"},"[Player ID]","With a player id the command will tell you the pvp state of that player. Without a player id the command will toggle your pvp state.",PermNone,false,false,false},
	{CommandPvpView,{"pvp_view","pv","pvpview"},"","Adds boxes on all vehicles within 2km that say the vehicles pvp state.",PermAuth,false,false},
	{CommandAntiSteal,{"antisteal","anti_steal","as"},"","Toggles your antisteal.",PermNone,false,false,false},
	{CommandTP,{"tp"}," [Teleport ID]","With an argument it will teleport you to the teleport point. Without an argument it will send all the teleport points to chat.",PermNone,false,false,false},
	{CommandTTP,{"ttp","teleport_to_player","tpp"},"(Player ID)","Teleports you to the specified player.",PermAuth,false,false,false},
	{CommandTTM,{"ttm","teleport_to_me"},"(Player ID)","Teleports the specified player to you.",PermMod,false,false,false},
	{CommandTVTM,{"tvtm","teleport_vehicle_to_me","here"},"[Vehicle ID]","Without a vehicle id and with only one vehicle it will teleport that vehicle to you. With a vehicle id it will teleport that vehicle to you.",PermAuth,false,false,false},
	{CommandGoto,{"goto","seat"},"[Vehicle ID]","Without a vehicle id it teleports you to the last seat you sat in. With a vehicle id it will teleport you to the first unocupied seat in the specified vehicle.",PermAuth,false,false,false},
	{CommandDiscordLink,{"discord","disc"},"","Sends you the discord link in chat.",PermNone,false,false,false},
	{CommandTool,{"tool","give","give_tool","tool_give"},"[Tool ID]", "Without arguments it will list all giveable tools. With an argument it will give the specified tool.",PermAuth,false,false,false},
	{CommandGps,{"gps","pos","position"},"","Tells you your current x y z postion",PermAuth,false,false,false},
	{CommandAnnounce,{"announce","announcement","broadcast"}, "(Chat/Notify) (Message)","Sends a notification to all players.",PermMod,false,true,false},
	{CommandClearInventory,{"clear_inv","ci","clearinv","cinv"},"[Player ID]","Without arguments it will clear your inventory. With a player id it will clear that players inventory. (Clearing other players inventory requires admin)",PermAuth,false,false,false},
	{CommandRepair,{"repair"}, "[Vehicle ID]", "Without arguments it will repair all of your vehicles. With a vehicle id it will repair the vehicle with that id. (Non admins can only repair vehicles that they own)",PermAuth,false,false,false},
	{CommandFlip,{"flip","right"},"[Vehicle ID]","Without arguments it will flip all of your vehicles. With a vehicle id it will flip a specific vehicle. (Fliping vehicles that you don't own requires admin)",PermAuth,false,false,false},
	{CommandEject,{"eject"},"[Player ID]", "Without arguments it will eject all players but you from all your vehicles. With a player id it will eject that player from your vehicles.",PermAuth,false,false,false},
	{CommandCharge,{"charge","batteries","bat","battery"},"[Vehicle ID]","Without arguments it will charge the batteries of all your vehicles. With a vehicle id it will charge all the batteries in that vehicle. (Non admins can only charge batteries on vehicles that they own)",PermAuth,false,false,false},
	{CommandFill,{"fill","set_tanks","fuel"}, "[Vehicle ID]","Without arguments it will fill the tanks all your vehicles. With a vehicle id it will fill all the tanks in that vehicle. (Non admins can only fill tanks on vehicles that they own)",PermAuth,false,false,false},
	{CommandInfiniteItems,{"inf_items","inf"},"[Slot]","Without arguments it will give you infinite ammo/uses/battery in all slots. With an argument it will give you infinite ammo/uses/battery in a specificed slot.",PermNone,false,false,false},
	{CommandKill,{"kill","die","suicide"}, "[Player ID]","Without arguments it will kill you. With a player id it will kill them. (Only admins can kill people other them themselves)",PermAuth,false,false,false},
	{CommandBlacklist,{"blacklist","bl"},"(Subcommand)","Allows you to prevent a player from interacting with your vehicles.",PermNone,false,false,false},
	{CommandFollow,{"follow"},"[Player ID] [Height]","Without arguments it will stop the following. With a player id it will teleport you above the player with a specific high (Default is 100) so you can use noclip to watch them.",PermMod,false,false,false},
	{CommandToggleInv,{"toggle_inv","ti"}, "(Player ID)","Toggles inventory for a specific player.",PermMod,false,false,false},
	{CommandToggleSpawn,{"toggle_spawn","ts"}, "(Player ID)","Toggles vehicle spawning for a specific player.",PermMod,false,false,false},
	{CommandTrackVehicles,{"track_vehicles","track_vehicle","tv"},"","Toggles tracking all vehicles.",PermMod,false,false,false},
	{CommandHeal,{"heal","h"},"[Player ID]", "Without arguments it heal you. With an argument it will heal the specified player.",PermAuth,false,false,false},
	{CommandAuth,GetServerConfigData()["AuthCommand"],"","Get auth with this command.",ReturnAuthCommandPermissions(),false,false,false},
	{CommandFreeze,{"freeze"},"(Player ID)","Freezes a player. Doing it on a player that's frozen will unfreeze them.",PermMod,false,false,false},
	{CommandListVehicles,{"list_vehicles","lv","vl"},"[Detailed]", "Lists out all player spawned vehicles.",PermMod,false,true,false},
	{CommandVehicleData,{"vehicledata","vehicle_data","vd"},"(Vehicle ID)","Shows the vehicle data for the specified vehicle.",PermMod,false,false,false},
	{CommandListStaff,{"staff","view_staff"},"","Shows a list of online staff.",PermAuth,false,true,false},
	{CommandHistory,{"history"}, "(Player ID)","Shows a players warn/ban history.",PermMod,false,true,false},
	{CommandMessage,{"msg","send","message","dm","whisper","tell"}, "(Player ID) (Message)","With a player id it will message the player with that id. (Admins can see private messages)",PermAuth,true,false,true},
	{CommandSettings,{"settings","setting"}," [Setting] [State]","Allows modification of addon settings.",PermAdmin,false,false,false},
	{CommandStats,{"server_stats"},"","Gives you server stats.",PermAuth,false,true,false},
	{CommandReply,{"r","reply","respond"},"(Message)","Messages the most recent player that messaged you or you messaged. (Admins can see private messages)",PermAuth,true,false,true},
	{CommandStaffChat,{"sc","staffchat"},"(Message)","Sends a message to staff chat.",PermNone,true,true,false},
	{CommandUI,{"ui"},"","Toggles the ui.",PermNone,false,false,false}
}


function GetCommand(Command,PeerID,CommandList,Prefix)
	for X,Y in pairs(CommandList) do
		local MatchedAlias=false
		for A,B in pairs(Y[2]) do
			if Command == Prefix .. string.lower(B) then
				MatchedAlias=true
				break
			end
		end
		if MatchedAlias == true then
			if GetPerms(PeerID) >= Y[5] and Y[5] >= 0 then
				return Y
			end
		end
	end
	return {nil,nil,nil,nil,nil,false,false,false}
end

function CommandMessageAnnounce(Name,PeerID,FullMessage)
	local PermString=""
	if g_savedata["Settings"]["ShowPermissionsInChat"] == true then
		PermString="[" .. ParsePermissions(GetPerms(PeerID),true) .. "] "
	end
	AnnounceAbovePerms("[Command]",PermString .. Name .. " - " .. FullMessage,PermMod,PeerID)
	SendHttp({"TypeCommand",tostring(PeerID),Name,FullMessage,GetSteamID(PeerID)})
end
function onCustomCommand(FullMessage, PeerID, Admin, Auth, Command, One, Two, Three, Four, Five,Discord)
	local LowCommand=string.lower(Command)
	local Name=FixBlankPlayer(server.getPlayerName(PeerID),PeerID)
	local CommandBlocked=false
	if NoSave["Player"][PeerID] ~= nil then
		CommandBlocked=NoSave["Player"][PeerID]["BanView"]
	end
	if CommandBlocked == false or GetPerms(PeerID) > 696420 then
		local CommandParsed=GetCommand(LowCommand,PeerID,CommandDirectory,"?")
		if (CommandParsed[7] == true and Discord == true) or Discord ~= true then
			
			if CommandParsed[6] ~= true and Discord ~= true then
				CommandMessageAnnounce(Name,PeerID,FullMessage)
			end
			if CommandParsed[1] ~= nil then
				local CommandResult=CommandParsed[1](FullMessage, PeerID, Admin, Auth, Command, One, Two, Three, Four, Five,Discord)
				if CommandResult ~= true and CommandParsed[8] == true and Discord ~= true then
					CommandMessageAnnounce(Name,PeerID,FullMessage)
				end
				return
			end
		end
		if Discord == true then
			DiscordNotify(PeerID, "Unknown Command", "That command is not valid or its execution is not supported over discord.", 6,Discord)
		else
			DiscordNotify(PeerID, "Unknown Command", "The command you have inputted ( " .. Command .. " ) is unknown. Do ?help for command help. ", 6,Discord)
		end
	else
		AnnounceAbovePerms("[Muted]",Name .. " - " .. FullMessage,PermMod,-1)
		SendHttp({"TypeCommand",tostring(PeerID),Name,FullMessage,GetSteamID(PeerID)})
	end
end
