// destination.js - Handles the destination detail page
console.log('[destination.js] Script is loading...');
window.__destination_js_loading = true;

const API_BASE_URL = window.APP_API_BASE_URL || (window.location.origin === 'null' || window.location.origin.startsWith('file') || window.location.port === '5500' || window.location.port === '5501') ? 'http://127.0.0.1:3000' : window.location.origin;
window.__destination_js_api_url_set = true;
console.log('[destination.js] API_BASE_URL set to:', API_BASE_URL);

let currentReviewRating = 0;
// Defensive Google Maps callback
window.onGoogleMapsApiLoaded = () => {
  try {
    if (typeof getDestinationFromURL === 'function' && typeof displayDestinationDetailMap === 'function') {
      const destIndex = getDestinationFromURL();
      const district = destIndex !== null && spots && spots[destIndex] ? spots[destIndex][1] : null;
      if (district) {
        displayDestinationDetailMap(district);
      }
    }
  } catch (err) {
    console.warn('Google Maps callback error:', err.message);
  }
};

let siteContentCache = null;

// Get destination index from URL parameter
function getDestinationFromURL() {
  const params = new URLSearchParams(window.location.search);
  const id = params.get('id');
  if (id === null || id === undefined || id === '') return null;
  const parsed = parseInt(id, 10);
  return isNaN(parsed) ? null : parsed;
}

// Initialize destination page
async function initDestinationPage() {
  await loadSpotsFromDB();
  await loadSiteContent();
  const destIndex = getDestinationFromURL();
  
  if (destIndex === null || destIndex < 0 || destIndex >= spots.length) {
    showError('Destination not found. Redirecting to home...');
    setTimeout(() => window.location.href = 'index.html', 2000);
    return;
  }

  const place = spots[destIndex];
  const [name, district, category] = place;

  // Display hero section
  displayDestinationHero(place, destIndex);
  displayDestinationAboutSection(place);

  // Display all sections
  displayDestinationCurrentWeather(district);
  displayDestinationForecastCalendar(district);
  displayDestinationDetailMap(district);
  displayDestinationGuide(place);
  displayHotels(place);
  displayRelatedDestinations(district, destIndex);
  updateBookingLinks(name, district);
  initBookingSection(place, destIndex);
  initReviewSection();
  initBudgetCalculator(place);
}

