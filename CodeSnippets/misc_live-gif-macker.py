# author: Juwon1405
## A simple program to save real-time web monitoring as a GIF

from selenium import webdriver
from pyvirtualdisplay import Display
import imageio
import time
import os


def capture_screenshot(browser, frame_num):
    """Capture a screenshot with the provided browser and frame number"""
    screenshot_name = f'frame{frame_num}.png'
    browser.save_screenshot(screenshot_name)
    return imageio.imread(screenshot_name)


def create_gif(images, output_name):
    """Create a GIF from the provided images"""
    imageio.mimsave(output_name, images)


def remove_files(num_frames):
    """Remove temporary screenshot files"""
    for i in range(num_frames):
        os.remove(f'frame{i}.png')


def capture_page(url, num_frames, delay, output_name):
    """Capture screenshots of a webpage at a set delay and create a GIF"""
    display = Display(visible=0, size=(800, 600))
    display.start()

    try:
        # Open the webpage
        browser = webdriver.Firefox()
        browser.get(url)

        images = []

        # Capture screenshots at each delay
        for i in range(num_frames):
            images.append(capture_screenshot(browser, i))
            time.sleep(delay)

        # Create a GIF from the screenshots
        create_gif(images, output_name)
    except Exception as e:
        print(f"An error occurred: {e}")
    finally:
        # Ensure the browser and display are closed even if an error occurs
        browser.quit()
        display.stop()

        # Remove temporary files
        remove_files(num_frames)


if __name__ == "__main__":
    output_name = 'output.gif'
    capture_page('http://www.example.com', 10, 1, output_name)
