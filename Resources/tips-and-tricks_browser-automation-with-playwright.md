> Source: https://heerpou.com/entry/브라우저-자동화-playwright-설치-방법-python-환경

## Browser automation with playwright

### playwright How to install

Other packages in Python can be installed with a single pip command, but playwright requires one more installation.

It's not that complicated. You only need to type one more line.

```bash
    pip install pytest-playwright

    playwright install
```
    
### playwright How to use

After the installation is complete, test it with the test code below.

The test code below accesses the designated website, takes a browser screenshot, and saves it as an 'example.png' file.

*   [https://www.example.com](https://www.example.com/) : URL to connect
*   example.png : screenshot file
>

```python
    from playwright.sync_api import Playwright, sync_playwright
    
    with sync_playwright() as playwright:
        browser = playwright.chromium.launch()
        page = browser.new_page()
    
        # Navigate to the website
        page.goto('https://www.example.com')

        # Take a screenshot
        page.screenshot(path='example.png')

        browser.close()
```

### Tips for using playwright

For those who have a plan on how to use playwright, but are at a loss as to what kind of code to write

It also has a record function.

As anyone who has ever touched macros in Excel knows, there was a convenient function that did not require me to type in the code one by one to write the appropriate code when I pressed the record button and performed the task I had to do.

Anyway, since playwright provides such a function, it is also recommended that those who have difficulty writing code take advantage of this function and try it.

How to use it in the command input window

```bash
    playwright codegen www.naver.com
```
In the URL at the end, you can enter the site address you want to test.

When you access Naver, enter 'playwright' and press the search button, everything is written in code and appears.

### playwright record function

![](https://blog.kakaocdn.net/dn/bQOwvB/btr727L7dqD/O6ZC4wB60ekOJM2Ljm7eh1/img.png)

