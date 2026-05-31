--[[
    ╔══════════════════════════════════════════════════════════════════╗
    ║     AMETHYST HUB  ·  Hot or Cold  ·  Semantic AI v4.1           ║
    ║     Premium Guessing Assistant — Leaderboard‑Aware Heat Engine   ║
    ╚══════════════════════════════════════════════════════════════════╝
--]]

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Constants
local LOCAL_PLAYER = Players.LocalPlayer
local PLAYER_GUI = LOCAL_PLAYER:WaitForChild("PlayerGui")
local REMOTE = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("SubmitGuess")

if not REMOTE then
    warn("[Amethyst] SubmitGuess remote not found – script will not work.")
end

-- ================================ THEME MANAGER ================================
local Themes = {
    Amethyst = {
        bg = Color3.fromRGB(12, 10, 20),
        panel = Color3.fromRGB(22, 18, 36),
        header = Color3.fromRGB(32, 24, 52),
        accent = Color3.fromRGB(155, 80, 255),
        accentDark = Color3.fromRGB(120, 50, 210),
        hot = Color3.fromRGB(255, 120, 40),
        success = Color3.fromRGB(72, 210, 110),
        danger = Color3.fromRGB(225, 70, 70),
        text = Color3.fromRGB(240, 235, 255),
        subtext = Color3.fromRGB(140, 130, 180),
        border = Color3.fromRGB(50, 45, 70),
    },
    Dark = {
        bg = Color3.fromRGB(18, 18, 22),
        panel = Color3.fromRGB(28, 28, 34),
        header = Color3.fromRGB(38, 38, 46),
        accent = Color3.fromRGB(0, 122, 255),
        accentDark = Color3.fromRGB(0, 90, 200),
        hot = Color3.fromRGB(255, 80, 60),
        success = Color3.fromRGB(48, 190, 100),
        danger = Color3.fromRGB(230, 60, 60),
        text = Color3.fromRGB(245, 245, 255),
        subtext = Color3.fromRGB(150, 150, 180),
        border = Color3.fromRGB(60, 60, 75),
    },
    Light = {
        bg = Color3.fromRGB(240, 240, 248),
        panel = Color3.fromRGB(250, 250, 255),
        header = Color3.fromRGB(230, 230, 245),
        accent = Color3.fromRGB(64, 128, 255),
        accentDark = Color3.fromRGB(40, 100, 220),
        hot = Color3.fromRGB(230, 80, 40),
        success = Color3.fromRGB(40, 180, 80),
        danger = Color3.fromRGB(210, 50, 50),
        text = Color3.fromRGB(30, 30, 40),
        subtext = Color3.fromRGB(100, 100, 120),
        border = Color3.fromRGB(200, 200, 215),
    },
    Neon = {
        bg = Color3.fromRGB(8, 8, 18),
        panel = Color3.fromRGB(18, 18, 32),
        header = Color3.fromRGB(28, 28, 48),
        accent = Color3.fromRGB(0, 255, 200),
        accentDark = Color3.fromRGB(0, 200, 150),
        hot = Color3.fromRGB(255, 80, 120),
        success = Color3.fromRGB(80, 255, 100),
        danger = Color3.fromRGB(255, 60, 90),
        text = Color3.fromRGB(210, 255, 250),
        subtext = Color3.fromRGB(120, 200, 190),
        border = Color3.fromRGB(0, 180, 160),
    },
}
local ActiveTheme = "Amethyst"

-- ================================ CORE STATE ================================
local Engine = {
    running = false,
    smartMode = true,
    kill = false,
    thread = nil,
    delay = 1000,
    guessed = {},
    totalFired = 0,
    topWord = {word = "—", rank = 0, mult = 1},
    targetCluster = "—",
    heatScore = 0,
}
local clusterHeat = {}
local HEAT_DECAY = 0.8

