-- WordGuesserGUI.lua
-- Place inside StarterPlayerScripts or StarterGui (as a LocalScript)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remote = ReplicatedStorage
	:WaitForChild("Remotes")
	:WaitForChild("SubmitGuess")

-- ─── Word Lists ───────────────────────────────────────────────────────────────

local words = {
	easy = {
		"apple","banana","orange","lemon","grape","cherry","peach","pear","strawberry",
		"pizza","burger","taco","cookie","cake","candy","milk","water","juice","bread",
		"cheese","egg","donut","fries","soda","chips","hotdog","chocolate","popcorn",
		"pancake","ice","soup","carrot","corn","milkshake","jam","mango","muffin","honey",
		"steak","phone","tablet","computer","tv","remote","book","pen","pencil","paper",
		"desk","bed","pillow","blanket","lamp","chair","table","couch","door","window",
		"key","box","bag","toy","ball","money","clock","mirror","soap","towel","bath",
		"cup","plate","bowl","spoon","fork","sink","balloon","radio","carpet","shelf",
		"mom","dad","baby","sister","brother","teacher","doctor","friend","boy","girl",
		"man","woman","king","queen","dog","cat","fish","bird","horse","cow","pig","duck",
		"bear","sun","moon","star","sky","cloud","rain","snow","fire","red","blue","green",
		"yellow","pirate","clown","stairs","sea","meat","sweet","clothes","dinner","dessert",
		"gold","breakfast","pink","meal","lunch","tea","coffee","butter","berry","snack",
		"purple","winter","paint","silver","brown","stone","sauce","melon","toast","rose",
		"doll","picture","lamb","worm","school","ocean","beach","kitchen","bedroom",
		"bathroom","floor","wall","roof","oven","garden","pool","park","watermelon",
		"tomato","pumpkin","rabbit","puppy","kitten","bottle","salt","pepper","rainbow",
		"diamond","glass","sand","stove","pineapple","lettuce","rice","eggs","lime","sugar",
		"summer","pasta","fireplace"
	},
	medium = {
		"lion","tiger","shark","spider","snake","bunny","chicken","monkey","frog","turtle",
		"whale","bee","wolf","crab","mouse","elephant","giraffe","zebra","dolphin","owl",
		"penguin","fox","hamster","parrot","lizard","camel","octopus","flower","tree","leaf",
		"grass","rock","dirt","river","mountain","forest","desert","jungle","swamp","island",
		"shirt","pants","shoe","hat","sock","jacket","dress","shorts","boot","glove","hoodie",
		"watch","ring","belt","mask","eye","nose","mouth","ear","hand","foot","hair","arm",
		"leg","tooth","finger","head","face","heart","pajamas","sneaker","elbow","shoulder",
		"button","car","truck","bus","bike","boat","plane","train","scooter","van","taxi",
		"tractor","skateboard","ship","hammer","bucket","brush","ladder","rope","slide","swing",
		"wheel","soccer","fence","magnet","trophy","wallet","whistle","bakery","seed","cheetah",
		"pastry","storm","skirt","rug","yard","shape","wing","raspberry","spaceship","jeans",
		"gorilla","airport","student","gym","spaghetti","dinosaur","ceiling","purse","library",
		"bush","crocodile","playground","basket","donkey","cotton","holiday","coral","dragon",
		"cinema","soil","cave","square","vanilla","cabinet","brownie","kiwi","thunder","lake",
		"pond","knife","piano","drum","castle","bridge","tunnel","restaurant","office","store",
		"toilet","coat","planet","sponge","broom","fridge","vacuum","laptop","city","bacon",
		"sheep","sofa","mushroom","sweater","hotel","motel","mall","factory","church","bank",
		"classroom","apartment","suitcase","bracelet","necklace","microphone","flute","violin",
		"science","math","history","pickle","broccoli","avocado","cabbage","noodles","microwave",
		"dresser","refrigerator","iron","triangle"
	},
	hard = {
		"elevator","lemonade","basketball","football","tennis","wrestling","karate","airplane",
		"tent","feather","television","flashlight","eraser","ruler","backpack","yacht","pyramid",
		"jewelry","astronaut","engineer","soldier","hospital","escalator","microscope","binoculars",
		"calculator","stapler","keyboard","headphones","dictionary","harmonica","fountain","statue",
		"bandage","battery","telescope","antenna","thermometer","microchip","camera","scissors",
		"chainsaw","submarine","helicopter","bulldozer","limousine","ambulance","satellite","rocket",
		"parachute","motorcycle","engine","controller","robot","drone","shuttle","skyscraper",
		"monument","lighthouse","cemetery","stadium","theater","laboratory","greenhouse","volcano",
		"waterfall","glacier","canyon","museum","aquarium","detective","scientist","architect",
		"referee","captain","magician","librarian","explorer","pilot","dentist","waiter","gladiator",
		"champion","witness","neighbor","mayor","sheriff","dynamite","crossbow","shield","treasure",
		"crystal","emerald","sapphire","sword","portal","clover","artifact","skeleton","helmet",
		"medal","anchor","panda","sushi","notebook","saturn","artist","cafe","grill","snail",
		"guitar","spring","tank","christmas","backyard","squid","crown","vet","sausage","ruby",
		"candle","coin","cheeseburger","drawer","rooster","diner","market","wardrobe","shrimp",
		"salmon","earring","tub","flamingo","mansion","monitor","badminton","cheesecake","lightning",
		"attic","squirrel","jellyfish","umbrella","starfish","village","instrument","lobster","kite",
		"subway","witch","firefighter","onion","shovel","bubble","seaweed","bench","mattress","seafood",
		"baker","saxophone","accordion","blender","dishwasher","snowboard","propeller","planetarium",
		"carnival","circus","highway","harbor","knight","ninja","samurai","werewolf","wizard","vampire",
		"zombie","unicorn","mermaid","ghost","fairy","volleyball","hockey","bowling","boxing","chess",
		"rugby","softball","cricket","golf","judge","professor","surgeon","lawyer","president","nurse",
		"chef","farmer","scarf","gloves","boots","crayon","costume","curtain"
	},
	impossible = {
		"stethoscope","kaleidoscope","hourglass","tongue","wrist","knee","ankle","eyebrow","jaw","brain",
		"skull","smoothie","waffle","cereal","yogurt","ketchup","mustard","oatmeal","croissant","bagel",
		"popsicle","gravity","oxygen","electricity","tornado","meteor","galaxy","comet","asteroid",
		"atmosphere","eclipse","iceberg","birthday","wedding","halloween","chimney","balcony","mechanic",
		"plumber","sailor","mosquito","ladybug","scorpion","beetle","dragonfly","phoenix","leprechaun",
		"alligator","jaguar","hippo","koala","sloth"
	},
}

