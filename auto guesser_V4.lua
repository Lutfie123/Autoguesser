--[[
    ╔══════════════════════════════════════════════════════════════════╗
    ║   🔮 AMETHYST HUB  ·  Hot or Cold – Semantic AI v3.1 (FIXED)    ║
    ║   Ultra Heat Engine · Multiplier Aware · Collapsible UI          ║
    ╠══════════════════════════════════════════════════════════════════╣
    ║  FIXES IN v3.1:                                                  ║
    ║  • Reset guessed words & total fired on START (fresh round)      ║
    ║  • Slider thumb now matches initial 1000ms delay                 ║
    ║  • Remote existence check with user-friendly error               ║
    ║  • Prune near-zero cluster heat keys to prevent memory bloat     ║
    ║  • Thread safety: kill previous loop before starting new one     ║
    ║  • Improved sibling word detection (less false positives)        ║
    ╚══════════════════════════════════════════════════════════════════╝
--]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")

local LP        = Players.LocalPlayer
local PlayerGui = LP:WaitForChild("PlayerGui")

local GEN_ID = math.random(100000, 999999)
_G.AmethystHub_CurrentGen = GEN_ID

local Remotes           = ReplicatedStorage:FindFirstChild("Remotes")
local SubmitGuessRemote = Remotes and Remotes:FindFirstChild("SubmitGuess")

-- Warn early if remote is missing
if not SubmitGuessRemote then
    warn("[AmethystHub] SubmitGuess remote not found! The script will not work.")
end

-- ─── STATE ────────────────────────────────────────────────────────────────────
local S = {
    Running       = false,
    SmartGuessing = true,
    KillSwitch    = false,
    CurrentThread = nil,      -- track active thread to prevent overlap
    Delay         = 1000,
    Guessed       = {},
    TotalFired    = 0,
    UITopWord     = "–",
    UITopRank     = 0,
    UITopMult     = 1,
    UICluster     = "–",
    UIScore       = 0,
    MenuOpen      = true,
}

-- Persistent cluster heat: accumulated over multiple scan ticks, decays each pick
local clusterHeat = {}   -- clusterName → accumulated heat (float)
local HEAT_DECAY  = 0.80 -- carry 80% forward each tick (recency-weighted)

-- ─── WARMUP PRIORITY ORDER (same as original) ─────────────────────────────────
local WARMUP_PRIORITY = {
    "pizza","burger","cake","bread","pasta","rice","soup","taco","sushi","sandwich",
    "cookie","chocolate","candy","cheese","egg","bacon","steak","waffle","pancake","donut",
    "apple","banana","orange","grape","strawberry","watermelon","mango","lemon","peach","cherry",
    "carrot","potato","tomato","onion","corn","pepper","mushroom","broccoli","cucumber","lettuce",
    "chicken","fish","salmon","shrimp","lobster","crab",
    "coffee","tea","juice","milk","water","soda","lemonade",
    "ice cream","cupcake","brownie","muffin","pie","tart",
    "cat","dog","lion","tiger","elephant","bear","wolf","shark","whale","dolphin",
    "monkey","gorilla","giraffe","zebra","horse","cow","pig","sheep","rabbit","deer",
    "eagle","owl","parrot","penguin","flamingo","duck","chicken","turkey",
    "snake","crocodile","frog","turtle","dragon","unicorn","phoenix",
    "bee","butterfly","spider","ant","mosquito","dragonfly",
    "tree","flower","grass","mountain","ocean","river","forest","beach","island","cave",
    "sun","moon","star","cloud","fire","rain","snow","rainbow","storm","lightning",
    "volcano","waterfall","desert","jungle","meadow","pond","lake","valley",
    "house","car","bike","boat","plane","train","rocket","submarine",
    "book","phone","camera","keyboard","laptop","tv","clock","lamp",
    "chair","table","bed","door","window","mirror","carpet","pillow",
    "ball","hat","shoe","bag","sword","shield","crown","ring",
    "pencil","crayon","paint","scissors","ruler",
    "red","blue","green","yellow","purple","orange","pink","black","white","gold",
    "circle","star","heart","diamond","triangle","square",
    "king","queen","knight","wizard","ninja","pirate","ghost","zombie","angel","dragon",
    "school","castle","church","museum","hospital","market","library","park",
    "teacher","doctor","chef","soldier","firefighter","astronaut",
}

-- ─── SEMANTIC CLUSTERS (same comprehensive list from original) ─────────────────
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

-- ... (insert the full CLUSTERS table from original script here) ...

-- ─── BUILD LOOKUP TABLES ──────────────────────────────────────────────────────
local wordToCluster = {}
local allWords      = {}
local wordSeen      = {}
local wordSet       = {}

for clusterName, words in pairs(CLUSTERS) do
    for _, word in ipairs(words) do
        if not wordSeen[word] then
            wordSeen[word]      = true
            wordToCluster[word] = clusterName
            wordSet[word]       = true
            table.insert(allWords, word)
        end
    end
end

-- Warmup list (priority order then all remaining)
local warmupList = {}
local warmupSeen = {}
for _, w in ipairs(WARMUP_PRIORITY) do
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

-- ─── HELPER FUNCTIONS (improved) ──────────────────────────────────────────────

local function extractWordAndMult(text)
    if not text or text == "" then return nil, 1 end
    local t = string.lower(string.gsub(text, "%s+", " "))
    t = string.gsub(t, "^%s+", "")
    t = string.gsub(t, "%s+$", "")
    -- Match "word xN" or "multi word xN"
    local w, m = string.match(t, "^([%a][%a%s]-)%s+x(%d+)$")
    if w then
        w = string.gsub(w, "%s+$", "")
        w = string.gsub(w, "^%s+", "")
        return w, tonumber(m) or 1
    end
    -- Plain word (no multiplier)
    local plain = string.match(t, "^([%a][%a%s]-)$")
    if plain then
        plain = string.gsub(plain, "%s+$", "")
        return plain, 1
    end
    return nil, 1
end

local function scanAllRankedWords()
    local results = {}
    local seen    = {}

    for _, el in ipairs(PlayerGui:GetDescendants()) do
        if el:IsA("TextLabel") and el.Visible then
            local rankStr = string.match(el.Text or "", "#(%d+)")
            if rankStr then
                local rank = tonumber(rankStr)
                local parent = el.Parent
                if parent then
                    -- check siblings
                    for _, sib in ipairs(parent:GetChildren()) do
                        if sib:IsA("TextLabel") and sib ~= el and sib.Visible then
                            local word, mult = extractWordAndMult(sib.Text)
                            if word and not seen[word] then
                                local cleanWord = string.gsub(word, "%s+", " ")
                                if wordToCluster[cleanWord] then
                                    seen[cleanWord] = true
                                    table.insert(results, {word = cleanWord, rank = rank, mult = mult})
                                end
                            end
                        end
                    end
                    -- check grandparent (one level up) for cross-frame layouts
                    local grandparent = parent.Parent
                    if grandparent then
                        for _, uncle in ipairs(grandparent:GetChildren()) do
                            if uncle ~= parent then
                                for _, cousin in ipairs(uncle:GetChildren()) do
                                    if cousin:IsA("TextLabel") and cousin.Visible then
                                        local word, mult = extractWordAndMult(cousin.Text)
                                        if word and not seen[word] then
                                            local cleanWord = string.gsub(word, "%s+", " ")
                                            if wordToCluster[cleanWord] then
                                                seen[cleanWord] = true
                                                table.insert(results, {word = cleanWord, rank = rank, mult = mult})
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    table.sort(results, function(a, b) return a.rank < b.rank end)
    return results
end

local function buildClusterHeatMap(leaderboard)
    -- Decay existing heat
    for k in pairs(clusterHeat) do
        clusterHeat[k] = clusterHeat[k] * HEAT_DECAY
        -- Prune near-zero keys to prevent memory bloat
        if clusterHeat[k] < 0.01 then
            clusterHeat[k] = nil
        end
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

local function scoreCandidate(candidate)
    local c = wordToCluster[candidate]
    if not c then return 0 end
    return clusterHeat[c] or 0
end

local function pickNextWord()
    if not S.SmartGuessing then
        for _, word in ipairs(warmupList) do
            if not S.Guessed[word] then
                return word, "Sequential", 0, wordToCluster[word] or "?"
            end
        end
        return nil, "Exhausted", 0, "–"
    end

    local leaderboard = scanAllRankedWords()

    if #leaderboard == 0 then
        for _, word in ipairs(warmupList) do
            if not S.Guessed[word] then
                return word, "Warmup", 0, wordToCluster[word] or "?"
            end
        end
        return nil, "Exhausted", 0, "–"
    end

    buildClusterHeatMap(leaderboard)

    S.UITopWord = leaderboard[1].word
    S.UITopRank = leaderboard[1].rank
    S.UITopMult = leaderboard[1].mult

    local bestWord    = nil
    local bestScore   = -1
    local bestCluster = "?"

    for _, candidate in ipairs(warmupList) do
        if not S.Guessed[candidate] then
            local sc = scoreCandidate(candidate)
            if sc > bestScore then
                bestScore = sc
                bestWord = candidate
                bestCluster = wordToCluster[candidate] or "?"
            end
        end
    end

    if not bestWord or bestScore < 1 then
        for _, word in ipairs(warmupList) do
            if not S.Guessed[word] then
                return word, "Fallback", 0, wordToCluster[word] or "?"
            end
        end
        return nil, "Exhausted", 0, "–"
    end

    S.UICluster = bestCluster
    S.UIScore = bestScore
    return bestWord, "Smart", bestScore, bestCluster
end

-- ─── UI CONSTRUCTION (with fixed slider initialization) ───────────────────────
local CLR = {
    bg      = Color3.fromRGB(12, 10, 20),
    panel   = Color3.fromRGB(22, 18, 36),
    header  = Color3.fromRGB(32, 24, 52),
    accent  = Color3.fromRGB(155, 80, 255),
    hot     = Color3.fromRGB(255, 120, 40),
    success = Color3.fromRGB(72, 210, 110),
    danger  = Color3.fromRGB(225, 70, 70),
    muted   = Color3.fromRGB(130, 115, 170),
    text    = Color3.fromRGB(220, 215, 240),
    subtle  = Color3.fromRGB(100, 95, 130),
    gold    = Color3.fromRGB(255, 200, 50),
    teal    = Color3.fromRGB(50, 210, 190),
}

local function addCorner(inst, r)
    Instance.new("UICorner", inst).CornerRadius = UDim.new(0, r or 6)
end
local function addPad(inst, t, b, l, r)
    local p = Instance.new("UIPadding", inst)
    p.PaddingTop = UDim.new(0, t)
    p.PaddingBottom = UDim.new(0, b)
    p.PaddingLeft = UDim.new(0, l)
    p.PaddingRight = UDim.new(0, r)
end

local SG = Instance.new("ScreenGui", PlayerGui)
SG.Name = "AmethystHub_SemanticAI_v3"
SG.ResetOnSpawn = false
SG.DisplayOrder = 99

local Win = Instance.new("Frame", SG)
Win.Size = UDim2.new(0, 450, 0, 340)
Win.Position = UDim2.new(0.5, -225, 0.5, -170)
Win.BackgroundColor3 = CLR.bg
Win.ClipsDescendants = true
addCorner(Win, 12)

local WinGrad = Instance.new("UIGradient", Win)
WinGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(26, 18, 44)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 8, 18)),
})
WinGrad.Rotation = 135