-- ================================ WORD DATABASE ================================
local CLUSTERS = {
    -- ── NATURE: Forest/Vegetation ─────────────────────────────────
    Forest_Core    = {"forest","woods","jungle","grove","rainforest","canopy","wilderness"},
    Trees_Plants   = {"tree","bush","shrub","fern","vine","bamboo","palm","sapling","hedge"},
    Tree_Parts     = {"leaf","branch","trunk","bark","root","twig","bud","petal","thorn","stem","acorn","pine"},
    Ground_Cover   = {"grass","lawn","meadow","field","pasture","prairie","clover","moss","soil","dirt"},
    -- ── NATURE: Terrain ──────────────────────────────────────────
    Mountains      = {"mountain","hill","valley","canyon","cliff","peak","ridge","summit","slope","gorge"},
    Caves_Underground = {"cave","cavern","grotto","burrow","pit","mine","tunnel"},
    Volcano_Fire   = {"volcano","lava","crater","magma","ash","geyser"},
    -- ── NATURE: Water Bodies ─────────────────────────────────────
    Water_Bodies   = {"ocean","sea","lake","river","stream","pond","creek","pool","bay","fjord","reservoir","lagoon"},
    Coastline      = {"beach","shore","coast","island","reef","sandbar","cove","harbor","pier","cliff"},
    Water_Events   = {"waterfall","rapids","current","tide","wave","surf","ripple","flood","delta"},
    Rain_Weather   = {"rain","drizzle","puddle","droplet","dew","mist","fog","steam","humidity"},
    Snow_Ice       = {"snow","ice","frost","glacier","iceberg","avalanche","blizzard","hail","sleet"},
    Storm_Wind     = {"storm","thunder","lightning","tornado","hurricane","cyclone","typhoon","breeze","gust","wind"},
    -- ── NATURE: Sky / Space ───────────────────────────────────────
    Sky_Atmos      = {"sky","cloud","sun","moon","star","rainbow","aurora","sunset","sunrise","horizon"},
    Space          = {"planet","galaxy","space","universe","asteroid","nebula","comet","meteor","orbit","cosmos"},
    Spacecraft     = {"rocket","spaceship","shuttle","telescope","satellite","astronaut"},
    -- ── TRAVEL / ROADS ────────────────────────────────────────────
    Roads          = {"road","highway","street","avenue","lane","alley","boulevard","freeway","motorway"},
    Paths          = {"path","trail","track","route","sidewalk","crosswalk","shortcut"},
    Bridges        = {"bridge","overpass","ramp","roundabout","intersection","junction","tunnel"},
    Camping        = {"camping","hiking","trekking","backpacking","expedition","adventure","outdoor"},
    Camp_Gear      = {"tent","campfire","bonfire","hammock","lantern","compass","canteen"},
    -- ── ANIMALS: Domestic ────────────────────────────────────────
    Dogs           = {"dog","puppy","hound","poodle","bulldog","beagle","labrador","husky"},
    Cats           = {"cat","kitten","tabby","siamese","persian","calico"},
    Small_Pets     = {"rabbit","bunny","hamster","guinea pig","gerbil","mouse","rat"},
    Pet_Birds      = {"parrot","canary","budgie","cockatoo","dove","pigeon"},
    Pet_Fish       = {"goldfish","koi","guppy","betta","clownfish","angelfish"},
    -- ── ANIMALS: Large Wild ───────────────────────────────────────
    Big_Cats       = {"lion","tiger","leopard","cheetah","jaguar","panther","cougar","lynx"},
    Bears_Wolves   = {"bear","wolf","fox","coyote","grizzly","polar bear","panda","jackal"},
    Mega_Animals   = {"elephant","rhino","hippo","mammoth","walrus"},
    Savanna        = {"giraffe","zebra","wildebeest","gazelle","antelope","buffalo","bison"},
    Primates       = {"gorilla","monkey","ape","chimp","baboon","orangutan","lemur","macaque"},
    Marsupials     = {"kangaroo","koala","wombat","platypus","wallaby","opossum"},
    Deer_Family    = {"deer","moose","elk","reindeer","caribou"},
    -- ── ANIMALS: Reptile / Amphibian ─────────────────────────────
    Snakes         = {"snake","python","cobra","viper","anaconda","boa","mamba"},
    Lizards        = {"lizard","gecko","iguana","chameleon","komodo","skink"},
    Crocodilians   = {"crocodile","alligator","caiman"},
    Turtles        = {"turtle","tortoise","terrapin"},
    Frogs          = {"frog","toad","salamander","newt","axolotl"},
    -- ── ANIMALS: Ocean ───────────────────────────────────────────
    Sharks_Whales  = {"shark","whale","dolphin","orca","narwhal","beluga","manatee"},
    Invertebrates  = {"octopus","squid","jellyfish","starfish","seahorse","crab","lobster","shrimp","clam","oyster"},
    Seals          = {"seal","walrus","sea lion","otter"},
    -- ── ANIMALS: Birds ───────────────────────────────────────────
    Birds_Prey     = {"eagle","hawk","falcon","vulture","kite","osprey","owl"},
    Tropical_Birds = {"penguin","flamingo","pelican","toucan","macaw","cockatoo"},
    Common_Birds   = {"crow","raven","sparrow","robin","hummingbird","woodpecker","swallow","finch"},
    Water_Birds    = {"duck","goose","swan","heron","stork","crane"},
    Farm_Birds     = {"chicken","turkey","rooster","hen","peacock","pheasant","quail"},
    -- ── ANIMALS: Insects ─────────────────────────────────────────
    Bees_Ants      = {"bee","wasp","ant","termite","hornet","bumblebee"},
    Butterflies    = {"butterfly","moth","dragonfly","firefly","grasshopper","cricket","beetle"},
    Spiders        = {"spider","scorpion","centipede","tick","flea","mosquito","fly"},
    -- ── FOOD: Fruit ──────────────────────────────────────────────
    Stone_Fruit    = {"apple","pear","peach","plum","cherry","apricot","fig","date","nectarine"},
    Tropical_Fruit = {"banana","mango","papaya","pineapple","coconut","guava","lychee"},
    Berries        = {"grape","strawberry","blueberry","raspberry","blackberry","cranberry","currant","gooseberry"},
    Citrus         = {"orange","lemon","lime","grapefruit","tangerine","clementine","yuzu"},
    Melons         = {"watermelon","cantaloupe","melon","honeydew"},
    -- ── FOOD: Vegetables ─────────────────────────────────────────
    Root_Veg       = {"carrot","potato","onion","garlic","radish","beetroot","turnip","parsnip","yam"},
    Leafy_Veg      = {"lettuce","spinach","kale","cabbage","broccoli","cauliflower","celery","asparagus"},
    Other_Veg      = {"tomato","pepper","cucumber","zucchini","corn","pea","bean","eggplant","mushroom","pumpkin"},
    -- ── FOOD: Grains / Bread ─────────────────────────────────────
    Bread_Dough    = {"bread","toast","bagel","croissant","muffin","waffle","pancake","biscuit","roll","pita","naan"},
    Pasta_Rice     = {"rice","pasta","noodle","spaghetti","macaroni","ramen","udon","soba","couscous","dumpling"},
    Cereals        = {"cereal","oat","wheat","granola","porridge","cracker","pretzel"},
    -- ── FOOD: Meat / Protein ─────────────────────────────────────
    Red_Meat       = {"steak","beef","pork","lamb","veal","venison","bison"},
    Poultry        = {"chicken","turkey","duck","goose"},
    Seafood        = {"salmon","tuna","cod","trout","sardine","anchovy","swordfish","halibut"},
    Processed_Meat = {"bacon","sausage","ham","salami","pepperoni","jerky","hotdog"},
    Protein_Other  = {"egg","tofu","tempeh","lentil","chickpea","bean"},
    -- ── FOOD: Dishes ─────────────────────────────────────────────
    Sandwiches     = {"pizza","burger","hotdog","sandwich","taco","burrito","wrap","sub","kebab","gyro"},
    Soups_Stews    = {"soup","stew","curry","chili","broth","bisque","gumbo","ramen","pho"},
    Asian_Dishes   = {"sushi","sashimi","dumpling","spring roll","fried rice","pad thai"},
    Snacks         = {"fries","chips","popcorn","nachos","pretzel","onion ring"},
    -- ── FOOD: Dairy / Condiments ─────────────────────────────────
    Dairy          = {"cheese","butter","cream","yogurt","milk","ice cream","custard","ghee"},
    Condiments     = {"ketchup","mustard","mayo","sauce","dressing","syrup","honey","jam","jelly","pickle"},
    -- ── FOOD: Sweets ─────────────────────────────────────────────
    Baked_Sweets   = {"cake","cupcake","cookie","brownie","donut","tart","pie","pastry","macaron"},
    Candy          = {"candy","chocolate","lollipop","gummy","caramel","fudge","marshmallow","taffy","toffee"},
    Desserts       = {"pudding","mousse","cheesecake","tiramisu","sorbet"},
    -- ── DRINKS ───────────────────────────────────────────────────
    Soft_Drinks    = {"water","juice","soda","lemonade","smoothie","milkshake","tea","coffee","cocoa"},
    Hot_Drinks     = {"espresso","latte","cappuccino","chai","matcha","cider","broth"},
    Alcohol        = {"beer","wine","champagne","whiskey","vodka","rum","cocktail","gin","sake"},
    -- ── HOUSEHOLD: Furniture ─────────────────────────────────────
    Beds           = {"bed","mattress","pillow","blanket","sheet","quilt","duvet","cot"},
    Seating        = {"chair","couch","sofa","bench","stool","ottoman","recliner","throne","hammock"},
    Tables_Storage = {"desk","table","shelf","cabinet","drawer","wardrobe","closet","dresser","nightstand"},
    Lighting       = {"lamp","chandelier","lantern","candle","torch","bulb","spotlight","neon"},
    -- ── HOUSEHOLD: Structure ─────────────────────────────────────
    Doors_Windows  = {"door","window","gate","hatch","shutter","curtain","blind"},
    Surfaces       = {"wall","floor","ceiling","roof","stairs","ramp","elevator","balcony"},
    Rooms          = {"hallway","corridor","porch","patio","garage","basement","attic","cellar"},
    -- ── HOUSEHOLD: Bathroom ──────────────────────────────────────
    Hygiene        = {"soap","towel","toothbrush","toothpaste","brush","comb","razor","shampoo","conditioner","lotion"},
    Bath_Fixtures  = {"sink","toilet","bathtub","shower","mirror","faucet","drain","scale"},
    -- ── HOUSEHOLD: Kitchen ───────────────────────────────────────
    Drinkware      = {"cup","mug","glass","bottle","jug","pitcher","flask","thermos","canteen"},
    Dishware       = {"bowl","plate","dish","tray","platter","pot","pan","wok","colander"},
    Cutlery        = {"spoon","fork","knife","chopstick","spatula","ladle","whisk","tong","peeler"},
    Appliances     = {"oven","stove","microwave","fridge","freezer","dishwasher","blender","toaster","kettle","mixer"},
    Decor          = {"carpet","rug","vase","frame","poster","painting","sculpture","clock","calendar","aquarium"},
    -- ── TECHNOLOGY: Devices ──────────────────────────────────────
    Computers      = {"phone","smartphone","tablet","laptop","computer","desktop","monitor","screen","keyboard","mouse"},
    Peripherals    = {"charger","cable","adapter","headphone","earphone","speaker","microphone","webcam","printer"},
    Camera_Gear    = {"camera","camcorder","tripod","lens","drone","projector"},
    Entertainment  = {"tv","remote","radio","stereo","console","controller","joystick","gamepad","headset"},
    Tech_Hardware  = {"battery","engine","motor","circuit","chip","processor","router","modem"},
    -- ── BUILDINGS / PLACES ───────────────────────────────────────
    Homes          = {"house","home","apartment","cabin","cottage","mansion","villa","hut","bungalow","condo"},
    Education      = {"school","university","college","classroom","library","gymnasium","laboratory","cafeteria"},
    Medical        = {"hospital","clinic","pharmacy","ambulance","emergency room"},
    Dining         = {"restaurant","cafe","diner","bakery","bar","pub","buffet","bistro"},
    Shopping       = {"mall","store","shop","supermarket","market","boutique","kiosk","stall"},
    Government     = {"bank","post office","police station","fire station","courthouse","city hall","embassy"},
    Religious      = {"church","temple","mosque","cathedral","synagogue","shrine","chapel","monastery"},
    Historic       = {"castle","palace","fortress","dungeon","tower","pyramid","monument","statue","ruins"},
    Parks_Nature   = {"park","garden","playground","zoo","aquarium","botanical garden","nature reserve","beach"},
    Culture        = {"museum","gallery","theater","cinema","concert hall","auditorium","stadium"},
    Transport_Hubs = {"airport","train station","bus station","port","dock","harbor","terminal","runway"},
    Industry       = {"factory","warehouse","workshop","office","skyscraper","headquarters"},
    Fitness        = {"gym","pool","spa","sauna","arena","racetrack","field","court"},
    Lodging        = {"hotel","motel","hostel","resort","inn","lodge","dormitory"},
    -- ── PEOPLE: Family ───────────────────────────────────────────
    Family_Core    = {"mom","mother","dad","father","parent","grandma","grandpa","baby","toddler","child","teen"},
    Family_Extended= {"sister","brother","cousin","aunt","uncle","niece","nephew","twin","sibling"},
    Social         = {"friend","buddy","partner","colleague","teammate","neighbor","stranger","mentor","rival"},
    -- ── PEOPLE: Professions ──────────────────────────────────────
    Educators      = {"teacher","professor","principal","tutor","student","pupil"},
    Medical_Roles  = {"doctor","surgeon","nurse","dentist","pharmacist","vet","paramedic","therapist"},
    Law_Military   = {"police","officer","detective","soldier","guard","marine","pilot","firefighter"},
    Food_Service   = {"chef","cook","waiter","baker","barista","bartender","butcher","farmer"},
    Tech_Jobs      = {"engineer","architect","programmer","developer","designer","scientist","analyst"},
    Legal_Finance  = {"lawyer","judge","accountant","banker","auditor","economist"},
    Politics       = {"president","politician","senator","mayor","ambassador","governor","king","queen"},
    Creative       = {"actor","singer","musician","dancer","comedian","writer","poet","artist","director"},
    Trades         = {"fisherman","miner","carpenter","plumber","electrician","mechanic","painter"},
    Fantasy_Roles  = {"pirate","knight","wizard","witch","ninja","samurai","viking","gladiator","warrior"},
    -- ── CLOTHING ─────────────────────────────────────────────────
    Tops           = {"shirt","blouse","tee","sweater","hoodie","jacket","coat","vest","cardigan","poncho","robe"},
    Formal_Wear    = {"dress","gown","uniform","suit","tuxedo","blazer"},
    Bottoms        = {"pants","jeans","shorts","skirt","leggings","trousers","chinos","sweatpants"},
    Footwear       = {"shoe","boot","sneaker","sandal","slipper","heel","loafer","moccasin","clog"},
    Hats           = {"hat","cap","beanie","beret","helmet","crown","tiara","hood","turban"},
    Small_Clothing = {"sock","glove","scarf","belt","tie","suspenders","apron","bandana"},
    Jewelry        = {"ring","necklace","bracelet","earring","watch","glasses","sunglasses","pendant","brooch"},
    Bags           = {"bag","purse","handbag","backpack","briefcase","wallet","tote","suitcase","pouch"},
    -- ── SPORTS / ACTIVITIES ──────────────────────────────────────
    Ball_Sports    = {"football","soccer","basketball","baseball","tennis","golf","rugby","volleyball","cricket","hockey"},
    Action_Sports  = {"swimming","running","cycling","skateboarding","snowboarding","skiing","surfing","climbing","parkour"},
    Combat_Sports  = {"boxing","wrestling","karate","judo","taekwondo","fencing","kickboxing"},
    Perform_Sports = {"dancing","yoga","gymnastics","cheerleading","ballet","acrobatics"},
    Leisure        = {"fishing","hunting","archery","bowling","billiards","darts","ping pong","chess","cards"},
    Sports_Gear    = {"ball","bat","racket","club","stick","glove","helmet","net","goal","hoop"},
    -- ── CONCEPTS: Colors / Shapes ────────────────────────────────
    Colors         = {"red","blue","green","yellow","purple","orange","pink","brown","black","white","gray","silver","gold","cyan","magenta"},
    Shapes         = {"circle","square","triangle","rectangle","diamond","oval","star","heart","pentagon","hexagon","cube","sphere","cone","cylinder"},
    -- ── CONCEPTS: Time ───────────────────────────────────────────
    Time_Day       = {"morning","noon","afternoon","evening","night","midnight","dawn","dusk","twilight"},
    Time_Large     = {"day","week","month","year","decade","century","millennium","season"},
    Calendar       = {"summer","winter","spring","autumn","weekend","holiday","birthday","anniversary","festival"},
    -- ── CONCEPTS: Abstract / Emotions ────────────────────────────
    Emotions       = {"love","hate","joy","sadness","fear","anger","surprise","jealousy","pride","shame"},
    Adjectives_Mood= {"happy","sad","excited","bored","tired","nervous","calm","confused","curious","lonely"},
    Virtues        = {"dream","wish","hope","faith","trust","courage","wisdom","justice","freedom","peace"},
    Temp_Size      = {"hot","cold","warm","cool","freezing","boiling","big","small","tall","short","fast","slow"},
    -- ── MONEY / VALUE ────────────────────────────────────────────
    Money          = {"money","cash","coin","gold","silver","diamond","gem","jewel","treasure","reward"},
    Finance        = {"bank","wallet","safe","budget","salary","profit","debt","investment","stock","tax"},
    -- ── FANTASY / MAGIC ──────────────────────────────────────────
    Magic_Items    = {"magic","spell","curse","potion","wand","staff","orb","amulet","scroll","rune","crystal"},
    Fantasy_Beings = {"dragon","phoenix","unicorn","mermaid","fairy","elf","dwarf","orc","troll","goblin","demon","angel","ghost"},
    Weapons        = {"sword","shield","armor","bow","arrow","axe","spear","dagger","lance","mace","crossbow","gun"},
    -- ── MUSIC ────────────────────────────────────────────────────
    Instruments    = {"guitar","piano","drum","violin","trumpet","flute","saxophone","harp","bass","ukulele","cello"},
    Music_Concepts = {"music","song","melody","rhythm","beat","chord","note","lyric","concert","band","album","record"},
    -- ── ART / STATIONERY ─────────────────────────────────────────
    Drawing        = {"pencil","pen","marker","brush","crayon","chalk","eraser","ruler","scissors","tape","glue"},
    Paper_Media    = {"paper","notebook","book","magazine","newspaper","card","envelope","stamp","diary","comic"},
    Painting       = {"paint","ink","canvas","palette","easel","sketchbook","watercolor","mural"},
    -- ── VEHICLES ─────────────────────────────────────────────────
    Land_Vehicles  = {"car","truck","bus","van","motorcycle","bicycle","scooter","tractor","ambulance","taxi"},
    Rail_Vehicles  = {"train","subway","tram","monorail","cable car","freight"},
    Air_Vehicles   = {"plane","helicopter","jet","glider","balloon","blimp","drone"},
    Water_Vehicles = {"boat","ship","yacht","submarine","canoe","kayak","ferry","sailboat","raft"},
}

