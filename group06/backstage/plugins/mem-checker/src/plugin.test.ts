import { memCheckerPlugin } from './plugin';

describe('mem-checker', () => {
  it('should export plugin', () => {
    expect(memCheckerPlugin).toBeDefined();
  });
});