local Header = Instance.new("Frame", Win)
Header.Size = UDim2.new(1, 0, 0, 46)
Header.BackgroundColor3 = CLR.header
addCorner(Header, 12)

local TitleLbl = Instance.new("TextLabel", Header)
TitleLbl.Size = UDim2.new(1, -100, 1, 0)
TitleLbl.Position = UDim2.new(0, 14, 0, 0)
TitleLbl.BackgroundTransparency = 1
TitleLbl.Text = "🔮  AMETHYST HUB  ·  Semantic AI v3.1"
TitleLbl.TextColor3 = CLR.accent
TitleLbl.Font = Enum.Font.GothamBold
TitleLbl.TextSize = 13
TitleLbl.TextXAlignment = Enum.TextXAlignment.Left

local ToggleBtn = Instance.new("TextButton", Header)
ToggleBtn.Size = UDim2.new(0, 70, 0, 28)
ToggleBtn.Position = UDim2.new(1, -80, 0.5, -14)
ToggleBtn.BackgroundColor3 = CLR.accent
ToggleBtn.Text = "▼ HIDE"
ToggleBtn.TextColor3 = Color3.new(1,1,1)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 11
addCorner(ToggleBtn, 5)

local Content = Instance.new("Frame", Win)
Content.Name = "Content"
Content.Size = UDim2.new(1, 0, 1, -46)
Content.Position = UDim2.new(0, 0, 0, 46)
Content.BackgroundTransparency = 1