-- Build lookup tables
local wordToCluster = {}
local allWords = {}
local wordSet = {}
local wordSeen = {}
for cluster, words in pairs(CLUSTERS) do
    for _, w in ipairs(words) do
        if not wordSeen[w] then
            wordSeen[w] = true
            wordToCluster[w] = cluster
            wordSet[w] = true
            table.insert(allWords, w)
        end
    end
end

-- Warmup list (priority + rest)
local warmupPriority = {
    "pizza","burger","cake","bread","pasta","rice","soup","taco","sushi","sandwich",
    "cookie","chocolate","candy","cheese","egg","bacon","steak","waffle","pancake","donut",
    "apple","banana","orange","grape","strawberry","watermelon","mango","lemon","peach","cherry",
    "carrot","potato","tomato","onion","corn","pepper","mushroom","broccoli","cucumber","lettuce",
    "chicken","fish","salmon","shrimp","lobster","crab",
    "coffee","tea","juice","milk","water","soda","lemonade",
    "ice cream","cupcake","brownie","muffin","pie","tart",
    "cat","dog","lion","tiger","elephant","bear","wolf","shark","whale","dolphin",
    "monkey","gorilla","giraffe","zebra","horse","cow","pig","sheep","rabbit","deer",
    "eagle","owl","parrot","penguin","flamingo","duck","turkey",
    "snake","crocodile","frog","turtle","dragon","unicorn","phoenix",
    "bee","butterfly","spider","ant","mosquito","dragonfly",
    "tree","flower","grass","mountain","ocean","river","forest","beach","island","cave",
    "house","car","bike","boat","plane","train","rocket","submarine",
}
local warmupList = {}
local warmupSeen = {}
for _, w in ipairs(warmupPriority) do
    if wordSet[w] and not warmupSeen[w] then
        warmupSeen[w] = true
        table.insert(warmupList, w)
    end
