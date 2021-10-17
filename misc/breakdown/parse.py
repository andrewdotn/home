#!/usr/bin/env python3

import math
import os.path
import re
from argparse import ArgumentParser, ArgumentDefaultsHelpFormatter
from collections import defaultdict

TIME_RE = re.compile(
    r"""
                     ^
                     ([0-9]{1,2}:[0-9]{2})? # start time
                     \s*
                     -
                     \s*
                     ([0-9]{1,2}:[0-9]{2}) # end time
                     \s*
                     ((?:
                        \[
                            [^\]]*
                        \]
                        \s*
                      )*)
                     :
                     """,
    re.VERBOSE,
)
TAG_RE = re.compile(r"\[([^\]]+)\]")


def time_str_to_minutes_since_midnight(s):
    h, m = s.split(":")
    return int(h) * 60 + int(m)


def to_hms(minutes):
    return f"{math.floor(minutes/60):2}:{minutes % 60 :02}"


FILENAME = os.path.expanduser("~/Desktop/timesheet.txt")


def main():
    parser = ArgumentParser()
    parser.formatter_class = ArgumentDefaultsHelpFormatter
    parser.add_argument(
        "--start-date",
        help="""
        Date, in YYYY-MM-DD format, on which to start analyzing entries.
    """,
    )
    parser.add_argument(
        "--end-date",
        help="""
        Date, in YYYY-MM-DD format, on which to stop analyzing entries.
    """,
    )
    parser.add_argument(
        "--morning-cutoff",
        default="04:00",
        help="""
            Allow sessions after midnight to count against previous day, as
            long as they come before this time early in the morning.
        """,
    )
    parser.add_argument(
        "--filter",
        help="""
            Only include items with this tag.
        """,
    )
    args = parser.parse_args()
    args.morning_cutoff = time_str_to_minutes_since_midnight(
        args.morning_cutoff
    )

    date = None
    end_time = None

    prev_date = None
    prev_end_minutes = None
    late_night_transition_used = False

    tag_times = defaultdict(int)
    date_times = defaultdict(int)
    total_time = 0

    with open(FILENAME, "rt") as f:
        found = False
        for n, line in enumerate(f):
            line_number = n + 1

            def report_error(msg):
                """Return a string with additional info, to be used in assert"""
                return f"{FILENAME}:{line_number}: {msg}: {line!r}"

            if re.match(r"^\s*[0-9]{4}-[0-9]{2}-[0-9]{2}\s*$", line):
                date = line.strip()

                should_skip_because_before_start_date = (
                    args.start_date is not None and date < args.start_date
                )
                if not found and should_skip_because_before_start_date:
                    continue
                found = True

                should_skip_because_after_end_date = (
                    args.end_date is not None and date > args.end_date
                )
                if should_skip_because_after_end_date:
                    found = False
                    continue

                assert prev_date is None or date > prev_date, report_error(
                    f"date {date} is not after previous {prev_date}"
                )

                if date != prev_date:
                    late_night_transition_used = False

            elif found and (match := TIME_RE.match(line)):
                if match.group(1):
                    start_time = match.group(1)
                else:
                    start_time = end_time
                end_time = match.group(2)
                tags = match.group(3)

                start_minutes = time_str_to_minutes_since_midnight(start_time)
                end_minutes = time_str_to_minutes_since_midnight(end_time)

                assert prev_date is None or date >= prev_date, report_error(
                    f"new date {date} before previous date {prev_date}"
                )

                # Handle work episodes after midnight, assigning time to
                # previous day. For episodes that contain midnight, try
                # adding 24 to the hour, e.g., ‘25:30’ for an end of
                # 1:30 a.m.
                late_night_session = False
                if (
                    not late_night_transition_used
                    and prev_end_minutes is not None
                    and start_minutes < prev_end_minutes
                    and start_minutes < args.morning_cutoff
                    and end_minutes < args.morning_cutoff
                ):
                    late_night_session = True
                    # Only allow transition to be used once per day,
                    # otherwise early-morning overlaps would sneak through
                    late_night_transition_used = True

                assert (
                    prev_end_minutes is None
                    or date != prev_date
                    or late_night_session
                    or start_minutes >= prev_end_minutes
                ), report_error(f"start {start_time} is before end of previous")
                assert start_minutes < end_minutes, report_error(
                    f"end time {end_time} not after start time {start_time}"
                )

                duration = end_minutes - start_minutes

                print(f"{date} {start_time=} {end_time=} {tags=} {duration=}")

                tag_list = TAG_RE.findall(tags)
                if args.filter is None or args.filter in tag_list:
                    total_time += duration
                    for t in tag_list:
                        tag_times[t] += duration

                    date_times[date] += duration

                prev_date, prev_start_minutes, prev_end_minutes = (
                    date,
                    start_minutes,
                    end_minutes,
                )

    for date, duration in date_times.items():
        print(f"{date} {to_hms(duration)}")

    tags_by_duration = sorted(tag_times.keys(), key=lambda t: -tag_times[t])

    for tag in tags_by_duration:
        duration = tag_times[tag]
        print(
            f"{tag:20} {duration:5} {to_hms(duration):>8} {duration / total_time * 100:3.0f}%"
        )


if __name__ == "__main__":
    main()
