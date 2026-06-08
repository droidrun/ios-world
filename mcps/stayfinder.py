"""StayFinder MCP — Airbnb-style stays: explore, search, book, checkout, chat.

Bundle: com.iosworld.benchmark.stayfinder

IDs (bnb.* namespace, see StayFinder/ source):
  Explore: bnb.explore.searchBar.
  Search: bnb.search.{destinationField, startDate, endDate, guestsStepper,
          apply, close, suggestion.<slug>}.
  Detail: bnb.detail.{screen, reserve, messageHost}.
  Booking: bnb.booking.{screen, startDate, endDate, guestsStepper, continue}.
  Checkout: bnb.checkout.{card, cardPicker, summary, confirmButton,
                          confirmLabel, confirmSwitch, mybank}.
  Chat: bnb.chat.{screen, input, send, messages, message.<id>, transcriptSummary}.
  Inbox: bnb.inbox.thread.<listing_id>.
  Profile: bnb.profile.{connections, hosting, notifications, pastTrips,
                        settings.<i>}.
  Trips: bnb.trips.upcomingHeader.
  Hosting: bnb.hosting.sampleListing.
  Lists: bnb.connections.<i>, bnb.notifications.<i>.

Naming: <slug> and <listing_id> are lowercase destination/listing slugs
read live from the UI tree. <i> indices for profile-settings /
connections / notifications come from observe().
"""

import sys, pathlib, re
from typing import Optional
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))

from fastmcp import FastMCP
from simulator_base import SimulatorBridge
import tool_support as ts

mcp = FastMCP("StayFinder")

BUNDLE_ID = "com.iosworld.benchmark.stayfinder"

TAB_MAP = {
    "explore":   "Explore", "search": "Explore",
    "wishlists": "Wishlists", "favorites": "Wishlists",
    "trips":     "Trips",
    "inbox":     "Messages", "messages": "Messages",
    "profile":   "Profile",
}

TAB_MARKERS = {
    "explore": ("bnb.explore.searchBar",),
    "search": ("bnb.explore.searchBar",),
    "wishlists": ("bnb.wishlist.add", "bnb.wishlist."),
    "favorites": ("bnb.wishlist.add", "bnb.wishlist."),
    "trips": ("bnb.trips.upcomingHeader", "bnb.trips.getStarted", "bnb.trips.pastTripsPrompt"),
    "inbox": ("bnb.inbox.search", "bnb.inbox.thread."),
    "messages": ("bnb.inbox.search", "bnb.inbox.thread."),
    "profile": ("bnb.profile.notifications", "bnb.profile.connections", "bnb.profile.hosting"),
}


