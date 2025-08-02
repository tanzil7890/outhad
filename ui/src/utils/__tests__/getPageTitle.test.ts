import { expect } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';

import getTitle from '@/utils/getPageTitle';

describe('getTitle', () => {
  it('should return the correct title for a known route', () => {
    expect(getTitle('/')).toBe('Dashboard | Outhad');
    expect(getTitle('/settings')).toBe('Settings | Outhad');
    expect(getTitle('/activate/syncs')).toBe('Syncs | Outhad');
    expect(getTitle('/setup/sources')).toBe('Sources | Outhad');
    expect(getTitle('/define/models')).toBe('Models | Outhad');
    expect(getTitle('/setup/destinations')).toBe('Destinations | Outhad');
  });

  it('should return "Outhad" for an unknown route', () => {
    expect(getTitle('/unknown')).toBe('Outhad');
    expect(getTitle('/another/unknown/path')).toBe('Outhad');
  });

  it('should return the correct title for a route with additional path segments', () => {
    expect(getTitle('/')).toBe('Dashboard | Outhad');
    expect(getTitle('/define/models/ai/28')).toBe('Models | Outhad');
    expect(getTitle('/define/models/28')).toBe('Models | Outhad');
  });
});
