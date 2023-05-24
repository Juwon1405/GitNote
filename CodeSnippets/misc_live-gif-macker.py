> author: Juwon1405

# A simple program to save real-time web monitoring as a GIF

from selenium import webdriver
from pyvirtualdisplay import Display
import imageio
import time
import os

def capture_page(url, num_frames, delay):
    display = Display(visible=0, size=(800, 600))
    display.start()

    browser = webdriver.Firefox()
    browser.get(url)

    images = []

    for i in range(num_frames):
        browser.save_screenshot('frame{}.png'.format(i))
        images.append(imageio.imread('frame{}.png'.format(i)))
        time.sleep(delay)

    imageio.mimsave('output.gif', images)

    browser.quit()
    display.stop()

    for i in range(num_frames):
        os.remove('frame{}.png'.format(i))

if __name__ == "__main__":
    capture_page('http://www.example.com', 10, 1)