_LISTING_CATALOG = [
    ('stay-beach', 'Clifftop retreat on Catalina', 'Catalina Island, CA'),
    ('stay-soma', 'Big Sur ridge cabin', 'Big Sur, CA'),
    ('stay-cabin', 'Cove-view guest suite', 'Catalina Island, CA'),
    ('stay-paris', 'Forest hideaway near the redwoods', 'Sequoia, CA'),
    ('stay-london', 'Valley overlook studio', 'Carmel Valley, CA'),
    ('stay-asheville', 'Redwood canyon room', 'Sequoia, CA'),
    ('stay-chelsea-hotel', 'Boutique harbor stay', 'Avalon, CA'),
    ('stay-midtown-hotel', 'Weekend stay above the bay', 'Monterey Bay, CA'),
    ('stay-soho-suite', 'Hillside suite with ocean views', 'Catalina Island, CA'),
    ('stay-seoul-hanok', 'Bukchon hanok loft', 'Seoul, South Korea'),
    ('stay-seoul-gangnam', 'Gangnam design apartment', 'Seoul, South Korea'),
    ('stay-tokyo-shibuya', 'Shibuya studio with soaking tub', 'Tokyo, Japan'),
    ('stay-lisbon-alfama', 'Alfama tile apartment', 'Lisbon, Portugal'),
    ('stay-tahoe', 'Lake Tahoe A-frame', 'Lake Tahoe, CA'),
    ('stay-joshua-tree', 'Desert dome retreat', 'Joshua Tree, CA'),
    ('stay-savannah', 'Historic district row house', 'Savannah, GA'),
    ('stay-austin', 'South Congress bungalow', 'Austin, TX'),
    ('stay-portland', 'Alberta Arts loft', 'Portland, OR'),
    ('stay-miami', 'Art Deco studio on the beach', 'Miami Beach, FL'),
    ('stay-napa', 'Vineyard cottage', 'Napa Valley, CA'),
    ('stay-santa-fe', 'Adobe casita with courtyard', 'Santa Fe, NM'),
    ('stay-hudson', 'Hudson Valley farmhouse', 'Hudson Valley, NY'),
    ('stay-cape-cod', 'Shingled seaside cottage', 'Cape Cod, MA'),
    ('stay-barcelona', 'Gothic Quarter apartment', 'Barcelona, Spain'),
    ('stay-amsterdam', 'Canal house studio', 'Amsterdam, Netherlands'),
    ('stay-bali', 'Rice terrace villa', 'Ubud, Bali'),
    ('stay-kyoto', 'Machiya townhouse', 'Kyoto, Japan'),
    ('stay-marrakech', 'Medina riad with courtyard', 'Marrakech, Morocco'),
    ('stay-copenhagen', 'Nyhavn harbor flat', 'Copenhagen, Denmark'),
    ('stay-buenos-aires', 'Palermo Soho townhouse', 'Buenos Aires, Argentina'),
    ('stay-dubrovnik', 'Old Town stone apartment', 'Dubrovnik, Croatia'),
    ('stay-amalfi', 'Cliffside lemon house', 'Amalfi Coast, Italy'),
    ('stay-reykjavik', 'Harbor loft with northern views', 'Reykjavik, Iceland'),
    ('stay-bangkok', 'Riverside studio with pool', 'Bangkok, Thailand'),
    ('stay-santorini', 'Caldera cave suite', 'Santorini, Greece'),
    ('stay-paris-marais', 'Le Marais loft with courtyard', 'Paris, France'),
    ('stay-paris-montmartre', 'Montmartre artist studio', 'Paris, France'),
    ('stay-paris-st-germain', 'Saint-Germain pied-a-terre', 'Paris, France'),
    ('stay-london-notting', 'Notting Hill terrace flat', 'London, UK'),
    ('stay-london-shoreditch', 'Shoreditch warehouse conversion', 'London, UK'),
    ('stay-london-camden', 'Camden market townhouse', 'London, UK'),
    ('stay-nyc-west-village', 'West Village brownstone floor', 'New York, NY'),
    ('stay-nyc-williamsburg', 'Williamsburg loft with skyline view', 'New York, NY'),
    ('stay-nyc-harlem', 'Harlem brownstone garden suite', 'New York, NY'),
    ('stay-rome-trastevere', 'Trastevere terrace apartment', 'Rome, Italy'),
    ('stay-rome-monti', 'Monti neighborhood studio', 'Rome, Italy'),
    ('stay-sydney-bondi', 'Bondi Beach apartment', 'Sydney, Australia'),
    ('stay-sydney-surry', 'Surry Hills terrace house', 'Sydney, Australia'),
    ('stay-cdmx-condesa', 'Condesa art deco apartment', 'Mexico City, Mexico'),
    ('stay-cdmx-roma', 'Roma Norte courtyard studio', 'Mexico City, Mexico'),
    ('stay-seoul-itaewon', 'Itaewon rooftop apartment', 'Seoul, South Korea'),
    ('stay-tokyo-asakusa', 'Asakusa temple-side flat', 'Tokyo, Japan'),
    ('stay-tokyo-shimokita', 'Shimokitazawa vintage loft', 'Tokyo, Japan'),
    ('stay-lisbon-belem', 'Belem riverside studio', 'Lisbon, Portugal'),
    ('stay-bigsur-treehouse', 'Coastal treehouse cabin', 'Big Sur, CA'),
    ('stay-tahoe-ski', 'Ski-in lodge suite', 'Lake Tahoe, CA'),
    ('stay-barcelona-gracia', 'Gracia neighborhood flat', 'Barcelona, Spain'),
    ('stay-amsterdam-jordaan', 'Jordaan canal houseboat', 'Amsterdam, Netherlands'),
    ('stay-bali-canggu', 'Canggu surf villa', 'Canggu, Bali'),
    ('stay-kyoto-arashiyama', 'Arashiyama bamboo retreat', 'Kyoto, Japan'),
    ('stay-ba-san-telmo', 'San Telmo tango loft', 'Buenos Aires, Argentina'),
    ('stay-amalfi-ravello', 'Ravello hilltop garden suite', 'Amalfi Coast, Italy'),
    ('stay-bangkok-sukhumvit', 'Sukhumvit sky loft', 'Bangkok, Thailand'),
    ('stay-savannah-forsyth', 'Forsyth Park Victorian', 'Savannah, GA'),
    ('stay-austin-east', 'East Austin container home', 'Austin, TX'),
    ('stay-miami-wynwood', 'Wynwood arts district studio', 'Miami Beach, FL'),
    ('stay-hk-central', 'Central harbor-view apartment', 'Hong Kong'),
    ('stay-sg-chinatown', 'Chinatown heritage shophouse', 'Singapore'),
    ('stay-lima-miraflores', 'Miraflores oceanfront studio', 'Lima, Peru'),
    ('stay-la-silverlake', 'Silver Lake hillside bungalow', 'Los Angeles, CA'),
    ('stay-la-dtla', 'Arts District warehouse loft', 'Los Angeles, CA'),
    ('stay-busan-haeundae', 'Haeundae beachfront suite', 'Busan, South Korea'),
    ('stay-sf-mission', 'Mission District Victorian flat', 'San Francisco, CA'),
    ('stay-sf-hayes', 'Hayes Valley garden apartment', 'San Francisco, CA'),
    ('stay-sf-nob-hill', 'Nob Hill classic apartment', 'San Francisco, CA'),
    ('exp-pastry', 'Chef-led tasting workshop', 'Carmel-by-the-Sea, CA'),
    ('exp-sail', 'Sunset Sail on the Bay', 'Barcelona, ES'),
    ('exp-seoul-market', 'Seoul night market tasting', 'Seoul, South Korea'),
    ('exp-tokyo-coffee', 'Tokyo coffee and kissaten crawl', 'Tokyo, Japan'),
    ('exp-food', 'Coastal taco tasting', 'San Diego, CA'),
    ('exp-barcelona-tapas', 'Barcelona tapas crawl', 'Barcelona, Spain'),
    ('exp-bali-terrace', 'Bali rice terrace walk', 'Ubud, Bali'),
    ('exp-kyoto-temple', 'Kyoto temple morning', 'Kyoto, Japan'),
    ('exp-sf-mission', 'Mission District food crawl', 'San Francisco, CA'),
    ('exp-sf-chinatown', 'Chinatown dim sum morning', 'San Francisco, CA'),
    ('exp-cdmx-food', 'Mexico City taco and mezcal tour', 'Mexico City, Mexico'),
    ('exp-paris-market', 'Paris morning market breakfast', 'Paris, France'),
    ('exp-hk-dimsum', 'Hong Kong dim sum breakfast route', 'Hong Kong'),
    ('exp-lima-ceviche', 'Lima ceviche tasting walk', 'Lima, Peru'),
    ('service-chef', 'Private chef dinner setup', 'Big Sur, CA'),
    ('service-photo', 'Vacation photo session', 'Catalina Island, CA'),
    ('service-seoul-photo', 'Seoul evening photo route', 'Seoul, South Korea'),
    ('service-lisbon-chef', 'Portuguese dinner at your stay', 'Lisbon, Portugal'),
    ('service-massage', 'In-home massage reset', 'Monterey Bay, CA'),
    ('service-sf-wine', 'Private sommelier tasting', 'San Francisco, CA'),
    ('service-cdmx-chef', 'Private Mexican chef dinner', 'Mexico City, Mexico'),
    ('service-tokyo-concierge', 'Tokyo dining concierge', 'Tokyo, Japan'),
    ('service-yoga', 'Private yoga session', 'Ubud, Bali'),
    ('stay-sf-mission', 'Mission District sunny flat', 'San Francisco, CA'),
    ('stay-sf-marina', 'Marina harbor-view apartment', 'San Francisco, CA'),
    ('stay-sf-hayes', 'Hayes Valley designer studio', 'San Francisco, CA'),
    ('stay-la-silver-lake', 'Silver Lake hillside studio', 'Los Angeles, CA'),
    ('stay-la-venice', 'Venice Beach bungalow', 'Los Angeles, CA'),
    ('stay-la-dtla', 'Arts District warehouse loft', 'Los Angeles, CA'),
    ('stay-nola-garden', 'Garden District shotgun house', 'New Orleans, LA'),
    ('stay-nola-quarter', 'French Quarter courtyard suite', 'New Orleans, LA'),
    ('stay-nola-bywater', 'Bywater artist cottage', 'New Orleans, LA'),
    ('stay-charleston-battery', 'Battery row house with garden', 'Charleston, SC'),
    ('stay-charleston-king', 'King Street carriage house', 'Charleston, SC'),
    ('stay-berlin-mitte', 'Mitte gallery loft', 'Berlin, Germany'),
    ('stay-berlin-kreuzberg', 'Kreuzberg canal apartment', 'Berlin, Germany'),
    ('stay-berlin-neukolln', 'Neukolln rooftop flat', 'Berlin, Germany'),
    ('stay-tulum-beach', 'Beachfront palapa suite', 'Tulum, Mexico'),
    ('stay-tulum-jungle', 'Jungle treehouse retreat', 'Tulum, Mexico'),
    ('stay-capetown-bo-kaap', 'Bo-Kaap colorful townhouse', 'Cape Town, South Africa'),
    ('stay-capetown-camps', 'Camps Bay ocean villa', 'Cape Town, South Africa'),
    ('stay-chiangmai-old', 'Old City teak house', 'Chiang Mai, Thailand'),
    ('stay-chiangmai-nimman', 'Nimman design studio', 'Chiang Mai, Thailand'),
    ('stay-edinburgh-old', 'Old Town tenement flat', 'Edinburgh, Scotland'),
    ('stay-edinburgh-stockbridge', 'Stockbridge garden flat', 'Edinburgh, Scotland'),
    ('stay-maui-paia', 'Paia surf cottage', 'Maui, HI'),
    ('stay-maui-wailea', 'Wailea ocean suite', 'Maui, HI'),
    ('stay-nashville-gulch', 'The Gulch modern loft', 'Nashville, TN'),
    ('stay-nashville-east', 'East Nashville cottage', 'Nashville, TN'),
    ('stay-sedona-red-rock', 'Red rock view casita', 'Sedona, AZ'),
    ('stay-sedona-creek', 'Oak Creek canyon cabin', 'Sedona, AZ'),
    ('stay-cartagena-walled', 'Walled City colonial apartment', 'Cartagena, Colombia'),
    ('stay-cartagena-getsemani', 'Getsemani street-art studio', 'Cartagena, Colombia'),
    ('stay-hanoi-old-quarter', 'Old Quarter lantern house', 'Hanoi, Vietnam'),
    ('stay-hanoi-west-lake', 'West Lake lakeside studio', 'Hanoi, Vietnam'),
    ('stay-tokyo-roppongi', 'Roppongi Hills designer flat', 'Tokyo, Japan'),
    ('stay-tokyo-nakameguro', 'Nakameguro canal apartment', 'Tokyo, Japan'),
    ('stay-tokyo-shinjuku', 'Shinjuku high-rise studio', 'Tokyo, Japan'),
    ('stay-tokyo-yanaka', 'Yanaka traditional townhouse', 'Tokyo, Japan'),
    ('stay-tokyo-daikanyama', 'Daikanyama loft with terrace', 'Tokyo, Japan'),
    ('stay-tokyo-koenji', 'Koenji vintage district room', 'Tokyo, Japan'),
    ('stay-paris-bastille', 'Bastille artist loft', 'Paris, France'),
    ('stay-paris-latin-quarter', "Latin Quarter book-lover's flat", 'Paris, France'),
    ('stay-paris-canal', 'Canal Saint-Martin studio', 'Paris, France'),
    ('stay-paris-belleville', 'Belleville panoramic penthouse', 'Paris, France'),
    ('stay-paris-opera', 'Opéra district classic apartment', 'Paris, France'),
    ('stay-paris-pigalle', 'South Pigalle boutique room', 'Paris, France'),
    ('stay-nyc-les', 'Lower East Side walkup', 'New York, NY'),
    ('stay-nyc-brooklyn-heights', 'Brooklyn Heights brownstone floor', 'New York, NY'),
    ('stay-nyc-chelsea', 'Chelsea gallery district loft', 'New York, NY'),
    ('stay-nyc-soho', 'SoHo cast-iron loft', 'New York, NY'),
    ('stay-nyc-ues', 'Upper East Side classic one-bed', 'New York, NY'),
    ('stay-nyc-bushwick', 'Bushwick creative studio', 'New York, NY'),
    ('stay-london-south-bank', 'South Bank river view flat', 'London, UK'),
    ('stay-london-hackney', 'Hackney warehouse conversion', 'London, UK'),
    ('stay-london-fitzrovia', 'Fitzrovia townhouse room', 'London, UK'),
    ('stay-london-brixton', 'Brixton village apartment', 'London, UK'),
    ('stay-london-greenwich', 'Greenwich riverside cottage', 'London, UK'),
    ('stay-london-marylebone', 'Marylebone mews house', 'London, UK'),
    ('stay-seoul-hongdae', 'Hongdae arts district flat', 'Seoul, South Korea'),
    ('stay-seoul-bukchon', 'Bukchon hanok guesthouse', 'Seoul, South Korea'),
    ('stay-seoul-yeonnam', 'Yeonnam-dong cozy studio', 'Seoul, South Korea'),
    ('stay-seoul-jongno', 'Jongno hanok with rooftop', 'Seoul, South Korea'),
    ('stay-berlin-prenzlauer', 'Prenzlauer Berg family flat', 'Berlin, Germany'),
    ('stay-berlin-charlottenburg', 'Charlottenburg grand apartment', 'Berlin, Germany'),
    ('stay-berlin-friedrichshain', 'Friedrichshain party district loft', 'Berlin, Germany'),
    ('stay-berlin-wedding', 'Wedding artist collective room', 'Berlin, Germany'),
    ('stay-barcelona-born', 'El Born gothic quarter flat', 'Barcelona, Spain'),
    ('stay-barcelona-eixample', 'Eixample Modernista apartment', 'Barcelona, Spain'),
    ('stay-barcelona-barceloneta', 'Barceloneta beachfront studio', 'Barcelona, Spain'),
    ('stay-barcelona-poble-sec', 'Poble-sec vermouth district room', 'Barcelona, Spain'),
    ('stay-rome-testaccio', 'Testaccio food district apartment', 'Rome, Italy'),
    ('stay-rome-prati', 'Prati Vatican-area flat', 'Rome, Italy'),
    ('stay-rome-san-lorenzo', 'San Lorenzo student quarter room', 'Rome, Italy'),
    ('stay-rome-aventine', 'Aventine Hill garden apartment', 'Rome, Italy'),
    ('stay-amsterdam-de-pijp', 'De Pijp market district flat', 'Amsterdam, Netherlands'),
    ('stay-amsterdam-west', 'Amsterdam West canal house room', 'Amsterdam, Netherlands'),
    ('stay-amsterdam-noord', 'Amsterdam Noord creative loft', 'Amsterdam, Netherlands'),
    ('stay-lisbon-principe', 'Principe Real garden flat', 'Lisbon, Portugal'),
    ('stay-lisbon-mouraria', 'Mouraria fado quarter studio', 'Lisbon, Portugal'),
    ('stay-lisbon-santos', 'Santos riverside loft', 'Lisbon, Portugal'),
    ('stay-bangkok-silom', 'Silom business district condo', 'Bangkok, Thailand'),
    ('stay-bangkok-ari', 'Ari neighborhood townhouse', 'Bangkok, Thailand'),
    ('stay-bangkok-chinatown', 'Chinatown heritage shophouse', 'Bangkok, Thailand'),
    ('stay-sydney-manly', 'Manly beachfront apartment', 'Sydney, Australia'),
    ('stay-sydney-newtown', 'Newtown terrace house', 'Sydney, Australia'),
    ('stay-sydney-glebe', 'Glebe harbor-view studio', 'Sydney, Australia'),
    ('stay-cdmx-juarez', 'Juarez art deco apartment', 'Mexico City, Mexico'),
    ('stay-cdmx-coyoacan', 'Coyoacan colonial house room', 'Mexico City, Mexico'),
    ('stay-cdmx-polanco', 'Polanco luxury apartment', 'Mexico City, Mexico'),
    ('stay-miami-design', 'Design District modern condo', 'Miami Beach, FL'),
    ('stay-miami-little-havana', 'Little Havana casita', 'Miami Beach, FL'),
    ('stay-miami-coconut', 'Coconut Grove waterfront villa', 'Miami Beach, FL'),
    ('stay-austin-south', 'South Congress bungalow', 'Austin, TX'),
    ('stay-austin-rainey', 'Rainey Street modern studio', 'Austin, TX'),
    ('stay-nashville-12south', '12 South cottage', 'Nashville, TN'),
    ('stay-nashville-germantown', 'Germantown loft', 'Nashville, TN'),
    ('stay-nola-marigny', 'Marigny shotgun house', 'New Orleans, LA'),
    ('stay-nola-warehouse', 'Warehouse District loft', 'New Orleans, LA'),
    ('stay-portland-alberta', 'Alberta Arts District house', 'Portland, OR'),
    ('stay-portland-hawthorne', 'Hawthorne vintage apartment', 'Portland, OR'),
    ('stay-portland-pearl', 'Pearl District modern loft', 'Portland, OR'),
    ('stay-kyoto-gion', 'Gion traditional machiya', 'Kyoto, Japan'),
    ('stay-kyoto-higashiyama', 'Higashiyama temple district room', 'Kyoto, Japan'),
    ('stay-tulum-pueblo', 'Tulum pueblo town studio', 'Tulum, Mexico'),
    ('stay-tulum-cenote', 'Cenote-side eco cabin', 'Tulum, Mexico'),
    ('stay-capetown-woodstock', 'Woodstock creative quarter flat', 'Cape Town, South Africa'),
    ('stay-capetown-gardens', 'Gardens district Victorian flat', 'Cape Town, South Africa'),
    ('stay-joshua-dome', 'Joshua Tree desert dome', 'Joshua Tree, CA'),
    ('stay-joshua-hacienda', 'High desert hacienda', 'Joshua Tree, CA'),
    ('stay-santorini-oia', 'Oia caldera cave suite', 'Santorini, Greece'),
    ('stay-santorini-fira', 'Fira cliffside apartment', 'Santorini, Greece'),
    ('stay-marrakech-riad', 'Medina traditional riad', 'Marrakech, Morocco'),
    ('stay-marrakech-gueliz', 'Gueliz modern apartment', 'Marrakech, Morocco'),
    ('stay-copenhagen-norrebro', 'Norrebro neighborhood flat', 'Copenhagen, Denmark'),
    ('stay-copenhagen-vesterbro', 'Vesterbro design studio', 'Copenhagen, Denmark'),
    ('stay-dubrovnik-old', 'Old Town stone apartment', 'Dubrovnik, Croatia'),
    ('stay-dubrovnik-lapad', 'Lapad seaside villa', 'Dubrovnik, Croatia'),
    ('stay-hk-sheung-wan', 'Sheung Wan art district flat', 'Hong Kong'),
    ('stay-hk-sai-kung', 'Sai Kung waterfront house', 'Hong Kong'),
    ('stay-singapore-kampong', 'Kampong Glam heritage room', 'Singapore'),
    ('stay-singapore-joo-chiat', 'Joo Chiat Peranakan flat', 'Singapore'),
    ('stay-reykjavik-old', 'Old Reykjavik colorful apartment', 'Reykjavik, Iceland'),
    ('stay-reykjavik-harbour', 'Old Harbour waterfront studio', 'Reykjavik, Iceland'),
    ('stay-ubud-terrace', 'Ubud rice terrace villa', 'Ubud, Bali'),
    ('stay-canggu-surf', 'Canggu surf villa', 'Canggu, Bali'),
    ('stay-napa-vineyard', 'Vineyard cottage', 'Napa Valley, CA'),
    ('stay-napa-downtown', 'Downtown Napa walkable flat', 'Napa Valley, CA'),
    ('stay-santafe-canyon', 'Canyon Road adobe casita', 'Santa Fe, NM'),
    ('stay-santafe-railyard', 'Railyard District modern studio', 'Santa Fe, NM'),
    ('stay-chiangmai-riverside', 'Ping River boutique room', 'Chiang Mai, Thailand'),
    ('stay-edinburgh-leith', 'Leith waterfront flat', 'Edinburgh, Scotland'),
    ('stay-hanoi-french', 'French Quarter colonial flat', 'Hanoi, Vietnam'),
    ('stay-charleston-rainbow', 'Rainbow Row carriage house', 'Charleston, SC'),
    ('stay-savannah-jones', 'Jones Street row house', 'Savannah, GA'),
    ('stay-maui-kihei', 'Kihei oceanview condo', 'Maui, HI'),
    ('stay-tahoe-emerald', 'Emerald Bay view cabin', 'Lake Tahoe, CA'),
    ('stay-amalfi-positano', 'Positano cliffside apartment', 'Amalfi Coast, Italy'),
    ('stay-ba-palermo', 'Palermo Soho loft', 'Buenos Aires, Argentina'),
    ('stay-lima-miraflores', 'Miraflores oceanview apartment', 'Lima, Peru'),
    ('stay-lima-barranco', 'Barranco bohemian studio', 'Lima, Peru'),
    ('stay-busan-haeundae', 'Haeundae beachfront condo', 'Busan, South Korea'),
    ('stay-busan-gamcheon', 'Gamcheon Culture Village room', 'Busan, South Korea'),
    ('stay-capecod-provincetown', 'Provincetown harbor cottage', 'Cape Cod, MA'),
    ('stay-capecod-wellfleet', 'Wellfleet oyster farm cottage', 'Cape Cod, MA'),
    ('stay-hudson-farmhouse', 'Hudson Valley farmhouse retreat', 'Hudson Valley, NY'),
    ('stay-hudson-cottage', 'Beacon arts district cottage', 'Hudson Valley, NY'),
    ('stay-sf-sunset', 'Outer Sunset beach bungalow', 'San Francisco, CA'),
    ('stay-la-highland-park', 'Highland Park craftsman', 'Los Angeles, CA'),
    ('stay-la-malibu', 'Malibu beach house', 'Los Angeles, CA'),
    ('exp-berlin-food', 'Berlin street food and beer tour', 'Berlin, Germany'),
    ('exp-nola-jazz', 'New Orleans jazz and cocktail walk', 'New Orleans, LA'),
    ('exp-capetown-wine', 'Cape Winelands tasting tour', 'Cape Town, South Africa'),
    ('exp-chiangmai-cook', 'Chiang Mai farm-to-table cooking class', 'Chiang Mai, Thailand'),
    ('exp-hanoi-street-food', 'Hanoi street food motorbike tour', 'Hanoi, Vietnam'),
    ('exp-edinburgh-whisky', 'Edinburgh whisky and history walk', 'Edinburgh, Scotland'),
    ('service-tulum-wellness', 'Beach yoga and sound bath', 'Tulum, Mexico'),
    ('service-nola-music', 'Private jazz trio for your stay', 'New Orleans, LA'),
]