local difficultyOrder = { "easy", "medium", "hard", "impossible" }

-- ─── State ────────────────────────────────────────────────────────────────────

local isRunning = false
local killSwitch = false
local selectedDifficulties = { easy = true, medium = false, hard = false, impossible = false }
local stats = { success = 0, failed = 0, total = 0 }

-- ─── GUI Construction ─────────────────────────────────────────────────────────

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "WordGuesserGUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Colours / theme
local CLR = {
	bg        = Color3.fromRGB(10, 10, 18),
	panel     = Color3.fromRGB(18, 18, 30),
	border    = Color3.fromRGB(50, 50, 80),
	accent    = Color3.fromRGB(100, 220, 255),
	danger    = Color3.fromRGB(255, 80, 80),
	success   = Color3.fromRGB(80, 255, 140),
	warn      = Color3.fromRGB(255, 200, 60),
	text      = Color3.fromRGB(220, 220, 240),
	muted     = Color3.fromRGB(120, 120, 160),
	easy      = Color3.fromRGB(80, 220, 120),
	medium    = Color3.fromRGB(80, 160, 255),
	hard      = Color3.fromRGB(255, 140, 60),
	impossible= Color3.fromRGB(220, 60, 255),
}

-- ── Helper: make a rounded frame ──────────────────────────────────────────────
local function mkFrame(parent, size, pos, color, corner, zIndex)
	local f = Instance.new("Frame")
	f.Size = size
	f.Position = pos
	f.BackgroundColor3 = color or CLR.panel
	f.BorderSizePixel = 0
	f.ZIndex = zIndex or 1
	if corner then
		local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, corner); c.Parent = f
	end
	f.Parent = parent
	return f
