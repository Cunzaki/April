--[[
		Thank you for using UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw.

		If you didn't save in Binary (rbxl) - it's recommended to save the game right away to take advantage of the binary format & to preserve values of certain properties if you used IgnoreDefaultProperties setting (as they might change in the future).
		You can do that by going to FILE -> Save to File As -> Make sure File Name ends with .rbxl -> Save

		ServerStorage, ServerScriptService and Server Scripts are IMPOSSIBLE to save because of FilteringEnabled.

		If your player cannot spawn into the game, please move the scripts in StarterPlayer somewhere else or delete them. Then run `game:GetService("Players").CharacterAutoLoads = true`.
		And use "Play Here" to start game instead of "Play" to spawn your Character where your Camera currently is.

		If the chat system does not work, please use the explorer and delete everything inside the TextChatService/Chat service(s). 
		Or run `game:GetService("Chat"):ClearAllChildren() game:GetService("TextChatService"):ClearAllChildren()`
				
		If Union and MeshPart collisions don't work, run the script below in the Studio Command Bar:
				
				
		local C = game:GetService("CoreGui")
		local D = Enum.CollisionFidelity.Default
				
		for _, v in game:GetDescendants() do
			if v:IsA("TriangleMeshPart") and not v:IsDescendantOf(C) then
				v.CollisionFidelity = D
			end
		end
		print("Done")
				
		If you can't move the Camera, run this script in the Studio Command Bar:
			
		workspace.CurrentCamera.CameraType = Enum.CameraType.Fixed
		
		Or Destroy the Camera.

		This file was generated with the following settings:
		{"SavePlayerCharacters":false,"SaveBytecode":false,"Callback":false,"ShowStatus":true,"IgnoreDefaultPlayerScripts":true,"NilInstancesFixes":{"BaseWrap":null,"Animator":null,"Attachment":null,"PackageLink":null,"AdPortal":null},"IgnoreList":["CoreGui","CorePackages"],"__DEBUG_MODE":false,"KillAllScripts":true,"DecompileJobless":false,"Decompile":true,"IgnoreNotArchivable":true,"Object":false,"DecompileIgnore":["TextChatService",null,null,null,null,null],"IgnoreSpecialProperties":false,"BoostFPS":true,"IsModel":false,"NilInstances":false,"ExtraInstances":[],"ReadMe":true,"OptionsAliasesInverse":{"noscripts":"Decompile","RemovePlayers":"IsolatePlayers","RemovePlayerCharacters":"SavePlayerCharacters"},"OptionsAliases":{"IgnoreDefaultProps":"IgnoreDefaultProperties","timeout":"DecompileTimeout","FileName":"FilePath","SaveCharacters":"SavePlayerCharacters","IgnoreArchivable":"IgnoreNotArchivable","SavePlayers":"IsolatePlayers","SaveLocalPlayer":"IsolateLocalPlayer","InstancesBlacklist":"IgnoreList","IsolatePlayerGui":"IsolateLocalPlayer","SaveNonCreatable":"SaveNotCreatable","SavePlayerGui":"IsolateLocalPlayer"},"SharedStringOverwrite":false,"scriptcache":true,"TreatUnionsAsParts":false,"AlternativeWritefile":true,"mode":"optimized","SaveCacheInterval":56320,"IgnoreSharedStrings":true,"IsolatePlayers":false,"NotCreatableFixes":["","AdvancedDragger","AnimationTrack","Dragger","Player","PlayerGui","PlayerMouse","PlayerMouse","PlayerScripts","ScreenshotHud","StudioData","TextChatMessage","TextSource","TouchTransmitter","Translator"],"FilePath":false,"IgnoreDefaultProperties":true,"Anonymous":false,"IsolateStarterPlayer":false,"IsolateLocalPlayerCharacter":false,"IgnorePropertiesOfNotScriptsOnScriptsMode":false,"AvoidFileOverwrite":true,"SaveNotCreatable":false,"IsolateLocalPlayer":false,"ShutdownWhenDone":false,"AntiIdle":true,"SafeMode":true,"IgnoreProperties":[],"DecompileTimeout":10}

		Elapsed time: 42.75592389999656 Date (UTC): 13 July 2026 05:49:32 PlaceId: 13800717766 PlaceVersion: 792 Client Version: 0.729.24.7290838 Platform: Windows Executor: Volt 1.3.0.2
]]