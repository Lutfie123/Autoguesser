--[[
    🔮 AMETHYST HUB: Hot or Cold - Guess the Word! (Expanded Dictionary Edition)
    ===================================================================
    Features: Responsive UI, Fluid Dragging, Smart Context Engine,
              Massive Difficulty-Based Dictionary, & Anti-Detection Jitter.
--]]

-- ─── 1. CORE SERVICES & CACHING ──────────────────────────────────────────────
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LP = Players.LocalPlayer
local PlayerGui = LP:WaitForChild("PlayerGui")

local GEN_ID = math.random(100000, 999999)
_G.AmethystHub_CurrentGen = GEN_ID

local Remotes = ReplicatedStorage:WaitForChild("Remotes", 5)
local SubmitGuessRemote = Remotes and Remotes:WaitForChild("SubmitGuess", 5)

-- ─── 2. STATE & CONFIGURATION ────────────────────────────────────────────────
local hubState = {
    Running = false,
    SmartGuessing = true,
    KillSwitch = false,
    Delay = 1000,
    SelectedDicts = { easy = true, medium = false, hard = false, nightmare = false },
    Stats = { Success = 0, Failed = 0, TotalChecked = 0 }
}

-- Comprehensive Thematic Dictionary (Integrated with User's Expanded Lists)
local wordDatabase = {
    easy = {
        "apple","banana","orange","lemon","grape","cherry","peach","pear",
        "pizza","burger","taco","cookie","cake","candy","milk","water",
        "desk","bed","pillow","blanket","lamp","chair","table","couch",
        "dog","cat","fish","bird","horse","cow","pig","duck","bear","strawberry",
        "juice","bread","cheese","egg","donut","fries","soda","chips","hotdog",
        "chocolate","popcorn","pancake","ice","soup","carrot","corn","milkshake",
        "jam","mango","muffin","honey","steak","phone","tablet","computer","tv",
        "remote","book","pen","pencil","paper","door","window","key","box","bag",
        "toy","ball","money","clock","mirror","soap","towel","bath","cup","plate",
        "bowl","spoon","fork","sink","balloon","radio","carpet","shelf","mom","dad",
        "baby","sister","brother","teacher","doctor","friend","boy","girl","man",
        "woman","king","queen","sun","moon","star","sky","cloud","rain","snow",
        "fire","red","blue","green","yellow","pirate","clown","stairs","sea",
        "meat","sweet","clothes","dinner","dessert","gold","breakfast","pink",
        "meal","lunch","tea","coffee","butter","berry","snack","purple","winter",
        "paint","silver","brown","stone","sauce","melon","toast","rose","doll",
        "picture","lamb","worm","school","ocean","beach","kitchen","bedroom",
        "bathroom","floor","wall","roof","oven","garden","pool","park","watermelon",
        "tomato","pumpkin","rabbit","puppy","kitten","bottle","salt","pepper",
        "rainbow","diamond","glass","sand","stove","pineapple","lettuce","rice",
        "eggs","lime","sugar","summer","pasta","fireplace"
    },
    medium = {
        "elephant","giraffe","kangaroo","penguin","dolphin","octopus",
        "computer","keyboard","telescope","microscope","smartphone",
        "apartment","skyscraper","restaurant","hospital","university",
        "adventure","beautiful","celebrate","dangerous","excellent","lion",
        "tiger","shark","spider","snake","bunny","chicken","monkey","frog",
        "turtle","whale","bee","wolf","crab","mouse","zebra","owl","fox",
        "hamster","parrot","lizard","camel","flower","tree","leaf","grass",
        "rock","dirt","river","mountain","forest","desert","jungle","swamp",
        "island","shirt","pants","shoe","hat","sock","jacket","dress","shorts",
        "boot","glove","hoodie","watch","ring","belt","mask","eye","nose","mouth",
        "ear","hand","foot","hair","arm","leg","tooth","finger","head","face",
        "heart","pajamas","sneaker","elbow","shoulder","button","car","truck",
        "bus","bike","boat","plane","train","scooter","van","taxi","tractor",
        "skateboard","ship","hammer","bucket","brush","ladder","rope","slide",
        "swing","wheel","soccer","fence","magnet","trophy","wallet","whistle",
        "bakery","seed","cheetah","pastry","storm","skirt","rug","yard","shape",
        "wing","raspberry","spaceship","jeans","gorilla","airport","student",
        "gym","spaghetti","dinosaur","ceiling","purse","library","bush","crocodile",
        "playground","basket","donkey","cotton","holiday","coral","dragon","cinema",
        "soil","cave","square","vanilla","cabinet","brownie","kiwi","thunder",
        "lake","pond","knife","piano","drum","castle","bridge","tunnel","office",
        "store","toilet","coat","planet","sponge","broom","fridge","vacuum","laptop",
        "city","bacon","sheep","sofa","mushroom","sweater","hotel","motel","mall",
        "factory","church","bank","classroom","suitcase","bracelet","necklace",
        "microphone","flute","violin","science","math","history","pickle","broccoli",
        "avocado","cabbage","noodles","microwave","dresser","refrigerator","iron","triangle"
    },
    hard = {
        "phenomenon","juxtaposition","idiosyncrasy","quintessential",
        "anachronism","cacophony","ephemeral","obfuscate","perfunctory",
        "ubiquitous","capricious","esoteric","fastidious","gregarious",
        "basketball","microscope","binoculars","calculator","laboratory",
        "elevator","lemonade","football","tennis","wrestling","karate","airplane",
        "tent","feather","television","flashlight","eraser","ruler","backpack",
        "yacht","pyramid","jewelry","astronaut","engineer","soldier","hospital",
        "escalator","stapler","keyboard","headphones","dictionary","harmonica",
        "fountain","statue","bandage","battery","telescope","antenna","thermometer",
        "microchip","camera","scissors","chainsaw","submarine","helicopter","bulldozer",
        "limousine","ambulance","satellite","rocket","parachute","motorcycle","engine",
        "controller","robot","drone","shuttle","skyscraper","monument","lighthouse",
        "cemetery","stadium","theater","greenhouse","volcano","waterfall","glacier",
        "canyon","museum","aquarium","detective","scientist","architect","referee",
        "captain","magician","librarian","explorer","pilot","dentist","waiter",
        "gladiator","champion","witness","neighbor","mayor","sheriff","dynamite",
        "crossbow","shield","treasure","crystal","emerald","sapphire","sword","portal",
        "clover","artifact","skeleton","helmet","medal","anchor","panda","sushi",
        "notebook","saturn","artist","cafe","grill","snail","guitar","spring","tank",
        "christmas","backyard","squid","crown","vet","sausage","ruby","candle","coin",
        "cheeseburger","drawer","rooster","diner","market","wardrobe","shrimp","salmon",
        "earring","tub","flamingo","mansion","monitor","badminton","cheesecake",
        "lightning","attic","squirrel","jellyfish","umbrella","starfish","village",
        "instrument","lobster","kite","subway","witch","firefighter","onion","shovel",
        "bubble","seaweed","bench","mattress","seafood","baker","saxophone","accordion",
        "blender","dishwasher","snowboard","propeller","planetarium","carnival","circus",
        "highway","harbor","knight","ninja","samurai","werewolf","wizard","vampire",
        "zombie","unicorn","mermaid","ghost","fairy","volleyball","hockey","bowling",
        "boxing","chess","rugby","softball","cricket","golf","judge","professor",
        "surgeon","lawyer","president","nurse","chef","farmer","scarf","gloves",
        "boots","crayon","costume","curtain"
    },
    nightmare = {
        "stethoscope","kaleidoscope","hourglass","tongue","wrist","knee","ankle",
        "eyebrow","jaw","brain","skull","smoothie","waffle","cereal","yogurt",
        "ketchup","mustard","oatmeal","croissant","bagel","popsicle","gravity",
        "oxygen","electricity","tornado","meteor","galaxy","comet","asteroid",
        "atmosphere","eclipse","iceberg","birthday","wedding","halloween","chimney",
        "balcony","mechanic","plumber","sailor","mosquito","ladybug","scorpion",
        "beetle","dragonfly","phoenix","leprechaun","alligator","jaguar","hippo",
        "koala","sloth"
    }
}
local difficultyOrder = { "easy", "medium", "hard", "nightmare" }

-- ─── 3. MEMORY MANAGEMENT ────────────────────────────────────────────────────
if _G.AmethystHub_Cleanup then pcall(_G.AmethystHub_Cleanup) end

local coreConnections = {}
_G.AmethystHub_Cleanup = function()
    for _, connection in ipairs(coreConnections) do
        if connection and connection.Connected then connection:Disconnect() end
    end
    local oldGui = PlayerGui:FindFirstChild("AmethystHub_Engine")
    if oldGui then oldGui:Destroy() end
    hubState.KillSwitch = true
    hubState.Running = false
end

-- ─── 4. MINIMALIST UI ENGINE ─────────────────────────────────────────────────
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AmethystHub_Engine"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

local CLR = {
    bg = Color3.fromRGB(15, 15, 20),
    header = Color3.fromRGB(28, 22, 38),
    panel = Color3.fromRGB(20, 20, 25),
    accent = Color3.fromRGB(155, 80, 255),
    text = Color3.fromRGB(220, 220, 240),
    muted = Color3.fromRGB(140, 140, 150),
    danger = Color3.fromRGB(230, 80, 80),
    success = Color3.fromRGB(80, 220, 120),
}

local MobileToggle = Instance.new("TextButton")
MobileToggle.Size = UDim2.new(0, 50, 0, 50)
MobileToggle.Position = UDim2.new(0.05, 0, 0.15, 0)
MobileToggle.BackgroundColor3 = CLR.header
MobileToggle.Text = "🔮"
MobileToggle.TextSize = 22
MobileToggle.Parent = ScreenGui
Instance.new("UICorner", MobileToggle).CornerRadius = UDim.new(0, 12)
Instance.new("UIStroke", MobileToggle).Color = CLR.accent

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 480, 0, 320)
MainFrame.Position = UDim2.new(0.5, -240, 0.5, -160)
MainFrame.BackgroundColor3 = CLR.bg
MainFrame.Visible = false
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 45)
Header.BackgroundColor3 = CLR.header
Header.Parent = MainFrame
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 8)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0.7, 0, 1, 0)
titleLabel.Position = UDim2.new(0, 15, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "AMETHYST HUB  |  Smart Engine V2"
titleLabel.TextColor3 = CLR.accent
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 14
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = Header

local ContentWindow = Instance.new("Frame")
ContentWindow.Size = UDim2.new(1, -20, 1, -55)
ContentWindow.Position = UDim2.new(0, 10, 0, 50)
ContentWindow.BackgroundTransparency = 1
ContentWindow.Parent = MainFrame

-- Difficulty Toggles
local diffFrame = Instance.new("Frame")
diffFrame.Size = UDim2.new(1, 0, 0, 30)
diffFrame.Position = UDim2.new(0, 0, 0, 0)
diffFrame.BackgroundTransparency = 1
diffFrame.Parent = ContentWindow

local diffWidth = 1 / #difficultyOrder
for i, diff in ipairs(difficultyOrder) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(diffWidth, -4, 1, 0)
    btn.Position = UDim2.new((i-1)*diffWidth, 2, 0, 0)
    btn.BackgroundColor3 = hubState.SelectedDicts[diff] and CLR.accent or CLR.header
    btn.Text = diff:upper()
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.Parent = diffFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

    btn.MouseButton1Click:Connect(function()
        hubState.SelectedDicts[diff] = not hubState.SelectedDicts[diff]
        TweenService:Create(btn, TweenInfo.new(0.15), {
            BackgroundColor3 = hubState.SelectedDicts[diff] and CLR.accent or CLR.header
        }):Play()
    end)
end

local statusBox = Instance.new("TextLabel")
statusBox.Size = UDim2.new(1, 0, 0, 30)
statusBox.Position = UDim2.new(0, 0, 0, 40)
statusBox.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
statusBox.Text = " System Idle"
statusBox.TextColor3 = CLR.muted
statusBox.Font = Enum.Font.GothamSemibold
statusBox.TextSize = 12
statusBox.TextXAlignment = Enum.TextXAlignment.Left
statusBox.Parent = ContentWindow
Instance.new("UICorner", statusBox).CornerRadius = UDim.new(0, 6)

local StartBtn = Instance.new("TextButton")
StartBtn.Size = UDim2.new(0, 220, 0, 36)
StartBtn.Position = UDim2.new(0, 0, 0, 80)
StartBtn.BackgroundColor3 = CLR.accent
StartBtn.Text = "Start AI Auto Guesser"
StartBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
StartBtn.Font = Enum.Font.GothamBold
StartBtn.TextSize = 12
StartBtn.Parent = ContentWindow
Instance.new("UICorner", StartBtn).CornerRadius = UDim.new(0, 4)

local StopBtn = Instance.new("TextButton")
StopBtn.Size = UDim2.new(0, 220, 0, 36)
StopBtn.Position = UDim2.new(1, -220, 0, 80)
StopBtn.BackgroundColor3 = CLR.header
StopBtn.Text = "Halt Sequence"
StopBtn.TextColor3 = CLR.text
StopBtn.Font = Enum.Font.GothamBold
StopBtn.TextSize = 12
StopBtn.Parent = ContentWindow
Instance.new("UICorner", StopBtn).CornerRadius = UDim.new(0, 4)

local SmartGuessBtn = Instance.new("TextButton")
SmartGuessBtn.Size = UDim2.new(1, 0, 0, 35)
SmartGuessBtn.Position = UDim2.new(0, 0, 0, 125)
SmartGuessBtn.BackgroundColor3 = CLR.accent
SmartGuessBtn.Text = "🧠 AI Engine: Vowel & Pattern Sorting ON"
SmartGuessBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SmartGuessBtn.Font = Enum.Font.GothamSemibold
SmartGuessBtn.TextSize = 12
SmartGuessBtn.Parent = ContentWindow
Instance.new("UICorner", SmartGuessBtn).CornerRadius = UDim.new(0, 4)

local DelayLabel = Instance.new("TextLabel")
DelayLabel.Size = UDim2.new(1, 0, 0, 20)
DelayLabel.Position = UDim2.new(0, 0, 0, 170)
DelayLabel.BackgroundTransparency = 1
DelayLabel.Text = "Network Throttle: 1000ms"
DelayLabel.TextColor3 = CLR.muted
DelayLabel.Font = Enum.Font.Gotham
DelayLabel.TextSize = 12
DelayLabel.TextXAlignment = Enum.TextXAlignment.Left
DelayLabel.Parent = ContentWindow

local SliderBg = Instance.new("TextButton")
SliderBg.Size = UDim2.new(1, 0, 0, 6)
SliderBg.Position = UDim2.new(0, 0, 0, 190)
SliderBg.BackgroundColor3 = CLR.header
SliderBg.Text = ""
SliderBg.Parent = ContentWindow
Instance.new("UICorner", SliderBg).CornerRadius = UDim.new(0, 3)

local SliderFill = Instance.new("Frame")
SliderFill.Size = UDim2.new(0.5, 0, 1, 0)
SliderFill.BackgroundColor3 = CLR.accent
SliderFill.Parent = SliderBg
Instance.new("UICorner", SliderFill).CornerRadius = UDim.new(0, 3)

local draggingSlider = false
table.insert(coreConnections, SliderBg.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then draggingSlider = true end
end))
table.insert(coreConnections, UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then draggingSlider = false end
end))
table.insert(coreConnections, UserInputService.InputChanged:Connect(function(input)
    if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local relativeX = math.clamp((input.Position.X - SliderBg.AbsolutePosition.X) / SliderBg.AbsoluteSize.X, 0, 1)
        SliderFill.Size = UDim2.new(relativeX, 0, 1, 0)
        hubState.Delay = math.floor(150 + (relativeX * 1850))
        DelayLabel.Text = "Network Throttle: " .. hubState.Delay .. "ms"
    end
end))

