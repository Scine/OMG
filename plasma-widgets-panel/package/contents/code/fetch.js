.pragma library

// Lightweight HTTP GET helper used across the widget.
// callback(errorStringOrNull, responseText)
function httpGet(url, callback, headers) {
    var xhr = new XMLHttpRequest();
    try {
        xhr.open("GET", url, true);
    } catch (e) {
        callback("Bad URL: " + e, null);
        return;
    }
    if (headers) {
        for (var k in headers) {
            try { xhr.setRequestHeader(k, headers[k]); } catch (e) { /* ignore */ }
        }
    }
    xhr.onreadystatechange = function () {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200 || xhr.status === 0) {
                callback(null, xhr.responseText);
            } else {
                callback("HTTP " + xhr.status, null);
            }
        }
    };
    xhr.onerror = function () { callback("Network error", null); };
    try { xhr.send(); } catch (e) { callback("Request failed: " + e, null); }
}

// ================= Locations =================
// Stored as newline-separated "Name\tlat\tlon" rows.

function parseLocations(str) {
    var out = [];
    if (!str) return out;
    var rows = str.split("\n");
    for (var i = 0; i < rows.length; i++) {
        var r = rows[i].trim();
        if (r.length === 0) continue;
        var parts = r.split("\t");
        if (parts.length < 3) continue;
        var lat = parseFloat(parts[1]);
        var lon = parseFloat(parts[2]);
        if (isNaN(lat) || isNaN(lon)) continue;
        out.push({ name: parts[0], latitude: lat, longitude: lon });
    }
    return out;
}

function formatLocations(arr) {
    var rows = [];
    for (var i = 0; i < arr.length; i++) {
        rows.push(arr[i].name + "\t" + arr[i].latitude + "\t" + arr[i].longitude);
    }
    return rows.join("\n");
}

// ================= Weather codes =================

var WEATHER_CODES = {
    0: ["Clear sky", "weather-clear"],
    1: ["Mainly clear", "weather-few-clouds"],
    2: ["Partly cloudy", "weather-clouds"],
    3: ["Overcast", "weather-many-clouds"],
    45: ["Fog", "weather-fog"],
    48: ["Rime fog", "weather-fog"],
    51: ["Light drizzle", "weather-showers-scattered"],
    53: ["Drizzle", "weather-showers-scattered"],
    55: ["Dense drizzle", "weather-showers"],
    56: ["Freezing drizzle", "weather-freezing-rain"],
    57: ["Freezing drizzle", "weather-freezing-rain"],
    61: ["Light rain", "weather-showers-scattered"],
    63: ["Rain", "weather-showers"],
    65: ["Heavy rain", "weather-showers"],
    66: ["Freezing rain", "weather-freezing-rain"],
    67: ["Freezing rain", "weather-freezing-rain"],
    71: ["Light snow", "weather-snow"],
    73: ["Snow", "weather-snow"],
    75: ["Heavy snow", "weather-snow"],
    77: ["Snow grains", "weather-snow"],
    80: ["Rain showers", "weather-showers"],
    81: ["Rain showers", "weather-showers"],
    82: ["Violent showers", "weather-storm"],
    85: ["Snow showers", "weather-snow"],
    86: ["Snow showers", "weather-snow"],
    95: ["Thunderstorm", "weather-storm"],
    96: ["Thunderstorm", "weather-storm"],
    99: ["Thunderstorm", "weather-storm"]
};

function describeWeather(code) {
    var e = WEATHER_CODES[code];
    return e ? e[0] : "Unknown";
}

function weatherIcon(code, isDay) {
    var e = WEATHER_CODES[code];
    var name = e ? e[1] : "weather-none-available";
    if (isDay === false) {
        // Prefer night variants where the icon theme offers them.
        if (name === "weather-clear") return "weather-clear-night";
        if (name === "weather-few-clouds") return "weather-few-clouds-night";
    }
    return name;
}

// Glyph category for the custom-drawn hero graphic.
// Returns one of: "sun", "moon", "partly", "cloud", "rain", "snow", "storm", "fog"
function glyphCategory(code, isDay) {
    if (code === 0 || code === 1) return isDay === false ? "moon" : "sun";
    if (code === 2) return "partly";
    if (code === 3 || code === 45 || code === 48) return (code === 3 ? "cloud" : "fog");
    if (code >= 51 && code <= 67) return "rain";
    if (code >= 71 && code <= 77) return "snow";
    if (code >= 80 && code <= 82) return "rain";
    if (code >= 85 && code <= 86) return "snow";
    if (code >= 95) return "storm";
    return isDay === false ? "moon" : "sun";
}