function escapeHtml(value) {
  return String(value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

async function loadSiteContent() {
  if (siteContentCache) return siteContentCache;
  try {
    const response = await fetch(`${API_BASE_URL}/api/site-content`);
    const data = await response.json().catch(() => ({}));
    if (response.ok && data?.content) {
      siteContentCache = data.content;
      return siteContentCache;
    }
  } catch (error) {
    // ignore and use fallback content
  }
  siteContentCache = {
    travelGuide: '',
    budgets: {},
  };
  return siteContentCache;
}

function updateBookingLinks(name, district) {
  const hotelBtn = document.getElementById('bookHotelsBtn');
  if (hotelBtn) {
    hotelBtn.href = `https://hotel.com.bd/search?q=${encodeURIComponent(district)}`;
  }
  
  const transportBtn = document.getElementById('bookTransportBtn');
  if (transportBtn) {
    transportBtn.href = `https://www.shohoz.com/bus-tickets?tocity=${encodeURIComponent(district)}`;
  }
}

function displayDestinationHero(place, index) {
  const [name, district, category] = place;
  const gradient = getSpotGradient(place);

  document.getElementById('destHeroName').textContent = name;
  document.getElementById('destHeroDistrict').textContent = `District: ${district}`;
  document.getElementById('destHeroBadge').textContent = cats[category];
  document.getElementById('destHeroIndex').textContent = `#${index + 1}`;
  document.getElementById('destHeroCategory').textContent = cats[category];
  
  if (place.image) {
    document.getElementById('destHeroVisual').style.backgroundImage = `url('${place.image}')`;
    document.getElementById('destHeroVisual').style.backgroundSize = 'cover';
    document.getElementById('destHeroVisual').style.backgroundPosition = 'center';
  } else {
    document.getElementById('destHeroVisual').style.backgroundImage = gradient;
  }
  
  document.getElementById('destHeroDescription').textContent = place.description || 
    `${name} is a ${cats[category].toLowerCase()} destination in ${district}. This is one of ${spots.length}+ amazing places across Bangladesh.`;
}

function displayDestinationAboutSection(place) {
  const [name, district, category] = place;
  
  const descEl = document.getElementById('destDetailDescription');
  if (descEl) {
    descEl.textContent = place.description || `${name} is a beautiful ${cats[category].toLowerCase()} spot located in the ${district} district.`;
  }
  
  const histEl = document.getElementById('destDetailHistory');
  if (histEl) {
    histEl.textContent = place.history || `${name} has rich cultural and historical significance, offering unique scenic value and travel experiences.`;
  }
  
  const factDistrictEl = document.getElementById('factDistrict');
  if (factDistrictEl) factDistrictEl.textContent = district;
  
  const factDivisionEl = document.getElementById('factDivision');
  if (factDivisionEl) factDivisionEl.textContent = place.division || 'Unknown';
  
  const factBudgetEl = document.getElementById('factBudget');
  if (factBudgetEl) factBudgetEl.textContent = place.budgetCategory || 'Medium';
  
  const factCategoryEl = document.getElementById('factCategory');
  if (factCategoryEl) factCategoryEl.textContent = cats[category];
}

async function displayDestinationCurrentWeather(district) {
  const iconEl = document.getElementById('destCurrentIcon');
  const tempEl = document.getElementById('destCurrentTemp');
  const descEl = document.getElementById('destCurrentDesc');
  const sugEl = document.getElementById('destCurrentSuggestion');

  if (!tempEl || !descEl || !sugEl || !iconEl) return;

  tempEl.textContent = 'Loading...';
  descEl.textContent = district;
  sugEl.textContent = 'Fetching weather...';

  try {
    const weather = await fetchOpenWeatherCurrent(district);
    const temp = weather.temp;
    const desc = weather.description;
    const main = weather.main;

    tempEl.textContent = `${temp}°C`;
    descEl.textContent = desc;
    iconEl.textContent = chooseIcon(main, desc);
    sugEl.textContent = travelSuggestion(main.toLowerCase(), temp);
  } catch (err) {
    const data = generateMockCurrentWeather(district);
    const temp = Math.round(data.main?.temp ?? 0);
    const desc = (data.weather && data.weather[0] && data.weather[0].description) || 'Clear';
    const main = (data.weather && data.weather[0] && data.weather[0].main) || '';

    tempEl.textContent = temp + '°C';
    descEl.textContent = desc;
    iconEl.textContent = chooseIcon(main, desc);
    sugEl.textContent = `Real-time weather unavailable. ${travelSuggestion(main.toLowerCase(), temp)}`;
  }
}

function displayDestinationForecastCalendar(district) {
  const container = document.getElementById('destForecastContainer');
  if (!container) return;

  container.innerHTML = '';

  const now = new Date();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const defaultDate = new Date(today);

  const formatDate = (value) => {
    const yyyy = value.getFullYear();
    const mm = String(value.getMonth() + 1).padStart(2, '0');
    const dd = String(value.getDate()).padStart(2, '0');
    return `${yyyy}-${mm}-${dd}`;
  };

  const parseDate = (value) => new Date(`${value}T00:00:00`);
  const monthNames = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

  let selectedTripDate = formatDate(defaultDate);
  let viewYear = defaultDate.getFullYear();
  let viewMonth = defaultDate.getMonth();

  const controls = document.createElement('div');
  controls.id = 'destPageTripDateControls';
  controls.style.marginTop = '20px';
  controls.innerHTML = `
    <div class="trip-calendar-shell">
      <div class="trip-calendar-title-row">
        <div>
          <div class="trip-calendar-label">Select Trip Date</div>
          <div class="trip-calendar-help">Choose a date to see weather forecast and travel advisory.</div>
        </div>
        <div class="trip-calendar-nav">
          <select id="destPageTripCalMonth" class="trip-calendar-select" aria-label="Select month"></select>
          <select id="destPageTripCalYear" class="trip-calendar-select" aria-label="Select year"></select>
        </div>
      </div>
      <div class="trip-calendar-weekdays" aria-hidden="true">
        <span>Sun</span><span>Mon</span><span>Tue</span><span>Wed</span><span>Thu</span><span>Fri</span><span>Sat</span>
      </div>
      <div id="destPageTripCalendarGrid" class="trip-calendar-grid"></div>
      <div class="trip-calendar-meta">
        Selected: <strong id="destPageTripCalendarSelected"></strong>
      </div>
      <button id="destPageCheckTripWeather" type="button" class="button primary trip-calendar-check">Check weather for this date</button>
    </div>
    <div class="weather-suggestion" id="destPageTripForecastOutput" style="margin-top:20px;">Choose a date to see detailed forecast.</div>
  `;

  container.appendChild(controls);

  const checkBtn = document.getElementById('destPageCheckTripWeather');
  const grid = document.getElementById('destPageTripCalendarGrid');
  const monthSelect = document.getElementById('destPageTripCalMonth');
  const yearSelect = document.getElementById('destPageTripCalYear');
  const selectedLabel = document.getElementById('destPageTripCalendarSelected');
  const output = document.getElementById('destPageTripForecastOutput');

  const monthStart = (year, month) => new Date(year, month, 1);

  const formatNiceDate = (value) => value.toLocaleDateString('en-US', {
    weekday: 'long',
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  });

  const populateSelectors = () => {
    if (monthSelect && !monthSelect.options.length) {
      monthSelect.innerHTML = monthNames.map((month, index) => `<option value="${index}">${month}</option>`).join('');
    }

    if (yearSelect && !yearSelect.options.length) {
      const startYear = 1990;
      const endYear = 2035;
      yearSelect.innerHTML = Array.from({ length: endYear - startYear + 1 }, (_, index) => startYear + index)
        .map((year) => `<option value="${year}">${year}</option>`).join('');
    }

    if (monthSelect) monthSelect.value = String(viewMonth);
    if (yearSelect) yearSelect.value = String(viewYear);
  };

  const renderCalendar = () => {
    viewYear = Number(yearSelect?.value || viewYear);
    viewMonth = Number(monthSelect?.value || viewMonth);

    const firstDay = monthStart(viewYear, viewMonth);
    const firstWeekday = firstDay.getDay();
    const daysInMonth = new Date(viewYear, viewMonth + 1, 0).getDate();

    if (selectedLabel) selectedLabel.textContent = formatNiceDate(parseDate(selectedTripDate));

    if (!grid) return;
    grid.innerHTML = '';

    for (let empty = 0; empty < firstWeekday; empty += 1) {
      const spacer = document.createElement('span');
      spacer.className = 'trip-calendar-spacer';
      grid.appendChild(spacer);
    }

    for (let day = 1; day <= daysInMonth; day += 1) {
      const value = new Date(viewYear, viewMonth, day);
      const dateKey = formatDate(value);
      const button = document.createElement('button');
      button.type = 'button';
      button.className = 'trip-calendar-day';
      button.textContent = String(day);
      button.dataset.date = dateKey;

      if (dateKey === selectedTripDate) button.classList.add('is-selected');
      if (dateKey === formatDate(today)) button.classList.add('is-today');

      button.addEventListener('click', () => {
        selectedTripDate = dateKey;
        renderCalendar();
        fetchDestinationPageForecast(district, selectedTripDate);
      });

      grid.appendChild(button);
    }
  };

  if (monthSelect) {
    monthSelect.addEventListener('change', () => {
      renderCalendar();
    });
  }

  if (yearSelect) {
    yearSelect.addEventListener('change', () => {
      renderCalendar();
    });
  }

  populateSelectors();

  checkBtn.addEventListener('click', () => {
    const dateVal = selectedTripDate || '';

    if (!dateVal) {
      output.textContent = 'Please select a trip date.';
      return;
    }

    fetchDestinationPageForecast(district, dateVal);
  });

  renderCalendar();
}

async function fetchDestinationPageForecast(district, dateVal) {
  const output = document.getElementById('destPageTripForecastOutput');
  if (!output) return;

  output.textContent = 'Loading forecast...';

  try {
    let summary;
    try {
      const location = await resolveWeatherLocation(district);
      const apiData = await fetchOpenMeteoWeather(location);
      summary = buildForecastSummaryFromRealData(location, dateVal, apiData);
      
      if (summary?.available === false) {
        throw new Error(summary.message || 'No live forecast data available');
      }
    } catch (err) {
      const data = generateMockForecast(district, dateVal);
      summary = generateMockSummary(district, dateVal, data);
    }
    
    output.innerHTML = renderForecastSummary(summary, district, dateVal);
  } catch (err) {
    output.innerHTML = `<strong>Forecast Error:</strong> ${err.message}`;
  }
}



async function displayDestinationDetailMap(district) {
  const container = document.getElementById('destDetailMap');
  const mapLabel = document.getElementById('destMapLocationName');
  if (!container) return;

  const placeIndex = getDestinationFromURL();
  const place = spots[placeIndex];
  const spotName = place ? place[0] : district;

  if (mapLabel) {
    mapLabel.textContent = spotName;
  }

  // Destroy existing map if any
  if (window.destPageMapInstance) {
    if (typeof window.destPageMapInstance.remove === 'function') {
      window.destPageMapInstance.remove();
    }
    window.destPageMapInstance = null;
  }

  container.innerHTML = '<div style="padding:20px;">Locating exact spot...</div>';

  let coords = (place && place[3]) || null;
  
  if (!coords) {
    try {
      const q = encodeURIComponent(`${spotName} ${district} Bangladesh`);
      const res = await fetch(`https://nominatim.openstreetmap.org/search?format=json&q=${q}`);
      const data = await res.json();
      if (data && data.length > 0) {
        coords = [parseFloat(data[0].lat), parseFloat(data[0].lon)];
      }
    } catch (e) {
      console.warn("Geocoding failed", e);
    }
  }

  // Fallback to district coords if all else fails
  if (!coords) {
    coords = districtCoords[district] || [23.685, 90.3563];
  }

  container.innerHTML = '';

  // Try Google Maps first
  if (window.google && window.google.maps) {
    const mapInstance = new google.maps.Map(container, {
      center: { lat: coords[0], lng: coords[1] },
      zoom: 17, // Much closer zoom to focus exactly on the spot
      mapTypeControl: true,
      streetViewControl: true,
      fullscreenControl: true
    });

    const gLink = `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(district + ' Bangladesh')}`;
    const externalLinkEl = document.getElementById('externalMapLink');
    if (externalLinkEl) externalLinkEl.href = gLink;

    const marker = new google.maps.Marker({
      position: { lat: coords[0], lng: coords[1] },
      map: mapInstance,
      title: spotName
    });

    const info = new google.maps.InfoWindow({
      content: `
        <div style="color:#333; padding:5px;">
          <strong style="display:block; font-size:1rem; margin-bottom:4px;">${spotName}</strong>
          <a href="${gLink}" target="_blank" style="color:#4285F4; font-weight:600; text-decoration:none;">View on Google Maps</a>
        </div>
      `
    });

    marker.addListener('click', () => {
      info.open({ map: mapInstance, anchor: marker });
    });


    window.destPageMapInstance = mapInstance;
    return;
  }

  // Leaflet fallback
  const mapInstance = L.map(container).setView(coords, 16);

  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    attribution: '© OpenStreetMap contributors',
    maxZoom: 19,
  }).addTo(mapInstance);

  L.circleMarker(coords, {
    radius: 12,
    fillColor: '#ff7e5f',
    color: '#fff',
    weight: 3,
    opacity: 1,
    fillOpacity: 0.9,
  }).addTo(mapInstance).bindPopup(`<strong>${spotName}</strong><br>Destination Location`);

  window.destPageMapInstance = mapInstance;

  requestAnimationFrame(() => {
    mapInstance.invalidateSize();
  });
}


