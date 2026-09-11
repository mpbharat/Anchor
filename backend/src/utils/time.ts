const DAYS = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];

export function dayIndex(day: string): number {
  return DAYS.indexOf(day);
}

// Monday of "today" in the given timezone, as YYYY-MM-DD
export function currentWeekStart(timezone: string): string {
  const now = new Date();
  const fmt = new Intl.DateTimeFormat('en-CA', {
    timeZone: timezone,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    weekday: 'short',
  });
  const parts = fmt.formatToParts(now);
  const get = (t: string) => parts.find((p) => p.type === t)?.value ?? '';
  const weekdayShort = get('weekday'); // Mon, Tue, ...
  const jsDay = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].indexOf(weekdayShort);
  const local = new Date(`${get('year')}-${get('month')}-${get('day')}T00:00:00Z`);
  local.setUTCDate(local.getUTCDate() - (jsDay < 0 ? 0 : jsDay));
  return local.toISOString().slice(0, 10);
}

export function isoWeekNumber(dateStr: string): number {
  const d = new Date(`${dateStr}T00:00:00Z`);
  const day = d.getUTCDay() || 7;
  d.setUTCDate(d.getUTCDate() + 4 - day);
  const yearStart = Date.UTC(d.getUTCFullYear(), 0, 1);
  return Math.ceil(((d.getTime() - yearStart) / 86400000 + 1) / 7);
}

export function addDays(dateStr: string, days: number): string {
  const d = new Date(`${dateStr}T00:00:00Z`);
  d.setUTCDate(d.getUTCDate() + days);
  return d.toISOString().slice(0, 10);
}

// Convert a wall-clock date+time in a timezone to a UTC instant.
// Two-pass offset estimate; good to the minute outside DST transition hours.
export function zonedToUtc(dateStr: string, timeStr: string, timezone: string): Date {
  const [hh, mm] = timeStr.split(':').map(Number);
  const [y, mo, da] = dateStr.split('-').map(Number);
  const guess = Date.UTC(y, mo - 1, da, hh, mm);

  const offsetAt = (utcMs: number): number => {
    const fmt = new Intl.DateTimeFormat('en-CA', {
      timeZone: timezone,
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
      hour12: false,
    });
    const parts = fmt.formatToParts(new Date(utcMs));
    const get = (t: string) => Number(parts.find((p) => p.type === t)?.value ?? 0);
    const asIfUtc = Date.UTC(get('year'), get('month') - 1, get('day'), get('hour') % 24, get('minute'), get('second'));
    return asIfUtc - utcMs;
  };

  let offset = offsetAt(guess);
  offset = offsetAt(guess - offset);
  return new Date(guess - offset);
}

// UTC instant for a weekday+time within the week beginning weekStart (a Monday)
export function weekdayTimeToUtc(
  weekStart: string,
  day: string,
  time: string,
  timezone: string,
): Date {
  const date = addDays(weekStart, dayIndex(day));
  return zonedToUtc(date, time, timezone);
}