// ================= Helpers =================

var COMPASS = ["N","NNE","NE","ENE","E","ESE","SE","SSE","S","SSW","SW","WSW","W","WNW","NW","NNW"];
function compass(deg) {
    if (deg === null || deg === undefined || isNaN(deg)) return "";
    return COMPASS[Math.round(deg / 22.5) % 16];
}

function uvLabel(uv) {
    if (uv === null || isNaN(uv)) return "";
    if (uv < 3) return "Low";
    if (uv < 6) return "Moderate";
    if (uv < 8) return "High";
    if (uv < 11) return "Very High";
    return "Extreme";
}

function aqiLabel(aqi) {
    if (aqi === null || isNaN(aqi)) return "";
    if (aqi <= 50) return "Good";
    if (aqi <= 100) return "Moderate";
    if (aqi <= 150) return "Unhealthy (sensitive)";
    if (aqi <= 200) return "Unhealthy";
    if (aqi <= 300) return "Very unhealthy";
    return "Hazardous";
}

// AQI -> a semantic color name the QML side maps to a theme role.
function aqiTone(aqi) {
    if (aqi === null || isNaN(aqi)) return "neutral";
    if (aqi <= 50) return "good";
    if (aqi <= 100) return "warn";
    return "bad";
}

function minutesOfDay(isoLocal) {
    // "2026-10-11T06:51" -> minutes since midnight (local wall clock).
    if (!isoLocal) return NaN;
    var t = isoLocal.split("T")[1];
    if (!t) return NaN;
    var hm = t.split(":");
    return parseInt(hm[0], 10) * 60 + parseInt(hm[1], 10);
}

function fmtClock(isoLocal) {
    if (!isoLocal) return "";
    var t = isoLocal.split("T")[1];
    if (!t) return "";
    var hm = t.split(":");
    var h = parseInt(hm[0], 10);
    var m = hm[1];
    var ampm = h >= 12 ? "PM" : "AM";
    var h12 = h % 12; if (h12 === 0) h12 = 12;
    return h12 + ":" + m + " " + ampm;
}

// ================= Moon phase (astronomical) =================
// Fraction 0..1 of the synodic cycle; 0 = new, 0.5 = full.
function moonPhase(date) {
    var synodic = 29.53058867;
    // Reference new moon: 2000-01-06 18:14 UTC.
    var ref = Date.UTC(2000, 0, 6, 18, 14, 0);
    var days = (date.getTime() - ref) / 86400000.0;
    var phase = (days % synodic) / synodic;
    if (phase < 0) phase += 1;
    return phase;
}

function moonPhaseName(p) {
    if (p < 0.03 || p > 0.97) return "New Moon";
    if (p < 0.22) return "Waxing Crescent";
    if (p < 0.28) return "First Quarter";
    if (p < 0.47) return "Waxing Gibbous";
    if (p < 0.53) return "Full Moon";
    if (p < 0.72) return "Waning Gibbous";
    if (p < 0.78) return "Last Quarter";
    return "Waning Crescent";
}

function moonIllumination(p) {
    // Fraction of the disc lit, 0..1.
    return (1 - Math.cos(2 * Math.PI * p)) / 2;
}

// ================= Weather =================