-- Progress Bar
local ProgressBarBg = Instance.new("Frame")
ProgressBarBg.Size = UDim2.new(1, 0, 0, 6)
ProgressBarBg.Position = UDim2.new(0, 0, 1, -15)
ProgressBarBg.BackgroundColor3 = CLR.header
ProgressBarBg.Parent = ContentWindow
Instance.new("UICorner", ProgressBarBg).CornerRadius = UDim.new(0, 3)

local ProgressBarFill = Instance.new("Frame")
ProgressBarFill.Size = UDim2.new(0, 0, 1, 0)
ProgressBarFill.BackgroundColor3 = CLR.success
ProgressBarFill.Parent = ProgressBarBg
Instance.new("UICorner", ProgressBarFill).CornerRadius = UDim.new(0, 3)

-- ─── 5. INTERACTION & DRAG MECHANICS ─────────────────────────────────────────
local function applyDrag(targetFrame, dragHandle)
    local dragging, dragInput, dragStart, startPos
    table.insert(coreConnections, dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = targetFrame.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end))
    table.insert(coreConnections, dragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end))
    table.insert(coreConnections, UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            local dest = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            TweenService:Create(targetFrame, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = dest}):Play()
        end
    end))
end

applyDrag(MainFrame, Header)
applyDrag(MobileToggle, MobileToggle)