end

-- ── Helper: make a label ──────────────────────────────────────────────────────
local function mkLabel(parent, text, size, pos, color, fontSize, bold, zIndex)
	local l = Instance.new("TextLabel")
	l.Size = size
	l.Position = pos
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextColor3 = color or CLR.text
	l.TextSize = fontSize or 14
	l.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.ZIndex = zIndex or 2
	l.Parent = parent
	return l
end

-- ── Helper: make a button ─────────────────────────────────────────────────────
local function mkButton(parent, text, size, pos, bgColor, textColor, corner, zIndex)
	local b = Instance.new("TextButton")
	b.Size = size
	b.Position = pos
	b.BackgroundColor3 = bgColor or CLR.accent
	b.BorderSizePixel = 0
	b.Text = text
	b.TextColor3 = textColor or CLR.bg
	b.TextSize = 13
	b.Font = Enum.Font.GothamBold
	b.AutoButtonColor = false
	b.ZIndex = zIndex or 2
	if corner then
		local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, corner); c.Parent = b
	end
	b.Parent = parent
	return b
end

-- ── Main window ───────────────────────────────────────────────────────────────
local mainFrame = mkFrame(
	screenGui,
	UDim2.new(0, 340, 0, 480),
	UDim2.new(0, 20, 0.5, -240),
	CLR.bg, 12, 1
)

-- Outer glow border
local border = mkFrame(mainFrame, UDim2.new(1, 2, 1, 2), UDim2.new(0, -1, 0, -1), CLR.border, 13, 0)

-- Title bar
local titleBar = mkFrame(mainFrame, UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 0, 0), CLR.panel, 0, 2)
do
	local tc = Instance.new("UICorner"); tc.CornerRadius = UDim.new(0, 12); tc.Parent = titleBar
end
local titleLabel = mkLabel(titleBar, "⚡  WORD GUESSER", UDim2.new(1, -60, 1, 0), UDim2.new(0, 14, 0, 0), CLR.accent, 15, true, 3)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Close / drag handle (cosmetic close — hides GUI)
local closeBtn = mkButton(titleBar, "✕", UDim2.new(0, 30, 0, 30), UDim2.new(1, -38, 0, 5), CLR.danger, Color3.new(1,1,1), 8, 3)
closeBtn.MouseButton1Click:Connect(function()
	mainFrame.Visible = false
end)

-- Drag logic
local dragging, dragStart, startPos
titleBar.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = i.Position
		startPos = mainFrame.Position
	end
end)
titleBar.InputChanged:Connect(function(i)
	if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = i.Position - dragStart
		mainFrame.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
	end
end)
titleBar.InputEnded:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

-- ── Difficulty selector ───────────────────────────────────────────────────────
mkLabel(mainFrame, "DIFFICULTY", UDim2.new(1, -20, 0, 16), UDim2.new(0, 14, 0, 48), CLR.muted, 11, true, 2)

local diffButtons = {}
local diffColors = { easy = CLR.easy, medium = CLR.medium, hard = CLR.hard, impossible = CLR.impossible }
local diffXPos = { easy = 0, medium = 85, hard = 170, impossible = 248 }
local diffWidths = { easy = 76, medium = 76, hard = 70, impossible = 84 }