function displayDestinationGuide(place) {
  const [name, district, category] = place;
  const container = document.getElementById('destGuideContent');
  if (!container) return;

  const tips = getTravelTips(category);
  const introGuide = siteContentCache?.travelGuide || '';
  // Build a simplified two-part guide: Essential Information + Guides
  const dbId = spots.indexOf(place) + 1;
  const coords = districtCoords[district] ? districtCoords[district].join(', ') : 'N/A';

  const essentialHTML = `
    <div class="guide-block" style="max-width:800px;">
      <h3 style="margin-top:0;">${name}</h3>
      <p style="font-size:1.05rem; line-height:1.8; color:var(--muted); margin-bottom:12px;">
        ${name} is a ${cats[category].toLowerCase()} destination located in ${district}. This guide provides essential information for planning your visit.
      </p>

      ${introGuide ? `<div style="margin:14px 0;padding:12px;border-radius:12px;background:rgba(255,255,255,0.03);">${escapeHtml(introGuide)}</div>` : ''}

      <section class="guide-section">
        <h4>📋 Essential Information</h4>
        <div class="travel-tips">
          ${tips.map(tip => `<p>• ${tip}</p>`).join('')}
        </div>

        <div style="margin-top:12px;">
          <strong>🕐 Best Time to Visit:</strong>
          <p style="margin:6px 0 0 0;">${getSeasonalInfo(category)}</p>
        </div>

        <div style="margin-top:12px;">
          <strong>💡 Local Information:</strong>
          <ul style="list-style:none; padding:0; margin:8px 0 0 0;">
            <li>📍 <strong>District:</strong> ${district}</li>
            <li>🏷️ <strong>Category:</strong> ${cats[category]}</li>
          </ul>
        </div>
      </section>
    </div>
  `;

  // Generate guide contacts (randomized placeholders)
  const guides = generateRandomGuides(3);
  const guidesHTML = `
    <div class="guide-block" style="max-width:800px; margin-top:20px;">
      <h4>🧑‍💼 Guides & Contacts</h4>
      <div class="guides-grid" style="display:flex; gap:12px; flex-wrap:wrap; margin-top:10px;">
        ${guides.map(g => `
          <div class="guide-card" style="flex:1 1 250px; background:var(--panel); padding:12px; border-radius:8px;">
            <div style="display:flex; align-items:center; gap:10px;">
              <div style="width:44px; height:44px; border-radius:50%; background:#2f4f3f; display:grid; place-items:center; color:#fff; font-weight:700;">
                ${g.initials}
              </div>
              <div>
                <div style="font-weight:600;">${g.name}</div>
              </div>
            </div>
            <div style="margin-top:10px; font-size:0.95rem; color:var(--muted);">
              <div>✉️ <a href="mailto:${g.email}" style="color:inherit; text-decoration:underline;">${g.email}</a></div>
              <div style="margin-top:6px;">📞 ${g.phone}</div>
            </div>
          </div>
        `).join('')}
      </div>
    </div>
  `;

  container.innerHTML = essentialHTML + guidesHTML;
}

// Helper: generate placeholder guides with random emails and phones
function generateRandomGuides(count = 3) {
  const firstNames = ['Arif', 'Nusrat', 'Rafiq', 'Maya', 'Tasnim', 'Sujon', 'Jahan', 'Rumana', 'Faruk', 'Lima'];
  const roles = ['Local Guide', 'Beach Guide', 'Nature Guide', 'Cultural Guide', 'History Guide'];
  const domains = ['example.com', 'travelsbd.com', 'guidehub.com', 'tourmail.com'];
  const bases = ['Cox\'s Bazar', 'Dhaka', 'Sylhet', 'Bandarban', 'Rangamati'];

  const list = [];
  for (let i = 0; i < count; i++) {
    const fn = firstNames[Math.floor(Math.random() * firstNames.length)];
    const ln = firstNames[Math.floor(Math.random() * firstNames.length)];
    const name = `${fn} ${ln}`;
    const initials = (fn[0] + ln[0]).toUpperCase();
    const role = roles[Math.floor(Math.random() * roles.length)];
    const domain = domains[Math.floor(Math.random() * domains.length)];
    const email = `${fn.toLowerCase()}.${ln.toLowerCase()}@${domain}`;
    const phone = `+88 ${Math.floor(10000000 + Math.random() * 90000000)}`;
    const base = bases[Math.floor(Math.random() * bases.length)];

    list.push({ name, initials, role, email, phone, base });
  }

  return list;
}

function getTravelTips(category) {
  const tipsByCategory = {
    beach: [
      'Best visited during November to February for pleasant weather',
      'Pack sunscreen, hat, and light clothing',
      'Carry plenty of water and stay hydrated',
      'Check tide times and weather conditions before visiting',
      'Respect local customs and swimming guidelines',
    ],
    nature: [
      'Wear comfortable hiking shoes and appropriate weather gear',
      'Start early in the morning to avoid crowds',
      'Bring insect repellent, first-aid kit, and plenty of water',
      'Check weather conditions and trail accessibility beforehand',
      'Hire local guides for better safety and experience',
    ],
    history: [
      'Hire a knowledgeable local guide for deeper understanding',
      'Visit in early morning for better photography and fewer crowds',
      'Show respect to cultural and historical sites',
      'Check opening hours and entrance fees in advance',
      'Take time to read historical markers and information boards',
    ],
    religious: [
      'Dress respectfully and modestly when visiting',
      'Remove shoes when required and follow posted guidelines',
      'Ask permission before taking photographs',
      'Respect prayer times and religious ceremonies',
      'Be mindful of cultural sensitivities and traditions',
    ],
    culture: [
      'Interact respectfully with local people and artisans',
      'Learn basic Bengali phrases to enhance your experience',
      'Try local cuisine from trusted vendors and restaurants',
      'Visit local markets and handicraft stores for authentic souvenirs',
      'Participate in local cultural events if available',
    ],
    city: [
      'Use public transport, rickshaws, or ride-sharing services',
      'Keep valuables secure and be aware of your surroundings',
      'Visit early morning for peaceful experience and better photography',
      'Try street food from popular, busy vendors',
      'Book accommodations in well-known areas',
    ],
    ecotourism: [
      'Follow "leave no trace" principles strictly',
      'Wear neutral earth tones to avoid disturbing wildlife',
      'Hire certified eco-guides for the best experience',
      'Stay on marked trails and respect protected areas',
      'Use eco-friendly products and minimize waste',
    ],
    wetland: [
      'Wear waterproof clothing and sturdy waterproof footwear',
      'Bring binoculars for bird watching opportunities',
      'Go with experienced local guides who know the area',
      'Visit during winter months for best wildlife viewing',
      'Respect wildlife habitats and maintain distance from animals',
    ],
  };

  return tipsByCategory[category] || [
    'Plan your visit well in advance',
    'Check current weather and local conditions',
    'Respect local customs and culture',
    'Book accommodations and transport ahead of time',
  ];
}

