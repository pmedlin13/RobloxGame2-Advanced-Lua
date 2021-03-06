local GameMode = {};

local Gets = script.Parent.Parent.Get
local Set = script.Parent.Parent.Set.PlayerData;
function Get(What)
	return Gets:FindFirstChild(What):Invoke();
end

local Data = require(script.Parent.Parent.DataModule);
local GameFunctions = Get("GameFunctions");

local VictoryMusic = game.ReplicatedStorage.Music.RoundEnd.victoryM
local LoserMusic = game.ReplicatedStorage.Music.RoundEnd.loserM
local PlaySong = game.ReplicatedStorage.PlayMusic

local RoleData = {};

GameMode.Name = "FreezeTag";

GameMode.Icon = "https://www.roblox.com/asset/?id=362564414";

GameMode.Coins = true;

--GameMode.Outfits = "Custom";

--GameMode.OutfitFolder = script.Outfits;

GameMode.GameTimer = 120;

GameMode.PlayerData = {};

GameMode.RoleSelectWait = 8;

GameMode.DoRoles = function()
	-- No roles needed!
end

--local WeldHat = require(script.WeldHat);

GameMode.MakeCharacter = require(script.MakeCharacter);

GameMode.GeneratePlayerData = function()
	GameMode.PlayerData = {};
	local Teams = {
		Red = {
			Name="Red";
			Pl={};
		};
		Blue = {
			Pl={};
			Name="Blue";
		};
	};
	local TeamColors = {
		Red = {
			BrickColor.new("Maroon");
			BrickColor.new("Bright red");
			BrickColor.new("Really red");
			BrickColor.new("Crimson");
			BrickColor.new("Persimmon");
			BrickColor.new("Dusty Eose");
		};
		Blue = {
			BrickColor.new("Bright blue");
			BrickColor.new("Electric blue");
			BrickColor.new("Cyan");
			BrickColor.new("Deep blue");
			BrickColor.new("Steel blue");
		};
	};
	local CodeNames = {unpack(require(game.ServerStorage.CodeNames))};
	for i,Player in pairs(game.Players:GetPlayers()) do if Player.Character ~= nil then if _G.ServerSettings.Disguises then Player:ClearCharacterAppearance(); end; 		local CodeName = math.random(1,#CodeNames);

		-----
		local Team = (#Teams.Blue.Pl>=#Teams.Red.Pl and Teams.Red.Name) or Teams.Blue.Name;
		local Role = Team;
		table.insert(Teams[Team].Pl,Player);
		local iColor = math.random(1,#TeamColors[Team]);
		local Color = TeamColors[Team][iColor];
		table.remove(TeamColors[Team],iColor);
		
		
		------
		Player.HealthDisplayDistance = 150;
		Player.NameDisplayDistance = 150;				
		GameMode.PlayerData[Player.Name] = {["Role"] = Role;["CodeName"] = CodeNames[CodeName];["Color"] = Color;["Dead"] = false;["XP"] = Data.Get(Player,"XP");["Knife"] = Data.Get(Player,"Weapons").Equipped.Knife;["Gun"] = Data.Get(Player,"Weapons").Equipped.Gun;};		
		pcall(function() Player.Character.Head.CodeNameGUI:Destroy();end);
		pcall(function() Player.Character.Torso.roblox:Destroy();end);	
		table.remove(CodeNames,CodeName);	
	end end
	return GameMode.PlayerData;
end

local function freeze(Victim, PlayerData)
	local part = script.Ice.Ice:Clone()
	part.Name = "Ice"
	part.CanCollide = false 	
	local Torso
	if Victim.Character:FindFirstChild("Torso") then
		Torso = Victim.Character.Torso
	end
	if Victim.Character:FindFirstChild("UpperTorso") then
		Torso = Victim.Character.UpperTorso
	end
	part.CFrame = Torso.CFrame 
	part.Anchored = true 
	part.Parent = Victim.Character 
	Torso.Anchored = true 
	Victim.Character.Humanoid.WalkSpeed = 0 
	
	part.Touched:connect(function(hit)
		if hit.Parent:FindFirstChild("Humanoid") then
			local player = game.Players:FindFirstChild(hit.Parent.Name)
			if player == nil then return end
			if player == Victim then return end
			if PlayerData[player.Name].Role == "Red" and PlayerData[player.Name].Dead == false then
				PlayerData[Victim.Name].Dead = false
				Torso.Anchored = false
				Victim.Character.Humanoid.WalkSpeed = 16
				part:Destroy()
			end
		end
	end)
end

GameMode.KnifeKill = function(Killer,Victim,VictimHumanoid,KillType,PlayerData)
	print("Attempt to freeze Player")
	if PlayerData[Victim.Name].Role == "Blue" then return; end;
	if PlayerData[Killer.Name].Role == "Red" then return; end;
	
	local CreatorTag = Instance.new("ObjectValue")
	CreatorTag.Name = ( KillType == "Throwing" and "Creator2" ) or "Creator";
	CreatorTag.Value = Killer;
	CreatorTag.Parent = VictimHumanoid;
	if PlayerData[Victim.Name].Role == "Red" and PlayerData[Victim.Name].Dead == false then 
		freeze(Victim, PlayerData)
		game.ReplicatedStorage.ActionText:FireClient(Victim,"You have been Frozen!",10);
		PlayerData[Victim.Name].Dead = true
	end;
end

GameMode.GunKill = function(Killer,Victim,VictimHumanoid,PlayerData)
end

GameMode.SpawnPlayers = function()
	local PlayerData = Get("PlayerData");
	local Map = Get("Map");
	local Sync = Get("Sync");

	local TeamSpawns = {
		Red = Map.RedSpawns:GetChildren();
		Blue = Map.BlueSpawns:GetChildren();
	};
	
	for _,Player in pairs(game.Players:GetPlayers()) do if PlayerData[Player.Name] ~= nil then if PlayerData[Player.Name]["Dead"] == false then if Player.Character ~= nil then
		
		local Team = PlayerData[Player.Name].Role;
		local Spawns = TeamSpawns[Team];

		------------ add teamcolor---------------------
		Player.TeamColor = game.Teams[Team].TeamColor
		Player.Neutral = false
		--------------------------------------------------------

		local iSpawn = math.random(1,#Spawns);
		local Spawn = Spawns[iSpawn];
		table.remove(TeamSpawns,iSpawn);
		
		local OppositeTeam = (Team=="Red"and"Blue")or"Red";
		local OS = Map[OppositeTeam.."Spawns"][Spawn.Name].CFrame.p;
		
		local Rotation = CFrame.new(OS.X,OS.Y+3.5,OS.Z).p;
		local Torso
		if Player.Character:FindFirstChild("Torso") then
			Torso = Player.Character.Torso
		end
		if Player.Character:FindFirstChild("UpperTorso") then
			Torso = Player.Character.UpperTorso
		end
		Torso.CFrame = CFrame.new( Spawn.CFrame.p+Vector3.new(0,2,0), Rotation);	
		Player.Character.Humanoid.WalkSpeed = 0;
				

	end end end end;
end

GameMode.GiveWeapons = function()
	local PlayerData = Get("PlayerData");
	for _,Player in pairs(game.Players:GetPlayers()) do
		pcall(function()
			local Knife = GameFunctions.GiveWeapon.Knife(Player);
			Player.Character.Humanoid.WalkSpeed = 16;
		end);
	end;
end

GameMode.Died = function(Player)
	Set:Fire(Player.Name,"Dead",true);
end

local function GetWinners()
	local T = {Red=0;Blue=0;};
	
	for Player,pData in pairs(Get("PlayerData")) do
		if not pData.Dead then T[pData.Role]=T[pData.Role]+1; end;
	end;
	
	local BlueWins = (T.Red<1);
	return BlueWins
end

GameMode.EndConditions = function()	
	local BlueWins = GetWinners();
	return BlueWins or false;
end


GameMode.Reward = function(PlayerData,TimerData)	
	local BlueWon = GetWinners();
	local RedWon
	print(TimerData)
	if TimerData <= 0 then
		RedWon = true
		BlueWon = false
	end
	local WinningTeam = (RedWon and "Red") or (BlueWon and "Blue") or nil;
	local TitleText = (WinningTeam and WinningTeam.. " has won") or "It's a tie!";
	local TitleTextColor = 
			WinningTeam=="Red" and Color3.new(217/255, 35/255, 35/255) or
			WinningTeam=="Blue" and Color3.new(63/255, 176/255, 224/255) or
			Color3.new(1,1,1);
			
	
	
	for Player,pData in pairs(PlayerData) do
		pcall(function()
			local PlayerWon = (pData.Role==WinningTeam);
			local XPAmount = (PlayerWon and 50) or 10;	

			local Song =  (PlayerWon and VictoryMusic)or LoserMusic;
			PlaySong:FireClient(game.Players[Player], Song)			

			local CoinAmount = (PlayerWon and 10) or 5;
			local IsElite = _G.CheckElite(game.Players[Player]);
			local EliteAmount = ( IsElite and math.ceil(CoinAmount*0.5) ) or 0;
			local CoinText = "You earned " .. CoinAmount .. " coins for " .. ((PlayerWon and "winning.") or "participating.");
			if IsElite then 
				CoinText = CoinText .. " (+" .. EliteAmount .. " from Elite)";
			end
			Data.Give(game.Players[Player],"Credits",CoinAmount+EliteAmount);		
			
			Data.Give(game.Players[Player],"XP",XPAmount);
			game.ReplicatedStorage.GameOver:FireClient(
				game.Players[Player],
				PlayerData,
				TimerData,
				GameMode.Name,
				"You gained " .. XPAmount*10 .. " xp for " .. ((PlayerWon and "winning.") or "participating."),
				WinningTeam,
				TitleText,
				TitleTextColor,
				CoinText
			);
		end);
	end
	
end

return GameMode;






