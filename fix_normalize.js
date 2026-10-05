// Fixed normalizeReading function to map backend API fields to frontend fields
function normalizeReading(data) {
  // Map backend field names to frontend field names
  const backendTemp = data.temperature_c ?? data.temp;
  const backendHumidity = data.humidity_pct ?? data.humidity;
  const backendPressure = data.pressure_hpa ?? data.pressure;
  const backendForecast1h = data.forecast_1h_mm ?? data.forecast_1h;
  const backendForecast2h = data.forecast_2h_mm ?? data.forecast_2h;
  const backendForecast3h = data.forecast_3h_mm ?? data.forecast_3h;

  const numericPressure =
    backendPressure === null || backendPressure === undefined || backendPressure === ''
      ? NaN
      : Number(backendPressure);

  return {
    deviceId: data.deviceId ?? data.device_id ?? 'esp32-hardware',
    source: data.source ?? null,
    time: data.time ?? null,
    temp: backendTemp ?? null,
    humidity: backendHumidity ?? null,
    pressure: Number.isFinite(numericPressure) ? numericPressure : DEFAULT_PRESSURE_HPA,
    rain_level: data.rain_level ?? null,
    rain_detected:
      typeof data.rain_detected === 'boolean' ? data.rain_detected : null,
    rain_intensity: data.rain_intensity ?? 'UNKNOWN',
    forecast_1h: backendForecast1h ?? null,
    forecast_2h: backendForecast2h ?? null,
    forecast_3h: backendForecast3h ?? null,
    capturedAt: data.capturedAt ?? data.captured_at ?? null,
    updatedAt: data.updatedAt ?? data.updated_at ?? null,
    createdAt: data.createdAt ?? data.created_at ?? null
  };
}