// callback(errorOrNull, weatherObject)
function fetchWeather(lat, lon, tempUnit, windUnit, callback) {
    var us = (tempUnit === "fahrenheit");
    var precipUnit = us ? "inch" : "mm";

    var url = "https://api.open-meteo.com/v1/forecast"
        + "?latitude=" + encodeURIComponent(lat)
        + "&longitude=" + encodeURIComponent(lon)
        + "&current=temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,"
        + "wind_speed_10m,wind_direction_10m,surface_pressure,precipitation,is_day,cloud_cover"
        + "&hourly=uv_index,visibility,dew_point_2m"
        + "&daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,"
        + "precipitation_sum,uv_index_max,snowfall_sum"
        + "&timezone=auto&forecast_days=7"
        + "&temperature_unit=" + encodeURIComponent(tempUnit)
        + "&wind_speed_unit=" + encodeURIComponent(windUnit)
        + "&precipitation_unit=" + encodeURIComponent(precipUnit);

    httpGet(url, function (err, text) {
        if (err) { callback(err, null); return; }
        var d;
        try { d = JSON.parse(text); } catch (e) { callback("Bad weather data", null); return; }
        if (!d.current) { callback("No weather data", null); return; }

        var c = d.current;
        var isDay = c.is_day === 1;
        var tSym = us ? "°F" : "°C";

        // Match the current hour inside the hourly arrays.
        var hIdx = 0;
        if (d.hourly && d.hourly.time) {
            var key = c.time ? c.time.slice(0, 13) : "";
            for (var i = 0; i < d.hourly.time.length; i++) {
                if (d.hourly.time[i].slice(0, 13) === key) { hIdx = i; break; }
            }
        }
        function hourly(name) {
            if (d.hourly && d.hourly[name] && d.hourly[name][hIdx] !== undefined)
                return d.hourly[name][hIdx];
            return null;
        }

        // Visibility (hourly, metres).
        var visM = hourly("visibility");
        var visStr = "";
        if (visM !== null && !isNaN(visM)) {
            visStr = us ? (visM / 1609.34).toFixed(1) + " mi" : (visM / 1000).toFixed(1) + " km";
        }

        // Pressure.
        var presStr = "";
        if (c.surface_pressure !== undefined && c.surface_pressure !== null) {
            presStr = us ? (c.surface_pressure * 0.02953).toFixed(2) + " inHg"
                         : Math.round(c.surface_pressure) + " hPa";
        }

        var uv = hourly("uv_index");
        if ((uv === null || isNaN(uv)) && d.daily && d.daily.uv_index_max)
            uv = d.daily.uv_index_max[0];

        var dew = hourly("dew_point_2m");

        // Sun arc maths in the location's local time.
        var offset = d.utc_offset_seconds || 0;
        var locNow = new Date(Date.now() + offset * 1000);
        var nowMin = locNow.getUTCHours() * 60 + locNow.getUTCMinutes();

        var sunrise = (d.daily && d.daily.sunrise) ? d.daily.sunrise[0] : "";
        var sunset = (d.daily && d.daily.sunset) ? d.daily.sunset[0] : "";
        var srMin = minutesOfDay(sunrise);
        var ssMin = minutesOfDay(sunset);
        var dayProgress = -1;
        if (!isNaN(srMin) && !isNaN(ssMin) && ssMin > srMin) {
            dayProgress = (nowMin - srMin) / (ssMin - srMin);
        }
        var dayLenMin = (!isNaN(srMin) && !isNaN(ssMin)) ? (ssMin - srMin) : NaN;

        // Moon.
        var mp = moonPhase(new Date());
        var moon = {
            phase: mp,
            name: moonPhaseName(mp),
            illumination: Math.round(moonIllumination(mp) * 100)
        };

        var result = {
            temperature: Math.round(c.temperature_2m),
            feelsLike: Math.round(c.apparent_temperature),
            humidity: c.relative_humidity_2m,
            windSpeed: Math.round(c.wind_speed_10m),
            windDir: c.wind_direction_10m,
            windCompass: compass(c.wind_direction_10m),
            cloudCover: c.cloud_cover,
            code: c.weather_code,
            condition: describeWeather(c.weather_code),
            icon: weatherIcon(c.weather_code, isDay),
            glyph: glyphCategory(c.weather_code, isDay),
            isDay: isDay,
            tempSymbol: tSym,
            windSymbol: windUnit,
            pressure: presStr,
            dewPoint: (dew !== null && !isNaN(dew)) ? Math.round(dew) + tSym : "",
            visibility: visStr,
            uv: (uv !== null && !isNaN(uv)) ? Math.round(uv) : null,
            uvLabel: uvLabel(uv),
            precipNow: (c.precipitation !== undefined ? c.precipitation : 0),
            precipUnit: us ? "in" : "mm",
            precipSum: (d.daily && d.daily.precipitation_sum) ? d.daily.precipitation_sum[0] : null,
            snowSum: (d.daily && d.daily.snowfall_sum) ? d.daily.snowfall_sum[0] : null,
            snowUnit: us ? "in" : "cm",
            high: (d.daily && d.daily.temperature_2m_max) ? Math.round(d.daily.temperature_2m_max[0]) : null,
            low: (d.daily && d.daily.temperature_2m_min) ? Math.round(d.daily.temperature_2m_min[0]) : null,
            sunrise: fmtClock(sunrise),
            sunset: fmtClock(sunset),
            dayProgress: dayProgress,
            dayLengthMin: dayLenMin,
            localTime: fmtClock(c.time),
            localDate: (c.time ? c.time.split("T")[0] : ""),
            moon: moon,
            forecast: [],
            hourly: []
        };

        if (d.daily && d.daily.time) {
            for (var j = 0; j < d.daily.time.length && j < 7; j++) {
                result.forecast.push({
                    date: d.daily.time[j],
                    code: d.daily.weather_code[j],
                    icon: weatherIcon(d.daily.weather_code[j], true),
                    glyph: glyphCategory(d.daily.weather_code[j], true),
                    high: Math.round(d.daily.temperature_2m_max[j]),
                    low: Math.round(d.daily.temperature_2m_min[j]),
                    precip: d.daily.precipitation_sum ? d.daily.precipitation_sum[j] : 0
                });
            }
        }

        callback(null, result);
    });
}

