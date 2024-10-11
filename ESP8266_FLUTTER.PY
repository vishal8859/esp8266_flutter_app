import network
import urequests
from machine import Pin
import time

# Setup LED pin for Pico W's onboard LED
led = Pin("LED", Pin.OUT)

# Function to connect to Wi-Fi
def connect_to_wifi(ssid, password):
    wlan = network.WLAN(network.STA_IF)
    wlan.active(True)
    if not wlan.isconnected():
        print('Connecting to WiFi...')
        wlan.connect(ssid, password)
        while not wlan.isconnected():
            time.sleep(1)
    print('Connected to WiFi:', wlan.ifconfig())
    return wlan  # Return the wlan object for later checks

# Function to check ThingSpeak for updates
def check_thingspeak(api_key, field):
    url = f'http://api.thingspeak.com/channels/2689268/fields/{field}.json?api_key={api_key}&results=1'
    attempt = 0
    max_attempts = 3  # Retry up to 3 times
    while attempt < max_attempts:
        try:
            response = urequests.get(url)
            data = response.json()
            
            if 'feeds' in data and len(data['feeds']) > 0 and f'field{field}' in data['feeds'][0]:
                field_value = data['feeds'][0][f'field{field}']
                if field_value == '1':
                    led.value(0)  # Turn LED ON (active low, 0 is ON)
                    print('LED ON')
                else:
                    led.value(1)  # Turn LED OFF
                    print('LED OFF')
            else:
                print('No data found or incorrect field')

            response.close()
            break  # Exit loop on successful request
        except Exception as e:
            attempt += 1
            print(f'Attempt {attempt} failed: {e}')
            if attempt >= max_attempts:
                print('Failed after multiple attempts, giving up.')
            time.sleep(5)  # Wait 5 seconds before retrying

# Connect to the Wi-Fi network
ssid = 'CMF'
password = 'subm0905'
wlan = connect_to_wifi(ssid, password)

# Main loop to continuously poll ThingSpeak and check Wi-Fi connection
while True:
    if wlan.isconnected():
        print("WiFi is connected")
        check_thingspeak('HJ7T71IUFCY18Q85', 1)  # Check Field 1 on ThingSpeak
    else:
        print("WiFi disconnected! Attempting to reconnect...")
        connect_to_wifi(ssid, password)
    
    time.sleep(30)  # Poll every 30 seconds