end
for _, w in ipairs(allWords) do
    if not warmupSeen[w] then
        warmupSeen[w] = true
        table.insert(warmupList, w)
    end
end

-- ================================ HELPER FUNCTIONS ================================
local function extractWordAndMult(text)
    if not text or text == "" then return nil, 1 end
    local t = text:lower():gsub("%s+", " "):match("^%s*(.-)%s*$")
    local word, mult = t:match("^([%a%s]-)%s+x(%d+)$")
    if word then
        return word:gsub("%s+$", ""):gsub("^%s+", ""), tonumber(mult)
    end
    if t:match("^[%a%s]+$") then
        return t, 1
    end
    return nil, 1
end

local function scanLeaderboard()
    local results, seen = {}, {}
    for _, obj in ipairs(PLAYER_GUI:GetDescendants()) do
        if obj:IsA("TextLabel") and obj.Visible then
            local rank = tonumber((obj.Text or ""):match("#(%d+)"))
            if rank then
                local parent = obj.Parent
                if parent then
                    local function checkLabel(label)
                        local word, mult = extractWordAndMult(label.Text)
                        if word and not seen[word] and wordToCluster[word] then
                            seen[word] = true
                            table.insert(results, {word = word, rank = rank, mult = mult or 1})
                        end
                    end
                    for _, sib in ipairs(parent:GetChildren()) do
                        if sib:IsA("TextLabel") and sib ~= obj then checkLabel(sib) end
                    end
                    if parent.Parent then
                        for _, uncle in ipairs(parent.Parent:GetChildren()) do
                            if uncle ~= parent then
                                for _, cousin in ipairs(uncle:GetChildren()) do
                                    if cousin:IsA("TextLabel") then checkLabel(cousin) end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    table.sort(results, function(a,b) return a.rank < b.rank end)
    return results