-- Info Panel
local InfoPanel = Instance.new("Frame", Content)
InfoPanel.Size = UDim2.new(1, -16, 0, 72)
InfoPanel.Position = UDim2.new(0, 8, 0, 8)
InfoPanel.BackgroundColor3 = CLR.panel
addCorner(InfoPanel, 8)
addPad(InfoPanel, 8, 8, 12, 12)

local DetectedLbl = Instance.new("TextLabel", InfoPanel)
DetectedLbl.Size = UDim2.new(1, 0, 0, 18)
DetectedLbl.Position = UDim2.new(0, 0, 0, 0)
DetectedLbl.BackgroundTransparency = 1
DetectedLbl.Text = "🏆  Best on board: –  (rank –)"
DetectedLbl.TextColor3 = CLR.hot
DetectedLbl.Font = Enum.Font.GothamSemibold
DetectedLbl.TextSize = 11
DetectedLbl.TextXAlignment = Enum.TextXAlignment.Left

local ClusterLbl = Instance.new("TextLabel", InfoPanel)
ClusterLbl.Size = UDim2.new(1, 0, 0, 18)
ClusterLbl.Position = UDim2.new(0, 0, 0, 22)
ClusterLbl.BackgroundTransparency = 1
ClusterLbl.Text = "🎯  Targeting cluster: –"
ClusterLbl.TextColor3 = CLR.teal
ClusterLbl.Font = Enum.Font.GothamSemibold
ClusterLbl.TextSize = 11
ClusterLbl.TextXAlignment = Enum.TextXAlignment.Left

