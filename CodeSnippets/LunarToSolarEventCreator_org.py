import warnings
warnings.filterwarnings("ignore", category=FutureWarning)

import subprocess
import sys

def ensure_dependencies():
    modules = ["ics", "colorama", "requests"]
    for module in modules:
        try:
            __import__(module)
        except ImportError:
            print(f"Installing missing module: {module}...")
            subprocess.check_call([sys.executable, "-m", "pip", "install", module])

ensure_dependencies()

import requests
from datetime import datetime
import datetime as dt
from ics import Calendar, Event
from ics.alarm import DisplayAlarm
from colorama import init, Fore, Back
from pathlib import Path

init(autoreset=True)

class LunarToSolarConverter:
    BASE_URL = 'https://astro.kasi.re.kr/life/lunc'
    REFERENCE_URL = 'https://astro.kasi.re.kr/life/pageView/8'
    _cookies = None

    @classmethod
    def get_cookies(cls):
        if cls._cookies is None:
            with requests.get(cls.REFERENCE_URL) as response:
                cls._cookies = response.cookies
        return cls._cookies

    @classmethod
    def convert(cls, lunar_year, lunar_month, lunar_day):
        cookies = cls.get_cookies()
        params = {
            'yyyy': lunar_year,
            'mm': f"{lunar_month:02}",
            'dd': f"{lunar_day:02}"
        }
        response = requests.get(cls.BASE_URL, cookies=cookies, params=params)
        if response.status_code != 200:
            raise Exception("Failed to fetch solar date. Please check the request.")
        data = response.json()[0]
        return int(data["SOLC_YYYY"]), int(data["SOLC_MM"]), int(data["SOLC_DD"]), data["SOLC_WEEK"]

class IcsEventCreator:

    @staticmethod
    def create_events(event_name, lunar_year, lunar_month, lunar_day):
        start_year = datetime.now().year - 1  # Get the last year
        end_year = 2040
        conversion_results = []

        total_years = end_year - start_year + 1
        formatted_event_name = f"{event_name}(Lunar: {lunar_year}.{lunar_month:02}.{lunar_day:02})"
        
        for idx, year in enumerate(range(start_year, end_year + 1)):
            solar_year, solar_month, solar_day, solar_week = LunarToSolarConverter.convert(year, lunar_month, lunar_day)
            event = Event()
            event.name = formatted_event_name
            event.begin = f"{solar_year}-{solar_month:02}-{solar_day:02} 00:00:00"
            
            # Add alarms
            one_week_before = -dt.timedelta(weeks=1)
            three_days_before = -dt.timedelta(days=3)
            event.alarms = [
                DisplayAlarm(trigger=one_week_before),
                DisplayAlarm(trigger=three_days_before)
            ]
            
            # Output progress percentage
            percentage = (idx + 1) / total_years * 100
            print(f"Progress: {percentage:.2f}%")
            
            conversion_results.append((year, f"{year}.{lunar_month:02}.{lunar_day:02}({solar_week})", f"{solar_year}.{solar_month:02}.{solar_day:02}({solar_week})"))
            
            yield event, conversion_results[-1]

    @staticmethod
    def create_calendar(event_name, lunar_year, lunar_month, lunar_day):
        calendar = Calendar()
        conversion_results = []
        for event, conversion in IcsEventCreator.create_events(event_name, lunar_year, lunar_month, lunar_day):
            calendar.events.add(event)
            conversion_results.append(conversion)
        return calendar, conversion_results

def main():
    try:
        event_name = input("Enter the calendar event name (e.g., Juwon's Birthday): ")
        if not event_name:
            raise ValueError("Calendar event name is required.")
        
        while True:
            lunar_date = input("Enter the lunar birthday to register (e.g., 1988.09.06): ")
            if not lunar_date:
                raise ValueError("Lunar birthday is required. Please enter the date in 'YYYY.MM.DD' format.")
            try:
                lunar_year, lunar_month, lunar_day = map(int, lunar_date.split('.'))
                if lunar_month < 1 or lunar_month > 12 or lunar_day < 1 or lunar_day > 30:
                    raise ValueError("Invalid date format. Please enter the date in 'YYYY.MM.DD' format.")
                break
            except ValueError:
                print("Invalid date format. Please enter the date in 'YYYY.MM.DD' format.")
        
        start_year = datetime.now().year - 1  # Get the last year

        print(f"""
          [Note: The event name includes the lunar birthday for reference.]
          
          Generating an ics file with the following details:
          - Event Name: {event_name}
          - Lunar Birthday: {lunar_date} 
          - Generation Period: Events will be created from {start_year} to 2040 using the converted solar dates.
          - Alarms: 1 week before, 3 days before, and at 00:00 on the birthday.
          - Source for Calculation: https://astro.kasi.re.kr/life/pageView/8
          """)

        calendar, conversion_results = IcsEventCreator.create_calendar(event_name, lunar_year, lunar_month, lunar_day)
        filename = Path.cwd() / f"{event_name}(Lunar: {lunar_year}.{lunar_month:02}.{lunar_day:02})_{start_year}_2040.ics"
        with open(filename, 'w', encoding='utf-8') as f:
            f.writelines(calendar.serialize())

        print(f"\n\nICS file has been created at: {filename}")

        if conversion_results:
            print("\n\n| No.       | Lunar Birthday       | Solar Birthday       |")
            print("|-----------|----------------------|----------------------|")
            for idx, (year, lunar, solar) in enumerate(conversion_results, 1):
                print(f"| {idx:<9} | {lunar:<20} | {solar:<20} |")
        else:
            print("No conversion results to display.")

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main()