function getSeasonalInfo(category) {
  const seasonByCategory = {
    beach: 'November to February offers the best weather for beach visits. Avoid monsoon season (June-September).',
    nature: 'October to March is ideal for trekking and nature activities. Avoid heavy monsoon seasons.',
    history: 'October to March is best for sightseeing. Cooler weather makes exploring comfortable.',
    religious: 'Year-round accessible, but check for religious festivals and events for special experiences.',
    culture: 'October to March is most pleasant. Many cultural events happen during this season.',
    city: 'October to March offers pleasant weather. Avoid monsoon and peak summer heat.',
    ecotourism: 'November to February is best for eco-tours. Maximum wildlife visibility during these months.',
    wetland: 'Winter (December-February) is best for wetland visits and bird watching.',
  };

  return seasonByCategory[category] || 'Year-round accessible. Check weather before planning.';
}

function getBudgetRecommendation(place) {
  const [name, district, category] = place || [];
  const lowerDistrict = (district || '').toLowerCase();
  const lowerName = (name || '').toLowerCase();

  const isBeach = ['beach', 'coastal', 'island'].includes(category) || lowerDistrict.includes('cox') || lowerDistrict.includes('kuakata') || lowerDistrict.includes('patuakhali') || lowerDistrict.includes('noakhali') || lowerName.includes('saint martin');
  const isHill = ['nature', 'ecotourism'].includes(category) || lowerDistrict.includes('bandarban') || lowerDistrict.includes('sajek') || lowerDistrict.includes('rangamati') || lowerDistrict.includes('khagrachari');
  const isWetland = category === 'wetland' || lowerDistrict.includes('sunamganj') || lowerDistrict.includes('haor');
  const isHistory = ['history', 'culture', 'religious', 'city'].includes(category) || lowerDistrict.includes('dhaka') || lowerDistrict.includes('bogura') || lowerDistrict.includes('paharpur') || lowerDistrict.includes('bagerhat');

  if (isBeach) {
    return {
      transport: 'bus_ac',
      hotel: 'beach_resort',
      guide: 'beach',
      food: 'seafood',
      text: 'Recommended for beach/coastal trips: AC bus or launch, beach resort, beach guide, and seafood dining.',
    };
  }

  if (isHill) {
    return {
      transport: 'jeep',
      hotel: 'hill_cottage',
      guide: 'hill',
      food: 'hill_cuisine',
      text: 'Recommended for hill trips: jeep/4x4, hill cottage, hill trek guide, and local hill cuisine.',
    };
  }

  if (isWetland) {
    return {
      transport: 'launch_deck',
      hotel: 'homestay',
      guide: 'boat',
      food: 'boat_meal',
      text: 'Recommended for haor/wetland trips: launch travel, homestay, boat guide, and boat meals.',
    };
  }

  if (isHistory) {
    return {
      transport: 'train_chair',
      hotel: '3star',
      guide: 'heritage',
      food: 'family',
      text: 'Recommended for city/heritage trips: train or AC bus, 3-star hotel, heritage guide, and family dining.',
    };
  }

  return {
    transport: 'bus_nonac',
    hotel: 'normal',
    guide: 'local',
    food: 'standard',
    text: 'Recommended starting point: budget hotel, local guide, standard dining, and non-AC bus travel.',
  };
}