end

local function updateHeat(leaderboard)
    for k in pairs(clusterHeat) do
        clusterHeat[k] = clusterHeat[k] * HEAT_DECAY
        if clusterHeat[k] < 0.01 then clusterHeat[k] = nil end
    end
    for _, entry in ipairs(leaderboard) do
        local c = wordToCluster[entry.word]
        if c then
            local multBonus = 1 + 0.6 * (entry.mult - 1)
            local heat = (1000000 / math.max(1, entry.rank)) * multBonus
            clusterHeat[c] = (clusterHeat[c] or 0) + heat
        end
    end
end

local function scoreWord(word)
    local c = wordToCluster[word]
    return c and (clusterHeat[c] or 0) or 0
end

local function pickNext()
    if not Engine.smartMode then
        for _, w in ipairs(warmupList) do
            if not Engine.guessed[w] then return w, "Sequential", 0 end
        end
        return nil, "Exhausted", 0
    end
    local lb = scanLeaderboard()
    if #lb == 0 then
        for _, w in ipairs(warmupList) do
            if not Engine.guessed[w] then return w, "Warmup", 0 end
        end
        return nil, "Exhausted", 0
    end
    updateHeat(lb)
    Engine.topWord = {word = lb[1].word, rank = lb[1].rank, mult = lb[1].mult}
    local bestWord, bestScore, bestCluster = nil, -1, "?"
    for _, w in ipairs(warmupList) do
        if not Engine.guessed[w] then
            local s = scoreWord(w)
            if s > bestScore then
                bestScore = s
                bestWord = w
                bestCluster = wordToCluster[w] or "?"
            end
        end
    end
    if not bestWord or bestScore < 1 then
        for _, w in ipairs(warmupList) do
            if not Engine.guessed[w] then return w, "Fallback", 0 end
        end
        return nil, "Exhausted", 0
    end
    Engine.targetCluster = bestCluster
    Engine.heatScore = bestScore
    return bestWord, "Smart", bestScore
end

-- ================================ UI CONSTRUCTION ================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AmethystHub_v4"
ScreenGui.Parent = PLAYER_GUI
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 99

