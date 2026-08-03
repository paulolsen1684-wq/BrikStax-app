// lib/modules/avatar/data/daily_content.dart
// Content pools for the Daily 5: trivia questions and collector tips.
// Picked deterministically by day-of-year so everyone sees the same one each
// day and it rotates predictably. 60 of each = ~2 months before any repeat.
//
// Facts spot-checked against current (2026) sources where they were likely to
// drift (e.g. largest set is now Sagrada Familia, not World Map).

class TriviaQuestion {
  final String question;
  final List<String> options;
  final int answerIndex;
  final String fact; // shown after answering
  const TriviaQuestion(this.question, this.options, this.answerIndex, this.fact);
}

class DailyContent {
  DailyContent._();

  static const List<TriviaQuestion> trivia = [
    TriviaQuestion(
      'What year was the modern LEGO minifigure introduced?',
      ['1969', '1978', '1985', '1992'], 1,
      'The modern minifigure debuted in 1978 — a smiling police officer in Set 600.'),
    TriviaQuestion(
      'Who designed the original LEGO minifigure?',
      ['Ole Kirk Christiansen', 'Jens Nygaard Knudsen', 'Godtfred Kirk', 'Niels Milan Pedersen'], 1,
      'Jens Nygaard Knudsen designed the 1978 minifigure with movable arms and legs.'),
    TriviaQuestion(
      'Which LEGO set is the largest by piece count (2026)?',
      ['World Map', 'Sagrada Familia', 'Titanic', 'Eiffel Tower'], 1,
      'LEGO Architecture 21065 Sagrada Familia holds the record at 12,060 pieces.'),
    TriviaQuestion(
      'What does "MISB" mean to a LEGO collector?',
      ['Mint In Sealed Box', 'Made In Small Batches', 'Multiple Identical Sets', 'Model In Standard Build'], 0,
      'MISB = Mint In Sealed Box — the gold standard for resale value.'),
    TriviaQuestion(
      'Which is LEGO\'s best-selling licensed theme of all time?',
      ['Harry Potter', 'Star Wars', 'Marvel', 'Batman'], 1,
      'LEGO Star Wars launched in 1999 and remains the top licensed theme.'),
    TriviaQuestion(
      'What is the "clutch power" of a LEGO brick?',
      ['Its color fastness', 'How tightly bricks grip', 'Its drop resistance', 'Paint adhesion'], 1,
      'Clutch power is the friction grip holding bricks together — refined since 1958.'),
    TriviaQuestion(
      'Which retired theme is most prized by investors?',
      ['Bionicle', 'Modular Buildings', 'Friends', 'Duplo'], 1,
      'Retired Modular Buildings like Cafe Corner routinely multiply their retail price.'),
    TriviaQuestion(
      'What does GWP stand for in LEGO promotions?',
      ['Gift With Purchase', 'Guaranteed Wholesale Price', 'Global Web Promo', 'Grand Winner Prize'], 0,
      'GWP = Gift With Purchase — free sets that often gain strong secondary value.'),
    TriviaQuestion(
      'The name "LEGO" comes from which Danish phrase?',
      ['"Leg godt" (play well)', '"Lego sten" (toy stone)', '"Lille gods" (small goods)', '"Lege gud" (good game)'], 0,
      '"LEGO" is from "leg godt" — Danish for "play well."'),
    TriviaQuestion(
      'What occupation was the very first minifigure?',
      ['Astronaut', 'Police Officer', 'Firefighter', 'Knight'], 1,
      'The first minifigure (1978, Set 600) was a smiling police officer.'),
    TriviaQuestion(
      'In what year did LEGO Star Wars first launch?',
      ['1997', '1999', '2002', '2005'], 1,
      'LEGO Star Wars debuted in 1999, breaking LEGO\'s old "no war themes" rule.'),
    TriviaQuestion(
      'Which tool ended decades of thumbnail pain for builders?',
      ['Brick separator', 'Stud opener', 'Plate lifter', 'Grip clamp'], 0,
      'The brick separator arrived in 1989 — every AFOL owns at least one.'),
    TriviaQuestion(
      'What does "AFOL" stand for?',
      ['Adult Fan Of LEGO', 'All-Format Online LEGO', 'Annual Festival Of LEGO', 'Advanced Friends Of LEGO'], 0,
      'AFOL = Adult Fan Of LEGO — the global grown-up collector community.'),
    TriviaQuestion(
      'In what year was the LEGO company founded?',
      ['1916', '1932', '1949', '1958'], 1,
      'Ole Kirk Christiansen founded LEGO in 1932 in Billund, Denmark.'),
    TriviaQuestion(
      'When was the LEGO brick (in its modern form) patented?',
      ['1949', '1958', '1965', '1972'], 1,
      'The modern stud-and-tube brick was patented January 28, 1958.'),
    TriviaQuestion(
      'What were LEGO\'s first products, before plastic bricks?',
      ['Board games', 'Wooden toys', 'Tin cars', 'Puzzles'], 1,
      'LEGO began as a wooden-toy maker in 1932 before moving to plastic.'),
    TriviaQuestion(
      'What theme introduced the first pirate minifigures?',
      ['Pirates (1989)', 'Adventurers', 'Vikings', 'Castle'], 0,
      'The Pirates theme in 1989 brought the first peg-legs, hooks, and detailed faces.'),
    TriviaQuestion(
      'Which LEGO theme features buildable robotic creatures with canisters?',
      ['Bionicle', 'Exo-Force', 'Hero Factory', 'Galidor'], 0,
      'Bionicle (2001) revived LEGO\'s fortunes with its canister-packaged figures.'),
    TriviaQuestion(
      'What is a "MOC" in LEGO culture?',
      ['My Own Creation', 'Master Of Color', 'Mint Original Carton', 'Modular Open Concept'], 0,
      'MOC = My Own Creation — a custom build not based on an official set.'),
    TriviaQuestion(
      'Roughly how tall is a standard minifigure?',
      ['2 bricks', '4 bricks', '6 bricks', '8 bricks'], 1,
      'A minifigure stands about four bricks tall.'),
    TriviaQuestion(
      'Which licensed theme came FIRST?',
      ['Harry Potter', 'Star Wars', 'Marvel', 'Indiana Jones'], 1,
      'Star Wars (1999) was LEGO\'s first major licensed theme; Harry Potter followed in 2001.'),
    TriviaQuestion(
      'What color were the earliest LEGO bricks primarily?',
      ['Red and white', 'Blue and yellow', 'Green and black', 'Grey and tan'], 0,
      'Early Automatic Binding Bricks were mainly red and white.'),
    TriviaQuestion(
      'What does "NISB" add over "MISB"?',
      ['Nothing, same thing', 'New (never owned)', 'Numbered edition', 'No instructions'], 1,
      'NISB = New In Sealed Box — emphasizes the set is brand-new, never owned.'),
    TriviaQuestion(
      'Which LEGO line is aimed at the youngest builders?',
      ['Duplo', 'Juniors', 'Creator', 'Technic'], 0,
      'Duplo bricks are twice the size of standard bricks — safer for toddlers.'),
    TriviaQuestion(
      'The LEGO Technic theme is known for what?',
      ['Glow bricks', 'Gears and mechanisms', 'Soft parts', 'Electronics only'], 1,
      'Technic uses beams, pins, gears, and axles for functional machines.'),
    TriviaQuestion(
      'What is the rarest minifigure ever made (gold)?',
      ['14k gold C-3PO', 'Solid silver R2-D2', 'Platinum Vader', 'Bronze Yoda'], 0,
      'A solid 14k gold C-3PO — only five were made in 2007 — is among the rarest.'),
    TriviaQuestion(
      'What does "retired" mean for a LEGO set?',
      ['It breaks easily', 'LEGO ended production', 'It lost a license', 'It was recalled'], 1,
      'Retirement means production stopped — scarcity then drives the aftermarket.'),
    TriviaQuestion(
      'Which modular building was the FIRST released?',
      ['Cafe Corner', 'Green Grocer', 'Market Street', 'Fire Brigade'], 0,
      'Cafe Corner (2007) launched the beloved Modular Buildings series.'),
    TriviaQuestion(
      'What flagship space set anchors the UCS Star Wars line?',
      ['Millennium Falcon', 'Star Destroyer', 'X-Wing', 'Slave I'], 0,
      'The UCS Millennium Falcon is the line\'s most iconic centerpiece.'),
    TriviaQuestion(
      'Which country is LEGO headquartered in?',
      ['Sweden', 'Denmark', 'Germany', 'Netherlands'], 1,
      'LEGO is based in Billund, Denmark — also home to the first LEGOLAND.'),
    TriviaQuestion(
      'What year did the first LEGOLAND park open?',
      ['1968', '1975', '1982', '1990'], 0,
      'LEGOLAND Billund opened in 1968, near the LEGO factory.'),
    TriviaQuestion(
      'What is "BURP" slang for among builders?',
      ['Big Ugly Rock Piece', 'Built-Up Resin Part', 'Brick Under Repair', 'Basic Universal Round Plate'], 0,
      'BURP = Big Ugly Rock Piece, a large pre-molded rock element.'),
    TriviaQuestion(
      'Which theme is a LEGO original (not licensed)?',
      ['Ninjago', 'Marvel', 'Harry Potter', 'Jurassic World'], 0,
      'Ninjago is a LEGO original IP, launched in 2011 and still going strong.'),
    TriviaQuestion(
      'What does a "sigfig" represent?',
      ['Signature minifigure (you)', 'Significant figure', 'Single-piece figure', 'Signed figure'], 0,
      'A sigfig is a minifigure a fan uses to represent themselves.'),
    TriviaQuestion(
      'Which licensed car theme makes 1:1 buildable models like the Bugatti?',
      ['Technic', 'Speed Champions', 'Racers', 'City'], 0,
      'LEGO Technic produced the life-scale-detailed Bugatti Chiron and others.'),
    TriviaQuestion(
      'Speed Champions sets are built at roughly what scale?',
      ['Minifig (6-8 wide)', '1:18', '1:24', '1:43'], 0,
      'Speed Champions cars are minifigure-scale, about 6-8 studs wide.'),
    TriviaQuestion(
      'What\'s the term for a sealed set kept purely as an investment?',
      ['Vault piece', 'Sealed hold', 'Grail', 'Mint flip'], 1,
      'Collectors often "hold sealed" — keeping MISB sets purely to appreciate.'),
    TriviaQuestion(
      'A collector\'s "grail" is best described as what?',
      ['A cheap common set', 'Their most-wanted set', 'A damaged box', 'A duplicate'], 1,
      'A grail is the set a collector most dreams of owning.'),
    TriviaQuestion(
      'Which LEGO theme recreates real-world landmarks in detail?',
      ['Architecture', 'City', 'Creator', 'Friends'], 0,
      'LEGO Architecture focuses on famous buildings and skylines.'),
    TriviaQuestion(
      'What does "PAB" stand for at LEGO stores?',
      ['Pick A Brick', 'Pay And Build', 'Premium Adult Box', 'Plastic Assembly Bin'], 0,
      'PAB = Pick A Brick, the in-store wall of loose elements.'),
    TriviaQuestion(
      'Which theme features the wizarding world?',
      ['Harry Potter', 'Elves', 'Hidden Side', 'Nexo Knights'], 0,
      'The Harry Potter theme launched alongside the first film in 2001.'),
    TriviaQuestion(
      'What is "greebling" in LEGO building?',
      ['Fine surface detailing', 'Color sorting', 'Gluing bricks', 'Photo editing'], 0,
      'Greebling adds small greeble parts for intricate sci-fi surface texture.'),
    TriviaQuestion(
      'Which sells for more, typically: a sealed or opened retired set?',
      ['Opened', 'Sealed', 'Same', 'Depends only on theme'], 1,
      'Sealed retired sets almost always command a premium over opened ones.'),
    TriviaQuestion(
      'What does "SNOT" mean as a building technique?',
      ['Studs Not On Top', 'Small New Order Tile', 'Sorted Naturally Over Time', 'Single Nub On Top'], 0,
      'SNOT = Studs Not On Top, building sideways for smooth or detailed surfaces.'),
    TriviaQuestion(
      'Which theme blends LEGO with a video-game tie-in and physical figures?',
      ['LEGO Dimensions', 'LEGO Worlds', 'LEGO Universe', 'LEGO Life'], 0,
      'LEGO Dimensions (2015) merged physical minifigs with a console game.'),
    TriviaQuestion(
      'What is the plastic most standard LEGO bricks are made from?',
      ['PVC', 'ABS', 'PET', 'Nylon'], 1,
      'Most bricks are ABS plastic, prized for durability and color retention.'),
    TriviaQuestion(
      'What\'s a "polybag" in LEGO terms?',
      ['A small bagged set', 'A storage box', 'A part sorter', 'A display case'], 0,
      'A polybag is a small promotional set packaged in a flat plastic bag.'),
    TriviaQuestion(
      'Which LEGO theme is built around ninjas and elemental dragons?',
      ['Ninjago', 'Chima', 'Exo-Force', 'Monkie Kid'], 0,
      'Ninjago centers on elemental ninja and their dragons.'),
    TriviaQuestion(
      'The first LEGO female minifigure was what profession?',
      ['Nurse', 'Teacher', 'Pilot', 'Scientist'], 0,
      'A nurse, released about two months after the first (police officer) minifig in 1978.'),
    TriviaQuestion(
      'What does "TLG" abbreviate?',
      ['The LEGO Group', 'Total LEGO Grade', 'Tan LEGO Gear', 'Top LEGO Grail'], 0,
      'TLG = The LEGO Group, the company\'s formal name.'),
    TriviaQuestion(
      'Which theme features modular street-level shops and apartments for adults?',
      ['Modular Buildings', 'City', 'Creator 3-in-1', 'Friends'], 0,
      'The Modular Buildings line targets adult collectors with detailed interiors.'),
    TriviaQuestion(
      'What is "brick rot" or discoloration usually caused by?',
      ['UV / sunlight', 'Cold', 'Humidity only', 'Air pressure'], 0,
      'UV exposure yellows and degrades ABS — keep sets out of direct sun.'),
    TriviaQuestion(
      'Which LEGO line lets you build art mosaics of portraits and logos?',
      ['LEGO Art', 'LEGO Dots', 'LEGO Mosaic', 'LEGO Frames'], 0,
      'LEGO Art produces large brick-built mosaic wall pieces.'),
    TriviaQuestion(
      'What does "EOL" mean for a set?',
      ['End Of Life', 'Edition Of LEGO', 'Extra Online Listing', 'Early Owner Lot'], 0,
      'EOL = End Of Life, another way to say a set is being retired.'),
    TriviaQuestion(
      'Which theme recreates Marvel and DC superheroes?',
      ['Super Heroes', 'Ultra Agents', 'Hero Factory', 'Nexo Knights'], 0,
      'LEGO Super Heroes covers both Marvel and DC licensed sets.'),
    TriviaQuestion(
      'What is the best site for checking real LEGO resale values?',
      ['eBay sold listings', 'Retail price tags', 'LEGO.com only', 'Social media'], 0,
      'eBay "sold" (not active) listings show what sets actually trade for.'),
    TriviaQuestion(
      'Which LEGO theme is themed around Norse-style monkey legends?',
      ['Monkie Kid', 'Chima', 'Elves', 'Hidden Side'], 0,
      'Monkie Kid draws on the Chinese legend of the Monkey King.'),
    TriviaQuestion(
      'What does "PPP" mean when comparing sets?',
      ['Price Per Piece', 'Parts Per Pack', 'Premium Pricing Plan', 'Plastic Purity Percent'], 0,
      'PPP = Price Per Piece, a quick value yardstick (lower is better value).'),
    TriviaQuestion(
      'Which iconic set type recreates a working amusement-park ride?',
      ['Fairground / Creator Expert', 'City Square', 'Friends Park', 'Junior Fair'], 0,
      'The Creator Expert Fairground series features motorized working rides.'),
    TriviaQuestion(
      'What\'s the collector term for buying multiples to resell later?',
      ['Flipping', 'Hoarding', 'Stacking', 'Cornering'], 0,
      'Flipping is buying sets (often to-be-retired) to resell at a profit.'),
    TriviaQuestion(
      'Which LEGO theme features buildable botanical flowers and plants?',
      ['Botanicals', 'Friends', 'Creator', 'Dots'], 0,
      'The Botanicals line offers buildable bouquets and plants for display.'),
  ];

