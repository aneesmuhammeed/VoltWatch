# Alarm Sound Assets

This directory contains bundled alarm sound files for iOS (platform-specific, as iOS requires local assets for notification sounds).

## Adding Alarm Sounds

Place your `.wav` or `.caf` files here for iOS notification sounds.

Example: `alarm_charging.wav`

### Creating iOS-compatible sounds
For iOS notification sounds, use:
- Format: Linear PCM (uncompressed) or IMA4 (compressed) for `.caf`, or PCM `.wav`
- Duration: Under 30 seconds (required by iOS)
- Sample Rate: 22.05 kHz or 44.1 kHz

### Generating placeholder sounds

You can generate a test sound file using Python:

```python
import wave, struct

# Generate a 1-second 1000Hz sine wave
duration = 1.0  # seconds
freq = 1000.0   # Hz
sampleRate = 44100

with wave.open('alarm_charging.wav', 'w') as f:
    f.setnchannels(1)        # Mono
    f.setsampwidth(2)        # 16-bit
    f.setframerate(sampleRate)
    for i in range(int(sampleRate * duration)):
        value = int(32767 * 0.8 * 
                    (1 if i % (sampleRate//freq) < (sampleRate//freq)//2 else -1))  # Square wave
        data = struct.pack('<h', value)
        f.writeframes(data)
```

Or use any audio editing tool to create short `.wav` files.

## Important Notes

- Android can use remote URLs (HTTP/HTTPS) for alarm sounds via `audioplayers`
- iOS requires **local bundled assets** for notification sounds
- The `NotificationService` handles platform-specific sound loading automatically