async function displayHotels(place) {
  const list = document.getElementById('hotelResultsList');
  if (!list) return;

  const [name, district, category] = place || [];

  const checkinInput = document.getElementById('hotelCheckin');
  const checkoutInput = document.getElementById('hotelCheckout');
  const searchBtn = document.getElementById('searchHotelsBtn');
  const dateSummaryEl = document.getElementById('hotelDateSummary');

  // Set default dates
  const today = new Date();
  const tomorrow = new Date();
  tomorrow.setDate(today.getDate() + 1);
  
  if (checkinInput && !checkinInput.value) {
    checkinInput.value = today.toISOString().split('T')[0];
  }
  if (checkoutInput && !checkoutInput.value) {
    checkoutInput.value = tomorrow.toISOString().split('T')[0];
  }

  const updateDateSummary = () => {
    if (!dateSummaryEl) return;
    const checkin = checkinInput?.value || '';
    const checkout = checkoutInput?.value || '';
    if (!checkin || !checkout) {
      dateSummaryEl.textContent = 'Select check-in and check-out dates to see live availability.';
      return;
    }

    const checkinDate = new Date(`${checkin}T00:00:00`);
    const checkoutDate = new Date(`${checkout}T00:00:00`);
    const nights = Number.isNaN(checkinDate.getTime()) || Number.isNaN(checkoutDate.getTime())
      ? ''
      : Math.max(1, Math.ceil((checkoutDate - checkinDate) / 86400000));

    dateSummaryEl.innerHTML = nights
      ? `Selected stay: <strong>${checkin}</strong> to <strong>${checkout}</strong> (${nights} night${nights === 1 ? '' : 's'}). Results are adjusted for this stay window.`
      : `Selected stay: <strong>${checkin}</strong> to <strong>${checkout}</strong>. Results are adjusted for this stay window.`;
  };

  async function performSearch() {
    const checkin = checkinInput?.value || '';
    const checkout = checkoutInput?.value || '';
    updateDateSummary();
    list.innerHTML = '<div style="color:var(--muted); padding:10px 0;">Searching for accommodations...</div>';
    try {
      const res = await fetch(`${API_BASE_URL}/api/hotels/search`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ city: district, destinationName: name, category, checkin, checkout })
      });
      const data = await res.json();
      
      if (!data.hotels || data.hotels.length === 0) {
        list.innerHTML = '<div style="color:var(--muted); padding:10px 0;">No matching hotels found for the selected destination and dates.</div>';
        return;
      }

      const statusOrder = { available: 0, limited: 1, unavailable: 2 };
      const sortedHotels = [...data.hotels].sort((a, b) => {
        const statusDiff = (statusOrder[a.availability] ?? 3) - (statusOrder[b.availability] ?? 3);
        if (statusDiff !== 0) return statusDiff;
        return (a.price || 0) - (b.price || 0);
      });

      const labelForStatus = (status) => {
        if (status === 'available') return 'Available';
        if (status === 'limited') return 'Limited availability';
        return 'Unavailable for selected dates';
      };

      list.innerHTML = `
        <div style="display:flex; justify-content:space-between; align-items:flex-start; gap:12px; margin-bottom:12px; flex-wrap:wrap;">
          <div style="color:var(--muted); font-size:0.88rem; line-height:1.45;">
            <strong style="color:var(--text);">${name || district || 'Selected destination'}</strong><br>
            ${checkin && checkout ? `Live availability for <strong>${checkin}</strong> to <strong>${checkout}</strong>.` : 'Live availability for the selected trip dates.'}
          </div>
          <div style="font-size:0.8rem; color:var(--muted);">${sortedHotels.filter(h => h.availability === 'available').length} available options</div>
        </div>
        ${sortedHotels.map(h => `
          <div class="hotel-card" style="padding:16px; border:1px solid rgba(255,255,255,0.08); border-radius:12px; margin-bottom:12px; background: rgba(255,255,255,0.02); display: flex; justify-content: space-between; align-items: center; gap:16px; transition: all 0.3s ease;">
            <div style="min-width:0;">
              <strong style="color: var(--accent); font-size: 1.05rem; display:block;">🏨 ${h.name}</strong>
              <div style="font-size:0.85rem; color:var(--muted); margin-top:6px; line-height:1.45;">
                Rating: ${Number(h.rating || 0).toFixed(1)}★ | Est. ৳${Number(h.price || 0).toLocaleString()} / night | ${labelForStatus(h.availability)}
              </div>
              <div style="font-size:0.78rem; color:${h.availability === 'available' ? '#a9e8bb' : h.availability === 'limited' ? '#F5C26B' : '#ff9a9a'}; margin-top:4px; line-height:1.4;">
                ${h.note || 'Availability is updated for the selected dates.'}
              </div>
            </div>
            <a href="${h.url}" target="_blank" rel="noopener noreferrer" class="button secondary" style="padding:6px 14px; font-size:0.8rem; border-radius: 8px; white-space:nowrap; ${h.availability === 'unavailable' ? 'opacity:0.7;' : ''}">${h.availability === 'unavailable' ? 'Check Alternative' : 'Visit Website'}</a>
          </div>
        `).join('')}
      `;
    } catch (e) {
      list.innerHTML = '<div style="color:#F5A623; padding:10px 0;">Failed to load hotels. Please try again.</div>';
    }
  }

  if (searchBtn && !searchBtn.dataset.listenerAdded) {
    searchBtn.addEventListener('click', performSearch);
    searchBtn.dataset.listenerAdded = 'true';
  }

  if (checkinInput && !checkinInput.dataset.listenerAdded) {
    checkinInput.addEventListener('change', performSearch);
    checkinInput.dataset.listenerAdded = 'true';
  }

  if (checkoutInput && !checkoutInput.dataset.listenerAdded) {
    checkoutInput.addEventListener('change', performSearch);
    checkoutInput.dataset.listenerAdded = 'true';
  }

  // Initial search
  await performSearch();
}

function displayRelatedDestinations(district, currentIndex) {
  const container = document.getElementById('relatedDestinations');
  if (!container) return;

  const currentSpot = spots[currentIndex];
  if (!currentSpot) return;

  function haversineDistance(lat1, lon1, lat2, lon2) {
    const R = 6371; // Earth radius in km
    const dLat = (lat2 - lat1) * Math.PI / 180;
    const dLon = (lon2 - lon1) * Math.PI / 180;
    const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
      Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
      Math.sin(dLon/2) * Math.sin(dLon/2);
    return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  }

  function getSpotCoords(s) {
    if (s[3] && Array.isArray(s[3])) return s[3];
    const distName = s[1];
    if (window.districtCoords && window.districtCoords[distName]) {
      return window.districtCoords[distName];
    }
    return null;
  }

  const currentCoords = getSpotCoords(currentSpot) || [23.685, 90.3563];

  // Calculate distance from current spot to all other spots, sort by distance
  const related = spots
    .map((place, idx) => {
      const coords = getSpotCoords(place) || [23.685, 90.3563];
      const dist = haversineDistance(currentCoords[0], currentCoords[1], coords[0], coords[1]);
      return { place, idx, dist };
    })
    .filter(item => item.idx !== currentIndex)
    .sort((a, b) => a.dist - b.dist)
    .slice(0, 4);

  if (related.length === 0) {
    container.innerHTML = '<p style="grid-column: 1/-1;">No other destinations found.</p>';
    return;
  }

  container.innerHTML = related.map(({ place, idx, dist }) => {
    const [name, placedistrict, category] = place;
    const gradient = getSpotGradient(place);
    const distText = dist < 1 ? 'Under 1 km away' : `${Math.round(dist)} km away`;

    return `
      <article class="related-card" onclick="goToDestination(${idx})" style="cursor:pointer;">
        <div class="related-card-image" style="background-image: ${gradient}"></div>
        <div class="related-card-info">
          <h4 style="margin: 0 0 6px 0; font-size: 1.05rem; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;">${name}</h4>
          <p style="margin: 0 0 8px 0; font-size: 0.82rem; color: var(--muted);">${cats[category]} &nbsp;•&nbsp; ${placedistrict}</p>
          <div style="font-size:0.8rem; color:var(--primary-light); display:flex; align-items:center; gap:6px; margin-bottom:12px;">
            <i class="fas fa-map-marker-alt" style="color:var(--primary);"></i> ${distText}
          </div>
          <span class="button primary" style="width: 100%; display: flex; align-items: center; justify-content: center; font-size: 0.85rem; padding: 8px 12px; border-radius: 8px;">View Details</span>
        </div>
      </article>
    `;
  }).join('');
}

function goToDestination(index) {
  window.location.href = `destination.html?id=${index}`;
}

function showError(message) {
  const main = document.getElementById('destDetailMain');
  if (main) {
    main.innerHTML = `<div style="text-align: center; padding: 60px 20px; color: var(--muted);">
      <h2>${message}</h2>
      <p>Redirecting to home page...</p>
    </div>`;
  }
}