# Host names / conversation titles seeded in the inbox, mapped to the listing
# id whose `bnb.inbox.thread.<listing_id>` row carries them. Lets name-based
# inbox lookups (e.g. "Lena", "Andre", "Catalina") resolve to a thread slug.
_INBOX_HINTS = [
    ("stay-soma", "Lena", "Lena and Ridge Cabin"),
    ("stay-beach", "Andre", "Andre at Catalina Retreat"),
    ("stay-midtown-hotel", "StayFinder Support", "StayFinder Support"),
    ("stay-asheville", "Andre", "Andre at Redwood Canyon"),
    ("service-photo", "", "Vacation photo session"),
    ("exp-food", "", "Coastal taco tasting"),
    ("exp-sail", "", "Sunset Sail on the Bay"),
    ("service-chef", "", "Private chef dinner setup"),
    ("stay-lisbon-alfama", "Nadia", "Alfama tile apartment"),
    ("stay-chelsea-hotel", "Lucia", "Boutique harbor stay"),
    ("stay-london", "Rina", "Valley overlook studio"),
    ("stay-cabin", "Mika", "Cove-view guest suite"),
]


def _norm(s: str) -> str:
    """Lowercase, strip punctuation to spaces, collapse whitespace."""
    return re.sub(r"\s+", " ", re.sub(r"[^a-z0-9]+", " ", (s or "").lower())).strip()