  static const List<String> tips = [
    'Store sealed sets upright, away from sunlight — UV fading kills box value.',
    'Photograph the box barcode and back when you buy — proof of authenticity helps resale.',
    'Retiring sets often spike 6-12 months AFTER retirement, not immediately.',
    'Bulk minifigs from a set can sometimes out-value the set sold whole.',
    'Keep instructions and inner bags — a complete used set beats a bare one.',
    'Watch LEGO\'s "retiring soon" page; it\'s your free investment radar.',
    'Modular Buildings are the bluest-chip LEGO investment — slow, steady, reliable.',
    'A crushed box can drop resale 20-40%. Storage matters as much as rarity.',
    'GWP exclusives have no retail price, so the secondary market sets their value.',
    'eBay "sold" listings (not "active") show what sets ACTUALLY trade for.',
    'Double-box for shipping — corners are the first thing buyers inspect.',
    'Theme anniversaries (Star Wars May 4th) often bring price bumps on classics.',
    'Buy two of a grail set if you can: one to build, one to keep sealed.',
    'Minifigure-only lots can be more profitable per-dollar than full sets.',
    'Check piece counts before buying loose — missing parts tank used value.',
    'Sets with licensed themes (Star Wars, Marvel) often retire faster than evergreen lines.',
    'Sun-yellowing is permanent. Display behind UV-filtering glass if possible.',
    'Sort spare parts by color, not shape — most builders search by color first.',
    'A sealed box with a price sticker residue can lose value; remove gently if at all.',
    'Smaller "impulse" sets sometimes appreciate more by percentage than big flagships.',
    'Keep silica gel packs near sealed boxes to fight humidity damage.',
    'Print-on-tile minifig parts wear with handling — store loose figs in compartment trays.',
    'The LEGO VIP program gives points and early access — worth it for frequent buyers.',
    'Watch for "double VIP points" weekends to stack value on planned purchases.',
    'Sealed Star Wars UCS sets are among the most reliable long-term holds.',
    'Damaged instructions can be replaced with free PDFs on LEGO.com for resale completeness.',
    'Avoid stacking heavy sets on sealed boxes — crushed corners are forever.',
    'Seasonal sets (winter village, Halloween) often spike each year in-season.',
    'When flipping, factor eBay + payment fees (~13%) into your target sell price.',
    'Retired Creator Expert vehicles (like the VW Beetle) tend to climb steadily.',
    'List sealed sets with clear corner photos — buyers pay for visible mint condition.',
    'A complete minifigure with all accessories sells far better than a partial one.',
    'Keep a spreadsheet (or use BrikStax) of paid vs. current value to spot your best flips.',
    'Buy during sales, hold through retirement — the patient collector wins.',
    'Original boxes age; archival sleeves protect high-value sealed sets.',
    'Promo/employee-exclusive sets can be sleeper investments — track them.',
    'Check the set\'s minifigure exclusivity — figs only in one set drive demand.',
    'Don\'t open a sealed set you might sell — opened value is usually far lower.',
    'Heavy themes like Technic have niche but loyal resale demand.',
    'Watch currency and import fees if buying sets from overseas sellers.',
    'Re-released sets can crash the value of an original — check before paying a premium.',
    'Group small polybags into lots to make shipping worth the effort.',
    'Brickset and BrickLink are your friends for verifying set numbers and parts.',
    'The best buy-low window is often right at a retail clearance before retirement.',
    'Keep your eBay feedback high — it directly affects what buyers will pay you.',
    'Store minifigures out of direct light; printed faces fade over years.',
    'Set a target sell price before you buy — discipline beats hoping for a moonshot.',
    'A "sealed but shelf-worn" set still beats opened; note condition honestly.',
    'Track which of your sets are nearing retirement — that\'s your sell-or-hold signal.',
    'Bundle a popular set with a matching polybag to stand out in listings.',
    'High-piece flagship sets are slow movers — price for patience, not a quick flip.',
    'Watch for factory sealing differences; collectors scrutinize tape and seams.',
    'Holiday season (Nov-Dec) is peak demand — time your sales accordingly.',
    'Keep receipts for expensive sets — proof of purchase reassures big buyers.',
    'Minifig accessories (capes, weapons) lost easily — bag them with the figure.',
    'A set\'s value often jumps the moment LEGO confirms it\'s retiring — watch news.',
    'Don\'t overpay on hype; check the 90-day sold average, not the asking prices.',
    'Clean used pieces gently with mild soap and air-dry — never a dishwasher.',
    'Diversify: don\'t sink everything into one theme in case its demand cools.',
    'Patience is the collector\'s edge — the market rewards those who can wait.',
  ];

  /// Day-of-year index so content rotates daily and is the same for everyone.
  static int _dayIndex() {
    final now = DateTime.now();
    final start = DateTime(now.year, 1, 1);
    return now.difference(start).inDays;
  }

  static TriviaQuestion todayTrivia() => trivia[_dayIndex() % trivia.length];
  static String todayTip() => tips[_dayIndex() % tips.length];
}