local Window = Instance.new("Frame")
Window.Name = "MainWindow"
Window.Size = UDim2.new(0, 480, 0, 380)
Window.Position = UDim2.new(0.5, -240, 0.5, -190)
Window.BackgroundColor3 = Themes.Amethyst.bg
Window.BorderSizePixel = 0
Window.ClipsDescendants = true
Window.Parent = ScreenGui
local winCorner = Instance.new("UICorner", Window)
winCorner.CornerRadius = UDim.new(0, 12)
local WindowGradient = Instance.new("UIGradient", Window)
WindowGradient.Rotation = 135
WindowGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Themes.Amethyst.header),
    ColorSequenceKeypoint.new(1, Themes.Amethyst.bg),
})

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 48)
Header.BackgroundColor3 = Themes.Amethyst.header
Header.BorderSizePixel = 0
Header.Parent = Window
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 12)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -100, 1, 0)
Title.Position = UDim2.new(0, 16, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "✧ AMETHYST HUB  |  Hot or Cold v4"
Title.TextColor3 = Themes.Amethyst.accent
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header
Title:SetAttribute("TextType", "accent")

local CollapseBtn = Instance.new("TextButton")
CollapseBtn.Size = UDim2.new(0, 80, 0, 30)
CollapseBtn.Position = UDim2.new(1, -90, 0.5, -15)
CollapseBtn.BackgroundColor3 = Themes.Amethyst.accent
CollapseBtn.Text = "▼ HIDE"
CollapseBtn.TextColor3 = Color3.new(1,1,1)
CollapseBtn.Font = Enum.Font.GothamBold
CollapseBtn.TextSize = 12
CollapseBtn.Parent = Header
Instance.new("UICorner", CollapseBtn).CornerRadius = UDim.new(0, 6)

local Content = Instance.new("Frame")
Content.Name = "Content"
Content.Size = UDim2.new(1, 0, 1, -48)
Content.Position = UDim2.new(0, 0, 0, 48)
Content.BackgroundTransparency = 1
Content.Parent = Window

-- Stats panel
local StatsPanel = Instance.new("Frame")
StatsPanel.Size = UDim2.new(1, -20, 0, 90)
StatsPanel.Position = UDim2.new(0, 10, 0, 10)
StatsPanel.BackgroundColor3 = Themes.Amethyst.panel
StatsPanel.BorderSizePixel = 0
StatsPanel.Parent = Content
StatsPanel:SetAttribute("Themed", true)
StatsPanel:SetAttribute("PanelType", "panel")
Instance.new("UICorner", StatsPanel).CornerRadius = UDim.new(0, 10)

local TopWordLbl = Instance.new("TextLabel")
TopWordLbl.Size = UDim2.new(1, -20, 0, 24)
TopWordLbl.Position = UDim2.new(0, 10, 0, 8)
TopWordLbl.BackgroundTransparency = 1
TopWordLbl.Text = "🏆 Top guess: — (rank —)"
TopWordLbl.TextColor3 = Themes.Amethyst.hot
TopWordLbl.Font = Enum.Font.GothamSemibold
TopWordLbl.TextSize = 13
TopWordLbl.TextXAlignment = Enum.TextXAlignment.Left
TopWordLbl.Parent = StatsPanel
TopWordLbl:SetAttribute("TextType", "primary")

local ClusterLbl = Instance.new("TextLabel")
ClusterLbl.Size = UDim2.new(1, -20, 0, 24)
ClusterLbl.Position = UDim2.new(0, 10, 0, 34)
ClusterLbl.BackgroundTransparency = 1
ClusterLbl.Text = "🎯 Targeting: —"
ClusterLbl.TextColor3 = Themes.Amethyst.accent
ClusterLbl.Font = Enum.Font.GothamSemibold
ClusterLbl.TextSize = 13
ClusterLbl.TextXAlignment = Enum.TextXAlignment.Left
ClusterLbl.Parent = StatsPanel
ClusterLbl:SetAttribute("TextType", "primary")

local HeatLbl = Instance.new("TextLabel")
HeatLbl.Size = UDim2.new(1, -20, 0, 24)
HeatLbl.Position = UDim2.new(0, 10, 0, 60)
HeatLbl.BackgroundTransparency = 1
HeatLbl.Text = "🔥 Heat: 0  |  Mode: Idle"
HeatLbl.TextColor3 = Themes.Amethyst.subtext
HeatLbl.Font = Enum.Font.Gotham
HeatLbl.TextSize = 12
HeatLbl.TextXAlignment = Enum.TextXAlignment.Left
HeatLbl.Parent = StatsPanel
HeatLbl:SetAttribute("TextType", "sub")

-- Status bar
local StatusBar = Instance.new("Frame")
StatusBar.Size = UDim2.new(1, -20, 0, 36)
StatusBar.Position = UDim2.new(0, 10, 0, 108)
StatusBar.BackgroundColor3 = Themes.Amethyst.panel
StatusBar.BorderSizePixel = 0
StatusBar.Parent = Content
StatusBar:SetAttribute("Themed", true)
StatusBar:SetAttribute("PanelType", "panel")
Instance.new("UICorner", StatusBar).CornerRadius = UDim.new(0, 8)
local StatusText = Instance.new("TextLabel")
StatusText.Size = UDim2.new(1, -20, 1, 0)
StatusText.Position = UDim2.new(0, 10, 0, 0)
StatusText.BackgroundTransparency = 1
StatusText.Text = "⏳ Ready"
StatusText.TextColor3 = Themes.Amethyst.text
StatusText.Font = Enum.Font.GothamSemibold
StatusText.TextSize = 13
StatusText.TextXAlignment = Enum.TextXAlignment.Left
StatusText.Parent = StatusBar
StatusText:SetAttribute("TextType", "primary")

-- Control buttons
local SmartToggle = Instance.new("TextButton")
SmartToggle.Size = UDim2.new(1, -20, 0, 38)
SmartToggle.Position = UDim2.new(0, 10, 0, 154)
SmartToggle.BackgroundColor3 = Themes.Amethyst.accent
SmartToggle.Text = "🧠 AI: HEAT MODE ON"
SmartToggle.TextColor3 = Color3.new(1,1,1)
SmartToggle.Font = Enum.Font.GothamBold
SmartToggle.TextSize = 13
SmartToggle.Parent = Content
Instance.new("UICorner", SmartToggle).CornerRadius = UDim.new(0, 8)
SmartToggle:SetAttribute("Themed", true)
SmartToggle:SetAttribute("PanelType", "accent")

local StartBtn = Instance.new("TextButton")
StartBtn.Size = UDim2.new(0.48, -10, 0, 42)
StartBtn.Position = UDim2.new(0, 10, 0, 202)
StartBtn.BackgroundColor3 = Themes.Amethyst.success
StartBtn.Text = "▶ START"
StartBtn.TextColor3 = Color3.new(0,0,0)
StartBtn.Font = Enum.Font.GothamBold
StartBtn.TextSize = 14
StartBtn.Parent = Content
Instance.new("UICorner", StartBtn).CornerRadius = UDim.new(0, 8)
StartBtn:SetAttribute("Themed", true)
StartBtn:SetAttribute("PanelType", "success")

local StopBtn = Instance.new("TextButton")
StopBtn.Size = UDim2.new(0.48, -10, 0, 42)
StopBtn.Position = UDim2.new(0.52, 0, 0, 202)
StopBtn.BackgroundColor3 = Themes.Amethyst.danger
StopBtn.Text = "■ STOP"
StopBtn.TextColor3 = Color3.new(1,1,1)
StopBtn.Font = Enum.Font.GothamBold
StopBtn.TextSize = 14
StopBtn.Parent = Content
Instance.new("UICorner", StopBtn).CornerRadius = UDim.new(0, 8)
StopBtn:SetAttribute("Themed", true)
StopBtn:SetAttribute("PanelType", "danger")

-- Delay slider
local DelayLabel = Instance.new("TextLabel")
DelayLabel.Size = UDim2.new(0.5, -20, 0, 20)
DelayLabel.Position = UDim2.new(0, 10, 0, 254)
DelayLabel.BackgroundTransparency = 1
DelayLabel.Text = "⏱ Delay: 1000 ms"
DelayLabel.TextColor3 = Themes.Amethyst.subtext
DelayLabel.Font = Enum.Font.Gotham
DelayLabel.TextSize = 12
DelayLabel.TextXAlignment = Enum.TextXAlignment.Left
DelayLabel.Parent = Content
DelayLabel:SetAttribute("TextType", "sub")

local TotalLabel = Instance.new("TextLabel")
TotalLabel.Size = UDim2.new(0.5, -10, 0, 20)
TotalLabel.Position = UDim2.new(0.5, 0, 0, 254)
TotalLabel.BackgroundTransparency = 1
TotalLabel.Text = "Fired: 0 words"
TotalLabel.TextColor3 = Themes.Amethyst.subtext
TotalLabel.Font = Enum.Font.Gotham
TotalLabel.TextSize = 12
TotalLabel.TextXAlignment = Enum.TextXAlignment.Right
TotalLabel.Parent = Content
TotalLabel:SetAttribute("TextType", "sub")

local SliderTrack = Instance.new("Frame")
SliderTrack.Size = UDim2.new(1, -20, 0, 6)
SliderTrack.Position = UDim2.new(0, 10, 0, 278)
SliderTrack.BackgroundColor3 = Themes.Amethyst.border
SliderTrack.BorderSizePixel = 0
SliderTrack.Parent = Content
Instance.new("UICorner", SliderTrack).CornerRadius = UDim.new(0, 3)
local SliderFill = Instance.new("Frame")
SliderFill.Size = UDim2.new(0.46, 0, 1, 0)
SliderFill.BackgroundColor3 = Themes.Amethyst.accent
SliderFill.BorderSizePixel = 0
SliderFill.Parent = SliderTrack
Instance.new("UICorner", SliderFill).CornerRadius = UDim.new(0, 3)
local SliderThumb = Instance.new("Frame")
SliderThumb.Size = UDim2.new(0, 14, 0, 14)
SliderThumb.Position = UDim2.new(0.46, -7, 0.5, -7)
SliderThumb.BackgroundColor3 = Color3.new(1,1,1)
SliderThumb.BorderSizePixel = 0
SliderThumb.Parent = SliderTrack
Instance.new("UICorner", SliderThumb).CornerRadius = UDim.new(0, 7)

-- Theme selector
local ThemeBtn = Instance.new("TextButton")
ThemeBtn.Size = UDim2.new(0, 36, 0, 36)
ThemeBtn.Position = UDim2.new(1, -46, 0, 8)
ThemeBtn.BackgroundColor3 = Themes.Amethyst.panel
ThemeBtn.Text = "🎨"
ThemeBtn.TextColor3 = Themes.Amethyst.accent
ThemeBtn.Font = Enum.Font.GothamBold
ThemeBtn.TextSize = 20
ThemeBtn.Parent = Content
Instance.new("UICorner", ThemeBtn).CornerRadius = UDim.new(0, 8)
ThemeBtn:SetAttribute("Themed", true)
ThemeBtn:SetAttribute("PanelType", "panel")

local ThemeDropdown = Instance.new("Frame")
ThemeDropdown.Size = UDim2.new(0, 140, 0, 120)
ThemeDropdown.Position = UDim2.new(1, -156, 0, 48)
ThemeDropdown.BackgroundColor3 = Themes.Amethyst.panel
ThemeDropdown.BorderSizePixel = 0
ThemeDropdown.Visible = false
ThemeDropdown.Parent = Content
Instance.new("UICorner", ThemeDropdown).CornerRadius = UDim.new(0, 8)
local themeNames = {"Amethyst", "Dark", "Light", "Neon"}
local themeY = 0
for _, name in ipairs(themeNames) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 30)
    btn.Position = UDim2.new(0, 0, 0, themeY)
    btn.BackgroundColor3 = Themes.Amethyst.panel
    btn.Text = name
    btn.TextColor3 = Themes.Amethyst.text
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 13
    btn.Parent = ThemeDropdown
    btn.MouseButton1Click:Connect(function()
        ActiveTheme = name
        applyTheme(Window, Content, Header, WindowGradient)
        ThemeDropdown.Visible = false
    end)
    themeY = themeY + 30