function initReviewSection() {
  const destIndex = getDestinationFromURL();
  const destinationName = spots[destIndex]?.[0] || '';
  const starButtons = document.querySelectorAll('.star-rating .star');
  const ratingText = document.getElementById('ratingText');
  const clearBtn = document.getElementById('clearReviewBtn');
  const submitBtn = document.getElementById('submitReviewBtn');
  const textarea = document.getElementById('reviewTextarea');
  const reviewList = document.getElementById('reviewList');

  async function loadReviews() {
    if (!reviewList) return;
    reviewList.innerHTML = '<p>Loading reviews...</p>';
    try {
      const response = await fetch(`${API_BASE_URL}/api/reviews?destinationName=${encodeURIComponent(destinationName)}`);
      const data = await response.json();
      if (!response.ok) throw new Error(data.error || 'Could not load reviews');

      const reviews = Array.isArray(data.reviews) ? data.reviews : [];
      if (!reviews.length) {
        reviewList.innerHTML = '<p>No reviews yet. Be the first to share one.</p>';
        return;
      }

      reviewList.innerHTML = reviews.map((review) => {
        const stars = '★★★★★'.slice(0, review.rating) + '☆☆☆☆☆'.slice(0, 5 - review.rating);
        const response = review.adminResponse
          ? `<div class="review-response"><strong>Admin response:</strong> <p>${escapeHtml(review.adminResponse.text)}</p></div>`
          : '<div class="review-response review-response-empty">No admin response yet.</div>';
        return `
          <article class="review-card">
            <div class="review-card-head">
              <strong>${escapeHtml(review.userName || 'Traveler')}</strong>
              <span>${stars}</span>
            </div>
            <p>${escapeHtml(review.text)}</p>
            ${response}
          </article>
        `;
      }).join('');
    } catch (error) {
      reviewList.innerHTML = `<p>${escapeHtml(error.message || 'Could not load reviews')}</p>`;
    }
  }

  function escapeHtml(value) {
    return String(value)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');
  }

  // Star rating interactions
  if (starButtons.length) {
    starButtons.forEach(button => {
      button.addEventListener('click', (e) => {
        e.preventDefault();
        currentReviewRating = parseInt(button.dataset.rating);
        
        // Update visual state
        starButtons.forEach((btn, idx) => {
          if (idx < currentReviewRating) {
            btn.classList.add('active');
          } else {
            btn.classList.remove('active');
          }
        });

        // Update rating text
        const ratingLabels = ['', '1 star', '2 stars', '3 stars', '4 stars', '5 stars'];
        if (ratingText) {
          ratingText.textContent = ratingLabels[currentReviewRating] || 'Select a rating';
        }
      });
    });
  }

  // Clear button
  if (clearBtn) {
    clearBtn.addEventListener('click', () => {
      currentReviewRating = 0;
      if (textarea) textarea.value = '';
      if (ratingText) ratingText.textContent = 'Select a rating';
      starButtons.forEach(btn => btn.classList.remove('active'));
    });
  }

  // Submit button
  if (submitBtn) {
    submitBtn.addEventListener('click', () => {
      const reviewText = textarea?.value.trim() || '';
      
      if (currentReviewRating === 0) {
        alert('Please select a rating before submitting your review.');
        return;
      }

      if (reviewText.length < 10) {
        alert('Please write at least 10 characters in your review.');
        return;
      }

      const token = localStorage.getItem('tourismAuthToken') || '';
      if (!token) {
        alert('Please sign in before publishing a review.');
        return;
      }

      fetch(`${API_BASE_URL}/api/reviews`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({
          destinationId: String(destIndex),
          destinationName,
          rating: currentReviewRating,
          text: reviewText,
        }),
      })
        .then(async (response) => {
          const data = await response.json().catch(() => ({}));
          if (!response.ok) throw new Error(data.error || 'Could not submit review');
          alert('Your review has been saved.');
          currentReviewRating = 0;
          if (textarea) textarea.value = '';
          if (ratingText) ratingText.textContent = 'Select a rating';
          starButtons.forEach((btn) => btn.classList.remove('active'));
          loadReviews();
        })
        .catch((error) => {
          alert(error.message || 'Could not submit review');
        });
    });
  }

  loadReviews();
}

function getBudgetByCategory(category) {
  const fallbackBudgets = {
    beach: { accommodation: 800, food: 250, transport: 200 },
    nature: { accommodation: 600, food: 200, transport: 150 },
    history: { accommodation: 700, food: 250, transport: 150 },
    religious: { accommodation: 500, food: 200, transport: 150 },
    culture: { accommodation: 700, food: 250, transport: 200 },
    city: { accommodation: 1000, food: 300, transport: 250 },
    ecotourism: { accommodation: 700, food: 200, transport: 150 },
    wetland: { accommodation: 500, food: 200, transport: 150 }
  };

  const budgets = (siteContentCache?.budgets && Object.keys(siteContentCache.budgets).length > 0)
    ? siteContentCache.budgets
    : fallbackBudgets;

  return budgets[category] || budgets.nature || fallbackBudgets.nature;
}

function getSelectedOptionLabel(selectEl, fallback = '') {
  if (!selectEl) return fallback;
  const selectedOption = selectEl.options?.[selectEl.selectedIndex];
  return selectedOption ? selectedOption.textContent.trim() : fallback;
}

const hotelTierMultipliers = {
  normal: 1,
  guesthouse: 1.15,
  homestay: 1.25,
  beach_resort: 2.9,
  hill_cottage: 2.5,
  forest_lodge: 2.3,
  rest_house: 1.4,
  '3star': 2.8,
  boutique: 3.2,
  '5star': 5.6,
  luxury_suite: 6.4,
  others: 2
};

const guideTierRates = {
  none: 0,
  local: 600,
  licensed: 1500,
  beach: 850,
  hill: 1400,
  forest: 1600,
  eco: 1100,
  heritage: 1200,
  religious: 950,
  boat: 1000,
  tribal: 1500,
  translator: 1200,
  private_vip: 2500,
  others: 1200
};

const foodTierRates = {
  street: 180,
  mess: 240,
  breakfast: 150,
  standard: 350,
  family: 450,
  fastfood: 320,
  seafood: 650,
  hill_cuisine: 520,
  tea_garden: 380,
  boat_meal: 500,
  buffet: 850,
  fine_dining: 1200,
  resort_dining: 1000,
  others: 500
};

const transportModePricing = {
  bus_nonac: { perKm: 1.2, minFare: 80 },
  bus_ac: { perKm: 2.2, minFare: 150 },
  bus_sleeper: { perKm: 2.6, minFare: 220 },
  train_shovon: { perKm: 1.0, minFare: 80 },
  train_chair: { perKm: 1.5, minFare: 120 },
  train_ac: { perKm: 2.0, minFare: 200 },
  train_sleeper: { perKm: 2.4, minFare: 250 },
  launch_deck: { perKm: 0.8, minFare: 100 },
  launch_cabin: { perKm: 2.2, minFare: 500 },
  ferry: { perKm: 0.9, minFare: 120 },
  boat: { perKm: 0.7, minFare: 80 },
  microbus: { perKm: 3.5, minFare: 600 },
  private_car: { perKm: 4.2, minFare: 900 },
  cng: { perKm: 2.8, minFare: 180 },
  jeep: { perKm: 5.0, minFare: 1200 },
  air: { perKm: 5.0, minFare: 2000 }
};