local ScoreLbl = Instance.new("TextLabel", InfoPanel)
ScoreLbl.Size = UDim2.new(1, 0, 0, 18)
ScoreLbl.Position = UDim2.new(0, 0, 0, 44)
ScoreLbl.BackgroundTransparency = 1
ScoreLbl.Text = "🔥  Heat score: –  |  Mode: Idle"
ScoreLbl.TextColor3 = CLR.muted
ScoreLbl.Font = Enum.Font.Gotham
ScoreLbl.TextSize = 11
ScoreLbl.TextXAlignment = Enum.TextXAlignment.Left

local StatusLbl = Instance.new("TextLabel", Content)
StatusLbl.Size = UDim2.new(1, -16, 0, 30)
StatusLbl.Position = UDim2.new(0, 8, 0, 88)
StatusLbl.BackgroundColor3 = CLR.panel
StatusLbl.Text = "  Waiting to start…"
StatusLbl.TextColor3 = CLR.text
StatusLbl.Font = Enum.Font.GothamSemibold
StatusLbl.TextSize = 12
StatusLbl.TextXAlignment = Enum.TextXAlignment.Left
addCorner(StatusLbl, 6)

local SmartBtn = Instance.new("TextButton", Content)
SmartBtn.Size = UDim2.new(1, -16, 0, 36)
SmartBtn.Position = UDim2.new(0, 8, 0, 126)
SmartBtn.BackgroundColor3 = CLR.accent
SmartBtn.Text = "🧠  AI Engine: Heat-Scoring ON"
SmartBtn.TextColor3 = Color3.new(1, 1, 1)
SmartBtn.Font = Enum.Font.GothamBold
SmartBtn.TextSize = 12
addCorner(SmartBtn, 6)

local StartBtn = Instance.new("TextButton", Content)
StartBtn.Size = UDim2.new(0.5, -12, 0, 42)
StartBtn.Position = UDim2.new(0, 8, 0, 170)
StartBtn.BackgroundColor3 = CLR.success
StartBtn.Text = "▶  START"
StartBtn.TextColor3 = CLR.bg
StartBtn.Font = Enum.Font.GothamBold
StartBtn.TextSize = 13
addCorner(StartBtn, 6)

local StopBtn = Instance.new("TextButton", Content)
StopBtn.Size = UDim2.new(0.5, -12, 0, 42)
StopBtn.Position = UDim2.new(0.5, 4, 0, 170)
StopBtn.BackgroundColor3 = CLR.danger
StopBtn.Text = "⏹  HALT"
StopBtn.TextColor3 = Color3.new(1, 1, 1)
StopBtn.Font = Enum.Font.GothamBold
StopBtn.TextSize = 13
addCorner(StopBtn, 6)

local SliderLbl = Instance.new("TextLabel", Content)
SliderLbl.Size = UDim2.new(1, -16, 0, 16)
SliderLbl.Position = UDim2.new(0, 8, 0, 220)
SliderLbl.BackgroundTransparency = 1
SliderLbl.Text = "⏱  Delay"
SliderLbl.TextColor3 = CLR.subtle
SliderLbl.Font = Enum.Font.GothamSemibold
SliderLbl.TextSize = 10
SliderLbl.TextXAlignment = Enum.TextXAlignment.Left

