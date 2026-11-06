import '../models/destination.dart';

/// Returns the story of a destination as three readable paragraphs.
///
/// Curated histories are used for well-known places. For other spots the
/// stored history is expanded with a category-aware narrative so the section
/// always feels like a story instead of a single descriptive sentence.
List<String> storyParagraphsFor(Destination destination) {
  final raw = destination.history.trim();
  final rawParagraphs = _splitParagraphs(raw);

  if (rawParagraphs.length >= 3) {
    if (rawParagraphs.length == 3) return rawParagraphs;
    return [
      rawParagraphs[0],
      rawParagraphs[1],
      rawParagraphs.sublist(2).join(' '),
    ];
  }

  final curated = _curatedStories[_normalize(destination.name)];
  if (curated != null) return curated;

  final fallback = _categoryStory(destination);
  if (rawParagraphs.isEmpty || _isGenericHistory(raw)) return fallback;
  if (rawParagraphs.length == 2) {
    return [rawParagraphs[0], rawParagraphs[1], fallback[2]];
  }
  return [rawParagraphs.first, fallback[1], fallback[2]];
}

List<String> _splitParagraphs(String value) => value
    .split(RegExp(r'\n\s*\n|\r\n\s*\r\n|\n'))
    .map((paragraph) => paragraph.trim())
    .where((paragraph) => paragraph.isNotEmpty)
    .toList();

bool _isGenericHistory(String value) {
  final lower = value.toLowerCase();
  return lower.contains('rich history and cultural significance') ||
      lower.contains('making it a must-visit destination');
}