function initBudgetCalculator(placeOrCategory) {
  const personInput = document.getElementById('budgetPersons');
  const daysInput = document.getElementById('budgetDays');
  const accEl = document.getElementById('budgetAccommodation');
  const foodEl = document.getElementById('budgetFood');
  const localTransportEl = document.getElementById('budgetLocalTransport');
  const guideEl = document.getElementById('budgetGuide');
  const travelCostEl = document.getElementById('budgetTravelCost');
  const perPersonPerDayEl = document.getElementById('budgetPerPersonPerDay');
  const totalEl = document.getElementById('budgetTotal');
  const routeInfoEl = document.getElementById('budgetRouteInfo');
  const originSelect = document.getElementById('budgetOriginDest');
  const transportModeSelect = document.getElementById('budgetTransportMode');
  const hotelTierSelect = document.getElementById('budgetHotelTier');
  const guideTierSelect = document.getElementById('budgetGuideTier');
  const foodTierSelect = document.getElementById('budgetFoodTier');
  const suggestionTextEl = document.getElementById('budgetSuggestionText');
  const applySuggestionBtn = document.getElementById('applyBudgetSuggestionBtn');

  if (!personInput || !daysInput) return;

  const category = Array.isArray(placeOrCategory) ? placeOrCategory[2] : placeOrCategory;
  const budget = getBudgetByCategory(category);
  const recommendation = getBudgetRecommendation(Array.isArray(placeOrCategory) ? placeOrCategory : [null, null, category]);

  function haversineDist(lat1, lon1, lat2, lon2) {
    const R = 6371;
    const dLat = (lat2 - lat1) * Math.PI / 180;
    const dLon = (lon2 - lon1) * Math.PI / 180;
    const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
      Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
      Math.sin(dLon/2) * Math.sin(dLon/2);
    return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  }

  // Get the destination district from the page
  const destIndex = getDestinationFromURL();
  const destDistrict = spots[destIndex]?.[1] || '';

  function updateCalculation() {
    const persons = parseInt(personInput.value) || 1;
    const days = parseInt(daysInput.value) || 1;
    const origin = originSelect ? originSelect.value : '';
    const transportMode = transportModeSelect ? transportModeSelect.value : 'bus_nonac';
    const hotelTier = hotelTierSelect ? hotelTierSelect.value : 'normal';
    const guideTier = guideTierSelect ? guideTierSelect.value : 'none';
    const foodTier = foodTierSelect ? foodTierSelect.value : 'standard';
    const transportLabel = getSelectedOptionLabel(transportModeSelect, 'Bus - Non-AC');
    const hotelLabel = getSelectedOptionLabel(hotelTierSelect, 'Normal / Economy Hotel');
    const guideLabel = getSelectedOptionLabel(guideTierSelect, 'No Guide (Self-Explore)');
    const foodLabel = getSelectedOptionLabel(foodTierSelect, 'Standard Restaurant Dining');

    // Calculate lodging rate
    const hotelMultiplier = hotelTierMultipliers[hotelTier] || 1;
    const accPerNight = Math.round(budget.accommodation * hotelMultiplier);

    // Calculate food quality tier
    const foodPerDay = foodTierRates[foodTier] || foodTierRates.standard;

    // Calculate guide daily flat charge
    const guidePerDay = guideTierRates[guideTier] || 0;

    const localTransportPerDay = budget.transport;

    // Calculate travel cost based on distance
    let roundTripPerPerson = 0;
    let routeText = '';

    if (origin && destDistrict) {
      const oCoords = districtCoords[origin];
      const dCoords = districtCoords[destDistrict];
      if (oCoords && dCoords) {
        let distKm = haversineDist(oCoords[0], oCoords[1], dCoords[0], dCoords[1]);
        distKm = Math.round(distKm * 1.3); // road distance factor
        const transportPricing = transportModePricing[transportMode] || transportModePricing.bus_nonac;
        const perKm = transportPricing.perKm;
        const minFare = transportPricing.minFare;
        const oneWay = Math.max(Math.round(distKm * perKm), minFare);
        roundTripPerPerson = oneWay * 2;
        
        routeText = `${origin} → ${destDistrict} (~${distKm} km by ${transportLabel})`;
      }
    }

    if (travelCostEl) {
      travelCostEl.textContent = roundTripPerPerson > 0 ? `৳ ${roundTripPerPerson.toLocaleString()}` : 'Select your district';
    }
    if (routeInfoEl) {
      routeInfoEl.textContent = routeText;
    }

    // Accommodation is for (days - 1) nights, minimum 1 night
    const nights = Math.max(1, days - 1);
    const totalLodging = accPerNight * persons * nights;
    const totalFood = foodPerDay * persons * days;
    const totalLocalTrans = localTransportPerDay * persons * days;
    const totalGuide = guidePerDay * days;
    const totalTravel = roundTripPerPerson * persons;
    
    const totalCost = totalLodging + totalFood + totalLocalTrans + totalGuide + totalTravel;
    const perPersonPerDay = Math.round((totalCost - totalTravel) / (persons * days));

    if (accEl) accEl.textContent = `৳ ${accPerNight.toLocaleString()}`;
    if (foodEl) foodEl.textContent = `৳ ${foodPerDay.toLocaleString()}`;
    if (guideEl) guideEl.textContent = `৳ ${guidePerDay.toLocaleString()}`;
    if (localTransportEl) localTransportEl.textContent = `৳ ${localTransportPerDay.toLocaleString()}`;
    if (perPersonPerDayEl) perPersonPerDayEl.textContent = `৳ ${perPersonPerDay.toLocaleString()}`;
    if (totalEl) totalEl.textContent = `৳ ${totalCost.toLocaleString()}`;

    // Sync with the booking section
    window.currentEstimatedBudget = totalCost;
    const bookingPriceEl = document.getElementById('bookingPrice');
    const bookingPricePerPersonEl = document.getElementById('bookingPricePerPerson');
    const bookingPersonsInput = document.getElementById('bookingPersons');
    const bookingEstimateDetailsEl = document.getElementById('bookingEstimateDetails');
    
    if (bookingPriceEl) {
      bookingPriceEl.textContent = `৳ ${totalCost.toLocaleString()}`;
    }
    if (bookingPricePerPersonEl) {
      bookingPricePerPersonEl.textContent = `৳ ${Math.round(totalCost / persons).toLocaleString()}`;
    }
    if (bookingPersonsInput && bookingPersonsInput.value !== String(persons)) {
      bookingPersonsInput.value = persons;
    }
    if (bookingEstimateDetailsEl) {
      if (origin) {
        bookingEstimateDetailsEl.innerHTML = `Calculated for <strong>${persons} traveler(s)</strong> from <strong>${origin}</strong> to <strong>${destDistrict}</strong> for <strong>${days} day(s)</strong> via <strong>${transportLabel}</strong> (Hotel: ${hotelLabel}, Food: ${foodLabel}, Guide: ${guideLabel}).`;
      } else {
        bookingEstimateDetailsEl.innerHTML = `<span style="color:#F5A623;">⚠️ Select your district in the Budget Calculator above for a complete estimate.</span>`;
      }
    }
  }

  function applyRecommendation(force = false) {
    if (transportModeSelect && (force || transportModeSelect.value === 'bus_nonac')) transportModeSelect.value = recommendation.transport;
    if (hotelTierSelect && (force || hotelTierSelect.value === 'normal')) hotelTierSelect.value = recommendation.hotel;
    if (guideTierSelect && (force || guideTierSelect.value === 'none')) guideTierSelect.value = recommendation.guide;
    if (foodTierSelect && (force || foodTierSelect.value === 'standard')) foodTierSelect.value = recommendation.food;
    if (suggestionTextEl) suggestionTextEl.textContent = recommendation.text;
  }

  // Add event listeners
  personInput.addEventListener('change', updateCalculation);
  daysInput.addEventListener('change', updateCalculation);
  if (originSelect) originSelect.addEventListener('change', updateCalculation);
  if (transportModeSelect) transportModeSelect.addEventListener('change', updateCalculation);
  if (hotelTierSelect) hotelTierSelect.addEventListener('change', updateCalculation);
  if (guideTierSelect) guideTierSelect.addEventListener('change', updateCalculation);
  if (foodTierSelect) foodTierSelect.addEventListener('change', updateCalculation);
  if (applySuggestionBtn) {
    applySuggestionBtn.addEventListener('click', () => {
      applyRecommendation(true);
      updateCalculation();
    });
  }

  applyRecommendation(false);

  // Button controls
  document.getElementById('personPlus')?.addEventListener('click', () => {
    let val = parseInt(personInput.value) || 1;
    if (val < 20) {
      personInput.value = val + 1;
      updateCalculation();
    }
  });

  document.getElementById('personMinus')?.addEventListener('click', () => {
    let val = parseInt(personInput.value) || 1;
    if (val > 1) {
      personInput.value = val - 1;
      updateCalculation();
    }
  });

  document.getElementById('daysPlus')?.addEventListener('click', () => {
    let val = parseInt(daysInput.value) || 1;
    if (val < 30) {
      daysInput.value = val + 1;
      updateCalculation();
    }
  });

  document.getElementById('daysMinus')?.addEventListener('click', () => {
    let val = parseInt(daysInput.value) || 1;
    if (val > 1) {
      daysInput.value = val - 1;
      updateCalculation();
    }
  });

  // Initial calculation
  updateCalculation();
}