def _resolve_listing(target: str):
    """Resolve a free-text target (id, title, or location) to a catalog entry.

    Returns ``(listing_id, title, location)`` or ``None``. Matching order:
      1. exact listing id
      2. exact normalized title
      3. id substring (target looks like a partial slug)
      4. full-token-subset match of target tokens against title+location
      5. any-token overlap (fuzzy fallback), best overlap wins
    """
    if not target:
        return None
    raw = target.strip()
    low = raw.lower()
    # 1. exact id
    for entry in _LISTING_CATALOG:
        if entry[0] == low:
            return entry
    nt = _norm(raw)
    # 2. exact normalized title
    for entry in _LISTING_CATALOG:
        if _norm(entry[1]) == nt:
            return entry
    # 3. slug-ish substring against id
    if re.fullmatch(r"[a-z0-9\-]+", low) and "-" in low:
        for entry in _LISTING_CATALOG:
            if low in entry[0] or entry[0] in low:
                return entry
    # 4 / 5. token matching against title + location. Ignore 1-char tokens
    # (e.g. the "a" in "A-frame") which would otherwise match noise.
    toks = [t for t in nt.split() if len(t) >= 2]
    if not toks:
        return None
    best = None
    best_score = 0
    for entry in _LISTING_CATALOG:
        hay = set(t for t in _norm(entry[1] + " " + entry[2]).split() if len(t) >= 2)
        overlap = sum(1 for t in toks if t in hay)
        if overlap == 0:
            continue
        subset = all(t in hay for t in toks)
        # A full-subset match always qualifies. Otherwise require a meaningful
        # overlap so a single incidental shared word don't resolve garbage.
        if not subset and overlap < 2 and overlap < max(1, (len(toks) + 1) // 2):
            continue
        score = (100 if subset else 0) + overlap
        if score > best_score:
            best_score = score
            best = entry
    return best


def _matching_listings(query: str, limit: int = 12):
    """Return up to *limit* catalog entries whose title/location match *query*
    by token overlap (for surfacing search results to the agent)."""
    toks = [t for t in _norm(query).split() if len(t) >= 2]
    if not toks:
        return []
    scored = []
    seen = set()
    for entry in _LISTING_CATALOG:
        if entry[0] in seen:
            continue
        hay = set(t for t in _norm(entry[1] + " " + entry[2]).split() if len(t) >= 2)
        overlap = sum(1 for t in toks if t in hay)
        if overlap == 0:
            continue
        subset = all(t in hay for t in toks)
        scored.append(((1 if subset else 0, overlap), entry))
        seen.add(entry[0])
    scored.sort(key=lambda x: x[0], reverse=True)
    return [e for _, e in scored[:limit]]


# ----------------------------------------------------------------------------
# UI-navigation helpers (self-navigation so tools work from a blind launch).
# ----------------------------------------------------------------------------

def _tree(sim) -> str:
    try:
        return sim.observe_text() or ""
    except Exception:
        return ""


def _try_tap(sim, accessibility_id: str) -> bool:
    try:
        sim.tap_id(accessibility_id)
        return True
    except Exception:
        return False


def _has_any_marker(tree: str, markers: tuple[str, ...]) -> bool:
    return any(marker in tree for marker in markers)


def _wait_for_markers(sim, markers: tuple[str, ...], attempts: int = 4,
                      interval: float = 0.5) -> str:
    """Return the first observed tree containing any marker, or last tree."""
    tree = _tree(sim)
    for _ in range(attempts):
        if _has_any_marker(tree, markers):
            return tree
        sim.wait(interval)
        tree = _tree(sim)
    return tree


def _dismiss_to_root(sim, max_steps: int = 4) -> str:
    """Pop any pushed detail / dismiss any open sheet so the bottom tab bar is
    reachable. Returns the resulting UI tree.

    A listing detail (and similar pushed screens) hide the tab bar and expose
    a `BackButton`; the search/booking/checkout sheets expose
    `bnb.search.close` / a `BackButton`. We tap whichever is present, a few
    times, until NO overlay remains.

    IMPORTANT: the Explore search sheet renders *over* the tab bar — so the
    tab buttons (e.g. 'Explore', 'Messages') are still present in the tree but
    are COVERED and won't receive taps. We therefore must dismiss any overlay
    even when the tab bar is technically present; we only treat ourselves as
    "at a root" once no overlay marker (search field / pushed BackButton) is
    left. This defends bug class (2): tapping a present-but-covered control.
    """
    # Markers that mean an overlay/pushed screen is on top of the tab bar.
    overlay_markers = (
        "bnb.search.destinationField",  # Explore search sheet
        "bnb.booking.screen",            # booking sheet (pushed)
        "bnb.checkout.summary",          # checkout sheet (pushed)
        "bnb.detail.reserve",            # listing detail (pushed)
        "bnb.chat.input",                # chat thread (pushed)
    )
    tree = _tree(sim)
    for _ in range(max_steps):
        overlay = any(m in tree for m in overlay_markers)
        at_root = (
            not overlay and (
                'name="Explore"' in tree or 'name="Profile"' in tree
                or 'name="Trips"' in tree
            )
        )
        if at_root:
            return tree
        acted = False
        if "bnb.search.close" in tree:
            acted = _try_tap(sim, "bnb.search.close")
        elif "BackButton" in tree:
            acted = _try_tap(sim, "BackButton")
        if not acted:
            break
        sim.wait(0.4)
        tree = _tree(sim)
    return tree


def _ensure_tab(sim, tab_key: str) -> Optional[str]:
    """Switch to a tab robustly. Dismisses any overlay first (the tab bar is
    hidden on pushed detail/sheet screens), then taps the tab item. Returns
    None on success or a recovery message."""
    aid = TAB_MAP.get(tab_key.strip().lower())
    if aid is None:
        return f"Unknown tab '{tab_key}'. Use: {', '.join(TAB_MAP.keys())}."
    tree = _tree(sim)
    # Dismiss any overlay that could cover the tab bar BEFORE tapping. The
    # search sheet renders over the tab bar, so the tab button can be present
    # in the tree yet uncovered/untappable — relying on "aid present" is not
    # enough. _dismiss_to_root() is a no-op when already at a clean root.
    _overlay = ("bnb.search.destinationField", "bnb.booking.screen",
                "bnb.checkout.summary", "bnb.detail.reserve", "bnb.chat.input")
    if f'name="{aid}"' not in tree or any(m in tree for m in _overlay):
        tree = _dismiss_to_root(sim)
    if not _try_tap(sim, aid):
        # Second chance after a hard dismiss.
        _dismiss_to_root(sim)
        if not _try_tap(sim, aid):
            # Last resort: the booking/checkout sheet is presented MODALLY and
            # hides the tab bar entirely (only a BackButton is exposed); on some
            # states dismissing it backgrounds StayFinder so the tab bar never
            # reappears (this is the real 53%-fail cause for 'trips'). Relaunch
            # StayFinder to force a clean rooted tab bar, then tap. This is the
            # same cold-state recovery used elsewhere — it does NOT thrash
            # because it runs only after both dismiss attempts failed.
            try:
                sim.launch_and_observe(BUNDLE_ID); sim.wait(0.6)
            except Exception:
                sim.wait(0.3)
            tree = _tree(sim)
            if f'name="{aid}"' not in tree:
                _dismiss_to_root(sim)
            if not _try_tap(sim, aid):
                return (f"Could not switch to '{tab_key}' tab — '{aid}' control "
                        "unavailable even after dismissing overlays.")
    sim.wait(0.4)
    markers = TAB_MARKERS.get(tab_key.strip().lower(), ())
    tree = _tree(sim)
    if markers and not _has_any_marker(tree, markers):
        sim.wait(0.5)
        tree = _tree(sim)
    if markers and not _has_any_marker(tree, markers):
        return (f"Tapped '{tab_key}' tab but could not verify its root content. "
                f"Expected one of: {', '.join(markers)}.")
    return None


def _open_search_sheet(sim) -> Optional[str]:
    """Ensure the Explore search sheet is open with its destination field
    focusable. Returns None on success or a recovery message."""
    tree = _tree(sim)
    if "bnb.search.destinationField" in tree:
        return None
    # Get to Explore root first.
    err = _ensure_tab(sim, "explore")
    if err:
        return err
    tree = _tree(sim)
    if "bnb.explore.searchBar" not in tree:
        # Maybe a detail/sheet still covers it.
        _dismiss_to_root(sim)
        _ensure_tab(sim, "explore")
        tree = _tree(sim)
    if not _try_tap(sim, "bnb.explore.searchBar"):
        return "Search bar (bnb.explore.searchBar) unavailable on the Explore tab."
    sim.wait(0.5)
    if "bnb.search.destinationField" not in (_tree(sim)):
        return "Could not open the destination field after tapping the search bar."
    return None


# Map a listing-id prefix to the kind-selector chip's accessibility name
# (the chips render as buttons named after their visible label: Homes /
# Experiences / Services — see KindSelectorView in ViewController.swift).
_KIND_CHIP = {"stay": "Homes", "exp": "Experiences", "service": "Services"}


def _listing_kind_chip(listing_id: Optional[str]) -> Optional[str]:
    """Return the kind-selector chip name (Homes/Experiences/Services) for a
    listing id, derived from its prefix. None for stays/unknown (default kind)."""
    if not listing_id:
        return None
    prefix = listing_id.split("-", 1)[0]
    return _KIND_CHIP.get(prefix)


def _select_kind_chip(sim, chip: Optional[str]) -> None:
    """Tap the kind chip on the open search sheet so the apply filters the
    right listing kind. The search panel filters results by the selected kind
    (`listing.kind == kind`), so searching a stay while 'Experiences' is
    selected returns nothing. No-op if *chip* is None or not present."""
    if not chip:
        return
    if f'name="{chip}"' in _tree(sim):
        _try_tap(sim, chip)
        sim.wait(0.4)


def _scroll_to_and_tap(sim, accessibility_id: str, max_swipes: int = 8) -> bool:
    """Tap an element by id, scrolling the current scroll view down until it is
    found. Returns True if tapped."""
    if _try_tap(sim, accessibility_id):
        return True
    for _ in range(max_swipes):
        tree = _tree(sim)
        if f'name="{accessibility_id}"' in tree:
            if _try_tap(sim, accessibility_id):
                return True
        sim.swipe("up")
        sim.wait(0.4)
    # final attempt after scrolling
    tree = _tree(sim)
    if f'name="{accessibility_id}"' in tree:
        return _try_tap(sim, accessibility_id)
    return False


def _current_detail_listing(sim):
    """If a listing detail is open, return the catalog entry it shows (matched
    by the nav title == listing.location and a title token), else None.

    We can't read the listing id off the detail screen, so this is a
    best-effort check used only to avoid re-navigating when already on a
    detail and no specific target was requested."""
    tree = _tree(sim)
    if "bnb.detail.reserve" not in tree:
        return None
    return True  # detail is open (identity unknown)


def _open_listing_detail(sim, target: Optional[str]) -> dict:
    """Self-navigate to a listing detail screen.

    If *target* is None and a detail is already open, reuse it. Otherwise
    resolve *target* (id / name / location) to a catalog entry, run a search
    for its title, and tap the matching result card (by listing id) to push
    the detail. Returns ``{"ok": bool, ...}``.
    """
    # Already on a detail and caller didn't pin a specific listing.
    if not target and _current_detail_listing(sim):
        return {"ok": True, "listing_id": None, "reused": True}

    entry = _resolve_listing(target) if target else None
    if target and not entry:
        return {"ok": False, "message": f"No StayFinder listing matches '{target}'."}
    if not target:
        # No listing specified and no detail currently open — honest failure
        # (don't relaunch into an empty search).
        return {"ok": False,
                "message": "No listing detail is open and no listing was "
                           "specified. Pass a listing id/title/location."}

    # If a detail is already open and matches the requested card id, reuse it
    # only when we can confirm the card id is present in the (pushed) tree's
    # "similar listings" — too unreliable; simpler to re-navigate.
    listing_id = entry[0] if entry else None
    title = entry[1] if entry else (target or "")

    # Relaunch to guarantee a clean Explore root. From the agent's real messy
    # states (booking sheet, checkout, pushed detail, drifted kind selector)
    # the Explore content fails to re-filter after applying a search — only a
    # fresh launch reliably resets the kind selector to its default and the
    # explore list to a populated state. This is the only recovery that works
    # for those states (verified live: dismiss-to-root alone leaves the filter
    # returning 0 cards).
    try:
        sim.launch_and_observe(BUNDLE_ID); sim.wait(0.6)
    except Exception:
        sim.wait(0.3)

    err = _open_search_sheet(sim)
    if err:
        return {"ok": False, "message": err}
    # Select the kind chip matching the target listing's kind BEFORE applying,
    # so the filter (listing.kind == selectedKind) doesn't drop the result.
    _select_kind_chip(sim, _listing_kind_chip(listing_id))
    # Type the resolved title (best signal) into the destination field.
    if not _try_tap(sim, "bnb.search.destinationField"):
        return {"ok": False, "message": "Could not focus the search destination field."}
    sim.wait(0.3)
    try:
        sim.type_text(title)
    except Exception as exc:
        return {"ok": False, "message": f"Could not type into search field. {str(exc)[:100]}"}
    sim.wait(0.3)
    if not _try_tap(sim, "bnb.search.apply"):
        return {"ok": False, "message": "Could not apply the search (bnb.search.apply missing)."}
    sim.wait(0.8)

    # Tap the result card. Prefer the resolved id; fall back to any stay/exp/
    # service card if the id isn't the one rendered (e.g. title collision).
    if listing_id and _scroll_to_and_tap(sim, listing_id):
        sim.wait(0.8)
    else:
        tree = _tree(sim)
        cards = re.findall(r'name="((?:stay|exp|service)-[^"]+)"', tree)
        if not cards:
            # scroll once and retry
            sim.swipe("up"); sim.wait(0.4)
            tree = _tree(sim)
            cards = re.findall(r'name="((?:stay|exp|service)-[^"]+)"', tree)
        if not cards:
            return {"ok": False,
                    "message": f"No result cards for '{title}'. Try a different query."}
        listing_id = cards[0]
        if not _try_tap(sim, listing_id):
            return {"ok": False, "message": f"Found card '{listing_id}' but tap failed."}
        sim.wait(0.8)

    tree = _tree(sim)
    if "bnb.detail.reserve" not in tree:
        return {"ok": False,
                "message": f"Opened card '{listing_id}' but the detail screen "
                           "(bnb.detail.reserve) did not appear."}
    return {"ok": True, "listing_id": listing_id}


def _read_detail_facts(tree: str) -> dict:
    """Scrape title / price-per-night / beds / baths / guests off an OPEN
    listing-detail screen (`bnb.detail.screen`).

    The detail screen (ListingDetailViewController) renders:
      * a 22pt bold title label (== listing.title),
      * a ReserveBarView price label "$<n> per night" (stays) /
        "$<n> per person" (experiences) / "From $<n>" (services),
      * an InfoRowView with three value/title label pairs:
        Guests / Beds / Baths (the value labels carry the integer).
    All are plain UILabels, so they surface in the accessibility tree as
    StaticText with matching `value`/`label`/`name`. Returns a dict with
    empty-string fallbacks for any field that can't be parsed.
    """
    facts = {"title": "", "price": "", "beds": "", "baths": "", "guests": ""}
    # Price: "$327 per night" / "$120 per person" / "From $90".
    m = re.search(r'(?:value|label|name)="(\$[\d,]+\s*per\s*night)"', tree)
    if not m:
        m = re.search(r'(?:value|label|name)="(\$[\d,]+\s*per\s*person)"', tree)
    if not m:
        m = re.search(r'(?:value|label|name)="(From\s*\$[\d,]+)"', tree)
    if m:
        facts["price"] = m.group(1).strip()
    # Title: the listing.title also drives the detail nav reuse, but read it
    # straight off a StaticText whose value/name equals a bold title. We can't
    # know the exact title up front here, so capture the first StaticText that
    # is NOT a numeric/price/section-label noise line near the top.
    # InfoRowView value labels: Guests/Beds/Baths each render the integer in a
    # value label immediately followed (in the stack) by the title label. Read
    # each "<int>" StaticText that pairs with a Guests/Beds/Baths title label.
    # Because XCUITest serializes siblings in order, match the integer value
    # that appears just before each title token.
    def _near_int(label_token: str) -> str:
        # Find the title StaticText, then look back for the nearest integer
        # value label.
        ti = tree.find(f'name="{label_token}"')
        if ti < 0:
            ti = tree.find(f'value="{label_token}"')
        if ti < 0:
            return ""
        window = tree[max(0, ti - 400):ti]
        ints = re.findall(r'(?:value|name)="(\d+)"', window)
        return ints[-1] if ints else ""

    facts["guests"] = _near_int("Guests")
    facts["beds"] = _near_int("Beds")
    facts["baths"] = _near_int("Baths")
    return facts


@mcp.tool()
def open_listing(listing: str) -> dict:
    """Open a listing's detail screen READ-ONLY and report its key facts.

    Self-navigates (Explore -> search -> open card) to the listing's detail
    and STOPS there — it does NOT tap Reserve and does NOT advance into the
    booking/checkout flow, so the detail stays on screen for inspection.

    Args:
      listing: the listing to open, given as a listing id (e.g. 'stay-beach'),
        a title (e.g. 'Clifftop retreat on Catalina'), or a location. Required.

    Returns ``{ok: True, action, listing_id, title, price, beds, baths,
    guests}`` with the facts scraped from the detail screen, or
    ``{ok: False, action, message}`` if the listing couldn't be resolved or
    its detail screen couldn't be reached.

    Use this to answer questions about a listing (name / price per night /
    beds / baths / guests) without committing a reservation. Follow with
    `reserve_listing` / `prepare_reserve_listing` only if you intend to book.
    """
    sim = SimulatorBridge.get()
    res = _open_listing_detail(sim, listing)
    if not res.get("ok"):
        return {"ok": False, "action": "open_listing",
                "message": res.get("message", "Could not open the listing detail.")}
    sim.wait(0.3)
    tree = sim.observe_text() or ""
    if "bnb.detail.screen" not in tree and "bnb.detail.reserve" not in tree:
        return {"ok": False, "action": "open_listing",
                "message": "Navigated but the listing detail screen is not on screen."}
    facts = _read_detail_facts(tree)
    # Prefer the authoritative catalog title for the resolved listing id; the
    # on-screen title scrape is a fallback for ids not in the catalog.
    title = facts["title"]
    cat = _resolve_listing(res.get("listing_id") or "")
    if cat:
        title = cat[1]
    return {
        "ok": True,
        "action": "open_listing",
        "listing_id": res.get("listing_id"),
        "title": title,
        "price": facts["price"],
        "beds": facts["beds"],
        "baths": facts["baths"],
        "guests": facts["guests"],
    }


@mcp.tool()
def launch() -> str:
    """Launch StayFinder and return the initial UI accessibility tree."""
    sim = SimulatorBridge.get()
    ui = sim.launch_and_observe(BUNDLE_ID)
    return f"Launched StayFinder.\n\n{ui}"


@mcp.tool()
def observe() -> str:
    """Return the current UI accessibility tree (XML) for StayFinder."""
    return ts.observe_app_scoped(
        SimulatorBridge.get(),
        bundle_id=BUNDLE_ID,
        app_name="StayFinder",
        markers=("bnb.", "stayfinder_", "listing_", "tab_trips"),
    )


@mcp.tool()
def navigate_to_tab(tab: str) -> str:
    """Switch to a StayFinder bottom-tab. Works from any screen — first
    dismisses any open detail/search/booking/checkout/chat overlay covering
    the tab bar, then taps the tab.

    Args:
      tab: one of 'explore' (or 'search'), 'wishlists' (or 'favorites'),
        'trips', 'inbox' (or 'messages'), 'profile'. Case-insensitive.

    Returns a confirmation string, or a recovery message (starting with
    "Unknown tab" / "Could not switch") if the tab is invalid or the bar
    stayed unreachable.
    """
    if TAB_MAP.get(tab.strip().lower()) is None:
        return f"Could not switch to unknown tab '{tab}'. Use: {', '.join(TAB_MAP.keys())}."
    sim = SimulatorBridge.get()
    err = _ensure_tab(sim, tab)
    if err:
        return err
    return f"Switched to '{tab}'."


@mcp.tool()
def open_search() -> str:
    """Open the Explore search sheet (taps `bnb.explore.searchBar`).

    Works from any screen — self-navigates to the Explore tab and dismisses
    any covering overlay first. After it returns, the destination field
    (`bnb.search.destinationField`) is on screen. Returns a confirmation
    string, or a recovery message if the search bar/field never appeared.
    """
    sim = SimulatorBridge.get()
    err = _open_search_sheet(sim)
    if err:
        return err
    return "Opened search sheet."


@mcp.tool()
def search_destination(destination: str) -> dict:
    """Open the search sheet, type a destination, and scrape matches.

    Works from any screen — self-navigates to Explore and opens the search
    sheet first.

    Args:
      destination: free-text destination query — a city, region, or listing
        title (e.g. 'Tokyo', 'paris', 'Catalina'). Case-insensitive.

    Returns ``{ok: True, destination, suggestions: [slug, ...], count,
    matching_listings: [{listing_id, title, location}, ...]}``. The
    `suggestions` are suggestion-chip slugs — feed any one to
    `pick_search_suggestion`. `matching_listings` are concrete catalog
    listings whose title/location match the query (use a `listing_id` with
    `reserve_listing`/`message_host` to open that exact stay even when the
    city has no suggestion chip). Returns ``{ok: False, message}`` if the
    search sheet/field could not be reached.
    """
    import re as _re
    sim = SimulatorBridge.get()
    # Self-navigate: ensure the Explore search sheet is open and the field
    # is focusable, regardless of the current screen (blind agent usage).
    err = _open_search_sheet(sim)
    if err:
        return {"ok": False, "action": "search_destination",
                "destination": destination, "message": err}
    if not _try_tap(sim, "bnb.search.destinationField"):
        return {"ok": False, "action": "search_destination",
                "destination": destination,
                "message": "Destination field unavailable on the search sheet."}
    sim.wait(0.3)
    sim.type_text(destination)
    sim.wait(0.5)
    tree = sim.observe_text() or ""
    slugs = sorted(set(_re.findall(r'bnb\.search\.suggestion\.([^"\s]+)', tree)))
    # Also resolve the free text against the seed listing catalog so the agent
    # can open a specific stay even when its city isn't a suggestion chip.
    matches = [{"listing_id": e[0], "title": e[1], "location": e[2]}
               for e in _matching_listings(destination)]
    return {
        "ok": True,
        "action": "search_destination",
        "destination": destination,
        "suggestions": slugs,
        "count": len(slugs),
        "matching_listings": matches,
    }


@mcp.tool()
def pick_search_suggestion(slug: str) -> str:
    """Tap a destination suggestion on the open search sheet.

    Args:
      slug: a suggestion slug as returned in the `suggestions` list of
        `search_destination` (the trailing token of
        `bnb.search.suggestion.<slug>`). Lowercase.

    Self-navigates: opens the search sheet first if it isn't already showing.
    Returns a confirmation string, or a recovery message (telling you to call
    `search_destination` to list valid slugs) if the suggestion isn't present.
    """
    sim = SimulatorBridge.get()
    aid = f"bnb.search.suggestion.{slug}"
    if aid not in _tree(sim):
        err = _open_search_sheet(sim)
        if err:
            return err
    if not _scroll_to_and_tap(sim, aid):
        return (f"Could not find suggestion '{slug}' on the search sheet. Use "
                "search_destination to list available suggestion slugs.")
    sim.wait(0.4)
    return f"Picked suggestion '{slug}'."


@mcp.tool()
def close_search() -> str:
    """Dismiss the search sheet (tap `bnb.search.close`)."""
    sim = SimulatorBridge.get()
    sim.tap_id("bnb.search.close"); sim.wait(0.3)
    return "Closed search."


def _reserve_listing_fill_form(listing: Optional[str] = None) -> Optional[str]:
    """Ensure a listing detail screen (with `bnb.detail.reserve`) is open.

    Self-navigates: if *listing* (an id, title, or location) is given, opens
    that listing's detail via search; otherwise reuses the currently-open
    detail. Returns None on success or a recovery message on failure. Used by
    both `reserve_listing` and `prepare_reserve_listing`.
    """
    sim = SimulatorBridge.get()
    tree = _tree(sim)
    if listing is None and "bnb.detail.reserve" in tree:
        return None
    res = _open_listing_detail(sim, listing)
    if not res.get("ok"):
        return res.get("message", "Could not open a listing detail screen.")
    return None


@mcp.tool()
def reserve_listing(listing: Optional[str] = None) -> str:
    """Reserve a listing — taps Reserve (`bnb.detail.reserve`) on its detail view.

    Args:
      listing: optional listing to reserve, given as a listing id
        (e.g. 'stay-beach'), a title (e.g. 'Clifftop retreat on Catalina'),
        or a location. If provided, the tool self-navigates to that listing's
        detail screen first (Explore → search → open). If omitted, it acts on
        the listing detail already on screen.

    Legacy single-verb commit — prefer `prepare_reserve_listing` +
    `confirm_reserve_listing` for new code.
    """
    sim = SimulatorBridge.get()
    err = _reserve_listing_fill_form(listing)
    if err:
        return err
    try:
        sim.tap_id("bnb.detail.reserve"); sim.wait(0.5)
    except Exception as exc:
        return f"Reserve button not found after navigating. {str(exc)[:100]}"
    tree = _wait_for_markers(sim, ("bnb.booking.screen",), attempts=3)
    if "bnb.booking.screen" not in tree:
        return "Tapped Reserve but could not verify the booking sheet opened."
    return "Tapped Reserve; booking sheet opened."


@mcp.tool()
def prepare_reserve_listing(listing: Optional[str] = None) -> dict:
    """Stage a Reserve tap on a listing detail view WITHOUT committing.

    Args:
      listing: optional listing id, title, or location. If provided, the tool
        self-navigates to that listing's detail screen first; if omitted it
        uses the detail already on screen.

    Reads the listing detail screen and captures a small snapshot, then
    issues a draft_id. Pass it to `confirm_reserve_listing` to commit.

    Returns ``{ok: True, action, draft_id, summary, next}`` on success
    or ``{ok: False, action, message}`` on precondition failure (no
    draft stored).
    """
    err = _reserve_listing_fill_form(listing)
    if err:
        return {"ok": False, "action": "prepare_reserve_listing", "message": err}
    sim = SimulatorBridge.get()
    # Capture a lightweight snapshot so the agent can verify which listing
    # is about to be reserved. We don't fail if the snapshot fails — the
    # commit still depends on the UI being in the right state at
    # confirm_reserve_listing time.
    snapshot = ""
    try:
        tree = sim.observe_text() or ""
        # Try to surface a few hints from the detail screen.
        match = re.search(r'name="bnb\.detail\.screen"[^>]*', tree)
        if match:
            snapshot = match.group(0)[:240]
    except Exception:
        pass
    summary = {"target_id": "bnb.detail.reserve", "detail_hint": snapshot}
    draft_id = ts.create_draft("stayfinder", "reserve_listing", summary)
    return {
        "ok": True,
        "action": "prepare_reserve_listing",
        "draft_id": draft_id,
        "summary": summary,
        "next": "Call confirm_reserve_listing(draft_id) to commit.",
    }


@mcp.tool()
def confirm_reserve_listing(draft_id: str) -> dict:
    """Commit a Reserve tap previously staged by `prepare_reserve_listing`.

    Args:
      draft_id: the id returned by `prepare_reserve_listing` (must still
        be active — not consumed, not expired).

    Taps `bnb.detail.reserve`. Returns ``{ok: True, action, evidence}``
    on success, or a controlled-failure response (without tapping) if
    the draft is missing/expired or the Reserve button is gone.
    """
    draft = ts.consume_draft(draft_id)
    if not draft:
        return {
            "ok": False,
            "action": "confirm_reserve_listing",
            "message": f"Draft '{draft_id}' not found or expired. Call prepare_reserve_listing first.",
        }
    sim = SimulatorBridge.get()
    try:
        sim.tap_id("bnb.detail.reserve"); sim.wait(0.5)
    except Exception:
        return {
            "ok": False,
            "action": "confirm_reserve_listing",
            "message": "Reserve button not found in current UI; verify the listing detail screen is still open.",
        }
    tree = _wait_for_markers(sim, ("bnb.booking.screen",), attempts=3)
    if "bnb.booking.screen" not in tree:
        return {
            "ok": False,
            "action": "confirm_reserve_listing",
            "message": "Tapped Reserve but the booking sheet did not appear; commit not verified.",
            "evidence": draft.get("payload", {}),
        }
    return {
        "ok": True,
        "action": "confirm_reserve_listing",
        "evidence": draft.get("payload", {}),
    }


@mcp.tool()
def message_host(listing: Optional[str] = None) -> str:
    """Open a chat with a listing's host (taps `bnb.detail.messageHost`).

    Args:
      listing: optional listing id, title, or location. If provided, the tool
        self-navigates to that listing's detail screen first; if omitted it
        uses the detail already on screen.

    After this returns, a chat thread is open (`bnb.chat.input`) — type with
    `send_chat_message` / `prepare_send_chat_message`.
    """
    sim = SimulatorBridge.get()
    tree = _tree(sim)
    if listing is not None or "bnb.detail.messageHost" not in tree:
        res = _open_listing_detail(sim, listing)
        if not res.get("ok"):
            return res.get("message", "Could not open a listing detail screen.")
    try:
        sim.tap_id("bnb.detail.messageHost"); sim.wait(0.5)
    except Exception as exc:
        return f"Message host button not found after navigating. {str(exc)[:100]}"
    return "Opened host chat."


@mcp.tool()
def continue_booking() -> str:
    """Tap Continue (`bnb.booking.continue`) on the booking sheet → checkout.

    Precondition: the booking sheet (`bnb.booking.screen`) must be open
    (reached via `reserve_listing` from a listing detail).
    """
    sim = SimulatorBridge.get()
    try:
        sim.tap_id("bnb.booking.continue"); sim.wait(0.5)
    except Exception as exc:
        return f"Continue button not found on booking sheet. {str(exc)[:100]}"
    markers = ("bnb.checkout.summary", "bnb.checkout.confirmButton")
    tree = _wait_for_markers(sim, markers, attempts=3)
    if not _has_any_marker(tree, markers):
        return "Tapped Continue but could not verify the checkout sheet opened."
    return "Continued to checkout."


_ATTR_RE = re.compile(r'(\w+)="([^"]*)"')


def _extract_attr(tree: str, accessibility_id: str, attr: str) -> str:
    """Find the XML element whose `name` attribute matches `accessibility_id`
    and return the value of its `attr` attribute (typically `value` or
    `label`). Returns "" if not found.

    The Appium XCUITest source uses XML with attributes in unspecified
    order, so we search any `<XCUIElementType... name="<id>"...>` tag
    and pick the requested attribute out of its attribute list.
    """
    pattern = re.compile(
        r'<[A-Za-z0-9_]+[^>]*\bname="' + re.escape(accessibility_id) + r'"[^>]*>'
    )
    match = pattern.search(tree)
    if not match:
        return ""
    for k, v in _ATTR_RE.findall(match.group(0)):
        if k == attr:
            return v
    return ""


def _parse_checkout_summary(tree: str) -> dict:
    """Pull a structured summary from the `bnb.checkout.summary` element.

    The summary label is multiline text emitted by StayFinder/ViewController:
        <listing title>
        <start_date> - <end_date>
        Guests: <n>
        ...
        Total: $<amount>
    Returns ``{listing_id, dates, guests, total}`` with empty-string
    fallbacks when any field can't be parsed (UI may be in a slightly
    different state).
    """
    # XCUITest serializes the multiline text into the `value` attribute
    # (escaped). Try `value` first, fall back to `label`.
    raw = _extract_attr(tree, "bnb.checkout.summary", "value")
    if not raw:
        raw = _extract_attr(tree, "bnb.checkout.summary", "label")
    # XCUITest XML escapes newlines as the literal text `&#10;` or `\n`.
    text = raw.replace("&#10;", "\n").replace("\\n", "\n")
    lines = [ln.strip() for ln in text.splitlines() if ln.strip()]
    listing_id = lines[0] if lines else ""
    dates = ""
    guests = ""
    total = ""
    for ln in lines:
        if " - " in ln and re.search(r"\d", ln) and not dates:
            # Heuristic: the date-range line has " - " and contains a digit.
            if not ln.lower().startswith(("guests", "total", "subtotal",
                                          "cleaning", "service", "taxes",
                                          "tip", "delivery")):
                dates = ln
        m = re.match(r"Guests:\s*(.+)", ln, re.IGNORECASE)
        if m:
            guests = m.group(1).strip()
        m = re.match(r"Total:\s*\$?(.+)", ln, re.IGNORECASE)
        if m:
            total = m.group(1).strip()
    return {
        "listing_id": listing_id,
        "dates": dates,
        "guests": guests,
        "total": total,
    }


def _checkout_fill_form() -> Optional[str]:
    """Open/verify the checkout sheet without committing.

    The checkout sheet is reached by the booking-continue → checkout
    chain, which is driven by the dedicated `continue_booking` /
    `reserve_listing` tools. This helper is intentionally a no-op so
    `prepare_checkout` and the legacy `confirm_checkout` share a single
    code path. Returns None on success or a precondition message on
    failure.
    """
    return None


@mcp.tool()
def prepare_checkout() -> dict:
    """Inspect the checkout sheet and stage a confirm WITHOUT committing.

    Reads the `bnb.checkout.summary` label and captures
    ``{listing_id, dates, guests, total}``. Pass the returned
    ``draft_id`` to `confirm_checkout` to actually confirm payment.

    Returns ``{ok: True, action, draft_id, summary, next}`` on success,
    or ``{ok: False, action, message}`` if the checkout sheet isn't
    visible (no draft stored).

    Precondition: the checkout sheet must already be on screen (e.g.
    `reserve_listing` → `continue_booking`). Drafts expire after
    `IOSWORLD_DRAFT_TTL_SECONDS` (default 10 minutes).
    """
    err = _checkout_fill_form()
    if err:
        return {"ok": False, "action": "prepare_checkout", "message": err}
    sim = SimulatorBridge.get()
    try:
        tree = sim.observe_text() or ""
    except Exception as exc:
        return {
            "ok": False,
            "action": "prepare_checkout",
            "message": f"Could not read UI tree to capture checkout summary. {str(exc)[:120]}",
        }
    if "bnb.checkout.summary" not in tree:
        return {
            "ok": False,
            "action": "prepare_checkout",
            "message": "Checkout sheet not visible (bnb.checkout.summary missing). "
                       "Open the booking flow first (reserve_listing → continue_booking).",
        }
    summary = _parse_checkout_summary(tree)
    draft_id = ts.create_draft("stayfinder", "checkout", summary)
    return {
        "ok": True,
        "action": "prepare_checkout",
        "draft_id": draft_id,
        "summary": summary,
        "next": "Call confirm_checkout(draft_id) to commit.",
    }


@mcp.tool()
def confirm_checkout(draft_id: str) -> dict:
    """Confirm payment on the StayFinder/MyBank checkout sheet.

    Args:
      draft_id: id from `prepare_checkout`. The draft must still be active and
        is consumed before tapping.

    Toggles `bnb.checkout.confirmSwitch` then taps
    `bnb.checkout.confirmButton`. Returns ``{ok: True, action,
    evidence}`` on success.

    Precondition: the checkout sheet must be on screen.
    """
    evidence: dict = {}
    draft = ts.consume_draft(draft_id)
    if not draft:
        return {
            "ok": False,
            "action": "confirm_checkout",
            "message": f"Draft '{draft_id}' not found or expired. Call prepare_checkout first.",
        }
    evidence = draft.get("payload", {})
    sim = SimulatorBridge.get()
    tree = _tree(sim)
    if "bnb.checkout.confirmButton" not in tree:
        return {
            "ok": False,
            "action": "confirm_checkout",
            "message": "Confirm button not found in current UI; verify the checkout sheet is still open.",
        }
    switch_value = _extract_attr(tree, "bnb.checkout.confirmSwitch", "value").strip().lower()
    switch_is_on = switch_value in {"1", "on", "true"}
    if not switch_is_on:
        try:
            sim.tap_id("bnb.checkout.confirmSwitch"); sim.wait(0.2)
        except Exception:
            pass
        tree = _tree(sim)
        switch_value = _extract_attr(tree, "bnb.checkout.confirmSwitch", "value").strip().lower()
        if switch_value and switch_value not in {"1", "on", "true"}:
            return {
                "ok": False,
                "action": "confirm_checkout",
                "message": "Could not enable the checkout confirmation switch; booking not confirmed.",
                "evidence": evidence,
            }
    try:
        sim.tap_id("bnb.checkout.confirmButton"); sim.wait(0.5)
    except Exception:
        return {
            "ok": False,
            "action": "confirm_checkout",
            "message": "Confirm button not found in current UI; verify the checkout sheet is still open.",
        }
    tree = _wait_for_markers(sim, TAB_MARKERS["trips"], attempts=5)
    if not _has_any_marker(tree, TAB_MARKERS["trips"]):
        return {
            "ok": False,
            "action": "confirm_checkout",
            "message": "Tapped Confirm but the Trips screen did not appear; booking commit not verified.",
            "evidence": evidence,
        }
    return {
        "ok": True,
        "action": "confirm_checkout",
        "evidence": evidence,
        "verified": "trips_screen",
    }


def _send_chat_message_fill_form(text: str) -> Optional[str]:
    """Type a chat message into the open thread's input field WITHOUT tapping Send.

    Returns None on success or a precondition message on failure. Used
    by both `send_chat_message` (one-shot commit) and
    `prepare_send_chat_message` (capture-only). Stops short of tapping
    `bnb.chat.send` so the caller decides whether to commit.
    """
    sim = SimulatorBridge.get()
    try:
        sim.tap_id("bnb.chat.input"); sim.wait(0.3)
        sim.type_text(text); sim.wait(0.3)
        return None
    except Exception as exc:
        return (
            "Chat input not available. Open a thread first via "
            f"open_inbox_thread(...). {str(exc)[:120]}"
        )


@mcp.tool()
def send_chat_message(text: str) -> str:
    """Type a message into the open chat thread and tap Send.

    Args:
      text: message body (free text).

    Precondition: a chat thread must be open (`bnb.chat.input` visible) —
    reached via `open_inbox_thread` or `message_host`. Legacy single-verb
    commit — prefer `prepare_send_chat_message` + `confirm_send_chat_message`
    for new code.
    """
    sim = SimulatorBridge.get()
    err = _send_chat_message_fill_form(text)
    if err:
        return err
    try:
        sim.tap_id("bnb.chat.send"); sim.wait(0.4)
    except Exception:
        return f"Could not send typed message '{text[:60]}': Send button not found — confirm via observe()."
    return f"Sent: '{text[:60]}'."


@mcp.tool()
def prepare_send_chat_message(text: str) -> dict:
    """Type a chat message into the open thread's input field WITHOUT sending.

    Args:
      text: message body (free text).

    Taps `bnb.chat.input` and types the text but does NOT tap
    `bnb.chat.send`. Pass the returned ``draft_id`` to
    `confirm_send_chat_message` to commit.

    Returns ``{ok: True, action, draft_id, summary, next}`` on success,
    or ``{ok: False, action, message}`` on precondition failure (no
    draft stored).

    Precondition: a chat thread must be open (use `open_inbox_thread`
    or `message_host` first).
    """
    err = _send_chat_message_fill_form(text)
    if err:
        return {"ok": False, "action": "prepare_send_chat_message", "message": err}
    summary = {"text": text}
    draft_id = ts.create_draft("stayfinder", "send_chat_message", summary)
    return {
        "ok": True,
        "action": "prepare_send_chat_message",
        "draft_id": draft_id,
        "summary": summary,
        "next": "Call confirm_send_chat_message(draft_id) to commit.",
    }


@mcp.tool()
def confirm_send_chat_message(draft_id: str) -> dict:
    """Send a chat message previously staged by `prepare_send_chat_message`.

    Args:
      draft_id: the id returned by `prepare_send_chat_message` (must
        still be active — not consumed, not expired).

    Taps `bnb.chat.send`. Returns ``{ok: True, action, evidence}`` on
    success, or a controlled-failure response (without tapping) if the
    draft is missing/expired or the Send button is gone.
    """
    draft = ts.consume_draft(draft_id)
    if not draft:
        return {
            "ok": False,
            "action": "confirm_send_chat_message",
            "message": f"Draft '{draft_id}' not found or expired. Call prepare_send_chat_message first.",
        }
    sim = SimulatorBridge.get()
    try:
        sim.tap_id("bnb.chat.send"); sim.wait(0.4)
    except Exception:
        return {
            "ok": False,
            "action": "confirm_send_chat_message",
            "message": "Send button not found in current UI; verify the chat thread is still open.",
        }
    return {
        "ok": True,
        "action": "confirm_send_chat_message",
        "evidence": draft.get("payload", {}),
    }


def _resolve_inbox_slug(target: str) -> Optional[str]:
    """Resolve an inbox-thread target to its `<listing_id>` slug.

    Accepts a listing id, a host name (e.g. 'Andre', 'Lena'), a conversation
    title fragment (e.g. 'Catalina Retreat'), or a listing title/location.
    """
    if not target:
        return None
    low = target.strip().lower()
    # exact listing id among seeded conversations
    for lid, host, title in _INBOX_HINTS:
        if lid == low:
            return lid
    nt = _norm(target)
    toks = [t for t in nt.split() if t]
    best = None
    best_score = 0
    for lid, host, title in _INBOX_HINTS:
        hay = set(_norm(f"{host} {title}").split())
        # also fold in the catalog title/location for this listing
        cat = _resolve_listing(lid)
        if cat:
            hay |= set(_norm(f"{cat[1]} {cat[2]}").split())
        overlap = sum(1 for t in toks if t in hay)
        if overlap == 0:
            continue
        subset = 100 if all(t in hay for t in toks) else 0
        score = subset + overlap
        if score > best_score:
            best_score = score
            best = lid
    if best:
        return best
    # fall back to general catalog resolution (slug == listing id)
    entry = _resolve_listing(target)
    return entry[0] if entry else None


@mcp.tool()
def open_inbox_thread(listing_id: str) -> str:
    """Open a message thread on the Messages (inbox) tab.

    Args:
      listing_id: the conversation's listing slug (e.g. 'stay-soma'), OR a
        host name (e.g. 'Andre', 'Lena'), OR a conversation/listing title
        fragment (e.g. 'Catalina Retreat'). The tool resolves it to a thread.

    Self-navigates to the Messages tab first, so it works from any screen.
    """
    sim = SimulatorBridge.get()
    slug = _resolve_inbox_slug(listing_id) or listing_id.strip()
    # Ensure the Messages tab is showing the thread rows.
    tree = _tree(sim)
    if f"bnb.inbox.thread.{slug}" not in tree:
        nav_err = _ensure_tab(sim, "inbox")
        if nav_err:
            return f"Could not open inbox thread '{listing_id}'. {nav_err}"
        sim.wait(0.3)
    aid = f"bnb.inbox.thread.{slug}"
    if not _scroll_to_and_tap(sim, aid):
        return (f"Could not open inbox thread for '{listing_id}'. No thread "
                f"'{aid}' found on the Messages tab (resolved slug: {slug}).")
    sim.wait(0.4)
    return f"Opened thread for listing {slug}."


@mcp.tool()
def view_trips() -> str:
    """Switch to the Trips tab (alias for `navigate_to_tab('trips')`)."""
    return navigate_to_tab("trips")


@mcp.tool()
def view_wishlists() -> str:
    """Switch to the Wishlists tab (alias for `navigate_to_tab('wishlists')`)."""
    return navigate_to_tab("wishlists")


@mcp.tool()
def view_profile() -> str:
    """Switch to the Profile tab (alias for `navigate_to_tab('profile')`)."""
    return navigate_to_tab("profile")


@mcp.tool()
def open_profile_section(section: str) -> str:
    """Open a section of the Profile tab.

    Args:
      section: one of 'connections', 'hosting', 'notifications',
        'pastTrips' (also accepts 'past_trips' / 'past trips').
        Case-insensitive.

    Works from any screen — self-navigates to the Profile tab and scrolls
    the section control into view before tapping. Returns a confirmation
    string, or a recovery message (starting with "Unknown section" / "Could
    not open") if the section name is invalid or the control was unreachable.
    """
    mapping = {
        "connections": "bnb.profile.connections",
        "hosting": "bnb.profile.hosting",
        "notifications": "bnb.profile.notifications",
        "pasttrips": "bnb.profile.pastTrips", "past_trips": "bnb.profile.pastTrips",
    }
    aid = mapping.get(section.strip().lower().replace(" ", "_"))
    if aid is None:
        return f"Could not open unknown section '{section}'. Use: connections, hosting, notifications, pastTrips."
    sim = SimulatorBridge.get()
    # Self-navigate to the Profile tab first (the section controls only exist
    # there), then scroll the section control into view before tapping.
    tree = _tree(sim)
    if aid not in tree:
        nav_err = _ensure_tab(sim, "profile")
        if nav_err:
            return f"Could not open profile section '{section}'. {nav_err}"
        sim.wait(0.3)
    if not _scroll_to_and_tap(sim, aid):
        return (f"Could not open profile section '{section}'. Control '{aid}' "
                "not found on the Profile tab even after scrolling.")
    sim.wait(0.4)
    return f"Opened profile.{section}."


if __name__ == "__main__":
    mcp.run()