// ================= Air quality =================
// callback(null, {aqi, label, tone}) — best effort; never errors hard.
function fetchAirQuality(lat, lon, callback) {
    var url = "https://air-quality-api.open-meteo.com/v1/air-quality"
        + "?latitude=" + encodeURIComponent(lat)
        + "&longitude=" + encodeURIComponent(lon)
        + "&current=us_aqi,grass_pollen,tree_pollen,weed_pollen";
    httpGet(url, function (err, text) {
        if (err) { callback(null, null); return; }
        var d;
        try { d = JSON.parse(text); } catch (e) { callback(null, null); return; }
        if (!d.current) { callback(null, null); return; }
        var aqi = d.current.us_aqi;
        var pollenVals = [d.current.grass_pollen, d.current.tree_pollen, d.current.weed_pollen];
        var pollenMax = null;
        for (var i = 0; i < pollenVals.length; i++) {
            if (pollenVals[i] !== null && pollenVals[i] !== undefined && !isNaN(pollenVals[i])) {
                if (pollenMax === null || pollenVals[i] > pollenMax) pollenMax = pollenVals[i];
            }
        }
        var pollenLabel = "--";
        if (pollenMax !== null) {
            if (pollenMax < 10) pollenLabel = "Low";
            else if (pollenMax < 50) pollenLabel = "Moderate";
            else if (pollenMax < 100) pollenLabel = "High";
            else pollenLabel = "Very high";
        }
        callback(null, {
            aqi: (aqi !== null && aqi !== undefined && !isNaN(aqi)) ? Math.round(aqi) : null,
            label: aqiLabel(aqi),
            tone: aqiTone(aqi),
            pollen: pollenLabel
        });
    });
}

// ================= Weather alerts (US / NOAA) =================
// callback(null, [{event, severity, tone}])
function fetchAlerts(lat, lon, callback) {
    var url = "https://api.weather.gov/alerts/active?point="
        + encodeURIComponent(lat + "," + lon);
    httpGet(url, function (err, text) {
        if (err) { callback(null, []); return; }
        var d;
        try { d = JSON.parse(text); } catch (e) { callback(null, []); return; }
        var out = [];
        if (d.features) {
            for (var i = 0; i < d.features.length && i < 5; i++) {
                var p = d.features[i].properties || {};
                var sev = (p.severity || "").toLowerCase();
                var tone = "warn";
                if (sev === "severe" || sev === "extreme") tone = "bad";
                else if (sev === "minor") tone = "neutral";
                out.push({ event: p.event || "Alert", severity: p.severity || "", tone: tone });
            }
        }
        callback(null, out);
    }, { "Accept": "application/geo+json" });
}

// ================= Space weather (NOAA Kp index) =================
// callback(null, {kp, g, tone})
function fetchSpaceWeather(callback) {
    var url = "https://services.swpc.noaa.gov/products/noaa-planetary-k-index.json";
    httpGet(url, function (err, text) {
        if (err) { callback(null, null); return; }
        var rows;
        try { rows = JSON.parse(text); } catch (e) { callback(null, null); return; }
        if (!rows || rows.length < 2) { callback(null, null); return; }
        var last = rows[rows.length - 1];
        // Columns: time_tag, Kp, Kp_fraction, a_running, station_count
        var kp = parseFloat(last[1]);
        if (isNaN(kp)) { callback(null, null); return; }
        var g = 0;
        if (kp >= 9) g = 5; else if (kp >= 8) g = 4; else if (kp >= 7) g = 3;
        else if (kp >= 6) g = 2; else if (kp >= 5) g = 1;
        var tone = g >= 3 ? "bad" : (g >= 1 ? "warn" : "good");
        callback(null, { kp: kp.toFixed(1), g: "G" + g, tone: tone });
    });
}

// ================= Geocoding =================
function geocode(query, callback) {
    var url = "https://geocoding-api.open-meteo.com/v1/search?count=6&language=en&format=json&name="
        + encodeURIComponent(query);
    httpGet(url, function (err, text) {
        if (err) { callback(err, null); return; }
        var data;
        try { data = JSON.parse(text); } catch (e) { callback("Bad geocode data", null); return; }
        var out = [];
        if (data.results) {
            for (var i = 0; i < data.results.length; i++) {
                var r = data.results[i];
                out.push({
                    name: r.name,
                    admin1: r.admin1 || "",
                    country: r.country || "",
                    latitude: r.latitude,
                    longitude: r.longitude
                });
            }
        }
        callback(null, out);
    });
}

