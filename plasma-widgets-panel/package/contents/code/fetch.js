.pragma library

// Lightweight HTTP GET helper used across the widget.
// callback(errorStringOrNull, responseText)
function httpGet(url, callback) {
    var xhr = new XMLHttpRequest();
    try {
        xhr.open("GET", url, true);
    } catch (e) {
        callback("Bad URL: " + e, null);
        return;
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
    xhr.onerror = function () {
        callback("Network error", null);
    };
    try {
        xhr.send();
    } catch (e) {
        callback("Request failed: " + e, null);
    }
}

// ---------------- Weather (Open-Meteo, no API key) ----------------

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
    var entry = WEATHER_CODES[code];
    return entry ? entry[0] : "Unknown";
}

function weatherIcon(code) {
    var entry = WEATHER_CODES[code];
    return entry ? entry[1] : "weather-none-available";
}

// callback(errorOrNull, weatherObject)
function fetchWeather(lat, lon, tempUnit, windUnit, callback) {
    var url = "https://api.open-meteo.com/v1/forecast"
        + "?latitude=" + encodeURIComponent(lat)
        + "&longitude=" + encodeURIComponent(lon)
        + "&current=temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,wind_speed_10m"
        + "&daily=weather_code,temperature_2m_max,temperature_2m_min"
        + "&timezone=auto"
        + "&forecast_days=5"
        + "&temperature_unit=" + encodeURIComponent(tempUnit)
        + "&wind_speed_unit=" + encodeURIComponent(windUnit);

    httpGet(url, function (err, text) {
        if (err) { callback(err, null); return; }
        var data;
        try { data = JSON.parse(text); } catch (e) { callback("Bad weather data", null); return; }
        if (!data.current) { callback("No weather data", null); return; }

        var result = {
            temperature: Math.round(data.current.temperature_2m),
            feelsLike: Math.round(data.current.apparent_temperature),
            humidity: data.current.relative_humidity_2m,
            windSpeed: Math.round(data.current.wind_speed_10m),
            code: data.current.weather_code,
            condition: describeWeather(data.current.weather_code),
            icon: weatherIcon(data.current.weather_code),
            tempSymbol: (tempUnit === "fahrenheit" ? "°F" : "°C"),
            windSymbol: windUnit,
            forecast: []
        };

        if (data.daily && data.daily.time) {
            for (var i = 0; i < data.daily.time.length && i < 5; i++) {
                result.forecast.push({
                    date: data.daily.time[i],
                    code: data.daily.weather_code[i],
                    icon: weatherIcon(data.daily.weather_code[i]),
                    high: Math.round(data.daily.temperature_2m_max[i]),
                    low: Math.round(data.daily.temperature_2m_min[i])
                });
            }
        }
        callback(null, result);
    });
}

// ---------------- Geocoding (Open-Meteo) ----------------
// callback(errorOrNull, [{name, country, latitude, longitude}, ...])
function geocode(query, callback) {
    var url = "https://geocoding-api.open-meteo.com/v1/search?count=5&language=en&format=json&name="
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

// ---------------- Stocks (Stooq CSV, no API key) ----------------
// Stooq uses symbols like aapl.us for US tickers.
function stooqSymbol(sym) {
    sym = sym.trim().toLowerCase();
    if (sym.length === 0) return "";
    // Already has an exchange suffix (contains a dot) -> leave as-is.
    if (sym.indexOf(".") !== -1) return sym;
    // Index symbols on Stooq begin with ^ (e.g. ^spx, ^dji).
    if (sym.charAt(0) === "^") return sym;
    return sym + ".us";
}

// callback(errorOrNull, [{symbol, name, price, change, changePercent, up}, ...])
function fetchStocks(symbolsCsv, callback) {
    var raw = symbolsCsv.split(",");
    var mapped = [];
    for (var i = 0; i < raw.length; i++) {
        var s = stooqSymbol(raw[i]);
        if (s.length > 0) mapped.push({ display: raw[i].trim().toUpperCase(), stooq: s });
    }
    if (mapped.length === 0) { callback(null, []); return; }

    var joined = mapped.map(function (m) { return m.stooq; }).join(",");
    // Default CSV columns: Symbol,Date,Time,Open,High,Low,Close,Volume
    // (&h adds the header row we parse by name; &e=csv selects CSV output).
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

// ---------------- News (RSS/Atom) ----------------

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

// callback(errorOrNull, [{title, link, source, date}, ...])
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