for _, diff in ipairs(difficultyOrder) do
	local btn = mkButton(
		mainFrame,
		diff:upper():sub(1,1)..diff:sub(2),
		UDim2.new(0, diffWidths[diff], 0, 28),
		UDim2.new(0, 14 + diffXPos[diff], 0, 68),
		selectedDifficulties[diff] and diffColors[diff] or CLR.panel,
		selectedDifficulties[diff] and CLR.bg or CLR.muted,
		6, 2
	)
	-- border stroke
	local stroke = Instance.new("UIStroke")
	stroke.Color = diffColors[diff]
	stroke.Thickness = 1
	stroke.Parent = btn
	diffButtons[diff] = btn

	btn.MouseButton1Click:Connect(function()
		selectedDifficulties[diff] = not selectedDifficulties[diff]
		local on = selectedDifficulties[diff]
		TweenService:Create(btn, TweenInfo.new(0.15), {
			BackgroundColor3 = on and diffColors[diff] or CLR.panel,
			TextColor3 = on and CLR.bg or CLR.muted,
		}):Play()
	end)

	btn.MouseEnter:Connect(function()
		if not selectedDifficulties[diff] then
			TweenService:Create(btn, TweenInfo.new(0.1), { BackgroundColor3 = Color3.fromRGB(30,30,50) }):Play()
		end
	end)
	btn.MouseLeave:Connect(function()
		if not selectedDifficulties[diff] then
			TweenService:Create(btn, TweenInfo.new(0.1), { BackgroundColor3 = CLR.panel }):Play()
		end
	end)
end

-- ── Delay slider ──────────────────────────────────────────────────────────────
mkLabel(mainFrame, "DELAY (ms)", UDim2.new(0, 80, 0, 16), UDim2.new(0, 14, 0, 106), CLR.muted, 11, true, 2)

local delayMin, delayMax = 600, 2000
local delayValue = 1000 -- ms

local delayDisplay = mkLabel(mainFrame, tostring(delayValue).." ms", UDim2.new(0, 80, 0, 16), UDim2.new(1, -94, 0, 106), CLR.accent, 11, true, 2)
delayDisplay.TextXAlignment = Enum.TextXAlignment.Right

local sliderBg = mkFrame(mainFrame, UDim2.new(1, -28, 0, 6), UDim2.new(0, 14, 0, 126), CLR.border, 3, 2)
local sliderFill = mkFrame(sliderBg, UDim2.new((delayValue - delayMin)/(delayMax - delayMin), 0, 1, 0), UDim2.new(0,0,0,0), CLR.accent, 3, 3)
local sliderKnob = mkFrame(sliderBg, UDim2.new(0, 14, 0, 14), UDim2.new((delayValue - delayMin)/(delayMax - delayMin), -7, 0.5, -7), CLR.accent, 7, 4)

local draggingSlider = false
sliderKnob.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then draggingSlider = true end end)
sliderBg.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then draggingSlider = true end end)

game:GetService("UserInputService").InputEnded:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 then draggingSlider = false end
end)

game:GetService("UserInputService").InputChanged:Connect(function(i)
	if draggingSlider and i.UserInputType == Enum.UserInputType.MouseMovement then
		local absPos = sliderBg.AbsolutePosition.X
		local absSize = sliderBg.AbsoluteSize.X
		local t = math.clamp((i.Position.X - absPos) / absSize, 0, 1)
		delayValue = math.floor(delayMin + t * (delayMax - delayMin))
		sliderFill.Size = UDim2.new(t, 0, 1, 0)
		sliderKnob.Position = UDim2.new(t, -7, 0.5, -7)
		delayDisplay.Text = tostring(delayValue).." ms"
	end
end)

