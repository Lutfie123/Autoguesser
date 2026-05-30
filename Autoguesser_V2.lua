--[[
    🔮 AMETHYST HUB: Hot or Cold - Guess the Word! (True Semantic Edition)
    ===================================================================
    Features: Real-Time UI Scraping, Dynamic Thematic Re-Routing, 
              Curated Master Dictionary, & Executor-Safe Fluid UI.
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LP = Players.LocalPlayer
local PlayerGui = LP:WaitForChild("PlayerGui")

local GEN_ID = math.random(100000, 999999)
_G.AmethystHub_CurrentGen = GEN_ID

local Remotes = ReplicatedStorage:WaitForChild("Remotes", 5)
local SubmitGuessRemote = Remotes and Remotes:WaitForChild("SubmitGuess", 5)

-- ─── 1. STATE & CONFIGURATION ────────────────────────────────────────────────
local hubState = {
    Running = false,
    SmartGuessing = true,
    KillSwitch = false,
    Delay = 1000,
    GuessedWords = {}, -- Tracks what we've already sent to avoid spamming
    Stats = { Success = 0, TotalChecked = 0 }
}

-- ─── 2. CURATED SEMANTIC DICTIONARY (Categorized for AI Context) ─────────────
-- Filtered for practical, highly-used nouns/verbs. Junk words removed.
local semanticCategories = {
    Nature_Outdoors = {
        "forest","jungle","tree","leaf","grass","mountain","river","ocean",
        "beach","sand","dirt","rock","stone","rain","snow","storm","wind",
        "camping","highway","road","trail","path","valley","canyon","island",
        "swamp","desert","lake","pond","bush","soil","cave","volcano","waterfall"
    },
    Animals = {
        "dog","cat","fish","bird","horse","cow","pig","duck","bear","lion",
        "tiger","shark","spider","snake","bunny","chicken","monkey","frog",
        "turtle","whale","bee","wolf","crab","mouse","elephant","giraffe","zebra",
        "dolphin","owl","penguin","fox","parrot","lizard","camel","octopus"
    },
    Food_Drink = {
        "apple","banana","orange","lemon","grape","cherry","peach","pear",
        "pizza","burger","taco","cookie","cake","candy","milk","water","juice",
        "bread","cheese","egg","donut","fries","soda","chips","hotdog","chocolate",
        "popcorn","steak","soup","carrot","corn","mango","coffee","tea","butter"
    },
    Household_Objects = {
        "desk","bed","pillow","blanket","lamp","chair","table","couch","door",
        "window","key","box","bag","clock","mirror","soap","towel","cup","plate",
        "bowl","spoon","fork","sink","carpet","shelf","oven","stove","fridge"
    },
    Technology_Science = {
        "phone","tablet","computer","tv","remote","radio","laptop","keyboard",
        "telescope","microscope","smartphone","battery","camera","robot","drone",
        "engine","satellite","rocket","planet","space","galaxy","gravity"
    },
    Places_Buildings = {
        "house","apartment","skyscraper","restaurant","hospital","university",
        "school","kitchen","bedroom","bathroom","garden","pool","park","airport",
        "gym","library","cinema","castle","bridge","tunnel","office","store",
        "bank","mall","factory","church","museum","stadium","theater"
    },
    People_Professions = {
        "mom","dad","baby","sister","brother","teacher","doctor","friend","boy",
        "girl","man","woman","king","queen","pirate","clown","student","police",
        "engineer","soldier","detective","scientist","architect","pilot","dentist",
        "waiter","farmer","chef","judge","lawyer","president","nurse"
    },
    Clothing_Accessories = {
        "shirt","pants","shoe","hat","sock","jacket","dress","shorts","boot",
        "glove","hoodie","watch","ring","belt","mask","glasses","scarf","necklace"
    },
    Concepts_Misc = {
        "time","day","night","summer","winter","spring","autumn","love",
        "hate","happy","sad","fast","slow","hot","cold","light","dark",
        "color","red","blue","green","yellow","shape","circle","square","money"
    }
}

-- ─── 3. CORE AI SCRAPING ENGINE ──────────────────────────────────────────────
-- This dynamically reads your UI to find the closest word on the leaderboard
local function scanUIForBestWord()
    local bestRank = math.huge
    local bestWord = nil

    -- Recursively search the entire PlayerGui for the leaderboard layout
    for _, element in ipairs(PlayerGui:GetDescendants()) do
        if element:IsA("TextLabel") and element.Visible then
            -- Look for rank formatting (e.g., "#6", "#123")
            local rankMatch = string.match(element.Text, "^#(%d+)$")
            if rankMatch then
                local currentRank = tonumber(rankMatch)
                if currentRank and currentRank < bestRank then
                    -- The actual word is usually in a sibling TextLabel inside the same frame
                    local parentFrame = element.Parent
                    if parentFrame then
                        for _, sibling in ipairs(parentFrame:GetChildren()) do
                            if sibling:IsA("TextLabel") and sibling ~= element and not string.match(sibling.Text, "#") then
                                bestRank = currentRank
                                bestWord = string.lower(sibling.Text)
                            end
                        end
                    end
                end
            end
        end
    end
    return bestWord, bestRank
end

local function getCategoryOfWord(targetWord)
    if not targetWord then return nil end
    for categoryName, wordsList in pairs(semanticCategories) do
        for _, word in ipairs(wordsList) do
            if word == targetWord then return categoryName end
        end
    end
    return nil
end

local function getNextSmartWord()
    local bestWordUI = nil
    
    if hubState.SmartGuessing then
        bestWordUI = scanUIForBestWord()
    end

    -- If we found a word on the screen, find its category
    local targetCategory = getCategoryOfWord(bestWordUI)

    -- 1. Try to guess an unused word from the best matching category
    if targetCategory then
        for _, word in ipairs(semanticCategories[targetCategory]) do
            if not hubState.GuessedWords[word] then return word end
        end
    end

    -- 2. Fallback: Iterate through all categories systematically
    for catName, wordsList in pairs(semanticCategories) do
        for _, word in ipairs(wordsList) do
            if not hubState.GuessedWords[word] then return word end
        end
    end

    return nil -- All dictionary words exhausted
end

-- ─── 4. MINIMALIST UI ────────────────────────────────────────────────────────
local ScreenGui = Instance.new("ScreenGui", PlayerGui)
ScreenGui.Name = "AmethystHub_Engine"
ScreenGui.ResetOnSpawn = false

local CLR = { bg = Color3.fromRGB(15,15,20), header = Color3.fromRGB(28,22,38), accent = Color3.fromRGB(155,80,255), success = Color3.fromRGB(80,220,120), danger = Color3.fromRGB(230,80,80), text = Color3.fromRGB(220,220,240) }

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 420, 0, 260)
MainFrame.Position = UDim2.new(0.5, -210, 0.5, -130)
MainFrame.BackgroundColor3 = CLR.bg
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

local Header = Instance.new("Frame", MainFrame)
Header.Size = UDim2.new(1, 0, 0, 40)
Header.BackgroundColor3 = CLR.header
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel", Header)
Title.Size = UDim2.new(1, -20, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "AMETHYST HUB | True Context AI"
Title.TextColor3 = CLR.accent
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left

local StatusLabel = Instance.new("TextLabel", MainFrame)
StatusLabel.Size = UDim2.new(1, -20, 0, 30)
StatusLabel.Position = UDim2.new(0, 10, 0, 50)
StatusLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
StatusLabel.Text = " Waiting to Start..."
StatusLabel.TextColor3 = CLR.text
StatusLabel.Font = Enum.Font.GothamSemibold
StatusLabel.TextSize = 12
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
Instance.new("UICorner", StatusLabel).CornerRadius = UDim.new(0, 4)

local SmartToggle = Instance.new("TextButton", MainFrame)
SmartToggle.Size = UDim2.new(1, -20, 0, 35)
SmartToggle.Position = UDim2.new(0, 10, 0, 90)
SmartToggle.BackgroundColor3 = CLR.accent
SmartToggle.Text = "🧠 AI Engine: Screen Scanning ON"
SmartToggle.TextColor3 = Color3.new(1,1,1)
SmartToggle.Font = Enum.Font.GothamBold
SmartToggle.TextSize = 12
Instance.new("UICorner", SmartToggle).CornerRadius = UDim.new(0, 4)

local StartBtn = Instance.new("TextButton", MainFrame)
StartBtn.Size = UDim2.new(0, 195, 0, 40)
StartBtn.Position = UDim2.new(0, 10, 0, 135)
StartBtn.BackgroundColor3 = CLR.success
StartBtn.Text = "START SEQUENCE"
StartBtn.TextColor3 = CLR.bg
StartBtn.Font = Enum.Font.GothamBold
StartBtn.TextSize = 12
Instance.new("UICorner", StartBtn).CornerRadius = UDim.new(0, 4)

local StopBtn = Instance.new("TextButton", MainFrame)
StopBtn.Size = UDim2.new(0, 195, 0, 40)
StopBtn.Position = UDim2.new(1, -205, 0, 135)
StopBtn.BackgroundColor3 = CLR.danger
StopBtn.Text = "HALT"
StopBtn.TextColor3 = CLR.text
StopBtn.Font = Enum.Font.GothamBold
StopBtn.TextSize = 12
Instance.new("UICorner", StopBtn).CornerRadius = UDim.new(0, 4)

local SliderBg = Instance.new("TextButton", MainFrame)
SliderBg.Size = UDim2.new(1, -20, 0, 8)
SliderBg.Position = UDim2.new(0, 10, 0, 200)
SliderBg.BackgroundColor3 = CLR.header
SliderBg.Text = ""
Instance.new("UICorner", SliderBg).CornerRadius = UDim.new(0, 4)

local SliderFill = Instance.new("Frame", SliderBg)
SliderFill.Size = UDim2.new(0.5, 0, 1, 0)
SliderFill.BackgroundColor3 = CLR.accent
Instance.new("UICorner", SliderFill).CornerRadius = UDim.new(0, 4)

local DelayReadout = Instance.new("TextLabel", MainFrame)
DelayReadout.Size = UDim2.new(1, -20, 0, 20)
DelayReadout.Position = UDim2.new(0, 10, 0, 215)
DelayReadout.BackgroundTransparency = 1
DelayReadout.Text = "Delay: 1000ms"
DelayReadout.TextColor3 = CLR.text
DelayReadout.Font = Enum.Font.Gotham
DelayReadout.TextSize = 11

-- ─── 5. LOGIC & CONNECTIONS ──────────────────────────────────────────────────
local draggingUI, dragStart, startPos
Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingUI = true; dragStart = input.Position; startPos = MainFrame.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if draggingUI and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then draggingUI = false end
end)

local draggingSlider = false
SliderBg.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then draggingSlider = true end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then draggingSlider = false end
end)
UserInputService.InputChanged:Connect(function(input)
    if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local relativeX = math.clamp((input.Position.X - SliderBg.AbsolutePosition.X) / SliderBg.AbsoluteSize.X, 0, 1)
        SliderFill.Size = UDim2.new(relativeX, 0, 1, 0)
        hubState.Delay = math.floor(150 + (relativeX * 1850))
        DelayReadout.Text = "Delay: " .. hubState.Delay .. "ms"
    end
end)