end

ThemeBtn.MouseButton1Click:Connect(function()
    ThemeDropdown.Visible = not ThemeDropdown.Visible
end)

-- Resize handle
local ResizeHandle = Instance.new("Frame")
ResizeHandle.Size = UDim2.new(0, 16, 0, 16)
ResizeHandle.Position = UDim2.new(1, -16, 1, -16)
ResizeHandle.BackgroundColor3 = Themes.Amethyst.accent
ResizeHandle.BorderSizePixel = 0
ResizeHandle.Parent = Window
Instance.new("UICorner", ResizeHandle).CornerRadius = UDim.new(0, 4)

-- ================================ THEME APPLY FUNCTION ================================
local function applyTheme(win, cont, head, grad)
    local t = Themes[ActiveTheme]
    if not t then return end
    win.BackgroundColor3 = t.bg
    head.BackgroundColor3 = t.header
    cont.BackgroundColor3 = t.bg
    if grad then grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, t.header),
        ColorSequenceKeypoint.new(1, t.bg),
    }) end
    for _, frame in ipairs(cont:GetDescendants()) do
        if frame:IsA("Frame") and frame:GetAttribute("Themed") then
            local ptype = frame:GetAttribute("PanelType")
            if ptype == "panel" then
                frame.BackgroundColor3 = t.panel
            elseif ptype == "accent" then
                frame.BackgroundColor3 = t.accent
            elseif ptype == "danger" then
                frame.BackgroundColor3 = t.danger
            elseif ptype == "success" then
                frame.BackgroundColor3 = t.success
            elseif ptype == "hot" then
                frame.BackgroundColor3 = t.hot
            end
        end
        if frame:IsA("TextLabel") or frame:IsA("TextButton") then
            local txtype = frame:GetAttribute("TextType")
            if txtype == "primary" then
                frame.TextColor3 = t.text
            elseif txtype == "sub" then
                frame.TextColor3 = t.subtext
            elseif txtype == "accent" then
                frame.TextColor3 = t.accent
            end
        end
    end