-- ── Stats bar ─────────────────────────────────────────────────────────────────
local statsFrame = mkFrame(mainFrame, UDim2.new(1, -28, 0, 36), UDim2.new(0, 14, 0, 140), CLR.panel, 8, 2)
local statSuccess = mkLabel(statsFrame, "✓ 0", UDim2.new(0.33, 0, 1, 0), UDim2.new(0, 8, 0, 0), CLR.success, 13, true, 3)
local statFailed  = mkLabel(statsFrame, "✗ 0", UDim2.new(0.33, 0, 1, 0), UDim2.new(0.33, 0, 0, 0), CLR.danger, 13, true, 3)
local statTotal   = mkLabel(statsFrame, "# 0", UDim2.new(0.34, 0, 1, 0), UDim2.new(0.66, 0, 0, 0), CLR.muted, 13, true, 3)
statSuccess.TextXAlignment = Enum.TextXAlignment.Center
statFailed.TextXAlignment  = Enum.TextXAlignment.Center
statTotal.TextXAlignment   = Enum.TextXAlignment.Center

local function updateStats()
	statSuccess.Text = "✓ "..stats.success
	statFailed.Text  = "✗ "..stats.failed
	statTotal.Text   = "# "..stats.total
end

-- ── Log box ───────────────────────────────────────────────────────────────────
local logContainer = mkFrame(mainFrame, UDim2.new(1, -28, 0, 180), UDim2.new(0, 14, 0, 185), Color3.fromRGB(8, 8, 15), 8, 2)
local logScroll = Instance.new("ScrollingFrame")
logScroll.Size = UDim2.new(1, 0, 1, 0)
logScroll.BackgroundTransparency = 1
logScroll.BorderSizePixel = 0
logScroll.ScrollBarThickness = 3
logScroll.ScrollBarImageColor3 = CLR.border
logScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
logScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
logScroll.ZIndex = 3
logScroll.Parent = logContainer

local logLayout = Instance.new("UIListLayout")
logLayout.SortOrder = Enum.SortOrder.LayoutOrder
logLayout.Padding = UDim.new(0, 2)
logLayout.Parent = logScroll

local logPadding = Instance.new("UIPadding")
logPadding.PaddingLeft   = UDim.new(0, 6)
logPadding.PaddingRight  = UDim.new(0, 6)
logPadding.PaddingTop    = UDim.new(0, 4)
logPadding.PaddingBottom = UDim.new(0, 4)
logPadding.Parent = logScroll

local logLineCount = 0

local function addLog(text, color)
	logLineCount += 1
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 0, 16)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = color or CLR.text
	lbl.TextSize = 11
	lbl.Font = Enum.Font.Code
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.TextTruncate = Enum.TextTruncate.AtEnd
	lbl.LayoutOrder = logLineCount
	lbl.ZIndex = 4
	lbl.Parent = logScroll
	-- auto-scroll
	task.defer(function()
		logScroll.CanvasPosition = Vector2.new(0, math.huge)
	end)
end

-- ── Control buttons ───────────────────────────────────────────────────────────
local startBtn = mkButton(
	mainFrame, "▶  START",
	UDim2.new(0, 148, 0, 36),
	UDim2.new(0, 14, 0, 376),
	CLR.success, CLR.bg, 8, 2
)
local stopBtn = mkButton(
	mainFrame, "■  STOP",
	UDim2.new(0, 148, 0, 36),
	UDim2.new(0, 178, 0, 376),
	CLR.danger, Color3.new(1,1,1), 8, 2
)

-- Progress bar
local progBg = mkFrame(mainFrame, UDim2.new(1, -28, 0, 6), UDim2.new(0, 14, 0, 422), CLR.border, 3, 2)
local progFill = mkFrame(progBg, UDim2.new(0, 0, 1, 0), UDim2.new(0,0,0,0), CLR.accent, 3, 3)

local statusLabel = mkLabel(mainFrame, "Idle — select difficulty and press START", UDim2.new(1, -28, 0, 18), UDim2.new(0, 14, 0, 434), CLR.muted, 11, false, 2)
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextTruncate = Enum.TextTruncate.AtEnd