// ================= Stocks (Stooq CSV) =================
function stooqSymbol(sym) {
    sym = sym.trim().toLowerCase();
    if (sym.length === 0) return "";
    if (sym.indexOf(".") !== -1) return sym;
    if (sym.charAt(0) === "^") return sym;
    return sym + ".us";
}

function fetchStocks(symbolsCsv, callback) {
    var raw = symbolsCsv.split(",");
    var mapped = [];
    for (var i = 0; i < raw.length; i++) {
        var s = stooqSymbol(raw[i]);
        if (s.length > 0) mapped.push({ display: raw[i].trim().toUpperCase(), stooq: s });
    }
    if (mapped.length === 0) { callback(null, []); return; }

    var joined = mapped.map(function (m) { return m.stooq; }).join(",");
    var url = "https://stooq.com/q/l/?s=" + encodeURIComponent(joined) + "&h&e=csv";

    httpGet(url, function (err, text) {
        if (err) { callback(err, null); return; }
        var lines = text.split("\n");
        if (lines.length < 2) { callback("No stock data", null); return; }
        var header = lines[0].split(",");
        var idx = {};
        for (var h = 0; h < header.length; h++) idx[header[h].trim().toLowerCase()] = h;

        var out = [];
        for (var r = 1; r < lines.length; r++) {
            var line = lines[r].trim();
            if (line.length === 0) continue;
            var cols = line.split(",");
            var close = parseFloat(cols[idx["close"]]);
            var open = parseFloat(cols[idx["open"]]);
            var name = (idx["name"] !== undefined && cols[idx["name"]]) ? cols[idx["name"]] : mapped[r - 1].display;
            var change = NaN, pct = NaN;
            if (!isNaN(close) && !isNaN(open) && open !== 0) {
                change = close - open;
                pct = (change / open) * 100;
            }
            out.push({
                symbol: mapped[r - 1] ? mapped[r - 1].display : (cols[idx["symbol"]] || "?"),
                name: name,
                price: isNaN(close) ? "N/A" : close.toFixed(2),
                change: isNaN(change) ? "" : (change >= 0 ? "+" : "") + change.toFixed(2),
                changePercent: isNaN(pct) ? "" : (pct >= 0 ? "+" : "") + pct.toFixed(2) + "%",
                up: !isNaN(change) && change >= 0,
                valid: !isNaN(close)
            });
        }
        callback(null, out);
    });
}

// ================= News (RSS / Atom) =================

function decodeEntities(s) {
    if (!s) return "";
    return s.replace(/<!\[CDATA\[([\s\S]*?)\]\]>/g, "$1")
            .replace(/<[^>]+>/g, "")
            .replace(/&lt;/g, "<")
            .replace(/&gt;/g, ">")
            .replace(/&quot;/g, '"')
            .replace(/&#39;/g, "'")
            .replace(/&apos;/g, "'")
            .replace(/&amp;/g, "&")
            .replace(/\s+/g, " ")
            .trim();
}

function extractTag(block, tag) {
    var m = block.match(new RegExp("<" + tag + "[^>]*>([\\s\\S]*?)</" + tag + ">", "i"));
    return m ? m[1] : "";
}

function fetchNews(feedUrl, callback) {
    httpGet(feedUrl, function (err, text) {
        if (err) { callback(err, null); return; }
        var items = [];
        var isAtom = text.indexOf("<entry") !== -1 && text.indexOf("<item") === -1;
        var re = isAtom ? /<entry[\s\S]*?<\/entry>/gi : /<item[\s\S]*?<\/item>/gi;
        var blocks = text.match(re) || [];
        for (var i = 0; i < blocks.length && i < 20; i++) {
            var b = blocks[i];
            var title = decodeEntities(extractTag(b, "title"));
            var link = "";
            if (isAtom) {
                var lm = b.match(/<link[^>]*href="([^"]+)"/i);
                link = lm ? lm[1] : "";
            } else {
                link = decodeEntities(extractTag(b, "link"));
            }
            var date = decodeEntities(extractTag(b, isAtom ? "updated" : "pubDate"));
            var source = decodeEntities(extractTag(b, "source"));
            if (title.length === 0) continue;
            items.push({ title: title, link: link, source: source, date: date });
        }
        callback(null, items);
    });
}