// --- BOOKING SECTION ---
function initBookingSection(place, destIndex) {
  const dateInput = document.getElementById('bookingDate');
  const personsInput = document.getElementById('bookingPersons');
  const priceEl = document.getElementById('bookingPrice');
  const pricePerPersonEl = document.getElementById('bookingPricePerPerson');
  const confirmBtn = document.getElementById('confirmBookingBtn');
  const messageEl = document.getElementById('bookingMessage');
  const minusBtn = document.getElementById('bookingPersonsMinus');
  const plusBtn = document.getElementById('bookingPersonsPlus');

  if (!dateInput || !confirmBtn) return;

  const [name, district, category] = place;

  // Set minimum date to tomorrow
  const tomorrow = new Date();
  tomorrow.setDate(tomorrow.getDate() + 1);
  const minDate = tomorrow.toISOString().split('T')[0];
  dateInput.min = minDate;
  dateInput.value = minDate;

  // Base rate depends on budget category (matches server logic)
  const profile = getSpotFilterProfile(place);
  const budgetCategory = (profile.budget || 'low').toLowerCase();
  const baseRate = budgetCategory === 'high' ? 1700 : (budgetCategory === 'mid' ? 1250 : 800);

  function updatePrice() {
    const persons = parseInt(personsInput.value) || 1;
    const budgetPersonsInput = document.getElementById('budgetPersons');
    if (budgetPersonsInput && budgetPersonsInput.value !== String(persons)) {
      budgetPersonsInput.value = persons;
      budgetPersonsInput.dispatchEvent(new Event('change'));
    } else {
      const total = window.currentEstimatedBudget || (baseRate * persons);
      if (priceEl) priceEl.textContent = '৳ ' + total.toLocaleString();
      if (pricePerPersonEl) pricePerPersonEl.textContent = '৳ ' + Math.round(total / persons).toLocaleString();
    }
  }

  // Persons +/- buttons
  if (minusBtn) {
    minusBtn.addEventListener('click', () => {
      let val = parseInt(personsInput.value) || 1;
      if (val > 1) { personsInput.value = val - 1; updatePrice(); }
    });
  }
  if (plusBtn) {
    plusBtn.addEventListener('click', () => {
      let val = parseInt(personsInput.value) || 1;
      if (val < 20) { personsInput.value = val + 1; updatePrice(); }
    });
  }
  personsInput.addEventListener('change', updatePrice);
  updatePrice();

  // Confirm booking
  // Expose modal close function globally
  window.closeBookingModal = function() {
    const modal = document.getElementById('bookingConfirmModal');
    if (modal) {
      modal.classList.remove('is-open');
      modal.style.display = 'none';
    }
  };

  // Confirm booking with popup confirmation modal
  confirmBtn.addEventListener('click', () => {
    const token = localStorage.getItem('tourismAuthToken') || '';
    if (!token) {
      messageEl.innerHTML = '<span style="color:#F5A623;">⚠️ Please <a href="/" style="color:#a9e8bb; text-decoration:underline;">sign in</a> to book this spot.</span>';
      return;
    }

    const bookingDate = dateInput.value;
    if (!bookingDate) {
      messageEl.innerHTML = '<span style="color:#F5A623;">⚠️ Please select a travel date.</span>';
      return;
    }

    const persons = parseInt(personsInput.value) || 1;
    const estPrice = window.currentEstimatedBudget || (baseRate * persons);

    // Populate modal fields
    document.getElementById('modalDestName').textContent = name;
    document.getElementById('modalTravelDate').textContent = new Date(bookingDate).toLocaleDateString('en-US', { weekday: 'short', year: 'numeric', month: 'short', day: 'numeric' });
    document.getElementById('modalTravelers').textContent = persons + (persons === 1 ? ' traveler' : ' travelers');
    document.getElementById('modalTotalPrice').textContent = '৳ ' + estPrice.toLocaleString();

    // Show modal
    const modal = document.getElementById('bookingConfirmModal');
    if (modal) {
      modal.classList.add('is-open');
      modal.style.display = 'flex';
    }

    // Set confirm button handler in modal
    const modalConfirmBtn = document.getElementById('modalConfirmBtn');
    modalConfirmBtn.onclick = async () => {
      window.closeBookingModal();
      
      confirmBtn.disabled = true;
      confirmBtn.textContent = '⏳ Booking...';
      messageEl.innerHTML = '';

      try {
        // Look up the spot_id by name from the DB
        const spotName = name;
        const lookupRes = await fetch(`${API_BASE_URL}/api/spots/lookup?name=${encodeURIComponent(spotName)}`).catch(() => null);

        let spotId = null;

        if (lookupRes && lookupRes.ok) {
          const lookupData = await lookupRes.json();
          if (lookupData.spot) spotId = lookupData.spot.id;
        }

        // Fallback: use destination index + 1
        if (!spotId) {
          spotId = parseInt(destIndex) + 1;
        }

        const res = await fetch(`${API_BASE_URL}/api/bookings`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ' + token
          },
          body: JSON.stringify({
            spot_id: spotId,
            booking_date: bookingDate,
            persons: persons,
            price: estPrice
          })
        });

        const data = await res.json();

        if (res.ok) {
          messageEl.innerHTML = '<span style="color:#a9e8bb;">✅ ' + (data.message || 'Booking confirmed!') + '</span>';
          confirmBtn.textContent = '✅ Booked!';
          setTimeout(() => {
            confirmBtn.disabled = false;
            confirmBtn.textContent = '✅ Confirm Booking';
          }, 3000);
        } else {
          messageEl.innerHTML = '<span style="color:#F5A623;">⚠️ ' + (data.error || 'Booking failed') + '</span>';
          confirmBtn.disabled = false;
          confirmBtn.textContent = '✅ Confirm Booking';
        }
      } catch (err) {
        messageEl.innerHTML = '<span style="color:#F5A623;">⚠️ Connection error. Please try again.</span>';
        confirmBtn.disabled = false;
        confirmBtn.textContent = '✅ Confirm Booking';
      }
    };
  });
}

// Initialize when page loads
window.addEventListener('DOMContentLoaded', initDestinationPage);
