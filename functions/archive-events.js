const { onSchedule } = require("firebase-functions/v2/scheduler");
const { getFirestore } = require("firebase-admin/firestore");

/**
 * The main Cloud Functions handler for archiveEvents.
 * When this is triggered, it will query for events that aren't archived,
 * check to see if their final date is in the past, and if so, archive them.
 */
async function handle() {
  try {
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    console.log(`Archiving events prior to ${yesterday}`);

    // Query for events that are not yet archived.
    const events = await getFirestore()
      .collection("resources")
      .where("resourceType", "==", "Event")
      .where("isVisable", "!=", false)
      .select("name", "schedule")
      .get();

    // Check each one to see if they're ready to be archived.
    // If any are, add the update promise to this array.
    const updates = [];
    events.forEach((doc) => {
      const data = doc.data();
      const final = getFinalDate(data.schedule);
      if (final !== null && final < yesterday) {
        // Archive it!
        console.log(`"${data.name}" (id: ${doc.id}) is due to be archived...`);
        const promise = doc.ref.update({ isVisable: false });
        updates.push(promise);
      }
    });

    await Promise.all(updates);
    console.log(`Success. Archived ${updates.length} events.`);
  } catch (error) {
    console.error("Error while checking events:", error);
    throw error;
  }
}

// Schedule this to run daily via Pub/Sub schedule.
// 7:03 AM UTC every day -- should be just after midnight in AZ
exports.archiveEvents = onSchedule(
  { timeoutSeconds: 300, schedule: "3 7 * * *" },
  handle
);

// This version is handy to keep around for local emulator debugging.
// Just make sure to comment it out before deploying.
// exports.archiveEvents = functions.https.onRequest(async (req, res) => {
//   try {
//     await handle();
//   } finally {
//     res.send("OK")
//   }
// });

/**
 * Get the final date of an event, accounting for the possiblity of
 * recurring events. (For non-recurring events, the final date is the
 * same as the first date.) A recurring event without an `until` date
 * does not have a final date, and we return null in this case.
 * @param {*} schedule the event's schedule object
 * @returns {Date | null} the final date of the event or null if there isn't one.
 */
function getFinalDate(schedule) {
  const first =
    schedule.time !== null
      ? new Date(`${schedule.date}${schedule.time}Z`)
      : new Date(`${schedule.date}T00:00:00Z`);

  switch (schedule.type) {
    case "once":
      return first;

    case "recurring":
      if (schedule.until === null) {
        // If there's no 'until' date, there is no final date.
        return null;
      } else {
        // Increment the first date by frequency until we find the
        // one prior to the until date.
        const until = new Date(schedule.until);
        const increment = getIncrement(schedule.frequency);
        let last = first;
        let d = first;
        while (d < until) {
          last = d;
          d = increment(first, d);
        }
        return last;
      }

    default:
      return null;
  }
}

// Date utils

/**
 * Increment a date by one year.
 * @param {Date} firstDate the first date in this series; used to maintain day-in-month stability
 * @param {Date} date the date to increment
 * @returns {Date} a new Date object
 */
function incrementYear(firstDate, date) {
  const d = new Date(date);
  d.setFullYear(date.getFullYear() + 1);
  return d;
}

/**
 * Increment a date by one month.
 * @param {Date} firstDate the first date in this series; used to maintain day-in-month stability
 * @param {Date} date the date to increment
 * @returns {Date} a new Date object
 */
function incrementMonth(firstDate, date) {
  // This implementation prefers the same day of the month as the initial
  // date, but will use the latest available day in the correct month
  // if it has to. In other words, 'Jan 31st, 2023' becomes 'Feb 28th, 2023'
  // and then 'Mar 31st, 2023' after that. Leap year accounted for.
  const year =
    date.getMonth() == 11 ? date.getFullYear() + 1 : date.getFullYear();
  const month = (date.getMonth() + 1) % 12; // in JS, months are in range: [0,11]
  const day = Math.min(firstDate.getDate(), daysInMonth(year, month));
  const d = new Date(firstDate);
  d.setFullYear(year);
  d.setMonth(month);
  d.setDate(day);
  return d;
}

/**
 * Increment a date by one week.
 * @param {Date} firstDate the first date in this series; used to maintain day-in-month stability
 * @param {Date} date the date to increment
 * @returns {Date} a new Date object
 */
function incrementWeek(firstDate, date) {
  const d = new Date(date);
  d.setDate(d.getDate() + 7);
  return d;
}

/**
 * Increment a date by one day.
 * @param {Date} firstDate the first date in this series; used to maintain day-in-month stability
 * @param {Date} date the date to increment
 * @returns {Date} a new Date object
 */
function incrementDay(firstDate, date) {
  const d = new Date(date);
  d.setDate(d.getDate() + 1);
  return d;
}

/**
 * Gets the increment function for the given frequency value.
 */
function getIncrement(frequency) {
  switch (frequency) {
    case "annually":
      return incrementYear;
    case "monthly":
      return incrementMonth;
    case "weekly":
      return incrementWeek;
    case "daily":
      return incrementDay;
    default:
      throw new Error(`Unsupported frequency value: ${frequency}`);
  }
}

/**
 * Returns the number of days in the given month for the given year.
 * @param {number} year full year
 * @param {number} month index of the month (0 to 11)
 * @returns {number} the number of days in that month
 */
function daysInMonth(year, month) {
  return new Date(year, month, 0).getDate();
}
