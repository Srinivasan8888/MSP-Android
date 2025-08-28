class SensorConfig {
  static const Map<String, SensorSettings> sensorSettings = {
    'vibration': SensorSettings(
      unit: 'mm/s',
      stepValue: 0.1,
      displayName: 'Vibration',
      minValue: 0.0,
      maxValue: 100.0,
    ),
    'magneticField': SensorSettings(
      unit: 'μT',
      stepValue: 10.0,
      displayName: 'Magnetic Field',
      minValue: 0.0,
      maxValue: 1000.0,
    ),
    'rotation': SensorSettings(
      unit: 'RPM',
      stepValue: 50.0,
      displayName: 'Rotation',
      minValue: 0.0,
      maxValue: 10000.0,
    ),
    'sound': SensorSettings(
      unit: 'dB',
      stepValue: 1.0,
      displayName: 'Sound',
      minValue: 0.0,
      maxValue: 120.0,
    ),
    'temperature': SensorSettings(
      unit: '°C',
      stepValue: 1.0,
      displayName: 'Temperature',
      minValue: -50.0,
      maxValue: 100.0,
    ),
    'humidity': SensorSettings(
      unit: '%',
      stepValue: 1.0,
      displayName: 'Humidity',
      minValue: 0.0,
      maxValue: 100.0,
    ),
    'pressure': SensorSettings(
      unit: 'hPa',
      stepValue: 1.0,
      displayName: 'Pressure',
      minValue: 800.0,
      maxValue: 1200.0,
    ),
    'distance': SensorSettings(
      unit: 'm',
      stepValue: 10.0,
      displayName: 'Distance',
      minValue: 0.0,
      maxValue: 1000.0,
    ),
    'airQuality': SensorSettings(
      unit: 'AQI',
      stepValue: 5.0,
      displayName: 'Air Quality',
      minValue: 0.0,
      maxValue: 500.0,
    ),
  };

  static SensorSettings? getSensorSettings(String sensorKey) {
    return sensorSettings[sensorKey];
  }

  static String getUnit(String sensorKey) {
    return sensorSettings[sensorKey]?.unit ?? '';
  }

  static double getStepValue(String sensorKey) {
    return sensorSettings[sensorKey]?.stepValue ?? 1.0;
  }

  static String getDisplayName(String sensorKey) {
    return sensorSettings[sensorKey]?.displayName ??
        _formatDisplayName(sensorKey);
  }

  static double getMinValue(String sensorKey) {
    return sensorSettings[sensorKey]?.minValue ?? 0.0;
  }

  static double getMaxValue(String sensorKey) {
    return sensorSettings[sensorKey]?.maxValue ?? 1000.0;
  }

  static String _formatDisplayName(String sensorKey) {
    String displayName = sensorKey.replaceAll(
      RegExp(r'([a-z])([A-Z])'),
      r'$1 $2',
    );
    return displayName[0].toUpperCase() + displayName.substring(1);
  }
}

class SensorSettings {
  final String unit;
  final double stepValue;
  final String displayName;
  final double minValue;
  final double maxValue;

  const SensorSettings({
    required this.unit,
    required this.stepValue,
    required this.displayName,
    required this.minValue,
    required this.maxValue,
  });
}