-- ── Hover effects for main buttons ────────────────────────────────────────────
for _, btn in ipairs({ startBtn, stopBtn }) do
	local orig = btn.BackgroundColor3
	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.1), { BackgroundColor3 = btn.BackgroundColor3:Lerp(Color3.new(1,1,1), 0.15) }):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.1), { BackgroundColor3 = orig }):Play()
	end)
end

-- ── Core runner ───────────────────────────────────────────────────────────────

local function setRunning(val)
	isRunning = val
	startBtn.AutoButtonColor = false
	stopBtn.AutoButtonColor = false
	startBtn.BackgroundColor3 = val and Color3.fromRGB(50, 100, 60) or CLR.success
	startBtn.Text = val and "⏳ RUNNING" or "▶  START"
end

local function buildWordList()
	local list = {}
	for _, diff in ipairs(difficultyOrder) do
		if selectedDifficulties[diff] then
			for _, w in ipairs(words[diff]) do
				table.insert(list, { word = w, diff = diff })
			end
		end
	end
	return list
end

startBtn.MouseButton1Click:Connect(function()
	if isRunning then return end

	local list = buildWordList()
	if #list == 0 then
		addLog("[!] Select at least one difficulty!", CLR.warn)
		return
	end

	-- Reset
	killSwitch = false
	stats = { success = 0, failed = 0, total = #list }
	updateStats()
	statTotal.Text = "# "..#list

	setRunning(true)
	statusLabel.Text = "Running — "..#list.." words queued"
	addLog("━━━ Session started ("..#list.." words) ━━━", CLR.accent)

	task.spawn(function()
		for i, entry in ipairs(list) do
			if killSwitch then
				addLog("⛔ Stopped by kill switch at word "..i, CLR.danger)
				break
			end

			local word = entry.word
			local diff = entry.diff
			local clr = diffColors[diff]

			local ok, err = pcall(function()
				remote:FireServer(word)
			end)

			if ok then
				stats.success += 1
				addLog(string.format("[%s] ✓ %s", diff, word), clr)
			else
				stats.failed += 1
				addLog(string.format("[%s] ✗ %s  (%s)", diff, word, tostring(err)), CLR.danger)
			end

			updateStats()

			-- progress bar
			local pct = i / #list
			TweenService:Create(progFill, TweenInfo.new(0.3), { Size = UDim2.new(pct, 0, 1, 0) }):Play()

			statusLabel.Text = string.format("Word %d/%d — last: %s", i, #list, word)

			task.wait(delayValue / 1000)
		end

		if not killSwitch then
			addLog("━━━ Done! ✓"..stats.success.."  ✗"..stats.failed.." ━━━", CLR.success)
			statusLabel.Text = "Finished ✓"..stats.success.."  ✗"..stats.failed
		else
			statusLabel.Text = "Stopped. ✓"..stats.success.."  ✗"..stats.failed
		end

		setRunning(false)
		TweenService:Create(progFill, TweenInfo.new(0.4), { Size = UDim2.new(0, 0, 1, 0) }):Play()
	end)
end)

stopBtn.MouseButton1Click:Connect(function()
	if isRunning then
		killSwitch = true
		statusLabel.Text = "Stopping…"
		addLog("⛔ Kill switch triggered!", CLR.danger)
	end
end)

-- ── Pulse accent line on titlebar ─────────────────────────────────────────────
local accentLine = mkFrame(mainFrame, UDim2.new(1, 0, 0, 2), UDim2.new(0, 0, 0, 40), CLR.accent, 0, 2)
spawn(function()
	while true do
		TweenService:Create(accentLine, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{ BackgroundColor3 = CLR.impossible }):Play()
		task.wait(4)
	end
end)

addLog("Word Guesser loaded. Select difficulty & press START.", CLR.muted)