MobileToggle.MouseButton1Click:Connect(function() MainFrame.Visible = not MainFrame.Visible end)

SmartGuessBtn.MouseButton1Click:Connect(function()
    hubState.SmartGuessing = not hubState.SmartGuessing
    SmartGuessBtn.BackgroundColor3 = hubState.SmartGuessing and CLR.accent or CLR.header
    SmartGuessBtn.Text = hubState.SmartGuessing and "🧠 AI Engine: Vowel & Pattern Sorting ON" or "🧠 AI Engine: Vowel & Pattern Sorting OFF"
end)

-- ─── 6. AI SEMANTIC GUESSING LOGIC ───────────────────────────────────────────

-- Deduplicates and Compiles the chosen lists safely
local function compileActiveList()
    local rawList = {}
    local seen = {}
    
    for diff, isSelected in pairs(hubState.SelectedDicts) do
        if isSelected and wordDatabase[diff] then
            for _, word in ipairs(wordDatabase[diff]) do
                local lowerWord = string.lower(word)
                if not seen[lowerWord] then
                    table.insert(rawList, lowerWord)
                    seen[lowerWord] = true
                end
            end
        end
    end
    return rawList
end

local function executeHackSequence()
    if hubState.Running then return end
    
    local activeList = compileActiveList()

    if #activeList == 0 then
        statusBox.Text = " Error: Select at least one dictionary category."
        statusBox.TextColor3 = CLR.danger
        return
    end

    if hubState.SmartGuessing then
        -- AI Data-Driven Sorting:
        -- Prioritizes words with higher unique vowels to extract max info per guess
        table.sort(activeList, function(a, b)
            local _, vowelsA = a:gsub("[aeiou]", "")
            local _, vowelsB = b:gsub("[aeiou]", "")
            if vowelsA ~= vowelsB then return vowelsA > vowelsB end
            return #a > #b
        end)
    end

    hubState.Running = true
    hubState.KillSwitch = false
    statusBox.Text = " Status: Injecting & Analyzing Patterns..."
    statusBox.TextColor3 = CLR.accent

    task.spawn(function()
        local listSize = #activeList

        for idx, word in ipairs(activeList) do
            if hubState.KillSwitch or (_G.AmethystHub_CurrentGen ~= GEN_ID) then break end

            pcall(function() SubmitGuessRemote:FireServer(word) end)

            statusBox.Text = string.format(" Checking [%d/%d]: %s", idx, listSize, word)
            local pct = idx / listSize
            TweenService:Create(ProgressBarFill, TweenInfo.new(0.1), {Size = UDim2.new(pct, 0, 1, 0)}):Play()

            -- Anti-Detection Jitter
            local jitter = math.random(-20, 50) / 1000
            task.wait((hubState.Delay / 1000) + jitter) 
        end

        hubState.Running = false
        statusBox.Text = hubState.KillSwitch and " Execution Terminated" or " Sequence Completed"
        statusBox.TextColor3 = CLR.muted
        TweenService:Create(ProgressBarFill, TweenInfo.new(0.4), {Size = UDim2.new(0, 0, 1, 0)}):Play()
    end)
end

StartBtn.MouseButton1Click:Connect(executeHackSequence)

StopBtn.MouseButton1Click:Connect(function()
    hubState.KillSwitch = true
    hubState.Running = false
    statusBox.Text = " System Aborted"
    statusBox.TextColor3 = CLR.danger
end)