SmartToggle.MouseButton1Click:Connect(function()
    hubState.SmartGuessing = not hubState.SmartGuessing
    SmartToggle.BackgroundColor3 = hubState.SmartGuessing and CLR.accent or CLR.header
    SmartToggle.Text = hubState.SmartGuessing and "🧠 AI Engine: Screen Scanning ON" or "🧠 AI Engine: Sequence Mode OFF"
end)

StartBtn.MouseButton1Click:Connect(function()
    if hubState.Running then return end
    hubState.Running = true
    hubState.KillSwitch = false
    
    task.spawn(function()
        while hubState.Running and not hubState.KillSwitch and _G.AmethystHub_CurrentGen == GEN_ID do
            local nextWord = getNextSmartWord()
            
            if not nextWord then
                StatusLabel.Text = " Out of words in dictionary!"
                hubState.Running = false
                break
            end

            -- Fire Remote
            pcall(function() SubmitGuessRemote:FireServer(nextWord) end)
            hubState.GuessedWords[nextWord] = true
            hubState.Stats.TotalChecked += 1
            
            StatusLabel.Text = string.format(" [AI Fired]: %s | Scans: %d", nextWord, hubState.Stats.TotalChecked)
            
            local jitter = math.random(-20, 50) / 1000
            task.wait((hubState.Delay / 1000) + jitter)
        end
    end)
end)

StopBtn.MouseButton1Click:Connect(function()
    hubState.KillSwitch = true
    hubState.Running = false
    StatusLabel.Text = " Halted."
end)