String _normalize(String value) => value
    .toLowerCase()
    .replaceAll(RegExp(r"[^a-z0-9\s]"), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

List<String> _categoryStory(Destination destination) {
  final place = destination.name;
  final area = destination.district.isEmpty
      ? (destination.division.isEmpty ? 'Bangladesh' : destination.division)
      : destination.district;
  final category = destination.category.toLowerCase();

  if (category.contains('beach') || category.contains('island')) {
    return [
      "Long before $place became a name on a travel map, its story was written in tides, salt air and the patient work of coastal families. Fishermen read the colour of the water each morning, boat builders repaired wooden hulls on the sand, and children learned the safe paths between the waves. The shore was never simply scenery; it was a workplace, a road and a gathering place rolled into one.",
      "As word spread beyond $area, traders, pilgrims and curious travellers began to arrive by boat and later by road. Small markets grew where nets were mended and meals were shared, carrying the flavours and languages of several communities. Storms and monsoons repeatedly reshaped the coastline, but the people who lived beside it learned to rebuild with patience, keeping their songs, recipes and local knowledge alive.",
      "Today $place invites visitors to experience that same rhythm at a gentler pace. Sunrise walks, fishing boats returning to shore and evenings beside the water still reveal the character of the place more clearly than any monument. Travel slowly, buy from local families and respect the tides, and the coast will share a story that feels personal rather than packaged.",
    ];
  }

  if (category.contains('hill') || category.contains('lake')) {
    return [
      "The story of $place begins with the land itself: layered hills, winding roads and water that mirrors the changing sky. For generations, communities in and around $area have built their lives around these slopes, growing crops on terraced ground, following forest paths and moving by boat where roads could not reach. The landscape has always demanded cooperation, and that shared effort is part of its identity.",
      "Over time, traders, travellers and settlers brought new customs into the hills while local traditions held their ground. Markets became meeting places for different communities, and festivals, woven cloth, bamboo craft and stories passed from elders to children. The region changed under kingdoms and modern borders, yet its everyday culture remained rooted in kinship, hospitality and a deep understanding of the terrain.",
      "For today's traveller, $place offers more than a viewpoint or a photograph. It is a chance to move with the pace of the hills, listen to local guides and appreciate how people live alongside forests, water and weather. The most memorable journeys here are the quiet ones: a boat ride at first light, a shared meal in a village, or a conversation that turns a landscape into a living story.",
    ];
  }

  if (category.contains('history')) {
    return [
      "The story of $place reaches back through layers of settlement, power and memory. The ground around $area has witnessed changing rulers, shifting trade routes and the everyday lives of people whose names rarely appear in official records. Walls, gateways and old foundations are only the visible fragments of a much larger story told through labour, craft and local legend.",
      "Each period left something behind: a style of brickwork, a word in the local dialect, a festival that outlived its original meaning. Merchants and travellers carried ideas along the roads, while craftsmen and farmers kept the settlement alive through seasons of plenty and hardship. What survives today is not simply architecture, but the habit of adapting without forgetting.",
      "A visit to $place is best approached as a walk through time rather than a checklist of monuments. Read the inscriptions slowly, notice the repairs made by later generations and ask local guides about the stories that never made it into textbooks. The past here is not sealed off from the present; it continues in the streets, markets and conversations that surround the old stones.",
    ];
  }

  if (category.contains('religious')) {
    return [
      "For generations, $place has been more than a landmark; it has been a place where people come to pause, remember and belong. The building and the ground around it grew through gifts of labour, money and faith from families across $area. Its courtyards and walls hold the quiet accumulation of prayers, journeys and promises made by ordinary people.",
      "The history of the site is closely tied to the community that cares for it. Festivals brought distant relatives home, markets gathered around the main entrances, and travellers found shelter nearby. Through changing seasons and political eras, the rituals adapted while the essential purpose remained: to offer a shared space for reflection and renewal.",
      "Today, visitors of all backgrounds can appreciate $place for its craftsmanship, its atmosphere and its place in local life. Dress respectfully, move quietly where people are praying and take time to speak with those who keep the site alive. The deepest history here is not only in the architecture but in the continuing devotion of the people around it.",
    ];
  }

  if (category.contains('city')) {
    return [
      "Like many living cities, $place grew around movement. Roads, river crossings and marketplaces drew people from surrounding villages, and each new arrival added a craft, a recipe or a way of speaking to the mix. What began as a practical stopping point gradually became a place with its own habits, landmarks and civic pride.",
      "The city's identity was shaped by work as much as by planning. Traders, clerks, teachers, labourers and students built neighbourhoods around shared needs, while parks, bridges and public buildings gave the growing population places to gather. Periods of rapid change brought new architecture and new tensions, but the streets kept absorbing them, layer by layer.",
      "Today $place is best understood by walking through its ordinary corners as well as its famous ones. Early morning markets, tea stalls, quiet lanes and riverside walks reveal how the city still works. Travellers who slow down and talk to residents will find that the story of the place is being written every day, not only preserved behind glass.",
    ];
  }

  if (category.contains('wetland')) {
    return [
      "The story of $place is a story of water. Seasonal floods, shallow basins and reed beds have shaped how people fish, farm and move through $area for generations. Families learned to read the rising and falling levels, building homes and livelihoods that could bend with the monsoon rather than resist it.",
      "Life here depends on cooperation. Fishermen, farmers and boatmen share the same channels and the same risks, and local customs often govern when and how resources are used. Birds arrive in great numbers each season, adding another layer to a landscape already rich with sound, movement and changing colour.",
      "For visitors, $place is an invitation to disappear from the usual pace of travel. A boat journey at dawn, a cup of tea with a fishing family or an afternoon beside the water can reveal more than a hurried tour. The wetland asks for patience and care; in return, it offers one of the most memorable natural stories in Bangladesh.",
    ];
  }

  if (category.contains('ecotourism')) {
    return [
      "The story of $place is rooted in the relationship between people and the natural world. Forests, wetlands and open land around $area have long provided food, shelter and materials, and local communities developed careful habits to keep those resources alive. What looks untouched to a visitor is often the result of generations of quiet stewardship.",
      "In recent decades, the idea of travel as a responsibility has become part of the area's identity. Guides, conservation workers and families have worked to protect wildlife habitats while creating livelihoods that depend on the forest remaining healthy. The balance is never perfect, but it has made the region a place where conservation and everyday life meet.",
      "A responsible visit to $place should begin with listening. Follow your guide, stay on marked paths, avoid plastic and choose local services wherever possible. The reward is a closer look at a landscape that is not a backdrop but a home, and a story in which the traveller can be a respectful guest rather than a passing spectator.",
    ];
  }

  if (category.contains('culture')) {
    return [
      "The story of $place is carried less by monuments than by memory. Songs, crafts, recipes and the way people greet one another have passed through families and neighbourhoods in $area for generations. Each generation has added something of its own while keeping the older forms close.",
      "Writers, artists, musicians and craftspeople have often gathered here because the place allows room for both tradition and experiment. Festivals and informal meetings created networks that reached far beyond the district, while ordinary households kept the daily practices that give the culture its texture. The result is a heritage that feels lived-in rather than staged.",
      "Visitors can experience $place through its food, markets, workshops and performances, but the most meaningful encounters come from conversation. Ask before taking photographs, support local makers and take time to understand the context behind a song or a design. Culture here is ongoing, and every respectful visitor becomes part of its next chapter.",
    ];
  }

  return [
    "The story of $place is closely tied to the landscape of $area. Rivers, forests, fields or open sky have shaped how people settle, travel and earn a living, and each generation has learned to work with what the land provides. The place may look peaceful at first glance, but its quiet routines are built on knowledge passed down over many years.",
    "Over time, nearby communities developed their own customs around food, work and hospitality. Markets brought people together, festivals marked the turning of the year, and travellers carried news and ideas along old routes. Change arrived gradually and then more quickly, yet local families continued to adapt without losing the habits that made the place distinctive.",
    "Today $place offers travellers a chance to slow down and see beyond the usual itinerary. Local guides, family-run eateries and small markets reveal a side of the place that a hurried visit cannot reach. Travel with curiosity and respect, and the story of $place becomes more than a stop on a map; it becomes a memory shaped by people and place together.",
  ];
}

const _curatedStories = <String, List<String>>{
  'coxs bazar sea beach': [
    "For generations, the long curve of sand at Cox's Bazar has belonged less to maps than to the rhythm of the Bay of Bengal. Fishing families read the tides before sunrise, boat builders repaired wooden hulls above the high-water line, and children learned to respect the currents. The beach was a road, a workplace and a gathering ground long before it became a holiday destination.",
    "The town grew as a meeting point for coastal communities, traders and travellers moving between Chattogram and the far south. Markets filled with dried fish, rice, betel leaf and stories from across the bay, while Rakhine and Bengali traditions blended in food, music and the shape of local homes. Storms repeatedly redrew the shoreline, but each time the community rebuilt with the patience of people who understand the sea.",
    "Today Cox's Bazar welcomes visitors from across Bangladesh and beyond. Behind the hotels and evening crowds, the older life of the coast is still visible in the fish landing sites, the quiet villages south of town and the long walk toward Himchari. Travellers who rise early, buy from local vendors and respect the water will find a place that is far richer than its famous beachfront.",
  ],
  'coxs bazar': [
    "For generations, the long curve of sand at Cox's Bazar has belonged less to maps than to the rhythm of the Bay of Bengal. Fishing families read the tides before sunrise, boat builders repaired wooden hulls above the high-water line, and children learned to respect the currents. The beach was a road, a workplace and a gathering ground long before it became a holiday destination.",
    "The town grew as a meeting point for coastal communities, traders and travellers moving between Chattogram and the far south. Markets filled with dried fish, rice, betel leaf and stories from across the bay, while Rakhine and Bengali traditions blended in food, music and the shape of local homes. Storms repeatedly redrew the shoreline, but each time the community rebuilt with the patience of people who understand the sea.",
    "Today Cox's Bazar welcomes visitors from across Bangladesh and beyond. Behind the hotels and evening crowds, the older life of the coast is still visible in the fish landing sites, the quiet villages south of town and the long walk toward Himchari. Travellers who rise early, buy from local vendors and respect the water will find a place that is far richer than its famous beachfront.",
  ],
  'sundarbans': [
    "The Sundarbans begins where land and water refuse to separate cleanly. For centuries, the mangrove forest has absorbed the force of cyclones, held the delta together and offered shelter to wildlife found almost nowhere else. Fishermen, honey collectors and boatmen learned to move through its creeks by reading the tides, the wind and the behaviour of birds long before any map was drawn.",
    "Life around the forest has always required courage and restraint. Villagers depend on its fish, honey and wood, yet they also carry the memory of storms and tiger encounters that have shaped local folklore. The forest is protected today, but the relationship between people and the Sundarbans remains intimate, practical and sometimes tense. That complexity is part of what makes the place so powerful.",
    "A journey into the Sundarbans is not a conventional sightseeing trip. It is a slow passage through silent channels, sudden open water and tangled roots, best undertaken with experienced local crews who understand the risks. Travel quietly, follow every safety instruction and remember that the forest is not a theme park; it is a living system that has survived by being respected.",
  ],
  'the sundarbans': [
    "The Sundarbans begins where land and water refuse to separate cleanly. For centuries, the mangrove forest has absorbed the force of cyclones, held the delta together and offered shelter to wildlife found almost nowhere else. Fishermen, honey collectors and boatmen learned to move through its creeks by reading the tides, the wind and the behaviour of birds long before any map was drawn.",
    "Life around the forest has always required courage and restraint. Villagers depend on its fish, honey and wood, yet they also carry the memory of storms and tiger encounters that have shaped local folklore. The forest is protected today, but the relationship between people and the Sundarbans remains intimate, practical and sometimes tense. That complexity is part of what makes the place so powerful.",
    "A journey into the Sundarbans is not a conventional sightseeing trip. It is a slow passage through silent channels, sudden open water and tangled roots, best undertaken with experienced local crews who understand the risks. Travel quietly, follow every safety instruction and remember that the forest is not a theme park; it is a living system that has survived by being respected.",
  ],
  'saint martins island': [
    "Saint Martin's Island has always been defined by the sea around it. For generations, fishing families have lived along its shore, drying fish in the sun and moving with the seasons between the island and the mainland. The coral stone, shallow water and narrow beaches shaped a way of life that was modest, resourceful and closely tied to the tides.",
    "The island's isolation made it a place of close-knit communities, where neighbours shared boats, wells and news from the mainland. Over time, visitors began to arrive in search of clear water and quiet nights, and small guesthouses and eateries grew around that new income. The change brought opportunity, but it also placed pressure on a fragile environment that has little room for careless growth.",
    "Today Saint Martin's is loved for its simplicity: bicycle rides, fresh fish, long walks at low tide and evenings without the noise of a city. That simplicity is worth protecting. Carry your waste back, avoid damaging coral, use local services and travel in smaller numbers so the island can keep offering the same quiet welcome to the next generation.",
  ],
  'bandarban': [
    "Bandarban rises in layers of green, cloud and stone, a place where roads bend around hills and rivers appear without warning. Long before it became a destination for travellers, the region was home to diverse hill communities who built their lives around shifting cultivation, forest produce and strong ties of kinship. The land was never easy, but it rewarded those who understood its seasons.",
    "The hill tracts have a history of independence and cultural resilience. Different communities developed their own languages, festivals, weaving traditions and systems of local authority, often maintaining them through periods of great political change. Markets in towns such as Bandarban became meeting points where hill and plains communities exchanged goods, news and mutual curiosity.",
    "For visitors, Bandarban is a place to move slowly and listen carefully. A boat on the Sangu, a walk through a village or a morning above the clouds at Nilgiri can be unforgettable, but the deeper story belongs to the people who live there. Choose local guides, ask before photographing and travel with humility; the hills have their own pace, and it is worth following.",
  ],
  'srimangal tea country': [
    "Srimangal's story changed with the arrival of tea. Before the estates spread across the low hills, the area was known for forests, wetlands and small settlements tied to the rhythms of the northeast. The first commercial tea gardens in the nineteenth century brought workers, machinery and new trade routes, gradually turning a quiet corner of Moulvibazar into a landscape of neat green rows.",
    "The tea industry drew families from across Bengal and beyond, creating communities whose food, language and daily routines still reflect that mixing. Estate workers rose before dawn, plucked leaves in the mist and carried their baskets to factories where the smell of drying tea filled the air. Around them, forests such as Lawachara survived, sheltering wildlife and reminding travellers that this is more than a cultivated landscape.",
    "Today Srimangal is best explored by bicycle, on foot and with time to spare. Estate roads, tea-stall cups, forest trails and the famous seven-layer tea all offer a way into local life. Visitors who respect workers, avoid waste and buy directly from small producers help keep the area's story rooted in the people who made it.",
  ],
  'srimangal tea garden': [
    "Srimangal's story changed with the arrival of tea. Before the estates spread across the low hills, the area was known for forests, wetlands and small settlements tied to the rhythms of the northeast. The first commercial tea gardens in the nineteenth century brought workers, machinery and new trade routes, gradually turning a quiet corner of Moulvibazar into a landscape of neat green rows.",
    "The tea industry drew families from across Bengal and beyond, creating communities whose food, language and daily routines still reflect that mixing. Estate workers rose before dawn, plucked leaves in the mist and carried their baskets to factories where the smell of drying tea filled the air. Around them, forests such as Lawachara survived, sheltering wildlife and reminding travellers that this is more than a cultivated landscape.",
    "Today Srimangal is best explored by bicycle, on foot and with time to spare. Estate roads, tea-stall cups, forest trails and the famous seven-layer tea all offer a way into local life. Visitors who respect workers, avoid waste and buy directly from small producers help keep the area's story rooted in the people who made it.",
  ],
  'lalbagh fort': [
    "Lalbagh Fort was never finished, and perhaps that is what makes it so compelling. Construction began in the seventeenth century under Prince Muhammad Azam Shah, but the project was abandoned when he left Dhaka, leaving behind gateways, a mosque, a hammam and the tomb of Bibi Pari. The incomplete complex became a permanent witness to the ambitions and uncertainties of Mughal rule.",
    "Over the following centuries the fort passed through changing hands and purposes. It survived sieges, neglect and the rapid growth of the city around it, while local stories attached themselves to its walls and gardens. The tomb of Bibi Pari became a place of respect and curiosity, and the grounds became a rare breathing space within the dense fabric of Old Dhaka.",
    "Today Lalbagh Fort is both a monument and a public garden, where families walk in the evening and students sketch the arches. A thoughtful visit means looking beyond the obvious photo spots: the water channels, the worn brickwork and the museum collections all reveal a city that has changed profoundly while keeping its past close at hand.",
  ],
  'ahsan manzil': [
    "Ahsan Manzil began as a riverside trading house before it became one of the most recognisable palaces in Dhaka. The Nawab family of Dhaka transformed the property into a grand residence facing the Buriganga, where business, politics and family life met under the same roof. Its pink walls and domed roof soon became part of the city's identity.",
    "From its rooms, the Nawabs witnessed the shifting fortunes of Bengal, the growth of river trade and the changing politics of the colonial era. The palace hosted guests, negotiations and celebrations, but it also suffered damage, neglect and the slow erosion of the family's influence. By the late twentieth century the building was a shadow of its former self.",
    "A careful restoration brought Ahsan Manzil back to public life as a museum, preserving its furniture, photographs and decorative details. Visitors can now step inside the palace and imagine the river traffic that once passed below its windows. The story is not only one of wealth and power, but of a city learning how to keep its heritage alive.",
  ],
  'jaflong': [
    "Jaflong sits where the Piyain River runs clear between green hills and stone-strewn banks. For generations, local communities have lived with the river's changing mood, collecting stones, fishing and moving produce by boat and foot. The borderland setting gave the area a distinctive culture shaped by trade, migration and the constant presence of the hills.",
    "Stone collection became central to Jaflong's economy, drawing labourers from nearby areas and changing the shape of the riverbed. At the same time, tea gardens and small settlements spread across the surrounding slopes, creating a landscape that was both beautiful and hard-working. The river has always been the source of life here, but also a reminder of how easily human demands can alter a natural system.",
    "Today Jaflong is a popular day trip from Sylhet, especially in the cooler months when the water is low and the hills are visible across the border. The best visits are not rushed. Walk away from the main souvenir stalls, watch how the river is used by local families and carry your waste out with you, so that the place stays as memorable for the next traveller.",
  ],
  'kuakata': [
    "Kuakata's name is often explained through the Rakhine word for a place of pilgrimage, and the town still carries the cultural imprint of the community that settled along this stretch of coast. For generations, fishing families and traders lived between the beach and the mangrove-lined rivers, adapting to a coastline that could be gentle at sunrise and dangerous during a storm.",
    "The area became known for offering both sunrise and sunset over the sea, a rare combination that began to attract travellers from the rest of Bangladesh. Small hotels and markets grew, and the annual festivals of the Rakhine community brought colour and music to the shore. Behind the tourist facilities, the old life of fishing, boat work and local cooking continued.",
    "A visit to Kuakata is most rewarding when it is spread across more than a single day. Walk the beach early, visit nearby villages, taste local food and learn something of the Rakhine heritage that gives the place its character. The coast here is generous, but it also asks visitors to travel lightly and respect the communities whose home it has always been.",
  ],
  'kuakata sea beach': [
    "Kuakata's name is often explained through the Rakhine word for a place of pilgrimage, and the town still carries the cultural imprint of the community that settled along this stretch of coast. For generations, fishing families and traders lived between the beach and the mangrove-lined rivers, adapting to a coastline that could be gentle at sunrise and dangerous during a storm.",
    "The area became known for offering both sunrise and sunset over the sea, a rare combination that began to attract travellers from the rest of Bangladesh. Small hotels and markets grew, and the annual festivals of the Rakhine community brought colour and music to the shore. Behind the tourist facilities, the old life of fishing, boat work and local cooking continued.",
    "A visit to Kuakata is most rewarding when it is spread across more than a single day. Walk the beach early, visit nearby villages, taste local food and learn something of the Rakhine heritage that gives the place its character. The coast here is generous, but it also asks visitors to travel lightly and respect the communities whose home it has always been.",
  ],
  'rangamati': [
    "Rangamati's landscape was reshaped dramatically by the Kaptai Dam in the twentieth century, when a large area of valley and forest was flooded to create Kaptai Lake. Villages disappeared beneath the water, families were resettled and the town took on a new geography defined by islands, bridges and boat routes. The lake is beautiful today, but its story begins with displacement as much as with engineering.",
    "Around the lake, diverse hill communities continue to live with strong ties to the land and water. Markets, weaving, fishing and small-scale farming remain part of everyday life, while the town of Rangamati serves as an administrative and cultural centre for the region. The suspension bridge, the palace grounds and the quiet temples all sit within a much larger story of identity and adaptation.",
    "Travellers often see Rangamati from a boat, which is a good place to start, but the town rewards those who stay a little longer. Visit the local markets, talk with guides and take an interest in the crafts and food of the hill communities. The lake is the entrance point, not the whole story; behind it lies a place that has learned to live with both beauty and loss.",
  ],
  'kaptai lake': [
    "Kaptai Lake was created when the Karnaphuli River was dammed in the mid-twentieth century, flooding a vast valley in the Chittagong Hill Tracts. The project brought electricity and change, but it also displaced thousands of families and submerged land that had belonged to hill communities for generations. The calm water that visitors see today hides a layered and difficult history.",
    "Over time, new settlements and boat routes formed around the lake, and islands emerged where hilltops had once risen above farmland. Fishermen, traders and ferry operators built their lives around the water, while the surrounding forested hills remained home to diverse communities. The lake became both a practical route and a symbol of the region's transformation.",
    "A boat journey across Kaptai Lake is the best way to appreciate its scale, but the experience is richer when paired with time on shore. Explore markets, visit villages with local guides and ask about the lives that were reshaped by the dam. The lake's beauty and its history belong together, and holding both in mind makes the journey more meaningful.",
  ],
  'somapura mahavihara': [
    "Somapura Mahavihara rose at Paharpur as one of the great monastic centres of ancient Bengal. From around the eighth century, it drew monks, scholars and pilgrims into a vast complex of cells, courtyards and shrines. Its scale reflected the wealth and ambition of the Pala rulers, but its daily life depended on the labour of farmers, artisans and ordinary families living around the monastery.",
    "For centuries the site was a place of learning and worship, connected to networks that stretched across South Asia and beyond. Then decline set in, the monastery was abandoned and its walls were gradually swallowed by earth and vegetation. Local memory kept the place alive even when its history was forgotten by the wider world, and its ruins became part of the landscape.",
    "Archaeological work revealed one of the most important surviving Buddhist sites in Bangladesh, and Somapura Mahavihara is now recognised as a World Heritage Site. Visitors should take time to walk the terraces, examine the terracotta panels and imagine the sounds of a working monastery. The ruins are impressive in themselves, but they become unforgettable when seen as the remains of a living community.",
  ],
  'sixty dome mosque': [
    "The Sixty Dome Mosque in Bagerhat is one of the most striking monuments of medieval Bengal. Built in the fifteenth century during the Bengal Sultanate, it formed part of a larger religious and civic complex established in the region. Its thick walls, repeated domes and spacious prayer hall were designed to serve a growing Muslim community and to express the confidence of the age.",
    "The building survived cyclones, changes in political power and the slow encroachment of the surrounding landscape. Local tradition links its construction to Khan Jahan Ali, whose influence shaped Bagerhat as a centre of settlement and worship. Over time the site was partly abandoned, but its massive structure endured, becoming an object of reverence and curiosity.",
    "Today the mosque is part of a World Heritage Site and remains active as a place of worship. Visitors should approach it with respect, covering carefully and observing the quiet of the prayer hall. Beyond the architecture, the surrounding tanks, tombs and ruins tell the story of a once-thriving city that has almost entirely disappeared into the green landscape.",
  ],
  'sonargaon': [
    "Sonargaon was once a centre of trade, administration and textile production in medieval Bengal. Its position near the old rivers made it a natural crossing point for goods, people and ideas, and it flourished under successive rulers. Muslin and other fine fabrics from this region were valued far beyond the subcontinent, linking local weavers to distant markets.",
    "Over time the rivers changed course, political power moved elsewhere and Sonargaon lost its commercial importance. What remained were the memories of craft and the quiet settlements around the old urban core. In the nineteenth and early twentieth centuries, wealthy merchant families built the ornate houses that still line Panam City, creating a new layer of history on top of the older one.",
    "Today Sonargaon is often visited for the folk art museum and the atmospheric ruins of Panam City. The decaying merchant houses are a reminder that prosperity can vanish as quickly as it arrives, while the museum preserves crafts that once made the region famous. A thoughtful visit connects the two: the grand facades and the everyday skills that supported them.",
  ],
  'padma bridge': [
    "The Padma Bridge began as an idea and a promise long before it became a structure across the river. For generations, the Padma's width and shifting currents separated communities, delayed trade and turned a simple journey into a difficult crossing. Ferries carried people, vehicles and goods, but they could not solve the fundamental barrier of the river.",
    "Planning, financing and construction turned the bridge into one of Bangladesh's largest infrastructure projects. Its spans now carry road and rail traffic, changing travel times and economic possibilities for the south and south-west. The project also brought debate and controversy, showing how a piece of engineering can become a national symbol as much as a transport route.",
    "Today the bridge is best understood as an invitation to new journeys rather than a monument in isolation. Travellers crossing it can look out at the river that shaped so much of the region's history, then continue to towns and villages that are now easier to reach. The story of the Padma is still being written by the people whose lives the crossing has changed.",
  ],
  'national martyrs memorial': [
    "The National Martyrs' Memorial stands at Savar as a national place of remembrance for those who died during the Liberation War of 1971. Its design, composed of tall concrete panels rising from a wide base, was chosen to convey strength, sacrifice and the determination of a nation seeking independence. Construction began in the 1970s and the memorial was completed in the early 1980s.",
    "The site is more than an architectural landmark. It is a place where families come to mourn, students learn about the war and visitors reflect on the cost of freedom. Each panel represents a stage in the struggle, while the surrounding gardens and reflective water create an atmosphere of stillness. The memorial's meaning depends on the rituals and memories that people bring to it.",
    "A visit should be made with time for quiet attention. Read the inscriptions, observe how Bangladeshis use the space and avoid treating it as only a backdrop for photographs. The memorial's power lies in its combination of scale and silence, and in the way it connects personal grief to a shared national story.",
  ],
};
