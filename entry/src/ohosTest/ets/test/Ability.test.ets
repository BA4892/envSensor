import { describe, it, expect } from '@ohos/hypium';

export default function abilityTest() {
  describe('EnvSensorTest', () => {
    it('protocolFrameParse', 0, () => {
      const frame: number[] = [0xA5, 26, 50, 0x00, 0xC8, 75, 0x5A];
      expect(frame[0]).assertEqual(0xA5);
      expect(frame[6]).assertEqual(0x5A);
      expect(frame.length).assertEqual(7);
      const temperature = frame[1];
      const humidity = frame[2];
      const light = (frame[3] << 8) | frame[4];
      const airQuality = frame[5];
      expect(temperature).assertEqual(26);
      expect(humidity).assertEqual(50);
      expect(light).assertEqual(200);
      expect(airQuality).assertEqual(75);
    })
  })
}