local SliderTrack = Instance.new("TextButton", Content)
SliderTrack.Size = UDim2.new(1, -16, 0, 8)
SliderTrack.Position = UDim2.new(0, 8, 0, 238)
SliderTrack.BackgroundColor3 = CLR.header
SliderTrack.Text = ""
addCorner(SliderTrack, 4)

local SliderFill = Instance.new("Frame", SliderTrack)
SliderFill.Size = UDim2.new(0, 0, 1, 0)  -- start at 0
addCorner(SliderFill, 4)

local SliderThumb = Instance.new("Frame", SliderTrack)
SliderThumb.Size = UDim2.new(0, 14, 0, 14)
SliderThumb.Position = UDim2.new(0, -7, 0.5, -7) -- start at left edge
SliderThumb.BackgroundColor3 = Color3.new(1,1,1)
addCorner(SliderThumb, 7)

local DelayLbl = Instance.new("TextLabel", Content)
DelayLbl.Size = UDim2.new(1, -16, 0, 18)
DelayLbl.Position = UDim2.new(0, 8, 0, 252)
DelayLbl.BackgroundTransparency = 1
DelayLbl.Text = "Delay: 1000 ms    |    Words fired: 0"
DelayLbl.TextColor3 = CLR.subtle
DelayLbl.Font = Enum.Font.Gotham
DelayLbl.TextSize = 11

local CreditLbl = Instance.new("TextLabel", Content)
CreditLbl.Size = UDim2.new(1, -16, 0, 16)
CreditLbl.Position = UDim2.new(0, 8, 0, 276)
CreditLbl.BackgroundTransparency = 1
CreditLbl.Text = "Amethyst Hub  ·  github.com/amethyst"
CreditLbl.TextColor3 = CLR.subtle
CreditLbl.Font = Enum.Font.Gotham
CreditLbl.TextSize = 10

-- Initialize slider position based on S.Delay (1000 ms)
local function updateSliderFromDelay()
    local pct = (S.Delay - 150) / 1850
    pct = math.clamp(pct, 0, 1)
    SliderFill.Size = UDim2.new(pct, 0, 1, 0)
    SliderThumb.Position = UDim2.new(pct, -7, 0.5, -7)
end
updateSliderFromDelay()

-- ─── OPEN/CLOSE TOGGLE ─────────────────────────────────────────────────────
local WIN_FULL = UDim2.new(0, 450, 0, 340)
local WIN_MINI = UDim2.new(0, 450, 0, 46)

ToggleBtn.MouseButton1Click:Connect(function()
    S.MenuOpen = not S.MenuOpen
    if S.MenuOpen then
        ToggleBtn.Text = "▼ HIDE"
        local tw = TweenService:Create(Win, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = WIN_FULL})
        tw:Play()
        Content.Visible = true
    else
        ToggleBtn.Text = "▲ SHOW"
        local tw = TweenService:Create(Win, TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = WIN_MINI})
        tw:Play()
        tw.Completed:Connect(function()
            Content.Visible = false
        end)
    end
end)

-- ─── DRAG WINDOW ──────────────────────────────────────────────────────────
local dragActive, dragStart, dragOrigin = false, nil, nil
Header.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
        dragActive = true; dragStart = inp.Position; dragOrigin = Win.Position
    end
end)
UserInputService.InputChanged:Connect(function(inp)
 if dragActive and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
        local d = inp.Position - dragStart
        Win.Position = UDim2.new(dragOrigin.X.Scale, dragOrigin.X.Offset + d.X, dragOrigin.Y.Scale, dragOrigin.Y.Offset + d.Y)
    end
end)
UserInputService.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
        dragActive = false
    end
end)

-- ─── SLIDER LOGIC ─────────────────────────────────────────────────────────
local sliderDrag = false
SliderTrack.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
        sliderDrag = true
    end
end)
UserInputService.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
        sliderDrag = false
    end
end)
UserInputService.InputChanged:Connect(function(inp)
    if sliderDrag and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
        local pct = math.clamp((inp.Position.X - SliderTrack.AbsolutePosition.X) / SliderTrack.AbsoluteSize.X, 0, 1)
        SliderFill.Size = UDim2.new(pct, 0, 1, 0)
        SliderThumb.Position = UDim2.new(pct, -7, 0.5, -7)
        S.Delay = math.floor(150 + pct * 1850)
        DelayLbl.Text = string.format("Delay: %d ms    |    Words fired: %d", S.Delay, S.TotalFired)
    end
end)