end

-- ================================ UI INTERACTIONS ================================
local isOpen = true
CollapseBtn.MouseButton1Click:Connect(function()
    isOpen = not isOpen
    CollapseBtn.Text = isOpen and "▼ HIDE" or "▲ SHOW"
    local targetSize = isOpen and UDim2.new(0, 480, 0, 380) or UDim2.new(0, 480, 0, 48)
    TweenService:Create(Window, TweenInfo.new(0.25), {Size = targetSize}):Play()
    Content.Visible = isOpen
end)

local dragActive, dragStartPos, dragStartOffset = false
Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragActive = true
        dragStartPos = input.Position
        dragStartOffset = Window.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragActive and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStartPos
        Window.Position = UDim2.new(dragStartOffset.X.Scale, dragStartOffset.X.Offset + delta.X,
                                    dragStartOffset.Y.Scale, dragStartOffset.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragActive = false
    end
end)

local resizeActive, resizeStartSize, resizeStartMouse = false
ResizeHandle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        resizeActive = true
        resizeStartSize = Window.Size
        resizeStartMouse = input.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if resizeActive and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - resizeStartMouse
        local newWidth = math.clamp(resizeStartSize.X.Offset + delta.X, 400, 800)
        local newHeight = math.clamp(resizeStartSize.Y.Offset + delta.Y, 300, 600)
        Window.Size = UDim2.new(0, newWidth, 0, newHeight)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        resizeActive = false
    end
end)

local sliderDrag = false
SliderTrack.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        sliderDrag = true
        local pct = math.clamp((input.Position.X - SliderTrack.AbsolutePosition.X) / SliderTrack.AbsoluteSize.X, 0, 1)
        SliderFill.Size = UDim2.new(pct, 0, 1, 0)
        SliderThumb.Position = UDim2.new(pct, -7, 0.5, -7)
        Engine.delay = math.floor(150 + pct * 1850)
        DelayLabel.Text = string.format("⏱ Delay: %d ms", Engine.delay)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if sliderDrag and input.UserInputType == Enum.UserInputType.MouseMovement then
        local pct = math.clamp((input.Position.X - SliderTrack.AbsolutePosition.X) / SliderTrack.AbsoluteSize.X, 0, 1)
        SliderFill.Size = UDim2.new(pct, 0, 1, 0)
        SliderThumb.Position = UDim2.new(pct, -7, 0.5, -7)
        Engine.delay = math.floor(150 + pct * 1850)
        DelayLabel.Text = string.format("⏱ Delay: %d ms", Engine.delay)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        sliderDrag = false
    end
end)

SmartToggle.MouseButton1Click:Connect(function()
    Engine.smartMode = not Engine.smartMode
    if Engine.smartMode then
        SmartToggle.BackgroundColor3 = Themes.Amethyst.accent
        SmartToggle.Text = "🧠 AI: HEAT MODE ON"
    else
        SmartToggle.BackgroundColor3 = Themes.Amethyst.panel
        SmartToggle.Text = "📋 AI: SEQUENTIAL MODE"
    end
end)

-- ================================ MAIN LOOP ================================
local function resetRound()
    Engine.guessed = {}
    Engine.totalFired = 0
    Engine.kill = false
    clusterHeat = {}
    TotalLabel.Text = "Fired: 0 words"
    StatusText.Text = "⏳ New round ready"
end

StartBtn.MouseButton1Click:Connect(function()
    if Engine.running then return end
    if not REMOTE then
        StatusText.Text = "❌ Remote not found – cannot start"
        return
    end
    if Engine.thread then
        Engine.kill = true
        task.wait(0.1)
    end
    resetRound()
    Engine.running = true
    Engine.kill = false
    Engine.thread = task.spawn(function()
        while Engine.running and not Engine.kill do
            local word, mode, score = pickNext()
            if not word then
                StatusText.Text = "⚠️ Dictionary exhausted"
                Engine.running = false
                break
            end
            pcall(function() REMOTE:FireServer(word) end)
            Engine.guessed[word] = true
            Engine.totalFired = Engine.totalFired + 1
            TotalLabel.Text = string.format("Fired: %d words", Engine.totalFired)
            StatusText.Text = string.format("🚀 Fired: %s", word)
            if mode == "Smart" then
                local multTag = Engine.topWord.mult > 1 and string.format(" ×%d", Engine.topWord.mult) or ""
                TopWordLbl.Text = string.format("🏆 Top guess: %s (rank #%d)%s", Engine.topWord.word, Engine.topWord.rank, multTag)
                ClusterLbl.Text = string.format("🎯 Targeting: %s", Engine.targetCluster)
                HeatLbl.Text = string.format("🔥 Heat: %.0f  |  Smart mode", score)
            elseif mode == "Warmup" then
                HeatLbl.Text = "🔥 Mode: Warmup (seeding)"
                ClusterLbl.Text = "🎯 Scanning leaderboard..."
            elseif mode == "Fallback" then
                HeatLbl.Text = "🔥 Mode: Fallback (diversifying)"
            else
                HeatLbl.Text = "🔥 Mode: Sequential"
            end
            local jitter = math.random(-40, 40) / 1000
            task.wait((Engine.delay / 1000) + jitter)
        end
        Engine.thread = nil
    end)
end)

StopBtn.MouseButton1Click:Connect(function()
    Engine.kill = true
    Engine.running = false
    clusterHeat = {}
    StatusText.Text = "⏹ Stopped"
    HeatLbl.Text = "🔥 Heat cleared"
end)

-- Apply initial theme (UI elements already exist)
applyTheme(Window, Content, Header, WindowGradient)