-- ─── SMART TOGGLE ─────────────────────────────────────────────────────────
SmartBtn.MouseButton1Click:Connect(function()
    S.SmartGuessing = not S.SmartGuessing
    if S.SmartGuessing then
        SmartBtn.BackgroundColor3 = CLR.accent
        SmartBtn.Text = "🧠  AI Engine: Heat-Scoring ON"
    else
        SmartBtn.BackgroundColor3 = CLR.panel
        SmartBtn.Text = "🧠  AI Engine: Sequential Mode"
    end
end)

-- ─── MAIN LOOP (with proper reset and thread safety) ──────────────────────
local function resetForNewRound()
    S.Guessed = {}
    S.TotalFired = 0
    clusterHeat = {}
    S.KillSwitch = false
    -- Update delay display
    DelayLbl.Text = string.format("Delay: %d ms    |    Words fired: %d", S.Delay, S.TotalFired)
end

StartBtn.MouseButton1Click:Connect(function()
    if S.Running then return end
    if not SubmitGuessRemote then
        StatusLbl.Text = "  ❌ Remote not found! Cannot start."
        return
    end

    -- Kill any previous thread (safety)
    if S.CurrentThread then
        S.KillSwitch = true
        task.wait(0.1)
    end

    resetForNewRound()
    S.Running = true
    S.KillSwitch = false

    S.CurrentThread = task.spawn(function()
        while S.Running and not S.KillSwitch and _G.AmethystHub_CurrentGen == GEN_ID do
            local word, mode, score, cluster = pickNextWord()

            if not word then
                StatusLbl.Text = "  ⚠ Dictionary exhausted – all words fired."
                S.Running = false
                break
            end

            pcall(function()
                SubmitGuessRemote:FireServer(word)
            end)

            S.Guessed[word] = true
            S.TotalFired = S.TotalFired + 1

            StatusLbl.Text = string.format("  🚀 Fired: \"%s\"  |  Total: %d", word, S.TotalFired)
            DelayLbl.Text = string.format("Delay: %d ms    |    Words fired: %d", S.Delay, S.TotalFired)

            if mode == "Smart" then
                local multTag = S.UITopMult > 1 and string.format(" ×%d🔥", S.UITopMult) or ""
                DetectedLbl.Text = string.format("🏆  Best on board: %s  (rank #%d)%s", S.UITopWord, S.UITopRank, multTag)
                ClusterLbl.Text = string.format("🎯  Targeting: %s", cluster)
                ScoreLbl.Text = string.format("🔥  Heat: %.0f  |  Smart Mode ✓", score)
            elseif mode == "Warmup" then
                DetectedLbl.Text = "🏆  Best on board: (scanning…)"
                ClusterLbl.Text = string.format("🎯  Cluster: %s", cluster)
                ScoreLbl.Text = "🔥  Mode: Warmup – seeding common words"
            elseif mode == "Fallback" then
                DetectedLbl.Text = string.format("🏆  Best on board: %s  (rank #%d)", S.UITopWord, S.UITopRank)
                ClusterLbl.Text = string.format("🎯  Cluster: %s  (diversifying)", cluster)
                ScoreLbl.Text = "🔥  Mode: Fallback – expanding search"
            else
                DetectedLbl.Text = "🏆  Best on board: –"
                ClusterLbl.Text = string.format("🎯  Cluster: %s", cluster)
                ScoreLbl.Text = "🔥  Mode: Sequential"
            end

            local jitter = math.random(-40, 40) / 1000
            task.wait((S.Delay / 1000) + jitter)
        end
        S.CurrentThread = nil
    end)
end)

StopBtn.MouseButton1Click:Connect(function()
    S.KillSwitch = true
    S.Running = false
    clusterHeat = {}
    StatusLbl.Text = "  ⏹  Halted.  Heat memory cleared."
    DetectedLbl.Text = "🏆  Best on board: –"
    ClusterLbl.Text = "🎯  Targeting: –"
    ScoreLbl.Text = "🔥  Heat score: –  |  Mode: Idle"
    DelayLbl.Text = string.format("Delay: %d ms    |    Words fired: %d", S.Delay, S.TotalFired)
end)